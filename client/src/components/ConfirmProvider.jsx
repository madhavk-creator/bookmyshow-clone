import { createContext, useContext, useMemo, useRef, useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { AlertTriangle, CircleAlert } from 'lucide-react'

const ConfirmContext = createContext(null)

const DEFAULT_OPTIONS = {
  title: 'Confirm Action',
  message: 'Are you sure you want to continue?',
  confirmText: 'Confirm',
  cancelText: 'Cancel',
  tone: 'danger',
}

const toneClasses = {
  danger: {
    badge: 'bg-red-500/12 text-red-500 border-red-500/20',
    button: 'bg-gradient-to-r from-red-600 to-rose-600 hover:from-red-500 hover:to-rose-500 shadow-red-500/30',
  },
  warning: {
    badge: 'bg-amber-500/12 text-amber-500 border-amber-500/20',
    button: 'bg-gradient-to-r from-amber-600 to-orange-600 hover:from-amber-500 hover:to-orange-500 shadow-amber-500/30',
  },
  info: {
    badge: 'bg-primary-500/12 text-primary-500 border-primary-500/20',
    button: 'bg-gradient-to-r from-primary-600 to-blue-600 hover:from-primary-500 hover:to-blue-500 shadow-primary-500/30',
  },
}

export function ConfirmProvider({ children }) {
  const resolverRef = useRef(null)
  const [dialog, setDialog] = useState(null)

  const confirm = (options = {}) => new Promise((resolve) => {
    resolverRef.current = resolve
    setDialog({ ...DEFAULT_OPTIONS, ...options })
  })

  const closeDialog = (result) => {
    resolverRef.current?.(result)
    resolverRef.current = null
    setDialog(null)
  }

  const value = useMemo(() => ({ confirm }), [])
  const tone = toneClasses[dialog?.tone] || toneClasses.danger

  return (
    <ConfirmContext.Provider value={value}>
      {children}
      <AnimatePresence>
        {dialog && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-[1200] flex items-center justify-center bg-black/60 p-4 backdrop-blur-md"
            onClick={() => closeDialog(false)}
          >
            <motion.div
              initial={{ opacity: 0, y: 18, scale: 0.94 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: 12, scale: 0.96 }}
              transition={{ duration: 0.22, ease: [0.22, 1, 0.36, 1] }}
              className="w-full max-w-md overflow-hidden rounded-[1.75rem] border border-white/10 bg-white/92 p-7 text-neutral-900 shadow-2xl shadow-black/20 backdrop-blur-xl dark:bg-[rgba(18,14,26,0.96)] dark:text-white"
              onClick={(event) => event.stopPropagation()}
            >
              <div className="absolute inset-x-0 top-0 h-24 bg-[radial-gradient(circle_at_top,rgba(139,92,246,0.2),transparent_65%)] dark:bg-[radial-gradient(circle_at_top,rgba(139,92,246,0.22),transparent_65%)]" />
              <div className="relative">
                <div className={`mb-5 inline-flex rounded-2xl border px-3 py-3 ${tone.badge}`}>
                  <AlertTriangle className="h-5 w-5" />
                </div>

                <h2 className="text-xl font-bold tracking-tight">{dialog.title}</h2>
                <p className="mt-3 text-sm leading-6 text-neutral-600 dark:text-neutral-300">
                  {dialog.message}
                </p>

                <div className="mt-7 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
                  <button
                    type="button"
                    onClick={() => closeDialog(false)}
                    className="rounded-xl border border-neutral-200 bg-neutral-100 px-4 py-3 text-sm font-semibold text-neutral-700 transition hover:bg-neutral-200 dark:border-white/10 dark:bg-white/5 dark:text-neutral-200 dark:hover:bg-white/10"
                  >
                    {dialog.cancelText}
                  </button>
                  <button
                    type="button"
                    onClick={() => closeDialog(true)}
                    className={`inline-flex items-center justify-center gap-2 rounded-xl px-4 py-3 text-sm font-semibold text-white shadow-lg transition hover:scale-[1.01] active:scale-[0.99] ${tone.button}`}
                  >
                    <CircleAlert className="h-4 w-4" />
                    {dialog.confirmText}
                  </button>
                </div>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </ConfirmContext.Provider>
  )
}

export function useConfirm() {
  const context = useContext(ConfirmContext)

  if (!context) {
    throw new Error('useConfirm must be used within ConfirmProvider')
  }

  return context.confirm
}
