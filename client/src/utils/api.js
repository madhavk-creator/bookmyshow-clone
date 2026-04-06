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

export function normalizeCollectionResponse(data, key) {
  if (Array.isArray(data)) return data
  return data?.[key] || []
}

export async function getCities(config = {}) {
  const { data } = await api.get('/api/v1/cities', config)
  return normalizeCollectionResponse(data, 'cities')
}

export async function getMovies(config = {}) {
  const { data } = await api.get('/api/v1/movies', config)
  return normalizeCollectionResponse(data, 'movies')
}

export async function getMovie(movieId, config = {}) {
  const { data } = await api.get(`/api/v1/movies/${movieId}`, config)
  return data
}

export async function getShows(config = {}) {
  const { data } = await api.get('/api/v1/shows', config)
  return normalizeCollectionResponse(data, 'shows')
}
