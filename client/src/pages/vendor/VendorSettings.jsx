import { useSelector } from 'react'
import { Settings, User, Mail, Bell, Shield, Moon } from 'lucide-react'
import { selectCurrentUser } from '../../store/authSlice'

export default function VendorSettings() {
  const user = useSelector(selectCurrentUser)

  return (
    <div className="p-6 lg:p-8 max-w-4xl mx-auto">
      <div className="mb-8 flex items-center gap-3">
        <div className="w-12 h-12 rounded-xl bg-amber-500/10 flex items-center justify-center">
          <Settings className="w-6 h-6 text-amber-500" />
        </div>
        <div>
          <h1 className="text-3xl font-bold text-neutral-900 dark:text-white">Settings</h1>
          <p className="text-neutral-500 dark:text-neutral-400 mt-1">Manage your vendor account preferences</p>
        </div>
      </div>

      <div className="grid gap-8 md:grid-cols-3">
        {/* Left Column - Navigation */}
        <div className="md:col-span-1 space-y-2">
          <button className="w-full flex items-center gap-3 px-4 py-3 rounded-xl bg-amber-500/10 text-amber-600 dark:text-amber-400 border border-amber-500/20 font-medium transition-all text-left">
            <User className="w-5 h-5 shrink-0" /> Account Details
          </button>
          <button className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-neutral-600 dark:text-neutral-400 hover:bg-neutral-100 dark:hover:bg-neutral-800/60 font-medium transition-all text-left cursor-not-allowed opacity-60">
            <Bell className="w-5 h-5 shrink-0" /> Notifications <span className="ml-auto text-[10px] uppercase font-bold tracking-wider opacity-70">Soon</span>
          </button>
          <button className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-neutral-600 dark:text-neutral-400 hover:bg-neutral-100 dark:hover:bg-neutral-800/60 font-medium transition-all text-left cursor-not-allowed opacity-60">
            <Shield className="w-5 h-5 shrink-0" /> Security <span className="ml-auto text-[10px] uppercase font-bold tracking-wider opacity-70">Soon</span>
          </button>
          <button className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-neutral-600 dark:text-neutral-400 hover:bg-neutral-100 dark:hover:bg-neutral-800/60 font-medium transition-all text-left cursor-not-allowed opacity-60">
            <Moon className="w-5 h-5 shrink-0" /> Appearance <span className="ml-auto text-[10px] uppercase font-bold tracking-wider opacity-70">Soon</span>
          </button>
        </div>

        {/* Right Column - Content */}
        <div className="md:col-span-2 space-y-6">
          <div className="glass-card p-6 md:p-8">
            <h2 className="text-xl font-bold text-neutral-900 dark:text-white mb-6">Profile Information</h2>
            
            <div className="space-y-6">
              <div className="flex items-center gap-4">
                <div className="w-16 h-16 rounded-full bg-gradient-to-br from-amber-500 to-orange-600 flex items-center justify-center text-white text-2xl font-bold shadow-lg shadow-amber-500/20">
                  {user?.name ? user.name.charAt(0).toUpperCase() : '?'}
                </div>
                <div>
                  <h3 className="font-semibold text-neutral-900 dark:text-white text-lg">{user?.name}</h3>
                  <p className="text-neutral-500 text-sm capitalize">{user?.role} Account</p>
                </div>
              </div>

              <div className="grid gap-4 mt-6">
                <div>
                  <label className="block text-sm font-medium text-neutral-500 dark:text-neutral-400 mb-1">Full Name</label>
                  <div className="flex items-center gap-3 px-4 py-3 rounded-xl bg-neutral-100 dark:bg-neutral-800/50 border border-neutral-200 dark:border-neutral-700/50">
                    <User className="w-5 h-5 text-neutral-400" />
                    <span className="text-neutral-900 dark:text-white font-medium">{user?.name}</span>
                  </div>
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-neutral-500 dark:text-neutral-400 mb-1">Email Address</label>
                  <div className="flex items-center gap-3 px-4 py-3 rounded-xl bg-neutral-100 dark:bg-neutral-800/50 border border-neutral-200 dark:border-neutral-700/50">
                    <Mail className="w-5 h-5 text-neutral-400" />
                    <span className="text-neutral-900 dark:text-white font-medium">{user?.email}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
