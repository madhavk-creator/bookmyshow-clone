BOOKING.show_id is a soft constraint. A booking references a show, and its tickets reference SHOW_SEAT rows which also belong to that show — but the DB can't enforce that these stay consistent on its own. At the application level, when creating tickets under a booking, you must validate that every show_seat.show_id matches booking.show_id. Worth adding a note in your API logic.
TICKET.status vs BOOKING.status. Right now both have a status enum. Think through what each means — a natural split is: BOOKING.status = overall state (pending / confirmed / cancelled), TICKET.status = per-seat state (valid / cancelled), useful for partial cancellations where a user cancels one seat from a multi-seat booking.


> `movie_language_id` and `movie_format_id` enforce that only supported languages/formats can be scheduled.
> At the API level, validate that `movie_format_id.format` is present in `SCREEN.capabilities`.

> `booking.show_id` is a soft constraint — the application must ensure all tickets under this booking belong to the same show.

> Consider adding a unique constraint on `(movie_id, user_id)` so a user can only review a movie once. in review
> 
> `SHOW.total_capacity` is set once when the show is created, based on the screen's seating configuration. This is a denormalization for performance — it avoids having to join with SEAT/SHOW_SEAT to calculate available seats during booking. The application must ensure this value stays consistent with the actual number of seats in the screen.
> for seat availability, we can calculate it as: `available_seats = total_capacity - COUNT(WHERE show_seat.status IN ('locked', 'booked'))` for that show. This is a common pattern in booking systems to optimize read performance at the cost of some denormalization complexity.
> seat layouts 
for each unique y_position (sorted ascending):
    assign row_label = A, B, C... (skip y gaps — they're aisles between sections)
        for each seat at that y (sorted by x_position ascending):
            assign seat_number = 1, 2, 3... (skip x gaps — they're aisle columns)
                set label = row_label + seat_number