-- SRM ParkEasy schema derived from project documentation.
-- Run with: mysql -u <user> -p < backend/sql/srm_parkeasy_schema.sql

CREATE DATABASE IF NOT EXISTS srm_parkeasy;
USE srm_parkeasy;

CREATE TABLE IF NOT EXISTS users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    srm_id VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15),
    role ENUM('STUDENT', 'STAFF', 'ADMIN') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS vehicle (
    vehicle_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    plate_number VARCHAR(20) UNIQUE NOT NULL,
    vehicle_type ENUM('2-WHEELER', '4-WHEELER') NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE IF NOT EXISTS parking_zone (
    zone_id INT AUTO_INCREMENT PRIMARY KEY,
    zone_name VARCHAR(50) NOT NULL,
    location VARCHAR(100),
    total_slots INT NOT NULL
);

CREATE TABLE IF NOT EXISTS parking_slot (
    slot_id INT AUTO_INCREMENT PRIMARY KEY,
    zone_id INT NOT NULL,
    slot_number VARCHAR(10) NOT NULL UNIQUE,
    slot_status ENUM('AVAILABLE', 'OCCUPIED', 'MAINTENANCE') DEFAULT 'AVAILABLE',
    FOREIGN KEY (zone_id) REFERENCES parking_zone(zone_id)
);

CREATE TABLE IF NOT EXISTS booking (
    booking_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    slot_id INT NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    booking_status ENUM('ACTIVE', 'COMPLETED', 'CANCELLED') DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicle(vehicle_id),
    FOREIGN KEY (slot_id) REFERENCES parking_slot(slot_id)
);

CREATE TABLE IF NOT EXISTS payment (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    payment_method ENUM('UPI', 'CARD', 'WALLET') NOT NULL,
    payment_status ENUM('SUCCESS', 'FAILED', 'PENDING') DEFAULT 'SUCCESS',
    payment_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_payment_amount CHECK (amount > 0),
    FOREIGN KEY (booking_id) REFERENCES booking(booking_id)
);

CREATE TABLE IF NOT EXISTS extension (
    extension_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL,
    extended_until DATETIME NOT NULL,
    extra_amount DECIMAL(10, 2),
    FOREIGN KEY (booking_id) REFERENCES booking(booking_id)
);

CREATE TABLE IF NOT EXISTS notification (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    message VARCHAR(255),
    sent_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('SENT', 'READ') DEFAULT 'SENT',
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE IF NOT EXISTS admin_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    admin_id INT NOT NULL,
    action VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (admin_id) REFERENCES users(user_id)
);

-- Useful indexes for booking and notification flows.
CREATE INDEX idx_booking_slot_status_time
ON booking(slot_id, booking_status, start_time, end_time);

CREATE INDEX idx_notification_user_time
ON notification(user_id, sent_time);

-- Keep slot status in sync when a new booking is created.
DROP TRIGGER IF EXISTS trg_update_slot_status_after_booking;
DELIMITER //
CREATE TRIGGER trg_update_slot_status_after_booking
AFTER INSERT ON booking
FOR EACH ROW
BEGIN
    UPDATE parking_slot
    SET slot_status = 'OCCUPIED'
    WHERE slot_id = NEW.slot_id;
END//
DELIMITER ;

-- Seed data from project report.
INSERT IGNORE INTO users (user_id, srm_id, name, email, phone, role) VALUES
    (1, 'SRM001', 'Aditya Kumar', 'aditya@srm.edu', '9876543210', 'STUDENT'),
    (2, 'SRM002', 'Rishi S', 'rishi@srm.edu', '9876543211', 'STUDENT'),
    (3, 'SRM003', 'Vatsal Kumar', 'vatsal@srm.edu', '9876543212', 'STAFF'),
    (4, 'SRM004', 'Admin User', 'admin@srm.edu', '9999999999', 'ADMIN');

INSERT IGNORE INTO vehicle (vehicle_id, user_id, plate_number, vehicle_type) VALUES
    (1, 1, 'TN01AB1234', '2-WHEELER'),
    (2, 1, 'TN01CD5678', '4-WHEELER'),
    (3, 2, 'TN02EF9012', '2-WHEELER'),
    (4, 3, 'TN03GH3456', '4-WHEELER');

INSERT IGNORE INTO parking_zone (zone_id, zone_name, location, total_slots) VALUES
    (1, 'Zone A', 'Near Main Gate', 50),
    (2, 'Zone B', 'Academic Block', 40),
    (3, 'Zone C', 'Hostel Area', 60);

INSERT IGNORE INTO parking_slot (slot_id, zone_id, slot_number, slot_status) VALUES
    (1, 1, 'A1', 'AVAILABLE'),
    (2, 1, 'A2', 'OCCUPIED'),
    (3, 2, 'B1', 'AVAILABLE'),
    (4, 2, 'B2', 'AVAILABLE'),
    (5, 3, 'C1', 'AVAILABLE');

