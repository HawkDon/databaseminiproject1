INSERT into book_orders(clientId, isbn, fromDate, toDate, status) VALUES (1, 1, '2021-02-01', '2021-02-06', 'ONGOING');
INSERT into book_orders(clientId, isbn, fromDate, toDate, status) VALUES (1, 2, '2021-02-01', '2021-02-06', 'ONGOING');
INSERT into book_orders(clientId, isbn, fromDate, toDate, status) VALUES (1, 3, '2021-02-01', '2021-02-06', 'ONGOING');
INSERT into book_orders(clientId, isbn, fromDate, toDate, status) VALUES (1, 4, '2021-02-01', '2021-02-06', 'ONGOING');

INSERT into book_orders(clientId, isbn, fromDate, toDate, status) VALUES (3, 5, '2021-02-01', '2021-02-08', 'ONGOING');
INSERT into book_orders(clientId, isbn, fromDate, toDate, status) VALUES (3, 6, '2021-02-01', '2021-02-09', 'ONGOING');

UPDATE book_orders SET status = 'FINISHED' WHERE isbn = 1;

UPDATE book_orders SET status = 'FINISHED' WHERE isbn = 5;