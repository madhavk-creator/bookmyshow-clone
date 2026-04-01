import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useDispatch } from 'react-redux'
import { motion } from 'framer-motion'
import { Mail, Lock, ArrowRight, Loader } from 'lucide-react'
import { setCredentials } from '../../store/authSlice'

export default function VendorLogin() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  const navigate = useNavigate()
  const dispatch = useDispatch()

  const handleLogin = async (e) => {
    e.preventDefault()
    setLoading(true)
    setError(null)

    try {
      const res = await fetch('/api/v1/vendors/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      })

      const data = await res.json()
      if (!res.ok) throw new Error(data.error || 'Invalid credentials')

      dispatch(setCredentials({ token: data.token, user: data.user }))
      navigate('/vendor')
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 0.5 }}
      className="w-full max-w-md relative z-10 glass-card p-8"
    >
      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold tracking-tight text-neutral-900 dark:text-white">Welcome Back</h1>
        <p className="text-neutral-500 dark:text-neutral-400 mt-2">Sign in to manage your theatres and screens</p>
      </div>

      {error && (
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="mb-4 p-3 rounded-lg bg-red-500/10 border border-red-500/50 text-red-500 text-sm text-center font-medium">
          {error}
        </motion.div>
      )}

      <form onSubmit={handleLogin} className="space-y-6">
        <div className="space-y-2">
          <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Email</label>
          <div className="relative">
            <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-neutral-400" />
            <input type="email" required className="input-field" placeholder="vendor@company.com" value={email} onChange={(e) => setEmail(e.target.value)} />
          </div>
        </div>

        <div className="space-y-2">
          <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Password</label>
          <div className="relative">
            <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-neutral-400" />
            <input type="password" required className="input-field" placeholder="••••••••" value={password} onChange={(e) => setPassword(e.target.value)} />
          </div>
        </div>

        <button type="submit" disabled={loading}
          className="w-full bg-gradient-to-r from-amber-600 to-orange-600 hover:from-amber-500 hover:to-orange-500 text-white font-medium py-3 px-6 rounded-xl shadow-lg shadow-amber-500/30 transition-all hover:shadow-amber-500/50 hover:scale-105 active:scale-95 flex justify-center items-center group disabled:opacity-70 disabled:pointer-events-none cursor-pointer">
          {loading ? <Loader className="w-5 h-5 animate-spin" /> : (
            <>
              <span>Sign In to Dashboard</span>
              <ArrowRight className="w-5 h-5 ml-2 group-hover:translate-x-1 transition-transform" />
            </>
          )}
        </button>
      </form>

      <p className="mt-6 text-center text-sm text-neutral-600 dark:text-neutral-400">
        Don't have an account? <Link to="/vendor/register" className="text-amber-500 font-semibold hover:underline">Register</Link>
      </p>
    </motion.div>
  )
}
