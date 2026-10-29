-- Fictional assignment examples. Current/overdue examples are relative to 2026-10-28.
-- Run once after importing the books. All members, inventory, and movie titles here are fictional.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;
INSERT INTO members(member_id,card_number,name,email) VALUES
(1,'DEMO-001','Nora Bennett','nora.bennett@example.invalid'),
(2,'DEMO-002','Eli Parker','eli.parker@example.invalid'),
(3,'DEMO-003','Maya Flores','maya.flores@example.invalid'),
(4,'DEMO-004','Owen Brooks','owen.brooks@example.invalid'),
(5,'DEMO-005','June Carter','june.carter@example.invalid'),
(6,'DEMO-006','Theo Reed','theo.reed@example.invalid');

INSERT INTO book_copies(copy_id,book_id,barcode,shelf_location,acquired_on,acquisition_method,notes) VALUES
(1,1,'DEMO-B001','Fiction A1','2026-09-01','purchase','Fictional assignment inventory'),
(2,2,'DEMO-B002','Fiction A1','2026-09-01','donation','Fictional assignment inventory'),
(3,3,'DEMO-B003','Fiction A1','2026-09-01','purchase','Fictional assignment inventory'),
(4,4,'DEMO-B004','Fiction A2','2026-09-01','donation','Fictional assignment inventory'),
(5,5,'DEMO-B005','Fiction A2','2026-09-01','purchase','Fictional assignment inventory'),
(6,6,'DEMO-B006','Fiction A2','2026-09-01','donation','Fictional assignment inventory'),
(7,7,'DEMO-B007','Fantasy B1','2026-09-01','purchase','Fictional assignment inventory'),
(8,8,'DEMO-B008','Fiction A3','2026-09-01','donation','Fictional assignment inventory'),
(9,9,'DEMO-B009','Mystery C1','2026-09-01','purchase','Fictional assignment inventory'),
(10,10,'DEMO-B010','Classics D1','2026-09-01','donation','Fictional assignment inventory');

INSERT INTO loans(loan_id,copy_id,member_id,borrowed_on,due_on,returned_on) VALUES
(1,1,1,'2026-09-02','2026-09-16','2026-09-12'),
(2,2,2,'2026-09-03','2026-09-17','2026-09-17'),
(3,3,3,'2026-09-04','2026-09-18','2026-09-20'),
(4,4,4,'2026-09-05','2026-09-19','2026-09-18'),
(5,5,1,'2026-09-08','2026-09-22','2026-09-21'),
(6,6,2,'2026-09-10','2026-09-24','2026-09-23'),
(7,7,3,'2026-09-12','2026-09-26','2026-09-25'),
(8,8,4,'2026-09-15','2026-09-29','2026-09-29'),
(9,1,1,'2026-10-05','2026-10-19',NULL),
(10,7,2,'2026-10-10','2026-10-24',NULL),
(11,9,3,'2026-10-23','2026-11-06',NULL),
(12,10,4,'2026-10-26','2026-11-09',NULL);

INSERT INTO vhs_tapes(tape_id,barcode,title,release_year,runtime_minutes,shelf_location,notes) VALUES
(1,'DEMO-V001','The Last Video Store',1991,94,'VHS shelf 1','Invented movie and tape for assignment'),
(2,'DEMO-V002','Moonlight at Maple Lake',1987,88,'VHS shelf 1','Invented movie and tape for assignment'),
(3,'DEMO-V003','The Popcorn Detectives',1994,102,'VHS shelf 1','Invented movie and tape for assignment'),
(4,'DEMO-V004','A Robot for the Weekend',1989,96,'VHS shelf 2','Invented movie and tape for assignment'),
(5,'DEMO-V005','The Haunted Rewind Button',1993,90,'VHS shelf 2','Invented movie and tape for assignment');

-- Insert as planned so signups can be added, then mark past screenings completed.
INSERT INTO events(event_id,series_id,name,starts_at,location,tape_id,capacity,notes) VALUES
(1,1,'Friday VHS: The Last Video Store','2026-10-02 19:00','Library reading room',1,12,'Fictional screening. Popcorn and a chat afterward.'),
(2,1,'Friday VHS: Moonlight at Maple Lake','2026-10-09 19:00','Library reading room',2,12,'Fictional screening. Bring a cozy sweater.'),
(3,1,'Friday VHS: The Popcorn Detectives','2026-10-16 19:00','Library reading room',3,12,'Fictional screening. Guess the ending before the credits.'),
(4,1,'Friday VHS: A Robot for the Weekend','2026-10-23 19:00','Library reading room',4,12,'Fictional screening. Remember to rewind.'),
(5,1,'Friday VHS: The Haunted Rewind Button','2026-10-30 19:00','Library reading room',5,3,'Fictional upcoming Halloween screening. Small group; all three seats booked.');
INSERT INTO event_signups(event_id,member_id,signed_up_at,attended) VALUES
(1,1,'2026-09-28 15:00:00',1),
(1,2,'2026-09-29 16:00:00',1),
(1,5,'2026-09-30 17:00:00',0),
(2,3,'2026-10-05 15:00:00',1),
(2,4,'2026-10-06 16:00:00',1),
(2,5,'2026-10-07 17:00:00',1),
(3,1,'2026-10-12 15:00:00',1),
(3,3,'2026-10-13 16:00:00',0),
(4,2,'2026-10-19 15:00:00',1),
(4,5,'2026-10-20 16:00:00',1),
(5,1,'2026-10-25 15:00:00',0),
(5,3,'2026-10-26 16:00:00',0),
(5,5,'2026-10-27 17:00:00',0);
UPDATE events SET status='completed' WHERE event_id IN (1,2,3,4);
COMMIT;
