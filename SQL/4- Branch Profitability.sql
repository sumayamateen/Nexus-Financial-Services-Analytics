/*
4 - Branch Profitability
Need a branch-by-branch view. Some branches are clearly underperforming want to know which ones, by how much, and why.
*/

--- Branch ranking by active customer count


SELECT 
    br.branch_id,
    br.branch_name,
    br.region,
    br.state,
    COUNT(cu.customer_id) AS total_customers,
    COUNT(cu.customer_id) FILTER (WHERE cu.is_active = TRUE) AS active_customers,
    ROUND(
        100.0 * COUNT(cu.customer_id) FILTER (WHERE cu.is_active = TRUE) 
        / NULLIF(COUNT(cu.customer_id), 0),
        1
    ) AS retention_rate_pct
FROM nexus_banking.branches AS br

LEFT JOIN nexus_banking.bankers AS ba
ON br.branch_id = ba.home_branch_id
LEFT JOIN nexus_banking.customers AS cu
ON ba.banker_id = cu.onboarded_by_banker_id

GROUP BY br.branch_id, br.branch_name, br.region, br.state

ORDER BY active_customers DESC;

/*
Query Results 45 rows
branch_id	branch_name	region	state	total_customers	active_customers	retention_rate_pct
BR0007	Central — New York	Northeast	NY	968	875	90.4
BR0016	Westside — Chicago	Midwest	IL	816	740	90.7
BR0036	Eastgate — Minneapolis	Midwest	MN	792	727	91.8
BR0019	Southpoint — Boston	Northeast	MA	747	666	89.2
BR0045	Southpoint — Boston	Northeast	MA	711	650	91.4
BR0025	Crossing — Atlanta	Southeast	GA	709	649	91.5
BR0031	Midtown — Austin	South	TX	708	648	91.5
BR0028	Crossing — Austin	South	TX	701	645	92
BR0024	Park — San Francisco	West	CA	679	622	91.6
BR0042	Crossing — Austin	South	TX	672	593	88.2
BR0029	Riverside — New York	Northeast	NY	653	586	89.7
BR0027	Westside — Houston	South	TX	635	580	91.3
BR0032	Central — Phoenix	West	AZ	638	568	89
BR0018	Commons — Portland	West	OR	620	565	91.1
BR0041	Eastgate — Charlotte	Southeast	NC	619	565	91.3
BR0002	Lakefront — Nashville	Southeast	TN	614	555	90.4
BR0039	Commons — Denver	West	CO	610	554	90.8
BR0038	Commons — Philadelphia	Northeast	PA	567	527	92.9
BR0013	Southpoint — Boston	Northeast	MA	582	522	89.7
BR0021	Northpoint — Cleveland	Midwest	OH	556	506	91
BR0005	Northpoint — Los Angeles	West	CA	569	506	88.9
BR0020	Westside — Chicago	Midwest	IL	550	498	90.5
BR0009	Riverside — Dallas	South	TX	537	486	90.5
BR0004	Northpoint — Philadelphia	Northeast	PA	533	480	90.1
BR0040	Plaza — Seattle	West	WA	535	471	88
BR0010	Downtown — Chicago	Midwest	IL	511	460	90
BR0012	Heights — Seattle	West	WA	506	457	90.3
BR0033	Crossing — Detroit	Midwest	MI	505	456	90.3
BR0043	Harbor — Philadelphia	Northeast	PA	495	450	90.9
BR0006	Southpoint — Houston	South	TX	488	449	92
BR0015	Central — Minneapolis	Midwest	MN	485	446	92
BR0011	Westside — Dallas	South	TX	488	441	90.4
BR0003	Westside — Los Angeles	West	CA	481	435	90.4
BR0044	Southpoint — San Francisco	West	CA	464	423	91.2
BR0030	Harbor — Portland	West	OR	439	399	90.9
BR0023	Commons — Los Angeles	West	CA	426	389	91.3
BR0035	Harbor — Seattle	West	WA	424	383	90.3
BR0008	Northpoint — Atlanta	Southeast	GA	435	380	87.4
BR0026	Lakefront — Newark	Northeast	NJ	389	365	93.8
BR0037	Westside — San Francisco	West	CA	399	362	90.7
BR0014	Riverside — Nashville	Southeast	TN	385	348	90.4
BR0034	Commons — Miami	Southeast	FL	388	346	89.2
BR0022	Court — Portland	West	OR	350	323	92.3
BR0001	Riverside — Portland	West	OR	342	311	90.9
BR0017	Central — Nashville	Southeast	TN	279 242	86.7		
*/


--- Branch deposit balances and account composition


WITH branch_accounts AS (
    SELECT
        br.branch_id,
        br.branch_name,
        br.region,
        br.state,
        a.account_id,
        a.account_type,
        a.current_balance
    FROM nexus_banking.branches br
	
    LEFT JOIN nexus_banking.bankers ba
    ON br.branch_id = ba.home_branch_id
    LEFT JOIN nexus_banking.customers cu
    ON ba.banker_id = cu.onboarded_by_banker_id
    LEFT JOIN nexus_banking.accounts a
    ON cu.customer_id = a.customer_id
    AND a.status = 'active'
)
SELECT
    branch_id,
    branch_name,
    region,
    state,
    COUNT(account_id) AS total_active_accounts,
    COALESCE(ROUND(SUM(current_balance) / 100.0, 2), 0) AS total_deposits,
    COALESCE(ROUND(AVG(current_balance) / 100.0, 2), 0) AS avg_balance_per_account,
    COUNT(account_id) FILTER (WHERE account_type = 'checking') AS checking_accounts,
    COUNT(account_id) FILTER (WHERE account_type = 'savings') AS savings_accounts,
    COUNT(account_id) FILTER (WHERE account_type = 'money_market') AS money_market_accounts,
    COUNT(account_id) FILTER (WHERE account_type NOT IN ('checking', 'savings', 'money_market')) AS other_accounts,
    RANK() OVER (ORDER BY SUM(current_balance) DESC) AS deposit_rank
FROM branch_accounts

