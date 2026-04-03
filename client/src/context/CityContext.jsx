import { createContext, useContext, useState, useEffect } from 'react';

const CityContext = createContext();

export function CityProvider({ children }) {
  const [selectedCity, setSelectedCity] = useState(() => {
    return localStorage.getItem('selectedCityId') || '';
  });

  useEffect(() => {
    if (selectedCity) {
      localStorage.setItem('selectedCityId', selectedCity);
    }
  }, [selectedCity]);

  return (
    <CityContext.Provider value={{ selectedCity, setSelectedCity }}>
      {children}
    </CityContext.Provider>
  );
}

export function useCity() {
  return useContext(CityContext);
}
