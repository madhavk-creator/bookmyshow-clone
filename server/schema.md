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
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| name | string | |
| email | string | unique |
| password | string | hashed |
| phone | string | |
| role | enum | `user`, `admin` |

---

### THEATRE
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| owner_id | uuid | FK → USER.id |
| name | string | |
| location | string | |

---

### SCREEN
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| theatre_id | uuid | FK → THEATRE.id |
| name | string | e.g. "Screen 1", "IMAX Hall" |
| capabilities | string | e.g. `2D`, `3D`, `4DX`, `IMAX` — used to validate SHOW.format |
| total_rows | int | |
| total_columns | int | |

---

### SEAT
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| screen_id | uuid | FK → SCREEN.id |
| type | enum | `silver`, `gold`, `premium`, `recliner` |
| row_label | string | e.g. `A`, `B`, `C` |
| seat_number | int | e.g. `1`, `2`, `3` |

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
| total_capacity    | int  |  -- set once when show is created (= total seats in screen), from total no of rows * total no of columns

> `movie_language_id` and `movie_format_id` enforce that only supported languages/formats can be scheduled.
> At the API level, validate that `movie_format_id.format` is present in `SCREEN.capabilities`.

---

### SHOW_PRICE
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| show_id | uuid | FK → SHOW.id |
| seat_type | enum | `silver`, `gold`, `premium`, `recliner` |
| base_price | decimal | set by admin when scheduling the show |

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

> `locked` is a temporary state during checkout (e.g. 10-minute window). A background job should expire stale locks by resetting `status` to `available` where `locked_until < now()`.

---

### BOOKING
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | FK → USER.id |
| show_id | uuid | FK → SHOW.id |
| total_amount | decimal | sum of all ticket prices in this booking |
| status | enum | `pending`, `confirmed`, `cancelled` |
| created_at | datetime | |

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
| amount | decimal | should equal `BOOKING.total_amount` |
| status | enum | `pending`, `completed`, `failed`, `refunded` |
| method | string | e.g. `UPI`, `card`, `net_banking`, `wallet` |
| transaction_id | string | from payment gateway (Razorpay, Stripe, etc.) |
| paid_at | datetime | nullable — set on completion |

---

### REVIEW
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| movie_id | uuid | FK → MOVIE.id |
| user_id | uuid | FK → USER.id |
| description | text | |
| rating | decimal | `1.0` to `5.0` |
| date | date | |

> Consider adding a unique constraint on `(movie_id, user_id)` so a user can only review a movie once.

---

## Key Design Decisions

**Pricing flow** — `SHOW_PRICE` stores the base price per seat type per show. When a ticket is created, `TICKET.price` is set to `base_price` minus any discount. `BOOKING.total_amount` is the sum of all ticket prices.

**Seat locking** — `SHOW_SEAT.status = locked` with a `locked_until` timestamp handles the race condition when multiple users try to book the same seat simultaneously. The lock must be acquired before checkout begins and released if payment fails or the timer expires.

**Booking vs Ticket status** — `BOOKING.status` tracks the overall purchase state (`pending → confirmed → cancelled`). `TICKET.status` tracks individual seat state (`valid / cancelled`), enabling partial cancellations without voiding the whole booking.

**Language and format validation** — `SHOW.movie_language_id` and `SHOW.movie_format_id` are FKs into `MOVIE_LANGUAGE` and `MOVIE_FORMAT`, ensuring only admin-defined languages and formats can be scheduled. Screen capability matching (`SCREEN.capabilities` vs `MOVIE_FORMAT.format`) is enforced at the API layer.