import { useSelector } from 'react-redux'
import { Navigate, Outlet, useLocation } from 'react-router-dom'
import { selectCurrentUser, selectCurrentToken } from '../store/authSlice'

export default function ProtectedRoute({ allowedRoles }) {
  const token = useSelector(selectCurrentToken)
  const user = useSelector(selectCurrentUser)
  const location = useLocation()

  if (!token || !user) {
    if (location.pathname.startsWith('/admin')) {
      return <Navigate to="/admin/login" replace state={{ from: location }} />
    }
    if (location.pathname.startsWith('/vendor')) {
      return <Navigate to="/vendor/login" replace state={{ from: location }} />
    }
    return <Navigate to="/login" replace state={{ from: location }} />
  }

  if (allowedRoles && !allowedRoles.includes(user.role)) {
    return <Navigate to="/" replace />
  }

  return <Outlet />
}
