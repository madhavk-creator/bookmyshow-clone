---
title: Overview
description: API documentation for the BookMyShow Clone backend.
---

# BookMyShow Clone API

This site documents the Rails API used by the movie booking platform.

## Base URL

```txt
/api/v1
```

## Main Areas

- Authentication for users, vendors, and admins
- Reference data such as cities, languages, and formats
- Movies, reviews, theatres, screens, seat layouts, and shows
- Seat availability, bookings, payments, and coupons

## Response Style

Most successful endpoints return JSON objects. Validation failures usually return:

```json
{
  "errors": {
    "field_name": ["message"]
  }
}
```

## Auth

Protected endpoints expect a bearer token:

```http
Authorization: Bearer <token>
```

Use the pages in this docs site as a writing scaffold. You can keep expanding each endpoint with:

- request params
- example payloads
- success responses
- validation rules
- role restrictions
