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
USER
 └── manages THEATRE
       └── has SCREEN
             ├── contains SEAT
             └── hosts SHOW
                   ├── references MOVIE (language + format validated)
                   ├── has SHOW_SEAT (per-seat availability + locking)
                   └── has SHOW_PRICE (base price per seat type)

USER
 └── makes BOOKING (for a SHOW)
       ├── contains TICKET (each linked to a SHOW_SEAT)
       └── paid via PAYMENT

USER
 └── writes REVIEW (for a MOVIE)
```

---

## Tables

### USER
| Column | Type | Notes                                                    |
|---|---|----------------------------------------------------------|
| id | uuid | PK                                                       |
| name | string |                                                          |
| email | string | unique                                                   |
| password | string | hashed                                                   |
| phone | string |                                                          |
| role | enum | `user`, `admin`, `vendor`                                 |
| is_active | boolean | default true — for soft deletes and account deactivation |

---

---
### CITY
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| name | string |  |
| state | string | |
unique(name, state) — to prevent duplicate city entries
---

### THEATRE
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| owner_id | uuid | FK → USER.id |
| name | string | |
| building_name | string | |
| street_address | string | |
| city_id | uuid | FK → CITY.id |
| pincode | string | |

---

### SCREEN
| Column        | Type | Notes |
|---------------|---|---|
| id            | uuid | PK |
| theatre_id    | uuid | FK → THEATRE.id |
| name          | string | e.g. "Screen 1", "IMAX Hall" |
| status        | enum | `active`, `inactive` — for maintenance etc. |
| total_rows    | int |  |
| total_columns | int |  |
| total_seats   | int | derived from SEAT count where is_active = true |

> SCREEN.total_seats must be recomputed whenever SEAT.is_active changes on any seat belonging to that screen. Same as SHOW.total_capacity — snapshot on creation, explicitly recomputed on change.
> 
---

### SCREEN_CAPABILITY
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| screen_id | uuid | FK → SCREEN.id |
| capability | enum | `2D`, `3D`, `4DX`, `IMAX` |
unique(screen_id, capability)

### SEAT
| Column       | Type    | Notes |
|---|---|---|
| id           | uuid    | PK |
| screen_id    | uuid    | FK → SCREEN.id |
| type         | enum    | silver, gold, premium, recliner |
| row_label    | string  | A, B, C — assigned when owner finalises layout |
| seat_number  | int     | 1, 2, 3 — assigned left to right within the row |
| label        | string  | derived + stored: row_label + seat_number e.g. B12 |
| x_position   | int     | grid column index (0-based) |
| y_position   | int     | grid row index (0-based) |
| col_span     | int     | default 1 — recliners may be 2 |
| row_span     | int     | default 1 — rarely > 1 |
| is_accessible| boolean | wheelchair-accessible seat |
| is_active    | boolean | false = seat exists but disabled (maintenance etc.) |
UNIQUE (screen_id, x_position, y_position)
UNIQUE (screen_id, label)

> Seat availability is **not** stored here — it lives in `SHOW_SEAT` per show.

---

### MOVIE
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| title | string | |
| genre | string | |
| rating | enum | `U`, `UA`, `A`, `S` |
| description | text | |
| director | string | |
| running_time | int | in minutes |
| release_date | date | |

---

### MOVIE_LANGUAGE
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| movie_id | uuid | FK → MOVIE.id |
| language | enum | `Hindi`, `English`, `Tamil`, `Telugu`, etc. |

> Admin populates this when adding a movie. A SHOW can only be scheduled in a language that exists here.

---

### MOVIE_FORMAT
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| movie_id | uuid | FK → MOVIE.id |
| format | enum | `2D`, `3D`, `4DX`, `IMAX` |

> A SHOW can only be scheduled in a format that exists here **and** is supported by the Screen's `capabilities`.

---

### CAST_MEMBER
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| movie_id | uuid | FK → MOVIE.id |
| name | string | |
| role | string | e.g. `actor`, `director`, `producer` |
| character_name | string | nullable — not applicable for crew |

---

### SHOW
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| screen_id | uuid | FK → SCREEN.id |
| movie_id | uuid | FK → MOVIE.id |
| movie_language_id | uuid | FK → MOVIE_LANGUAGE.id |
| movie_format_id | uuid | FK → MOVIE_FORMAT.id |
| start_time | datetime | |
| end_time | datetime | derived: `start_time + MOVIE.running_time` |
| available_seats |  int  | -- decremented on lock/booking, incremented on cancellation/lock expiry
| total_capacity    | int  |  -- set once when show is created (SELECT COUNT(*) FROM seat WHERE screen_id = :screen_id AND is_active = true)
| status | enum | `scheduled`, `cancelled`, `completed` |

> note on available_seats we need to decide whether to calculate it on the fly by counting SHOW_SEAT rows with status `available`, or maintain it as a denormalized column that we update whenever a seat is locked/booked/cancelled. The latter is more performant for reads but requires careful handling to avoid inconsistencies.
```SQL
COUNT(*) WHERE status = 'available'
```

> `movie_language_id` and `movie_format_id` enforce that only supported languages/formats can be scheduled.
> At the API level, validate that `movie_format_id.format` is present in `SCREEN.capabilities`.
> to avoid show overlaps No two rows in SHOW can overlap for same screen_id — this must be enforced at the application level when creating/updating shows by checking:
```SQL
EXCLUDE USING gist (
  screen_id WITH =,
  tsrange(start_time, end_time) WITH &&
)
```
 ```SQL
