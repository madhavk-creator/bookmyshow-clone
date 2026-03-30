import { createSlice } from '@reduxjs/toolkit'

const savedToken = localStorage.getItem('token')
const savedUser = (() => {
  try {
    const raw = localStorage.getItem('user')
    return raw ? JSON.parse(raw) : null
  } catch {
    localStorage.removeItem('user')
    return null
  }
})()

const initialState = {
  user: savedUser,
  token: savedToken,
}

const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    setCredentials(state, action) {
      const { token, user } = action.payload
      state.token = token
      state.user = user
      localStorage.setItem('token', token)
      localStorage.setItem('user', JSON.stringify(user))
    },
    clearCredentials(state) {
      state.token = null
      state.user = null
      localStorage.removeItem('token')
      localStorage.removeItem('user')
    },
  },
})

export const { setCredentials, clearCredentials } = authSlice.actions

export const selectCurrentUser = (state) => state.auth.user
export const selectCurrentToken = (state) => state.auth.token
export const selectIsLoggedIn = (state) => !!state.auth.token

export default authSlice.reducer
