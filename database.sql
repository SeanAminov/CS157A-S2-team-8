-- MySQL dump 10.13  Distrib 8.0.40, for macos14 (x86_64)
--
-- Host: localhost    Database: FMP
-- ------------------------------------------------------
-- Server version	8.0.40

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `Courses`
--

DROP TABLE IF EXISTS `Courses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Courses` (
  `course_id` int NOT NULL AUTO_INCREMENT,
  `course_code` varchar(45) NOT NULL,
  `course_name` varchar(90) NOT NULL,
  `credits` varchar(45) NOT NULL,
  `department_id` int NOT NULL,
  PRIMARY KEY (`course_id`),
  UNIQUE KEY `uq_courses_course_code` (`course_code`),
  KEY `fk_course_department_idx` (`department_id`),
  CONSTRAINT `fk_course_department` FOREIGN KEY (`department_id`) REFERENCES `Departments` (`department_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Courses`
--

LOCK TABLES `Courses` WRITE;
/*!40000 ALTER TABLE `Courses` DISABLE KEYS */;
INSERT INTO `Courses` VALUES (1,'CS101','Intro to Programming','3',1),(2,'CS201','Data Structures','4',1),(3,'SE101','Software Design','3',2),(4,'DS201','Data Analysis','4',3),(5,'EE101','Circuits I','3',4),(6,'ME101','Statics','3',5),(7,'BUS101','Intro to Business','3',6),(8,'ECON101','Microeconomics','3',7),(9,'MATH201','Linear Algebra','4',8),(10,'PHYS101','General Physics','4',9);
/*!40000 ALTER TABLE `Courses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Departments`
--

DROP TABLE IF EXISTS `Departments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Departments` (
  `department_id` int NOT NULL,
  `department_name` varchar(45) NOT NULL,
  PRIMARY KEY (`department_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Departments`
--

LOCK TABLES `Departments` WRITE;
/*!40000 ALTER TABLE `Departments` DISABLE KEYS */;
INSERT INTO `Departments` VALUES (1,'Computer Science'),(2,'Software Engineering'),(3,'Data Science'),(4,'Electrical Engineering'),(5,'Mechanical Engineering'),(6,'Business'),(7,'Economics'),(8,'Mathematics'),(9,'Physics'),(10,'Biology');
/*!40000 ALTER TABLE `Departments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `DesiredCourses`
--

DROP TABLE IF EXISTS `DesiredCourses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `DesiredCourses` (
  `user_id` int NOT NULL,
  `course_id` int NOT NULL,
  PRIMARY KEY (`user_id`,`course_id`),
  KEY `fk_desired_course_idx` (`course_id`),
  CONSTRAINT `fk_desired_course` FOREIGN KEY (`course_id`) REFERENCES `Courses` (`course_id`),
  CONSTRAINT `fk_desired_user` FOREIGN KEY (`user_id`) REFERENCES `Users` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `DesiredCourses`
--

LOCK TABLES `DesiredCourses` WRITE;
/*!40000 ALTER TABLE `DesiredCourses` DISABLE KEYS */;
INSERT INTO `DesiredCourses` VALUES (3,1),(2,2),(5,3),(1,4),(4,5),(6,6),(10,7),(7,8),(8,9),(9,10);
/*!40000 ALTER TABLE `DesiredCourses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `FilterPreferences`
--

DROP TABLE IF EXISTS `FilterPreferences`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `FilterPreferences` (
  `filter_id` int NOT NULL,
  `max_credits` varchar(45) DEFAULT NULL,
  `preferred_format` varchar(45) DEFAULT NULL,
  `min_rating` varchar(45) DEFAULT NULL,
  `user_id` int NOT NULL,
  PRIMARY KEY (`filter_id`),
  KEY `user_id_idx` (`user_id`),
  CONSTRAINT `fk_filterpreferences_user` FOREIGN KEY (`user_id`) REFERENCES `Users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `FilterPreferences`
--

LOCK TABLES `FilterPreferences` WRITE;
/*!40000 ALTER TABLE `FilterPreferences` DISABLE KEYS */;
INSERT INTO `FilterPreferences` VALUES (1,'18','In-Person','3.5',1),(2,'15','Online','4.0',2),(3,'12','Hybrid','3.0',3),(4,'18','In-Person','3.8',4),(5,'16','Online','3.2',5),(6,'14','Hybrid','3.6',6),(7,'20','In-Person','4.2',7),(8,'15','Online','3.7',8),(9,'17','Hybrid','3.3',9),(10,'13','In-Person','3.9',10);
/*!40000 ALTER TABLE `FilterPreferences` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `MajorRequirements`
--

DROP TABLE IF EXISTS `MajorRequirements`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `MajorRequirements` (
  `major_id` int NOT NULL,
  `course_id` int NOT NULL,
  PRIMARY KEY (`major_id`,`course_id`),
  KEY `fk_majorreq_course_idx` (`course_id`),
  CONSTRAINT `fk_majorreq_course` FOREIGN KEY (`course_id`) REFERENCES `Courses` (`course_id`),
  CONSTRAINT `fk_majorreq_major` FOREIGN KEY (`major_id`) REFERENCES `Majors` (`major_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `MajorRequirements`
--

LOCK TABLES `MajorRequirements` WRITE;
/*!40000 ALTER TABLE `MajorRequirements` DISABLE KEYS */;
INSERT INTO `MajorRequirements` VALUES (1,1),(1,2),(2,3),(3,4),(4,5),(5,6),(6,7),(7,8),(8,9),(9,10);
/*!40000 ALTER TABLE `MajorRequirements` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Majors`
--

DROP TABLE IF EXISTS `Majors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Majors` (
  `major_id` int NOT NULL,
  `major_name` varchar(45) NOT NULL,
  PRIMARY KEY (`major_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Majors`
--

LOCK TABLES `Majors` WRITE;
/*!40000 ALTER TABLE `Majors` DISABLE KEYS */;
INSERT INTO `Majors` VALUES (1,'Computer Science'),(2,'Software Engineering'),(3,'Data Science'),(4,'Electrical Engineering'),(5,'Mechanical Engineering'),(6,'Business Administration'),(7,'Economics'),(8,'Mathematics'),(9,'Physics'),(10,'Biology');
/*!40000 ALTER TABLE `Majors` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Professors`
--

DROP TABLE IF EXISTS `Professors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Professors` (
  `professor_id` int NOT NULL AUTO_INCREMENT,
  `first_name` varchar(45) NOT NULL,
  `last_name` varchar(45) NOT NULL,
  `rating` decimal(2,1) DEFAULT NULL,
  `department_id` int NOT NULL,
  PRIMARY KEY (`professor_id`),
  UNIQUE KEY `uq_professor_name` (`first_name`, `last_name`),
  KEY `fk_professor_department_idx` (`department_id`),
  CONSTRAINT `fk_professor_department` FOREIGN KEY (`department_id`) REFERENCES `Departments` (`department_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Professors`
--

LOCK TABLES `Professors` WRITE;
/*!40000 ALTER TABLE `Professors` DISABLE KEYS */;
INSERT INTO `Professors` VALUES (1,'Alan','Turing',5,1),(2,'Grace','Hopper',5,1),(3,'Ada','Lovelace',5,2),(4,'Andrew','Ng',5,3),(5,'Nikola','Tesla',5,4),(6,'Elon','Musk',4,5),(7,'Warren','Buffett',5,6),(8,'Adam','Smith',4,7),(9,'Carl','Gauss',5,8),(10,'Albert','Einstein',5,9);
/*!40000 ALTER TABLE `Professors` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ScheduleCourses`
--

DROP TABLE IF EXISTS `ScheduleCourses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ScheduleCourses` (
  `schedule_id` int NOT NULL,
  `section_id` int NOT NULL,
  PRIMARY KEY (`schedule_id`,`section_id`),
  KEY `fk_schedule_course_idx` (`section_id`),
  CONSTRAINT `fk_schedule_course` FOREIGN KEY (`section_id`) REFERENCES `Sections` (`section_id`),
  CONSTRAINT `fk_schedule_schedule` FOREIGN KEY (`schedule_id`) REFERENCES `Schedules` (`schedule_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ScheduleCourses`
--

LOCK TABLES `ScheduleCourses` WRITE;
/*!40000 ALTER TABLE `ScheduleCourses` DISABLE KEYS */;
INSERT INTO `ScheduleCourses` VALUES (1,1),(1,2),(2,3),(2,4),(3,5),(4,6),(5,7),(6,8),(7,9),(8,10);
/*!40000 ALTER TABLE `ScheduleCourses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Schedules`
--

DROP TABLE IF EXISTS `Schedules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Schedules` (
  `schedule_id` int NOT NULL,
  `schedule_name` varchar(45) NOT NULL,
  `term` varchar(45) NOT NULL,
  `date_created` varchar(45) NOT NULL,
  `user_id` int NOT NULL,
  PRIMARY KEY (`schedule_id`),
  KEY `fk_schedule_user_idx` (`user_id`),
  CONSTRAINT `fk_schedule_user` FOREIGN KEY (`user_id`) REFERENCES `Users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Schedules`
--

LOCK TABLES `Schedules` WRITE;
/*!40000 ALTER TABLE `Schedules` DISABLE KEYS */;
INSERT INTO `Schedules` VALUES (1,'Spring Plan A','Spring 2025','2025-01-10',1),(2,'Spring Plan B','Spring 2025','2025-01-12',2),(3,'Fall Backup','Fall 2025','2025-02-01',3),(4,'Main Schedule','Spring 2025','2025-01-15',4),(5,'Light Load','Spring 2025','2025-01-20',5),(6,'Heavy Load','Fall 2025','2025-02-10',6),(7,'Alt Schedule','Spring 2025','2025-01-18',7),(8,'Preferred','Fall 2025','2025-02-05',8),(9,'Draft Plan','Spring 2025','2025-01-25',9),(10,'Final Plan','Spring 2025','2025-01-30',10);
/*!40000 ALTER TABLE `Schedules` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Sections`
--

DROP TABLE IF EXISTS `Sections`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Sections` (
  `section_id` int NOT NULL AUTO_INCREMENT,
  `term` varchar(45) NOT NULL,
  `days` varchar(45) NOT NULL,
  `start_time` varchar(45) NOT NULL,
  `end_time` varchar(45) NOT NULL,
  `location` varchar(45) NOT NULL,
  `format` varchar(45) NOT NULL,
  `professor_id` int NOT NULL,
  `course_id` int NOT NULL,
  PRIMARY KEY (`section_id`),
  UNIQUE KEY `uq_section` (`course_id`, `term`, `days`, `start_time`, `location`),
  KEY `fk_section_course_idx` (`course_id`),
  KEY `fk_section_professor_idx` (`professor_id`),
  CONSTRAINT `fk_section_course` FOREIGN KEY (`course_id`) REFERENCES `Courses` (`course_id`),
  CONSTRAINT `fk_section_professor` FOREIGN KEY (`professor_id`) REFERENCES `Professors` (`professor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Sections`
--

LOCK TABLES `Sections` WRITE;
/*!40000 ALTER TABLE `Sections` DISABLE KEYS */;
INSERT INTO `Sections` VALUES (1,'Spring 2025','MWF','09:00','10:00','Room 101','In-Person',1,1),(2,'Spring 2025','TTh','10:00','11:30','Room 102','In-Person',2,2),(3,'Spring 2025','MWF','11:00','12:00','Room 201','Hybrid',3,3),(4,'Spring 2025','TTh','13:00','14:30','Room 202','Online',4,4),(5,'Spring 2025','MWF','08:00','09:00','Lab 1','In-Person',5,5),(6,'Spring 2025','TTh','14:00','15:30','Lab 2','Hybrid',6,6),(7,'Spring 2025','MWF','12:00','13:00','Room 301','Online',7,7),(8,'Spring 2025','TTh','09:00','10:30','Room 302','In-Person',8,8),(9,'Spring 2025','MWF','15:00','16:00','Room 401','Hybrid',9,9),(10,'Spring 2025','TTh','11:00','12:30','Room 402','In-Person',10,10);
/*!40000 ALTER TABLE `Sections` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `TakenCourses`
--

DROP TABLE IF EXISTS `TakenCourses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `TakenCourses` (
  `transcript_id` int NOT NULL,
  `course_id` int NOT NULL,
  PRIMARY KEY (`transcript_id`,`course_id`),
  KEY `fk_taken_course_idx` (`course_id`),
  CONSTRAINT `fk_taken_course` FOREIGN KEY (`course_id`) REFERENCES `Courses` (`course_id`),
  CONSTRAINT `fk_taken_transcript` FOREIGN KEY (`transcript_id`) REFERENCES `Transcripts` (`transcript_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `TakenCourses`
--

LOCK TABLES `TakenCourses` WRITE;
/*!40000 ALTER TABLE `TakenCourses` DISABLE KEYS */;
INSERT INTO `TakenCourses` VALUES (1,1),(4,1),(1,2),(2,3),(6,3),(3,4),(7,4),(5,5),(8,6),(2,7);
/*!40000 ALTER TABLE `TakenCourses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `TimeBlocks`
--

DROP TABLE IF EXISTS `TimeBlocks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `TimeBlocks` (
  `block_id` int NOT NULL,
  `start_time` varchar(45) NOT NULL,
  `end_time` varchar(45) NOT NULL,
  `day` varchar(45) NOT NULL,
  `user_id` int NOT NULL,
  PRIMARY KEY (`block_id`),
  KEY `user_id_idx` (`user_id`),
  CONSTRAINT `fk_timeblocks_user` FOREIGN KEY (`user_id`) REFERENCES `Users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `TimeBlocks`
--

LOCK TABLES `TimeBlocks` WRITE;
/*!40000 ALTER TABLE `TimeBlocks` DISABLE KEYS */;
INSERT INTO `TimeBlocks` VALUES (1,'08:00','10:00','Monday',1),(2,'10:00','12:00','Tuesday',2),(3,'13:00','15:00','Wednesday',3),(4,'09:00','11:00','Thursday',4),(5,'14:00','16:00','Friday',5),(6,'08:00','09:30','Monday',6),(7,'11:00','13:00','Tuesday',7),(8,'15:00','17:00','Wednesday',8),(9,'10:00','12:00','Thursday',9),(10,'13:00','15:00','Friday',10);
/*!40000 ALTER TABLE `TimeBlocks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Transcripts`
--

DROP TABLE IF EXISTS `Transcripts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Transcripts` (
  `transcript_id` int NOT NULL,
  `upload_date` varchar(45) NOT NULL,
  `total_credits` varchar(45) NOT NULL,
  `current_major` varchar(45) NOT NULL,
  `user_id` int NOT NULL,
  PRIMARY KEY (`transcript_id`),
  KEY `fk_transcript_user_idx` (`user_id`),
  CONSTRAINT `fk_transcript_user` FOREIGN KEY (`user_id`) REFERENCES `Users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Transcripts`
--

LOCK TABLES `Transcripts` WRITE;
/*!40000 ALTER TABLE `Transcripts` DISABLE KEYS */;
INSERT INTO `Transcripts` VALUES (1,'2025-01-05','45','Computer Science',1),(2,'2025-01-06','60','Software Engineering',2),(3,'2025-01-07','30','Data Science',3),(4,'2025-01-08','75','Computer Science',4),(5,'2025-01-09','50','Electrical Engineering',5),(6,'2025-01-10','40','Software Engineering',6),(7,'2025-01-11','90','Data Science',7),(8,'2025-01-12','20','Mechanical Engineering',8),(9,'2025-01-13','55','Electrical Engineering',9),(10,'2025-01-14','65','Computer Science',10);
/*!40000 ALTER TABLE `Transcripts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Users`
--

DROP TABLE IF EXISTS `Users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Users` (
  `user_id` int NOT NULL AUTO_INCREMENT,
  `role` varchar(45) NOT NULL,
  `email` varchar(45) NOT NULL,
  `password_hash` varchar(60) NOT NULL,
  `date_created` varchar(45) NOT NULL,
  `major_id` int DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  KEY `fk_user_major_idx` (`major_id`),
  CONSTRAINT `fk_user_major` FOREIGN KEY (`major_id`) REFERENCES `Majors` (`major_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Users`
--

LOCK TABLES `Users` WRITE;
/*!40000 ALTER TABLE `Users` DISABLE KEYS */;
INSERT INTO `Users` VALUES (1,'student','alice.johnson@example.com','hash_abc123','2024-01-10',1),(2,'student','bob.smith@example.com','hash_def456','2024-02-15',2),(3,'student','carol.lee@example.com','hash_ghi789','2024-03-05',3),(4,'student','david.kim@example.com','hash_jkl012','2024-01-22',1),(5,'student','emma.wilson@example.com','hash_mno345','2024-04-18',4),(6,'student','frank.miller@example.com','hash_pqr678','2024-02-28',2),(7,'admin','grace.taylor@example.com','hash_stu901','2024-01-05',3),(8,'student','henry.anderson@example.com','hash_vwx234','2024-03-12',5),(9,'student','isabella.thomas@example.com','hash_yza567','2024-04-01',4),(10,'student','jack.white@example.com','hash_bcd890','2024-02-10',1);
/*!40000 ALTER TABLE `Users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-03-17 10:28:15
