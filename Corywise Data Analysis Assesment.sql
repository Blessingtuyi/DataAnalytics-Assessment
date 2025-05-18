CREATE DATABASE adashi_staging;

SHOW TABLES;

DESC users_customuser;
DESC users_customuser;

SELECT COUNT(*) FROM users_customuser;
SELECT * FROM users_customuser LIMIT 5;

SELECT 
    u.id, u.name, s.confirmed_amount, p.id AS investment_id
FROM users_customuser u
LEFT JOIN savings_savingsaccount s ON u.id = s.owner_id
LEFT JOIN plans_plan p ON u.id = p.owner_id
LIMIT 5;


--- Removing null names 
SELECT * FROM users_customuser WHERE name IS NULL LIMIT 10;

SELECT COUNT(*) FROM users_customuser;

SELECT id, name, first_name, last_name FROM users_customuser WHERE name IS NULL LIMIT 10;

UPDATE users_customuser SET name = CONCAT(first_name, ' ', last_name) WHERE name IS NULL;


SELECT id, COUNT(*) FROM users_customuser GROUP BY id HAVING COUNT(*) > 1;

--- CONFIRMING PASSWORD DATA AND CLEANING DATA
SELECT password FROM users_customuser LIMIT 10;

SELECT name, first_name, last_name FROM users_customuser WHERE name IS NULL LIMIT 10;

SELECT COUNT(*) FROM users_customuser WHERE name IS NOT NULL;

UPDATE users_customuser 
SET name = CONCAT(first_name, ' ', last_name) 
WHERE name IS NULL AND first_name IS NOT NULL AND last_name IS NOT NULL;

UPDATE users_customuser 
SET name = 'Test Name' 
WHERE id = (SELECT id FROM users_customuser WHERE name IS NULL LIMIT 1);

 --- Data Cleaning: Handling NULL values

--- 1. Fix missing customer names (replace NULL with 'Unknown User')
UPDATE users_customuser 
SET name = 'Unknown User' 
WHERE name IS NULL;

--- 2. Verify there are no remaining NULL names
SELECT * FROM users_customuser WHERE first_name IS NULL AND last_name IS NULL;
SELECT * FROM users_customuser WHERE name IS NULL LIMIT 10;


--- 3. Ensure all savings transactions have valid amounts
UPDATE savings_savingsaccount 
SET confirmed_amount = 0 
WHERE confirmed_amount IS NULL;

--- 4. Check if transaction_date values are missing
SELECT * FROM savings_savingsaccount WHERE transaction_date IS NULL LIMIT 10;

--- 5. Remove corrupted records where both first_name and last_name are NULL
DELETE FROM users_customuser WHERE first_name IS NULL AND last_name IS NULL;

--- Question 1: High-Value Customers with Multiple Products
--- Identifies customers with at least one funded savings plan AND one funded investment plan
--- Sorting by total deposits

SELECT 
    u.id AS owner_id,
    u.name,
    COUNT(DISTINCT s.id) AS savings_count,
    COUNT(DISTINCT p.id) AS investment_count,
    SUM(s.confirmed_amount) AS total_deposits
FROM users_customuser u
LEFT JOIN savings_savingsaccount s ON u.id = s.owner_id AND s.is_regular_savings = 1
LEFT JOIN plans_plan p ON u.id = p.owner_id AND p.is_a_fund = 1
WHERE s.confirmed_amount IS NOT NULL AND p.id IS NOT NULL
GROUP BY u.id, u.name
ORDER BY total_deposits DESC;
DESC savings_savingsaccount;
SELECT 
    u.id AS owner_id,
    u.name,
    COUNT(DISTINCT s.id) AS savings_count,
    COUNT(DISTINCT p.id) AS investment_count,
    SUM(s.confirmed_amount) AS total_deposits
FROM users_customuser u
LEFT JOIN savings_savingsaccount s ON u.id = s.owner_id
LEFT JOIN plans_plan p ON u.id = p.owner_id AND p.is_a_fund = 1
WHERE s.confirmed_amount IS NOT NULL AND p.id IS NOT NULL
GROUP BY u.id, u.name
ORDER BY total_deposits DESC;


SHOW VARIABLES LIKE 'wait_timeout';
SHOW VARIABLES LIKE 'wait_timeout';


SELECT 
    u.id AS owner_id,
    u.name,
    COUNT(DISTINCT s.id) AS savings_count,
    COUNT(DISTINCT p.id) AS investment_count,
    SUM(s.confirmed_amount) AS total_deposits
