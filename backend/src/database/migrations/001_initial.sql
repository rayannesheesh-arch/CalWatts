CREATE TABLE IF NOT EXISTS users (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  full_name VARCHAR(120) NOT NULL,
  email VARCHAR(254) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('admin', 'user') NOT NULL DEFAULT 'user',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email),
  KEY idx_users_role_active (role, is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS appliances (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(120) NOT NULL,
  category VARCHAR(60) NOT NULL DEFAULT 'other',
  wattage DECIMAL(12,3) NOT NULL,
  daily_operating_hours DECIMAL(5,2) NOT NULL,
  operating_days JSON NOT NULL,
  is_on BOOLEAN NOT NULL DEFAULT TRUE,
  quantity INT UNSIGNED NOT NULL DEFAULT 1,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_appliances_user (user_id),
  CONSTRAINT fk_appliances_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT chk_appliances_wattage CHECK (wattage > 0),
  CONSTRAINT chk_appliances_hours CHECK (daily_operating_hours BETWEEN 0 AND 24),
  CONSTRAINT chk_appliances_quantity CHECK (quantity > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS electricity_rates (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  rate_per_kwh DECIMAL(12,4) NOT NULL,
  effective_at DATETIME(3) NOT NULL,
  created_by BIGINT UNSIGNED NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_rates_effective (effective_at),
  CONSTRAINT fk_rates_admin FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT chk_rates_positive CHECK (rate_per_kwh > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS consumption_records (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  appliance_id BIGINT UNSIGNED NULL,
  appliance_name VARCHAR(120) NOT NULL,
  wattage DECIMAL(12,3) NOT NULL,
  operating_hours DECIMAL(5,2) NOT NULL,
  quantity INT UNSIGNED NOT NULL DEFAULT 1,
  consumption_kwh DECIMAL(14,5) NOT NULL,
  rate_id BIGINT UNSIGNED NOT NULL,
  rate_per_kwh DECIMAL(12,4) NOT NULL,
  estimated_cost DECIMAL(14,4) NOT NULL,
  recorded_for DATE NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_records_user_date (user_id, recorded_for),
  KEY idx_records_date (recorded_for),
  KEY idx_records_appliance (appliance_id),
  CONSTRAINT fk_records_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_records_appliance FOREIGN KEY (appliance_id) REFERENCES appliances(id) ON DELETE SET NULL,
  CONSTRAINT fk_records_rate FOREIGN KEY (rate_id) REFERENCES electricity_rates(id),
  CONSTRAINT chk_records_hours CHECK (operating_hours BETWEEN 0 AND 24),
  CONSTRAINT chk_records_quantity CHECK (quantity > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS simulation_days (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  day_number TINYINT UNSIGNED NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_simulation_user_day (user_id, day_number),
  CONSTRAINT fk_simulation_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT chk_simulation_day CHECK (day_number BETWEEN 1 AND 31)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS simulation_usages (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  simulation_day_id BIGINT UNSIGNED NOT NULL,
  appliance_id BIGINT UNSIGNED NOT NULL,
  operating_hours DECIMAL(5,2) NOT NULL,
  quantity INT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_simulation_usage (simulation_day_id, appliance_id),
  CONSTRAINT fk_usages_day FOREIGN KEY (simulation_day_id) REFERENCES simulation_days(id) ON DELETE CASCADE,
  CONSTRAINT fk_usages_appliance FOREIGN KEY (appliance_id) REFERENCES appliances(id) ON DELETE CASCADE,
  CONSTRAINT chk_usages_hours CHECK (operating_hours BETWEEN 0 AND 24),
  CONSTRAINT chk_usages_quantity CHECK (quantity > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS audit_logs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  admin_id BIGINT UNSIGNED NULL,
  action VARCHAR(80) NOT NULL,
  entity_type VARCHAR(80) NOT NULL,
  entity_id VARCHAR(80) NULL,
  details JSON NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_audit_created (created_at),
  KEY idx_audit_admin (admin_id),
  CONSTRAINT fk_audit_admin FOREIGN KEY (admin_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS user_sessions (
  session_id VARCHAR(128) NOT NULL,
  expires INT UNSIGNED NOT NULL,
  data MEDIUMTEXT,
  PRIMARY KEY (session_id),
  KEY idx_sessions_expires (expires)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