GROUP BY branch_id, branch_name, region, state

ORDER BY total_deposits DESC;

/*
Query Results 45 rows
branch_id	branch_name	region	state	total_active_accounts	total_deposits	avg_balance_per_account	checking_accounts	savings_accounts	money_market_accounts	other_accounts	deposit_rank
BR0007	Central — New York	Northeast	NY	1,955	1,898,532.52	971.12	887	479	300	289	1
BR0016	Westside — Chicago	Midwest	IL	1,630	1,590,653.1	975.86	711	437	246	236	2
BR0036	Eastgate — Minneapolis	Midwest	MN	1,621	1,570,659.11	968.94	722	414	243	242	3
BR0019	Southpoint — Boston	Northeast	MA	1,483	1,446,031.61	975.07	661	370	228	224	4
BR0025	Crossing — Atlanta	Southeast	GA	1,440	1,415,111.92	982.72	643	367	220	210	5
BR0031	Midtown — Austin	South	TX	1,443	1,390,375.18	963.53	648	353	217	225	6
BR0045	Southpoint — Boston	Northeast	MA	1,482	1,385,269.93	934.73	646	390	209	237	7
BR0028	Crossing — Austin	South	TX	1,486	1,364,540.47	918.26	682	387	204	213	8
BR0042	Crossing — Austin	South	TX	1,313	1,356,678.33	1,033.27	585	332	204	192	9
BR0024	Park — San Francisco	West	CA	1,393	1,344,663	965.3	634	333	221	205	10
BR0029	Riverside — New York	Northeast	NY	1,316	1,297,811.44	986.18	574	344	203	195	11
BR0039	Commons — Denver	West	CO	1,262	1,275,512.92	1,010.71	600	308	161	193	12
BR0038	Commons — Philadelphia	Northeast	PA	1,209	1,196,823.5	989.93	541	306	179	183	13
BR0041	Eastgate — Charlotte	Southeast	NC	1,252	1,194,798.53	954.31	576	320	178	178	14
BR0002	Lakefront — Nashville	Southeast	TN	1,243	1,194,023.32	960.6	582	291	183	187	15
BR0027	Westside — Houston	South	TX	1,284	1,179,774.99	918.83	589	297	196	202	16
BR0032	Central — Phoenix	West	AZ	1,240	1,171,484.07	944.75	544	319	186	191	17
BR0013	Southpoint — Boston	Northeast	MA	1,150	1,161,685.87	1,010.16	533	302	145	170	18
BR0020	Westside — Chicago	Midwest	IL	1,119	1,122,689.52	1,003.3	484	300	171	164	19
BR0018	Commons — Portland	West	OR	1,269	1,120,593.52	883.05	613	298	179	179	20
BR0005	Northpoint — Los Angeles	West	CA	1,160	1,089,642.82	939.35	553	261	176	170	21
BR0021	Northpoint — Cleveland	Midwest	OH	1,125	1,072,944.41	953.73	508	255	185	177	22
BR0009	Riverside — Dallas	South	TX	1,102	1,050,740.11	953.48	497	267	161	177	23
BR0040	Plaza — Seattle	West	WA	1,063	1,042,803.39	981	478	253	165	167	24
BR0010	Downtown — Chicago	Midwest	IL	1,076	1,039,501.1	966.08	471	276	178	151	25
BR0004	Northpoint — Philadelphia	Northeast	PA	1,076	1,024,987.01	952.59	499	278	144	155	26
BR0012	Heights — Seattle	West	WA	1,058	1,023,248.36	967.15	486	246	180	146	27
BR0043	Harbor — Philadelphia	Northeast	PA	990	990,698.71	1,000.71	407	258	154	171	28
BR0015	Central — Minneapolis	Midwest	MN	998	971,595.95	973.54	431	263	154	150	29
BR0033	Crossing — Detroit	Midwest	MI	1,009	967,336.05	958.71	475	230	161	143	30
BR0044	Southpoint — San Francisco	West	CA	968	937,966.05	968.97	449	238	138	143	31
BR0011	Westside — Dallas	South	TX	976	928,181.29	951.01	454	248	134	140	32
BR0023	Commons — Los Angeles	West	CA	909	890,437.21	979.58	424	227	122	136	33
BR0003	Westside — Los Angeles	West	CA	960	884,231.09	921.07	436	240	142	142	34
BR0008	Northpoint — Atlanta	Southeast	GA	867	883,204.79	1,018.69	380	218	135	134	35
BR0006	Southpoint — Houston	South	TX	975	878,522.6	901.05	407	269	148	151	36
BR0030	Harbor — Portland	West	OR	891	846,889.35	950.49	390	216	155	130	37
BR0035	Harbor — Seattle	West	WA	864	808,498.88	935.76	404	180	144	136	38
BR0014	Riverside — Nashville	Southeast	TN	779	757,208.81	972.03	373	195	129	82	39
BR0037	Westside — San Francisco	West	CA	829	751,632.81	906.67	379	211	110	129	40
BR0034	Commons — Miami	Southeast	FL	765	742,429.13	970.5	324	191	113	137	41
BR0026	Lakefront — Newark	Northeast	NJ	803	724,379.37	902.09	357	177	124	145	42
BR0022	Court — Portland	West	OR	716	708,040.64	988.88	332	177	100	107	43
BR0001	Riverside — Portland	West	OR	654	587,981.54	899.05	278	169	103	104	44
BR0017	Central — Nashville	Southeast	TN	543	541,704.92	997.61	247	154	66	76	45
*/


--- Loan origination volume by branch in 2024


