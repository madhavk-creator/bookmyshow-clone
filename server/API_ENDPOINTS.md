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