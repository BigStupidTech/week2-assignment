-- Small library database. Enable foreign keys on every connection.
PRAGMA foreign_keys = ON;

CREATE TABLE books (
    book_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL CHECK (length(trim(title)) > 0),
    authors TEXT NOT NULL,
    subject TEXT,
    isbn TEXT,
    publication_year INTEGER,
    language TEXT,
    edition TEXT
);

CREATE TABLE book_copies (
    copy_id INTEGER PRIMARY KEY,
    book_id INTEGER NOT NULL REFERENCES books(book_id),
    barcode TEXT NOT NULL UNIQUE,
    shelf_location TEXT NOT NULL,
    condition TEXT NOT NULL DEFAULT 'good'
        CHECK (condition IN ('good', 'worn', 'damaged')),
    status TEXT NOT NULL DEFAULT 'in_service'
        CHECK (status IN ('in_service', 'repair', 'missing', 'withdrawn')),
    acquired_on TEXT,
    acquisition_method TEXT CHECK (acquisition_method IN ('purchase', 'donation')),
    notes TEXT
);

CREATE TABLE members (
    member_id INTEGER PRIMARY KEY,
    card_number TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL CHECK (length(trim(name)) > 0),
    email TEXT,
    phone TEXT,
    active INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0, 1)),
    CHECK (length(trim(coalesce(email, ''))) > 0 OR
           length(trim(coalesce(phone, ''))) > 0)
);

CREATE TABLE loans (
    loan_id INTEGER PRIMARY KEY,
    copy_id INTEGER NOT NULL REFERENCES book_copies(copy_id),
    member_id INTEGER NOT NULL REFERENCES members(member_id),
    borrowed_on TEXT NOT NULL DEFAULT (date('now')),
    due_on TEXT NOT NULL,
    returned_on TEXT,
    renewal_count INTEGER NOT NULL DEFAULT 0 CHECK (renewal_count >= 0),
    last_reminded_on TEXT,
    CHECK (due_on >= borrowed_on),
    CHECK (returned_on IS NULL OR returned_on >= borrowed_on)
);
CREATE UNIQUE INDEX one_open_loan_per_copy ON loans(copy_id)
    WHERE returned_on IS NULL;
CREATE INDEX loans_by_member ON loans(member_id);

CREATE TABLE reservations (
    reservation_id INTEGER PRIMARY KEY,
    book_id INTEGER NOT NULL REFERENCES books(book_id),
    member_id INTEGER NOT NULL REFERENCES members(member_id),
    requested_at TEXT NOT NULL DEFAULT (datetime('now')),
    status TEXT NOT NULL DEFAULT 'waiting'
        CHECK (status IN ('waiting', 'ready', 'fulfilled', 'cancelled', 'expired')),
    notified_at TEXT,
    collect_by TEXT
);
CREATE UNIQUE INDEX one_active_reservation ON reservations(book_id, member_id)
    WHERE status IN ('waiting', 'ready');
CREATE INDEX reservation_queue ON reservations(book_id, requested_at, reservation_id);

CREATE TRIGGER check_checkout BEFORE INSERT ON loans
WHEN NEW.returned_on IS NULL
BEGIN
    SELECT CASE WHEN NOT EXISTS (
        SELECT 1 FROM book_copies WHERE copy_id = NEW.copy_id
        AND status = 'in_service' AND condition <> 'damaged'
    ) THEN RAISE(ABORT, 'This copy is not lendable') END;
    SELECT CASE WHEN NOT EXISTS (
        SELECT 1 FROM members WHERE member_id = NEW.member_id AND active = 1
    ) THEN RAISE(ABORT, 'Member must be active') END;
END;

CREATE TRIGGER check_renewal BEFORE UPDATE OF due_on ON loans
WHEN NEW.due_on > OLD.due_on
BEGIN
    SELECT CASE WHEN OLD.returned_on IS NOT NULL
        THEN RAISE(ABORT, 'Cannot renew a returned loan') END;
    SELECT CASE WHEN EXISTS (
        SELECT 1 FROM reservations r JOIN book_copies c ON c.book_id = r.book_id
        WHERE c.copy_id = OLD.copy_id AND r.member_id <> OLD.member_id
        AND r.status IN ('waiting', 'ready')
    ) THEN RAISE(ABORT, 'Another member is waiting for this book') END;