WITH branch_loans AS (
    SELECT 
        br.branch_id,
        br.branch_name,
        br.region,
        br.state,
        l.loan_id,
        l.principal,
        l.status
    FROM nexus_banking.branches br
	
    LEFT JOIN nexus_banking.bankers ba
	ON br.branch_id = ba.home_branch_id
    LEFT JOIN nexus_banking.customers cu
	ON ba.banker_id = cu.onboarded_by_banker_id
    LEFT JOIN nexus_banking.loans l
	ON cu.customer_id = l.customer_id
    AND EXTRACT(YEAR FROM l.origination_date) = 2024 
)
SELECT 
    branch_id,
    branch_name,
    region,
    state,
    COUNT(loan_id) AS loans_originated,
    COALESCE(ROUND(SUM(principal) / 100.0, 2), 0) AS total_principal_originated,
    COALESCE(ROUND(AVG(principal) / 100.0, 2), 0) AS avg_loan_size,
    COUNT(loan_id) FILTER (WHERE status = 'default') AS currently_in_default,
    ROUND(
        100.0 * COUNT(loan_id) FILTER (WHERE status = 'default') 
        / NULLIF(COUNT(loan_id), 0),
        1
    ) AS default_rate_pct,
    RANK() OVER (ORDER BY COALESCE(SUM(principal), 0) DESC) AS origination_rank
FROM branch_loans

GROUP BY branch_id, branch_name, region, state

ORDER BY total_principal_originated DESC;

/*
Query Results 45 rows
branch_id	branch_name	region	state	loans_originated	total_principal_originated	avg_loan_size	currently_in_default	default_rate_pct	origination_rank
BR0045	Southpoint — Boston	Northeast	MA	226	2,344,906.81	10,375.69	23	10.2	1
BR0007	Central — New York	Northeast	NY	287	2,314,207.77	8,063.44	20	7	2
BR0036	Eastgate — Minneapolis	Midwest	MN	206	2,181,184.15	10,588.27	13	6.3	3
BR0042	Crossing — Austin	South	TX	197	2,085,741.76	10,587.52	13	6.6	4
BR0025	Crossing — Atlanta	Southeast	GA	203	2,065,861.4	10,176.66	16	7.9	5
BR0027	Westside — Houston	South	TX	178	1,978,022.07	11,112.48	18	10.1	6
BR0024	Park — San Francisco	West	CA	188	1,943,124.35	10,335.77	19	10.1	7
BR0031	Midtown — Austin	South	TX	215	1,943,025.92	9,037.33	19	8.8	8
BR0019	Southpoint — Boston	Northeast	MA	197	1,931,337.28	9,803.74	17	8.6	9
BR0020	Westside — Chicago	Midwest	IL	158	1,891,883.53	11,973.95	12	7.6	10
BR0016	Westside — Chicago	Midwest	IL	214	1,862,940.26	8,705.33	16	7.5	11
BR0028	Crossing — Austin	South	TX	206	1,801,372.73	8,744.53	19	9.2	12
BR0029	Riverside — New York	Northeast	NY	165	1,801,261.25	10,916.73	14	8.5	13
BR0038	Commons — Philadelphia	Northeast	PA	168	1,735,736.99	10,331.77	18	10.7	14
BR0044	Southpoint — San Francisco	West	CA	152	1,679,376.64	11,048.53	12	7.9	15
BR0013	Southpoint — Boston	Northeast	MA	184	1,629,295.74	8,854.87	13	7.1	16
BR0040	Plaza — Seattle	West	WA	160	1,619,912.07	10,124.45	21	13.1	17
BR0039	Commons — Denver	West	CO	177	1,617,526.3	9,138.57	15	8.5	18
BR0005	Northpoint — Los Angeles	West	CA	164	1,616,309.89	9,855.55	13	7.9	19
BR0033	Crossing — Detroit	Midwest	MI	159	1,580,295.11	9,938.96	14	8.8	20
BR0018	Commons — Portland	West	OR	182	1,557,041.15	8,555.17	11	6	21
BR0006	Southpoint — Houston	South	TX	141	1,535,204.36	10,887.97	14	9.9	22
BR0002	Lakefront — Nashville	Southeast	TN	167	1,503,822.47	9,004.92	16	9.6	23
BR0009	Riverside — Dallas	South	TX	154	1,495,417.56	9,710.5	15	9.7	24
BR0012	Heights — Seattle	West	WA	165	1,399,111.98	8,479.47	12	7.3	25
BR0015	Central — Minneapolis	Midwest	MN	127	1,390,237.61	10,946.75	10	7.9	26
BR0035	Harbor — Seattle	West	WA	129	1,361,559.63	10,554.73	11	8.5	27
BR0003	Westside — Los Angeles	West	CA	145	1,339,069.19	9,234.96	13	9	28
BR0043	Harbor — Philadelphia	Northeast	PA	137	1,329,564.83	9,704.85	14	10.2	29
BR0021	Northpoint — Cleveland	Midwest	OH	144	1,312,155.89	9,112.19	13	9	30
BR0041	Eastgate — Charlotte	Southeast	NC	151	1,300,675.67	8,613.75	10	6.6	31
BR0008	Northpoint — Atlanta	Southeast	GA	107	1,247,230.3	11,656.36	12	11.2	32
BR0023	Commons — Los Angeles	West	CA	142	1,229,075.03	8,655.46	10	7	33
BR0032	Central — Phoenix	West	AZ	153	1,227,546.64	8,023.18	12	7.8	34
BR0010	Downtown — Chicago	Midwest	IL	126	1,216,044.1	9,651.14	6	4.8	35
BR0011	Westside — Dallas	South	TX	128	1,100,543.66	8,598	12	9.4	36
BR0030	Harbor — Portland	West	OR	119	1,093,711.94	9,190.86	8	6.7	37
BR0037	Westside — San Francisco	West	CA	107	1,063,009.92	9,934.67	13	12.1	38
BR0026	Lakefront — Newark	Northeast	NJ	112	1,048,130.8	9,358.31	4	3.6	39
BR0001	Riverside — Portland	West	OR	101	958,445.86	9,489.56	6	5.9	40
BR0034	Commons — Miami	Southeast	FL	94	954,134.19	10,150.36	6	6.4	41
BR0014	Riverside — Nashville	Southeast	TN	106	858,229.28	8,096.5	11	10.4	42
BR0022	Court — Portland	West	OR	93	825,479.03	8,876.12	5	5.4	43
BR0004	Northpoint — Philadelphia	Northeast	PA	111	797,200.7	7,181.99	10	9	44
BR0017	Central — Nashville	Southeast	TN	76	619,596.55	8,152.59	4	5.3	45
*/


