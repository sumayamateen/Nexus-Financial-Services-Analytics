
/*
2 - Customer Churn Analysis
Customer churn has been climbing all year — particularly in the second half. Need to know who is leaving, when, and from which segments. Industry, branch, banker, risk tier. 
*/


--- Total churned customers in 2024


SELECT 
  COUNT(*) FILTER (WHERE churn_date >= '2024-01-01' AND churn_date < '2025-01-01') AS customer_churn_in_2024,
  COUNT(*) FILTER (WHERE churn_date >= '2023-01-01' AND churn_date < '2024-01-01') AS customer_churn_in_2023,
  ROUND(
    100.0 * 
    (COUNT(*) FILTER (WHERE churn_date >= '2024-01-01' AND churn_date < '2025-01-01') - 
     COUNT(*) FILTER (WHERE churn_date >= '2023-01-01' AND churn_date < '2024-01-01')) / 
    NULLIF(COUNT(*) FILTER (WHERE churn_date >= '2023-01-01' AND churn_date < '2024-01-01'), 0),
    1
  ) AS pct_change
FROM nexus_banking.customers

WHERE churn_date IS NOT NULL;

/*
Run Query
Query Results 1 rows
customer_churn_in_2024	customer_churn_in_2023	pct_change
1,848	503	267.4
*/


---- Monthly churn trajectory across 2024


SELECT 
	EXTRACT(MONTH FROM churn_date)::INT AS month_number,
	TO_CHAR(churn_date,'FMMonth') AS month_name,
	COUNT(*) AS churn_this_month,
	SUM(COUNT(*) ) OVER(ORDER BY EXTRACT(MONTH FROM churn_date)) AS cumulative_ytd
FROM nexus_banking.customers

WHERE churn_date >= '2024-01-01' AND churn_date < '2025-01-01' 

GROUP BY EXTRACT(MONTH FROM churn_date), TO_CHAR(churn_date,'FMMonth')

ORDER BY month_number ASC

/*
Run Query
Query Results 12 rows
month_number	month_name	churn_this_month	cumulative_ytd
1	January	58	58
2	February	53	111
3	March	79	190
4	April	63	253
5	May	55	308
6	June	46	354
7	July	231	585
8	August	233	818
9	September	246	1,064
10	October	252	1,316
11	November	278	1,594
12	December	254	1,848
*/


--- Churn rate by industry


SELECT 
  i.industry_name,
  COUNT(c.customer_id) AS total_customers,
  COUNT(c.customer_id) FILTER (WHERE churn_date IS NOT NULL) AS churned_customers,
  ROUND(100.0 * (COUNT(c.customer_id) FILTER (WHERE churn_date IS NOT NULL)) / (COUNT(c.customer_id)),1) AS churn_rate_pct
FROM nexus_banking.customers AS c

INNER JOIN nexus_banking.industry_codes AS i
ON c.industry_code = i.industry_code

GROUP BY i.industry_name

HAVING COUNT(c.customer_id) >= 100

ORDER BY churn_rate_pct DESC

/*
Run Query
Query Results 16 rows
industry_name	total_customers	churned_customers	churn_rate_pct
Construction	2,391	344	14.4
Retail Trade	2,129	303	14.2
Accommodation & Food	1,426	197	13.8
Administrative Support	1,199	108	9
Healthcare & Social Asst.	1,977	176	8.9
Information & Tech	2,013	171	8.5
Educational Services	751	63	8.4
Finance & Insurance	1,172	96	8.2
Arts, Entertainment & Rec.	738	60	8.1
Wholesale Trade	1,675	133	7.9
Agriculture, Forestry, Fishing	942	74	7.9
Transportation & Warehousing	1,452	114	7.9
Professional Services	2,437	183	7.5
Manufacturing	2,011	142	7.1
Other Services	1,006	70	7
Real Estate	1,681	117	7
*/


--- Churn rate by risk tier


SELECT 
    risk_tier,
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (WHERE churn_date IS NOT NULL) AS churned_customers,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE churn_date IS NOT NULL) / COUNT(*),
        1
    ) AS churn_rate_pct
FROM nexus_banking.customers

GROUP BY risk_tier

ORDER BY 
    CASE risk_tier
        WHEN 'low' THEN 1
        WHEN 'medium' THEN 2
        WHEN 'high' THEN 3
        ELSE 4
    END;

/*
Run Query
Query Results 3 rows
risk_tier	total_customers	churned_customers	churn_rate_pct
low	10,742	911	8.5
medium	10,039	924	9.2
high	4,219	516	12.2
*/


--- Top 10 bankers by customer churn


