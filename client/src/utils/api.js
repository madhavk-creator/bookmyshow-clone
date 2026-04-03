import axios from 'axios'

export const api = axios.create({
  headers: {
    'Content-Type': 'application/json',
  },
})

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token')

  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }

  return config
})

export function extractApiError(error, fallback = 'Something went wrong') {
  const data = axios.isAxiosError(error) ? error.response?.data : error

  if (!data) return error?.message || fallback
  if (data.errors) {
    if (Array.isArray(data.errors)) return data.errors.join(', ')
    if (typeof data.errors === 'object') {
      return Object.entries(data.errors)
        .map(([k, v]) => `${k} ${[].concat(v).join(', ')}`)
        .join('; ')
    }
    return String(data.errors)
  }

  return data.error || error?.message || fallback
}

export function getVendors(config = {}) {
  return api.get('/api/v1/vendors', config)
}

export function getVendorIncome(vendorId, config = {}) {
  return api.get(`/api/v1/vendors/${vendorId}/income`, config)
}
