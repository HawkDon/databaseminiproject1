/* Cleanup */

DROP TABLE IF EXISTS book_orders;
DROP TABLE IF EXISTS client;
DROP TABLE IF EXISTS stockings;
DROP TABLE IF EXISTS book_instances;
DROP TABLE IF EXISTS book;
DROP TABLE IF EXISTS author;
DROP TABLE IF EXISTS publisher;

DROP TRIGGER IF EXISTS add_booking_order ON book_orders;
DROP TRIGGER IF EXISTS delete_booking_order ON book_orders;
DROP TRIGGER IF EXISTS update_amount_of_copies ON book_instances;

DROP FUNCTION IF EXISTS isBookAvailable(isbnId integer);
DROP FUNCTION IF EXISTS checkBookCapacityPrivileges(client_id integer);
DROP FUNCTION IF EXISTS checkDatePrivileges(client_id integer, from_date date, to_date date);
DROP FUNCTION IF EXISTS remove_book_from_the_shelf();
DROP FUNCTION IF EXISTS put_book_on_the_shelf();
DROP FUNCTION If EXISTS update_amount_of_copies();

DROP TYPE IF EXISTS rarity_t;
DROP TYPE IF EXISTS roles_t;
DROP TYPE IF EXISTS type_t;
DROP TYPE IF EXISTS location_t;

/* Enums */
create type rarity_t as enum ('RARE', 'NORMAL');
create type roles_t as enum ('STUDENT', 'NORMAL', 'TEACHER');
create type type_t as enum('PRINTED_BOOK', 'ELECTRONIC_BOOK');
create type location_t as enum('AT_LIBRARY', 'AT_CLIENT');

/* Tables */
CREATE TABLE author (
    id SERIAL PRIMARY KEY NOT NULL,
    name varchar(150) NOT NULL
);

CREATE TABLE publisher (
    id SERIAL PRIMARY KEY NOT NULL,
    name varchar(150) NOT NULL
);

CREATE TABLE book (
    id SERIAL PRIMARY KEY NOT NULL,
    title varchar(150) NOT NULL,
    author integer REFERENCES author(id) NOT NULL,
    publisher integer REFERENCES publisher(id) NOT NULL,
    year date NOT NULL
);

CREATE TABLE book_instances(
    isbn SERIAL PRIMARY KEY NOT NULL,
    bookTypeId integer REFERENCES book(id),
    type type_t NOT NULL,
    rarity rarity_t DEFAULT 'NORMAL' NOT NULL,
    availability boolean DEFAULT true NOT NULL,
    location location_t DEFAULT 'AT_LIBRARY' NOT NULL
);

CREATE TABLE stockings (
    id integer REFERENCES book(id) NOT NULL,
    electronic_copies integer NOT NULL,
    printed_copies integer NOT NULL
);

CREATE TABLE client(
    id SERIAL PRIMARY KEY,
    role roles_t NOT NULL
);

/* Checks */
CREATE OR REPLACE FUNCTION isBookAvailable(isbnId integer)
RETURNS boolean as $$
    DECLARE
        isAvailable boolean;
        e_copies integer;
        p_copies integer;
        bookType type_t;
        bookId integer;
    BEGIN
        SELECT type into bookType FROM book_instances WHERE isbn = isbnId;
        SELECT bookTypeId into bookId FROM book_instances WHERE isbn = isbnId;
        IF bookType = 'PRINTED_BOOK' THEN
            SELECT printed_copies into p_copies from stockings where id = bookId;
            IF p_copies = 0 THEN
                RAISE NOTICE 'The book with type "PRINTED" is not available';
                isAvailable = false;
            END IF;
            IF p_copies > 0 THEN
                isAvailable = true;
            END IF;
        END IF;
        IF bookType = 'ELECTRONIC_BOOK' THEN
            SELECT electronic_copies into e_copies from stockings where id = bookId;
            IF e_copies = 0 THEN
                RAISE NOTICE 'The book with type "ELECTRONIC" is not available';
                isAvailable = false;
            END IF;
            IF e_copies > 0 THEN
                isAvailable = true;
            END IF;
        END IF;
        RETURN isAvailable;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION checkBookCapacityPrivileges(client_id integer)
RETURNS boolean as $$
    DECLARE
        roleOfClient roles_t;
        amountOfOrders integer;
        hasSpace boolean;
    BEGIN
        SELECT role into roleOfClient FROM client WHERE id = client_id;
        SELECT count(*) into amountOfOrders FROM book_orders WHERE clientId = client_id AND current_date < toDate;
        IF roleOfClient = 'NORMAL' THEN
            IF amountOfOrders < 1 THEN
                hasSpace = true;
            ELSE
                hasSpace = false;
            END IF;
        END IF;
        IF roleOfClient = 'TEACHER' THEN
            IF amountOfOrders < 2 THEN
                hasSpace = true;
            ELSE
                hasSpace = false;
            END IF;
        END IF;
        IF roleOfClient = 'STUDENT' THEN
            IF amountOfOrders < 3 THEN
                hasSpace = true;
            ELSE
                hasSpace = false;
            END IF;
        END IF;
        RETURN hasSpace;
    END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION checkDatePrivileges(client_id integer, from_date date, to_date date)