FROM users_customuser u
LEFT JOIN savings_savingsaccount s ON u.id = s.owner_id
LEFT JOIN plans_plan p ON u.id = p.owner_id AND p.is_a_fund = 1
WHERE s.confirmed_amount IS NOT NULL AND p.id IS NOT NULL
GROUP BY u.id, u.name
ORDER BY total_deposits DESC
LIMIT 50;
SELECT 
    u.id AS owner_id,
    u.name,
    COUNT(DISTINCT s.id) AS savings_count,
    COUNT(DISTINCT p.id) AS investment_count,
    SUM(s.confirmed_amount) AS total_deposits
FROM users_customuser u
LEFT JOIN savings_savingsaccount s ON u.id = s.owner_id
LEFT JOIN plans_plan p ON u.id = p.owner_id AND p.is_a_fund = 1
WHERE s.confirmed_amount IS NOT NULL AND p.id IS NOT NULL
GROUP BY u.id, u.name
ORDER BY total_deposits DESC
LIMIT 100;



--- Question 2: Transaction Frequency Analysis
-- Categorizes customers into High, Medium, and Low frequency segments
-- Based on average transactions per month

--- SELECT 
 ---   CASE 
---      WHEN AVG(transaction_count_per_month) >= 10 THEN 'High Frequency'
    ---    WHEN AVG(transaction_count_per_month) BETWEEN 3 AND 9 THEN 'Medium Frequency'
     ---   ELSE 'Low Frequency'
   --- END AS frequency_category,
  ---  COUNT(DISTINCT u.id) AS customer_count,
   --- AVG(transaction_count_per_month) AS avg_transactions_per_month
--- FROM (
    --- SELECT 
       --- s.owner_id,
      ---  COUNT(s.id) / TIMESTAMPDIFF(MONTH, MIN(s.transaction_date), MAX(s.transaction_date)) AS transaction_count_per_month
    --- FROM savings_savingsaccount s
   --- GROUP BY s.owner_id
--- ) AS monthly_transactions
--- JOIN users_customuser u ON monthly_transactions.owner_id = u.id
--- GROUP BY frequency_category;

-- Step 1: Calculate monthly transaction frequency per customer
WITH monthly_transactions AS (
    SELECT 
        s.owner_id,
        COUNT(s.id) / TIMESTAMPDIFF(MONTH, MIN(s.transaction_date), MAX(s.transaction_date)) AS transaction_count_per_month
    FROM savings_savingsaccount s
    GROUP BY s.owner_id
)
-- Step 2: Categorize customers based on transaction frequency
SELECT 
    CASE 
        WHEN transaction_count_per_month >= 10 THEN 'High Frequency'
        WHEN transaction_count_per_month BETWEEN 3 AND 9 THEN 'Medium Frequency'
        ELSE 'Low Frequency'
    END AS frequency_category,
    COUNT(DISTINCT owner_id) AS customer_count,
    AVG(transaction_count_per_month) AS avg_transactions_per_month
FROM monthly_transactions
GROUP BY frequency_category;

--- Question 3:  Account Inactivity Alert.
--- To identify active savings or investment accounts that have not recorded any transactions for over a year (365 days).

-- Question 3: Account Inactivity Alert
-- ==========================================
-- Identifies accounts that have recorded no transactions for over a year

SELECT 
    p.id AS plan_id,
    p.owner_id,
    CASE 
        WHEN p.is_a_fund = 1 THEN 'Investment'
        ELSE 'Savings'
    END AS type,
    MAX(s.transaction_date) AS last_transaction_date,
    DATEDIFF(CURDATE(), MAX(s.transaction_date)) AS inactivity_days
FROM plans_plan p
LEFT JOIN savings_savingsaccount s ON p.owner_id = s.owner_id
WHERE s.transaction_date IS NOT NULL
GROUP BY p.id, p.owner_id, type
HAVING inactivity_days > 365
ORDER BY inactivity_days DESC
LIMIT 50;

-- Optimization Steps to Fix Connection Loss Issues

SET GLOBAL wait_timeout = 5000;
SET GLOBAL interactive_timeout = 5000;
SET GLOBAL max_allowed_packet = 1073741824;

SHOW INDEX FROM savings_savingsaccount;
SHOW INDEX FROM plans_plan;
CREATE INDEX idx_transaction_date ON savings_savingsaccount(transaction_date);
CREATE INDEX idx_owner_id ON plans_plan(owner_id);



SELECT 
    p.id AS plan_id,
    p.owner_id,
    CASE 
        WHEN p.is_a_fund = 1 THEN 'Investment'
        ELSE 'Savings'
    END AS type,
    MAX(s.transaction_date) AS last_transaction_date,
    DATEDIFF(CURDATE(), MAX(s.transaction_date)) AS inactivity_days
