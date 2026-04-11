---
title: Booking Flow
description: High-level explanation of how seat booking works.
---

# Booking Flow

This project uses a live seat-locking flow.

## Typical Flow

1. Discover a show.
2. Fetch seat availability.
3. Create a booking with selected seat IDs.
4. A pending booking holds those seats for a short time.
5. Apply or remove a coupon if needed.
6. Confirm payment.
7. Booking becomes confirmed and locked seats become booked.

## Important Rules

- Seat availability is fetched from the show seat state layer.
- Pending bookings hold seats temporarily.
- Coupon usage is counted only after successful payment.
- Timed-out pending bookings are discarded.
- Cancelled pending bookings release seats immediately.

## Related Endpoints

- `GET /api/v1/shows/:id/seats`
- `POST /api/v1/bookings`
- `POST /api/v1/bookings/:id/apply_coupon`
- `POST /api/v1/bookings/:id/confirm_payment`
- `POST /api/v1/bookings/:id/cancel`
