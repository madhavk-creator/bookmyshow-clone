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
# All endpoints accept:  { user: { name:, email:, password:, ... } }
# All endpoints return:  { token:, user: { id:, name:, email:, role: } }