-- Drop tables if they already exist

DROP TABLE IF EXISTS material_usage_items;
DROP TABLE IF EXISTS material_usage_logs;
DROP TABLE IF EXISTS material_request_items;
DROP TABLE IF EXISTS material_requests;
DROP TABLE IF EXISTS task_materials;
DROP TABLE IF EXISTS tasks;
DROP TABLE IF EXISTS payroll_records;
DROP TABLE IF EXISTS payroll_periods;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS invoice_items;
DROP TABLE IF EXISTS invoices;
DROP TABLE IF EXISTS job_orders;
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS service_requests;
DROP TABLE IF EXISTS services;
DROP TABLE IF EXISTS inventory_items;
DROP TABLE IF EXISTS plant_master;
DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS employee_availability;
DROP TABLE IF EXISTS employee_skills;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS client_locations;
DROP TABLE IF EXISTS addresses;
DROP TABLE IF EXISTS clients;
DROP TABLE IF EXISTS users;

-- USERS

CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    role ENUM('Management','Staff','Client') NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(30),
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ADDRESSES

CREATE TABLE addresses (
    address_id INT PRIMARY KEY AUTO_INCREMENT,
    street_1 VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    zip_code VARCHAR(20) NOT NULL
);

-- CLIENTS

CREATE TABLE clients (
    client_id INT PRIMARY KEY AUTO_INCREMENT,
    contact_user_id INT NOT NULL UNIQUE,
    company_name VARCHAR(255) NOT NULL,
    member_since DATETIME DEFAULT CURRENT_TIMESTAMP,
    account_status VARCHAR(50) DEFAULT 'Active',
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (contact_user_id) REFERENCES users(user_id)
);

CREATE TABLE client_locations (
    location_id INT PRIMARY KEY AUTO_INCREMENT,
    client_id INT NOT NULL,
    address_id INT NOT NULL,
    location_name VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (client_id) REFERENCES clients(client_id),
    FOREIGN KEY (address_id) REFERENCES addresses(address_id)
);

-- EMPLOYEES

CREATE TABLE employees (
    employee_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL UNIQUE,
    employee_code VARCHAR(20) NOT NULL UNIQUE,
    job_title VARCHAR(150),
    employment_status VARCHAR(50) DEFAULT 'Active',
    hire_date DATETIME,
    pay_rate_hourly DECIMAL(10,2),
    address_id INT,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (address_id) REFERENCES addresses(address_id)
);

CREATE TABLE employee_skills (
    skill_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id INT NOT NULL,
    skill_name VARCHAR(100) NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

CREATE TABLE employee_availability (
    employee_id INT NOT NULL,
    week_start_date DATE NOT NULL,
    day_of_week INT NOT NULL,
    available_from TIME,
    available_to TIME,
    is_available BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (employee_id, week_start_date, day_of_week),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- SUPPLIERS

CREATE TABLE suppliers (
    supplier_id INT PRIMARY KEY AUTO_INCREMENT,
    supplier_name VARCHAR(255) NOT NULL,
    phone VARCHAR(30),
    email VARCHAR(255),
    address_id INT,
    total_orders INT DEFAULT 0,
    last_order_date DATE,
    status ENUM('Ordered','Shipped','Delivered'),
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (address_id) REFERENCES addresses(address_id)
);

-- PLANT MASTER

CREATE TABLE plant_master (
    plant_id INT PRIMARY KEY AUTO_INCREMENT,
    common_name VARCHAR(255) NOT NULL,
    scientific_name VARCHAR(255),
    light_level VARCHAR(100),
    watering_frequency VARCHAR(100),
    temperature_range VARCHAR(100),
    humidity_range VARCHAR(100),
    photo_url TEXT,
    notes TEXT,
    is_active BOOLEAN DEFAULT TRUE
);

-- INVENTORY

CREATE TABLE inventory_items (
    item_id INT PRIMARY KEY AUTO_INCREMENT,
    item_name VARCHAR(255) NOT NULL,
    item_type VARCHAR(100),
    plant_id INT,
    supplier_id INT,
    sku VARCHAR(100),
    unit_price DECIMAL(10,2),
    quantity_on_hand DECIMAL(10,2),
    reorder_level DECIMAL(10,2),
    unit_label VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (plant_id) REFERENCES plant_master(plant_id),
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
);

-- SERVICES

CREATE TABLE services (
    service_id INT PRIMARY KEY AUTO_INCREMENT,
    service_name VARCHAR(255) NOT NULL,
    description TEXT,
    base_price DECIMAL(10,2),
    is_active BOOLEAN DEFAULT TRUE
);

-- SERVICE REQUESTS

CREATE TABLE service_requests (
    service_request_id INT PRIMARY KEY AUTO_INCREMENT,
    client_id INT NOT NULL,
    location_id INT NOT NULL,
    service_id INT NOT NULL,
    requested_date DATE,
    requested_notes TEXT,
    status VARCHAR(50),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    approved_by INT,
    FOREIGN KEY (client_id) REFERENCES clients(client_id),
    FOREIGN KEY (location_id) REFERENCES client_locations(location_id),
    FOREIGN KEY (service_id) REFERENCES services(service_id),
    FOREIGN KEY (approved_by) REFERENCES users(user_id)
);

-- APPOINTMENTS

CREATE TABLE appointments (
    appointment_id INT PRIMARY KEY AUTO_INCREMENT,
    client_id INT NOT NULL,
    location_id INT NOT NULL,
    service_id INT NOT NULL,
    service_request_id INT,
    assigned_employee_id INT,
    appointment_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    status VARCHAR(50),
    FOREIGN KEY (client_id) REFERENCES clients(client_id),
    FOREIGN KEY (location_id) REFERENCES client_locations(location_id),
    FOREIGN KEY (service_id) REFERENCES services(service_id),
    FOREIGN KEY (service_request_id) REFERENCES service_requests(service_request_id),
    FOREIGN KEY (assigned_employee_id) REFERENCES employees(employee_id)
);

-- JOB ORDERS

CREATE TABLE job_orders (
    job_order_id INT PRIMARY KEY AUTO_INCREMENT,
    job_order_code VARCHAR(50) NOT NULL UNIQUE,
    client_id INT NOT NULL,
    location_id INT NOT NULL,
    service_id INT NOT NULL,
    appointment_id INT,
    service_request_id INT,
    assigned_employee_id INT,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    scheduled_date DATE,
    start_time TIME,
    end_time TIME,
    estimated_cost DECIMAL(10,2),
    status VARCHAR(50),
    priority VARCHAR(50),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (client_id) REFERENCES clients(client_id),
    FOREIGN KEY (location_id) REFERENCES client_locations(location_id),
    FOREIGN KEY (service_id) REFERENCES services(service_id),
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id),
    FOREIGN KEY (service_request_id) REFERENCES service_requests(service_request_id),
    FOREIGN KEY (assigned_employee_id) REFERENCES employees(employee_id)
);

-- TASKS

CREATE TABLE tasks (
    task_id INT PRIMARY KEY AUTO_INCREMENT,
    job_order_id INT NOT NULL,
    assigned_employee_id INT,
    task_name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50),
    completed_at DATETIME,
    FOREIGN KEY (job_order_id) REFERENCES job_orders(job_order_id),
    FOREIGN KEY (assigned_employee_id) REFERENCES employees(employee_id)
);

