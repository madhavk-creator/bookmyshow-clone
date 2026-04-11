---
title: Seat Layouts And Shows
description: Seat layout editing, publishing, and show scheduling endpoints.
---

# Seat Layouts And Shows

## Seat Layout Endpoints

- `GET /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts`
- `GET /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts/:id`
- `POST /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts`
- `PATCH /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts/:id`
- `POST /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts/:id/publish`
- `POST /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts/:id/archive`
- `PUT /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts/:id/sections`
- `PUT /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts/:id/seats`

## Show Endpoints

Public discovery:

- `GET /api/v1/shows`
- `GET /api/v1/shows/:id`
- `GET /api/v1/shows/:id/seats`

Nested management:

- `GET /api/v1/theatres/:theatre_id/screens/:screen_id/shows`
- `GET /api/v1/theatres/:theatre_id/screens/:screen_id/shows/:id`
- `POST /api/v1/theatres/:theatre_id/screens/:screen_id/shows`
- `PATCH /api/v1/theatres/:theatre_id/screens/:screen_id/shows/:id`
- `POST /api/v1/theatres/:theatre_id/screens/:screen_id/shows/:id/cancel`

## Notes

- Layout dimensions are derived from the screen.
- Show scheduling validates screen format compatibility.
- Recurring daily scheduling is supported with an end date.
- Seat availability uses live show seat state records.
