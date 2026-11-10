
/*
3 - Fraud Analysis
The numbers are climbing in late 2024. Need a deep investigation — transaction patterns, customer concentration, channel patterns, dollar impact. 
*/

---Fraud case volume by month


SELECT
    EXTRACT(YEAR  FROM opened_date) AS year,
    EXTRACT(MONTH FROM opened_date) AS month_num,
    TRIM(TO_CHAR(opened_date, 'Month')) AS month_name,
    COUNT(*) AS cases_opened,
    COUNT(*) FILTER (WHERE case_status = 'confirmed_fraud') AS cases_confirmed,
    SUM(loss_amount) AS total_dollar_loss
FROM nexus_banking.fraud_cases

WHERE opened_date >= '2023-01-01'
AND opened_date <  '2025-01-01'

GROUP BY
    EXTRACT(YEAR  FROM opened_date),
    EXTRACT(MONTH FROM opened_date),
    TO_CHAR(opened_date, 'Month')
	
ORDER BY year, month_num;

/*
Run Query
Query Results 24 rows
year	month_num	month_name	case_opened	cases_confirmed	total_dollar_loss
2023	1	JANUARY	51	16	413,480.31
2023	2	FEBRUARY	31	10	269,610.26
2023	3	MARCH	42	12	214,639.29
2023	4	APRIL	37	7	185,729.9
2023	5	MAY	36	10	314,815.99
2023	6	JUNE	45	9	125,255.51
2023	7	JULY	52	18	477,566.78
2023	8	AUGUST	42	13	238,257.19
2023	9	SEPTEMBER	33	9	228,710.98
2023	10	OCTOBER	33	7	173,577.39
2023	11	NOVEMBER	47	16	464,262.57
2023	12	DECEMBER	46	15	389,043.29
2024	1	JANUARY	31	5	168,573.37
2024	2	FEBRUARY	31	10	229,103.33
2024	3	MARCH	33	10	266,126.64
2024	4	APRIL	31	14	318,060.79
2024	5	MAY	37	19	497,019.47
2024	6	JUNE	36	5	147,549.06
2024	7	JULY	213	53	1,318,164.69
2024	8	AUGUST	194	63	1,641,310.46
2024	9	SEPTEMBER	150	40	1,109,633.37
2024	10	OCTOBER	176	55	1,457,046.54
2024	11	NOVEMBER	189	45	1,321,225.49
2024	12	DECEMBER	184	52	1,185,796.9
*/


--- Year-over-year fraud comparison by case type


WITH cases_year AS (
SELECT 
    case_type,
    COUNT(*) FILTER (WHERE opened_date >= '2023-01-01' AND opened_date < '2024-01-01') AS cases_2023,
    COUNT(*) FILTER (WHERE opened_date >= '2024-01-01' AND opened_date < '2025-01-01') AS cases_2024
FROM nexus_banking.fraud_cases

GROUP BY case_type    
)

SELECT 
	case_type,
	cases_2023,
	cases_2024,
	cases_2024 -  cases_2023 AS yoy_change,
	ROUND(100.0 * (cases_2024 -  cases_2023) /  NULLIF(cases_2023, 0), 0) AS yoy_pct
FROM cases_year

ORDER BY cases_2024 DESC;

/*
Query Results 4 rows
case_type	cases_2023	cases_2024	yoy_change	yoy_pct
suspected_fraud	161	417	256	159
wire_fraud	125	343	218	174
identity_theft	119	291	172	145
check_fraud	90	254	164	182
*/


--- Top 20 customers by fraud exposure


SELECT 
    c.business_name,
    i.industry_name,
    c.risk_tier,
    COUNT(f.case_id) AS total_fraud_cases,
    ROUND(COALESCE(SUM(f.loss_amount) / 100.0, 0), 2) AS total_loss
FROM nexus_banking.fraud_cases f

INNER JOIN nexus_banking.customers c 
ON f.customer_id = c.customer_id
INNER JOIN nexus_banking.industry_codes i 
ON c.industry_code = i.industry_code

GROUP BY c.business_name, i.industry_name, c.risk_tier
	
ORDER BY total_loss DESC

LIMIT 20;