END;

CREATE TRIGGER count_renewal AFTER UPDATE OF due_on ON loans
WHEN NEW.due_on > OLD.due_on
BEGIN
    UPDATE loans SET renewal_count = OLD.renewal_count + 1
    WHERE loan_id = NEW.loan_id;
END;

CREATE VIEW copy_availability AS
SELECT c.copy_id, c.barcode, b.title, b.authors, c.shelf_location,
       c.condition,
       CASE WHEN c.status <> 'in_service' THEN c.status
            WHEN c.condition = 'damaged' THEN 'damaged'
            WHEN EXISTS (SELECT 1 FROM loans l WHERE l.copy_id = c.copy_id
                         AND l.returned_on IS NULL) THEN 'on_loan'
            ELSE 'available' END AS availability
FROM book_copies c JOIN books b ON b.book_id = c.book_id;

CREATE VIEW overdue_loans AS
SELECT l.loan_id, m.name, m.email, m.phone, b.title, c.barcode, l.due_on
FROM loans l JOIN members m ON m.member_id = l.member_id
JOIN book_copies c ON c.copy_id = l.copy_id
JOIN books b ON b.book_id = c.book_id
WHERE l.returned_on IS NULL AND l.due_on < date('now', 'localtime');

-- A tape row represents one physical VHS tape, kept for in-library screenings.
CREATE TABLE vhs_tapes (
    tape_id INTEGER PRIMARY KEY,
    barcode TEXT NOT NULL UNIQUE,
    title TEXT NOT NULL,
    release_year INTEGER,
    runtime_minutes INTEGER CHECK (runtime_minutes > 0),
    age_rating TEXT,
    shelf_location TEXT,
    condition TEXT NOT NULL DEFAULT 'good'
        CHECK (condition IN ('good', 'worn', 'damaged')),
    notes TEXT
);

CREATE TABLE event_series (
    series_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    weekday INTEGER CHECK (weekday BETWEEN 0 AND 6), -- Sunday=0, Friday=5
    usual_start_time TEXT,
    location TEXT
);

CREATE TABLE events (
    event_id INTEGER PRIMARY KEY,
    series_id INTEGER REFERENCES event_series(series_id),
    name TEXT NOT NULL,
    starts_at TEXT NOT NULL, -- local date and time: YYYY-MM-DD HH:MM
    location TEXT NOT NULL,
    tape_id INTEGER REFERENCES vhs_tapes(tape_id),
    capacity INTEGER CHECK (capacity > 0),
    status TEXT NOT NULL DEFAULT 'planned'
        CHECK (status IN ('planned', 'completed', 'cancelled')),
    notes TEXT
);

CREATE TABLE event_signups (
    event_id INTEGER NOT NULL REFERENCES events(event_id),
    member_id INTEGER NOT NULL REFERENCES members(member_id),
    signed_up_at TEXT NOT NULL DEFAULT (datetime('now')),
    attended INTEGER NOT NULL DEFAULT 0 CHECK (attended IN (0, 1)),
    PRIMARY KEY (event_id, member_id)
);

CREATE TRIGGER check_event_signup BEFORE INSERT ON event_signups
BEGIN
    SELECT CASE WHEN EXISTS (
        SELECT 1 FROM events WHERE event_id = NEW.event_id AND status <> 'planned'
    ) THEN RAISE(ABORT, 'Event is not open for signups') END;
    SELECT CASE WHEN (
        SELECT count(*) FROM event_signups WHERE event_id = NEW.event_id
    ) >= (SELECT capacity FROM events WHERE event_id = NEW.event_id)
    THEN RAISE(ABORT, 'Event is full') END;
END;

INSERT INTO event_series (name, description, weekday, usual_start_time, location)
VALUES ('Friday Night VHS Club',
        'A cozy Friday movie night: a VHS tape, popcorn, and a little time to talk about the movie afterward. Remember to rewind.',
        5, '19:00', 'Library reading room');