CREATE TABLE task_materials (
    task_material_id INT PRIMARY KEY AUTO_INCREMENT,
    task_id INT NOT NULL,
    item_id INT NOT NULL,
    required_quantity DECIMAL(10,2),
    FOREIGN KEY (task_id) REFERENCES tasks(task_id),
    FOREIGN KEY (item_id) REFERENCES inventory_items(item_id)
);

-- INVOICES

CREATE TABLE invoices (
    invoice_id INT PRIMARY KEY AUTO_INCREMENT,
    invoice_number VARCHAR(50) NOT NULL UNIQUE,
    client_id INT NOT NULL,
    job_order_id INT,
    issue_date DATE NOT NULL,
    due_date DATE NOT NULL,
    subtotal DECIMAL(10,2),
    tax_amount DECIMAL(10,2),
    total_amount DECIMAL(10,2),
    status VARCHAR(50),
    FOREIGN KEY (client_id) REFERENCES clients(client_id)
);

CREATE TABLE invoice_items (
    invoice_item_id INT PRIMARY KEY AUTO_INCREMENT,
    invoice_id INT NOT NULL,
    description VARCHAR(255) NOT NULL,
    quantity DECIMAL(10,2),
    unit_price DECIMAL(10,2),
    line_total DECIMAL(10,2),
    FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id)
);

CREATE TABLE payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    invoice_id INT NOT NULL,
    payment_date DATE NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(50),
    reference_number VARCHAR(100),
    notes TEXT,
    FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id)
);

-- PAYROLL

CREATE TABLE payroll_periods (
    payroll_period_id INT PRIMARY KEY AUTO_INCREMENT,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    payment_date DATE NOT NULL
);

