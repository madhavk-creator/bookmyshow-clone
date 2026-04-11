---
title: Reference Data
description: Cities, languages, formats, vendors, and public coupon validation.
---

# Reference Data

## Cities

- `GET /api/v1/cities`
- `GET /api/v1/cities/:id`
- `POST /api/v1/cities`
- `PATCH /api/v1/cities/:id`
- `DELETE /api/v1/cities/:id`

## Languages

- `GET /api/v1/languages`
- `GET /api/v1/languages/:id`
- `POST /api/v1/languages`
- `PATCH /api/v1/languages/:id`
- `DELETE /api/v1/languages/:id`

## Formats

- `GET /api/v1/formats`
- `GET /api/v1/formats/:id`
- `POST /api/v1/formats`
- `PATCH /api/v1/formats/:id`
- `DELETE /api/v1/formats/:id`

## Vendors

- `GET /api/v1/vendors`
- `GET /api/v1/vendors/:id/income`
- `GET /api/v1/vendors/:id/shows_summary`

## Coupons

Public coupon endpoints:

- `GET /api/v1/coupons`
- `GET /api/v1/coupons/:code/validate`

Admin coupon endpoints:

- `GET /api/v1/admin/coupons`
- `POST /api/v1/admin/coupons`
- `DELETE /api/v1/admin/coupons/:id`
