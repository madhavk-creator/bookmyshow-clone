import { useState } from 'react'
import { useSelector } from 'react-redux'
import { motion } from 'framer-motion'
import { Mail, Lock, User, Phone, ShieldCheck, ArrowRight, Loader, CheckCircle } from 'lucide-react'
import { selectCurrentToken } from '../../store/authSlice'

export default function AdminRegister() {
  const token = useSelector(selectCurrentToken)
  const [formData, setFormData] = useState({ name: '', email: '', phone: '', password: '', password_confirmation: '' })
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  const [success, setSuccess] = useState(null)

  const handleChange = (e) => setFormData(p => ({ ...p, [e.target.name]: e.target.value }))

  const handleRegister = async (e) => {
    e.preventDefault()
    setLoading(true)
    setError(null)
    setSuccess(null)

    if (formData.password !== formData.password_confirmation) {
      setError("Passwords do not match")
      setLoading(false)
      return
    }

    try {
      const res = await fetch('/api/v1/admin/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ registration: formData }),
      })
      const data = await res.json()
      if (!res.ok) throw new Error(data.errors?.join(', ') || data.error || 'Registration failed')
      setSuccess(`Admin "${data.user?.name || formData.name}" created successfully!`)
      setFormData({ name: '', email: '', phone: '', password: '', password_confirmation: '' })
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="p-6 lg:p-8 max-w-2xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-neutral-900 dark:text-white">Register New Admin</h1>
        <p className="text-neutral-500 dark:text-neutral-400 mt-1">Create a new administrator account</p>
      </div>

      <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="glass-card p-8 hover:translate-y-0">
        <div className="flex items-center gap-3 mb-6 p-3 rounded-xl bg-rose-500/5 border border-rose-500/10">
          <ShieldCheck className="w-5 h-5 text-rose-500 shrink-0" />
          <p className="text-sm text-neutral-600 dark:text-neutral-400">This action requires your current admin credentials. The new admin will have full platform access.</p>
        </div>

        {error && (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="mb-4 p-3 rounded-lg bg-red-500/10 border border-red-500/50 text-red-500 text-sm text-center font-medium">{error}</motion.div>
        )}
        {success && (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="mb-4 p-3 rounded-lg bg-emerald-500/10 border border-emerald-500/50 text-emerald-600 dark:text-emerald-400 text-sm text-center font-medium flex items-center justify-center gap-2">
            <CheckCircle className="w-4 h-4" /> {success}
          </motion.div>
        )}

        <form onSubmit={handleRegister} className="space-y-4">
          <div className="space-y-1">
            <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Full Name</label>
            <div className="relative">
              <User className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
              <input type="text" name="name" required className="input-field" placeholder="Admin Name" value={formData.name} onChange={handleChange} />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-1">
              <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Email</label>
              <div className="relative">
                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
                <input type="email" name="email" required className="input-field" placeholder="admin@cinebooking.com" value={formData.email} onChange={handleChange} />
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
            className="w-full mt-2 bg-gradient-to-r from-rose-600 to-red-600 hover:from-rose-500 hover:to-red-500 text-white font-medium py-3 px-6 rounded-xl shadow-lg shadow-rose-500/30 transition-all hover:shadow-rose-500/50 hover:scale-105 active:scale-95 flex justify-center items-center group disabled:opacity-70 disabled:pointer-events-none cursor-pointer">
            {loading ? <Loader className="w-5 h-5 animate-spin" /> : (<><span>Create Admin</span><ArrowRight className="w-5 h-5 ml-2 group-hover:translate-x-1 transition-transform" /></>)}
          </button>
        </form>
      </motion.div>
    </div>
  )
}
