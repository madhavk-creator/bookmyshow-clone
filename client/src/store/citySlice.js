import { createSlice } from '@reduxjs/toolkit'

const selectedCityFromStorage = localStorage.getItem('selectedCityId') || ''

const citySlice = createSlice({
  name: 'city',
  initialState: {
    selectedCity: selectedCityFromStorage,
  },
  reducers: {
    setSelectedCity(state, action) {
      state.selectedCity = action.payload || ''

      if (state.selectedCity) {
        localStorage.setItem('selectedCityId', state.selectedCity)
      } else {
        localStorage.removeItem('selectedCityId')
      }
    },
    clearSelectedCity(state) {
      state.selectedCity = ''
      localStorage.removeItem('selectedCityId')
    },
  },
})

export const { setSelectedCity, clearSelectedCity } = citySlice.actions

export const selectSelectedCity = (state) => state.city.selectedCity

export default citySlice.reducer
