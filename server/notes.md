BOOKING.show_id is a soft constraint. A booking references a show, and its tickets reference SHOW_SEAT rows which also belong to that show — but the DB can't enforce that these stay consistent on its own. At the application level, when creating tickets under a booking, you must validate that every show_seat.show_id matches booking.show_id. Worth adding a note in your API logic.
TICKET.status vs BOOKING.status. Right now both have a status enum. Think through what each means — a natural split is: BOOKING.status = overall state (pending / confirmed / cancelled), TICKET.status = per-seat state (valid / cancelled), useful for partial cancellations where a user cancels one seat from a multi-seat booking.


> `movie_language_id` and `movie_format_id` enforce that only supported languages/formats can be scheduled.
> At the API level, validate that `movie_format_id.format` is present in `SCREEN.capabilities`.

> `booking.show_id` is a soft constraint — the application must ensure all tickets under this booking belong to the same show.

> Consider adding a unique constraint on `(movie_id, user_id)` so a user can only review a movie once. in review