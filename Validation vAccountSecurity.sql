-- checking for missing data
-------------------------------------------------
INSERT INTO ccep.logTable	-- ${logTable}  -- hard code in Nifi for now
select
	${period} as ReportingPeriod,
    'm_vaccountsecurity' AS TableOrView,
    'Check if any empty account_tkn_id exists' AS TestCase,
    'Empty account_tkn_id count' AS Issue,
    NULL as IssueItem,
    sum(case when account_tkn_id is null then 1 else 0 end) AS IssueItemValue,
    current_timestamp AS Runtime -- count(distinct a.account_tkn_id)
from
	ccep.m_vaccountsecurity
where
	ReportingPeriod = ${period}
group by
	ReportingPeriod
having
	sum(case when account_tkn_id is null then 1 else 0 end) > 0;

-------------------------------------------------
INSERT INTO ccep.logTable	-- ${logTable}  -- hard code in Nifi for now
select
	a.ReportingPeriod,
    'm_vaccountsecurity' AS TableOrView,
    'Check if all account has securities' AS TestCase,
    'Account without holdings' AS Issue,
    'account_tkn_id=' + a.account_tkn_id as IssueItem,
    NULL AS IssueItemValue,
    current_timestamp AS Runtime -- count(distinct a.account_tkn_id)
FROM
    (select
    	qa.*
    from
    	ccep.m_apx_quarterly_holdings qa
    		inner join
    		ccep.union_shadow_advisor_center_account a on a.account_tkn_id = qa.account_tkn_id
    where
    	a.close_date IS NULL) a

    	left join
    	ccep.m_vaccountsecurity qas on a.account_tkn_id = qas.account_tkn_id and a.ReportingPeriod = qas.ReportingPeriod
    where
    	qas.account_tkn_id is null and
    	a.ReportingPeriod = ${period};
 
-- checking to see which holdings does not have security_tkn_id
INSERT INTO ccep.logTable	-- ${logTable}  -- hard code in Nifi for now
select distinct
	ReportingPeriod,
    'm_vaccountsecurity' AS TableOrView,
    'Check if all non-cash holdings matches its security' AS TestCase,
    'Holding without security' AS Issue, 
    'SECURITY' AS IssueItem,
    CONCAT('SECURITY: ', security, '; SEC_TYPE_CODE: ', sec_type_code, '; SEDOL: ', NVL(sedol, '[NULL]'), '; CUSIP: ', NVL(cusip, '[NULL]'), '; ISIN: ', NVL(isin, '[NULL]'), '; TICKER: ', NVL(ticker, '[NULL]')) AS IssueItemValue,
    current_timestamp AS Runtime -- count(distinct a.account_tkn_id)
from
	ccep.m_vaccountsecurity
where
	ReportingPeriod = ${period} and
	security_tkn_id is null and
	MarketWeight = MarketWeightNetCash;
 
-- verifying the grainularity of the data
INSERT INTO ccep.logTable	-- ${logTable}  -- hard code in Nifi for now
select
	ReportingPeriod,
    'm_vaccountsecurity' AS TableOrView,
    'Check if all security appear no more than once' AS TestCase,
    'Duplicate records' AS Issue, 
    NULL as IssueItem,
    concat('ReportingPeriod: ', reportingperiod, '/report_date: ', report_date, '/account_tkn_id: ', account_tkn_id, '/security_tkn_id: ', cast(security_tkn_id AS varchar(15)), ' appears ', cast(cnt AS varchar(8)), ' times') AS IssueItemValue,
    current_timestamp AS Runtime
FROM
    (select
    	report_date,
    	ReportingPeriod,
    	account_tkn_id,
    	security_tkn_id,
    	count(*) AS cnt
    from
    	ccep.m_vaccountsecurity qas
    where
    	ReportingPeriod = ${period} and
    	security_tkn_id is not null
    group by
    	report_date,
    	ReportingPeriod,
    	account_tkn_id,
    	security_tkn_id
    having
    	count(*) > 1) a;
