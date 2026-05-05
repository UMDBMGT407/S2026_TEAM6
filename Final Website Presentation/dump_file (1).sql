-- MySQL dump 10.13  Distrib 8.0.45, for macos15 (arm64)
--
-- Host: localhost    Database: user_management
-- ------------------------------------------------------
-- Server version	8.2.0

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `addresses`
--

DROP TABLE IF EXISTS `addresses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `addresses` (
  `address_id` int NOT NULL AUTO_INCREMENT,
  `street_1` varchar(255) NOT NULL,
  `city` varchar(100) NOT NULL,
  `state` varchar(100) NOT NULL,
  `zip_code` varchar(20) NOT NULL,
  PRIMARY KEY (`address_id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `addresses`
--

LOCK TABLES `addresses` WRITE;
/*!40000 ALTER TABLE `addresses` DISABLE KEYS */;
INSERT INTO `addresses` VALUES (1,'101 Garden Ave','Baltimore','MD','21201'),(2,'202 Greenway Dr','Baltimore','MD','21202'),(3,'303 Orchard Ln','Baltimore','MD','21203'),(4,'500 Harbor Pl','Baltimore','MD','21230'),(5,'1200 Warehouse Rd','Baltimore','MD','21224'),(6,'88 Market St','Towson','MD','21286'),(7,'410 North Park','Baltimore','MD','21210'),(8,'77 Elm Street','Catonsville','MD','21228'),(9,'900 Charles St','Baltimore','MD','21201'),(10,'1000 Commerce Blvd','Columbia','MD','21044'),(11,'45 Dockside Way','Baltimore','MD','21231');
/*!40000 ALTER TABLE `addresses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `appointments`
--

DROP TABLE IF EXISTS `appointments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `appointments` (
  `appointment_id` int NOT NULL AUTO_INCREMENT,
  `client_id` int NOT NULL,
  `location_id` int NOT NULL,
  `service_id` int NOT NULL,
  `service_request_id` int DEFAULT NULL,
  `assigned_employee_id` int DEFAULT NULL,
  `appointment_date` date NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `status` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`appointment_id`),
  KEY `client_id` (`client_id`),
  KEY `location_id` (`location_id`),
  KEY `service_id` (`service_id`),
  KEY `service_request_id` (`service_request_id`),
  KEY `assigned_employee_id` (`assigned_employee_id`),
  CONSTRAINT `appointments_ibfk_1` FOREIGN KEY (`client_id`) REFERENCES `clients` (`client_id`),
  CONSTRAINT `appointments_ibfk_2` FOREIGN KEY (`location_id`) REFERENCES `client_locations` (`location_id`),
  CONSTRAINT `appointments_ibfk_3` FOREIGN KEY (`service_id`) REFERENCES `services` (`service_id`),
  CONSTRAINT `appointments_ibfk_4` FOREIGN KEY (`service_request_id`) REFERENCES `service_requests` (`service_request_id`),
  CONSTRAINT `appointments_ibfk_5` FOREIGN KEY (`assigned_employee_id`) REFERENCES `employees` (`employee_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `appointments`
--

LOCK TABLES `appointments` WRITE;
/*!40000 ALTER TABLE `appointments` DISABLE KEYS */;
INSERT INTO `appointments` VALUES (1,3,5,2,9,4,'2026-04-23','10:00:00','11:30:00','Scheduled'),(2,4,6,1,10,5,'2026-04-21','15:00:00','16:00:00','Scheduled');
/*!40000 ALTER TABLE `appointments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `client_locations`
--

DROP TABLE IF EXISTS `client_locations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `client_locations` (
  `location_id` int NOT NULL AUTO_INCREMENT,
  `client_id` int NOT NULL,
  `address_id` int NOT NULL,
  `location_name` varchar(255) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`location_id`),
  KEY `client_id` (`client_id`),
  KEY `address_id` (`address_id`),
  CONSTRAINT `client_locations_ibfk_1` FOREIGN KEY (`client_id`) REFERENCES `clients` (`client_id`),
  CONSTRAINT `client_locations_ibfk_2` FOREIGN KEY (`address_id`) REFERENCES `addresses` (`address_id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `client_locations`
--

LOCK TABLES `client_locations` WRITE;
/*!40000 ALTER TABLE `client_locations` DISABLE KEYS */;
INSERT INTO `client_locations` VALUES (1,1,4,'HQ Lobby',1),(2,1,5,'Warehouse',1),(3,2,6,'Main Storefront',1),(4,3,9,'Hotel Lobby',1),(5,3,10,'Hotel Annex',1),(6,4,11,'Downtown Flex Space',1);
/*!40000 ALTER TABLE `client_locations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `clients`
--

DROP TABLE IF EXISTS `clients`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `clients` (
  `client_id` int NOT NULL AUTO_INCREMENT,
  `contact_user_id` int NOT NULL,
  `company_name` varchar(255) NOT NULL,
  `member_since` datetime DEFAULT CURRENT_TIMESTAMP,
  `account_status` varchar(50) DEFAULT 'Active',
  `is_active` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`client_id`),
  UNIQUE KEY `contact_user_id` (`contact_user_id`),
  CONSTRAINT `clients_ibfk_1` FOREIGN KEY (`contact_user_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `clients`
--

LOCK TABLES `clients` WRITE;
/*!40000 ALTER TABLE `clients` DISABLE KEYS */;
INSERT INTO `clients` VALUES (1,6,'BrenCo Offices','2025-01-15 10:00:00','Active',1),(2,7,'Ivy Retail Group','2025-05-01 09:00:00','Active',1),(3,10,'Nora Hospitality','2025-09-10 09:15:00','Active',1),(4,11,'Oscar CoWorking','2025-11-20 13:40:00','Active',1);
/*!40000 ALTER TABLE `clients` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `employee_availability`
--

DROP TABLE IF EXISTS `employee_availability`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `employee_availability` (
  `employee_id` int NOT NULL,
  `week_start_date` date NOT NULL,
  `day_of_week` int NOT NULL,
  `available_from` time DEFAULT NULL,
  `available_to` time DEFAULT NULL,
  `is_available` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`employee_id`,`week_start_date`,`day_of_week`),
  CONSTRAINT `employee_availability_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `employee_availability`
--

LOCK TABLES `employee_availability` WRITE;
/*!40000 ALTER TABLE `employee_availability` DISABLE KEYS */;
INSERT INTO `employee_availability` VALUES (1,'2026-04-13',1,'08:00:00','17:00:00',1),(1,'2026-04-13',2,'08:00:00','17:00:00',1),(1,'2026-04-13',3,'08:00:00','17:00:00',1),(1,'2026-04-13',4,'08:00:00','12:00:00',1),(1,'2026-04-13',5,NULL,NULL,0),(1,'2026-04-20',1,'08:00:00','16:00:00',1),(1,'2026-04-20',2,'08:00:00','16:00:00',1),(1,'2026-04-20',3,'08:00:00','16:00:00',1),(1,'2026-04-20',4,'08:00:00','16:00:00',1),(1,'2026-04-20',5,'08:00:00','13:00:00',1),(2,'2026-04-13',1,NULL,NULL,0),(2,'2026-04-13',2,'12:00:00','20:00:00',1),(2,'2026-04-13',3,'12:00:00','20:00:00',1),(2,'2026-04-13',4,'12:00:00','20:00:00',1),(2,'2026-04-13',5,'12:00:00','20:00:00',1),(2,'2026-04-20',1,'12:00:00','20:00:00',1),(2,'2026-04-20',2,'12:00:00','20:00:00',1),(2,'2026-04-20',3,'12:00:00','20:00:00',1),(2,'2026-04-20',4,'12:00:00','20:00:00',1),(2,'2026-04-20',5,NULL,NULL,0),(4,'2026-04-20',1,'07:00:00','15:00:00',1),(4,'2026-04-20',2,'07:00:00','15:00:00',1),(4,'2026-04-20',3,'07:00:00','15:00:00',1),(4,'2026-04-20',4,'07:00:00','15:00:00',1),(4,'2026-04-20',5,'07:00:00','12:00:00',1),(5,'2026-04-20',1,'14:00:00','21:00:00',1),(5,'2026-04-20',2,'14:00:00','21:00:00',1),(5,'2026-04-20',3,'14:00:00','21:00:00',1),(5,'2026-04-20',4,'14:00:00','21:00:00',1),(5,'2026-04-20',5,'14:00:00','18:00:00',1);
/*!40000 ALTER TABLE `employee_availability` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `employee_skills`
--

DROP TABLE IF EXISTS `employee_skills`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `employee_skills` (
  `skill_id` int NOT NULL AUTO_INCREMENT,
  `employee_id` int NOT NULL,
  `skill_name` varchar(100) NOT NULL,
  PRIMARY KEY (`skill_id`),
  KEY `employee_id` (`employee_id`),
  CONSTRAINT `employee_skills_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`employee_id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `employee_skills`
--

LOCK TABLES `employee_skills` WRITE;
/*!40000 ALTER TABLE `employee_skills` DISABLE KEYS */;
INSERT INTO `employee_skills` VALUES (1,1,'Watering'),(2,1,'Pruning'),(3,2,'Pest Inspection'),(4,2,'Soil Testing'),(5,4,'Installations'),(6,4,'Client Training'),(7,5,'Emergency Response');
/*!40000 ALTER TABLE `employee_skills` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `employees`
--

DROP TABLE IF EXISTS `employees`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `employees` (
  `employee_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `employee_code` varchar(20) NOT NULL,
  `job_title` varchar(150) DEFAULT NULL,
  `employment_status` varchar(50) DEFAULT 'Active',
  `hire_date` datetime DEFAULT NULL,
  `pay_rate_hourly` decimal(10,2) DEFAULT NULL,
  `address_id` int DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`employee_id`),
  UNIQUE KEY `user_id` (`user_id`),
  UNIQUE KEY `employee_code` (`employee_code`),
  KEY `address_id` (`address_id`),
  CONSTRAINT `employees_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`),
  CONSTRAINT `employees_ibfk_2` FOREIGN KEY (`address_id`) REFERENCES `addresses` (`address_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `employees`
--

LOCK TABLES `employees` WRITE;
/*!40000 ALTER TABLE `employees` DISABLE KEYS */;
INSERT INTO `employees` VALUES (1,3,'EMP-1001','Horticulture Technician','Active','2024-06-10 08:00:00',24.50,1,1),(2,4,'EMP-1002','Plant Care Specialist','Active','2024-08-05 08:00:00',22.00,2,1),(3,5,'EMP-1003','Field Technician','Inactive','2024-09-15 08:00:00',21.00,3,1),(4,8,'EMP-1004','Senior Plant Technician','Active','2023-11-01 08:00:00',27.00,7,1),(5,9,'EMP-1005','Field Specialist','Active','2025-02-12 08:00:00',23.25,8,1);
/*!40000 ALTER TABLE `employees` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `inventory_items`
--

DROP TABLE IF EXISTS `inventory_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inventory_items` (
  `item_id` int NOT NULL AUTO_INCREMENT,
  `item_name` varchar(255) NOT NULL,
  `item_type` varchar(100) DEFAULT NULL,
  `plant_id` int DEFAULT NULL,
  `supplier_id` int DEFAULT NULL,
  `sku` varchar(100) DEFAULT NULL,
  `unit_price` decimal(10,2) DEFAULT NULL,
  `quantity_on_hand` decimal(10,2) DEFAULT NULL,
  `reorder_level` decimal(10,2) DEFAULT NULL,
  `unit_label` varchar(50) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`item_id`),
  KEY `plant_id` (`plant_id`),
  KEY `supplier_id` (`supplier_id`),
  CONSTRAINT `inventory_items_ibfk_1` FOREIGN KEY (`plant_id`) REFERENCES `plant_master` (`plant_id`),
  CONSTRAINT `inventory_items_ibfk_2` FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`supplier_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inventory_items`
--

LOCK TABLES `inventory_items` WRITE;
/*!40000 ALTER TABLE `inventory_items` DISABLE KEYS */;
INSERT INTO `inventory_items` VALUES (1,'Premium Potting Mix','Soil',NULL,2,'SOIL-001',14.99,52.00,20.00,'bags',1),(2,'14in Ceramic Pot','Container',NULL,1,'POT-014',24.50,18.00,8.00,'each',1),(3,'Fiddle Leaf Fig (Medium)','Plant',1,1,'PLANT-FLF-M',39.00,11.00,4.00,'each',1);
/*!40000 ALTER TABLE `inventory_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `invoice_items`
--

DROP TABLE IF EXISTS `invoice_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `invoice_items` (
  `invoice_item_id` int NOT NULL AUTO_INCREMENT,
  `invoice_id` int NOT NULL,
  `description` varchar(255) NOT NULL,
  `quantity` decimal(10,2) DEFAULT NULL,
  `unit_price` decimal(10,2) DEFAULT NULL,
  `line_total` decimal(10,2) DEFAULT NULL,
  PRIMARY KEY (`invoice_item_id`),
  KEY `invoice_id` (`invoice_id`),
  CONSTRAINT `invoice_items_ibfk_1` FOREIGN KEY (`invoice_id`) REFERENCES `invoices` (`invoice_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `invoice_items`
--

LOCK TABLES `invoice_items` WRITE;
/*!40000 ALTER TABLE `invoice_items` DISABLE KEYS */;
INSERT INTO `invoice_items` VALUES (1,1,'Lobby plant maintenance service',1.00,150.00,150.00),(2,2,'Warehouse plant health check',1.00,100.00,100.00),(3,3,'Office Plant Installation Service',1.00,350.00,350.00);
/*!40000 ALTER TABLE `invoice_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `invoices`
--

DROP TABLE IF EXISTS `invoices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `invoices` (
  `invoice_id` int NOT NULL AUTO_INCREMENT,
  `invoice_number` varchar(50) NOT NULL,
  `client_id` int NOT NULL,
  `job_order_id` int DEFAULT NULL,
  `issue_date` date NOT NULL,
  `due_date` date NOT NULL,
  `subtotal` decimal(10,2) DEFAULT NULL,
  `tax_amount` decimal(10,2) DEFAULT NULL,
  `total_amount` decimal(10,2) DEFAULT NULL,
  `status` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`invoice_id`),
  UNIQUE KEY `invoice_number` (`invoice_number`),
  KEY `client_id` (`client_id`),
  CONSTRAINT `invoices_ibfk_1` FOREIGN KEY (`client_id`) REFERENCES `clients` (`client_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `invoices`
--

LOCK TABLES `invoices` WRITE;
/*!40000 ALTER TABLE `invoices` DISABLE KEYS */;
INSERT INTO `invoices` VALUES (1,'INV-1001',1,1,'2026-04-10','2026-04-25',150.00,30.00,180.00,'Unpaid'),(2,'INV-1002',1,2,'2026-03-20','2026-04-04',100.00,20.00,120.00,'Paid'),(3,'INV-20260420-001',3,12,'2026-04-20','2026-05-04',350.00,21.00,371.00,'Issued');
/*!40000 ALTER TABLE `invoices` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `job_orders`
--

DROP TABLE IF EXISTS `job_orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `job_orders` (
  `job_order_id` int NOT NULL AUTO_INCREMENT,
  `job_order_code` varchar(50) NOT NULL,
  `client_id` int NOT NULL,
  `location_id` int NOT NULL,
  `service_id` int NOT NULL,
  `appointment_id` int DEFAULT NULL,
  `service_request_id` int DEFAULT NULL,
  `assigned_employee_id` int DEFAULT NULL,
  `title` varchar(255) NOT NULL,
  `description` text,
  `scheduled_date` date DEFAULT NULL,
  `start_time` time DEFAULT NULL,
  `end_time` time DEFAULT NULL,
  `estimated_cost` decimal(10,2) DEFAULT NULL,
  `status` varchar(50) DEFAULT NULL,
  `priority` varchar(50) DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`job_order_id`),
  UNIQUE KEY `job_order_code` (`job_order_code`),
  KEY `client_id` (`client_id`),
  KEY `location_id` (`location_id`),
  KEY `service_id` (`service_id`),
  KEY `appointment_id` (`appointment_id`),
  KEY `service_request_id` (`service_request_id`),
  KEY `assigned_employee_id` (`assigned_employee_id`),
  CONSTRAINT `job_orders_ibfk_1` FOREIGN KEY (`client_id`) REFERENCES `clients` (`client_id`),
  CONSTRAINT `job_orders_ibfk_2` FOREIGN KEY (`location_id`) REFERENCES `client_locations` (`location_id`),
  CONSTRAINT `job_orders_ibfk_3` FOREIGN KEY (`service_id`) REFERENCES `services` (`service_id`),
  CONSTRAINT `job_orders_ibfk_4` FOREIGN KEY (`appointment_id`) REFERENCES `appointments` (`appointment_id`),
  CONSTRAINT `job_orders_ibfk_5` FOREIGN KEY (`service_request_id`) REFERENCES `service_requests` (`service_request_id`),
  CONSTRAINT `job_orders_ibfk_6` FOREIGN KEY (`assigned_employee_id`) REFERENCES `employees` (`employee_id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `job_orders`
--

LOCK TABLES `job_orders` WRITE;
/*!40000 ALTER TABLE `job_orders` DISABLE KEYS */;
INSERT INTO `job_orders` VALUES (1,'JO-20260410-001',1,2,2,NULL,3,1,'Indoor Plant Health Check','Approved request from BrenCo warehouse.','2026-04-16','13:00:00','14:30:00',120.00,'Scheduled','High','2026-04-10 08:30:00'),(2,'JO-20260411-001',1,1,1,NULL,5,2,'Watering Plants','Approved recurring lobby watering.','2026-04-17','12:00:00','13:00:00',60.00,'Scheduled','Normal','2026-04-11 08:00:00'),(3,'JO-20260412-001',1,1,3,NULL,NULL,NULL,'Office Plant Installation','Manual management-created job order pending assignment.','2026-04-16','13:30:00','14:30:00',350.00,'Unassigned','High','2026-04-12 09:00:00'),(4,'JO-20260413-001',2,3,1,NULL,6,1,'Watering Plants','Completed lunch area watering job.','2026-04-16','09:00:00','10:00:00',60.00,'Completed','Low','2026-04-13 09:00:00'),(5,'JO-20260414-001',2,3,2,NULL,NULL,NULL,'Indoor Plant Health Check','Unassigned health check awaiting staffing.','2026-04-17','09:00:00','10:00:00',120.00,'Unassigned','Normal','2026-04-14 11:00:00'),(6,'JO-20260414-002',2,3,3,NULL,NULL,NULL,'Office Plant Installation','Backlog job with no schedule yet.',NULL,NULL,NULL,350.00,'Unassigned','Low','2026-04-14 12:00:00'),(7,'JO-20260415-101',3,5,2,NULL,9,4,'Indoor Plant Health Check','Approved quarterly wellness for hotel annex.','2026-04-23','10:00:00','11:30:00',120.00,'Scheduled','Normal','2026-04-15 11:00:00'),(8,'JO-20260415-102',4,6,1,NULL,10,5,'Watering Plants','Approved watering for coworking floor.','2026-04-21','15:00:00','16:00:00',60.00,'Scheduled','High','2026-04-15 11:20:00'),(9,'JO-20260415-103',3,4,5,NULL,NULL,NULL,'Emergency Plant Triage','Awaiting assignment for urgent triage request.','2026-04-21','09:00:00','10:30:00',180.00,'Unassigned','High','2026-04-15 11:40:00'),(10,'JO-20260415-104',4,6,6,NULL,NULL,NULL,'Soil and Pot Refresh','Pending materials confirmation before assignment.','2026-04-22','13:00:00','14:30:00',95.00,'Unassigned','Normal','2026-04-15 12:00:00'),(11,'JO-20260415-105',1,1,1,NULL,NULL,2,'Watering Plants','Cancelled schedule scenario for conflict testing.','2026-04-16','14:00:00','15:00:00',60.00,'Cancelled','Low','2026-04-15 12:20:00'),(12,'JO-20260415-106',3,5,3,NULL,NULL,4,'Office Plant Installation','Completed installation follow-up.','2026-04-20','08:00:00','11:00:00',350.00,'Completed','High','2026-04-15 12:40:00'),(13,'JO-20260415-107',4,6,2,NULL,NULL,4,'Indoor Plant Health Check','Active assignment used for overlap checks.','2026-04-21','10:00:00','11:00:00',120.00,'Scheduled','Normal','2026-04-15 13:00:00');
/*!40000 ALTER TABLE `job_orders` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `material_request_items`
--

DROP TABLE IF EXISTS `material_request_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `material_request_items` (
  `material_request_item_id` int NOT NULL AUTO_INCREMENT,
  `material_request_id` int NOT NULL,
  `item_id` int NOT NULL,
  `quantity_requested` decimal(10,2) DEFAULT NULL,
  PRIMARY KEY (`material_request_item_id`),
  KEY `material_request_id` (`material_request_id`),
  KEY `item_id` (`item_id`),
  CONSTRAINT `material_request_items_ibfk_1` FOREIGN KEY (`material_request_id`) REFERENCES `material_requests` (`material_request_id`),
  CONSTRAINT `material_request_items_ibfk_2` FOREIGN KEY (`item_id`) REFERENCES `inventory_items` (`item_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `material_request_items`
--

LOCK TABLES `material_request_items` WRITE;
/*!40000 ALTER TABLE `material_request_items` DISABLE KEYS */;
INSERT INTO `material_request_items` VALUES (1,1,2,2.00);
/*!40000 ALTER TABLE `material_request_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `material_requests`
--

DROP TABLE IF EXISTS `material_requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `material_requests` (
  `material_request_id` int NOT NULL AUTO_INCREMENT,
  `request_code` varchar(50) NOT NULL,
  `employee_id` int NOT NULL,
  `task_id` int DEFAULT NULL,
  `note` text,
  `status` varchar(50) DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`material_request_id`),
  UNIQUE KEY `request_code` (`request_code`),
  KEY `employee_id` (`employee_id`),
  KEY `task_id` (`task_id`),
  CONSTRAINT `material_requests_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`employee_id`),
  CONSTRAINT `material_requests_ibfk_2` FOREIGN KEY (`task_id`) REFERENCES `tasks` (`task_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `material_requests`
--

LOCK TABLES `material_requests` WRITE;
/*!40000 ALTER TABLE `material_requests` DISABLE KEYS */;
INSERT INTO `material_requests` VALUES (1,'MR-20260415-001',4,3,'Need additional ceramic pots before install.','Approved','2026-04-15 13:30:00');
/*!40000 ALTER TABLE `material_requests` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `material_usage_items`
--

DROP TABLE IF EXISTS `material_usage_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `material_usage_items` (
  `usage_item_id` int NOT NULL AUTO_INCREMENT,
  `usage_log_id` int NOT NULL,
  `item_id` int NOT NULL,
  `quantity_used` decimal(10,2) DEFAULT NULL,
  PRIMARY KEY (`usage_item_id`),
  KEY `usage_log_id` (`usage_log_id`),
  KEY `item_id` (`item_id`),
  CONSTRAINT `material_usage_items_ibfk_1` FOREIGN KEY (`usage_log_id`) REFERENCES `material_usage_logs` (`usage_log_id`),
  CONSTRAINT `material_usage_items_ibfk_2` FOREIGN KEY (`item_id`) REFERENCES `inventory_items` (`item_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `material_usage_items`
--

LOCK TABLES `material_usage_items` WRITE;
/*!40000 ALTER TABLE `material_usage_items` DISABLE KEYS */;
INSERT INTO `material_usage_items` VALUES (1,1,2,4.00);
/*!40000 ALTER TABLE `material_usage_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `material_usage_logs`
--

DROP TABLE IF EXISTS `material_usage_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `material_usage_logs` (
  `usage_log_id` int NOT NULL AUTO_INCREMENT,
  `task_id` int NOT NULL,
  `employee_id` int NOT NULL,
  `logged_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`usage_log_id`),
  KEY `task_id` (`task_id`),
  KEY `employee_id` (`employee_id`),
  CONSTRAINT `material_usage_logs_ibfk_1` FOREIGN KEY (`task_id`) REFERENCES `tasks` (`task_id`),
  CONSTRAINT `material_usage_logs_ibfk_2` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`employee_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `material_usage_logs`
--

LOCK TABLES `material_usage_logs` WRITE;
/*!40000 ALTER TABLE `material_usage_logs` DISABLE KEYS */;
INSERT INTO `material_usage_logs` VALUES (1,3,4,'2026-04-20 11:15:00');
/*!40000 ALTER TABLE `material_usage_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `payments`
--

DROP TABLE IF EXISTS `payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `payments` (
  `payment_id` int NOT NULL AUTO_INCREMENT,
  `invoice_id` int NOT NULL,
  `payment_date` date NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `payment_method` varchar(50) DEFAULT NULL,
  `reference_number` varchar(100) DEFAULT NULL,
  `notes` text,
  PRIMARY KEY (`payment_id`),
  KEY `invoice_id` (`invoice_id`),
  CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`invoice_id`) REFERENCES `invoices` (`invoice_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `payments`
--

LOCK TABLES `payments` WRITE;
/*!40000 ALTER TABLE `payments` DISABLE KEYS */;
INSERT INTO `payments` VALUES (1,2,'2026-04-02',120.00,'Credit Card','CC-20260402-001','Payment for invoice INV-1002'),(2,3,'2026-04-22',371.00,'ACH','ACH-77881','Paid in full');
/*!40000 ALTER TABLE `payments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `payroll_periods`
--

DROP TABLE IF EXISTS `payroll_periods`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `payroll_periods` (
  `payroll_period_id` int NOT NULL AUTO_INCREMENT,
  `period_start` date NOT NULL,
  `period_end` date NOT NULL,
  `payment_date` date NOT NULL,
  PRIMARY KEY (`payroll_period_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `payroll_periods`
--

LOCK TABLES `payroll_periods` WRITE;
/*!40000 ALTER TABLE `payroll_periods` DISABLE KEYS */;
INSERT INTO `payroll_periods` VALUES (1,'2026-04-13','2026-04-26','2026-04-30');
/*!40000 ALTER TABLE `payroll_periods` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `payroll_records`
--

DROP TABLE IF EXISTS `payroll_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `payroll_records` (
  `payroll_record_id` int NOT NULL AUTO_INCREMENT,
  `payroll_period_id` int NOT NULL,
  `employee_id` int NOT NULL,
  `regular_hours` decimal(10,2) DEFAULT NULL,
  `overtime_hours` decimal(10,2) DEFAULT NULL,
  `billable_hours` decimal(10,2) DEFAULT NULL,
  `pay_rate` decimal(10,2) DEFAULT NULL,
  `bonus_amount` decimal(10,2) DEFAULT NULL,
  `deduction_amount` decimal(10,2) DEFAULT NULL,
  `gross_pay` decimal(10,2) DEFAULT NULL,
  `net_pay` decimal(10,2) DEFAULT NULL,
  `payment_method` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`payroll_record_id`),
  KEY `payroll_period_id` (`payroll_period_id`),
  KEY `employee_id` (`employee_id`),
  CONSTRAINT `payroll_records_ibfk_1` FOREIGN KEY (`payroll_period_id`) REFERENCES `payroll_periods` (`payroll_period_id`),
  CONSTRAINT `payroll_records_ibfk_2` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`employee_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `payroll_records`
--

LOCK TABLES `payroll_records` WRITE;
/*!40000 ALTER TABLE `payroll_records` DISABLE KEYS */;
INSERT INTO `payroll_records` VALUES (1,1,1,76.00,4.00,60.00,24.50,100.00,50.00,2060.00,2010.00,'Direct Deposit'),(2,1,2,72.00,2.00,55.00,22.00,0.00,40.00,1628.00,1588.00,'Direct Deposit');
/*!40000 ALTER TABLE `payroll_records` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `plant_master`
--

DROP TABLE IF EXISTS `plant_master`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `plant_master` (
  `plant_id` int NOT NULL AUTO_INCREMENT,
  `common_name` varchar(255) NOT NULL,
  `scientific_name` varchar(255) DEFAULT NULL,
  `light_level` varchar(100) DEFAULT NULL,
  `watering_frequency` varchar(100) DEFAULT NULL,
  `temperature_range` varchar(100) DEFAULT NULL,
  `humidity_range` varchar(100) DEFAULT NULL,
  `photo_url` text,
  `notes` text,
  `is_active` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`plant_id`)
) ENGINE=InnoDB AUTO_INCREMENT=43 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `plant_master`
--

LOCK TABLES `plant_master` WRITE;
/*!40000 ALTER TABLE `plant_master` DISABLE KEYS */;
INSERT INTO `plant_master` VALUES (1,'Fiddle Leaf Fig','Ficus lyrata','Bright indirect','Weekly','65-80F','40-60%',NULL,'Rotate weekly for even growth',1),(2,'Snake Plant','Sansevieria trifasciata','Low to bright indirect','Bi-weekly','60-85F','30-50%',NULL,'Avoid overwatering',1),(3,'Snake Plant','Dracaena trifasciata','Low to Bright Indirect','Every 2-3 weeks','60-85°F','Low','','Very hardy, good for beginners',1),(4,'Peace Lily','Spathiphyllum wallisii','Low to Medium','Weekly','65-80°F','Medium','','Flowers indoors, likes moisture',1),(5,'Fiddle Leaf Fig','Ficus lyrata','Bright Indirect','Weekly','65-75°F','Medium','','Sensitive to changes',1),(6,'Spider Plant','Chlorophytum comosum','Bright Indirect','Weekly','60-80°F','Medium','','Produces baby plants',1),(7,'Pothos','Epipremnum aureum','Low to Bright','Every 1-2 weeks','65-85°F','Low','','Very easy to grow',1),(8,'Monstera','Monstera deliciosa','Bright Indirect','Weekly','65-85°F','Medium','','Large split leaves',1),(9,'ZZ Plant','Zamioculcas zamiifolia','Low to Bright','Every 2-3 weeks','60-85°F','Low','','Very drought tolerant',1),(10,'Rubber Plant','Ficus elastica','Bright Indirect','Weekly','60-80°F','Medium','','Glossy leaves',1),(11,'Boston Fern','Nephrolepis exaltata','Indirect','2-3 times weekly','60-75°F','High','','Needs humidity',1),(12,'Aloe Vera','Aloe barbadensis miller','Bright Direct','Every 2-3 weeks','55-80°F','Low','','Succulent, medicinal',1),(13,'Jade Plant','Crassula ovata','Bright Direct','Every 2-3 weeks','60-75°F','Low','','Succulent, long lifespan',1),(14,'Areca Palm','Dypsis lutescens','Bright Indirect','Weekly','65-75°F','Medium','','Adds tropical look',1),(15,'Calathea','Calathea ornata','Low to Medium','Weekly','65-80°F','High','','Sensitive to water quality',1),(16,'Philodendron','Philodendron hederaceum','Low to Bright','Weekly','65-85°F','Medium','','Trailing plant',1),(17,'Chinese Evergreen','Aglaonema','Low to Medium','Weekly','65-80°F','Medium','','Tolerates low light',1),(18,'Dracaena','Dracaena marginata','Low to Bright','Every 1-2 weeks','65-80°F','Low','','Tall indoor plant',1),(19,'Parlor Palm','Chamaedorea elegans','Low to Medium','Weekly','65-80°F','Medium','','Classic indoor palm',1),(20,'Croton','Codiaeum variegatum','Bright Light','Weekly','65-85°F','Medium','','Colorful leaves',1),(21,'Bamboo Palm','Chamaedorea seifrizii','Indirect','Weekly','65-80°F','Medium','','Air purifying',1),(22,'Kentia Palm','Howea forsteriana','Indirect','Weekly','60-80°F','Medium','','Slow growing',1),(23,'Anthurium','Anthurium andraeanum','Bright Indirect','Weekly','65-80°F','High','','Red waxy flowers',1),(24,'Orchid','Phalaenopsis','Bright Indirect','Weekly','65-80°F','High','','Needs careful watering',1),(25,'Lavender','Lavandula','Full Sun','Weekly','60-85°F','Low','','Fragrant herb',1),(26,'Rosemary','Rosmarinus officinalis','Full Sun','Weekly','60-80°F','Low','','Herb plant',1),(27,'Mint','Mentha','Partial Sun','2-3 times weekly','60-75°F','Medium','','Fast growing herb',1),(28,'Basil','Ocimum basilicum','Full Sun','Weekly','65-85°F','Medium','','Common herb',1),(29,'Thyme','Thymus vulgaris','Full Sun','Weekly','60-80°F','Low','','Drought tolerant herb',1),(30,'Cactus','Various','Full Sun','Every 3-4 weeks','60-90°F','Low','','Minimal water needed',1),(31,'Succulent Mix','Various','Bright Light','Every 2-3 weeks','60-85°F','Low','','Assorted succulents',1),(32,'Air Plant','Tillandsia','Indirect','Mist weekly','60-80°F','Medium','','No soil required',1),(33,'Bird of Paradise','Strelitzia reginae','Bright Light','Weekly','65-85°F','Medium','','Large tropical plant',1),(34,'Banana Plant','Musa','Bright Light','Weekly','65-85°F','High','','Large leaves',1),(35,'Yucca','Yucca elephantipes','Bright Light','Every 2 weeks','60-85°F','Low','','Drought tolerant',1),(36,'Dieffenbachia','Dieffenbachia seguine','Indirect','Weekly','65-80°F','Medium','','Large patterned leaves',1),(37,'Oxalis','Oxalis triangularis','Bright Indirect','Weekly','60-75°F','Medium','','Purple leaves',1),(38,'Coleus','Plectranthus scutellarioides','Bright Indirect','Weekly','65-80°F','Medium','','Colorful foliage',1),(39,'Begonia','Begonia rex','Indirect','Weekly','65-75°F','High','','Decorative leaves',1),(40,'Gardenia','Gardenia jasminoides','Bright Light','Weekly','65-75°F','High','','Fragrant flowers',1),(41,'Hibiscus','Hibiscus rosa-sinensis','Full Sun','Weekly','65-85°F','Medium','','Large flowers',1),(42,'Geranium','Pelargonium','Full Sun','Weekly','60-80°F','Low','','Outdoor/indoor plant',1);
/*!40000 ALTER TABLE `plant_master` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `service_requests`
--

DROP TABLE IF EXISTS `service_requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `service_requests` (
  `service_request_id` int NOT NULL AUTO_INCREMENT,
  `client_id` int NOT NULL,
  `location_id` int NOT NULL,
  `service_id` int NOT NULL,
  `requested_date` date DEFAULT NULL,
  `requested_notes` text,
  `status` varchar(50) DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `approved_by` int DEFAULT NULL,
  PRIMARY KEY (`service_request_id`),
  KEY `client_id` (`client_id`),
  KEY `location_id` (`location_id`),
  KEY `service_id` (`service_id`),
  KEY `approved_by` (`approved_by`),
  CONSTRAINT `service_requests_ibfk_1` FOREIGN KEY (`client_id`) REFERENCES `clients` (`client_id`),
  CONSTRAINT `service_requests_ibfk_2` FOREIGN KEY (`location_id`) REFERENCES `client_locations` (`location_id`),
  CONSTRAINT `service_requests_ibfk_3` FOREIGN KEY (`service_id`) REFERENCES `services` (`service_id`),
  CONSTRAINT `service_requests_ibfk_4` FOREIGN KEY (`approved_by`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `service_requests`
--

LOCK TABLES `service_requests` WRITE;
/*!40000 ALTER TABLE `service_requests` DISABLE KEYS */;
INSERT INTO `service_requests` VALUES (1,1,1,1,'2026-04-16','Front desk plants are drying out quickly.','Pending','2026-04-14 09:15:00',NULL),(2,2,3,2,'2026-04-17','Leaves are yellowing near the storefront entrance.','Pending','2026-04-14 10:45:00',NULL),(3,1,2,2,'2026-04-16','Monthly warehouse plant maintenance.','Approved','2026-04-10 08:00:00',1),(4,2,3,3,'2026-04-18','Need installation before weekend event.','Rejected','2026-04-09 11:30:00',1),(5,1,1,1,'2026-04-17','Weekly watering route for lobby planters.','Approved','2026-04-11 07:30:00',1),(6,2,3,1,'2026-04-16','Lunch area watering and cleanup.','Approved','2026-04-12 08:20:00',1),(7,3,4,5,'2026-04-21','Urgent stress signs in lobby ficus trees.','Pending','2026-04-15 08:45:00',NULL),(8,4,6,6,'2026-04-22','Requesting soil refresh for desk plants.','Pending','2026-04-15 09:20:00',NULL),(9,3,5,2,'2026-04-23','Quarterly health inspection for annex plants.','Approved','2026-04-13 14:10:00',2),(10,4,6,1,'2026-04-21','Watering for newly occupied coworking suites.','Approved','2026-04-13 15:00:00',2),(11,3,4,3,'2026-04-24','Install display plants before ribbon cutting.','Rejected','2026-04-12 11:00:00',2),(12,1,2,5,'2026-04-22','Emergency call for drooping atrium plants.','Pending','2026-04-15 10:30:00',NULL);
/*!40000 ALTER TABLE `service_requests` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `services`
--

DROP TABLE IF EXISTS `services`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `services` (
  `service_id` int NOT NULL AUTO_INCREMENT,
  `service_name` varchar(255) NOT NULL,
  `description` text,
  `base_price` decimal(10,2) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`service_id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `services`
--

LOCK TABLES `services` WRITE;
/*!40000 ALTER TABLE `services` DISABLE KEYS */;
INSERT INTO `services` VALUES (1,'Watering Plants','Routine watering and moisture checks',60.00,1),(2,'Indoor Plant Health Check','Inspect plant health and treat common issues',120.00,1),(3,'Office Plant Installation','Install and stage new office plants',350.00,1),(4,'Seasonal Decor Refresh','Rotate seasonal plant decor package',250.00,0),(5,'Emergency Plant Triage','Urgent same-day diagnosis and stabilization',180.00,1),(6,'Soil and Pot Refresh','Refresh soil blend and repot where needed',95.00,1);
/*!40000 ALTER TABLE `services` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `suppliers`
--

DROP TABLE IF EXISTS `suppliers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `suppliers` (
  `supplier_id` int NOT NULL AUTO_INCREMENT,
  `supplier_name` varchar(255) NOT NULL,
  `phone` varchar(30) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `address_id` int DEFAULT NULL,
  `total_orders` int DEFAULT '0',
  `last_order_date` date DEFAULT NULL,
  `status` enum('Ordered','Shipped','Delivered') DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`supplier_id`),
  KEY `address_id` (`address_id`),
  CONSTRAINT `suppliers_ibfk_1` FOREIGN KEY (`address_id`) REFERENCES `addresses` (`address_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `suppliers`
--

LOCK TABLES `suppliers` WRITE;
/*!40000 ALTER TABLE `suppliers` DISABLE KEYS */;
INSERT INTO `suppliers` VALUES (1,'GreenGrow Supply','555-200-0001','orders@greengrow.test',9,12,'2026-04-01','Delivered',1),(2,'Urban Soil Partners','555-200-0002','sales@urbansoil.test',10,7,'2026-03-28','Shipped',1);
/*!40000 ALTER TABLE `suppliers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `task_materials`
--

DROP TABLE IF EXISTS `task_materials`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `task_materials` (
  `task_material_id` int NOT NULL AUTO_INCREMENT,
  `task_id` int NOT NULL,
  `item_id` int NOT NULL,
  `required_quantity` decimal(10,2) DEFAULT NULL,
  PRIMARY KEY (`task_material_id`),
  KEY `task_id` (`task_id`),
  KEY `item_id` (`item_id`),
  CONSTRAINT `task_materials_ibfk_1` FOREIGN KEY (`task_id`) REFERENCES `tasks` (`task_id`),
  CONSTRAINT `task_materials_ibfk_2` FOREIGN KEY (`item_id`) REFERENCES `inventory_items` (`item_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `task_materials`
--

LOCK TABLES `task_materials` WRITE;
/*!40000 ALTER TABLE `task_materials` DISABLE KEYS */;
INSERT INTO `task_materials` VALUES (1,3,2,4.00),(2,3,3,4.00),(3,2,1,1.00);
/*!40000 ALTER TABLE `task_materials` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tasks`
--

DROP TABLE IF EXISTS `tasks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tasks` (
  `task_id` int NOT NULL AUTO_INCREMENT,
  `job_order_id` int NOT NULL,
  `assigned_employee_id` int DEFAULT NULL,
  `task_name` varchar(255) NOT NULL,
  `description` text,
  `status` varchar(50) DEFAULT NULL,
  `completed_at` datetime DEFAULT NULL,
  PRIMARY KEY (`task_id`),
  KEY `job_order_id` (`job_order_id`),
  KEY `assigned_employee_id` (`assigned_employee_id`),
  CONSTRAINT `tasks_ibfk_1` FOREIGN KEY (`job_order_id`) REFERENCES `job_orders` (`job_order_id`),
  CONSTRAINT `tasks_ibfk_2` FOREIGN KEY (`assigned_employee_id`) REFERENCES `employees` (`employee_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tasks`
--

LOCK TABLES `tasks` WRITE;
/*!40000 ALTER TABLE `tasks` DISABLE KEYS */;
INSERT INTO `tasks` VALUES (1,7,4,'Inspect foliage and roots','Check for pests, root rot, and nutrient stress.','Scheduled',NULL),(2,8,5,'Water and trim display plants','Standard watering plus light pruning.','Scheduled',NULL),(3,12,4,'Install lobby display set','Position planters and verify irrigation trays.','Completed','2026-04-20 11:10:00');
/*!40000 ALTER TABLE `tasks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `user_id` int NOT NULL AUTO_INCREMENT,
  `role` enum('Management','Staff','Client') NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `first_name` varchar(100) NOT NULL,
  `last_name` varchar(100) NOT NULL,
  `phone` varchar(30) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'Management','admin@test.com','scrypt:32768:8:1$6rMePe6Pg4whHb8b$3364b9f8dfbd6ddfda885f94e44a750f26ef4b7182c7589ca0ebbf8c7adc643d41f48a2a148e34f62a8dc3485d1046f5ccb7c65b94595e9d4e57df6f58c97064','Test','Admin','555-123-4567',1,'2026-04-15 23:01:34'),(2,'Management','manager@test.com','scrypt:32768:8:1$liE9UDZJXxfXB9Nm$a768d6047ea608148f634c840a6aa461a6607832e334eb18eb8ffafdfa2c447dac5756e9a31d33904709d3d98b17e1f802dca20a0c9ecf616b9e419d1c02dc6b','Maya','Manager','555-111-1000',1,'2026-04-15 23:01:34'),(3,'Staff','alice.staff@test.com','scrypt:32768:8:1$liE9UDZJXxfXB9Nm$a768d6047ea608148f634c840a6aa461a6607832e334eb18eb8ffafdfa2c447dac5756e9a31d33904709d3d98b17e1f802dca20a0c9ecf616b9e419d1c02dc6b','Alice','Green','555-111-2001',1,'2026-04-15 23:01:34'),(4,'Staff','bob.staff@test.com','scrypt:32768:8:1$liE9UDZJXxfXB9Nm$a768d6047ea608148f634c840a6aa461a6607832e334eb18eb8ffafdfa2c447dac5756e9a31d33904709d3d98b17e1f802dca20a0c9ecf616b9e419d1c02dc6b','Bob','Rivera','555-111-2002',1,'2026-04-15 23:01:34'),(5,'Staff','carla.staff@test.com','scrypt:32768:8:1$liE9UDZJXxfXB9Nm$a768d6047ea608148f634c840a6aa461a6607832e334eb18eb8ffafdfa2c447dac5756e9a31d33904709d3d98b17e1f802dca20a0c9ecf616b9e419d1c02dc6b','Carla','Stone','555-111-2003',0,'2026-04-15 23:01:34'),(6,'Client','brendan.client@test.com','scrypt:32768:8:1$liE9UDZJXxfXB9Nm$a768d6047ea608148f634c840a6aa461a6607832e334eb18eb8ffafdfa2c447dac5756e9a31d33904709d3d98b17e1f802dca20a0c9ecf616b9e419d1c02dc6b','Brendan','User','555-111-3001',1,'2026-04-15 23:01:34'),(7,'Client','ivy.client@test.com','scrypt:32768:8:1$liE9UDZJXxfXB9Nm$a768d6047ea608148f634c840a6aa461a6607832e334eb18eb8ffafdfa2c447dac5756e9a31d33904709d3d98b17e1f802dca20a0c9ecf616b9e419d1c02dc6b','Ivy','Client','555-111-3002',1,'2026-04-15 23:01:34'),(8,'Staff','dylan.staff@test.com','scrypt:32768:8:1$liE9UDZJXxfXB9Nm$a768d6047ea608148f634c840a6aa461a6607832e334eb18eb8ffafdfa2c447dac5756e9a31d33904709d3d98b17e1f802dca20a0c9ecf616b9e419d1c02dc6b','Dylan','Frost','555-111-2004',1,'2026-04-15 23:01:34'),(9,'Staff','emma.staff@test.com','scrypt:32768:8:1$liE9UDZJXxfXB9Nm$a768d6047ea608148f634c840a6aa461a6607832e334eb18eb8ffafdfa2c447dac5756e9a31d33904709d3d98b17e1f802dca20a0c9ecf616b9e419d1c02dc6b','Emma','Lane','555-111-2005',1,'2026-04-15 23:01:34'),(10,'Client','nora.client@test.com','scrypt:32768:8:1$liE9UDZJXxfXB9Nm$a768d6047ea608148f634c840a6aa461a6607832e334eb18eb8ffafdfa2c447dac5756e9a31d33904709d3d98b17e1f802dca20a0c9ecf616b9e419d1c02dc6b','Nora','Mills','555-111-3003',1,'2026-04-15 23:01:34'),(11,'Client','oscar.client@test.com','scrypt:32768:8:1$liE9UDZJXxfXB9Nm$a768d6047ea608148f634c840a6aa461a6607832e334eb18eb8ffafdfa2c447dac5756e9a31d33904709d3d98b17e1f802dca20a0c9ecf616b9e419d1c02dc6b','Oscar','Reed','555-111-3004',1,'2026-04-15 23:01:34');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-04-15 23:56:56