/*
Query Results 20 rows
business_name	industry_name	risk_tier	total_fraud_cases	total_loss
Carrillo and Sons	Construction	high	2	904.12
Perry, Finley and Anderson	Construction	medium	2	689.75
Lindsey Group	Retail Trade	low	2	689.59
Hill, Maxwell and Rodriguez	Construction	medium	2	657.49
Jones Group	Construction	high	3	653.27
May, Conway and Richards	Accommodation & Food	high	2	577.34
Malone-Sanford	Construction	medium	2	547.4
Richardson PLC	Accommodation & Food	medium	2	542.94
Reid-Ayala	Manufacturing	low	2	534.3
Lawson Inc	Construction	high	3	513.61
Monroe LLC	Retail Trade	high	2	510.43
Miller Group	Construction	high	1	496.35
Bradley Ltd	Wholesale Trade	medium	1	495.54
Hayes-Costa	Retail Trade	high	1	493.7
Adams and Sons	Construction	medium	1	492.95
Larsen and Sons	Retail Trade	medium	1	492.65
Duran, Ortiz and Tucker	Construction	high	1	490.64
Hernandez-Ballard	Educational Services	low	1	488.9
Smith-House	Educational Services	low	1	488.72
Stevenson and Sons	Construction	high	1	488.69
*/


--- Fraud rate by industry


WITH  industry_stats AS (
SELECT 
    i.industry_name,
    COUNT(DISTINCT(c.customer_id))  AS total_customers,
    COUNT(DISTINCT(f.customer_id))  AS customers_with_fraud
FROM nexus_banking.customers c    

INNER JOIN nexus_banking.industry_codes i
ON c.industry_code = i.industry_code
INNER JOIN  nexus_banking.fraud_cases f
ON c.customer_id = f.customer_id

GROUP BY i.industry_name

HAVING COUNT(DISTINCT(c.customer_id)) >= 100
)
SELECT 
  industry_name,
  total_customers,
  customers_with_fraud,
      ROUND(
        100.0 * customers_with_fraud / NULLIF(total_customers, 0),
        1
    ) AS fraud_rate_pct
FROM  industry_stats

ORDER BY fraud_rate_pct DESC;

/*
Query Results 16 rows
industry_name	total_customers	customers_with_fraud	fraud_rate_pct
Construction	2,391	484	20.2
Accommodation & Food	1,426	265	18.6
Retail Trade	2,129	369	17.3
Educational Services	751	30	4
Wholesale Trade	1,675	52	3.1
Transportation & Warehousing	1,452	43	3
Other Services	1,006	29	2.9
Finance & Insurance	1,172	33	2.8
Healthcare & Social Asst.	1,977	55	2.8
Manufacturing	2,011	55	2.7
Real Estate	1,681	45	2.7
Professional Services	2,437	66	2.7
Administrative Support	1,199	30	2.5
Information & Tech	2,013	51	2.5
Agriculture, Forestry, Fishing	942	23	2.4
Arts, Entertainment & Rec.	738	15	2
*/


--- Wire transaction fraud flag rate


SELECT 
    EXTRACT(YEAR FROM transaction_date) AS year,
    EXTRACT(MONTH FROM  transaction_date) AS month_num,
    TRIM(TO_CHAR(transaction_date, 'month')) AS month_name,
    COUNT(*) AS total_wire_transactions,
    COUNT(*) FILTER (WHERE is_flagged_for_fraud = TRUE) AS flagged_wire_transactions,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE is_flagged_for_fraud = TRUE) / NULLIF(COUNT(*), 0),
        2
    ) AS flag_rate_pct
FROM nexus_banking.transactions

WHERE transaction_type = 'wire'
AND transaction_date >= '2023-01-01' 
AND transaction_date < '2025-01-01'

GROUP BY EXTRACT(YEAR FROM transaction_date), EXTRACT(MONTH FROM transaction_date),  TRIM(TO_CHAR(transaction_date, 'month'))

ORDER BY year ASC , month_num ASC;

/*
Query Results 24 rows
year	month_num	month_name	total_wire_transactions	flagged_wire_transactions	flag_rate_pct
2023	1	january	898	5	0.56
2023	2	february	1,037	6	0.58
2023	3	march	1,338	11	0.82
2023	4	april	1,645	8	0.49
2023	5	may	2,023	12	0.59
2023	6	june	2,284	11	0.48
2023	7	july	2,792	10	0.36
2023	8	august	3,232	15	0.46
2023	9	september	3,369	13	0.39
2023	10	october	3,902	19	0.49
2023	11	november	4,354	23	0.53
2023	12	december	5,036	23	0.46
2024	1	january	5,378	27	0.5
2024	2	february	5,432	33	0.61
2024	3	march	6,144	31	0.5
2024	4	april	6,068	43	0.71
2024	5	may	6,512	30	0.46
2024	6	june	6,515	24	0.37
2024	7	july	7,023	389	5.54
2024	8	august	7,514	379	5.04
2024	9	september	7,651	368	4.81
2024	10	october	8,628	430	4.98
2024	11	november	9,332	435	4.66
2024	12	december	11,724	594	5.07
*/


