-- Database Barberly - Barbershop Management System (sesuai SRS v1.3 Subbab 4.2)

CREATE DATABASE IF NOT EXISTS barberly;
USE barberly;

CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  phone VARCHAR(20) NULL,
  password VARCHAR(255) NOT NULL,
  role ENUM('admin', 'barber', 'customer') NOT NULL DEFAULT 'customer',
  photo_url VARCHAR(255) NULL,
  photo_public_id VARCHAR(255) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE barbers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL UNIQUE,
  specialty VARCHAR(100) NULL,
  bio TEXT NULL,
  photo_url VARCHAR(255) NULL,
  photo_public_id VARCHAR(255) NULL,
  work_start TIME NOT NULL DEFAULT '09:00:00',
  work_end TIME NOT NULL DEFAULT '21:00:00',
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  CONSTRAINT fk_barbers_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE services (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description TEXT NULL,
  price DECIMAL(10, 2) NOT NULL,
  duration_minutes INT NOT NULL,
  image_url VARCHAR(255) NULL,
  image_public_id VARCHAR(255) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1
);

CREATE TABLE bookings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NOT NULL,
  barber_id INT NOT NULL,
  booking_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  status ENUM('pending', 'confirmed', 'completed', 'cancelled') NOT NULL DEFAULT 'pending',
  subtotal DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  ppn_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  tax_deduction DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  total_price DECIMAL(10, 2) NOT NULL,
  notes TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_bookings_customer FOREIGN KEY (customer_id) REFERENCES users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_bookings_barber FOREIGN KEY (barber_id) REFERENCES barbers(id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE booking_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  booking_id INT NOT NULL,
  service_id INT NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  CONSTRAINT fk_booking_items_booking FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_booking_items_service FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE transactions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  booking_id INT NOT NULL UNIQUE,
  subtotal DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  ppn_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  tax_deduction DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  amount DECIMAL(10, 2) NOT NULL,
  payment_method ENUM('cash', 'transfer', 'ewallet') NOT NULL,
  payment_status ENUM('waiting', 'paid', 'rejected') NOT NULL DEFAULT 'waiting',
  proof_url VARCHAR(255) NULL,
  proof_public_id VARCHAR(255) NULL,
  paid_at DATETIME NULL,
  note VARCHAR(255) NULL,
  CONSTRAINT fk_transactions_booking FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO services (name, description, price, duration_minutes, is_active) VALUES
('Haircut', 'Potong rambut pria lengkap dengan keramas dan styling', 50000.00, 45, 1),
('Shave', 'Cukur kumis dan jenggot rapi dengan handuk hangat', 30000.00, 30, 1),
('Hair Coloring', 'Pewarnaan rambut profesional dengan produk berkualitas', 120000.00, 90, 1);