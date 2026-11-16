const allDays = JSON.stringify(Array(7).fill(true));

export const sampleAppliances = [
  ['Living Room Fan', 'fan', 70, 6, false],
  ['Bedroom Light', 'light', 15, 4, false],
  ['Living Room TV', 'television', 100, 5, false],
  ['Kitchen Refrigerator', 'refrigerator', 150, 24, true],
  ['Kitchen Rice Cooker', 'riceCooker', 1000, 1, false],
  ['Bedroom Air Conditioner', 'airConditioner', 2500, 8, false],
].map(([name, category, wattage, hours, isOn]) => ({
  name, category, wattage, hours, isOn, operatingDays: allDays,
}));

export async function insertMissingSampleAppliances(connection, userId) {
  const [existing] = await connection.execute(
    'SELECT name FROM appliances WHERE user_id = ?',
    [userId],
  );
  const existingNames = new Set(existing.map((appliance) => appliance.name.toLocaleLowerCase()));
  let inserted = 0;
  for (const appliance of sampleAppliances) {
    if (existingNames.has(appliance.name.toLocaleLowerCase())) continue;
    await connection.execute(
      `INSERT INTO appliances (user_id, name, category, wattage, daily_operating_hours, operating_days, is_on)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [userId, appliance.name, appliance.category, appliance.wattage, appliance.hours,
        appliance.operatingDays, appliance.isOn],
    );
    inserted += 1;
  }
  return inserted;
}
