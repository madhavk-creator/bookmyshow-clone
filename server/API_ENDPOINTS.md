# ── Endpoints ──────────────────────────────────────────────────────────────────
#
#   POST  /api/v1/users/register
#   POST  /api/v1/users/login
#
#   POST  /api/v1/vendors/register
#   POST  /api/v1/vendors/login
#
#   POST  /api/v1/admin/register    (requires admin JWT in Authorization header)
#   POST  /api/v1/admin/login
#
# All endpoints accept:  { user: { name:, email:, password:, password_confirmation:, phone } }
# All endpoints return:  { token:, user: { id:, name:, email:, role: } }
#
#  Cities
#   GET    /api/v1/cities              public — ?state=Maharashtra
#   GET    /api/v1/cities/:id          public
#   POST   /api/v1/cities              admin or vendor
#   PATCH  /api/v1/cities/:id          admin only
#   DELETE /api/v1/cities/:id          admin only
#
#  Theatres
#   GET    /api/v1/theatres            public — ?city_id= ?vendor_id=
#   GET    /api/v1/theatres/:id        public
#   POST   /api/v1/theatres            vendor or admin
#   PATCH  /api/v1/theatres/:id        owning vendor or admin
#   DELETE /api/v1/theatres/:id        owning vendor or admin

#
#  Screens (nested under theatres)
#   GET    /api/v1/theatres/:theatre_id/screens              public
#   GET    /api/v1/theatres/:theatre_id/screens/:id          public
#   POST   /api/v1/theatres/:theatre_id/screens              vendor (own theatre) or admin
#   PATCH  /api/v1/theatres/:theatre_id/screens/:id          vendor (own theatre) or admin
#   DELETE /api/v1/theatres/:theatre_id/screens/:id          vendor (own theatre) or admin
#
#  Create/update payload:
#   {
#     "screen": {
#       "name": "Screen 1",
#       "total_rows": 10,
#       "total_columns": 20,
#       "status": "active",
#       "format_ids": ["uuid-1", "uuid-2"]   ← optional, replaces all capabilities
#     }
#   }

# Movies Create/update payload:
#   {
#     "movie": {
#       "title": "Dune Part Two",
#       "genre": "Sci-Fi",
#       "rating": "UA",
#       "description": "...",
#       "director": "Denis Villeneuve",
#       "running_time": 166,
#       "release_date": "2024-03-01",
#       "language_entries": [
#         { "language_id": "uuid", "type": "original" },
#         { "language_id": "uuid", "type": "dubbed" }
#       ],
#       "format_ids": ["uuid", "uuid"],
#       "cast_members": [
#         { "name": "Timothée Chalamet", "role": "actor", "character_name": "Paul Atreides" },
#         { "name": "Denis Villeneuve",  "role": "director", "character_name": null }
#       ]
#     }
#   }
#
# cast_members is replace-on-update when present — omitting it leaves existing cast untouched.

# Index filters:
#   ?genre=    — filter by genre (case-insensitive)
#   ?language= — filter by language code (e.g. hi, en, ta)
#   ?format=   — filter by format code (e.g. 2d, imax)
#   ?city_id=  — only movies with at least one scheduled show in that city
#
#  Movies
#   GET    /api/v1/movies                  public
#                                          ?genre=Sci-Fi
#                                          ?language=hi
#                                          ?format=imax
#                                          ?city_id=uuid
#   GET    /api/v1/movies/:id              public — full detail + cast
#   POST   /api/v1/movies                  admin only
#   PATCH  /api/v1/movies/:id              admin only
#   DELETE /api/v1/movies/:id              admin only

#  Languages
#   GET    /api/v1/languages               public
#   GET    /api/v1/languages/:id           public
#   POST   /api/v1/languages               admin or vendor
#   PATCH  /api/v1/languages/:id           admin or vendor
#   DELETE /api/v1/languages/:id           admin or vendor
#
#  Formats
#   GET    /api/v1/formats                 public
#   GET    /api/v1/formats/:id             public
#   POST   /api/v1/formats                 admin or vendor
#   PATCH  /api/v1/formats/:id             admin or vendor
#   DELETE /api/v1/formats/:id             admin or vendor
#
#  Seat Layouts
#  Base: /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts
#
#  GET    /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts
#                                           public — published layouts for public users,
#                                           all published + own drafts for vendor, all for admin
#  GET    /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts/:id
#                                           public for published layouts, private for drafts/archived
#  POST   /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts
#                                           vendor (own screen) or admin — create draft
#  PATCH  /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts/:id
#                                           vendor (own screen) or admin — draft only
#  POST   /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts/:id/publish
#                                           vendor (own screen) or admin — draft → published
#  POST   /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts/:id/archive
#                                           vendor (own screen) or admin — published → archived
#  PUT    /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts/:id/sections
#                                           vendor (own screen) or admin — replace sections
#  PUT    /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts/:id/seats
#                                           vendor (own screen) or admin — replace seats
#
#  Section payload:
#    { "sections": [{ "code": "premium", "name": "Premium", "color_hex": "#FFD700", "rank": 0 }] }
#
#  Seat payload:
#    { "seats": [{ "row_label": "A", "seat_number": 1, "grid_row": 0, "grid_column": 0,
#                  "seat_section_id": "uuid", "seat_kind": "standard",
#                  "is_accessible": false, "is_active": true }] }

