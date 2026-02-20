import React, { useState, useEffect, useCallback, createContext, useContext } from 'react';
import {
    loadPrayerSettings,
    loadOffsets,
    setMethodId as persistMethodId,
    setSchool as persistSchool,
    setOffset as persistOffset,
    DEFAULT_METHOD_ID,
    DEFAULT_SCHOOL,
    OFFSET_PRAYERS,
} from '../services/prayerSettingsService';

const defaultOffsets = {};
for (const p of OFFSET_PRAYERS) defaultOffsets[p] = 0;

const PrayerSettingsContext = createContext({
    methodId: DEFAULT_METHOD_ID,
    school: DEFAULT_SCHOOL,
    offsets: defaultOffsets,
    setMethodId: () => { },
    setSchool: () => { },
    setOffset: () => { },
});

export function usePrayerSettings() {
    return useContext(PrayerSettingsContext);
}

export function PrayerSettingsProvider({ children }) {
    const [methodId, setMethodIdState] = useState(DEFAULT_METHOD_ID);
    const [school, setSchoolState] = useState(DEFAULT_SCHOOL);
    const [offsets, setOffsetsState] = useState({ ...defaultOffsets });

    useEffect(() => {
        (async () => {
            const settings = await loadPrayerSettings();
            setMethodIdState(settings.methodId);
            setSchoolState(settings.school);
            const savedOffsets = await loadOffsets();
            setOffsetsState(savedOffsets);
        })();
    }, []);

    const setMethodId = useCallback(async (id) => {
        setMethodIdState(id);
        await persistMethodId(id);
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
        <PrayerSettingsContext.Provider value={{ methodId, school, offsets, setMethodId, setSchool, setOffset }}>
            {children}
        </PrayerSettingsContext.Provider>
    );
}