WITH banker_churn AS (
    SELECT 
        ba.banker_id,
        ba.first_name || ' ' || ba.last_name AS banker_name,
        ba.role,
        br.branch_name,
        COUNT(cu.customer_id) AS total_customers_onboarded,
        COUNT(cu.customer_id) FILTER (WHERE cu.churn_date IS NOT NULL) AS customers_churned,
        ROUND(
            100.0 * COUNT(cu.customer_id) FILTER (WHERE cu.churn_date IS NOT NULL) / COUNT(cu.customer_id),
            1
        ) AS churn_rate_pct
    FROM nexus_banking.customers AS cu
    INNER JOIN nexus_banking.bankers AS ba
    ON cu.onboarded_by_banker_id = ba.banker_id
    INNER JOIN nexus_banking.branches AS br
    ON ba.home_branch_id = br.branch_id
	
    WHERE ba.role IN ('relationship_manager', 'loan_officer')
	
    GROUP BY ba.banker_id, ba.first_name, ba.last_name, ba.role, br.branch_name
	
    HAVING COUNT(cu.customer_id) >= 30
)
SELECT 
    banker_name,
    role,
    branch_name,
    total_customers_onboarded,
    customers_churned,
    churn_rate_pct,
    ROUND(AVG(churn_rate_pct) OVER (), 1) AS network_avg_churn,
    ROUND(churn_rate_pct - AVG(churn_rate_pct) OVER (), 1) AS vs_network_avg
FROM banker_churn

ORDER BY churn_rate_pct DESC

LIMIT 10

/*
Run Query
Query Results10 rows
banker_name	role	branch_name	total_customers_onboarded	customers_churned	churn_rate_pct	network_avg_churn	vs_network_avg
Maria Rodgers	relationship_manager	Central — New York	42	12	28.6	9	19.6
Julie Alvarez	relationship_manager	Southpoint — Boston	33	8	24.2	9	15.2
Nicholas Johnson	relationship_manager	Westside — Houston	39	9	23.1	9	14.1
Thomas Pearson	relationship_manager	Central — New York	35	8	22.9	9	13.9
Samuel Jenkins	loan_officer	Southpoint — Boston	36	8	22.2	9	13.2
William Hoover	relationship_manager	Northpoint — Los Angeles	38	8	21.1	9	12.1
Cindy Johnson	relationship_manager	Northpoint — Atlanta	35	7	20	9	11
Haley Lyons	relationship_manager	Southpoint — Boston	41	8	19.5	9	10.5
Dylan Lester	relationship_manager	Northpoint — Cleveland	31	6	19.4	9	10.4
Gary Dixon	relationship_manager	Crossing — Austin	38	7	18.4	9	9.4
*/


--- Tenure at churn — how long do customers stay?


WITH churned_customers AS (
  SELECT 
    customer_id,
    onboarding_date,
    churn_date,
    churn_date - onboarding_date AS tenure_days
  FROM nexus_banking.customers
  
  WHERE churn_date IS NOT NULL
),
tenure AS (
  SELECT
    customer_id,
    tenure_days,
	
    CASE 
      WHEN tenure_days < 180  THEN 'Under 6 months'
      WHEN tenure_days >= 180 AND tenure_days < 366  THEN '6-12 months'
      WHEN tenure_days >= 366 AND tenure_days < 730  THEN '1-2 years'
      ELSE '2+ years' 
    END AS tenure_bucket
  FROM churned_customers
)

SELECT  
  tenure_bucket,
  COUNT(*) AS churned_customers,
  ROUND((COUNT(*) / SUM(COUNT(*)) OVER()) * 100.0, 1) AS pct_of_churned
FROM tenure  

GROUP BY tenure_bucket

ORDER BY CASE tenure_bucket
   WHEN 'Under 6 months' THEN 1
   WHEN '6-12 months' THEN 2
   WHEN '1-2 years' THEN 3
   ELSE 4
END

/*
Run Query
Query Results 4 rows
tenure_bucket	churned_customers	pct_of_churned
Under 6 months	622	26.5
6-12 months	567	24.1
1-2 years	951	40.5
2+ years	211	9
*/


--- Churn concentration by region

WITH region_stats AS (
    SELECT 
        br.region,
        COUNT(c.customer_id) AS total_customers,
        COUNT(c.customer_id) FILTER (WHERE c.churn_date IS NOT NULL) AS churned_customers
    FROM nexus_banking.customers AS c
	
    INNER JOIN nexus_banking.bankers AS ba
    ON c.onboarded_by_banker_id = ba.banker_id
    INNER JOIN nexus_banking.branches AS br
    ON ba.home_branch_id = br.branch_id
	
    GROUP BY br.region
)
SELECT 
    region,
    total_customers,
    churned_customers,
    ROUND(
        100.0 * churned_customers / NULLIF(total_customers, 0),
        1) AS churn_rate
FROM region_stats

ORDER BY churn_rate DESC;

/*
Run Query
Query Results 5 rows
region	total_customers	churned_customers	churn_rate
Southeast	3,429	344	10
West	7,482	714	9.5
Northeast	5,645	524	9.3
South	4,229	387	9.2
Midwest	4,215	382	9.1
*/