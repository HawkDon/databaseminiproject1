/* Cleanup */
DROP TABLE IF EXISTS book_orders;
DROP TABLE IF EXISTS client;
DROP TABLE IF EXISTS book;
DROP TABLE IF EXISTS author;
DROP TABLE IF EXISTS publisher;

DROP FUNCTION IF EXISTS isBookAvailable(a integer);
DROP FUNCTION IF EXISTS remove_book_from_the_shelf();
DROP FUNCTION IF EXISTS put_book_back_on_the_shelf();

DROP TYPE IF EXISTS rarity_t;
DROP TYPE IF EXISTS roles_t;
DROP TYPE IF EXISTS type_t;

/* Enums */
create type rarity_t as enum ('RARE', 'NORMAL');
create type roles_t as enum ('STUDENT', 'NORMAL', 'TEACHER');
create type type_t as enum('PRINTED_BOOK', 'ELECTRONIC_BOOK');

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
    book integer REFERENCES book(id),
    type type_t NOT NULL,
    rarity rarity_t DEFAULT 'NORMAL' NOT NULL
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
        getType type_t;
        getBookId integer;
    BEGIN
        SELECT type into getType FROM book_instances WHERE isbn = isbnId;
        SELECT book into getBookId FROM book_instances WHERE isbn = isbnId;
        IF getType = 'PRINTED_BOOK' THEN
            SELECT printed_copies into p_copies from stockings where id = getBookId;
            IF p_copies = 0 THEN
                RAISE NOTICE 'The book with type printed is not available';
                isAvailable = false;
            END IF;
            IF p_copies > 0 THEN
                RAISE NOTICE 'The book with type printed is available';
                isAvailable = true;
            END IF;
        END IF;
        IF getType = 'ELECTRONIC_BOOK' THEN
            SELECT electronic_copies into e_copies from stockings where id = getBookId;
            IF e_copies = 0 THEN
                RAISE NOTICE 'The book with type electronic is not available';
                isAvailable = false;
            END IF;
            IF e_copies > 0 THEN
                RAISE NOTICE 'The book with type electronic is available';
                isAvailable = true;
            END IF;
        END IF;
        RETURN isAvailable;
    END;
$$ LANGUAGE plpgsql;

CREATE TABLE book_orders(
    id SERIAL PRIMARY KEY,
    clientId integer REFERENCES client(id),
    bookId integer REFERENCES book_instances(isbn),
    fromDate date NOT NULL,
    toDate date NOT NULL,
    CHECK ( isBookAvailable(bookId) )
);

/* Procedures */
CREATE OR REPLACE FUNCTION remove_book_from_the_shelf()
RETURNS TRIGGER as $$
    DECLARE
        getType type_t;
        getBookId integer;
    BEGIN
        RAISE NOTICE 'Book rented with booking id: %', new.bookId;
        SELECT type into getType FROM book_instances where isbn = new.bookId;
        SELECT book into getBookId FROM book_instances where isbn = new.bookId;
        IF getType = 'PRINTED_BOOK' THEN
            UPDATE stockings SET printed_copies = printed_copies - 1 WHERE id = getBookId;
        END IF;
        IF getType = 'ELECTRONIC_BOOK' THEN
            UPDATE stockings SET electronic_copies = electronic_copies - 1 WHERE id = getBookId;
        END IF;
        RETURN NEW;
    END;
    $$ language plpgsql;

CREATE OR REPLACE FUNCTION put_book_back_on_the_shelf()
RETURNS TRIGGER as $$
    DECLARE
        getType type_t;
        getBookId integer;
    BEGIN
        RAISE NOTICE 'Order deleted with booking id: %', old.bookId;
        SELECT type into getType FROM book_instances where isbn = old.bookId;
        SELECT book into getBookId FROM book_instances where isbn = old.bookId;
        IF getType = 'PRINTED_BOOK' THEN
            UPDATE stockings SET printed_copies = printed_copies + 1 WHERE id = getBookId;
        END IF;
        IF getType = 'ELECTRONIC_BOOK' THEN
            UPDATE stockings SET electronic_copies = electronic_copies + 1 WHERE id = getBookId;
        END IF;
        RETURN NEW;
    END;
    $$ language plpgsql;

CREATE OR REPLACE FUNCTION update_amount_of_copies()
RETURNS TRIGGER as $$
    DECLARE
        isCreated boolean;
    BEGIN
        RAISE NOTICE 'Book Instance available of book: %', new.book;
        SELECT EXISTS(SELECT * from stockings WHERE id = new.book) into isCreated;
        IF new.type = 'PRINTED_BOOK' THEN
            IF isCreated = true THEN
                UPDATE stockings SET printed_copies = printed_copies + 1 WHERE id = new.book;
            END IF;
            IF isCreated = false THEN
                INSERT INTO stockings(id, electronic_copies, printed_copies) VALUES (new.book, 0, 1);
            END IF;
        END IF;
        IF new.type = 'ELECTRONIC_BOOK' THEN
            IF isCreated = true THEN
                UPDATE stockings SET electronic_copies = electronic_copies + 1 WHERE id = new.book;
            END IF;
            IF isCreated = false THEN
                INSERT INTO stockings(id, electronic_copies, printed_copies) VALUES (new.book, 1, 0);
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
    EXECUTE PROCEDURE put_book_back_on_the_shelf();

CREATE TRIGGER update_amount_of_copies
    AFTER INSERT ON book_instances
    FOR EACH ROW
    EXECUTE PROCEDURE update_amount_of_copies();
