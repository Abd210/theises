import React, { useState, useEffect, useCallback, createContext, useContext } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {
    loadSavedLocation,
    detectLocation,
    isFirstRunCompleted,
    markFirstRunCompleted,
} from '../services/locationService';

const LocationContext = createContext({
    location: null,
    detecting: false,
    usingDefaultLocationBanner: false,
    detect: () => { },
});

export function useLocation() {
    return useContext(LocationContext);
}

export function LocationProvider({ children }) {
    const [location, setLocation] = useState(null);
    const [detecting, setDetecting] = useState(false);
    const [firstRunCompleted, setFirstRunCompleted] = useState(false);

    useEffect(() => {
        (async () => {
            const saved = await loadSavedLocation();
            setLocation(saved);

            const isFirstRunDone = await isFirstRunCompleted();
            setFirstRunCompleted(isFirstRunDone);
            if (!isFirstRunDone) {
                setDetecting(true);
                try {
                    const loc = await detectLocation();
                    setLocation(loc);
                    if (loc.source === 'gps') {
                        // Invalidate prayer cache so it refetches with new coords
                        await AsyncStorage.removeItem('cached_prayer_date');
                    }
                } catch (_) {
                    setLocation(saved);
                } finally {
                    await markFirstRunCompleted();
                    setFirstRunCompleted(true);
                    setDetecting(false);
                }
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
        <LocationContext.Provider
            value={{
                location,
                detecting,
                detect,
                usingDefaultLocationBanner: firstRunCompleted && location?.source === 'default',
            }}
        >
            {children}
        </LocationContext.Provider>
    );
}
