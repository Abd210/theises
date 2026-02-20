import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { nightTheme, appThemes } from '../theme/themes';

const PREF_KEY = 'selected_theme_id';

const ThemeContext = createContext({
    theme: nightTheme,
    setTheme: () => { },
});

export function ThemeProvider({ children }) {
    const [theme, setThemeState] = useState(nightTheme);

    // Load persisted theme on mount
    useEffect(() => {
        (async () => {
            try {
                const id = await AsyncStorage.getItem(PREF_KEY);
                if (id && appThemes[id]) {
                    setThemeState(appThemes[id]);
                }
            } catch (e) {
                // ignore
            }
        })();
    }, []);

    const setTheme = useCallback(async (id) => {
        const next = appThemes[id];
        if (!next) return;
        setThemeState(next);
        try {
            await AsyncStorage.setItem(PREF_KEY, id);
        } catch (e) {
            // ignore
        }
    }, []);

    return (
        <ThemeContext.Provider value={{ theme, setTheme }}>
            {children}
        </ThemeContext.Provider>
    );
}

/** Hook to access current theme colors + setter */
export function useTheme() {
    return useContext(ThemeContext);
}
