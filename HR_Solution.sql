-- DATA CLEANING USING SQL 
-- Setting the autocomit to off so we can rollback if error arise from new code
USE project;
SET AUTOCOMMIT = OFF;
START TRANSACTION;

-- View Data df
SELECT * FROM df;

-- Describe the data Structure
DESCRIBE df;

-- NB: Column not in proper field name
	-- Birthdate, hire_date, and termdate i.e termination date

ALTER TABLE df
RENAME COLUMN ï»¿id to employee_id;

ALTER TABLE df
MODIFY employee_id VARCHAR(20) NOT NULL;

-- Make the column for birthdate, hire_date and termdate uniform column
-- The safe update is on

SET sql_safe_updates = 0;

UPDATE df
SET birthdate = CASE
	WHEN birthdate LIKE '%-%' THEN date_format(str_to_date(birthdate, '%m-%d-%Y'), '%Y/%m/%d')
    WHEN birthdate LIKE '%/%' THEN date_format(str_to_date(birthdate, '%m/%d/%Y'), '%Y/%m/%d')
	ELSE NULL
END;

UPDATE df
SET hire_date= CASE
	WHEN hire_date LIKE '%-%' THEN date_format(str_to_date(hire_date, '%m-%d-%Y'), '%Y/%m/%d')
    WHEN hire_date LIKE '%/%' THEN date_format(str_to_date(hire_date, '%m/%d/%Y'), '%Y/%m/%d')
    ELSE null
END;

ALTER TABLE df
MODIFY hire_date Date,
MODIFY birthdate Date;

UPDATE df
SET termdate = CASE 
	WHEN termdate LIKE '%-%' THEN date(str_to_date(termdate, '%Y-%m-%d %H:%i:%s UTC'))
	ELSE '0000-00-00'
END;

-- Create age column
ALTER TABLE df
ADD COLUMN age INT;

UPDATE df
SET age = abs(timestampdiff(YEAR, birthdate, curdate()));



ALTER TABLE df
MODIFY termdate date;

rollback;

-- ** Questions
-- 1. What is the gender breakdown of employees in the company?
SELECT gender, count(*) AS Total FROM df
	WHERE termdate = '0000-00-00'
    GROUP BY gender;
    
-- 2. What is the race/ethnicity breakdown of employees in the company?
SELECT race, count(*) AS Total 
FROM df
	WHERE termdate = '0000-00-00'
    GROUP BY race
    ORDER BY Total DESC;

-- 3. What is the age distribution of employees in the company
SELECT MIN(age) AS Youngest,
		MAX(age) AS Oldest,
        round(AVG(age), 0) AS Average_age
FROM df;
-- Youngest age is 21, Oldest is 57

SELECT CASE
	WHEN age BETWEEN 21 and 30 THEN '21-30'
    WHEN age BETWEEN 31 and 40 THEN '31-40'
    WHEN age BETWEEN 41 and 50 THEN '41-50'
    ELSE '51_Above'
END as Age_distribution, count(*) AS Total
FROM df
WHERE termdate = '0000-00-00'
GROUP BY Age_distribution
ORDER BY  Age_distribution ASC;
    
-- 4. How many employees work at headquaters versus remote locations
SELECT location, count(*) AS Total
FROM df
WHERE termdate = '0000-00-00'
GROUP BY location;
-- 4b
SELECT gender, location, count(*) AS Total_employee
FROM df
WHERE termdate = '0000-00-00'
GROUP BY gender, location
ORDER BY gender DESC;

-- 5. What is the average length of employment for employees who hae been terminated?
SELECT round(abs(avg(datediff(hire_date, termdate)/360)), 0) AS Avg_len_employment
FROM df
WHERE termdate != '0000-00-00' and termdate <= curdate();
-- The average length of employment is 8years 

-- 6. How does the gender distribution vary across departments and job titles?
SELECT gender, department, jobtitle, count(*) AS Total 
FROM df
WHERE termdate = '0000-00-00'
GROUP BY gender, department
ORDER BY department ASC;

SELECT * FROM df;

-- 7. What is the distribution of job titles across the company?
SELECT jobtitle, location_city, count(*) AS Tot
FROM df
WHERE termdate = '0000-00-00'
GROUP BY location_city
ORDER BY location_city ASC;

SELECT jobtitle, location_state, count(*) AS Tot
FROM df
WHERE termdate = '0000-00-00'
GROUP BY location_state
ORDER BY location_state ASC;

SELECT * FROM df;
-- 8. Which department has the highest turnover rate?
SELECT department, total_count,
		terminated_count,
        concat(round(terminated_count/total_count *100, 0), '%') AS termination_rate
			FROM (SELECT department, count(*) AS total_count,
				SUM(CASE WHEN termdate != '0000-00-00' AND termdate <= curdate() THEN 1 ELSE 0 END) AS terminated_count
				FROM df
				GROUP BY department) AS Sb_query
                ORDER BY termination_rate DESC;
        
-- 9. What is the distribution of employees across locations by city and state?
SELECT location_state, count(*) AS total_employee
FROM df
WHERE termdate = '0000-00-00'
GROUP BY location_state
ORDER BY total_employee DESC;

SELECT location_city, count(*) AS total_employee
FROM df
WHERE termdate = '0000-00-00'
GROUP BY location_city
ORDER BY total_employee DESC;

-- 10. How has the company's employee count changed over time based on hire and termdates?

SELECT 
	yr, 
    hires,
    termination,
    hires-termination AS net_change,
    round((hires -termination)/hires * 100, 2) AS percent_net_change
    FROM (
		SELECT YEAR(hire_date) AS yr,
        count(*) AS hires,
        SUM(CASE WHEN termdate != '0000-00-00' AND termdate <= curdate() THEN 1 ELSE 0 END) AS termination
        FROM df
			GROUP BY YEAR(hire_date))
         AS Subq
	ORDER BY yr DESC;

-- 11. What is the tenure distribution for each department
SELECT department, round(avg(datediff(termdate, hire_date)/365), 0) AS avg_tenure
FROM df
	WHERE termdate != '0000-00-00' AND termdate <= curdate()
	GROUP BY department
	ORDER BY avg_tenure DESC;