FROM plans_plan p
LEFT JOIN savings_savingsaccount s ON p.owner_id = s.owner_id
WHERE s.transaction_date IS NOT NULL
GROUP BY p.id, p.owner_id, type
HAVING inactivity_days > 365
ORDER BY inactivity_days DESC;

 --- Limitataions attempts to Fix Connection Loss Issues

SELECT 
    p.id AS plan_id,
    p.owner_id,
    CASE 
        WHEN p.is_a_fund = 1 THEN 'Investment'
        ELSE 'Savings'
    END AS type,
    MAX(s.transaction_date) AS last_transaction_date,
    DATEDIFF(CURDATE(), MAX(s.transaction_date)) AS inactivity_days
FROM plans_plan p
LEFT JOIN savings_savingsaccount s ON p.owner_id = s.owner_id
WHERE s.transaction_date IS NOT NULL
GROUP BY p.id, p.owner_id, type
HAVING inactivity_days > 365
ORDER BY inactivity_days DESC
LIMIT 100;

SELECT 
    p.id AS plan_id,
    p.owner_id,
    CASE 
        WHEN p.is_a_fund = 1 THEN 'Investment'
        ELSE 'Savings'
    END AS type,
    MAX(s.transaction_date) AS last_transaction_date,
    DATEDIFF(CURDATE(), MAX(s.transaction_date)) AS inactivity_days
FROM plans_plan p
LEFT JOIN savings_savingsaccount s ON p.owner_id = s.owner_id
WHERE s.transaction_date IS NOT NULL
GROUP BY p.id, p.owner_id, type
HAVING inactivity_days > 365
ORDER BY inactivity_days DESC
LIMIT 50;


SHOW TABLES;


SELECT COUNT(*) FROM savings_savingsaccount;
SELECT COUNT(*) FROM plans_plan;

--- Running code chunk by chunk 

SELECT p.id, p.owner_id, MAX(s.transaction_date) AS last_transaction_date
FROM plans_plan p
LEFT JOIN savings_savingsaccount s ON p.owner_id = s.owner_id
WHERE s.transaction_date IS NOT NULL
GROUP BY p.id, p.owner_id
ORDER BY last_transaction_date DESC
LIMIT 50;

SELECT p.id, p.owner_id, MAX(s.transaction_date) AS last_transaction_date,
    DATEDIFF(CURDATE(), MAX(s.transaction_date)) AS inactivity_days
FROM plans_plan p
LEFT JOIN savings_savingsaccount s ON p.owner_id = s.owner_id
WHERE s.transaction_date IS NOT NULL
GROUP BY p.id, p.owner_id
HAVING inactivity_days > 365
ORDER BY inactivity_days DESC
LIMIT 50;





--- Question 4: Customer Lifetime Value (CLV) Estimation
--- Estimates CLV using tenure, transaction count, and profit margin

WITH customer_activity AS (
    SELECT 
        u.id AS customer_id,
        u.name,
        TIMESTAMPDIFF(MONTH, MIN(s.transaction_date), CURDATE()) AS tenure_months,
        COUNT(s.id) AS total_transactions,
        SUM(s.confirmed_amount) AS total_transaction_value
    FROM users_customuser u
    LEFT JOIN savings_savingsaccount s ON u.id = s.owner_id
    WHERE s.transaction_date IS NOT NULL
    GROUP BY u.id, u.name
)
SELECT 
    customer_id,
    name,
    tenure_months,
    total_transactions,
    (total_transactions / NULLIF(tenure_months, 0)) * 12 * (0.001 * total_transaction_value) AS estimated_clv
FROM customer_activity
ORDER BY estimated_clv DESC
LIMIT 50;

-- Prevent Connection Loss
SET GLOBAL innodb_buffer_pool_size = 2147483648;
FLUSH TABLES;
OPTIMIZE TABLE savings_savingsaccount;
OPTIMIZE TABLE plans_plan;


WITH customer_activity AS (
    SELECT 
        u.id AS customer_id,
        u.name,
        TIMESTAMPDIFF(MONTH, MIN(s.transaction_date), CURDATE()) AS tenure_months,
        COUNT(s.id) AS total_transactions,
        SUM(s.confirmed_amount) AS total_transaction_value
    FROM users_customuser u
    LEFT JOIN savings_savingsaccount s ON u.id = s.owner_id
    WHERE s.transaction_date IS NOT NULL
    GROUP BY u.id, u.name
)
SELECT 
    customer_id,
    name,
    tenure_months,
    total_transactions,
    (total_transactions / NULLIF(tenure_months, 0)) * 12 * (0.001 * total_transaction_value) AS estimated_clv
FROM customer_activity
ORDER BY estimated_clv DESC;