--- Branch transaction volume and channel mix


WITH branch_transactions AS (
    SELECT 
        br.branch_id,
        br.branch_name,
        br.region,
        br.state,
        t.transaction_id,
        t.amount,
        t.channel
    FROM nexus_banking.branches br
	
    LEFT JOIN nexus_banking.bankers ba
	ON br.branch_id = ba.home_branch_id
    LEFT JOIN nexus_banking.customers cu
	ON ba.banker_id = cu.onboarded_by_banker_id
    LEFT JOIN nexus_banking.accounts a
	ON cu.customer_id = a.customer_id
    LEFT JOIN nexus_banking.transactions t
	ON a.account_id = t.account_id
	AND EXTRACT(YEAR FROM t.transaction_date) = 2024
)
SELECT 
    branch_id,
    branch_name,
    region,
    state,
    COUNT(transaction_id) AS total_transactions,
    COALESCE(ROUND(SUM(amount) / 100.0, 2), 0) AS total_dollar_volume,
    COUNT(transaction_id) FILTER (WHERE channel = 'branch') AS branch_channel_transactions,
    COUNT(transaction_id) FILTER (WHERE channel = 'online') AS online_channel_transactions,
    COUNT(transaction_id) FILTER (WHERE channel NOT IN ('branch', 'online')) AS other_channel_transactions,
    ROUND(
        100.0 * COUNT(transaction_id) FILTER (WHERE channel = 'branch') 
        / NULLIF(COUNT(transaction_id), 0),
        1
    ) AS branch_pct,
    ROUND(
        100.0 * COUNT(transaction_id) FILTER (WHERE channel = 'online') 
        / NULLIF(COUNT(transaction_id), 0),
        1
    ) AS online_pct,
    ROUND(
        100.0 * COUNT(transaction_id) FILTER (WHERE channel NOT IN ('branch', 'online')) 
        / NULLIF(COUNT(transaction_id), 0),
        1
    ) AS onther_pct,
    RANK() OVER (ORDER BY COUNT(transaction_id) DESC) AS transaction_rank,
    CASE 
        WHEN ROUND(
            100.0 * COUNT(transaction_id) FILTER (WHERE channel = 'branch') 
            / NULLIF(COUNT(transaction_id), 0),
            1
        ) < 30 THEN 'Digital Dominant'
        WHEN ROUND(
            100.0 * COUNT(transaction_id) FILTER (WHERE channel = 'branch') 
            / NULLIF(COUNT(transaction_id), 0),
            1
        ) < 50 THEN 'Transitioning'
        ELSE 'Branch Centric'
    END AS branch_digital_profile
	
FROM branch_transactions

GROUP BY branch_id, branch_name, region, state

ORDER BY total_transactions DESC;

