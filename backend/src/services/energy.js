import { HttpError, requireNumber } from '../utils/http.js';

export function calculateEntry({ wattage, hours, quantity = 1, rate }) {
  const watts = requireNumber(wattage, 'Wattage', { min: Number.EPSILON, max: 1000000 });
  const operatingHours = requireNumber(hours, 'Operating hours', { min: 0, max: 24 });
  const units = requireNumber(quantity, 'Quantity', { min: 1, max: 1000 });
  const electricityRate = requireNumber(rate, 'Electricity rate', { min: Number.EPSILON, max: 1000000 });
  const kwh = (watts / 1000) * operatingHours * units;
  return { kwh, cost: kwh * electricityRate };
}

export function roundEntry({ kwh, cost }) {
  return { kwh: Number(kwh.toFixed(5)), cost: Number(cost.toFixed(4)) };
}

export function calculateAverageDailyKwh(appliances) {
  const weeklyKwh = appliances.reduce((total, appliance) => {
    if (!appliance.isOn) return total;
    const operatingDays = Array.isArray(appliance.operatingDays)
      ? appliance.operatingDays
      : JSON.parse(appliance.operatingDays);
    if (operatingDays.length !== 7 || operatingDays.some((day) => typeof day !== 'boolean')) {
      throw new HttpError(500, 'An appliance has invalid operating-day data.');
    }
    const daysPerWeek = operatingDays.filter(Boolean).length;
    return total + (Number(appliance.wattage) / 1000)
      * Number(appliance.dailyOperatingHours)
      * Number(appliance.quantity)
      * daysPerWeek;
  }, 0);
  return weeklyKwh / 7;
}

export function requireValidEmail(email) {
  if (typeof email !== 'string' || email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new HttpError(400, 'Enter a valid email address.');
  }
  return email.trim().toLowerCase();
}

export function requirePassword(password) {
  if (typeof password !== 'string' || password.length < 10 || password.length > 72) {
    throw new HttpError(400, 'Password must be between 10 and 72 characters.');
  }
  return password;
}
