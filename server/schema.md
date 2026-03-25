# Movie Booking System — Database Schema

## Overview

The schema is organized into five logical groups:

- **Users & Theatres** — identity, roles, venue management
- **Movies** — film metadata, cast, supported languages and formats
- **Shows** — scheduled screenings, seat inventory and locking
- **Bookings** — user purchases, tickets, pricing and payments
- **Reviews** — user-generated movie ratings

---

## Entity Flow

```
VENDOR
 └── manages THEATRE
       └── has SCREEN
             ├── contains SEAT
             └── hosts SHOW
                   ├── references MOVIE (language + format validated)
                   ├── has SHOW_SEAT (transient state for active locks/checkouts)
                   └── has SHOW_PRICE (base price per seat type)

USER
 └── makes BOOKING (for a SHOW)
       ├── contains TICKET (linked permanently to SHOW and SEAT)
       └── paid via PAYMENT

USER
 └── writes REVIEW (for a MOVIE)
```

---

## Tables

### USER
| Column    | Type    | Notes                                                    |
|-----------|---------|----------------------------------------------------------|
| id        | uuid    | PK                                                       |
| name      | string  |                                                          |
| email     | string  | unique                                                   |
| password  | string  | hashed                                                   |
| phone     | string  |                                                          |
| role      | enum    | `user`, `admin`, `vendor`                                |
| is_active | boolean | default true — for soft deletes and account deactivation |

---

---
### CITY
| Column | Type   | Notes |
|--------|--------|-------|
| id     | uuid   | PK    |
| name   | string |       |
| state  | string |       |
unique(name, state) — to prevent duplicate city entries
---

### THEATRE
| Column         | Type   | Notes        |
|----------------|--------|--------------|
| id             | uuid   | PK           |
| vendor_id      | uuid   | FK → USER.id |
| name           | string |              |
| building_name  | string |              |
| street_address | string |              |
| city_id        | uuid   | FK → CITY.id |
| pincode        | string |              |

---

### SCREEN
| Column        | Type   | Notes                                          |
|---------------|--------|------------------------------------------------|
| id            | uuid   | PK                                             |
| theatre_id    | uuid   | FK → THEATRE.id                                |
| name          | string | e.g. "Screen 1", "IMAX Hall"                   |
| status        | enum   | `active`, `inactive` — for maintenance etc.    |
| total_rows    | int    |                                                |
| total_columns | int    |                                                |
| total_seats   | int    | derived from SEAT count where is_active = true |

> SCREEN.total_seats must be recomputed whenever SEAT.is_active changes on any seat belonging to that screen. Same as SHOW.total_capacity — snapshot on creation, explicitly recomputed on change.

---

### SCREEN_CAPABILITY
| Column    | Type | Notes                     |
|-----------|------|---------------------------|
| id        | uuid | PK                        |
| screen_id | uuid | FK → SCREEN.id            |
| format_id | uuid | FK → FORMAT.id            |
unique(screen_id, capability)

### SEAT
| Column        | Type    | Notes                                               |
|---------------|---------|-----------------------------------------------------|
| id            | uuid    | PK                                                  |
| screen_id     | uuid    | FK → SCREEN.id                                      |
| type          | enum    | silver, gold, premium, recliner                     |
| label         | string  | derived + stored: row_label + seat_number e.g. B12  |
| is_accessible | boolean | wheelchair-accessible seat                          |
| is_active     | boolean | false = seat exists but disabled (maintenance etc.) |
UNIQUE (screen_id, label)

---
### SEAT_LAYOUT
| Column      | Type  | Notes                                              |
|-------------|-------|----------------------------------------------------|
| id          | uuid  | PK                                                 |
| screen_id   | uuid  | FK → SCREEN.id                                     |
| layout_json | jsonb | stores the seat arrangement as a JSON object, e.g. |

```json
{
  "rows": [
    {
      "row_label": "A",
      "seats": [
        {"x":  0, "y":  1,"seat_number": 1},
        {"x":  0, "y":  2,"seat_number": 2},
        {"x":  0, "y":  3,"seat_number": 3}
      ]
    },
    {
      "row_label": "B",
      "seats": [    
        {"x":  1, "y":  1,"seat_number": 1},
        {"x":  1, "y":  2,"seat_number": 2},
        {"x":  1, "y":  4,"seat_number": 3}
      ]
    }
  ]}
```
---

