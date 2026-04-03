import { toast } from 'react-toastify'
import { extractApiError } from './api'

const baseOptions = {
  closeButton: false,
}

export function showSuccessToast(message, options = {}) {
  return toast.success(message, { ...baseOptions, ...options })
}

export function showErrorToast(message, options = {}) {
  return toast.error(message, { ...baseOptions, ...options })
}

export function showInfoToast(message, options = {}) {
  return toast.info(message, { ...baseOptions, ...options })
}

export function showWarningToast(message, options = {}) {
  return toast.warning(message, { ...baseOptions, ...options })
}

export function showApiErrorToast(error, fallback = 'Something went wrong', options = {}) {
  return showErrorToast(extractApiError(error, fallback), options)
}
