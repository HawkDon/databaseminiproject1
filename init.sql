/* Cleanup */
DROP VIEW IF EXISTS get_most_popular_titles;
DROP VIEW IF EXISTS get_current_availability;

DROP TABLE IF EXISTS book_orders;
DROP TABLE IF EXISTS client;
DROP TABLE IF EXISTS stockings;
DROP TABLE IF EXISTS book_instances;
DROP TABLE IF EXISTS book;
DROP TABLE IF EXISTS author;
DROP TABLE IF EXISTS publisher;

DROP TRIGGER IF EXISTS add_booking_order ON book_orders;
DROP TRIGGER IF EXISTS insert_book_stock_rent ON book_instances;
DROP TRIGGER IF EXISTS update_book_stock_rent ON book_orders;

DROP FUNCTION IF EXISTS checkDatePrivileges(client_id integer, from_date date, to_date date);
DROP FUNCTION IF EXISTS remove_book_from_the_shelf();
DROP FUNCTION If EXISTS insert_book_stock_rent();
DROP FUNCTION If EXISTS update_book_stock_rent();

DROP TYPE IF EXISTS rarity_t;
DROP TYPE IF EXISTS roles_t;
DROP TYPE IF EXISTS type_t;
DROP TYPE IF EXISTS location_t;
DROP TYPE IF EXISTS status_t;
DROP TYPE IF EXISTS orderStatus_t;

/* Enums */
create type rarity_t as enum ('RARE', 'NORMAL');
create type roles_t as enum ('STUDENT', 'NORMAL', 'TEACHER');
create type type_t as enum('PRINTED_BOOK', 'ELECTRONIC_BOOK');
create type location_t as enum('AT_LIBRARY', 'AT_CLIENT');
create type status_t as enum('AVAILABLE', 'NOT_AVAILABLE');
create type orderStatus_t as enum('ONGOING', 'FINISHED', 'DELAYED');

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
    status status_t DEFAULT 'AVAILABLE' NOT NULL,
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
    status orderStatus_t NOT NULL,
    CHECK ( checkDatePrivileges(clientId, fromDate, toDate) )
);

/* Procedures */
CREATE OR REPLACE FUNCTION remove_book_from_the_shelf()
RETURNS TRIGGER as $$
    DECLARE
        e_copies integer;
        p_copies integer;
        bookType type_t;
        bookId integer;
        roleOfClient roles_t;
        amountOfOrders integer;
    BEGIN
        SELECT role into roleOfClient FROM client WHERE id = new.clientId;
        SELECT count(*) into amountOfOrders FROM book_orders WHERE clientId = new.clientId AND current_date < toDate and status = 'ONGOING';
            IF roleOfClient = 'NORMAL' THEN
            IF amountOfOrders > 1 THEN
                ROLLBACK;
            END IF;
        END IF;
        IF roleOfClient = 'TEACHER' THEN
            IF amountOfOrders > 2 THEN
                ROLLBACK;
            END IF;
        END IF;
        IF roleOfClient = 'STUDENT' THEN
            IF amountOfOrders > 3 THEN
                ROLLBACK;
            END IF;
        END IF;
        SELECT type into bookType FROM book_instances where isbn = new.isbn;
        SELECT bookTypeId into bookId FROM book_instances where isbn = new.isbn;
        IF bookType = 'PRINTED_BOOK' THEN
            SELECT printed_copies into p_copies FROM stockings WHERE id = bookId;
            IF p_copies = 0 THEN
                RAISE NOTICE 'The book with type "PRINTED" is not available';
                ROLLBACK;
            END IF;
            IF p_copies > 0 THEN
                UPDATE stockings SET printed_copies = printed_copies - 1 WHERE id = bookId;
                UPDATE book_instances SET status = 'NOT_AVAILABLE', location = 'AT_CLIENT' WHERE isbn = new.isbn;
            END IF;
        END IF;
        IF bookType = 'ELECTRONIC_BOOK' THEN
                SELECT electronic_copies into e_copies FROM stockings WHERE id = bookId;
            IF e_copies = 0 THEN
                RAISE NOTICE 'The book with type "ELECTRONIC" is not available';
                ROLLBACK;
            END IF;
            IF e_copies > 0 THEN
                UPDATE stockings SET electronic_copies = electronic_copies - 1 WHERE id = bookId;
                UPDATE book_instances SET status = 'NOT_AVAILABLE', location = 'AT_CLIENT' WHERE isbn = new.isbn;
            END IF;
        END IF;
        RAISE NOTICE 'Book instance with id: %', new.isbn;
        RAISE NOTICE 'has been rented.';
        RETURN NEW;
    END;
    $$ language plpgsql;

CREATE OR REPLACE FUNCTION insert_book_stock_rent()
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

CREATE OR REPLACE FUNCTION update_book_stock_rent()
RETURNS TRIGGER as $$
    DECLARE
        bookType type_t;
        bookId integer;
    BEGIN
        RAISE NOTICE 'Updating stockings...';
        SELECT type into bookType FROM book_instances WHERE book_instances.isbn = new.isbn;
        SELECT bookTypeId into bookId FROM book_instances WHERE book_instances.isbn = new.isbn;
        IF bookType = 'PRINTED_BOOK' THEN
            if old.status = 'ONGOING' AND new.status = 'FINISHED' OR new.status = 'DELAYED' THEN
                UPDATE stockings SET printed_copies = printed_copies + 1 WHERE id = bookId;
                UPDATE book_instances SET status = 'AVAILABLE', location = 'AT_LIBRARY' WHERE isbn = new.isbn;
            END IF;
        END IF;
        IF bookType = 'ELECTRONIC_BOOK' THEN
            if old.status = 'ONGOING' AND new.status = 'FINISHED' OR new.status = 'DELAYED' THEN
                UPDATE stockings SET electronic_copies = electronic_copies + 1 WHERE id = bookId;
                UPDATE book_instances SET status = 'AVAILABLE', location = 'AT_LIBRARY' WHERE isbn = new.isbn;
            END IF;
        END IF;
        RETURN NEW;
    END;
    $$ language plpgsql;

CREATE TRIGGER add_booking_order
    AFTER INSERT ON book_orders
    FOR EACH ROW
    EXECUTE PROCEDURE remove_book_from_the_shelf();

CREATE TRIGGER insert_amount_of_copies
    AFTER INSERT ON book_instances
    FOR EACH ROW
    EXECUTE PROCEDURE insert_book_stock_rent();

CREATE TRIGGER update_book_stock_rent
    AFTER UPDATE ON book_orders
    FOR EACH ROW
    EXECUTE PROCEDURE update_book_stock_rent();


/* Views */
/* Get currently availability of a book */
CREATE VIEW get_current_availability AS
SELECT status from book_instances where isbn = 2;
/* Get most popular title by students */
CREATE VIEW get_most_popular_titles AS
SELECT book.title, count(book.title) as most_popular FROM book_orders
INNER JOIN client ON book_orders.clientid = client.id
INNER JOIN book_instances ON book_orders.isbn = book_instances.isbn
INNER JOIN book ON book.id = book_instances.booktypeid
WHERE client.role = 'STUDENT'
AND book_orders.fromdate > '2021-01-25'
AND book_orders.todate < '2021-02-07'
GROUP BY 1
ORDER BY most_popular DESC;