WHERE screen_id = X
AND start_time < existing.end_time
AND end_time > existing.start_time
```

---

### SHOW_PRICE
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| show_id | uuid | FK → SHOW.id |
| seat_type | enum | `silver`, `gold`, `premium`, `recliner` |
| base_price | decimal | set by admin when scheduling the show |
UNIQUE (show_id, seat_type)

> This is the source of truth for pricing. `TICKET.price` starts from here and adjusts for discounts/coupons.
> A show must have a price row for every seat type present in the screen.

---

### SHOW_SEAT
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| show_id | uuid | FK → SHOW.id |
| seat_id | uuid | FK → SEAT.id |
| locked_by_user_id | uuid | FK → USER.id — nullable |
| status | enum | `available`, `locked`, `booked` |
| locked_until | datetime | nullable — lock expiry timestamp |

UNIQUE (show_id, seat_id)

> `locked` is a temporary state during checkout (e.g. 10-minute window). A background job should expire stale locks by resetting `status` to `available` where `locked_until < now()`.

---

### BOOKING
| Column       | Type         | Notes |
|--------------|--------------|---|
| id           | uuid         | PK |
| user_id      | uuid         | FK → USER.id |
| show_id      | uuid         | FK → SHOW.id |
| total_amount | decimal      | sum of all ticket prices in this booking |
| status       | enum         | `pending`, `confirmed`, `cancelled` |
| booking_time | datetime.now | |

> `show_id` is a soft constraint — the application must ensure all tickets under this booking belong to the same show.

---

### TICKET
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| booking_id | uuid | FK → BOOKING.id |
| show_seat_id | uuid | FK → SHOW_SEAT.id |
| price | decimal | final price paid — base price after discounts/coupons |
| status | enum | `valid`, `cancelled` |

> `status` here handles **partial cancellations** — a user can cancel individual seats within a booking without cancelling the whole booking.

---

### PAYMENT
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| booking_id | uuid | FK → BOOKING.id |
| user_id | uuid | FK → USER.id |
| transaction_id | string | from payment gateway (Razorpay, Stripe, etc.) |
| amount | decimal | should equal `BOOKING.total_amount` |
| status | enum | `pending`, `completed`, `failed`, `refunded` |
| method | string | e.g. `UPI`, `card`, `net_banking`, `wallet` |
| paid_at | datetime | nullable — set on completion |


```SQL 
CREATE UNIQUE INDEX one_completed_payment_per_booking
ON payment(booking_id)
WHERE status = 'completed';
```

---

### PAYMENT_REFUND
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| payment_id | uuid | FK → PAYMENT.id |
| ticket_id | uuid | FK → TICKET.id |
| amount | decimal | refund amount |
| refunded_at | datetime | |
| status | enum | `pending`, `completed`, `failed` |

> refunds won't be processed after start of a show, so we won't have to worry about partial refunds for a single ticket across multiple shows. If a user cancels a ticket before the show starts, we create a PAYMENT_REFUND record linked to that ticket and the original payment. Once the refund is processed, we update the TICKET.status to `cancelled` and adjust the BOOKING.total_amount accordingly.
> full refunds for a booking would simply be multiple PAYMENT_REFUND records for each ticket, all linked to the same original PAYMENT.
> refunds are processed asynchronously — when a user requests a cancellation, we create the PAYMENT_REFUND record with status `pending` and trigger the refund through the payment gateway. Once we get a callback from the gateway, we update the status to `completed` or `failed` accordingly.
> policy enforcement (e.g. no refunds within 1 hour of showtime) should be handled at the API layer before creating the PAYMENT_REFUND record.
> refund policy example:
```SQL
WHERE show.start_time > now() + interval '1 hour'
```
> no refunds after show starts:
```SQL
WHERE show.start_time > now()
```

---

### REVIEW
| Column      | Type | Notes |
|-------------|---|---|
| id          | uuid | PK |
| movie_id    | uuid | FK → MOVIE.id |
| user_id     | uuid | FK → USER.id |
| description | text | |
| rating      | decimal | `1.0` to `5.0` |
| reviewed_on | date | |

>unique constraint on `(movie_id, user_id)` so a user can only review a movie once.
> check for if user had purchased a ticket for movie they are reviewing to be enforced at api layer
`SELECT 1 FROM ticket t
JOIN show_seat ss ON ss.id = t.show_seat_id
JOIN show sh      ON sh.id = ss.show_id
WHERE t.booking_id IN (SELECT id FROM booking WHERE user_id = :user_id)
  AND sh.movie_id = :movie_id
  AND t.status = 'valid'
