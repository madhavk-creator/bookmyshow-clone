# Movie Booking System - Database Schema

## Overview

This schema is designed for a modern cinema booking flow where:

- screen geometry is modeled once and versioned safely
- each show uses an immutable seat layout snapshot
- the seat picker can render live availability, accessibility, and section pricing
- historical tickets remain correct even if the screen layout changes later

The schema is organized into five logical groups:

- Users & theatres
- Movies & metadata
- Screens, layouts, and seats
- Shows, pricing, and seat state
- Bookings, payments, and reviews

---

## Entity Flow

```text
VENDOR
 └── manages THEATRE
       └── has SCREEN
             ├── supports FORMAT via SCREEN_CAPABILITY
             ├── has many SEAT_LAYOUT versions
             │     ├── has SECTIONs
             │     └── has SEATs
             └── hosts SHOW
                   ├── references MOVIE + selected MOVIE_LANGUAGE + MOVIE_FORMAT
                   ├── points to one immutable SEAT_LAYOUT version
                   ├── has SHOW_SECTION_PRICE
                   └── has SHOW_SEAT_STATE for live lock / booked / blocked state

USER
 └── makes BOOKING for one SHOW
       ├── contains TICKETs for chosen seats
       └── pays through PAYMENT / TRANSACTION

USER
 └── writes REVIEW for a MOVIE
```

---

## Core Design Principles

### 1. Layout versioning is mandatory

Do not let `SHOW`, `TICKET`, or seat history depend on a mutable current screen layout.

When a screen layout changes:

- create a new `SEAT_LAYOUT` version
- copy sections and seats into the new version
- future shows use the new version
- existing shows keep referencing the older version

This prevents historical bookings from breaking when seat labels, coordinates, or sections are edited.

### 2. Visual layout and transactional seats must use the same source of truth

Avoid storing the real seat map only in ad hoc JSON.

The UI should render from relational seat rows with coordinates plus optional layout metadata, so:

- every rendered seat maps to one stable `SEAT.id`
- section colors and legends remain consistent
- pricing and occupancy can be joined directly

### 3. Pricing should be by section, not only by seat type

Modern seat pickers usually show sections such as Premium, Executive, Recliner, Lounge, etc.

Use `SHOW_SECTION_PRICE` as the default price source, and allow optional per-seat overrides later if needed.

---

## Tables

### USER
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| name | string | |
| email | string | unique |
| encrypted_password | string | Devise-managed |
| phone | string | |
| role | enum/string | `user`, `admin`, `vendor` |
| is_active | boolean | default true |
| created_at | datetime | |
| updated_at | datetime | |

---

### CITY
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| name | string | |
| state | string | |
| created_at | datetime | |
| updated_at | datetime | |

Unique: `(name, state)`

---

### THEATRE
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| vendor_id | uuid | FK -> USER.id |
| name | string | |
| building_name | string | nullable |
| street_address | string | nullable |
| city_id | uuid | FK -> CITY.id |
| pincode | string | nullable |
| created_at | datetime | |
| updated_at | datetime | |

---

### SCREEN
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| theatre_id | uuid | FK -> THEATRE.id |
| name | string | unique within theatre |
| status | enum/string | `active`, `inactive` |
| total_rows | integer | current published layout bounds |
| total_columns | integer | current published layout bounds |
| total_seats | integer | current published layout active seat count |
| created_at | datetime | |
| updated_at | datetime | |

`total_rows`, `total_columns`, and `total_seats` should reflect the latest published layout only. Historical shows must not depend on these values.

---

### SCREEN_CAPABILITY
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| screen_id | uuid | FK -> SCREEN.id |
| format_id | uuid | FK -> FORMAT.id |
| created_at | datetime | |
| updated_at | datetime | |

Unique: `(screen_id, format_id)`

This table is already correctly modeled in the current migration.

---

