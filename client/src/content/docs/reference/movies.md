---
title: Movies
description: Movie catalogue and review endpoints.
---

# Movies

## Movie Endpoints

- `GET /api/v1/movies`
- `GET /api/v1/movies/:id`
- `POST /api/v1/movies`
- `PATCH /api/v1/movies/:id`
- `DELETE /api/v1/movies/:id`

## Review Endpoints

- `GET /api/v1/movies/:movie_id/reviews`
- `GET /api/v1/movies/:movie_id/reviews/:id`
- `POST /api/v1/movies/:movie_id/reviews`
- `PATCH /api/v1/movies/:movie_id/reviews/:id`
- `DELETE /api/v1/movies/:movie_id/reviews/:id`

## Notes

- Movies must have at least one language.
- Movies must have at least one format.
- Running time is capped at `250` minutes.
