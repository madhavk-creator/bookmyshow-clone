---
title: Bookings And Coupons
description: Booking, payment, ticket cancellation, and coupon application endpoints.
---

# Bookings And Coupons

## Booking Endpoints

- `GET /api/v1/bookings`
- `GET /api/v1/bookings/:id`
- `POST /api/v1/bookings`
- `POST /api/v1/bookings/:id/confirm_payment`
- `POST /api/v1/bookings/:id/cancel`
- `POST /api/v1/bookings/:id/apply_coupon`
- `POST /api/v1/bookings/:id/tickets/:ticket_id/cancel`

## Coupon Behavior

- Only eligible coupons should be shown for a pending booking.
- Applying a new coupon replaces the previous coupon on that booking.
- Removing a coupon resets the pending payment amount to subtotal.
- Coupon usage is recorded only after successful payment confirmation.
- Cancelled confirmed bookings do not restore coupon usage.

## Payment Notes

- Payment confirmation is simulated through the booking confirmation endpoint.
- Pending bookings are discarded when the hold window expires.
- Confirmed payments transition locked seats to booked.
