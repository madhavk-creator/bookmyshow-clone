import { Settings } from 'lucide-react'

export default function VendorSettings() {
  return (
    <div className="p-6 lg:p-8 max-w-4xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-neutral-900 dark:text-white">Settings</h1>
        <p className="text-neutral-500 dark:text-neutral-400 mt-1">Manage your vendor account preferences</p>
      </div>

      <div className="glass-card p-16 text-center hover:translate-y-0">
        <Settings className="w-16 h-16 mx-auto text-neutral-300 dark:text-neutral-600 mb-4 animate-spin" style={{ animationDuration: '8s' }} />
        <h3 className="text-xl font-semibold text-neutral-700 dark:text-neutral-300 mb-2">Coming Soon</h3>
        <p className="text-neutral-500 dark:text-neutral-400">Account settings, notification preferences, and API keys will be available here.</p>
      </div>
    </div>
  )
}