### LANGUAGE
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| name | string | unique |
| code | string | unique, e.g. `en`, `hi`, `ta` |
| created_at | datetime | |
| updated_at | datetime | |

---

### FORMAT
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| name | string | unique |
| code | string | unique, e.g. `2d`, `3d`, `imax` |
| created_at | datetime | |
| updated_at | datetime | |

---

### MOVIE
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| title | string | |
| genre | string | |
| rating | enum/string | `U`, `UA`, `A`, `S` |
| description | text | nullable |
| director | string | nullable |
| running_time | integer | minutes |
| release_date | date | nullable |
| created_at | datetime | |
| updated_at | datetime | |

This matches the direction of the current migrations better than the old draft.

---

### MOVIE_LANGUAGE
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| movie_id | uuid | FK -> MOVIE.id |
| language_id | uuid | FK -> LANGUAGE.id |
| language_type | enum/string | `original`, `dubbed`, `subtitled` |
| created_at | datetime | |
| updated_at | datetime | |

Unique: `(movie_id, language_id)`

---

### MOVIE_FORMAT
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| movie_id | uuid | FK -> MOVIE.id |
| format_id | uuid | FK -> FORMAT.id |
| created_at | datetime | |
| updated_at | datetime | |

Unique: `(movie_id, format_id)`

---

### CAST_MEMBER
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| movie_id | uuid | FK -> MOVIE.id |
| name | string | |
| role | string | e.g. `actor`, `director`, `producer` |
| character_name | string | nullable |
| created_at | datetime | |
| updated_at | datetime | |

---

## Screens, Layouts, and Seats

### SEAT_LAYOUT
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| screen_id | uuid | FK -> SCREEN.id |
| version_number | integer | monotonically increasing per screen |
| name | string | e.g. `Default Layout`, `Renovation 2026` |
| status | enum/string | `draft`, `published`, `archived` |
| total_rows | integer | snapshot for this layout version |
| total_columns | integer | snapshot for this layout version |
| total_seats | integer | active bookable seats in this version |
| screen_label | string | optional UI copy like `All eyes this way` |
| legend_json | jsonb | optional UI metadata only, not source of truth |
| published_at | datetime | nullable |
| created_at | datetime | |
| updated_at | datetime | |

Unique: `(screen_id, version_number)`

Recommended rule:

- only one `published` layout per screen at a time
- a `SHOW` can reference only a `published` layout

Database guard:

- add a partial unique index on `seat_layouts(screen_id)` where `status = 'published'`

`legend_json` can store non-transactional display hints, but seat geometry must live in relational rows below.

---

### SEAT_SECTION
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| seat_layout_id | uuid | FK -> SEAT_LAYOUT.id |
| code | string | stable internal identifier like `premium`, `executive`, `recliner` |
| name | string | UI label |
| color_hex | string | for legend rendering |
| rank | integer | display order in UI and pricing list |
| created_at | datetime | |
| updated_at | datetime | |

Unique: `(seat_layout_id, code)`

This is the pricing and legend anchor for the seat picker.

Do not duplicate pricing semantics in another field unless you need a distinct operational concept. If `code` already represents the commercial class, keep that as the source of truth and avoid a redundant `seat_type`.

---

### SEAT
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| seat_layout_id | uuid | FK -> SEAT_LAYOUT.id |
| seat_section_id | uuid | FK -> SEAT_SECTION.id |
| row_label | string | e.g. `A`, `B`, `AA` |
| seat_number | integer | e.g. `12` |
| label | string | stored snapshot like `B12` |
| grid_row | integer | row coordinate for UI |
| grid_column | integer | column coordinate for UI |
| x_span | integer | default 1, useful for recliners/couple seats |
| y_span | integer | default 1 |
| seat_kind | enum/string | `standard`, `recliner`, `wheelchair`, `companion`, `couple` |
| is_accessible | boolean | default false |
| is_active | boolean | default true |
| created_at | datetime | |
| updated_at | datetime | |