### LANGUAGE
| Column | Type   | Notes                 |
|--------|--------|-----------------------|
| id     | uuid   | PK                    |
| name   | string | unique                |
| code   | string | e.g. `en`, `hi`, `ta` |

---

### FORMAT
| Column | Type   | Notes                   |
|--------|--------|-------------------------|
| id     | uuid   | PK                      |
| name   | string | unique                  |
| code   | string | e.g. `2d`, `3d`, `imax` |

### MOVIE
| Column            | Type   | Notes                  |
|-------------------|--------|------------------------|
| id                | uuid   | PK                     |
| title             | string |                        |
| genre             | string |                        |
| rating            | enum   | `U`, `UA`, `A`, `S`    |
| movie_language_id | uuid   | FK → MOVIE_LANGUAGE.id |
| movie_format_id   | uuid   | FK → MOVIE_FORMAT.id   |
| description       | text   |                        |
| director          | string |                        |
| running_time      | int    | in minutes             |
| release_date      | date   |                        |

---

### MOVIE_LANGUAGE
| Column      | Type   | Notes                                |
|-------------|--------|--------------------------------------|
| id          | uuid   | PK                                   |
| movie_id    | uuid   | FK → MOVIE.id                        |
| language_id | uuid   | FK → LANGUAGE.id                     |
| type        | enum   | `original`, `dubbed`, `subtitled`    |

unique(movie_id, language_id) — a movie can only have one entry per language

### MOVIE_FORMAT
| Column      | Type   | Notes                                |
|-------------|--------|--------------------------------------|
| id          | uuid   | PK                                   |
| movie_id    | uuid   | FK → MOVIE.id                        |
| format_id   | uuid   | FK → FORMAT.id                       |
unique(movie_id, format_id) — a movie can only have one entry per format

> separate tables for languages and formats allow us to easily query which movies are available in a given language or format, and also allows a movie to have different languages and formats without having to create a new entry.
---

### CAST_MEMBER
| Column         | Type   | Notes                                |
|----------------|--------|--------------------------------------|
| id             | uuid   | PK                                   |
| movie_id       | uuid   | FK → MOVIE.id                        |
| name           | string |                                      |
| role           | string | e.g. `actor`, `director`, `producer` |
| character_name | string | nullable — not applicable for crew   |

---

### SHOW
| Column            | Type     | Notes                                                                                                          |
|-------------------|----------|----------------------------------------------------------------------------------------------------------------|
| id                | uuid     | PK                                                                                                             |
| screen_id         | uuid     | FK → SCREEN.id                                                                                                 |
| movie_id          | uuid     | FK → MOVIE.id                                                                                                  |
| movie_language_id | uuid     | FK → MOVIE_LANGUAGE.id                                                                                         |
| movie_format_id   | uuid     | FK → MOVIE_FORMAT.id                                                                                           |
| start_time        | datetime |                                                                                                                |
| end_time          | datetime | derived: `start_time + MOVIE.running_time`                                                                     |
| total_capacity    | int      | -- set once when show is created (SELECT COUNT(*) FROM seat WHERE screen_id = :screen_id AND is_active = true) |
| status            | enum     | `scheduled`, `cancelled`, `completed`                                                                          |

> **Availability Calculation (Lazy Init):** We calculate available seats on the fly by taking `total_capacity` and subtracting the count of `SHOW_SEAT` rows that have a status of `locked` or `booked`. If a seat does not have a row in `SHOW_SEAT`, it is implicitly available.
> **Format Validation:** when creating a show, validate that the selected movie's language and format are supported by the screen's capabilities. This ensures we don't schedule a 3D show in a screen that only supports 2D, for example.
> **Overlap Prevention:** No two rows in SHOW can overlap for the same `screen_id`.

---

### SHOW_PRICE
| Column     | Type    | Notes                                   |
|------------|---------|-----------------------------------------|
| id         | uuid    | PK                                      |
| show_id    | uuid    | FK → SHOW.id                            |
| seat_type  | enum    | `silver`, `gold`, `premium`, `recliner` |
| base_price | decimal | set by admin when scheduling the show   |
UNIQUE (show_id, seat_type)

