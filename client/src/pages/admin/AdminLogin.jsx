import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useDispatch } from 'react-redux'
import { motion } from 'framer-motion'
import { Mail, Lock, ArrowRight, Loader } from 'lucide-react'
import { setCredentials } from '../../store/authSlice'
import { api } from '../../utils/api'
import { showApiErrorToast, showSuccessToast } from '../../utils/toast'

export default function AdminLogin() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const navigate = useNavigate()
  const dispatch = useDispatch()

  const handleLogin = async (e) => {
    e.preventDefault()
    setLoading(true)

    try {
      const { data } = await api.post('/api/v1/admin/login', { email, password })
      dispatch(setCredentials({ token: data.token, user: data.user }))
      showSuccessToast(`Admin access granted for ${data.user?.name || 'your account'}.`)
      navigate('/admin')
    } catch (err) {
      showApiErrorToast(err, 'Invalid credentials')
    } finally {
      setLoading(false)
    }
  }

  return (
    <motion.div initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} transition={{ duration: 0.5 }} className="w-full max-w-md relative z-10 glass-card p-8">
      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold tracking-tight text-neutral-900 dark:text-white">Admin Login</h1>
        <p className="text-neutral-500 dark:text-neutral-400 mt-2">Access the administration console</p>
      </div>
      <form onSubmit={handleLogin} className="space-y-6">
        <div className="space-y-2">
          <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Email</label>
          <div className="relative">
            <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-neutral-400" />
            <input type="email" required className="input-field" placeholder="admin@cinebooking.com" value={email} onChange={(e) => setEmail(e.target.value)} />
          </div>
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Password</label>
          <div className="relative">
            <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-neutral-400" />
            <input type="password" required className="input-field" placeholder="••••••••" value={password} onChange={(e) => setPassword(e.target.value)} />
          </div>
        </div>
        <button type="submit" disabled={loading} className="w-full bg-gradient-to-r from-rose-600 to-red-600 hover:from-rose-500 hover:to-red-500 text-white font-medium py-3 px-6 rounded-xl shadow-lg shadow-rose-500/30 transition-all hover:shadow-rose-500/50 hover:scale-105 active:scale-95 flex justify-center items-center group disabled:opacity-70 disabled:pointer-events-none cursor-pointer">
          {loading ? <Loader className="w-5 h-5 animate-spin" /> : (<><span>Sign In</span><ArrowRight className="w-5 h-5 ml-2 group-hover:translate-x-1 transition-transform" /></>)}
        </button>
      </form>
    </motion.div>
  )
}
