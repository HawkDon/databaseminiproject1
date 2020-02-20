/* Clients */
INSERT INTO client(role) VALUES ('STUDENT');
INSERT INTO client(role) VALUES ('TEACHER');
INSERT INTO client(role) VALUES ('NORMAL');

/* Publishers */
INSERT INTO publisher(name) VALUES ('Bloomsbury');
INSERT INTO publisher(name) VALUES ('The Pragmatic Programmers');
INSERT INTO publisher(name) VALUES ('Prentice Hall');
INSERT INTO publisher(name) VALUES ('TOM BADGETT');
INSERT INTO publisher(name) VALUES ('C.A. Reitzel');
INSERT INTO publisher(name) VALUES ('Packt');
INSERT INTO publisher(name) VALUES ('OXFORD');
INSERT INTO publisher(name) VALUES ('No Starch Press');
INSERT INTO publisher(name) VALUES ('CreateSpace Independent Publishing Platform');
INSERT INTO publisher(name) VALUES ('Hanning');
INSERT INTO publisher(name) VALUES ('Addson-Wesley Professional Computing Series');

/* Authors */
INSERT INTO author(name) VALUES ('J.K. Rowling');
INSERT INTO author(name) VALUES ('Luc Perkins');
INSERT INTO author(name) values ('Robert C. Martin');
INSERT INTO author(name) values ('Glenford Myers');
INSERT INTO author(name) values ('H.C. Andersen');
INSERT INTO author(name) values ('Chandra Sekhar Nayak');
INSERT INTO author(name) values ('Andrew Davies');
INSERT INTO author(name) values ('Steve Klabnik');
INSERT INTO author(name) values ('Oscar Levin');
INSERT INTO author(name) values ('Dmitry Jemerov');
INSERT INTO author(name) values ('John Lakos');

/* Books */
INSERT INTO book(title, author, publisher, year) VALUES ('Harry Potter and the philosophers stone', 1, 1, '1997-06-26');
INSERT INTO book(title, author, publisher, year) VALUES ('Harry Potter and the chamber of secrets', 1, 1, '1998-07-02');
INSERT INTO book(title, author, publisher, year) VALUES ('Harry Potter and the prisoner of azkaban', 1, 1, '1999-07-08');
INSERT INTO book(title, author, publisher, year) VALUES ('Harry Potter and the goblet of fire', 1, 1, '2000-07-08');
INSERT INTO book(title, author, publisher, year) VALUES ('Harry Potter and the order of the phoenix', 1, 1, '2003-06-21');
INSERT INTO book(title, author, publisher, year) VALUES ('Harry Potter and the half blood prince', 1, 1, '2005-07-16');
INSERT INTO book(title, author, publisher, year) VALUES ('Harry Potter and the deathly hallows', 1, 1, '2007-07-21');
INSERT INTO book(title, author, publisher, year) VALUES ('The Ugly Duckling', 5, 5, '1843-11-11');
INSERT INTO book(title, author, publisher, year) VALUES ('The Little Mermaid', 5, 5, '1837-04-07');
INSERT INTO book(title, author, publisher, year) VALUES ('The Snow Queen', 5, 5, '1844-12-21');
INSERT INTO book(title, author, publisher, year) VALUES ('The Tinderbox', 5, 5, '1835-05-08');
INSERT INTO book(title, author, publisher, year) VALUES ('Hands-On Data structures and Algorithms with Kotlin', 6, 6, '2019-02-28');
INSERT INTO book(title, author, publisher, year) VALUES ('The Business of Systems Integration', 7, 7, '2019-02-28');
INSERT INTO book(title, author, publisher, year) VALUES ('The Rust Programming language', 8, 8, '2018-01-02');
INSERT INTO book(title, author, publisher, year) VALUES ('Discreet Mathematics', 8, 8, '2015-08-15');
INSERT INTO book(title, author, publisher, year) VALUES ('Kotlin in action', 9, 9, '2015-08-15');
INSERT INTO book(title, author, publisher, year) VALUES ('Seven databases in seven weeks', 2, 2, '2012-05-11');
INSERT INTO book(title, author, publisher, year) VALUES ('Clean Code', 3, 3, '2008-08-01');
INSERT INTO book(title, author, publisher, year) VALUES ('The Art of Software Testing', 4, 4, '1979-05-14');
INSERT INTO book(title, author, publisher, year) VALUES ('Large-Scale C++ Software Design', 10, 10, '1979-05-14');

/* Book Instances */
INSERT INTO book_instances(booktypeid, type) VALUES (1, 'ELECTRONIC_BOOK');
INSERT INTO book_instances(booktypeid, type, rarity) VALUES (1, 'PRINTED_BOOK', 'RARE');
INSERT INTO book_instances(booktypeid, type) VALUES (2, 'ELECTRONIC_BOOK');
INSERT INTO book_instances(booktypeid, type) VALUES (2, 'PRINTED_BOOK');
INSERT INTO book_instances(booktypeid, type) VALUES (3, 'ELECTRONIC_BOOK');
INSERT INTO book_instances(booktypeid, type, rarity) VALUES (3, 'PRINTED_BOOK', 'RARE');
INSERT INTO book_instances(booktypeid, type) VALUES (4, 'ELECTRONIC_BOOK');
INSERT INTO book_instances(booktypeid, type) VALUES (4, 'PRINTED_BOOK');
INSERT INTO book_instances(booktypeid, type) VALUES (5, 'ELECTRONIC_BOOK');
INSERT INTO book_instances(booktypeid, type, rarity) VALUES (5, 'PRINTED_BOOK', 'RARE');
INSERT INTO book_instances(booktypeid, type) VALUES (6, 'ELECTRONIC_BOOK');
INSERT INTO book_instances(booktypeid, type) VALUES (6, 'PRINTED_BOOK');

/* Orders */
INSERT into book_orders(clientId, isbn, fromDate, toDate) VALUES (1, 3, '2021-02-01', '2021-02-06');
INSERT into book_orders(clientId, isbn, fromDate, toDate) VALUES (2, 4, '2021-02-01', '2021-02-06');
INSERT into book_orders(clientId, isbn, fromDate, toDate) VALUES (3, 5, '2021-02-01', '2021-02-06');