import React, { useState, useEffect, useCallback, createContext, useContext } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { loadSavedLocation, detectLocation } from '../services/locationService';

const LocationContext = createContext({
    location: null,
    detecting: false,
    detect: () => { },
});

export function useLocation() {
    return useContext(LocationContext);
}

export function LocationProvider({ children }) {
    const [location, setLocation] = useState(null);
    const [detecting, setDetecting] = useState(false);

    useEffect(() => {
        (async () => {
            const saved = await loadSavedLocation();
            // If no prior GPS fix, auto-detect on first launch
            if (saved.source === 'default') {
                setDetecting(true);
                try {
                    const loc = await detectLocation();
                    setLocation(loc);
                    // Invalidate prayer cache so it refetches with new coords
                    await AsyncStorage.removeItem('cached_prayer_date');
                } catch (_) {
                    setLocation(saved);
                } finally {
                    setDetecting(false);
                }
            } else {
                setLocation(saved);
            }
        })();
    }, []);

    const detect = useCallback(async () => {
        setDetecting(true);
        try {
            const loc = await detectLocation();
            setLocation(loc);
            // Invalidate prayer cache so it refetches with new coords
            await AsyncStorage.removeItem('cached_prayer_date');
            return loc;
        } finally {
            setDetecting(false);
        }
    }, []);

    return (
        <LocationContext.Provider value={{ location, detecting, detect }}>
            {children}
        </LocationContext.Provider>
    );
}