LIMIT 1;`

---

### COUPONS
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| code | string | unique coupon code |
| description | text | |
| type | enum | `amount`, `percentage` |
| discount_amount | decimal | fixed amount discount |
| discount_percentage | decimal | percentage discount (0-100) |
| max_uses_per_user | int | limit on how many times a single user can use this coupon |
| max_total_uses | int | limit on total redemptions across all users |
| valid_from | datetime | |
| valid_until | datetime | |

---

---

### COUPON_USAGE
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| coupon_id | uuid | FK → COUPONS.id |
| user_id | uuid | FK → USER.id |
| booking_id | uuid | FK → BOOKING.id |
| usage_count | int | how many times this user has used this coupon (for enforcing max_uses_per_user) |
| used_at | datetime | |


## Key Design Decisions

**Pricing flow** — `SHOW_PRICE` stores the base price per seat type per show. When a ticket is created, `TICKET.price` is set to `base_price` minus any discount. `BOOKING.total_amount` is the sum of all ticket prices.

**Seat locking** — `SHOW_SEAT.status = locked` with a `locked_until` timestamp handles the race condition when multiple users try to book the same seat simultaneously. The lock must be acquired before checkout begins and released if payment fails or the timer expires.

**Booking vs Ticket status** — `BOOKING.status` tracks the overall purchase state (`pending → confirmed → cancelled`). `TICKET.status` tracks individual seat state (`valid / cancelled`), enabling partial cancellations without voiding the whole booking.

**Language and format validation** — `SHOW.movie_language_id` and `SHOW.movie_format_id` are FKs into `MOVIE_LANGUAGE` and `MOVIE_FORMAT`, ensuring only admin-defined languages and formats can be scheduled. Screen capability matching (`SCREEN.capabilities` vs `MOVIE_FORMAT.format`) is enforced at the API layer.

indexes on frequently queried columns (e.g. `SHOW.start_time`, `SHOW(screen_id, start_time)`, `SHOW_SEAT(show_id, status)`, `BOOKING(user_id)`, `PAYMENT(booking_id)`, `REVIEW.movie_id`) will be crucial for performance as the dataset grows.