> This is the source of truth for pricing. `TICKET.price` starts from here and adjusts for discounts/coupons.
> A show must have a price row for every seat type present in the screen.

---

### SHOW_SEAT
| Column            | Type     | Notes                            |
|-------------------|----------|----------------------------------|
| id                | uuid     | PK                               |
| show_id           | uuid     | FK → SHOW.id                     |
| seat_id           | uuid     | FK → SEAT.id                     |
| locked_by_user_id | uuid     | FK → USER.id — nullable          |
| status            | enum     | `locked`, `booked`               |
| locked_until      | datetime | nullable — lock expiry timestamp |

UNIQUE (show_id, seat_id)
> **TRANSIENT TABLE:** This table uses Lazy Initialization. Rows are **only** inserted when a user attempts to lock a seat.
> `status` no longer needs an `available` option. If a seat is available, the row simply does not exist.
> **Data Retention:** A background job runs daily to `DELETE` all rows in this table where the parent `SHOW.status` is `completed`. Historical seating data is preserved exclusively in the `TICKET` table.

---

### BOOKING
| Column       | Type         | Notes                                              |
|--------------|--------------|----------------------------------------------------|
| id           | uuid         | PK                                                 |
| user_id      | uuid         | FK → USER.id                                       |
| show_id      | uuid         | FK → SHOW.id                                       |
| coupon_id    | uuid         | FK → COUPONS.id nullable — if a coupon was applied |
| total_amount | decimal      | sum of all ticket prices in this booking           |
| status       | enum         | `pending`, `confirmed`, `cancelled`                |
| booking_time | datetime.now |                                                    |

> `show_id` is a soft constraint — the application must ensure all tickets under this booking belong to the same show.

---

### TICKET
| Column     | Type    | Notes                                                                                       |
|------------|---------|---------------------------------------------------------------------------------------------|
| id         | uuid    | PK                                                                                          |
| booking_id | uuid    | FK → BOOKING.id                                                                             |
| show_id    | uuid    | FK → SHOW.id — denormalized for easy access during ticket display and refunds               |
| seat_id    | uuid    | FK → SEAT.id — permanent link to the specific seat booked                                   |
| seat_label | string  | denormalized from SEAT.label for easy access during booking confirmation and ticket display |
| price      | decimal | final price paid — base price after discounts/coupons                                       |
| status     | enum    | `valid`, `cancelled`                                                                        |

> **Historical Ledger:** Because `SHOW_SEAT` is wiped clean after a show ends, this table acts as the permanent historical record of who sat where.
> `status` here handles **partial cancellations** — a user can cancel individual seats within a booking without cancelling the whole booking.

---

### TRANSACTION
| Column           | Type     | Notes                                         |
|------------------|----------|-----------------------------------------------|
| id               | uuid     | PK                                            |
| ref_no           | uuid     | from payment gateway (Razorpay, Stripe, etc.) |
| method           | string   | e.g. `UPI`, `card`, `net_banking`, `wallet`   |
| payment_id       | uuid     | FK → PAYMENT.id                               |
| amount           | decimal  | transaction amount                            |
| transaction_time | datetime | when the transaction occurred                 | 
| status           | enum     | `pending`, `completed`, `failed`              |

> one payment can have multiple transactions (e.g. initial payment + refund), but each transaction belongs to only one payment. This allows us to track the full lifecycle of a payment, including any refunds that may occur later.
---

### PAYMENT
| Column     | Type     | Notes                                        |
|------------|----------|----------------------------------------------|
| id         | uuid     | PK                                           |
| booking_id | uuid     | FK → BOOKING.id                              |
| user_id    | uuid     | FK → USER.id                                 |
| amount     | decimal  | should equal `BOOKING.total_amount`          |
| status     | enum     | `pending`, `completed`, `failed`, `refunded` |
| paid_at    | datetime | nullable — set on completion                 |


---