/*
Query Results 45 rows
branch_id	branch_name	region	state	total_transactions	total_dollar_volume	branch_channel_transactions	online_channel_transactions	other_channel_transactions	branch_pct	online_pct	onther_pct	transaction_rank	branch_digital_profile
BR0007	Central — New York	Northeast	NY	56,434	5,776,855.95	11,330	30,920	14,184	20.1	54.8	25.1	1	Digital Dominant
BR0016	Westside — Chicago	Midwest	IL	46,728	4,740,428.79	9,271	25,631	11,826	19.8	54.9	25.3	2	Digital Dominant
BR0036	Eastgate — Minneapolis	Midwest	MN	45,991	4,646,157.81	9,216	25,349	11,426	20	55.1	24.8	3	Digital Dominant
BR0028	Crossing — Austin	South	TX	42,968	4,373,754.59	8,655	23,484	10,829	20.1	54.7	25.2	4	Digital Dominant
BR0045	Southpoint — Boston	Northeast	MA	42,905	4,383,148.18	8,507	23,592	10,806	19.8	55	25.2	5	Digital Dominant
BR0019	Southpoint — Boston	Northeast	MA	42,729	4,314,767.14	8,421	23,628	10,680	19.7	55.3	25	6	Digital Dominant
BR0031	Midtown — Austin	South	TX	42,070	4,181,418.23	8,498	23,288	10,284	20.2	55.4	24.4	7	Digital Dominant
BR0025	Crossing — Atlanta	Southeast	GA	41,590	4,119,986.79	8,359	22,842	10,389	20.1	54.9	25	8	Digital Dominant
BR0024	Park — San Francisco	West	CA	40,252	4,138,330.12	8,028	22,183	10,041	19.9	55.1	24.9	9	Digital Dominant
BR0029	Riverside — New York	Northeast	NY	37,599	3,761,452.87	7,596	20,590	9,413	20.2	54.8	25	10	Digital Dominant
BR0027	Westside — Houston	South	TX	37,575	3,845,553.28	7,490	20,700	9,385	19.9	55.1	25	11	Digital Dominant
BR0042	Crossing — Austin	South	TX	37,563	3,827,845.78	7,460	20,758	9,345	19.9	55.3	24.9	12	Digital Dominant
BR0039	Commons — Denver	West	CO	37,227	3,825,200.59	7,488	20,425	9,314	20.1	54.9	25	13	Digital Dominant
BR0041	Eastgate — Charlotte	Southeast	NC	36,842	3,691,710.67	7,483	20,293	9,066	20.3	55.1	24.6	14	Digital Dominant
BR0018	Commons — Portland	West	OR	36,828	3,711,690.27	7,343	20,358	9,127	19.9	55.3	24.8	15	Digital Dominant
BR0032	Central — Phoenix	West	AZ	36,477	3,740,595.23	7,425	20,124	8,928	20.4	55.2	24.5	16	Digital Dominant
BR0002	Lakefront — Nashville	Southeast	TN	35,290	3,601,374.55	7,044	19,412	8,834	20	55	25	17	Digital Dominant
BR0038	Commons — Philadelphia	Northeast	PA	34,250	3,461,040.26	6,778	18,932	8,540	19.8	55.3	24.9	18	Digital Dominant
BR0005	Northpoint — Los Angeles	West	CA	33,588	3,446,500.13	6,826	18,366	8,396	20.3	54.7	25	19	Digital Dominant
BR0021	Northpoint — Cleveland	Midwest	OH	32,860	3,303,832.58	6,538	18,135	8,187	19.9	55.2	24.9	20	Digital Dominant
BR0013	Southpoint — Boston	Northeast	MA	32,612	3,338,557.98	6,533	17,991	8,088	20	55.2	24.8	21	Digital Dominant
BR0009	Riverside — Dallas	South	TX	32,086	3,176,662.36	6,404	17,633	8,049	20	55	25.1	22	Digital Dominant
BR0020	Westside — Chicago	Midwest	IL	31,716	3,214,287.06	6,315	17,491	7,910	19.9	55.1	24.9	23	Digital Dominant
BR0010	Downtown — Chicago	Midwest	IL	31,151	3,177,779.07	6,213	17,117	7,821	19.9	54.9	25.1	24	Digital Dominant
BR0040	Plaza — Seattle	West	WA	31,117	3,152,660.16	6,329	17,091	7,697	20.3	54.9	24.7	25	Digital Dominant
BR0012	Heights — Seattle	West	WA	30,846	3,090,076.6	6,091	17,070	7,685	19.7	55.3	24.9	26	Digital Dominant
BR0004	Northpoint — Philadelphia	Northeast	PA	30,821	3,116,448.87	6,153	17,058	7,610	20	55.3	24.7	27	Digital Dominant
BR0033	Crossing — Detroit	Midwest	MI	29,650	3,069,182.23	5,931	16,445	7,274	20	55.5	24.5	28	Digital Dominant
BR0043	Harbor — Philadelphia	Northeast	PA	28,924	2,955,608.9	5,779	16,029	7,116	20	55.4	24.6	29	Digital Dominant
BR0015	Central — Minneapolis	Midwest	MN	28,844	2,939,832.16	5,795	15,975	7,074	20.1	55.4	24.5	30	Digital Dominant
BR0044	Southpoint — San Francisco	West	CA	28,089	2,834,314.43	5,628	15,544	6,917	20	55.3	24.6	31	Digital Dominant
BR0006	Southpoint — Houston	South	TX	27,864	2,817,939.71	5,601	15,319	6,944	20.1	55	24.9	32	Digital Dominant
BR0003	Westside — Los Angeles	West	CA	27,777	2,820,079.71	5,508	15,203	7,066	19.8	54.7	25.4	33	Digital Dominant
BR0011	Westside — Dallas	South	TX	27,553	2,820,016.17	5,531	15,088	6,934	20.1	54.8	25.2	34	Digital Dominant
BR0023	Commons — Los Angeles	West	CA	26,631	2,667,894	5,276	14,855	6,500	19.8	55.8	24.4	35	Digital Dominant
BR0008	Northpoint — Atlanta	Southeast	GA	25,706	2,591,931.02	5,143	14,256	6,307	20	55.5	24.5	36	Digital Dominant
BR0030	Harbor — Portland	West	OR	25,067	2,552,577.2	4,988	13,809	6,270	19.9	55.1	25	37	Digital Dominant
BR0035	Harbor — Seattle	West	WA	24,718	2,491,025.69	4,935	13,601	6,182	20	55	25	38	Digital Dominant
BR0037	Westside — San Francisco	West	CA	24,110	2,423,765.16	4,857	13,167	6,086	20.1	54.6	25.2	39	Digital Dominant
BR0026	Lakefront — Newark	Northeast	NJ	23,280	2,375,547.39	4,649	12,771	5,860	20	54.9	25.2	40	Digital Dominant
BR0014	Riverside — Nashville	Southeast	TN	22,977	2,369,288.6	4,541	12,617	5,819	19.8	54.9	25.3	41	Digital Dominant
BR0034	Commons — Miami	Southeast	FL	22,163	2,311,347.95	4,460	12,213	5,490	20.1	55.1	24.8	42	Digital Dominant
BR0022	Court — Portland	West	OR	20,983	2,124,009.32	4,338	11,386	5,259	20.7	54.3	25.1	43	Digital Dominant
BR0001	Riverside — Portland	West	OR	18,896	1,925,166.15	3,837	10,441	4,618	20.3	55.3	24.4	44	Digital Dominant
BR0017	Central — Nashville	Southeast	TN	15,528	1,571,988.2	3,102	8,439	3,987	20	54.3	25.7	45	Digital Dominant
*/


--- Branch composite scorecard


