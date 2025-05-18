SQL Proficiency Assessment
Welcome to my Data Analytics Assessment Submission! This evaluation tests SQL skills in data retrieval,
aggregation, joins, subqueries, and data manipulation. Below, you’ll find explanations for each query, 
challenges encountered, and solutions implemented.

Assessment Overview
The assessment involves working with relational databases containing customer, transaction, 
and account plan data to solve business-related queries.

Provided Tables
users_customuser – Customer demographic and contact details

savings_savingsaccount – Deposit transaction records

plans_plan – Records of investment plans created by customers

withdrawals_withdrawal – Withdrawal transaction records

Each SQL query is stored in a well-structured format, ensuring clarity and efficiency.

 Data Cleaning Process
Before executing queries, we cleaned the dataset to fix missing values: 

1️⃣ . Replaced NULL customer names with "Unknown User" to maintain data integrity:
UPDATE users_customuser 
SET name = 'Unknown User' 
WHERE name IS NULL;

2️⃣ . Checked if any NULL values remained in customer names:
SELECT * FROM users_customuser WHERE name IS NULL LIMIT 10;

3️⃣. Ensured savings accounts had proper amounts assigned:
UPDATE savings_savingsaccount 
SET confirmed_amount = 0 
WHERE confirmed_amount IS NULL;

4️⃣ Filtered out corrupted records where both first and last names were missing:
DELETE FROM users_customuser WHERE first_name IS NULL AND last_name IS NULL;

📌 SQL Queries & Solutions
Each question required a carefully structured query to derive insights.

🟢 Question 1: High-Value Customers with Multiple Products
Scenario: Identify customers who have both a funded savings plan AND an investment plan to explore cross-selling opportunities.

Challenges: ⚠️ Initially, is_regular_savings did not exist in the database schema, causing a query failure.
 ✅ Fix: Adjusted column references and verified correct data filtering.


Final Query:
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


🟠 Question 2: Transaction Frequency Analysis
Scenario: Calculate average transaction frequency per customer per month and categorize users into:

High Frequency (≥10 transactions/month)

Medium Frequency (3-9 transactions/month)

Low Frequency (≤2 transactions/month)

Challenges: ⚠️ MySQL grouping error (Error Code: 1056) caused incorrect frequency categorization. ✅ Fix: Used Common Table Expressions (CTE) to first calculate transaction frequency and then categorize customers.


Final Query:
WITH monthly_transactions AS (
    SELECT 
        s.owner_id,
        COUNT(s.id) / TIMESTAMPDIFF(MONTH, MIN(s.transaction_date), MAX(s.transaction_date)) AS transaction_count_per_month
    FROM savings_savingsaccount s
    GROUP BY s.owner_id
)
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


🔴 Question 3: Account Inactivity Alert
Scenario: Flag accounts with no inflow transactions for over 1 year (365 days).

Challenges: ⚠️ Large dataset caused MySQL timeouts & connection losses (Error Code: 2013). 
✅ Fix: Used LIMIT to break data retrieval into smaller chunks and optimized indexing for better execution.


Final Query:
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


🟣 Question 4: Customer Lifetime Value (CLV) Estimation
Scenario: Estimate CLV based on tenure, total transactions, and profitability using:

𝐶𝐿𝑉 = (total transactions/tenure) ∗ 12 ∗ avg profit per transaction
(where avg profit per transaction = 0.1% of total transaction value)

Challenges: ⚠️ MySQL memory issues required buffer optimization (max_allowed_packet) to prevent disconnects.
 ✅ Fix: Applied step-by-step query execution and table optimization.


Final Query:
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

--- Final Thoughts
This assessment provided valuable experience in troubleshooting database issues, optimizing queries, and handling large datasets efficiently. 💡 Key Takeaways:

Optimizing queries using indexing & limiting row retrieval enhances performance.

Using CTEs and proper grouping prevents aggregation errors.

Handling NULL values before execution ensures accurate results.