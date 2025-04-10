WITH customer_last_purchase AS (
    SELECT
        customerkey,
        cleaned_name,
        orderdate,
        EXTRACT(YEAR FROM orderdate) AS year,
        ROW_NUMBER() OVER (PARTITION BY customerkey ORDER BY orderdate DESC) AS rn,
        MIN(orderdate) OVER (PARTITION BY customerkey) AS first_purchase_date
    FROM cohort_analysis
),

customer_status_cte AS (
    SELECT
        customerkey,
        year,
        CASE
            WHEN orderdate < (SELECT MAX(orderdate) FROM sales) - INTERVAL '6 months'
                THEN 'Churned'
            ELSE 'Active'
        END AS customer_status
    FROM customer_last_purchase
    WHERE rn = 1
      AND first_purchase_date < (SELECT MAX(orderdate) FROM sales) - INTERVAL '6 months'
)

SELECT
    year,
    customer_status,
    COUNT(*) AS num_customers,
    SUM(COUNT(*)) OVER (PARTITION BY year) AS total_customers,
    ROUND(COUNT(*) * 1.0 / SUM(COUNT(*)) OVER (PARTITION BY year), 2) AS status_percentage
FROM customer_status_cte
GROUP BY year, customer_status
ORDER BY year, customer_status;