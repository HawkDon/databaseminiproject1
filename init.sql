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
create type type_t as enum('E_BOOK', 'PHYSICAL_BOOK');

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
    isbn SERIAL PRIMARY KEY NOT NULL,
    title varchar(150) NOT NULL,
    author integer REFERENCES author(id) NOT NULL,
    publisher integer REFERENCES publisher(id) NOT NULL,
    year date NOT NULL,
    rarity rarity_t DEFAULT 'NORMAL' NOT NULL,
    availability boolean NOT NULL,
    type type_t NOT NULL
);

CREATE TABLE client(
    id SERIAL PRIMARY KEY,
    role roles_t NOT NULL
);

/* Checks */
CREATE OR REPLACE FUNCTION isBookAvailable(a integer)
RETURNS boolean as $$
    DECLARE
        isAvailable boolean;
    BEGIN
        SELECT availability into isAvailable from book where isbn = a;
        RETURN isAvailable;
    END;
$$ LANGUAGE plpgsql;

CREATE TABLE book_orders(
    id SERIAL PRIMARY KEY,
    clientId integer REFERENCES client(id),
    bookId integer REFERENCES book(isbn),
    fromDate date NOT NULL,
    toDate date NOT NULL,
    CHECK ( isBookAvailable(bookId) )
);

/* Triggers */
CREATE OR REPLACE FUNCTION remove_book_from_the_shelf()
RETURNS TRIGGER as $$
    BEGIN
        RAISE NOTICE 'Book rented with booking id: %', new.bookId;
        UPDATE book SET availability = false WHERE isbn = new.bookId;
        RETURN NEW;
    END;
    $$ language plpgsql;

CREATE OR REPLACE FUNCTION put_book_back_on_the_shelf()
RETURNS TRIGGER as $$
    BEGIN
        RAISE NOTICE 'Order deleted with booking id: %', old.bookId;
        UPDATE book SET availability = true WHERE isbn = old.bookId;
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