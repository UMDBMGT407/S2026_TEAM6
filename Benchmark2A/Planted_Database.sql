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
    FOREIGN KEY (contact_user_id) REFERENCES users(user_id) ON DELETE CASCADE
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
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
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
    FOREIGN KEY (approved_by) REFERENCES users(user_id) ON DELETE CASCADE
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



-- DUMMY DATA FOR DEMO


-- ADDRESSES
INSERT INTO addresses (street_1, city, state, zip_code) VALUES
('123 Garden St', 'Los Angeles', 'CA', '90001'),
('456 Office Blvd', 'San Diego', 'CA', '92101'),
('789 Green Ave', 'San Jose', 'CA', '95101'),
('222 Supply Rd', 'Fresno', 'CA', '93701');

-- USERS
INSERT INTO users (role, email, password, first_name, last_name, phone) VALUES
('Management', 'manager@test.com', 'pass', 'Olivia', 'Grant', '555-111-2222'),
('Staff', 'martha@test.com', 'pass', 'Martha', 'Schemer', '555-222-3333'),
('Staff', 'mike@test.com', 'pass', 'Mike', 'Chen', '555-333-4444'),
('Client', 'client1@test.com', 'pass', 'Jessica', 'Day', '555-444-5555'),
('Client', 'client2@test.com', 'pass', 'Sarah', 'Mitchell', '555-555-6666');

-- CLIENTS
INSERT INTO clients (contact_user_id, company_name, account_status) VALUES
(4, 'Tech Innovations Inc.', 'Active'),
(5, NULL, 'Active');

-- CLIENT LOCATIONS
INSERT INTO client_locations (client_id, address_id, location_name) VALUES
(1, 2, 'Main Office'),
(2, 1, 'Home Address');

-- EMPLOYEES
INSERT INTO employees (user_id, employee_code, job_title, employment_status, hire_date, pay_rate_hourly, address_id) VALUES
(2, 'EMP001', 'Horticulturist', 'Active', '2025-01-01', 25.00, 3),
(3, 'EMP002', 'Technician', 'Active', '2025-02-01', 22.00, 3);

-- EMPLOYEE SKILLS
INSERT INTO employee_skills (employee_id, skill_name) VALUES
(1, 'Plant Installation'),
(1, 'Maintenance'),
(2, 'Pest Control'),
(2, 'Irrigation');

-- EMPLOYEE AVAILABILITY
INSERT INTO employee_availability 
(employee_id, week_start_date, day_of_week, available_from, available_to) VALUES
(1, '2026-04-07', 1, '08:00', '16:00'),
(1, '2026-04-07', 2, '08:00', '16:00'),
(2, '2026-04-07', 1, '10:00', '18:00');

-- SUPPLIERS
INSERT INTO suppliers (supplier_name, phone, email, address_id, total_orders, last_order_date, status) VALUES
('Green Thumb Nursery', '555-777-8888', 'orders@greenthumb.com', 4, 120, '2026-03-01', 'Delivered'),
('Soil Solutions', '555-888-9999', 'sales@soil.com', 4, 80, '2026-02-20', 'Shipped');

-- PLANT MASTER
INSERT INTO plant_master (common_name, scientific_name, light_level, watering_frequency) VALUES
('Monstera', 'Monstera deliciosa', 'Bright Indirect', 'Weekly'),
('Snake Plant', 'Sansevieria', 'Low Light', 'Biweekly');

-- INVENTORY
INSERT INTO inventory_items 
(item_name, item_type, plant_id, supplier_id, unit_price, quantity_on_hand, reorder_level, unit_label) VALUES
('Monstera Plant', 'Plant', 1, 1, 45.00, 10, 5, 'units'),
('Snake Plant', 'Plant', 2, 1, 25.00, 20, 10, 'units'),
('Potting Soil', 'Supply', NULL, 2, 15.00, 5, 10, 'bags');

-- SERVICES
INSERT INTO services (service_name, description, base_price) VALUES
('Plant Installation', 'Install plants at location', 200),
('Weekly Maintenance', 'Routine plant care', 100);

-- SERVICE REQUESTS
INSERT INTO service_requests (client_id, location_id, service_id, requested_date, status, approved_by) VALUES
(1, 1, 1, '2026-04-10', 'Approved', 1),
(2, 2, 2, '2026-04-12', 'Pending', 1);

-- APPOINTMENTS
INSERT INTO appointments 
(client_id, location_id, service_id, service_request_id, assigned_employee_id, appointment_date, start_time, end_time, status) VALUES
(1, 1, 1, 1, 1, '2026-04-10', '09:00', '12:00', 'Scheduled');

-- JOB ORDERS
INSERT INTO job_orders 
(job_order_code, client_id, location_id, service_id, appointment_id, assigned_employee_id, title, description, status) VALUES
('JO-001', 1, 1, 1, 1, 1, 'Install Plants', 'Install plants in office lobby', 'Scheduled');

-- TASKS
INSERT INTO tasks 
(job_order_id, assigned_employee_id, task_name, description, status) VALUES
(1, 1, 'Install Monstera', 'Place plants in lobby area', 'Incomplete');

-- TASK MATERIALS
INSERT INTO task_materials (task_id, item_id, required_quantity) VALUES
(1, 1, 2),
(1, 3, 1);

-- INVOICES
INSERT INTO invoices 
(invoice_number, client_id, job_order_id, issue_date, due_date, total_amount, status) VALUES
('INV-001', 1, 1, '2026-04-10', '2026-04-20', 250.00, 'Due');

-- INVOICE ITEMS
INSERT INTO invoice_items (invoice_id, description, quantity, unit_price, line_total) VALUES
(1, 'Plant Installation Service', 1, 250.00, 250.00);

-- PAYMENTS
INSERT INTO payments (invoice_id, payment_date, amount, payment_method) VALUES
(1, '2026-04-11', 250.00, 'Card');

-- PAYROLL
INSERT INTO payroll_periods (period_start, period_end, payment_date) VALUES
('2026-04-01', '2026-04-15', '2026-04-16');

INSERT INTO payroll_records 
(payroll_period_id, employee_id, regular_hours, pay_rate, gross_pay, net_pay) VALUES
(1, 1, 80, 25.00, 2000.00, 1800.00);

-- MATERIAL REQUESTS
INSERT INTO material_requests (request_code, employee_id, task_id, status) VALUES
('REQ-001', 1, 1, 'Submitted');

-- MATERIAL REQUEST ITEMS
INSERT INTO material_request_items (material_request_id, item_id, quantity_requested) VALUES
(1, 3, 2);

-- MATERIAL USAGE LOGS
INSERT INTO material_usage_logs (task_id, employee_id) VALUES
(1, 1);

-- MATERIAL USAGE ITEMS
INSERT INTO material_usage_items (usage_log_id, item_id, quantity_used) VALUES
(1, 1, 2),
(1, 3, 1);