WITH branch_metrics AS (
    -- Active customer count by branch
    SELECT 
        br.branch_id,
        br.branch_name,
        br.region,
        br.state,
        COUNT(DISTINCT cu.customer_id) AS active_customers
    FROM nexus_banking.branches br
	
    LEFT JOIN nexus_banking.bankers ba
	ON br.branch_id = ba.home_branch_id
    LEFT JOIN nexus_banking.customers cu
	ON ba.banker_id = cu.onboarded_by_banker_id
	AND cu.is_active = TRUE
		
    GROUP BY br.branch_id, br.branch_name, br.region, br.state
),
branch_deposits AS (
    -- Total deposits by branch
    SELECT 
        br.branch_id,
        COALESCE(ROUND(SUM(a.current_balance) / 100.0, 2), 0) AS total_deposits
    FROM nexus_banking.branches br
	
    LEFT JOIN nexus_banking.bankers ba
	ON br.branch_id = ba.home_branch_id
    LEFT JOIN nexus_banking.customers cu
	ON ba.banker_id = cu.onboarded_by_banker_id
    LEFT JOIN nexus_banking.accounts a
	ON cu.customer_id = a.customer_id
	AND a.status = 'active'
		
    GROUP BY br.branch_id
),
branch_loans AS (
    -- 2024 loan origination metrics by branch
    SELECT 
        br.branch_id,
        COUNT(l.loan_id) AS loans_originated,
        COALESCE(ROUND(SUM(l.principal) / 100.0, 2), 0) AS total_loan_principal
    FROM nexus_banking.branches br
	
    LEFT JOIN nexus_banking.bankers ba
	ON br.branch_id = ba.home_branch_id
    LEFT JOIN nexus_banking.customers cu
	ON ba.banker_id = cu.onboarded_by_banker_id
    LEFT JOIN nexus_banking.loans l
	ON cu.customer_id = l.customer_id
	AND EXTRACT(YEAR FROM l.origination_date) = 2024
	
    GROUP BY br.branch_id
),
branch_transactions AS (
    -- 2024 transaction volume by branch
    SELECT 
        br.branch_id,
        COUNT(t.transaction_id) AS total_transactions
    FROM nexus_banking.branches br
	
    LEFT JOIN nexus_banking.bankers ba
	ON br.branch_id = ba.home_branch_id
    LEFT JOIN nexus_banking.customers cu
	ON ba.banker_id = cu.onboarded_by_banker_id
    LEFT JOIN nexus_banking.accounts a
	ON cu.customer_id = a.customer_id
    LEFT JOIN nexus_banking.transactions t
	ON a.account_id = t.account_id
	AND EXTRACT(YEAR FROM t.transaction_date) = 2024
	
    GROUP BY br.branch_id
),
branch_fraud AS (
    --Fraud loss by branch
    SELECT 
        br.branch_id,
        COALESCE(ROUND(SUM(f.loss_amount) / 100.0, 2), 0) AS total_fraud_loss
    FROM nexus_banking.branches br
	
    LEFT JOIN nexus_banking.bankers ba
	ON br.branch_id = ba.home_branch_id
    LEFT JOIN nexus_banking.customers cu
	ON ba.banker_id = cu.onboarded_by_banker_id
    LEFT JOIN nexus_banking.fraud_cases f
	ON cu.customer_id = f.customer_id
	AND f.case_status = 'confirmed_fraud'
	AND EXTRACT(YEAR FROM f.opened_date) = 2024
		
    GROUP BY br.branch_id
)
	-- Combine everything into final scorecard
SELECT 
    cm.branch_id,
    cm.branch_name,
    cm.region,
    cm.state,
    cm.active_customers,
    COALESCE(cd.total_deposits, 0) AS total_deposits,
    COALESCE(cl.loans_originated, 0) AS loans_originated,
    COALESCE(cl.total_loan_principal, 0) AS total_loan_principal,
    COALESCE(ct.total_transactions, 0) AS total_transactions,
    COALESCE(cf.total_fraud_loss, 0) AS total_fraud_loss,
    NTILE(4) OVER (ORDER BY COALESCE(cd.total_deposits, 0) DESC) AS deposit_quartile
FROM branch_metrics cm

LEFT JOIN branch_deposits cd
ON cm.branch_id = cd.branch_id
LEFT JOIN branch_loans cl
ON cm.branch_id = cl.branch_id
LEFT JOIN branch_transactions ct
ON cm.branch_id = ct.branch_id
LEFT JOIN branch_fraud cf
ON cm.branch_id = cf.branch_id

ORDER BY deposit_quartile, total_deposits DESC;

