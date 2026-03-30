import { useState, useRef, useEffect } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useSelector, useDispatch } from 'react-redux'
import { Film, LogIn, UserPlus, ChevronDown, Settings, LogOut, User, Ticket, Building2, ShieldCheck } from 'lucide-react'
import { clearCredentials, selectCurrentUser, selectIsLoggedIn } from '../store/authSlice'

export default function Navbar() {
  const dispatch = useDispatch()
  const user = useSelector(selectCurrentUser)
  const isLoggedIn = useSelector(selectIsLoggedIn)
  const [dropdownOpen, setDropdownOpen] = useState(false)
  const dropdownRef = useRef(null)
  const navigate = useNavigate()

  // Close dropdown on outside click
  useEffect(() => {
    function handleClickOutside(e) {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target)) {
        setDropdownOpen(false)
      }
    }
    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [])

  const handleLogout = () => {
    dispatch(clearCredentials())
    setDropdownOpen(false)
    navigate('/')
  }

  // Get initials for avatar
  const getInitials = (name) => {
    if (!name) return '?'
    return name.split(' ').map(w => w[0]).join('').toUpperCase().slice(0, 2)
  }

  return (
    <nav className="fixed top-0 left-0 right-0 z-50 glass">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <div className="flex items-center">
            <Link to="/" className="flex items-center gap-2 text-primary-600 dark:text-primary-500 hover:scale-105 transition-transform">
              <Film className="h-8 w-8" />
              <span className="font-bold text-xl tracking-tight text-neutral-900 dark:text-white glow-text">CineBooking</span>
            </Link>
          </div>

          {/* Right Side */}
          <div className="flex items-center space-x-4">
            {isLoggedIn ? (
              /* ── Logged-in: Profile Dropdown ── */
              <div className="relative" ref={dropdownRef}>
                <button
                  onClick={() => setDropdownOpen(prev => !prev)}
                  className="flex items-center gap-2 px-2 py-1.5 rounded-xl hover:bg-neutral-100 dark:hover:bg-neutral-800/60 transition-colors cursor-pointer"
                >
                  {/* Avatar Circle */}
                  <div className="w-9 h-9 rounded-full bg-gradient-to-br from-primary-500 to-purple-600 flex items-center justify-center text-white text-sm font-bold shadow-lg shadow-primary-500/20">
                    {getInitials(user?.name)}
                  </div>
                  <span className="hidden sm:block text-sm font-medium text-neutral-700 dark:text-neutral-200 max-w-[120px] truncate">
                    {user?.name}
                  </span>
                  <ChevronDown className={`w-4 h-4 text-neutral-500 transition-transform duration-200 ${dropdownOpen ? 'rotate-180' : ''}`} />
                </button>

                {/* Dropdown Menu */}
                {dropdownOpen && (
                  <div className="absolute right-0 mt-2 w-64 rounded-2xl glass-card py-2 overflow-hidden animate-in fade-in slide-in-from-top-2 duration-200">
                    {/* User Info Header */}
                    <div className="px-4 py-3 border-b border-neutral-200 dark:border-neutral-700/50">
                      <p className="text-sm font-semibold text-neutral-900 dark:text-white truncate">{user?.name}</p>
                      <p className="text-xs text-neutral-500 dark:text-neutral-400 truncate">{user?.email}</p>
                      <span className="inline-block mt-1.5 text-[10px] font-bold uppercase tracking-widest px-2 py-0.5 rounded-full bg-primary-500/10 text-primary-600 dark:text-primary-400 border border-primary-500/20">
                        {user?.role}
                      </span>
                    </div>

                    {/* Menu Items */}
                    <div className="py-1">
                      <Link
                        to="/"
                        onClick={() => setDropdownOpen(false)}
                        className="flex items-center gap-3 px-4 py-2.5 text-sm text-neutral-700 dark:text-neutral-300 hover:bg-neutral-100 dark:hover:bg-neutral-800/60 transition-colors"
                      >
                        <User className="w-4 h-4 text-neutral-400" />
                        My Profile
                      </Link>
                      <Link
                        to="/"
                        onClick={() => setDropdownOpen(false)}
                        className="flex items-center gap-3 px-4 py-2.5 text-sm text-neutral-700 dark:text-neutral-300 hover:bg-neutral-100 dark:hover:bg-neutral-800/60 transition-colors"
                      >
                        <Ticket className="w-4 h-4 text-neutral-400" />
                        My Bookings
                      </Link>
                      {user?.role === 'vendor' && (
                        <Link
                          to="/vendor"
                          onClick={() => setDropdownOpen(false)}
                          className="flex items-center gap-3 px-4 py-2.5 text-sm text-amber-600 dark:text-amber-400 hover:bg-amber-500/10 transition-colors"
                        >
                          <Building2 className="w-4 h-4" />
                          Vendor Dashboard
                        </Link>
                      )}
                      {user?.role === 'admin' && (
                        <Link
                          to="/admin"
                          onClick={() => setDropdownOpen(false)}
                          className="flex items-center gap-3 px-4 py-2.5 text-sm text-rose-600 dark:text-rose-400 hover:bg-rose-500/10 transition-colors"
                        >
                          <ShieldCheck className="w-4 h-4" />
                          Admin Console
                        </Link>
                      )}
                      <Link
                        to="/"
                        onClick={() => setDropdownOpen(false)}
                        className="flex items-center gap-3 px-4 py-2.5 text-sm text-neutral-700 dark:text-neutral-300 hover:bg-neutral-100 dark:hover:bg-neutral-800/60 transition-colors"
                      >
                        <Settings className="w-4 h-4 text-neutral-400" />
                        Settings
                      </Link>
                    </div>

                    {/* Logout */}
                    <div className="border-t border-neutral-200 dark:border-neutral-700/50 pt-1">
                      <button
                        onClick={handleLogout}
                        className="flex items-center gap-3 w-full px-4 py-2.5 text-sm text-red-500 hover:bg-red-500/10 transition-colors cursor-pointer"
                      >
                        <LogOut className="w-4 h-4" />
                        Log Out
                      </button>
                    </div>
                  </div>
                )}
              </div>
            ) : (
              /* ── Logged-out: Login & Register ── */
              <>
                <Link to="/login" className="nav-link flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors">
                  <LogIn className="h-5 w-5" />
                  <span>Login</span>
                </Link>
                <Link to="/register" className="btn-primary flex items-center gap-2">
                  <UserPlus className="h-5 w-5" />
                  <span>Register</span>
                </Link>
              </>
            )}
          </div>
        </div>
      </div>
    </nav>
  )
}