Unique:

- `(seat_layout_id, label)`
- `(seat_layout_id, grid_row, grid_column)`

Notes:

- gaps and aisles are represented by missing coordinates, not fake seats
- if you later need explicit non-seat cells, add `LAYOUT_CELL` instead of overloading `SEAT`

---

## Shows, Pricing, and Live Availability

### SHOW
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| screen_id | uuid | FK -> SCREEN.id |
| seat_layout_id | uuid | FK -> SEAT_LAYOUT.id |
| movie_id | uuid | FK -> MOVIE.id |
| movie_language_id | uuid | FK -> MOVIE_LANGUAGE.id |
| movie_format_id | uuid | FK -> MOVIE_FORMAT.id |
| start_time | datetime | |
| end_time | datetime | derived from running time |
| total_capacity | integer | snapshot from active seats in referenced layout |
| status | enum/string | `scheduled`, `cancelled`, `completed` |
| created_at | datetime | |
| updated_at | datetime | |

Rules:

- the referenced `seat_layout_id` must belong to the same `screen_id`
- `seat_layout_id` is immutable after show creation
- validate the selected movie format against `SCREEN_CAPABILITY`
- prevent overlapping shows on the same screen

This same-screen check is not guaranteed by foreign keys alone. It must be enforced explicitly in show creation/update validation.

This is the key change that makes historical seat maps safe.

---

### SHOW_SECTION_PRICE
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| show_id | uuid | FK -> SHOW.id |
| seat_section_id | uuid | FK -> SEAT_SECTION.id |
| base_price | decimal | default price for this section in this show |
| created_at | datetime | |
| updated_at | datetime | |

Unique: `(show_id, seat_section_id)`

Use this instead of pricing only by seat type. It maps directly to what the UI shows in the legend.

Optional future extension:

- `SHOW_SEAT_PRICE_OVERRIDE(show_id, seat_id, price)`

---

### SHOW_SEAT_STATE
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| show_id | uuid | FK -> SHOW.id |
| seat_id | uuid | FK -> SEAT.id |
| status | enum/string | `locked`, `booked`, `blocked` |
| locked_by_user_id | uuid | FK -> USER.id, nullable |
| booking_id | uuid | FK -> BOOKING.id, nullable |
| lock_token | string | nullable, useful for idempotent checkout |
| locked_until | datetime | nullable |
| created_at | datetime | |
| updated_at | datetime | |

Unique: `(show_id, seat_id)`

Recommended behavior:

- no row means seat is currently available
- `locked` is temporary and expires
- `booked` is written once payment succeeds
- `blocked` is for admin/manual holds or broken seats in a particular show

Do not calculate availability only from `total_capacity - locked/booked count` once `blocked` exists. The seat picker should query actual seat rows plus joined state.

---

## Bookings and Payments

### BOOKING
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | FK -> USER.id |
| show_id | uuid | FK -> SHOW.id |
| coupon_id | uuid | FK -> COUPON.id, nullable |
| total_amount | decimal | sum of active ticket prices |
| status | enum/string | `pending`, `confirmed`, `cancelled`, `expired` |
| booking_time | datetime | |
| created_at | datetime | |
| updated_at | datetime | |

Keep `show_id` as a hard rule, not a soft application-level rule. A booking should belong to exactly one show.

Lifecycle note:

- `pending -> confirmed` after successful payment and ticket creation
- `pending -> expired` when the seat lock window ends before payment completion
- the background job that expires a booking must also release or delete the corresponding `SHOW_SEAT_STATE.locked` rows in the same transaction, otherwise you can leave seats locked under expired bookings

---

### TICKET
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| booking_id | uuid | FK -> BOOKING.id |
| show_id | uuid | FK -> SHOW.id |
| seat_id | uuid | FK -> SEAT.id |
| seat_label | string | snapshot from SEAT.label |
| section_name | string | snapshot from SEAT_SECTION.name |
| price | decimal | final paid amount for this seat |
| status | enum/string | `valid`, `cancelled` |
| created_at | datetime | |
| updated_at | datetime | |

