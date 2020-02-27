INSERT into book_orders(clientId, isbn, fromDate, toDate, status) VALUES (1, 1, '2021-02-01', '2021-02-06', 'ONGOING');
INSERT into book_orders(clientId, isbn, fromDate, toDate, status) VALUES (2, 1, '2021-02-01', '2021-02-06', 'ONGOING');
UPDATE book_orders SET status = 'FINISHED' WHERE isbn = 1;

UPDATE book_orders SET status = 'FINISHED' WHERE isbn = 5;