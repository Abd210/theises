import React, { useState, useEffect, useCallback, createContext, useContext } from 'react';
import {
    loadPrayerSettings,
    loadOffsets,
    setMethodId as persistMethodId,
    setSchool as persistSchool,
    setOffset as persistOffset,
    setMethodMode as persistMethodMode,
    DEFAULT_METHOD_ID,
    DEFAULT_SCHOOL,
    DEFAULT_METHOD_MODE,
    OFFSET_PRAYERS,
} from '../services/prayerSettingsService';

const defaultOffsets = {};
for (const p of OFFSET_PRAYERS) defaultOffsets[p] = 0;

const PrayerSettingsContext = createContext({
    methodId: DEFAULT_METHOD_ID,
    school: DEFAULT_SCHOOL,
    methodMode: DEFAULT_METHOD_MODE,
    offsets: defaultOffsets,
    setMethodId: () => { },
    setMethodIdAuto: () => { },
    setMethodMode: () => { },
    setSchool: () => { },
    setOffset: () => { },
});

export function usePrayerSettings() {
    return useContext(PrayerSettingsContext);
}

export function PrayerSettingsProvider({ children }) {
    const [methodId, setMethodIdState] = useState(DEFAULT_METHOD_ID);
    const [school, setSchoolState] = useState(DEFAULT_SCHOOL);
    const [methodMode, setMethodModeState] = useState(DEFAULT_METHOD_MODE);
    const [offsets, setOffsetsState] = useState({ ...defaultOffsets });
    const [settingsReady, setSettingsReady] = useState(false);

    useEffect(() => {
        (async () => {
            const settings = await loadPrayerSettings();
            setMethodIdState(settings.methodId);
            setSchoolState(settings.school);
            setMethodModeState(settings.methodMode);
            const savedOffsets = await loadOffsets();
            setOffsetsState(savedOffsets);
            setSettingsReady(true);
            if (__DEV__) console.log(`[SETTINGS] ready methodId=${settings.methodId} school=${settings.school} mode=${settings.methodMode}`);
        })();
    }, []);

    // Manual picker tap → also sets mode to "manual"
    const setMethodId = useCallback(async (id) => {
        setMethodIdState(id);
        setMethodModeState('manual');
        await persistMethodId(id);
        await persistMethodMode('manual');
    }, []);

    // Auto-select → does NOT change mode
    const setMethodIdAuto = useCallback(async (id) => {
        setMethodIdState((prev) => {
            if (prev === id) return prev;
            return id;
        });
        await persistMethodId(id);
        console.log(`[PrayerSettings] auto-selected method ${id}`);
    }, []);

    const setMethodMode = useCallback(async (mode) => {
        setMethodModeState(mode);
        await persistMethodMode(mode);
    }, []);

    const setSchool = useCallback(async (id) => {
        setSchoolState(id);
        await persistSchool(id);
    }, []);

    const setOffset = useCallback(async (prayer, minutes) => {
        const clamped = Math.max(-30, Math.min(30, minutes));
        setOffsetsState((prev) => ({ ...prev, [prayer]: clamped }));
        await persistOffset(prayer, minutes);
    }, []);

    return (
        <PrayerSettingsContext.Provider value={{
            methodId, school, methodMode, offsets, settingsReady,
            setMethodId, setMethodIdAuto, setMethodMode, setSchool, setOffset,
        }}>
            {children}
        </PrayerSettingsContext.Provider>
    );
}
