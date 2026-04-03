import { Routes, Route } from 'react-router-dom'
import ProtectedRoute from './components/ProtectedRoute'
import PublicLayout from './layouts/PublicLayout'
import VendorAuthLayout from './layouts/VendorAuthLayout'
import VendorLayout from './layouts/VendorLayout'
import AdminAuthLayout from './layouts/AdminAuthLayout'
import AdminLayout from './layouts/AdminLayout'
import Home from './pages/Home'
import Login from './pages/Login'
import Register from './pages/Register'
import VendorLogin from './pages/vendor/VendorLogin'
import VendorRegister from './pages/vendor/VendorRegister'
import VendorDashboard from './pages/vendor/VendorDashboard'
import VendorTheatres from './pages/vendor/VendorTheatres'
import VendorScreens from './pages/vendor/VendorScreens'
import VendorSettings from './pages/vendor/VendorSettings'
import SeatLayoutManager from './pages/vendor/SeatLayoutManager'
import SeatLayoutEditor from './pages/vendor/SeatLayoutEditor'
import VendorShows from './pages/vendor/VendorShows'
import VendorShowEditor from './pages/vendor/VendorShowEditor'
import AdminLogin from './pages/admin/AdminLogin'
import AdminDashboard from './pages/admin/AdminDashboard'
import AdminMovies from './pages/admin/AdminMovies'
import AdminCities from './pages/admin/AdminCities'
import AdminLanguages from './pages/admin/AdminLanguages'
import AdminFormats from './pages/admin/AdminFormats'
import AdminTheatres from './pages/admin/AdminTheatres'
import AdminRegisterPage from './pages/admin/AdminRegister'
import AdminScreens from './pages/admin/AdminScreens'
import AdminSeatLayoutManager from './pages/admin/AdminSeatLayoutManager'
import AdminSeatLayoutEditor from './pages/admin/AdminSeatLayoutEditor'

function App() {
  return (
    <Routes>
      {/* Public routes (top navbar) */}
      <Route element={<PublicLayout />}>
        <Route path="/" element={<Home />} />
        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />
      </Route>

      {/* Vendor auth (standalone) */}
      <Route element={<VendorAuthLayout />}>
        <Route path="/vendor/login" element={<VendorLogin />} />
        <Route path="/vendor/register" element={<VendorRegister />} />
      </Route>

      {/* Vendor dashboard (sidebar) */}
      <Route element={<ProtectedRoute allowedRoles={['vendor']} />}>
        <Route path="/vendor" element={<VendorLayout />}>
          <Route index element={<VendorDashboard />} />
          <Route path="theatres" element={<VendorTheatres />} />
          <Route path="screens" element={<VendorScreens />} />
          <Route path="layouts/:theatreId/:screenId" element={<SeatLayoutManager />} />
          <Route path="layouts/:theatreId/:screenId/:layoutId" element={<SeatLayoutEditor />} />
          <Route path="shows/:theatreId/:screenId" element={<VendorShows />} />
          <Route path="shows/:theatreId/:screenId/new" element={<VendorShowEditor />} />
          <Route path="shows/:theatreId/:screenId/:showId/edit" element={<VendorShowEditor />} />
          <Route path="settings" element={<VendorSettings />} />
        </Route>
      </Route>

      {/* Admin auth (standalone) */}
      <Route element={<AdminAuthLayout />}>
        <Route path="/admin/login" element={<AdminLogin />} />
      </Route>

      {/* Admin dashboard (sidebar) */}
      <Route element={<ProtectedRoute allowedRoles={['admin']} />}>
        <Route path="/admin" element={<AdminLayout />}>
          <Route index element={<AdminDashboard />} />
          <Route path="movies" element={<AdminMovies />} />
          <Route path="cities" element={<AdminCities />} />
          <Route path="languages" element={<AdminLanguages />} />
          <Route path="formats" element={<AdminFormats />} />
          <Route path="theatres" element={<AdminTheatres />} />
          <Route path="theatres/:theatreId/screens" element={<AdminScreens />} />
          <Route path="layouts/:theatreId/:screenId" element={<AdminSeatLayoutManager />} />
          <Route path="layouts/:theatreId/:screenId/:layoutId" element={<AdminSeatLayoutEditor />} />
          <Route path="register" element={<AdminRegisterPage />} />
        </Route>
      </Route>
    </Routes>
  )
}

export default App
