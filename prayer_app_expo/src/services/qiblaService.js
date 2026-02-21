/**
 * Kaaba coordinates (Mecca, Saudi Arabia).
 */
const KAABA_LAT = 21.4225;
const KAABA_LON = 39.8262;

const toRad = (deg) => (deg * Math.PI) / 180;
const toDeg = (rad) => (rad * 180) / Math.PI;

/**
 * Compute bearing from North to the Kaaba (0–360°, 1 decimal).
 *
 * Formula:
 *   Δlon = kaabaLon - userLon
 *   y = sin(Δlon) * cos(kaabaLat)
 *   x = cos(userLat)*sin(kaabaLat) - sin(userLat)*cos(kaabaLat)*cos(Δlon)
 *   bearing = atan2(y, x)  →  degrees  →  normalize 0..360
 */
export function computeQiblaDegrees(userLat, userLon) {
    const uLatR = toRad(userLat);
    const kLatR = toRad(KAABA_LAT);
    const dLonR = toRad(KAABA_LON - userLon);

    const y = Math.sin(dLonR) * Math.cos(kLatR);
    const x = Math.cos(uLatR) * Math.sin(kLatR) - Math.sin(uLatR) * Math.cos(kLatR) * Math.cos(dLonR);
    const bearing = toDeg(Math.atan2(y, x));

    // Normalize to 0..360 with 1 decimal
    const normalized = ((bearing % 360) + 360) % 360;
    return Math.round(normalized * 10) / 10;
}
