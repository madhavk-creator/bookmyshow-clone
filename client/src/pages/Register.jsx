import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useDispatch } from 'react-redux'
import { motion } from 'framer-motion'
import { Mail, Lock, User, Phone, ArrowRight, Loader } from 'lucide-react'
import { setCredentials } from '../store/authSlice'
import { api } from '../utils/api'
import { showApiErrorToast, showSuccessToast, showWarningToast } from '../utils/toast'

export default function Register() {
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
      const { data } = await api.post('/api/v1/users/register', { registration: formData })
      dispatch(setCredentials({ token: data.token, user: data.user }))
      showSuccessToast(`Account created for ${data.user?.name || formData.name}.`)
      navigate('/')
    } catch (err) {
      showApiErrorToast(err, 'Failed to register')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="flex-1 flex items-center justify-center min-h-[calc(100vh-4rem)] p-4 relative overflow-hidden py-12">
      {/* dynamic bg */}
      <div className="absolute top-10 left-10 w-80 h-80 bg-blue-600/20 rounded-full mix-blend-multiply filter blur-3xl animate-float" />
      <div className="absolute bottom-10 right-10 w-96 h-96 bg-primary-600/20 rounded-full mix-blend-multiply filter blur-3xl animate-float delay-1000" />

      <motion.div 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="w-full max-w-lg relative z-10 glass-card p-8"
      >
        <div className="text-center mb-8 gap-2 flex flex-col items-center">
          <h1 className="text-3xl font-bold tracking-tight text-neutral-900 dark:text-white">Create Account</h1>
          <p className="text-neutral-500 dark:text-neutral-400">Join us for the best movie booking experience</p>
        </div>
        <form onSubmit={handleRegister} className="space-y-4">
          <div className="space-y-1">
            <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Full Name</label>
            <div className="relative">
              <User className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
              <input type="text" name="name" required className="input-field pl-10" placeholder="John Doe" value={formData.name} onChange={handleChange} />
            </div>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-1">
              <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Email</label>
              <div className="relative">
                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
                <input type="email" name="email" required className="input-field pl-10" placeholder="yours@example.com" value={formData.email} onChange={handleChange} />
              </div>
            </div>
            
            <div className="space-y-1">
              <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Phone</label>
              <div className="relative">
                <Phone className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
                <input type="tel" name="phone" className="input-field pl-10" placeholder="1234567890" value={formData.phone} onChange={handleChange} />
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-1">
              <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Password</label>
              <div className="relative">
                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
                <input type="password" name="password" required className="input-field pl-10" placeholder="••••••••" value={formData.password} onChange={handleChange} />
              </div>
            </div>

            <div className="space-y-1">
              <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Confirm Password</label>
              <div className="relative">
                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
                <input type="password" name="password_confirmation" required className="input-field pl-10" placeholder="••••••••" value={formData.password_confirmation} onChange={handleChange} />
              </div>
            </div>
          </div>

          <button type="submit" disabled={loading} className="w-full btn-primary flex justify-center items-center py-3 mt-4 group">
            {loading ? <Loader className="w-5 h-5 animate-spin" /> : (
              <>
                <span>Create Account</span>
                <ArrowRight className="w-5 h-5 ml-2 group-hover:translate-x-1 transition-transform" />
              </>
            )}
          </button>
        </form>

        <p className="mt-6 text-center text-sm text-neutral-600 dark:text-neutral-400">
          Already have an account?{' '}
          <Link to="/login" className="text-primary-600 font-semibold hover:underline">Sign in</Link>
        </p>
      </motion.div>
    </div>
  )
}
