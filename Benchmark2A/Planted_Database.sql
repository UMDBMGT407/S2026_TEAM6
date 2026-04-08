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
DROP TABLE IF EXISTS clients;
DROP TABLE IF EXISTS addresses;
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
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP  -- tracks when the account was made
);

-- ADDRESSES

CREATE TABLE addresses (
    address_id INT PRIMARY KEY AUTO_INCREMENT, -- Makes it easier to link to other tables
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
    member_since DATE,
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

-- EMPLOYEES / STAFF

CREATE TABLE employees (
    employee_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    employee_code VARCHAR(20) NOT NULL UNIQUE,
    job_title VARCHAR(150),
    employment_status VARCHAR(50),
    hire_date DATE,
    pay_rate_hourly DECIMAL(10,2),
    address_id INT,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (address_id) REFERENCES addresses(address_id),
    FOREIGN KEY (hire_date) REFERENCES users(created_at)
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
    PRIMARY KEY (employee_id, week_start_date, day_of_week), --makes it so each employee can only have one availability entry for each day in each week
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
    status ENUM('Ordered','Shipped','Delivered'), -- Changed from VARCHAR to ENUM because it simplifies the options
    FOREIGN KEY (address_id) REFERENCES addresses(address_id)
);

-- PLANT MASTER LIST

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

-- STAFF MATERIAL REQUESTS

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

-- STAFF MATERIAL USAGE LOGS

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
