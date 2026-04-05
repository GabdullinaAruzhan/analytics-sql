#1. Список "лояльных" клиентов (непрерывная история за год)

SELECT 
    ID_client,
    ROUND(AVG(Sum_payment), 2) AS avg_check,             
    ROUND(SUM(Sum_payment) / 12, 2) AS avg_monthly_sum, 
    COUNT(Id_check) AS total_operations                 
FROM fp.transactions_info
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY ID_client
-- Условие: уникальных месяцев должно быть 12
HAVING COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) >= 12;

#2. Анализ в разрезе месяцев
WITH monthly_metrics AS (
    SELECT 
        DATE_FORMAT(date_new, '%Y-%m') AS month_id,
        AVG(Sum_payment) AS avg_check_monthly,
        COUNT(Id_check) AS ops_count,
        COUNT(DISTINCT ID_client) AS unique_clients,
        SUM(Sum_payment) AS total_month_sum
    FROM fp.transactions_info
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY month_id
),
year_totals AS (
    SELECT 
        SUM(Sum_payment) as total_year_sum, 
        COUNT(Id_check) as total_year_ops 
    FROM fp.transactions_info 
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
)
SELECT 
    m.*,
    ROUND(m.ops_count / y.total_year_ops * 100, 2) AS share_of_annual_ops_pct,
    ROUND(m.total_month_sum / y.total_year_sum * 100, 2) AS share_of_annual_sum_pct
FROM monthly_metrics m, year_totals y;

#2 (e). Соотношение по полу (M/F/NA) и доли затрат
SELECT 
    DATE_FORMAT(t.date_new, '%Y-%m') AS month_id,
    c.Gender,
    COUNT(t.Id_check) AS ops_by_gender,
    SUM(t.Sum_payment) AS sum_by_gender,
    -- Доля затрат конкретного пола от общей суммы за этот месяц
    ROUND(SUM(t.Sum_payment) / SUM(SUM(t.Sum_payment)) OVER(PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m')) * 100, 2) AS gender_spend_share_pct
FROM fp.transactions_info t
JOIN fp.customer_info c ON t.ID_client = c.Id_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY month_id, c.Gender;

#3. Возрастные группы (шаг 10 лет)

SELECT 
    CASE 
        WHEN Age IS NULL THEN 'Unknown'
        ELSE CONCAT(FLOOR(Age / 10) * 10, '-', FLOOR(Age / 10) * 10 + 9)
    END AS age_group,
    SUM(Sum_payment) AS total_sum,
    COUNT(Id_check) AS total_operations,
    ROUND(AVG(CASE WHEN QUARTER(date_new) = 1 THEN Sum_payment END), 2) AS q1_avg_sum,
    ROUND(AVG(CASE WHEN QUARTER(date_new) = 2 THEN Sum_payment END), 2) AS q2_avg_sum,
    ROUND(AVG(CASE WHEN QUARTER(date_new) = 3 THEN Sum_payment END), 2) AS q3_avg_sum,
    ROUND(AVG(CASE WHEN QUARTER(date_new) = 4 THEN Sum_payment END), 2) AS q4_avg_sum
FROM fp.transactions_info t
LEFT JOIN fp.customer_info c ON t.ID_client = c.Id_client
GROUP BY age_group;