#  Shows
#  Supports two route contexts:
#
#   Top-level (discovery/browsing):
#     GET    /api/v1/shows
#     GET    /api/v1/shows/:id
#     GET    /api/v1/shows/:show_id/seats
#     POST   /api/v1/shows/:show_id/seats/:seat_id/block
#     DELETE /api/v1/shows/:show_id/seats/:seat_id/block
#
#   Nested (vendor/admin management):
#     GET    /api/v1/theatres/:theatre_id/screens/:screen_id/shows
#     GET    /api/v1/theatres/:theatre_id/screens/:screen_id/shows/:id
#     POST   /api/v1/theatres/:theatre_id/screens/:screen_id/shows
#     PATCH  /api/v1/theatres/:theatre_id/screens/:screen_id/shows/:id
#     POST   /api/v1/theatres/:theatre_id/screens/:screen_id/shows/:id/cancel
#
#  GET    /api/v1/shows                        public
#                                              ?movie_id= ?date=YYYY-MM-DD
#                                              ?language=hi ?format=imax
#                                              ?city_id=uuid ?status=scheduled
#  GET    /api/v1/shows/:id                    public — detail + section prices
#  GET    /api/v1/shows/:show_id/seats         public — full seat map grouped by section,
#                                                       per-seat status, and section pricing
#  POST   /api/v1/shows/:show_id/seats/:seat_id/block
#                                              admin only — manually block a seat
#  DELETE /api/v1/shows/:show_id/seats/:seat_id/block
#                                              admin only — manually unblock a seat
#  GET    /api/v1/theatres/:theatre_id/screens/:screen_id/shows
#                                              public — same filters, scoped to a screen
#  GET    /api/v1/theatres/:theatre_id/screens/:screen_id/shows/:id
#                                              public
#  POST   /api/v1/theatres/:theatre_id/screens/:screen_id/shows
#                                              vendor (own screen) or admin
#  PATCH  /api/v1/theatres/:theatre_id/screens/:screen_id/shows/:id
#                                              vendor (own screen) or admin — scheduled only
#  POST   /api/v1/theatres/:theatre_id/screens/:screen_id/shows/:id/cancel
#                                              vendor (own screen) or admin — scheduled only
#
#  Create payload:
#   {
#     "show": {
#       "movie_id": "uuid",
#       "seat_layout_id": "uuid",
#       "movie_language_id": "uuid",
#       "movie_format_id": "uuid",
#       "start_time": "2026-04-01T18:30:00+05:30",
#       "section_prices": [
#         { "seat_section_id": "uuid", "base_price": "250.00" },
#         { "seat_section_id": "uuid", "base_price": "450.00" }
#       ]
#     }
#   }
#
#  Seat map response:
#   {
#     "show_id": "uuid",
#     "total_capacity": 240,
#     "available_count": 187,
#     "locked_count": 3,
#     "booked_count": 48,
#     "blocked_count": 2,
#     "inactive_count": 1,
#     "sections": [
#       {
#         "id": "section-uuid",
#         "code": "premium",
#         "name": "Premium",
#         "color_hex": "#FFD700",
#         "rank": 0,
#         "base_price": "250.0",
#         "seats": [
#           {
#             "id": "seat-uuid",
#             "label": "A1",
#             "row_label": "A",
#             "seat_number": 1,
#             "seat_section_id": "section-uuid",
#             "grid_row": 0,
#             "grid_column": 0,
#             "x_span": 1,
#             "y_span": 1,
#             "seat_kind": "standard",
#             "is_accessible": false,
#             "status": "available"
#           }
#         ]
#       } 
#     ]
#   }
#
#  Seat status values:
#    available | locked | booked | blocked | inactive
#
# ── Seat state endpoint reference ─────────────────────────────────────────────
#
#  GET    /api/v1/shows/:show_id/seats
#    → full seat map grouped by section, with per-seat status and section pricing
#    → public, no auth required
#
#  POST   /api/v1/shows/:show_id/seats/:seat_id/block
#    → admin manually holds a seat (broken seat, VIP reserve, etc.)
#    → requires admin JWT
#
#  DELETE /api/v1/shows/:show_id/seats/:seat_id/block
#    → admin releases a manually blocked seat
#    → requires admin JWT
#
# ── Internal operations (not exposed as endpoints) ───────────────────────────
#
#  ShowSeatState::Lock    — called by Booking::Create to lock selected seats
#  ShowSeatState::Release — called by Booking::Abandon or lock-expiry cleanup
