![Library database ERD](erd.png)

# Library database summary

My library is mostly about borrowing books, but I also wanted Friday night VHS movies. Just something fun where people can come in, have popcorn and watch an old movie.

The books table has the titles and authors. book_copies is for the copies we actually own and where they are. members has peoples names and contact details. loans keeps track of who took a copy, when its due and if it came back. reservations is the waiting list for books.

Then there is vhs_tapes for the movie tapes. event_series is the regular movie club, and events is each individual movie night. event_signups tells us who signed up and whether they came. So we can have people who only come for movies too.

One book can have many copies. One member can have many loans. These are one-to-many relationships, connected by IDs. Foreign keys point back to the right record. Members and events are many-to-many, because people can attend several nights and each night has several people. event_signups connects them. loans connects members and copies over time, and reservations connects members and book titles.

I separated books from copies because having a title doesn't tell us how many are on the shelf. If one copy is borrowed, another might still be there. Each copy gets its own barcode. We also block two open loans for the same copy.

One thing we changed was movie night. At first it was just a club idea. We then added actual example dates and signups so we could tell who came. June in the made-up data has never borrowed anything, but comes to movies. I think that makes sense for a small library.

## Mermaid source

```mermaid
erDiagram
    direction LR
    book_copies {
        INTEGER copy_id PK "required"
        INTEGER book_id FK "required"
        TEXT barcode UK "required"
        TEXT shelf_location "required"
        TEXT condition "required"
        TEXT status "required"
        TEXT acquired_on "nullable"
        TEXT acquisition_method "nullable"
        TEXT notes "nullable"
    }
    books ||..o{ book_copies : "book_id"
    books {
        INTEGER book_id PK "required"
        TEXT title "required"
        TEXT authors "required"
        TEXT subject "nullable"
        TEXT isbn "nullable"
        INTEGER publication_year "nullable"
        TEXT language "nullable"
        TEXT edition "nullable"
    }
    event_series {
        INTEGER series_id PK "required"
        TEXT name "required"
        TEXT description "nullable"
        INTEGER weekday "nullable"
        TEXT usual_start_time "nullable"
        TEXT location "nullable"
    }
    event_signups {
        INTEGER event_id PK, FK "required"
        INTEGER member_id PK, FK "required"
        TEXT signed_up_at "required"
        INTEGER attended "required"
    }
    members ||--o{ event_signups : "member_id"
    events ||--o{ event_signups : "event_id"
    events {
        INTEGER event_id PK "required"
        INTEGER series_id FK "nullable"
        TEXT name "required"
        TEXT starts_at "required"
        TEXT location "required"
        INTEGER tape_id FK "nullable"
        INTEGER capacity "nullable"
        TEXT status "required"
        TEXT notes "nullable"
    }
    vhs_tapes |o..o{ events : "tape_id"
    event_series |o..o{ events : "series_id"
    loans {
        INTEGER loan_id PK "required"
        INTEGER copy_id FK "required"
        INTEGER member_id FK "required"
        TEXT borrowed_on "required"
        TEXT due_on "required"
        TEXT returned_on "nullable"
        INTEGER renewal_count "required"
        TEXT last_reminded_on "nullable"
    }
    members ||..o{ loans : "member_id"
    book_copies ||..o{ loans : "copy_id"
    members {
        INTEGER member_id PK "required"
        TEXT card_number UK "required"
        TEXT name "required"
        TEXT email "nullable"
        TEXT phone "nullable"
        INTEGER active "required"
    }
    reservations {
        INTEGER reservation_id PK "required"
        INTEGER book_id FK "required"
        INTEGER member_id FK "required"
        TEXT requested_at "required"
        TEXT status "required"
        TEXT notified_at "nullable"
        TEXT collect_by "nullable"
    }
    members ||..o{ reservations : "member_id"
    books ||..o{ reservations : "book_id"
    vhs_tapes {
        INTEGER tape_id PK "required"
        TEXT barcode UK "required"
        TEXT title "required"
        INTEGER release_year "nullable"
        INTEGER runtime_minutes "nullable"
        TEXT age_rating "nullable"
        TEXT shelf_location "nullable"
        TEXT condition "required"
        TEXT notes "nullable"
    }
```
