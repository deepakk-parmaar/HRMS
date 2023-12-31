-- Create tables
CREATE TABLE IF NOT EXISTS positions (
  position_id INT NOT NULL AUTO_INCREMENT,
  title VARCHAR(255) NOT NULL,
  description VARCHAR(255) NOT NULL,
  is_vacant BOOLEAN NOT NULL,
  PRIMARY KEY (position_id)
);

CREATE TABLE IF NOT EXISTS departments (
  department_id INT NOT NULL AUTO_INCREMENT,
  department_name VARCHAR(255) NOT NULL,
  location VARCHAR(255) NOT NULL,
  PRIMARY KEY (department_id)
);

CREATE TABLE IF NOT EXISTS employees (
  employee_id INT NOT NULL AUTO_INCREMENT,
  first_name VARCHAR(255) NOT NULL,
  last_name VARCHAR(255) NOT NULL,
  date_of_birth DATE NOT NULL,
  gender VARCHAR(10) NOT NULL,
  email VARCHAR(255) NOT NULL,
  hire_date DATE NOT NULL,
  position_id INT,
  department_id INT,
  supervisor_id INT,
  PRIMARY KEY (employee_id),
  FOREIGN KEY (position_id) REFERENCES positions(position_id) ON DELETE SET NULL,
  FOREIGN KEY (department_id) REFERENCES departments(department_id) ON DELETE SET NULL,
  FOREIGN KEY (supervisor_id) REFERENCES employees(employee_id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS applications (
  application_id INT NOT NULL AUTO_INCREMENT,
  position_id INT ,
  employee_id INT ,
  status VARCHAR(255) NOT NULL,
  PRIMARY KEY (application_id),
  FOREIGN KEY (position_id) REFERENCES positions(position_id) ON DELETE SET NULL,
  FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS employee_leaves (
  leave_id INT NOT NULL AUTO_INCREMENT,
  attendance VARCHAR(255) NOT NULL,
  employee_id INT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  PRIMARY KEY (leave_id),
  FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS performance_reviews (
  review_id INT NOT NULL AUTO_INCREMENT,
  review_date DATE NOT NULL,
  employee_id INT NOT NULL,
  rating INT NOT NULL,
  comments VARCHAR(255) NOT NULL,
  PRIMARY KEY (review_id),
  FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS attendance (
  employee_id INT NOT NULL,
  date DATE NOT NULL,
  is_present BOOLEAN NOT NULL,
  PRIMARY KEY (employee_id, date),
  FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE
);

-- Trigger
DELIMITER //
CREATE TRIGGER after_employee_insert
AFTER INSERT ON employees
FOR EACH ROW
BEGIN
  UPDATE positions
  SET is_vacant = 0
  WHERE position_id = NEW.position_id;
END;
//
DELIMITER ;

-- Procedure
DELIMITER //
CREATE PROCEDURE GetEmployeesByDepartment(IN dept_name VARCHAR(255))
BEGIN
    SELECT e.first_name, e.last_name, d.department_name
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
    WHERE d.department_name = dept_name;
END;
//
DELIMITER ;

-- Function
DELIMITER //
CREATE FUNCTION avgDepartmentRating(dept_id Int) RETURNS DECIMAL
BEGIN
  DECLARE avg_rating DECIMAL;
  SELECT AVG(pr.rating) INTO avg_rating
  FROM performance_reviews pr
  JOIN employees e ON pr.employee_id = e.employee_id
  WHERE e.department_id = dept_id;
  RETURN avg_rating;
END;
//
DELIMITER ;

DELIMITER //
CREATE FUNCTION IF NOT EXISTS CalculateAge(dob DATE)
     RETURNS INT
     BEGIN
         RETURN YEAR(CURDATE()) - YEAR(dob) - (RIGHT(CURDATE(), 5) < RIGHT(dob, 5));
     END;
//
DELIMITER ;

-- Insert data into tables

INSERT INTO positions (title, description, is_vacant) VALUES 
('Software Engineer', 'Develops software applications', TRUE),
('Marketing Manager', 'Leads the marketing team', TRUE),
('Data Analyst', 'Analyzes data and generates reports', TRUE),
('HR Coordinator', 'Manages human resources tasks', TRUE),
('Sales Representative', 'Handles sales and client interactions', TRUE);

INSERT INTO departments (department_name, location) VALUES 
('Engineering', 'New York'),
('Marketing', 'Los Angeles'),
('Analytics', 'Chicago'),
('Human Resources', 'Houston'),
('Sales', 'San Francisco');

INSERT INTO employees (first_name, last_name, date_of_birth, gender, email, hire_date, position_id, department_id, supervisor_id) VALUES 
('John', 'Doe', '1990-05-15', 'Male', 'john@example.com', '2020-10-20', 1, 1, NULL),
('Jane', 'Smith', '1985-12-28', 'Female', 'jane@example.com', '2018-07-12', 2, 2, 1),
('Michael', 'Johnson', '1992-09-30', 'Male', 'michael@example.com', '2021-03-05', 3, 3, 2),
('Emily', 'Williams', '1988-07-19', 'Female', 'emily@example.com', '2019-11-14', 4, 4, 3),
('David', 'Brown', '1995-02-10', 'Male', 'david@example.com', '2022-05-08', 5, 5, 4);

INSERT INTO applications (position_id, employee_id, status) VALUES 
(1, 2, 'Pending'),
(3, 4, 'Approved'),
(2, 1, 'Rejected'),
(4, 3, 'Pending'),
(5, 5, 'Under Review');

INSERT INTO employee_leaves (attendance, employee_id, start_date, end_date) VALUES 
('Vacation', 1, '2023-01-10', '2023-01-15'),
('Sick Leave', 3, '2023-04-05', '2023-04-07'),
('Maternity Leave', 4, '2023-06-20', '2023-09-20'),
('Personal Leave', 2, '2023-08-10', '2023-08-12'),
('Vacation', 5, '2023-11-05', '2023-11-10');

INSERT INTO performance_reviews (review_date, employee_id, rating, comments) VALUES 
('2023-03-15', 1, 4, 'Excellent performance this quarter'),
('2023-07-22', 2, 3, 'Meeting expectations'),
('2023-09-10', 3, 5, 'Outstanding work in data analysis'),
('2023-10-30', 4, 2, 'Room for improvement in HR tasks'),
('2023-11-05', 5, 4, 'Consistently good sales performance');

INSERT INTO attendance (employee_id, date, is_present) VALUES 
(1, '2023-11-01', TRUE),
(2, '2023-11-01', TRUE),
(3, '2023-11-01', FALSE),
(4, '2023-11-01', TRUE),
(5, '2023-11-01', TRUE);


--Nested Queries
-- Show positions where there are no applicants
SELECT * FROM positions
WHERE position_id NOT IN (SELECT position_id FROM applications);
//Find the details of employees who applied for a position marked as vacant:
SELECT e.first_name, e.last_name, p.title
FROM employees e
JOIN applications a ON e.employee_id = a.employee_id
JOIN positions p ON a.position_id = p.position_id
WHERE p.is_vacant = TRUE;

--Correlated Queries
--List employees with a higher performance rating than their department's average rating:
SELECT e.first_name, e.last_name, pr.rating, d.department_name
FROM employees e
JOIN performance_reviews pr ON e.employee_id = pr.employee_id
JOIN departments d ON e.department_id = d.department_id
WHERE pr.rating > (
    SELECT AVG(pr2.rating)
    FROM performance_reviews pr2
    WHERE pr2.employee_id = e.employee_id
);
Find employees who are supervisors:
SELECT e.first_name, e.last_name
FROM employees e
WHERE e.employee_id IN (SELECT supervisor_id FROM employees WHERE supervisor_id IS NOT NULL);

--Aggregate Queries
-- Find the number of employees in each department
SELECT d.department_name, COUNT(e.employee_id) AS num_employees
FROM employees e
JOIN departments d ON e.department_id = d.department_id
GROUP BY d.department_name;
-- Find average age 
SELECT d.department_name, AVG(CalculateAge(e.date_of_birth)) AS avg_age
FROM employees e
JOIN departments d ON e.department_id = d.department_id
GROUP BY d.department_name;



