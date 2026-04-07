import { CircleAlert, CircleCheckBig, Info, Sparkles } from 'lucide-react'
import { ToastContainer, cssTransition } from 'react-toastify'
import 'react-toastify/dist/ReactToastify.css'

const cinemaToastTransition = cssTransition({
  enter: 'toast-enter',
  exit: 'toast-exit',
  collapse: true,
  collapseDuration: 220,
})

const toastIcons = {
  success: <CircleCheckBig className="h-5 w-5" />,
  error: <CircleAlert className="h-5 w-5" />,
  info: <Info className="h-5 w-5" />,
  warning: <Sparkles className="h-5 w-5" />,
  default: <Sparkles className="h-5 w-5" />,
}

export default function AppToastProvider() {
  return (
    <ToastContainer
      position="top-right"
      autoClose={3200}
      newestOnTop
      closeOnClick
      pauseOnHover
      pauseOnFocusLoss={false}
      draggable
      stacked
      limit={4}
      icon={({ type }) => toastIcons[type] || toastIcons.default}
      transition={cinemaToastTransition}
      toastClassName={({ type }) => `cine-toast cine-toast--${type || 'default'}`}
      bodyClassName="cine-toast__body"
      progressClassName="cine-toast__progress"
    />
  )
}