/*
Query Results 45 rows
branch_id	branch_name	region	state	active_customers	total_deposits	loans_originated	total_loan_principal	total_transactions	total_fraud_loss	deposit_quartile
BR0007	Central — New York	Northeast	NY	875	1,898,532.52	287	2,314,207.77	56,434	2,007.87	1
BR0016	Westside — Chicago	Midwest	IL	740	1,590,653.1	214	1,862,940.26	46,728	3,749.32	1
BR0036	Eastgate — Minneapolis	Midwest	MN	727	1,570,659.11	206	2,181,184.15	45,991	2,648.69	1
BR0019	Southpoint — Boston	Northeast	MA	666	1,446,031.61	197	1,931,337.28	42,729	3,403.05	1
BR0025	Crossing — Atlanta	Southeast	GA	649	1,415,111.92	203	2,065,861.4	41,590	2,422.35	1
BR0031	Midtown — Austin	South	TX	648	1,390,375.18	215	1,943,025.92	42,070	2,933.46	1
BR0045	Southpoint — Boston	Northeast	MA	650	1,385,269.93	226	2,344,906.81	42,905	3,244.63	1
BR0028	Crossing — Austin	South	TX	645	1,364,540.47	206	1,801,372.73	42,968	3,127.32	1
BR0042	Crossing — Austin	South	TX	593	1,356,678.33	197	2,085,741.76	37,563	2,348.01	1
BR0024	Park — San Francisco	West	CA	622	1,344,663	188	1,943,124.35	40,252	1,758.42	1
BR0029	Riverside — New York	Northeast	NY	586	1,297,811.44	165	1,801,261.25	37,599	2,451.68	1
BR0039	Commons — Denver	West	CO	554	1,275,512.92	177	1,617,526.3	37,227	3,711.06	1
BR0038	Commons — Philadelphia	Northeast	PA	527	1,196,823.5	168	1,735,736.99	34,250	2,338.59	2
BR0041	Eastgate — Charlotte	Southeast	NC	565	1,194,798.53	151	1,300,675.67	36,842	2,350.59	2
BR0002	Lakefront — Nashville	Southeast	TN	555	1,194,023.32	167	1,503,822.47	35,290	2,412.17	2
BR0027	Westside — Houston	South	TX	580	1,179,774.99	178	1,978,022.07	37,575	2,425.77	2
BR0032	Central — Phoenix	West	AZ	568	1,171,484.07	153	1,227,546.64	36,477	3,722.31	2
BR0013	Southpoint — Boston	Northeast	MA	522	1,161,685.87	184	1,629,295.74	32,612	2,380.21	2
BR0020	Westside — Chicago	Midwest	IL	498	1,122,689.52	158	1,891,883.53	31,716	2,417.56	2
BR0018	Commons — Portland	West	OR	565	1,120,593.52	182	1,557,041.15	36,828	3,105.52	2
BR0005	Northpoint — Los Angeles	West	CA	506	1,089,642.82	164	1,616,309.89	33,588	1,473.48	2
BR0021	Northpoint — Cleveland	Midwest	OH	506	1,072,944.41	144	1,312,155.89	32,860	3,706.74	2
BR0009	Riverside — Dallas	South	TX	486	1,050,740.11	154	1,495,417.56	32,086	1,145	2
BR0040	Plaza — Seattle	West	WA	471	1,042,803.39	160	1,619,912.07	31,117	2,135.36	3
BR0010	Downtown — Chicago	Midwest	IL	460	1,039,501.1	126	1,216,044.1	31,151	1,830.09	3
BR0004	Northpoint — Philadelphia	Northeast	PA	480	1,024,987.01	111	797,200.7	30,821	121.28	3
BR0012	Heights — Seattle	West	WA	457	1,023,248.36	165	1,399,111.98	30,846	2,659.02	3
BR0043	Harbor — Philadelphia	Northeast	PA	450	990,698.71	137	1,329,564.83	28,924	1,895.17	3
BR0015	Central — Minneapolis	Midwest	MN	446	971,595.95	127	1,390,237.61	28,844	2,165.84	3
BR0033	Crossing — Detroit	Midwest	MI	456	967,336.05	159	1,580,295.11	29,650	1,939.74	3
BR0044	Southpoint — San Francisco	West	CA	423	937,966.05	152	1,679,376.64	28,089	2,120.25	3
BR0011	Westside — Dallas	South	TX	441	928,181.29	128	1,100,543.66	27,553	2,181.6	3
BR0023	Commons — Los Angeles	West	CA	389	890,437.21	142	1,229,075.03	26,631	1,680.35	3
BR0003	Westside — Los Angeles	West	CA	435	884,231.09	145	1,339,069.19	27,777	1,689.25	3
BR0008	Northpoint — Atlanta	Southeast	GA	380	883,204.79	107	1,247,230.3	25,706	1,881.42	4
BR0006	Southpoint — Houston	South	TX	449	878,522.6	141	1,535,204.36	27,864	2,453.31	4
BR0030	Harbor — Portland	West	OR	399	846,889.35	119	1,093,711.94	25,067	1,018.69	4
BR0035	Harbor — Seattle	West	WA	383	808,498.88	129	1,361,559.63	24,718	256.82	4
BR0014	Riverside — Nashville	Southeast	TN	348	757,208.81	106	858,229.28	22,977	1,421.1	4
BR0037	Westside — San Francisco	West	CA	362	751,632.81	107	1,063,009.92	24,110	925.3	4
BR0034	Commons — Miami	Southeast	FL	346	742,429.13	94	954,134.19	22,163	1,491.13	4
BR0026	Lakefront — Newark	Northeast	NJ	365	724,379.37	112	1,048,130.8	23,280	1,186.88	4
BR0022	Court — Portland	West	OR	323	708,040.64	93	825,479.03	20,983	780.39	4
BR0001	Riverside — Portland	West	OR	311	587,981.54	101	958,445.86	18,896	2,319.69	4
BR0017	Central — Nashville	Southeast	TN	242	541,704.92	76	619,596.55	15,528	1,159.61	4
*/


--- Region-level YoY performance


WITH deposit AS (
    SELECT
        br.region,
        COALESCE(ROUND(SUM(a.current_balance) / 100.0, 2), 0) AS total_deposits
    FROM nexus_banking.branches br
	
    LEFT JOIN nexus_banking.bankers ba
	ON br.branch_id = ba.home_branch_id
    LEFT JOIN nexus_banking.customers cu
	ON ba.banker_id = cu.onboarded_by_banker_id
    LEFT JOIN nexus_banking.accounts a
	ON cu.customer_id = a.customer_id
	AND a.status = 'active'
	
    GROUP BY br.region
),

loan AS (
    SELECT 
        br.region,
        COALESCE(COUNT(l.loan_id) FILTER (WHERE l.origination_date >= '2023-01-01' AND l.origination_date < '2024-01-01'), 0) AS loan_originations_2023,
        COALESCE(COUNT(l.loan_id) FILTER (WHERE l.origination_date >= '2024-01-01' AND l.origination_date < '2025-01-01'), 0) AS loan_originations_2024
    FROM nexus_banking.branches br
	
    LEFT JOIN nexus_banking.bankers ba
	ON br.branch_id = ba.home_branch_id
    LEFT JOIN nexus_banking.customers cu
	ON ba.banker_id = cu.onboarded_by_banker_id
    LEFT JOIN nexus_banking.loans l
	ON cu.customer_id = l.customer_id
	
    GROUP BY br.region
),

fraud AS (
    SELECT
        br.region,
        COALESCE(ROUND(SUM(f.loss_amount) FILTER (
            WHERE f.case_status = 'confirmed_fraud'
            AND f.opened_date >= '2023-01-01' 
            AND f.opened_date < '2024-01-01'
        ) / 100.0, 2), 0) AS fraud_loss_2023,
        COALESCE(ROUND(SUM(f.loss_amount) FILTER (
            WHERE f.case_status = 'confirmed_fraud'
            AND f.opened_date >= '2024-01-01' 
            AND f.opened_date < '2025-01-01'
        ) / 100.0, 2), 0) AS fraud_loss_2024
    FROM nexus_banking.branches br
	
    LEFT JOIN nexus_banking.bankers ba
	ON br.branch_id = ba.home_branch_id
    LEFT JOIN nexus_banking.customers cu
	ON ba.banker_id = cu.onboarded_by_banker_id
    LEFT JOIN nexus_banking.fraud_cases f
	ON cu.customer_id = f.customer_id
	
    GROUP BY br.region
),

