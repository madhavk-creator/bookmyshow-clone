import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useDispatch } from 'react-redux'
import { motion } from 'framer-motion'
import { Mail, Lock, User, Phone, ArrowRight, Loader } from 'lucide-react'
import { setCredentials } from '../../store/authSlice'
import { api } from '../../utils/api'
import { showApiErrorToast, showSuccessToast, showWarningToast } from '../../utils/toast'

export default function VendorRegister() {
  const [formData, setFormData] = useState({
    name: '', email: '', phone: '', password: '', password_confirmation: ''
  })
  const [loading, setLoading] = useState(false)
  const navigate = useNavigate()
  const dispatch = useDispatch()

  const handleChange = (e) => setFormData(p => ({ ...p, [e.target.name]: e.target.value }))

  const handleRegister = async (e) => {
    e.preventDefault()
    setLoading(true)

    if (formData.password !== formData.password_confirmation) {
      showWarningToast('Passwords do not match.')
      setLoading(false)
      return
    }

    try {
      const { data } = await api.post('/api/v1/vendors/register', { registration: formData })
      dispatch(setCredentials({ token: data.token, user: data.user }))
      showSuccessToast(`Welcome aboard, ${data.user?.name || formData.name}.`)
      navigate('/vendor')
    } catch (err) {
      showApiErrorToast(err, 'Registration failed')
    } finally {
      setLoading(false)
    }
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5 }}
      className="w-full max-w-lg relative z-10 glass-card p-8"
    >
      <div className="text-center mb-8 gap-2 flex flex-col items-center">
        <h1 className="text-3xl font-bold tracking-tight text-neutral-900 dark:text-white">Create Vendor Account</h1>
        <p className="text-neutral-500 dark:text-neutral-400">Register to list your theatres and manage screens</p>
      </div>
      <form onSubmit={handleRegister} className="space-y-4">
        <div className="space-y-1">
          <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Full Name</label>
          <div className="relative">
            <User className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
            <input type="text" name="name" required className="input-field" placeholder="John Doe" value={formData.name} onChange={handleChange} />
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="space-y-1">
            <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Email</label>
            <div className="relative">
              <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
              <input type="email" name="email" required className="input-field" placeholder="vendor@company.com" value={formData.email} onChange={handleChange} />
            </div>
          </div>
          <div className="space-y-1">
            <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Phone</label>
            <div className="relative">
              <Phone className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
              <input type="tel" name="phone" className="input-field" placeholder="9876543210" value={formData.phone} onChange={handleChange} />
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="space-y-1">
            <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Password</label>
            <div className="relative">
              <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
              <input type="password" name="password" required className="input-field" placeholder="••••••••" value={formData.password} onChange={handleChange} />
            </div>
          </div>
          <div className="space-y-1">
            <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Confirm Password</label>
            <div className="relative">
              <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
              <input type="password" name="password_confirmation" required className="input-field" placeholder="••••••••" value={formData.password_confirmation} onChange={handleChange} />
            </div>
          </div>
        </div>

        <button type="submit" disabled={loading}
          className="w-full mt-2 bg-gradient-to-r from-amber-600 to-orange-600 hover:from-amber-500 hover:to-orange-500 text-white font-medium py-3 px-6 rounded-xl shadow-lg shadow-amber-500/30 transition-all hover:shadow-amber-500/50 hover:scale-105 active:scale-95 flex justify-center items-center group disabled:opacity-70 disabled:pointer-events-none cursor-pointer">
          {loading ? <Loader className="w-5 h-5 animate-spin" /> : (
            <>
              <span>Create Vendor Account</span>
              <ArrowRight className="w-5 h-5 ml-2 group-hover:translate-x-1 transition-transform" />
            </>
          )}
        </button>
      </form>

      <p className="mt-6 text-center text-sm text-neutral-600 dark:text-neutral-400">
        Already registered? <Link to="/vendor/login" className="text-amber-500 font-semibold hover:underline">Sign in</Link>
      </p>
    </motion.div>
  )
}