CREATE TABLE payroll_records (
    payroll_record_id INT PRIMARY KEY AUTO_INCREMENT,
    payroll_period_id INT NOT NULL,
    employee_id INT NOT NULL,
    regular_hours DECIMAL(10,2),
    overtime_hours DECIMAL(10,2),
    billable_hours DECIMAL(10,2),
    pay_rate DECIMAL(10,2),
    bonus_amount DECIMAL(10,2),
    deduction_amount DECIMAL(10,2),
    gross_pay DECIMAL(10,2),
    net_pay DECIMAL(10,2),
    payment_method VARCHAR(50),
    FOREIGN KEY (payroll_period_id) REFERENCES payroll_periods(payroll_period_id),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- MATERIAL REQUESTS

CREATE TABLE material_requests (
    material_request_id INT PRIMARY KEY AUTO_INCREMENT,
    request_code VARCHAR(50) NOT NULL UNIQUE,
    employee_id INT NOT NULL,
    task_id INT,
    note TEXT,
    status VARCHAR(50),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    FOREIGN KEY (task_id) REFERENCES tasks(task_id)
);

CREATE TABLE material_request_items (
    material_request_item_id INT PRIMARY KEY AUTO_INCREMENT,
    material_request_id INT NOT NULL,
    item_id INT NOT NULL,
    quantity_requested DECIMAL(10,2),
    FOREIGN KEY (material_request_id) REFERENCES material_requests(material_request_id),
    FOREIGN KEY (item_id) REFERENCES inventory_items(item_id)
);

CREATE TABLE material_usage_logs (
    usage_log_id INT PRIMARY KEY AUTO_INCREMENT,
    task_id INT NOT NULL,
    employee_id INT NOT NULL,
    logged_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (task_id) REFERENCES tasks(task_id),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

CREATE TABLE material_usage_items (
    usage_item_id INT PRIMARY KEY AUTO_INCREMENT,
    usage_log_id INT NOT NULL,
    item_id INT NOT NULL,
    quantity_used DECIMAL(10,2),
    FOREIGN KEY (usage_log_id) REFERENCES material_usage_logs(usage_log_id),
    FOREIGN KEY (item_id) REFERENCES inventory_items(item_id)
);

-- ADMIN USER

INSERT INTO users (
    role,
    email,
    password,
    first_name,
    last_name,
    phone,
    is_active
) VALUES (
    'Management',
    'admin@test.com',
    'scrypt:32768:8:1$6rMePe6Pg4whHb8b$3364b9f8dfbd6ddfda885f94e44a750f26ef4b7182c7589ca0ebbf8c7adc643d41f48a2a148e34f62a8dc3485d1046f5ccb7c65b94595e9d4e57df6f58c97064',
    'Test',
    'Admin',
    '555-123-4567',
    1
);

-- TEST DATA SEED (for scheduling / assignment / management workflow testing)
-- Seeded non-admin users all use password: test123

INSERT INTO users (
    role,
    email,
    password,
    first_name,
    last_name,
    phone,
    is_active
) VALUES
    ('Management', 'manager@test.com', 'scrypt:32768:8:1$liE9UDZJXxfXB9Nm$a768d6047ea608148f634c840a6aa461a6607832e334eb18eb8ffafdfa2c447dac5756e9a31d33904709d3d98b17e1f802dca20a0c9ecf616b9e419d1c02dc6b', 'Maya', 'Manager', '555-111-1000', 1),
    ('Staff', 'alice.staff@test.com', 'scrypt:32768:8:1$liE9UDZJXxfXB9Nm$a768d6047ea608148f634c840a6aa461a6607832e334eb18eb8ffafdfa2c447dac5756e9a31d33904709d3d98b17e1f802dca20a0c9ecf616b9e419d1c02dc6b', 'Alice', 'Green', '555-111-2001', 1),
    ('Staff', 'bob.staff@test.com', 'scrypt:32768:8:1$liE9UDZJXxfXB9Nm$a768d6047ea608148f634c840a6aa461a6607832e334eb18eb8ffafdfa2c447dac5756e9a31d33904709d3d98b17e1f802dca20a0c9ecf616b9e419d1c02dc6b', 'Bob', 'Rivera', '555-111-2002', 1),
    ('Staff', 'carla.staff@test.com', 'scrypt:32768:8:1$liE9UDZJXxfXB9Nm$a768d6047ea608148f634c840a6aa461a6607832e334eb18eb8ffafdfa2c447dac5756e9a31d33904709d3d98b17e1f802dca20a0c9ecf616b9e419d1c02dc6b', 'Carla', 'Stone', '555-111-2003', 0),
    ('Client', 'brendan.client@test.com', 'scrypt:32768:8:1$liE9UDZJXxfXB9Nm$a768d6047ea608148f634c840a6aa461a6607832e334eb18eb8ffafdfa2c447dac5756e9a31d33904709d3d98b17e1f802dca20a0c9ecf616b9e419d1c02dc6b', 'Brendan', 'User', '555-111-3001', 1),
    ('Client', 'ivy.client@test.com', 'scrypt:32768:8:1$liE9UDZJXxfXB9Nm$a768d6047ea608148f634c840a6aa461a6607832e334eb18eb8ffafdfa2c447dac5756e9a31d33904709d3d98b17e1f802dca20a0c9ecf616b9e419d1c02dc6b', 'Ivy', 'Client', '555-111-3002', 1);

INSERT INTO addresses (street_1, city, state, zip_code) VALUES
    ('101 Garden Ave', 'Baltimore', 'MD', '21201'),
    ('202 Greenway Dr', 'Baltimore', 'MD', '21202'),
    ('303 Orchard Ln', 'Baltimore', 'MD', '21203'),
    ('500 Harbor Pl', 'Baltimore', 'MD', '21230'),
    ('1200 Warehouse Rd', 'Baltimore', 'MD', '21224'),
    ('88 Market St', 'Towson', 'MD', '21286');

INSERT INTO clients (contact_user_id, company_name, member_since, account_status) VALUES
    (6, 'BrenCo Offices', '2025-01-15 10:00:00', 'Active'),
    (7, 'Ivy Retail Group', '2025-05-01 09:00:00', 'Active');

INSERT INTO client_locations (client_id, address_id, location_name, is_active) VALUES
    (1, 4, 'HQ Lobby', 1),
    (1, 5, 'Warehouse', 1),
    (2, 6, 'Main Storefront', 1);

INSERT INTO employees (
    user_id,
    employee_code,
    job_title,
    employment_status,
    hire_date,
    pay_rate_hourly,
    address_id
) VALUES
    (3, 'EMP-1001', 'Horticulture Technician', 'Active', '2024-06-10 08:00:00', 24.50, 1),
    (4, 'EMP-1002', 'Plant Care Specialist', 'Active', '2024-08-05 08:00:00', 22.00, 2),
    (5, 'EMP-1003', 'Field Technician', 'Inactive', '2024-09-15 08:00:00', 21.00, 3);

-- day_of_week mapping in this app: Sunday=0, Monday=1, ... Saturday=6
-- week_start_date for seeded requests below is Monday 2026-04-13
INSERT INTO employee_availability (
    employee_id,
    week_start_date,
    day_of_week,
    available_from,
    available_to,
    is_available
) VALUES
    (1, '2026-04-13', 1, '08:00:00', '17:00:00', 1),
    (1, '2026-04-13', 2, '08:00:00', '17:00:00', 1),
    (1, '2026-04-13', 3, '08:00:00', '17:00:00', 1),
    (1, '2026-04-13', 4, '08:00:00', '12:00:00', 1),
    (1, '2026-04-13', 5, NULL, NULL, 0),
    (2, '2026-04-13', 1, NULL, NULL, 0),
    (2, '2026-04-13', 2, '12:00:00', '20:00:00', 1),
    (2, '2026-04-13', 3, '12:00:00', '20:00:00', 1),
    (2, '2026-04-13', 4, '12:00:00', '20:00:00', 1),
    (2, '2026-04-13', 5, '12:00:00', '20:00:00', 1);

INSERT INTO services (service_name, description, base_price, is_active) VALUES
    ('Watering Plants', 'Routine watering and moisture checks', 60.00, 1),
    ('Indoor Plant Health Check', 'Inspect plant health and treat common issues', 120.00, 1),
    ('Office Plant Installation', 'Install and stage new office plants', 350.00, 1),
    ('Seasonal Decor Refresh', 'Rotate seasonal plant decor package', 250.00, 0);

INSERT INTO invoices (
    invoice_number,
    client_id,
    job_order_id,
    issue_date,
    due_date,
    subtotal,
    tax_amount,
    total_amount,
    status
) VALUES
    ('INV-1001', 1, 1, '2026-04-10', '2026-04-25', 150.00, 30.00, 180.00, 'Unpaid'),
    ('INV-1002', 1, 2, '2026-03-20', '2026-04-04', 100.00, 20.00, 120.00, 'Paid');

INSERT INTO invoice_items (
    invoice_id,
    description,
    quantity,
    unit_price,
    line_total
) VALUES
    (1, 'Lobby plant maintenance service', 1, 150.00, 150.00),
    (2, 'Warehouse plant health check', 1, 100.00, 100.00);

INSERT INTO payments (
    invoice_id,
    payment_date,
    amount,
    payment_method,
    reference_number,
    notes
) VALUES
    (2, '2026-04-02', 120.00, 'Credit Card', 'CC-20260402-001', 'Payment for invoice INV-1002');

INSERT INTO service_requests (
    client_id,
    location_id,
    service_id,
    requested_date,
    requested_notes,
    status,
    created_at,
    approved_by
) VALUES
    (1, 1, 1, '2026-04-16', 'Front desk plants are drying out quickly.', 'Pending', '2026-04-14 09:15:00', NULL),
    (2, 3, 2, '2026-04-17', 'Leaves are yellowing near the storefront entrance.', 'Pending', '2026-04-14 10:45:00', NULL),
    (1, 2, 2, '2026-04-16', 'Monthly warehouse plant maintenance.', 'Approved', '2026-04-10 08:00:00', 1),
    (2, 3, 3, '2026-04-18', 'Need installation before weekend event.', 'Rejected', '2026-04-09 11:30:00', 1),
    (1, 1, 1, '2026-04-17', 'Weekly watering route for lobby planters.', 'Approved', '2026-04-11 07:30:00', 1),
    (2, 3, 1, '2026-04-16', 'Lunch area watering and cleanup.', 'Approved', '2026-04-12 08:20:00', 1);

INSERT INTO job_orders (
    job_order_code,
    client_id,
    location_id,
    service_id,
    appointment_id,
    service_request_id,
    assigned_employee_id,
    title,
    description,
    scheduled_date,
    start_time,
    end_time,
    estimated_cost,
    status,
    priority,
    created_at
) VALUES
    ('JO-20260410-001', 1, 2, 2, NULL, 3, 1, 'Indoor Plant Health Check', 'Approved request from BrenCo warehouse.', '2026-04-16', '13:00:00', '14:30:00', 120.00, 'Scheduled', 'High', '2026-04-10 08:30:00'),
    ('JO-20260411-001', 1, 1, 1, NULL, 5, 2, 'Watering Plants', 'Approved recurring lobby watering.', '2026-04-17', '12:00:00', '13:00:00', 60.00, 'Scheduled', 'Normal', '2026-04-11 08:00:00'),
    ('JO-20260412-001', 1, 1, 3, NULL, NULL, NULL, 'Office Plant Installation', 'Manual management-created job order pending assignment.', '2026-04-16', '13:30:00', '14:30:00', 350.00, 'Unassigned', 'High', '2026-04-12 09:00:00'),
    ('JO-20260413-001', 2, 3, 1, NULL, 6, 1, 'Watering Plants', 'Completed lunch area watering job.', '2026-04-16', '09:00:00', '10:00:00', 60.00, 'Completed', 'Low', '2026-04-13 09:00:00'),
    ('JO-20260414-001', 2, 3, 2, NULL, NULL, NULL, 'Indoor Plant Health Check', 'Unassigned health check awaiting staffing.', '2026-04-17', '09:00:00', '10:00:00', 120.00, 'Unassigned', 'Normal', '2026-04-14 11:00:00'),
    ('JO-20260414-002', 2, 3, 3, NULL, NULL, NULL, 'Office Plant Installation', 'Backlog job with no schedule yet.', NULL, NULL, NULL, 350.00, 'Unassigned', 'Low', '2026-04-14 12:00:00');

-- ADDITIONAL TEST DATA (extended coverage)

INSERT INTO users (
    role,
    email,
    password,
    first_name,
    last_name,
    phone,
    is_active
) VALUES
    ('Staff', 'dylan.staff@test.com', 'scrypt:32768:8:1$liE9UDZJXxfXB9Nm$a768d6047ea608148f634c840a6aa461a6607832e334eb18eb8ffafdfa2c447dac5756e9a31d33904709d3d98b17e1f802dca20a0c9ecf616b9e419d1c02dc6b', 'Dylan', 'Frost', '555-111-2004', 1),
    ('Staff', 'emma.staff@test.com', 'scrypt:32768:8:1$liE9UDZJXxfXB9Nm$a768d6047ea608148f634c840a6aa461a6607832e334eb18eb8ffafdfa2c447dac5756e9a31d33904709d3d98b17e1f802dca20a0c9ecf616b9e419d1c02dc6b', 'Emma', 'Lane', '555-111-2005', 1),
    ('Client', 'nora.client@test.com', 'scrypt:32768:8:1$liE9UDZJXxfXB9Nm$a768d6047ea608148f634c840a6aa461a6607832e334eb18eb8ffafdfa2c447dac5756e9a31d33904709d3d98b17e1f802dca20a0c9ecf616b9e419d1c02dc6b', 'Nora', 'Mills', '555-111-3003', 1),
    ('Client', 'oscar.client@test.com', 'scrypt:32768:8:1$liE9UDZJXxfXB9Nm$a768d6047ea608148f634c840a6aa461a6607832e334eb18eb8ffafdfa2c447dac5756e9a31d33904709d3d98b17e1f802dca20a0c9ecf616b9e419d1c02dc6b', 'Oscar', 'Reed', '555-111-3004', 1);

INSERT INTO addresses (street_1, city, state, zip_code) VALUES
    ('410 North Park', 'Baltimore', 'MD', '21210'),
    ('77 Elm Street', 'Catonsville', 'MD', '21228'),
    ('900 Charles St', 'Baltimore', 'MD', '21201'),
    ('1000 Commerce Blvd', 'Columbia', 'MD', '21044'),
    ('45 Dockside Way', 'Baltimore', 'MD', '21231');

INSERT INTO clients (contact_user_id, company_name, member_since, account_status) VALUES
    (10, 'Nora Hospitality', '2025-09-10 09:15:00', 'Active'),
    (11, 'Oscar CoWorking', '2025-11-20 13:40:00', 'Active');

INSERT INTO client_locations (client_id, address_id, location_name, is_active) VALUES
    (3, 9, 'Hotel Lobby', 1),
    (3, 10, 'Hotel Annex', 1),
    (4, 11, 'Downtown Flex Space', 1);

INSERT INTO employees (
    user_id,
    employee_code,
    job_title,
    employment_status,
    hire_date,
    pay_rate_hourly,
    address_id
) VALUES
    (8, 'EMP-1004', 'Senior Plant Technician', 'Active', '2023-11-01 08:00:00', 27.00, 7),
    (9, 'EMP-1005', 'Field Specialist', 'Active', '2025-02-12 08:00:00', 23.25, 8);

INSERT INTO employee_skills (employee_id, skill_name) VALUES
    (1, 'Watering'),
    (1, 'Pruning'),
    (2, 'Pest Inspection'),
    (2, 'Soil Testing'),
    (4, 'Installations'),
    (4, 'Client Training'),
    (5, 'Emergency Response');

-- Additional week availability for forward-dated scheduling tests
INSERT INTO employee_availability (
    employee_id,
    week_start_date,
    day_of_week,
    available_from,
    available_to,
    is_available
) VALUES
    (1, '2026-04-20', 1, '08:00:00', '16:00:00', 1),
    (1, '2026-04-20', 2, '08:00:00', '16:00:00', 1),
    (1, '2026-04-20', 3, '08:00:00', '16:00:00', 1),
    (1, '2026-04-20', 4, '08:00:00', '16:00:00', 1),
    (1, '2026-04-20', 5, '08:00:00', '13:00:00', 1),
    (2, '2026-04-20', 1, '12:00:00', '20:00:00', 1),
    (2, '2026-04-20', 2, '12:00:00', '20:00:00', 1),
    (2, '2026-04-20', 3, '12:00:00', '20:00:00', 1),
    (2, '2026-04-20', 4, '12:00:00', '20:00:00', 1),
    (2, '2026-04-20', 5, NULL, NULL, 0),
    (4, '2026-04-20', 1, '07:00:00', '15:00:00', 1),
    (4, '2026-04-20', 2, '07:00:00', '15:00:00', 1),
    (4, '2026-04-20', 3, '07:00:00', '15:00:00', 1),
    (4, '2026-04-20', 4, '07:00:00', '15:00:00', 1),
    (4, '2026-04-20', 5, '07:00:00', '12:00:00', 1),
    (5, '2026-04-20', 1, '14:00:00', '21:00:00', 1),
    (5, '2026-04-20', 2, '14:00:00', '21:00:00', 1),
    (5, '2026-04-20', 3, '14:00:00', '21:00:00', 1),
    (5, '2026-04-20', 4, '14:00:00', '21:00:00', 1),
    (5, '2026-04-20', 5, '14:00:00', '18:00:00', 1);

INSERT INTO services (service_name, description, base_price, is_active) VALUES
    ('Emergency Plant Triage', 'Urgent same-day diagnosis and stabilization', 180.00, 1),
    ('Soil and Pot Refresh', 'Refresh soil blend and repot where needed', 95.00, 1);

INSERT INTO service_requests (
    client_id,
    location_id,
    service_id,
    requested_date,
    requested_notes,
    status,
    created_at,
    approved_by
) VALUES
    (3, 4, 5, '2026-04-21', 'Urgent stress signs in lobby ficus trees.', 'Pending', '2026-04-15 08:45:00', NULL),
    (4, 6, 6, '2026-04-22', 'Requesting soil refresh for desk plants.', 'Pending', '2026-04-15 09:20:00', NULL),
    (3, 5, 2, '2026-04-23', 'Quarterly health inspection for annex plants.', 'Approved', '2026-04-13 14:10:00', 2),
    (4, 6, 1, '2026-04-21', 'Watering for newly occupied coworking suites.', 'Approved', '2026-04-13 15:00:00', 2),
    (3, 4, 3, '2026-04-24', 'Install display plants before ribbon cutting.', 'Rejected', '2026-04-12 11:00:00', 2),
    (1, 2, 5, '2026-04-22', 'Emergency call for drooping atrium plants.', 'Pending', '2026-04-15 10:30:00', NULL);

INSERT INTO job_orders (
    job_order_code,
    client_id,
    location_id,
    service_id,
    appointment_id,
    service_request_id,
    assigned_employee_id,
    title,
    description,
    scheduled_date,
    start_time,
    end_time,
    estimated_cost,
    status,
    priority,
    created_at
) VALUES
    ('JO-20260415-101', 3, 5, 2, NULL, 9, 4, 'Indoor Plant Health Check', 'Approved quarterly wellness for hotel annex.', '2026-04-23', '10:00:00', '11:30:00', 120.00, 'Scheduled', 'Normal', '2026-04-15 11:00:00'),
    ('JO-20260415-102', 4, 6, 1, NULL, 10, 5, 'Watering Plants', 'Approved watering for coworking floor.', '2026-04-21', '15:00:00', '16:00:00', 60.00, 'Scheduled', 'High', '2026-04-15 11:20:00'),
    ('JO-20260415-103', 3, 4, 5, NULL, NULL, NULL, 'Emergency Plant Triage', 'Awaiting assignment for urgent triage request.', '2026-04-21', '09:00:00', '10:30:00', 180.00, 'Unassigned', 'High', '2026-04-15 11:40:00'),
    ('JO-20260415-104', 4, 6, 6, NULL, NULL, NULL, 'Soil and Pot Refresh', 'Pending materials confirmation before assignment.', '2026-04-22', '13:00:00', '14:30:00', 95.00, 'Unassigned', 'Normal', '2026-04-15 12:00:00'),
    ('JO-20260415-105', 1, 1, 1, NULL, NULL, 2, 'Watering Plants', 'Cancelled schedule scenario for conflict testing.', '2026-04-16', '14:00:00', '15:00:00', 60.00, 'Cancelled', 'Low', '2026-04-15 12:20:00'),
    ('JO-20260415-106', 3, 5, 3, NULL, NULL, 4, 'Office Plant Installation', 'Completed installation follow-up.', '2026-04-20', '08:00:00', '11:00:00', 350.00, 'Completed', 'High', '2026-04-15 12:40:00'),
    ('JO-20260415-107', 4, 6, 2, NULL, NULL, 4, 'Indoor Plant Health Check', 'Active assignment used for overlap checks.', '2026-04-21', '10:00:00', '11:00:00', 120.00, 'Scheduled', 'Normal', '2026-04-15 13:00:00');

INSERT INTO appointments (
    client_id,
    location_id,
    service_id,
    service_request_id,
    assigned_employee_id,
    appointment_date,
    start_time,
    end_time,
    status
) VALUES
    (3, 5, 2, 9, 4, '2026-04-23', '10:00:00', '11:30:00', 'Scheduled'),
    (4, 6, 1, 10, 5, '2026-04-21', '15:00:00', '16:00:00', 'Scheduled');

INSERT INTO suppliers (
    supplier_name,
    phone,
    email,
    address_id,
    total_orders,
    last_order_date,
    status
) VALUES
    ('GreenGrow Supply', '555-200-0001', 'orders@greengrow.test', 9, 12, '2026-04-01', 'Delivered'),
    ('Urban Soil Partners', '555-200-0002', 'sales@urbansoil.test', 10, 7, '2026-03-28', 'Shipped');

INSERT INTO plant_master (
    common_name,
    scientific_name,
    light_level,
    watering_frequency,
    temperature_range,
    humidity_range,
    photo_url,
    notes
) VALUES
    ('Fiddle Leaf Fig', 'Ficus lyrata', 'Bright indirect', 'Weekly', '65-80F', '40-60%', NULL, 'Rotate weekly for even growth'),
    ('Snake Plant', 'Sansevieria trifasciata', 'Low to bright indirect', 'Bi-weekly', '60-85F', '30-50%', NULL, 'Avoid overwatering');

INSERT INTO inventory_items (
    item_name,
    item_type,
    plant_id,
    supplier_id,
    sku,
    unit_price,
    quantity_on_hand,
    reorder_level,
    unit_label
) VALUES
    ('Premium Potting Mix', 'Soil', NULL, 2, 'SOIL-001', 14.99, 52.00, 20.00, 'bags'),
    ('14in Ceramic Pot', 'Container', NULL, 1, 'POT-014', 24.50, 18.00, 8.00, 'each'),
    ('Fiddle Leaf Fig (Medium)', 'Plant', 1, 1, 'PLANT-FLF-M', 39.00, 11.00, 4.00, 'each');

INSERT INTO tasks (
    job_order_id,
    assigned_employee_id,
    task_name,
    description,
    status,
    completed_at
) VALUES
    ((SELECT job_order_id FROM job_orders WHERE job_order_code = 'JO-20260415-101'), 4, 'Inspect foliage and roots', 'Check for pests, root rot, and nutrient stress.', 'Scheduled', NULL),
    ((SELECT job_order_id FROM job_orders WHERE job_order_code = 'JO-20260415-102'), 5, 'Water and trim display plants', 'Standard watering plus light pruning.', 'Scheduled', NULL),
    ((SELECT job_order_id FROM job_orders WHERE job_order_code = 'JO-20260415-106'), 4, 'Install lobby display set', 'Position planters and verify irrigation trays.', 'Completed', '2026-04-20 11:10:00');

INSERT INTO task_materials (task_id, item_id, required_quantity) VALUES
    ((SELECT task_id FROM tasks WHERE task_name = 'Install lobby display set' ORDER BY task_id DESC LIMIT 1), 2, 4.00),
    ((SELECT task_id FROM tasks WHERE task_name = 'Install lobby display set' ORDER BY task_id DESC LIMIT 1), 3, 4.00),
    ((SELECT task_id FROM tasks WHERE task_name = 'Water and trim display plants' ORDER BY task_id DESC LIMIT 1), 1, 1.00);

INSERT INTO invoices (
    invoice_number,
    client_id,
    job_order_id,
    issue_date,
    due_date,
    subtotal,
    tax_amount,
    total_amount,
    status
) VALUES
    (
        'INV-20260420-001',
        3,
        (SELECT job_order_id FROM job_orders WHERE job_order_code = 'JO-20260415-106'),
        '2026-04-20',
        '2026-05-04',
        350.00,
        21.00,
        371.00,
        'Issued'
    );

INSERT INTO invoice_items (
    invoice_id,
    description,
    quantity,
    unit_price,
    line_total
) VALUES
    (
        (SELECT invoice_id FROM invoices WHERE invoice_number = 'INV-20260420-001'),
        'Office Plant Installation Service',
        1.00,
        350.00,
        350.00
    );

INSERT INTO payments (
    invoice_id,
    payment_date,
    amount,
    payment_method,
    reference_number,
    notes
) VALUES
    (
        (SELECT invoice_id FROM invoices WHERE invoice_number = 'INV-20260420-001'),
        '2026-04-22',
        371.00,
        'ACH',
        'ACH-77881',
        'Paid in full'
    );

INSERT INTO payroll_periods (period_start, period_end, payment_date) VALUES
    ('2026-04-13', '2026-04-26', '2026-04-30');

INSERT INTO payroll_records (
    payroll_period_id,
    employee_id,
    regular_hours,
    overtime_hours,
    billable_hours,
    pay_rate,
    bonus_amount,
    deduction_amount,
    gross_pay,
    net_pay,
    payment_method
) VALUES
    (1, 1, 76.00, 4.00, 60.00, 24.50, 100.00, 50.00, 2060.00, 2010.00, 'Direct Deposit'),
    (1, 2, 72.00, 2.00, 55.00, 22.00, 0.00, 40.00, 1628.00, 1588.00, 'Direct Deposit');


INSERT INTO plant_master 
(common_name, scientific_name, light_level, watering_frequency, temperature_range, humidity_range, photo_url, notes, is_active)
VALUES
('Snake Plant','Dracaena trifasciata','Low to Bright Indirect','Every 2-3 weeks','60-85°F','Low','', 'Very hardy, good for beginners', TRUE),
('Peace Lily','Spathiphyllum wallisii','Low to Medium','Weekly','65-80°F','Medium','', 'Flowers indoors, likes moisture', TRUE),
('Fiddle Leaf Fig','Ficus lyrata','Bright Indirect','Weekly','65-75°F','Medium','', 'Sensitive to changes', TRUE),
('Spider Plant','Chlorophytum comosum','Bright Indirect','Weekly','60-80°F','Medium','', 'Produces baby plants', TRUE),
('Pothos','Epipremnum aureum','Low to Bright','Every 1-2 weeks','65-85°F','Low','', 'Very easy to grow', TRUE),
('Monstera','Monstera deliciosa','Bright Indirect','Weekly','65-85°F','Medium','', 'Large split leaves', TRUE),
('ZZ Plant','Zamioculcas zamiifolia','Low to Bright','Every 2-3 weeks','60-85°F','Low','', 'Very drought tolerant', TRUE),
('Rubber Plant','Ficus elastica','Bright Indirect','Weekly','60-80°F','Medium','', 'Glossy leaves', TRUE),
('Boston Fern','Nephrolepis exaltata','Indirect','2-3 times weekly','60-75°F','High','', 'Needs humidity', TRUE),
('Aloe Vera','Aloe barbadensis miller','Bright Direct','Every 2-3 weeks','55-80°F','Low','', 'Succulent, medicinal', TRUE),

('Jade Plant','Crassula ovata','Bright Direct','Every 2-3 weeks','60-75°F','Low','', 'Succulent, long lifespan', TRUE),
('Areca Palm','Dypsis lutescens','Bright Indirect','Weekly','65-75°F','Medium','', 'Adds tropical look', TRUE),
('Calathea','Calathea ornata','Low to Medium','Weekly','65-80°F','High','', 'Sensitive to water quality', TRUE),
('Philodendron','Philodendron hederaceum','Low to Bright','Weekly','65-85°F','Medium','', 'Trailing plant', TRUE),
('Chinese Evergreen','Aglaonema','Low to Medium','Weekly','65-80°F','Medium','', 'Tolerates low light', TRUE),
('Dracaena','Dracaena marginata','Low to Bright','Every 1-2 weeks','65-80°F','Low','', 'Tall indoor plant', TRUE),
('Parlor Palm','Chamaedorea elegans','Low to Medium','Weekly','65-80°F','Medium','', 'Classic indoor palm', TRUE),
('Croton','Codiaeum variegatum','Bright Light','Weekly','65-85°F','Medium','', 'Colorful leaves', TRUE),
('Bamboo Palm','Chamaedorea seifrizii','Indirect','Weekly','65-80°F','Medium','', 'Air purifying', TRUE),
('Kentia Palm','Howea forsteriana','Indirect','Weekly','60-80°F','Medium','', 'Slow growing', TRUE),

('Anthurium','Anthurium andraeanum','Bright Indirect','Weekly','65-80°F','High','', 'Red waxy flowers', TRUE),
('Orchid','Phalaenopsis','Bright Indirect','Weekly','65-80°F','High','', 'Needs careful watering', TRUE),
('Lavender','Lavandula','Full Sun','Weekly','60-85°F','Low','', 'Fragrant herb', TRUE),
('Rosemary','Rosmarinus officinalis','Full Sun','Weekly','60-80°F','Low','', 'Herb plant', TRUE),
('Mint','Mentha','Partial Sun','2-3 times weekly','60-75°F','Medium','', 'Fast growing herb', TRUE),
('Basil','Ocimum basilicum','Full Sun','Weekly','65-85°F','Medium','', 'Common herb', TRUE),
('Thyme','Thymus vulgaris','Full Sun','Weekly','60-80°F','Low','', 'Drought tolerant herb', TRUE),
('Cactus','Various','Full Sun','Every 3-4 weeks','60-90°F','Low','', 'Minimal water needed', TRUE),
('Succulent Mix','Various','Bright Light','Every 2-3 weeks','60-85°F','Low','', 'Assorted succulents', TRUE),
('Air Plant','Tillandsia','Indirect','Mist weekly','60-80°F','Medium','', 'No soil required', TRUE),

('Bird of Paradise','Strelitzia reginae','Bright Light','Weekly','65-85°F','Medium','', 'Large tropical plant', TRUE),
('Banana Plant','Musa','Bright Light','Weekly','65-85°F','High','', 'Large leaves', TRUE),
('Yucca','Yucca elephantipes','Bright Light','Every 2 weeks','60-85°F','Low','', 'Drought tolerant', TRUE),
('Dieffenbachia','Dieffenbachia seguine','Indirect','Weekly','65-80°F','Medium','', 'Large patterned leaves', TRUE),
('Oxalis','Oxalis triangularis','Bright Indirect','Weekly','60-75°F','Medium','', 'Purple leaves', TRUE),
('Coleus','Plectranthus scutellarioides','Bright Indirect','Weekly','65-80°F','Medium','', 'Colorful foliage', TRUE),
('Begonia','Begonia rex','Indirect','Weekly','65-75°F','High','', 'Decorative leaves', TRUE),
('Gardenia','Gardenia jasminoides','Bright Light','Weekly','65-75°F','High','', 'Fragrant flowers', TRUE),
('Hibiscus','Hibiscus rosa-sinensis','Full Sun','Weekly','65-85°F','Medium','', 'Large flowers', TRUE),
('Geranium','Pelargonium','Full Sun','Weekly','60-80°F','Low','', 'Outdoor/indoor plant', TRUE);


INSERT INTO material_requests (
    request_code,
    employee_id,
    task_id,
    note,
    status,
    created_at
) VALUES
    (
        'MR-20260415-001',
        4,
        (SELECT task_id FROM tasks WHERE task_name = 'Install lobby display set' ORDER BY task_id DESC LIMIT 1),
        'Need additional ceramic pots before install.',
        'Approved',
        '2026-04-15 13:30:00'
    );

INSERT INTO material_request_items (material_request_id, item_id, quantity_requested) VALUES
    (
        (SELECT material_request_id FROM material_requests WHERE request_code = 'MR-20260415-001'),
        2,
        2.00
    );

INSERT INTO material_usage_logs (
    task_id,
    employee_id,
    logged_at
) VALUES
    (
        (SELECT task_id FROM tasks WHERE task_name = 'Install lobby display set' ORDER BY task_id DESC LIMIT 1),
        4,
        '2026-04-20 11:15:00'
    );

INSERT INTO material_usage_items (usage_log_id, item_id, quantity_used) VALUES
    (
        (SELECT usage_log_id FROM material_usage_logs ORDER BY usage_log_id DESC LIMIT 1),
        2,
        4.00
    );
