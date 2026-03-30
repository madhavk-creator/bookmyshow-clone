import { Outlet, Link, useLocation } from 'react-router-dom'
import { Building2, Film } from 'lucide-react'

export default function VendorAuthLayout() {
  const location = useLocation()
  const isLogin = location.pathname === '/vendor/login'

  return (
    <div className="min-h-screen flex flex-col bg-neutral-50 dark:bg-[#0b090f] relative overflow-hidden">
      {/* Floating BG blobs */}
      <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-amber-500/10 rounded-full mix-blend-multiply filter blur-3xl animate-float" />
      <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-primary-600/10 rounded-full mix-blend-multiply filter blur-3xl animate-float" style={{ animationDelay: '3s' }} />
      <div className="absolute top-1/2 right-1/3 w-72 h-72 bg-orange-500/10 rounded-full mix-blend-multiply filter blur-3xl animate-float" style={{ animationDelay: '5s' }} />

      {/* Minimal header */}
      <header className="relative z-10 flex items-center justify-between px-6 py-4 max-w-7xl mx-auto w-full">
        <Link to="/" className="flex items-center gap-2 text-primary-600 dark:text-primary-500 hover:scale-105 transition-transform">
          <Film className="h-7 w-7" />
          <span className="font-bold text-lg tracking-tight text-neutral-900 dark:text-white glow-text">CineBooking</span>
        </Link>

        <div className="flex items-center gap-1 bg-neutral-200/50 dark:bg-neutral-800/50 rounded-xl p-1 backdrop-blur-sm">
          <Link
            to="/vendor/login"
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-all ${
              isLogin
                ? 'bg-white dark:bg-neutral-900 text-amber-600 dark:text-amber-400 shadow-sm'
                : 'text-neutral-500 dark:text-neutral-400 hover:text-neutral-700 dark:hover:text-neutral-200'
            }`}
          >
            Sign In
          </Link>
          <Link
            to="/vendor/register"
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-all ${
              !isLogin
                ? 'bg-white dark:bg-neutral-900 text-amber-600 dark:text-amber-400 shadow-sm'
                : 'text-neutral-500 dark:text-neutral-400 hover:text-neutral-700 dark:hover:text-neutral-200'
            }`}
          >
            Register
          </Link>
        </div>
      </header>

      {/* Vendor badge */}
      <div className="relative z-10 flex justify-center mt-4 mb-2">
        <div className="flex items-center gap-2 px-4 py-1.5 rounded-full bg-amber-500/10 border border-amber-500/20">
          <Building2 className="w-4 h-4 text-amber-500" />
          <span className="text-xs font-bold uppercase tracking-widest text-amber-600 dark:text-amber-400">Vendor Portal</span>
        </div>
      </div>

      {/* Content */}
      <main className="flex-1 flex items-center justify-center p-4 relative z-10">
        <Outlet />
      </main>

      {/* Footer link */}
      <footer className="relative z-10 text-center py-6 text-xs text-neutral-400 dark:text-neutral-600">
        Looking to book tickets instead? <Link to="/" className="text-primary-500 hover:underline font-medium">Go to CineBooking</Link>
      </footer>
    </div>
  )
}
