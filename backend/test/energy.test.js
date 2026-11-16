import test from 'node:test';
import assert from 'node:assert/strict';
import { calculateAverageDailyKwh, calculateEntry, roundEntry } from '../src/services/energy.js';
import { dateAtOffset, dateRange, timezoneOffsetMinutes } from '../src/utils/http.js';

test('calculates the same kWh and cost formula as the Flutter app', () => {
  assert.deepEqual(calculateEntry({ wattage: 1000, hours: 2, quantity: 1, rate: 12 }), {
    kwh: 2,
    cost: 24,
  });
});

test('includes the number of running identical appliances', () => {
  const result = calculateEntry({ wattage: 70, hours: 6, quantity: 3, rate: 12 });
  assert.ok(Math.abs(result.kwh - 1.26) < 1e-10);
  assert.ok(Math.abs(result.cost - 15.12) < 1e-10);
});

test('rounds saved values to the database precision', () => {
  assert.deepEqual(roundEntry({ kwh: 0.1050001, cost: 1.23456 }), { kwh: 0.105, cost: 1.2346 });
});

test('uses operating-day schedules in the average daily estimate', () => {
  const dailyKwh = calculateAverageDailyKwh([
    { wattage: 70, dailyOperatingHours: 6, quantity: 3, isOn: true, operatingDays: [true, true, true, true, true, false, false] },
    { wattage: 500, dailyOperatingHours: 4, quantity: 1, isOn: false, operatingDays: Array(7).fill(true) },
  ]);
  assert.ok(Math.abs(dailyKwh - 0.9) < 1e-10);
  assert.ok(Math.abs(dailyKwh * 12 - 10.8) < 1e-10);
  assert.ok(Math.abs(dailyKwh * 30 - 27) < 1e-10);
});

test('calculates the current day in a browser-provided timezone offset', () => {
  assert.equal(dateAtOffset(-480, new Date('2026-11-06T16:30:00Z')), '2026-11-07');
  assert.equal(timezoneOffsetMinutes('-480'), -480);
  assert.throws(() => timezoneOffsetMinutes('1.5'), /whole number/);
});

test('rejects invalid operating hours and a non-positive rate', () => {
  assert.throws(() => calculateEntry({ wattage: 100, hours: 25, rate: 12 }), /Operating hours/);
  assert.throws(() => calculateEntry({ wattage: 100, hours: 1, rate: 0 }), /Electricity rate/);
});

test('rejects impossible dates in history filters', () => {
  assert.throws(() => dateRange({ from: '2026-02-31' }), /valid YYYY-MM-DD date/);
});