### PAYMENT_REFUND
| Column      | Type     | Notes                            |
|-------------|----------|----------------------------------|
| id          | uuid     | PK                               |
| payment_id  | uuid     | FK → PAYMENT.id                  |
| ticket_id   | uuid     | FK → TICKET.id                   |
| amount      | decimal  | refund amount                    |
| refunded_at | datetime |                                  |
| status      | enum     | `pending`, `completed`, `failed` |

> refunds won't be processed after start of a show, so we won't have to worry about partial refunds for a single ticket across multiple shows. If a user cancels a ticket before the show starts, we create a PAYMENT_REFUND record linked to that ticket and the original payment. Once the refund is processed, we update the TICKET.status to `cancelled` and adjust the BOOKING.total_amount accordingly.
> full refunds for a booking would simply be multiple PAYMENT_REFUND records for each ticket, all linked to the same original PAYMENT.
> refunds are processed asynchronously — when a user requests a cancellation, we create the PAYMENT_REFUND record with status `pending` and trigger the refund through the payment gateway. Once we get a callback from the gateway, we update the status to `completed` or `failed` accordingly.
> policy enforcement (e.g. no refunds within 1 hour of showtime) should be handled at the API layer before creating the PAYMENT_REFUND record.
> refund policy example:

> no refunds after show starts:

---

### REVIEW
| Column      | Type    | Notes          |
|-------------|---------|----------------|
| id          | uuid    | PK             |
| movie_id    | uuid    | FK → MOVIE.id  |
| user_id     | uuid    | FK → USER.id   |
| description | text    |                |
| rating      | decimal | `1.0` to `5.0` |
| reviewed_on | date    |                |

>unique constraint on `(movie_id, user_id)` so a user can only review a movie once.
> check for if user had purchased a ticket for movie they are reviewing to be enforced at api layer

---

### COUPONS
| Column                 | Type     | Notes                                                     |
|------------------------|----------|-----------------------------------------------------------|
| id                     | uuid     | PK                                                        |
| code                   | string   | unique coupon code                                        |
| description            | text     |                                                           |
| type                   | enum     | `amount`, `percentage`                                    |
| discount_amount        | decimal  | fixed amount discount                                     |
| discount_percentage    | decimal  | percentage discount (0-100)                               |
| minimum_booking_amount | decimal  | minimum total_amount required to apply this coupon        |
| max_uses_per_user      | int      | limit on how many times a single user can use this coupon |
| max_total_uses         | int      | limit on total redemptions across all users               |
| valid_from             | datetime |                                                           |
| valid_until            | datetime |                                                           |

---

---

### USER_COUPON_USAGE
| Column      | Type     | Notes           |
|-------------|----------|-----------------|
| id          | uuid     | PK              |
| coupon_id   | uuid     | FK → COUPONS.id |
| user_id     | uuid     | FK → USER.id    |
| booking_id  | uuid     | FK → BOOKING.id |
| used_at     | datetime |                 |

> we need to count the number of times a user has used a coupon to enforce `max_uses_per_user`, and also count total redemptions to enforce `max_total_uses`. This table allows us to track each redemption event.
> when a user applies a coupon during booking, we check the COUPONS table for validity and then insert a record into USER_COUPON_USAGE if the coupon is successfully applied. This way we can easily query how many times a user has used a coupon and how many total redemptions have occurred.


## Key Design Decisions

**Pricing flow** — `SHOW_PRICE` stores the base price per seat type per show. When a ticket is created, `TICKET.price` is set to `base_price` minus any discount. `BOOKING.total_amount` is the sum of all ticket prices.

**Seat locking** — `SHOW_SEAT.status = locked` with a `locked_until` timestamp handles the race condition when multiple users try to book the same seat simultaneously. The lock must be acquired before checkout begins and released if payment fails or the timer expires.

**Booking vs Ticket status** — `BOOKING.status` tracks the overall purchase state (`pending → confirmed → cancelled`). `TICKET.status` tracks individual seat state (`valid / cancelled`), enabling partial cancellations without voiding the whole booking.

>Indexes on frequently queried columns (e.g. `SHOW.start_time`, `SHOW(screen_id, start_time)`, `SHOW_SEAT(show_id, status)`, `BOOKING(user_id)`, `PAYMENT(booking_id)`, `REVIEW.movie_id`) will be crucial for performance as the dataset grows.