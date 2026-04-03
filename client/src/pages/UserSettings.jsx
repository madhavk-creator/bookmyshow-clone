import { useState } from 'react'
import { useSelector, useDispatch } from 'react-redux'
import { useNavigate } from 'react-router-dom'
import { selectCurrentUser, setCredentials, selectCurrentToken, clearCredentials } from '../store/authSlice'
import { api, extractApiError } from '../utils/api'
import { showApiErrorToast, showSuccessToast } from '../utils/toast'
import { User, Lock, Mail, Phone, Loader, Bell } from 'lucide-react'

export default function UserSettings() {
  const user = useSelector(selectCurrentUser)
  const token = useSelector(selectCurrentToken)
  const dispatch = useDispatch()
  const navigate = useNavigate()

  const [activeTab, setActiveTab] = useState('profile') // 'profile', 'password', 'notifications'

  // Profile Form State
  const [profileData, setProfileData] = useState({
    name: user?.name || '',
    email: user?.email || '',
    phone: user?.phone || ''
  })
  const [savingProfile, setSavingProfile] = useState(false)

  // Password Form State
  const [passwordData, setPasswordData] = useState({
    current_password: '',
    password: '',
    password_confirmation: ''
  })
  const [savingPassword, setSavingPassword] = useState(false)

  const getEndpointPrefix = () => {
    if (user?.role === 'admin') return '/api/v1/admin'
    if (user?.role === 'vendor') return '/api/v1/vendors'
    return '/api/v1/users'
  }

  const handleProfileUpdate = async (e) => {
    e.preventDefault()
    setSavingProfile(true)
    try {
      const endpoint = `${getEndpointPrefix()}/profile`
      const { data } = await api.patch(endpoint, { profile: profileData })
      // API returns { token, user }
      dispatch(setCredentials({ token: data.token || token, user: data.user }))
      showSuccessToast('Profile updated successfully')
    } catch (err) {
      showApiErrorToast(err, 'Failed to update profile')
    } finally {
      setSavingProfile(false)
    }
  }

  const handlePasswordUpdate = async (e) => {
    e.preventDefault()
    if (passwordData.password !== passwordData.password_confirmation) {
      showApiErrorToast({ response: { data: { errors: ['New passwords do not match'] } } }, 'Failed to change password')
      return
    }
    setSavingPassword(true)
    try {
      const endpoint = `${getEndpointPrefix()}/password`
      await api.patch(endpoint, { password: passwordData })
      showSuccessToast('Password changed successfully. Please log in again.')
      setPasswordData({ current_password: '', password: '', password_confirmation: '' })

      dispatch(clearCredentials())
      if (user?.role === 'admin') navigate('/admin/login')
      else if (user?.role === 'vendor') navigate('/vendor/login')
      else navigate('/login')
    } catch (err) {
      showApiErrorToast(err, 'Failed to change password')
    } finally {
      setSavingPassword(false)
    }
  }

  return (
    <div className="min-h-screen bg-neutral-50 dark:bg-[#0b090f] py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-4xl mx-auto flex flex-col md:flex-row gap-8 animate-slide-up">

        {/* Sidebar Navigation */}
        <div className="w-full md:w-64 shrink-0 space-y-2">
          <h1 className="text-2xl font-black text-neutral-900 dark:text-white mb-6 px-4">Settings</h1>

          <button
            onClick={() => setActiveTab('profile')}
            className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl font-bold transition-all text-left
              ${activeTab === 'profile'
                ? 'bg-primary-500/10 text-primary-600 dark:text-primary-400'
                : 'text-neutral-500 hover:bg-neutral-100 dark:hover:bg-neutral-800'}`}
          >
            <User className="w-5 h-5" /> Account Details
          </button>

          <button
            onClick={() => setActiveTab('password')}
            className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl font-bold transition-all text-left
              ${activeTab === 'password'
                ? 'bg-primary-500/10 text-primary-600 dark:text-primary-400'
                : 'text-neutral-500 hover:bg-neutral-100 dark:hover:bg-neutral-800'}`}
          >
            <Lock className="w-5 h-5" /> Change Password
          </button>

          <button
            onClick={() => setActiveTab('notifications')}
            className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl font-bold transition-all text-left
              ${activeTab === 'notifications'
                ? 'bg-primary-500/10 text-primary-600 dark:text-primary-400'
                : 'text-neutral-500 hover:bg-neutral-100 dark:hover:bg-neutral-800'}`}
          >
            <Bell className="w-5 h-5" /> Notifications setup
          </button>
        </div>

        {/* Content Area */}
        <div className="flex-1">
          {activeTab === 'profile' && (
            <div className="glass-card rounded-2xl p-6 sm:p-10 animate-fade-in">
              <h2 className="text-2xl font-bold text-neutral-900 dark:text-white mb-6 border-b border-neutral-200 dark:border-neutral-800 pb-4">Personal Information</h2>
              <form onSubmit={handleProfileUpdate} className="space-y-6">
                <div>
                  <label className="block text-sm font-bold text-neutral-500 uppercase tracking-widest mb-2">Full Name</label>
                  <div className="relative">
                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-neutral-400"><User className="w-5 h-5" /></div>
                    <input
                      type="text" required
                      value={profileData.name} onChange={e => setProfileData({ ...profileData, name: e.target.value })}
                      className="w-full pl-10 pr-4 py-3 bg-neutral-50 dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-700/50 rounded-xl focus:ring-2 focus:ring-primary-500 outline-none transition-all text-neutral-900 dark:text-white font-medium"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-bold text-neutral-500 uppercase tracking-widest mb-2">Email Address</label>
                  <div className="relative">
                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-neutral-400"><Mail className="w-5 h-5" /></div>
                    <input
                      type="email" required
                      value={profileData.email} onChange={e => setProfileData({ ...profileData, email: e.target.value })}
                      className="w-full pl-10 pr-4 py-3 bg-neutral-50 dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-700/50 rounded-xl focus:ring-2 focus:ring-primary-500 outline-none transition-all text-neutral-900 dark:text-white font-medium"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-bold text-neutral-500 uppercase tracking-widest mb-2">Phone Number</label>
                  <div className="relative">
                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-neutral-400"><Phone className="w-5 h-5" /></div>
                    <input
                      type="tel"
                      value={profileData.phone} onChange={e => setProfileData({ ...profileData, phone: e.target.value })}
                      placeholder="+1 (555) 000-0000"
                      className="w-full pl-10 pr-4 py-3 bg-neutral-50 dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-700/50 rounded-xl focus:ring-2 focus:ring-primary-500 outline-none transition-all text-neutral-900 dark:text-white font-medium"
                    />
                  </div>
                </div>

                <div className="pt-4 flex justify-end">
                  <button
                    type="submit" disabled={savingProfile}
                    className="px-8 py-3 bg-primary-600 hover:bg-primary-500 text-white rounded-xl font-bold shadow-lg shadow-primary-500/30 transition-all flex items-center gap-2 disabled:opacity-50"
                  >
                    {savingProfile ? <Loader className="w-5 h-5 animate-spin" /> : 'Save Changes'}
                  </button>
                </div>
              </form>
            </div>
          )}

          {activeTab === 'password' && (
            <div className="glass-card rounded-2xl p-6 sm:p-10 animate-fade-in">
              <h2 className="text-2xl font-bold text-neutral-900 dark:text-white mb-6 border-b border-neutral-200 dark:border-neutral-800 pb-4">Change Password</h2>
              <form onSubmit={handlePasswordUpdate} className="space-y-6">
                <div>
                  <label className="block text-sm font-bold text-neutral-500 uppercase tracking-widest mb-2">Current Password</label>
                  <div className="relative">
                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-neutral-400"><Lock className="w-5 h-5" /></div>
                    <input
                      type="password" required minLength={6}
                      value={passwordData.current_password} onChange={e => setPasswordData({ ...passwordData, current_password: e.target.value })}
                      className="w-full pl-10 pr-4 py-3 bg-neutral-50 dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-700/50 rounded-xl focus:ring-2 focus:ring-primary-500 outline-none transition-all text-neutral-900 dark:text-white font-medium"
                    />
                  </div>
                </div>

                <div className="pt-4">
                  <label className="block text-sm font-bold text-neutral-500 uppercase tracking-widest mb-2">New Password</label>
                  <div className="relative">
                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-neutral-400"><Lock className="w-5 h-5" /></div>
                    <input
                      type="password" required minLength={8}
                      value={passwordData.password} onChange={e => setPasswordData({ ...passwordData, password: e.target.value })}
                      className="w-full pl-10 pr-4 py-3 bg-neutral-50 dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-700/50 rounded-xl focus:ring-2 focus:ring-primary-500 outline-none transition-all text-neutral-900 dark:text-white font-medium"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-bold text-neutral-500 uppercase tracking-widest mb-2">Confirm New Password</label>
                  <div className="relative">
                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-neutral-400"><Lock className="w-5 h-5" /></div>
                    <input
                      type="password" required minLength={8}
                      value={passwordData.password_confirmation} onChange={e => setPasswordData({ ...passwordData, password_confirmation: e.target.value })}
                      className="w-full pl-10 pr-4 py-3 bg-neutral-50 dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-700/50 rounded-xl focus:ring-2 focus:ring-primary-500 outline-none transition-all text-neutral-900 dark:text-white font-medium"
                    />
                  </div>
                </div>

                <div className="pt-4 flex justify-end">
                  <button
                    type="submit" disabled={savingPassword}
                    className="px-8 py-3 bg-emerald-600 hover:bg-emerald-500 text-white rounded-xl font-bold shadow-lg shadow-emerald-500/30 transition-all flex items-center gap-2 disabled:opacity-50"
                  >
                    {savingPassword ? <Loader className="w-5 h-5 animate-spin" /> : 'Update Password'}
                  </button>
                </div>
              </form>
            </div>
          )}

          {activeTab === 'notifications' && (
            <div className="glass-card rounded-2xl p-6 sm:p-10 animate-fade-in">
              <h2 className="text-2xl font-bold text-neutral-900 dark:text-white mb-6 border-b border-neutral-200 dark:border-neutral-800 pb-4">Communication Preferences</h2>

              <div className="space-y-6">
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="text-lg font-bold text-neutral-900 dark:text-white">Email Receipts</h3>
                    <p className="text-sm text-neutral-500 font-medium">Receive tickets directly to your email inbox</p>
                  </div>
                  <div className="relative inline-block w-12 h-6 rounded-full bg-primary-500 transition-colors shadow-inner mr-2 cursor-not-allowed">
                    <span className="absolute left-1 top-1 w-4 h-4 rounded-full bg-white transition-transform translate-x-6" />
                  </div>
                </div>

                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="text-lg font-bold text-neutral-900 dark:text-white">SMS Alerts</h3>
                    <p className="text-sm text-neutral-500 font-medium">Get a heads-up message 2 hours before your show starts</p>
                  </div>
                  <div className="relative inline-block w-12 h-6 rounded-full bg-neutral-300 dark:bg-neutral-700 transition-colors shadow-inner mr-2 cursor-pointer">
                    <span className="absolute left-1 top-1 w-4 h-4 rounded-full bg-white transition-transform translate-x-0" />
                  </div>
                </div>

                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="text-lg font-bold text-neutral-900 dark:text-white">Marketing & Offers</h3>
                    <p className="text-sm text-neutral-500 font-medium">Occasional platform discounts and new movie releases</p>
                  </div>
                  <div className="relative inline-block w-12 h-6 rounded-full bg-primary-500 transition-colors shadow-inner mr-2 cursor-pointer">
                    <span className="absolute left-1 top-1 w-4 h-4 rounded-full bg-white transition-transform translate-x-6" />
                  </div>
                </div>
              </div>
              <div className="mt-8 pt-6 border-t border-neutral-200 dark:border-neutral-800">
                <p className="text-xs text-neutral-400">(This section is a UI mockup. Your preferences are saved locally.)</p>
              </div>
            </div>
          )}
        </div>

      </div>
    </div>
  )
}
