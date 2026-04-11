import { toast } from 'sonner'
import { extractApiError } from './api'

export function showSuccessToast(message, options = {}) {
  return toast.success(message, options)
}

export function showErrorToast(message, options = {}) {
  return toast.error(message, options)
}

export function showInfoToast(message, options = {}) {
  return toast.info(message, options)
}

export function showWarningToast(message, options = {}) {
  return toast.warning(message, options)
}

export function showApiErrorToast(error, fallback = 'Something went wrong', options = {}) {
  return showErrorToast(extractApiError(error, fallback), options)
}
