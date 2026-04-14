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
    contact_user_id INT,
    company_name VARCHAR(255),
    member_since DATETIME,
    account_status VARCHAR(50),
    FOREIGN KEY (contact_user_id) REFERENCES users(user_id),
    FOREIGN KEY (member_since) REFERENCES users(created_at)
);

CREATE TABLE client_locations (
    location_id INT PRIMARY KEY AUTO_INCREMENT,
    client_id INT NOT NULL,
    address_id INT NOT NULL,
    location_name VARCHAR(255),
    FOREIGN KEY (client_id) REFERENCES clients(client_id),
    FOREIGN KEY (address_id) REFERENCES addresses(address_id)
);

-- EMPLOYEES

CREATE TABLE employees (
    employee_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    employee_code VARCHAR(20) NOT NULL UNIQUE,
    job_title VARCHAR(150),
    employment_status VARCHAR(50),
    hire_date DATETIME,
    pay_rate_hourly DECIMAL(10,2),
    address_id INT,
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
    notes TEXT
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
    FOREIGN KEY (plant_id) REFERENCES plant_master(plant_id),
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
);

-- SERVICES

CREATE TABLE services (
    service_id INT PRIMARY KEY AUTO_INCREMENT,
    service_name VARCHAR(255) NOT NULL,
    description TEXT,
    base_price DECIMAL(10,2)
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
    FOREIGN KEY (client_id) REFERENCES clients(client_id),
    FOREIGN KEY (job_order_id) REFERENCES job_orders(job_order_id)
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

-- DUMMY DATA


-- USERS
INSERT INTO users (user_id, role, email, password, first_name, last_name, phone) VALUES
(1, 'Management', 'admin@dcplants.com', 'hash', 'Angela', 'Reed', '202-555-0101'),
(2, 'Staff', 'jason@dcplants.com', 'hash', 'Jason', 'Miller', '202-555-0102'),
(3, 'Staff', 'maria@dcplants.com', 'hash', 'Maria', 'Lopez', '202-555-0103'),
(4, 'Client', 'facilities@capitolco.com', 'hash', 'David', 'Kim', '202-555-0201'),
(5, 'Client', 'admin@dupontlaw.com', 'hash', 'Rachel', 'Green', '202-555-0202');

-- ADDRESSES
INSERT INTO addresses (address_id, street_1, city, state, zip_code) VALUES
(1, '1200 G St NW', 'Washington', 'DC', '20005'),
(2, '2000 M St NW', 'Washington', 'DC', '20036'),
(3, '1500 K St NW', 'Washington', 'DC', '20005'),
(4, '7700 Old Georgetown Rd', 'Bethesda', 'MD', '20814'),
(5, '2200 Crystal Dr', 'Arlington', 'VA', '22202'),
(6, '900 7th St NW', 'Washington', 'DC', '20001');

-- CLIENTS
INSERT INTO clients (client_id, contact_user_id, company_name, member_since, account_status) VALUES
(1, 4, 'Capitol CoWorking', '2023-01-15', 'Active'),
(2, 5, 'Dupont Legal Group', '2024-03-10', 'Active');

-- CLIENT LOCATIONS
INSERT INTO client_locations (location_id, client_id, address_id, location_name) VALUES
(1, 1, 1, 'Capitol HQ'),
(2, 1, 3, 'Capitol Annex'),
(3, 2, 2, 'Dupont Office');

-- EMPLOYEES
INSERT INTO employees (employee_id, user_id, employee_code, job_title, employment_status, hire_date, pay_rate_hourly, address_id) VALUES
(1, 2, 'EMP001', 'Plant Technician', 'Active', '2022-06-01', 22.50, 4),
(2, 3, 'EMP002', 'Senior Horticulturist', 'Active', '2021-02-15', 28.00, 5);

-- EMPLOYEE SKILLS
INSERT INTO employee_skills (employee_id, skill_name) VALUES
(1, 'Indoor Plant Care'),
(1, 'Watering Systems'),
(2, 'Plant Diagnosis'),
(2, 'Design & Installation');

-- SUPPLIERS
INSERT INTO suppliers (supplier_id, supplier_name, phone, email, address_id, status) VALUES
(1, 'GreenGrow Nursery', '301-555-1111', 'sales@greengrow.com', 4, 'Delivered'),
(2, 'Urban Plant Supply', '703-555-2222', 'info@urbanplants.com', 5, 'Delivered');

-- PLANT MASTER
INSERT INTO plant_master (plant_id, common_name, scientific_name, light_level, watering_frequency) VALUES
(1, 'Snake Plant', 'Sansevieria trifasciata', 'Low', 'Biweekly'),
(2, 'Fiddle Leaf Fig', 'Ficus lyrata', 'Bright', 'Weekly'),
(3, 'Pothos', 'Epipremnum aureum', 'Low-Medium', 'Weekly');

-- INVENTORY
INSERT INTO inventory_items (item_id, item_name, item_type, plant_id, supplier_id, sku, unit_price, quantity_on_hand, reorder_level, unit_label) VALUES
(1, 'Snake Plant 10in', 'Plant', 1, 1, 'SP-10', 25.00, 50, 10, 'each'),
(2, 'Fiddle Leaf Fig 12in', 'Plant', 2, 1, 'FLF-12', 60.00, 20, 5, 'each'),
(3, 'Potting Soil Bag', 'Supply', NULL, 2, 'SOIL-01', 8.50, 100, 20, 'bag');

-- SERVICES
INSERT INTO services (service_id, service_name, description, base_price) VALUES
(1, 'Plant Maintenance', 'Routine watering and care', 150.00),
(2, 'Plant Installation', 'New plant installation', 500.00),
(3, 'Plant Replacement', 'Replace unhealthy plants', 200.00);

-- SERVICE REQUESTS
INSERT INTO service_requests (service_request_id, client_id, location_id, service_id, requested_date, status, approved_by) VALUES
(1, 1, 1, 1, '2026-04-10', 'Approved', 1);

-- APPOINTMENTS
INSERT INTO appointments (appointment_id, client_id, location_id, service_id, service_request_id, assigned_employee_id, appointment_date, start_time, end_time, status) VALUES
(1, 1, 1, 1, 1, 1, '2026-04-15', '09:00:00', '11:00:00', 'Scheduled');

-- JOB ORDERS
INSERT INTO job_orders (job_order_id, job_order_code, client_id, location_id, service_id, appointment_id, assigned_employee_id, title, scheduled_date, status, priority) VALUES
(1, 'JOB-DC-001', 1, 1, 1, 1, 1, 'Weekly Plant Maintenance', '2026-04-15', 'Open', 'Medium');

-- TASKS
INSERT INTO tasks (task_id, job_order_id, assigned_employee_id, task_name, status) VALUES
(1, 1, 1, 'Water Plants', 'Pending'),
(2, 1, 1, 'Inspect Leaves', 'Pending');

-- TASK MATERIALS
INSERT INTO task_materials (task_id, item_id, required_quantity) VALUES
(1, 3, 2.00);

-- INVOICES
INSERT INTO invoices (invoice_id, invoice_number, client_id, job_order_id, issue_date, due_date, subtotal, tax_amount, total_amount, status) VALUES
(1, 'INV-DC-001', 1, 1, '2026-04-15', '2026-04-30', 150.00, 9.00, 159.00, 'Pending');

-- INVOICE ITEMS
INSERT INTO invoice_items (invoice_id, description, quantity, unit_price, line_total) VALUES
(1, 'Plant Maintenance Service', 1, 150.00, 150.00);

-- PAYMENTS
INSERT INTO payments (invoice_id, payment_date, amount, payment_method) VALUES
(1, '2026-04-16', 159.00, 'Credit Card');

-- PAYROLL
INSERT INTO payroll_periods (payroll_period_id, period_start, period_end, payment_date) VALUES
(1, '2026-04-01', '2026-04-15', '2026-04-20');

INSERT INTO payroll_records (payroll_period_id, employee_id, regular_hours, pay_rate, gross_pay, net_pay, payment_method) VALUES
(1, 1, 80, 22.50, 1800.00, 1500.00, 'Direct Deposit');

-- MATERIAL REQUESTS
INSERT INTO material_requests (material_request_id, request_code, employee_id, task_id, status) VALUES
(1, 'MR-001', 1, 1, 'Approved');

INSERT INTO material_request_items (material_request_id, item_id, quantity_requested) VALUES
(1, 3, 5.00);

-- MATERIAL USAGE
INSERT INTO material_usage_logs (usage_log_id, task_id, employee_id) VALUES
(1, 1, 1);

INSERT INTO material_usage_items (usage_log_id, item_id, quantity_used) VALUES
(1, 3, 2.00);
