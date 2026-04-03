import { useState } from 'react'
import { Link, Outlet, useLocation, useNavigate } from 'react-router-dom'
import { useSelector, useDispatch } from 'react-redux'
import { clearCredentials, selectCurrentUser } from '../store/authSlice'
import {
  ShieldCheck, Film as FilmIcon, LayoutDashboard, Clapperboard, MapPin, Globe, MonitorPlay,
  Settings, LogOut, ChevronLeft, ChevronRight, Building2, UserPlus, Tag
} from 'lucide-react'

const sidebarLinks = [
  { to: '/admin',            icon: LayoutDashboard, label: 'Dashboard',  end: true },
  { to: '/admin/movies',     icon: Clapperboard,    label: 'Movies' },
  { to: '/admin/cities',     icon: MapPin,          label: 'Cities' },
  { to: '/admin/languages',  icon: Globe,           label: 'Languages' },
  { to: '/admin/formats',    icon: MonitorPlay,     label: 'Formats' },
  { to: '/admin/theatres',   icon: Building2,       label: 'Theatres' },
  { to: '/admin/coupons',    icon: Tag,             label: 'Coupons' },
  { to: '/admin/register',   icon: UserPlus,        label: 'Add Admin' },
  { to: '/admin/settings',   icon: Settings,        label: 'Settings' },
]

export default function AdminLayout() {
  const [collapsed, setCollapsed] = useState(false)
  const dispatch = useDispatch()
  const user = useSelector(selectCurrentUser)
  const location = useLocation()
  const navigate = useNavigate()

  const handleLogout = () => {
    dispatch(clearCredentials())
    navigate('/')
  }

  const getInitials = (name) => {
    if (!name) return '?'
    return name.split(' ').map(w => w[0]).join('').toUpperCase().slice(0, 2)
  }

  return (
    <div className="flex min-h-screen bg-neutral-50 dark:bg-[#0b090f]">
      <aside className={`fixed top-0 left-0 h-screen z-40 flex flex-col border-r border-neutral-200 dark:border-neutral-800 bg-white/80 dark:bg-neutral-950/80 backdrop-blur-xl transition-all duration-300 ${collapsed ? 'w-20' : 'w-64'}`}>
        <div className="flex items-center h-16 px-4 border-b border-neutral-200 dark:border-neutral-800">
          <Link to="/" className="flex items-center gap-2 text-primary-600 dark:text-primary-500">
            <FilmIcon className="h-7 w-7 shrink-0" />
            {!collapsed && <span className="font-bold text-lg tracking-tight text-neutral-900 dark:text-white glow-text whitespace-nowrap">CineBooking</span>}
          </Link>
        </div>

        <div className={`px-4 py-4 border-b border-neutral-200 dark:border-neutral-800 ${collapsed ? 'flex justify-center' : ''}`}>
          <div className={`flex items-center gap-3 ${collapsed ? 'justify-center' : ''}`}>
            <div className="w-10 h-10 rounded-full bg-gradient-to-br from-rose-500 to-red-600 flex items-center justify-center text-white text-sm font-bold shadow-lg shadow-rose-500/20 shrink-0">
              {getInitials(user?.name)}
            </div>
            {!collapsed && (
              <div className="min-w-0">
                <p className="text-sm font-semibold text-neutral-900 dark:text-white truncate">{user?.name}</p>
                <span className="inline-block text-[10px] font-bold uppercase tracking-widest px-2 py-0.5 rounded-full bg-rose-500/10 text-rose-600 dark:text-rose-400 border border-rose-500/20">
                  Admin
                </span>
              </div>
            )}
          </div>
        </div>

        <nav className="flex-1 py-4 px-3 space-y-1 overflow-y-auto">
          {sidebarLinks.map(link => {
            const isActive = link.end
              ? location.pathname === link.to
              : location.pathname.startsWith(link.to)
            return (
              <Link
                key={link.to}
                to={link.to}
                className={`flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-colors ${
                  isActive
                    ? 'bg-rose-500/10 text-rose-600 dark:text-rose-400 border border-rose-500/20'
                    : 'text-neutral-600 dark:text-neutral-400 hover:bg-neutral-100 dark:hover:bg-neutral-800/60 hover:text-neutral-900 dark:hover:text-neutral-200'
                } ${collapsed ? 'justify-center' : ''}`}
                title={link.label}
              >
                <link.icon className="w-5 h-5 shrink-0" />
                {!collapsed && <span>{link.label}</span>}
              </Link>
            )
          })}
        </nav>

        <div className="p-3 border-t border-neutral-200 dark:border-neutral-800 space-y-1">
          <button onClick={handleLogout} className={`flex items-center gap-3 w-full px-3 py-2.5 rounded-xl text-sm font-medium text-red-500 hover:bg-red-500/10 transition-colors cursor-pointer ${collapsed ? 'justify-center' : ''}`} title="Log Out">
            <LogOut className="w-5 h-5 shrink-0" />
            {!collapsed && <span>Log Out</span>}
          </button>
          <button onClick={() => setCollapsed(prev => !prev)} className={`flex items-center gap-3 w-full px-3 py-2.5 rounded-xl text-sm font-medium text-neutral-500 hover:bg-neutral-100 dark:hover:bg-neutral-800/60 transition-colors cursor-pointer ${collapsed ? 'justify-center' : ''}`} title={collapsed ? 'Expand' : 'Collapse'}>
            {collapsed ? <ChevronRight className="w-5 h-5" /> : <><ChevronLeft className="w-5 h-5 shrink-0" /><span>Collapse</span></>}
          </button>
        </div>
      </aside>

      <main className={`flex-1 transition-all duration-300 ${collapsed ? 'ml-20' : 'ml-64'}`}>
        <Outlet />
      </main>
    </div>
  )
}
