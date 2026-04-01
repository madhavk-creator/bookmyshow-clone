import { Outlet, Link, useLocation } from 'react-router-dom'
import { ShieldCheck, Film } from 'lucide-react'

export default function AdminAuthLayout() {
  const location = useLocation()
  const isLogin = location.pathname === '/admin/login'

  return (
    <div className="min-h-screen flex flex-col bg-neutral-50 dark:bg-[#0b090f] relative overflow-hidden">
      <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-rose-500/10 rounded-full mix-blend-multiply filter blur-3xl animate-float" />
      <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-primary-600/10 rounded-full mix-blend-multiply filter blur-3xl animate-float" style={{ animationDelay: '3s' }} />
      <div className="absolute top-1/2 right-1/3 w-72 h-72 bg-sky-500/10 rounded-full mix-blend-multiply filter blur-3xl animate-float" style={{ animationDelay: '5s' }} />

      <header className="relative z-10 flex items-center justify-between px-6 py-4 max-w-7xl mx-auto w-full">
        <Link to="/" className="flex items-center gap-2 text-primary-600 dark:text-primary-500 hover:scale-105 transition-transform">
          <Film className="h-7 w-7" />
          <span className="font-bold text-lg tracking-tight text-neutral-900 dark:text-white glow-text">CineBooking</span>
        </Link>
      </header>

      <div className="relative z-10 flex justify-center mt-4 mb-2">
        <div className="flex items-center gap-2 px-4 py-1.5 rounded-full bg-rose-500/10 border border-rose-500/20">
          <ShieldCheck className="w-4 h-4 text-rose-500" />
          <span className="text-xs font-bold uppercase tracking-widest text-rose-600 dark:text-rose-400">Admin Console</span>
        </div>
      </div>

      <main className="flex-1 flex items-center justify-center p-4 relative z-10">
        <Outlet />
      </main>

      <footer className="relative z-10 text-center py-6 text-xs text-neutral-400 dark:text-neutral-600">
        Looking to book tickets? <Link to="/" className="text-primary-500 hover:underline font-medium">Go to CineBooking</Link>
      </footer>
    </div>
  )
}
