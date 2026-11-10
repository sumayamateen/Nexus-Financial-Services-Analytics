
/*
Business Problem
Customer churn spiked last quarter — quietly, without anyone noticing until the numbers hit the board pack. Transaction volumes are flat but fee income is declining. The lending pipeline looks healthy on paper, but approval-to-disbursement times have nearly doubled.
Something is slipping across multiple parts of the business simultaneously, and leadership needs someone to dig in

1 - The Onboarding Audit
A clean view of where we stand — customer counts, account portfolio, branch footprint, onboarding volume. 
*/

--- How many customers and accounts do we have?


SELECT
  (SELECT COUNT(*) FROM nexus_banking.customers) AS total_customers,
  (SELECT COUNT(*) FROM nexus_banking.customers WHERE is_active = TRUE) AS active_customers,
  (SELECT COUNT(*) FROM nexus_banking.accounts) AS total_accounts;

/*
Run Query
Query Results 1 rows
total_customers	active_customers	total_accounts
25,000	22,649	58,910
*/

--- Customer breakdown by industry


SELECT 
	i.industry_name AS industry,
	i.sector,
	COUNT(c.customer_id) AS active_customer_count,
	ROUND(COUNT(c.customer_id) / SUM(COUNT(c.customer_id)) OVER() * 100.0, 1) AS percent_of_active_customer
FROM nexus_banking.customers AS c
INNER JOIN nexus_banking.industry_codes AS i
ON c.industry_code = i.industry_code

WHERE c.is_active = TRUE

GROUP BY i.industry_name, sector

ORDER BY active_customer_count DESC;

/*
Run Query
Query Results 16 rows
industry	sector	active_customer_count	percent_of_active_customer
Professional Services	Service	2,254	10
Construction	Goods-Producing	2,047	9
Manufacturing	Goods-Producing	1,869	8.3
Information & Tech	Service	1,842	8.1
Retail Trade	Trade	1,826	8.1
Healthcare & Social Asst.	Service	1,801	8
Real Estate	Service	1,564	6.9
Wholesale Trade	Trade	1,542	6.8
Transportation & Warehousing	Service	1,338	5.9
Accommodation & Food	Service	1,229	5.4
Administrative Support	Service	1,091	4.8
Finance & Insurance	Service	1,076	4.8
Other Services	Service	936	4.1
Agriculture, Forestry, Fishing	Primary	868	3.8
Educational Services	Service	688	3
Arts, Entertainment & Rec.	Service	678	3
*/


--- Branch footprint by region


SELECT 
  region,
  COUNT(branch_id) AS branch_count,
  ROUND(AVG(square_feet),0) AS avg_sqft,
  COUNT(*) FILTER (WHERE is_full_service = TRUE) AS full_service_count 
FROM nexus_banking.branches

GROUP BY region

ORDER BY branch_count DESC;

/*
Run Query
Query Results 5 rows
region	branch_count	avg_sqft	full_service_count
West	15	2,833	12
Northeast	9	2,944	8
Midwest	7	2,786	7
Southeast	7	2,643	6
South	7	3,286	7
*/


--- Banker headcount by role


SELECT 
  role,
  COUNT(banker_id) AS current_bankers,
  COUNT(*) FILTER(WHERE is_active = TRUE) AS active_bankers,
  COUNT(*) FILTER(WHERE is_active = FALSE) AS inactive_bankers
FROM nexus_banking.bankers

GROUP BY role

ORDER BY current_bankers DESC;

/*
Run Query
Query Results 4 rows
role	current_bankers	active_bankers	inactive_bankers
teller	246	238	8
relationship_manager	211	202	9
loan_officer	75	72	3
branch_manager	68	66	2
*/


--- Monthly onboarding volume for 2024


SELECT 
  EXTRACT(YEAR FROM onboarding_date)::INT AS onboard_year,
  EXTRACT(MONTH FROM onboarding_date)::INT AS onboard_month,
  COUNT(*) AS new_customers,
  COUNT(*) FILTER (WHERE industry_code IN ('23','72','44'))  AS high_risk_industry_count,
   ROUND(
    100.0 * COUNT(*) FILTER (WHERE industry_code IN ('23','72','44')) / COUNT(*), 
    1) AS high_risk_percentage
FROM nexus_banking.customers 

WHERE onboarding_date >= '2024-01-01' AND onboarding_date < '2025-01-01' 

GROUP BY onboard_year,onboard_month

ORDER BY onboard_year, onboard_month ASC;

/*
Run Query
Query Results 11 rows
onboard_year	onboard_month	new_customers	high_risk_industry_count	high_risk_percentage
2,024	1	402	105	26.1
2,024	2	366	79	21.6
2,024	3	411	93	22.6
2,024	4	396	103	26
2,024	5	386	93	24.1
2,024	6	352	89	25.3
2,024	7	364	88	24.2
2,024	8	392	103	26.3
2,024	9	392	103	26.3
2,024	10	438	105	24
2,024	11	357	84	23.5
*/


--- Account composition — type and status


SELECT 
    account_type,
    status,   
    COUNT(*) AS account_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY account_type), 1) AS pct_of_type
FROM nexus_banking.accounts

WHERE account_type IN ('checking', 'savings', 'money_market')

GROUP BY account_type,status

ORDER BY account_type,status;

/*
Run Query
Query Results 9 rows
account_type	status	account_count	pct_of_type
checking	active	22,894	86.3
checking	closed	2,522	9.5
checking	dormant	1,099	4.1
money_market	active	7,594	85.9
money_market	closed	833	9.4
money_market	dormant	412	4.7
savings	active	12,644	86
savings	closed	1,374	9.4
savings	dormant	677	4.6
*/


--- Top 10 branches by customer assignment


SELECT 
  br.branch_name,
  br.region,
  br.state,
  COUNT(cu.customer_id) AS customer_count
FROM nexus_banking.branches AS br

LEFT JOIN nexus_banking.bankers AS ba
ON br.branch_id = ba.home_branch_id
LEFT JOIN nexus_banking.customers AS cu
ON ba.banker_id = cu.onboarded_by_banker_id

GROUP BY br.branch_name, br.region, br.state

ORDER BY customer_count DESC

LIMIT 10; 

/*
Run Query
Query Results 10 rows
branch_name	region	state	customer_count
Southpoint — Boston	Northeast	MA	2,040
Crossing — Austin	South	TX	1,373
Westside — Chicago	Midwest	IL	1,366
Central — New York	Northeast	NY	968
Eastgate — Minneapolis	Midwest	MN	792
Crossing — Atlanta	Southeast	GA	709
Midtown — Austin	South	TX	708
Park — San Francisco	West	CA	679
Riverside — New York	Northeast	NY	653
Central — Phoenix	West	AZ	638
*/