RETURNS boolean as $$
    DECLARE
        clientRole roles_t;
        days integer;
        dateIsValid boolean;
    BEGIN
        SELECT role into clientRole from client WHERE id = client_id;
        SELECT DATE_PART('day', to_date::timestamp - from_date::timestamp) into days;
        IF clientRole = 'NORMAL' THEN
            IF days < 8 AND days > 0 THEN
                dateIsValid = true;
            ELSE
                RAISE NOTICE 'Date range is invalid for role type of: %', clientRole;
                dateIsValid = false;
            END IF;
        END IF;
        IF clientRole = 'TEACHER' THEN
            IF days < 15 AND days > 0 THEN
                dateIsValid = true;
            ELSE
                RAISE NOTICE 'Date range is invalid for role type of: %', clientRole;
                dateIsValid = false;
            END IF;
        END IF;
        IF clientRole = 'STUDENT' THEN
            IF days < 22 AND days > 0 THEN
                dateIsValid = true;
            ELSE
                RAISE NOTICE 'Date range is invalid for role type of: %', clientRole;
                dateIsValid = false;
            END IF;
        END IF;
        RETURN dateIsValid;
    END;
$$ language plpgsql;

CREATE TABLE book_orders(
    id SERIAL PRIMARY KEY NOT NULL,
    clientId integer REFERENCES client(id) NOT NULL,
    isbn integer REFERENCES book_instances(isbn) NOT NULL,
    fromDate date NOT NULL,
    toDate date NOT NULL,
    CHECK ( isBookAvailable(isbn) ),
    CHECK ( checkBookCapacityPrivileges( clientId ) ),
    CHECK ( checkDatePrivileges(clientId, fromDate, toDate) )
);

/* Procedures */
CREATE OR REPLACE FUNCTION remove_book_from_the_shelf()
RETURNS TRIGGER as $$
    DECLARE
        bookType type_t;
        bookId integer;
    BEGIN
        RAISE NOTICE 'Book instance with id: %', new.isbn;
        RAISE NOTICE 'has been rented.';
        SELECT type into bookType FROM book_instances where isbn = new.isbn;
        SELECT bookTypeId into bookId FROM book_instances where isbn = new.isbn;
        IF bookType = 'PRINTED_BOOK' THEN
            UPDATE stockings SET printed_copies = printed_copies - 1 WHERE id = bookId;
            UPDATE book_instances SET availability = false, location = 'AT_CLIENT' WHERE isbn = new.isbn;
        END IF;
        IF bookType = 'ELECTRONIC_BOOK' THEN
            UPDATE stockings SET electronic_copies = electronic_copies - 1 WHERE id = bookId;
            UPDATE book_instances SET availability = false, location = 'AT_CLIENT' WHERE isbn = new.isbn;
        END IF;
        RETURN NEW;
    END;
    $$ language plpgsql;

CREATE OR REPLACE FUNCTION put_book_on_the_shelf()
RETURNS TRIGGER as $$
    DECLARE
        bookType type_t;
        bookId integer;
    BEGIN
        RAISE NOTICE 'Order is being deleted...';
        RAISE NOTICE 'Storing book instance with id: %', old.isbn;
        RAISE NOTICE 'back into the database.';
        SELECT type into bookType FROM book_instances where isbn = old.isbn;
        SELECT bookTypeId into bookId FROM book_instances where isbn = old.isbn;
        IF bookType = 'PRINTED_BOOK' THEN
            UPDATE stockings SET printed_copies = printed_copies + 1 WHERE id = bookId;
        END IF;
        IF bookType = 'ELECTRONIC_BOOK' THEN
            UPDATE stockings SET electronic_copies = electronic_copies + 1 WHERE id = bookId;
        END IF;
        RETURN NEW;
    END;
    $$ language plpgsql;

CREATE OR REPLACE FUNCTION update_amount_of_copies()
RETURNS TRIGGER as $$
    DECLARE
        isCreated boolean;
    BEGIN
        RAISE NOTICE 'Book type available for book: %', new.bookTypeId;
        RAISE NOTICE 'Updating stockings...';
        SELECT EXISTS(SELECT * from stockings WHERE id = new.bookTypeId) into isCreated;
        IF new.type = 'PRINTED_BOOK' THEN
            IF isCreated = true THEN
                UPDATE stockings SET printed_copies = printed_copies + 1 WHERE id = new.bookTypeId;
            END IF;
            IF isCreated = false THEN
                INSERT INTO stockings(id, electronic_copies, printed_copies) VALUES (new.bookTypeId, 0, 1);
            END IF;
        END IF;
        IF new.type = 'ELECTRONIC_BOOK' THEN
            IF isCreated = true THEN
                UPDATE stockings SET electronic_copies = electronic_copies + 1 WHERE id = new.bookTypeId;
            END IF;
            IF isCreated = false THEN
                INSERT INTO stockings(id, electronic_copies, printed_copies) VALUES (new.bookTypeId, 1, 0);
            END IF;
        END IF;
        RETURN NEW;
    END;
    $$ language plpgsql;

CREATE TRIGGER add_booking_order
    AFTER INSERT ON book_orders
    FOR EACH ROW
    EXECUTE PROCEDURE remove_book_from_the_shelf();

CREATE TRIGGER delete_booking_order
    AFTER DELETE ON book_orders
    FOR EACH ROW
    EXECUTE PROCEDURE put_book_on_the_shelf();

CREATE TRIGGER update_amount_of_copies
    AFTER INSERT ON book_instances
    FOR EACH ROW
    EXECUTE PROCEDURE update_amount_of_copies();
