import { useState } from 'react'
import { Link } from 'react-router-dom'
import { Film, LogIn, UserPlus } from 'lucide-react'

export default function Navbar() {
  return (
    <nav className="fixed top-0 left-0 right-0 z-50 glass">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          <div className="flex items-center">
            <Link to="/" className="flex items-center gap-2 text-primary-600 dark:text-primary-500 hover:scale-105 transition-transform">
              <Film className="h-8 w-8" />
              <span className="font-bold text-xl tracking-tight text-neutral-900 dark:text-white glow-text">CineBooking</span>
            </Link>
          </div>
          <div className="flex items-center space-x-4">
            <Link to="/login" className="nav-link flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors">
              <LogIn className="h-5 w-5" />
              <span>Login</span>
            </Link>
            <Link to="/register" className="btn-primary flex items-center gap-2">
              <UserPlus className="h-5 w-5" />
              <span>Register</span>
            </Link>
          </div>
        </div>
      </div>
    </nav>
  )
}