--- Fraud overlap with churned customers


WITH customer_churn AS (
    SELECT 
        c.customer_id,
        CASE
            WHEN c.churn_date IS NOT NULL THEN TRUE
            WHEN EXISTS (
                SELECT 1 FROM nexus_banking.customer_lifecycle cl
                WHERE cl.customer_id = c.customer_id
                  AND cl.event_type IN ('churned', 'closed')
            ) THEN TRUE
            WHEN NOT EXISTS (
                SELECT 1 FROM nexus_banking.accounts a
                WHERE a.customer_id = c.customer_id
                  AND a.status = 'active'
            ) AND EXISTS (
                SELECT 1 FROM nexus_banking.accounts a
                WHERE a.customer_id = c.customer_id
            ) THEN TRUE
            ELSE FALSE
        END AS has_churned
		
    FROM nexus_banking.customers c
),
fraud_status AS (
    SELECT 
        c.customer_id,
        cc.has_churned,
        CASE 
            WHEN COUNT(f.case_id) > 0 THEN TRUE
            ELSE FALSE
        END AS has_fraud
    FROM nexus_banking.customers c
	
    LEFT JOIN nexus_banking.fraud_cases f
	ON c.customer_id = f.customer_id
    LEFT JOIN customer_churn cc
	ON c.customer_id = cc.customer_id
    WHERE EXTRACT(YEAR FROM c.onboarding_date) = 2024
	
    GROUP BY c.customer_id, cc.has_churned
)
SELECT 
    CASE 
        WHEN has_fraud THEN 'Fraud Cohort'
        ELSE 'Non-Fraud Cohort'
    END AS cohort,
    COUNT(customer_id) AS total_customers,
    COUNT(customer_id) FILTER (WHERE has_churned = TRUE) AS churned_customers,
    ROUND(
        100.0 * COUNT(customer_id) FILTER (WHERE has_churned = TRUE) / COUNT(customer_id),
        1
    ) AS churn_rate_pct
FROM fraud_status

GROUP BY has_fraud

ORDER BY has_fraud DESC;

/*
Run Query
Query Results 2 rows
cohort	total_customers	churned_customers	churn_rate_pct
Fraud Cohort	293	2	0.7
Non-Fraud Cohort	3,963	339	8.6
*/


--- Total 2024 fraud loss with recovery scenarios


WITH loss AS (
    SELECT
        ROUND(COALESCE(SUM(loss_amount) / 100.0, 0), 2) AS gross_loss
    FROM pbi_nexus.fact_fraud_cases
    WHERE case_status = 'confirmed_fraud'
      AND opened_year = 2024
)  
SELECT 
    'Pessimistic (10%)' AS scenario,
    gross_loss,
    ROUND(gross_loss * 0.10, 2) AS projected_recovery,
    gross_loss - ROUND(gross_loss * 0.10, 2) AS net_loss,  -- FIXED: Derived from gross_loss
    '90%' AS loss_retained_pct
FROM loss

UNION ALL 

SELECT 
    'Base Case (25%)' AS scenario,
    gross_loss,
    ROUND(gross_loss * 0.25, 2) AS projected_recovery,
    gross_loss - ROUND(gross_loss * 0.25, 2) AS net_loss,  -- FIXED: Derived from gross_loss
    '75%' AS loss_retained_pct
FROM loss

UNION ALL 

SELECT 
    'Optimistic (40%)' AS scenario,
    gross_loss,
    ROUND(gross_loss * 0.40, 2) AS projected_recovery,
    gross_loss - ROUND(gross_loss * 0.40, 2) AS net_loss,  -- FIXED: Derived from gross_loss
    '60%' AS loss_retained_pct
FROM loss
ORDER BY projected_recovery ASC;

/*
Query Results 3 rows
scenario	gross_loss	projected_recovery	net_loss	loss_retained_pct
Pessimistic (10%)	96,596.1	9,659.61	86,936.49	90%
Base Case (25%)	96,596.1	24,149.03	72,447.07	75%
Optimistic (40%)	96,596.1	38,638.44	57,957.66	60%

*/