active_customers AS (
    -- Count active customers by year using onboarding_date
    SELECT 
        br.region,
        COALESCE(COUNT(DISTINCT cu.customer_id) FILTER (
            WHERE cu.is_active = TRUE 
            AND cu.onboarding_date < '2024-01-01'
        ), 0) AS active_customers_2023,
        COALESCE(COUNT(DISTINCT cu.customer_id) FILTER (
            WHERE cu.is_active = TRUE 
            AND cu.onboarding_date < '2025-01-01'
        ), 0) AS active_customers_2024
    FROM nexus_banking.branches br
	
    LEFT JOIN nexus_banking.bankers ba
	ON br.branch_id = ba.home_branch_id
    LEFT JOIN nexus_banking.customers cu
	ON ba.banker_id = cu.onboarded_by_banker_id
	
    GROUP BY br.region
)
SELECT 
    d.region,
    d.total_deposits,
    COALESCE(l.loan_originations_2023, 0) AS loan_originations_2023,
    COALESCE(l.loan_originations_2024, 0) AS loan_originations_2024,
    COALESCE(l.loan_originations_2024 - l.loan_originations_2023, 0) AS loan_yoy_change,
    ROUND(
        100.0 * (l.loan_originations_2024 - l.loan_originations_2023) / 
        NULLIF(l.loan_originations_2023, 0),
        1
    ) AS loan_yoy_pct,
    COALESCE(f.fraud_loss_2023, 0) AS fraud_loss_2023,
    COALESCE(f.fraud_loss_2024, 0) AS fraud_loss_2024,
    COALESCE(f.fraud_loss_2024 - f.fraud_loss_2023, 0) AS fraud_yoy_change,
    ROUND(
        100.0 * (f.fraud_loss_2024 - f.fraud_loss_2023) / 
        NULLIF(f.fraud_loss_2023, 0),
        1
    ) AS fraud_yoy_pct,
    -- Active customers: 2023 vs 2024 with YoY change
    COALESCE(a.active_customers_2023, 0) AS active_customers_2023,
    COALESCE(a.active_customers_2024, 0) AS active_customers_2024,
    COALESCE(a.active_customers_2024 - a.active_customers_2023, 0) AS active_customers_yoy_change,
    ROUND(
        100.0 * (a.active_customers_2024 - a.active_customers_2023) / 
        NULLIF(a.active_customers_2023, 0),
        1
    ) AS active_customers_yoy_pct
FROM deposit d

LEFT JOIN loan l
ON d.region = l.region
LEFT JOIN fraud f 
ON d.region = f.region
LEFT JOIN active_customers a 
ON d.region = a.region

ORDER BY d.total_deposits DESC;

/*
Query Results 5 rows
region	total_deposits	loan_originations_2023	loan_originations_2024	loan_yoy_change	loan_yoy_pct	fraud_loss_2023	fraud_loss_2024	fraud_yoy_change	fraud_yoy_pct	active_customers_2023	active_customers_2024	active_customers_yoy_change	active_customers_yoy_pct
West	14,483,625.65	1,918	2,177	259	13.5	9,387.31	29,355.92	19,968.61	212.7	5,592	6,768	1,176	21
Northeast	11,126,219.95	1,487	1,587	100	6.7	7,171.1	19,029.36	11,858.26	165.4	4,226	5,121	895	21.2
Midwest	8,335,379.24	1,090	1,134	44	4	5,272.74	18,457.98	13,185.24	250.1	3,152	3,833	681	21.6
South	8,148,812.98	1,041	1,219	178	17.1	6,977.14	16,614.47	9,637.33	138.1	3,187	3,842	655	20.6
Southeast	6,728,481.42	887	904	17	1.9	6,141.2	13,138.37	6,997.17	113.9	2,547	3,085	538	21.1
*/


--- Identify candidates for branch restructuring


WITH branch_metrics AS (
    SELECT 
        br.branch_id,
        br.branch_name,
        br.region,
        br.state,
        -- Active customers (current)
        COUNT(DISTINCT cu.customer_id) FILTER (WHERE cu.is_active = TRUE) AS active_customers,
        -- Retention rate: customers who have NOT churned
        ROUND(
            100.0 * COUNT(DISTINCT cu.customer_id) FILTER (WHERE cu.churn_date IS NULL) / 
            NULLIF(COUNT(DISTINCT cu.customer_id), 0),
            1
        ) AS retention_rate_pct,
        -- 2024 loan originations (dollar value)
        COALESCE(ROUND(SUM(l.principal) FILTER (WHERE l.origination_date >= '2024-01-01' AND l.origination_date < '2025-01-01') / 100.0, 2), 0) AS total_loan_principal_2024,
        -- 2024 fraud loss exposure
        COALESCE(ROUND(SUM(f.loss_amount) FILTER (WHERE f.case_status = 'confirmed_fraud' AND f.opened_date >= '2024-01-01' AND f.opened_date < '2025-01-01') / 100.0, 2), 0) AS fraud_loss_2024
    FROM nexus_banking.branches br
	
    LEFT JOIN nexus_banking.bankers ba
	ON br.branch_id = ba.home_branch_id
    LEFT JOIN nexus_banking.customers cu
	ON ba.banker_id = cu.onboarded_by_banker_id
    LEFT JOIN nexus_banking.loans l
    ON cu.customer_id = l.customer_id
	AND l.origination_date >= '2024-01-01' 
	AND l.origination_date < '2025-01-01'
    LEFT JOIN nexus_banking.fraud_cases f
	ON cu.customer_id = f.customer_id
	AND f.case_status = 'confirmed_fraud'
	AND f.opened_date >= '2024-01-01' 
	AND f.opened_date < '2025-01-01'
	
    GROUP BY br.branch_id, br.branch_name, br.region, br.state
),
thresholds AS (
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY active_customers) AS threshold_active_customers
    FROM branch_metrics
)
SELECT 
    bm.branch_name,
    bm.region,
    bm.state,
    bm.active_customers,
    bm.total_loan_principal_2024,
    bm.fraud_loss_2024,
    bm.retention_rate_pct
FROM branch_metrics bm

CROSS JOIN thresholds t

WHERE bm.active_customers <= t.threshold_active_customers  
AND bm.total_loan_principal_2024 < 5000000              
AND bm.fraud_loss_2024 > 50000                         
AND bm.retention_rate_pct < 85              
            
ORDER BY bm.active_customers ASC;

/*
Run Query
Query returned 0 rows
*/