Critical constraint:

- unique `(show_id, seat_id)`

That uniqueness belongs in the database, not only in application logic.

---

### PAYMENT
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| booking_id | uuid | FK -> BOOKING.id |
| user_id | uuid | FK -> USER.id |
| amount | decimal | expected booking amount |
| status | enum/string | `pending`, `completed`, `failed`, `refunded` |
| paid_at | datetime | nullable |
| created_at | datetime | |
| updated_at | datetime | |

---

### TRANSACTION
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| payment_id | uuid | FK -> PAYMENT.id |
| ref_no | string/uuid | gateway reference |
| method | string | `UPI`, `card`, `wallet`, etc. |
| amount | decimal | |
| transaction_time | datetime | |
| status | enum/string | `pending`, `completed`, `failed` |
| created_at | datetime | |
| updated_at | datetime | |

One payment can have multiple transactions.

---

### PAYMENT_REFUND
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| payment_id | uuid | FK -> PAYMENT.id |
| ticket_id | uuid | FK -> TICKET.id |
| amount | decimal | |
| refunded_at | datetime | nullable |
| status | enum/string | `pending`, `completed`, `failed` |
| created_at | datetime | |
| updated_at | datetime | |

---

## Reviews and Coupons

### REVIEW
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| movie_id | uuid | FK -> MOVIE.id |
| user_id | uuid | FK -> USER.id |
| description | text | |
| rating | decimal | `1.0` to `5.0` |
| reviewed_on | date | |
| created_at | datetime | |
| updated_at | datetime | |

Unique: `(movie_id, user_id)`

---

### COUPON
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| code | string | unique |
| description | text | |
| coupon_type | enum/string | `amount`, `percentage` |
| discount_amount | decimal | nullable |
| discount_percentage | decimal | nullable |
| minimum_booking_amount | decimal | nullable |
| max_uses_per_user | integer | nullable |
| max_total_uses | integer | nullable |
| valid_from | datetime | |
| valid_until | datetime | |
| created_at | datetime | |
| updated_at | datetime | |

---

### USER_COUPON_USAGE
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| coupon_id | uuid | FK -> COUPON.id |
| user_id | uuid | FK -> USER.id |
| booking_id | uuid | FK -> BOOKING.id |
| used_at | datetime | |
| created_at | datetime | |
| updated_at | datetime | |

---

## Recommended Indexes

- `SHOW(screen_id, start_time)`
- `SHOW(screen_id, status, start_time)`
- `SHOW_SEAT_STATE(show_id, status)`
- `SHOW_SEAT_STATE(show_id, seat_id)`
- `SEAT(seat_layout_id, seat_section_id)`
- `SEAT(seat_layout_id, row_label, seat_number)`
- `TICKET(show_id, seat_id)` unique
- `BOOKING(user_id, booking_time)`
- `PAYMENT(booking_id)`
- `REVIEW(movie_id)`

---

## Migration Guidance From Current State

### No new migration needed for these

- `movies`
- `movie_languages`
- `movie_formats`
- `screen_capabilities`
- `screens`

Those are aligned enough with this revised schema direction.

### New migrations are needed for the seat-picker design

Your current seat-related migrations are placeholders, so this is where the real work starts:

1. build `seat_layouts` as a versioned table tied to `screens`
2. build `seat_sections`
3. build `seats` tied to `seat_layouts` and `seat_sections`
4. when you introduce shows, include `seat_layout_id` on `shows`
5. replace old `show_price` thinking with `show_section_prices`
6. enforce `unique(show_id, seat_id)` on both live seat state and tickets

If you have not run the empty seat migrations yet, rewrite them directly. If they were already run anywhere important, create follow-up migrations instead of editing history.
