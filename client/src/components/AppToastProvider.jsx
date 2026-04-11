import { Toaster } from 'sonner'

export default function AppToastProvider() {
  return (
    <Toaster 
      position="top-right" 
      richColors 
      closeButton
      expand={true}
      theme="system"
      toastOptions={{
        className: 'font-medium',
      }}
    />
  )
}
