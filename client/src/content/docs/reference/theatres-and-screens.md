---
title: Theatres And Screens
description: Theatre and screen management endpoints.
---

# Theatres And Screens

## Theatre Endpoints

- `GET /api/v1/theatres`
- `GET /api/v1/theatres/:id`
- `POST /api/v1/theatres`
- `PATCH /api/v1/theatres/:id`
- `DELETE /api/v1/theatres/:id`

## Screen Endpoints

- `GET /api/v1/theatres/:theatre_id/screens`
- `GET /api/v1/theatres/:theatre_id/screens/:id`
- `POST /api/v1/theatres/:theatre_id/screens`
- `PATCH /api/v1/theatres/:theatre_id/screens/:id`
- `DELETE /api/v1/theatres/:theatre_id/screens/:id`

## Notes

- Screen format capabilities are managed at the screen level.
- Rows and columns must both be less than `50`.
- Removing a screen format is blocked if scheduled shows still depend on it.
