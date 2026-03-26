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