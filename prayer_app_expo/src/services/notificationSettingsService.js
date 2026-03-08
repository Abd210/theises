import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';

const PRAYER_NAMES = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
const LEAD_TIME_OPTIONS = [0, 5, 10];

const KEYS = {
    enabled: 'notif_enabled',
    leadMinutes: 'notif_lead_minutes',
    prayerPrefix: 'notif_prayer_',
};

const NotificationSettingsContext = createContext(null);

export function NotificationSettingsProvider({ children }) {
    const [enabled, setEnabledState] = useState(false);
    const [leadMinutes, setLeadMinutesState] = useState(0);
    const [prayerEnabled, setPrayerEnabledState] = useState({
        Fajr: true,
        Dhuhr: true,
        Asr: true,
        Maghrib: true,
        Isha: true,
    });
    const [loaded, setLoaded] = useState(false);

    useEffect(() => {
        (async () => {
            try {
                const [enaRaw, leadRaw] = await Promise.all([
                    AsyncStorage.getItem(KEYS.enabled),
                    AsyncStorage.getItem(KEYS.leadMinutes),
                ]);
                if (enaRaw !== null) setEnabledState(enaRaw === 'true');
                if (leadRaw !== null) setLeadMinutesState(parseInt(leadRaw, 10) || 0);

                const pe = {};
                for (const name of PRAYER_NAMES) {
                    const val = await AsyncStorage.getItem(`${KEYS.prayerPrefix}${name.toLowerCase()}`);
                    pe[name] = val === null ? true : val === 'true';
                }
                setPrayerEnabledState(pe);
            } catch (_) { /* skip */ }
            setLoaded(true);
        })();
    }, []);

    const setEnabled = useCallback(async (val) => {
        setEnabledState(val);
        await AsyncStorage.setItem(KEYS.enabled, String(val)).catch(() => {});
    }, []);

    const setPrayerEnabled = useCallback(async (name, val) => {
        setPrayerEnabledState(prev => ({ ...prev, [name]: val }));
        await AsyncStorage.setItem(`${KEYS.prayerPrefix}${name.toLowerCase()}`, String(val)).catch(() => {});
    }, []);

    const setLeadMinutes = useCallback(async (val) => {
        setLeadMinutesState(val);
        await AsyncStorage.setItem(KEYS.leadMinutes, String(val)).catch(() => {});
    }, []);

    return (
        <NotificationSettingsContext.Provider value={{
            enabled,
            setEnabled,
            prayerEnabled,
            setPrayerEnabled,
            leadMinutes,
            setLeadMinutes,
            loaded,
            PRAYER_NAMES,
            LEAD_TIME_OPTIONS,
        }}>
            {children}
        </NotificationSettingsContext.Provider>
    );
}

export function useNotificationSettings() {
    const ctx = useContext(NotificationSettingsContext);
    if (!ctx) throw new Error('useNotificationSettings must be inside NotificationSettingsProvider');
    return ctx;
}

export { PRAYER_NAMES, LEAD_TIME_OPTIONS };
