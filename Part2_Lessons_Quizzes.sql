USE mavenfuzzyfactory;

-- Section 7: Analysis for Channel Portfolio Management  

-- understand which marketing channels are driving most sessions and orders
-- understand user characteristics and conversion performance across channel
-- goal is to bid efficiently to maximize effectiveness of marketing budget
-- Paid marketing campaigns tend to track and measure everything; placed in sessions table
-- can track if repeat customer, what device
SELECT 
	sum(is_repeat_session) as repeat_visitors,
    count(distinct website_session_id) as total,
    sum(is_repeat_session)/count(distinct website_session_id) as pct_rept
FROM mavenfuzzyfactory.website_sessions;


-- 55. Analyzing Channel Portfolios
-- get weekly trended session volume for bsearch vs. gsearch nonbrand starting 8/22/2012 up to 11/29/2012
-- week_start_date	gsearch_sessions		bsearch_sessions
-- 2012-08-22
-- etc.

-- we can see there are brand and nonbrand utm_campaign for bsearch and gsearch, so we select nonbrand in query below this one
SELECT 
	utm_source,
    utm_campaign,
    COUNT(DISTINCT mavenfuzzyfactory.website_sessions.website_session_id)
FROM mavenfuzzyfactory.website_sessions
GROUP BY utm_source, utm_campaign;

-- 56. ASSIGNMENT: Analyzing Channel Portfolios
-- NOTE that video shows final answer with slightly different numbers in the columns
SELECT
--	YEARWEEK(created_at) AS yrwk,
    MIN(DATE(created_at)) AS week_start_date,
    COUNT(DISTINCT CASE WHEN utm_source='gsearch' THEN ws.website_session_id ELSE NULL END) AS gsearch_sessions,
    COUNT(DISTINCT CASE WHEN utm_source='bsearch' THEN ws.website_session_id ELSE NULL END) AS bsearch_sessions
FROM website_sessions ws
WHERE created_at BETWEEN '2012-08-22' AND '2012-11-29'
	AND utm_campaign='nonbrand'
GROUP BY YEARWEEK(created_at);

-- 58. ASSIGNMENT: Comparing Channel Characteristics
-- see aggregate % of traffic from mobile on bsearch nonbrand vs. gsearch nonbrand 8/22 - 11/30
-- utm_source		sessions	mobile_sessions		pct_mobile
-- bsearch			6522		562					0.0862
-- gsearch			20079		4923				0.2452
-- we can see that there is a lot less mobile on bsearch; i.e., more desktop
-- maybe we should compare converstion rates by desktop and mobile of bsearch to gsearch; perhaps we'll focus more on desktop for bsearch

SELECT
    utm_source,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN device_type='mobile' THEN ws.website_session_id ELSE NULL END) AS mobile_sessions,
    COUNT(DISTINCT CASE WHEN device_type='mobile' THEN ws.website_session_id ELSE NULL END)/COUNT(DISTINCT ws.website_session_id) AS pct_mobile
FROM website_sessions ws
WHERE created_at BETWEEN '2012-08-22' AND '2012-11-30'
	AND utm_campaign='nonbrand'
GROUP BY utm_source;

-- 60. ASSIGNMENT: Cross-Channel Bid Optimization
-- nonbrand cvr session to order for gsearch and bsearch by device type, aug 22-sept 18
-- device-type	utm_source	sessions	orders	conv_rate
-- desktop		bsearch		1161		44		0.0379
-- desktop		gsearch		3010		135		0.0449
-- mobile		bsearch		130			1		0.0077
-- mobile		gsearch		1017		13		0.0128
-- Wow, the cvr is very low on mobile; probably focus on desktop channel for orders

SELECT
    device_type,
    utm_source,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.website_session_id) AS orders,
	COUNT(DISTINCT o.website_session_id)/COUNT(DISTINCT ws.website_session_id) AS cvr 
FROM website_sessions ws
LEFT JOIN orders o
	ON o.website_session_id = ws.website_session_id
WHERE ws.created_at >'2012-08-22' 
	AND ws.created_at <'2012-09-19'
	AND utm_campaign='nonbrand'
GROUP BY device_type, utm_source;

-- 62. ASSIGNMENT: Analyzing Channel Portfolio Trends
-- pull weekly session vol for gsearch and bsearch nonbrand, by device, nov 4 - dec 22, include bsearch as % of gsearch for each device--
-- Week, g_dt_sessions, b_dt_sessions, b_pct_g_dt, g_mob_sessions, b_mob_sessions, b_pct_g_mob
-- 2012-11-04	1028	401	0.3901	325	29	0.0892
-- 2012-11-11	956		401	0.4195	290	37	0.1276
-- 2012-11-18	2655	1008 0.3797	853	85	0.0996
-- 2012-11-25	2058	843	0.4096	692	62	0.0896
-- 2012-12-02	1326	517	0.3899	396	31	0.0783
-- 2012-12-09	1277	293	0.2294	424	46	0.1085
-- 2012-12-16	1270	348	0.2740	376	41	0.1090
-- bsearch dropped more than gsearch after cybermonday/black friday

SELECT
    MIN(DATE(created_at)) as Week,
    COUNT(DISTINCT CASE WHEN (device_type='desktop' and utm_source='gsearch') THEN website_session_id ELSE NULL END) AS g_dt_sessions,
    COUNT(DISTINCT CASE WHEN (device_type='desktop' and utm_source='bsearch') THEN website_session_id ELSE NULL END) AS b_dt_sessions,
    COUNT(DISTINCT CASE WHEN (device_type='desktop' and utm_source='bsearch') THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN (device_type='desktop' and utm_source='gsearch') THEN website_session_id ELSE NULL END) AS b_pct_g_dt,

    COUNT(DISTINCT CASE WHEN (device_type='mobile' and utm_source='gsearch') THEN website_session_id ELSE NULL END) AS g_mob_sessions,
    COUNT(DISTINCT CASE WHEN (device_type='mobile' and utm_source='bsearch') THEN website_session_id ELSE NULL END) AS b_mob_sessions,
    COUNT(DISTINCT CASE WHEN (device_type='mobile' and utm_source='bsearch') THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN (device_type='mobile' and utm_source='gsearch') THEN website_session_id ELSE NULL END) AS b_pct_g_mob
FROM website_sessions ws
WHERE ws.created_at >'2012-11-04' 
	AND ws.created_at <'2012-12-22'
	AND utm_campaign='nonbrand'
GROUP BY YEARWEEK(DATE(created_at));

-- 64. Analyzing Direct, Brand-Driven Traffic 

SELECT 	
    CASE
		WHEN http_referer IS NULL THEN 'direct_type_in'
        WHEN http_referer = 'https://www.gsearch.com' AND utm_source IS NULL THEN 'gsearch_organic'
        WHEN http_referer = 'https://www.bsearch.com' AND utm_source IS NULL THEN 'bsearch_organic'
		ELSE 'other'
	END,
    COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions 
WHERE website_session_id BETWEEN 100000 AND 115000 -- arbitrary
GROUP BY 1
ORDER BY 2 DESC;

-- 65. ASSIGNMENT: Analyzing Direct Traffic
-- pull organic serach, direct type in, and paid brand serach by month, showing sessions as % of paid serach nonbrand
-- year 	month	nonbrand	brand	brand_pct_nonbrand	direct	direct_pct organic	organic % nonbrand

-- we can see direct and organic search are growing as pct of paid search, so this is very positive
SELECT
	YEAR(DATE(created_at)) AS Yr,
    MONTH(DATE(created_at)) AS Mo,
    COUNT(DISTINCT website_session_id) AS total_sessions,
    COUNT(DISTINCT CASE WHEN utm_campaign='nonbrand' THEN website_session_id ELSE NULL END) AS nonbrand,
    COUNT(DISTINCT CASE WHEN utm_campaign='brand' THEN website_session_id ELSE NULL END) AS brand,
    COUNT(DISTINCT CASE WHEN utm_campaign='brand' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN utm_campaign='nonbrand' THEN website_session_id ELSE NULL END) AS br_pct_nonbrand,
    COUNT(DISTINCT CASE WHEN (utm_campaign IS NULL and  http_referer IS NULL) THEN website_session_id ELSE NULL END) AS direct,
    COUNT(DISTINCT CASE WHEN (utm_campaign IS NULL and  http_referer IS NULL) THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN utm_campaign='nonbrand' THEN website_session_id ELSE NULL END) AS direct_as_pct_nonbrand,
    COUNT(DISTINCT CASE WHEN (utm_campaign IS NULL and  http_referer IS NOT NULL) THEN website_session_id ELSE NULL END) AS organic_search,
    COUNT(DISTINCT CASE WHEN (utm_campaign IS NULL and  http_referer IS NOT NULL) THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN utm_campaign='nonbrand' THEN website_session_id ELSE NULL END) AS organic__as_pct_nonbrand
FROM website_sessions ws
WHERE created_at < '2012-12-23'
GROUP BY Yr, Mo;

-- Section 8: Analyzing Business Patterns and Seasonality

SELECT 
	COUNT(DISTINCT website_session_id),
    HOUR(created_at) AS hr,
    WEEKDAY(created_at) AS wkday -- 0 = Mon, Sun = 6
FROM website_sessions
WHERE website_session_id BETWEEN 150000 AND 200000
GROUP BY wkday; -- , hr;

-- 68. ASSIGNMENT: Analyzing Seasonality
-- find monthly and weekly session and order volumes
-- Query 1
-- yr 	mo		sessions	orders
-- all 2012
SELECT 
    YEAR(ws.created_at) AS yr,
    MONTH(ws.created_at) AS mo,
	COUNT(DISTINCT ws.website_session_id) AS n_sessions,
	COUNT(DISTINCT o.order_id) AS n_orders
FROM website_sessions ws
	LEFT JOIN orders o
	ON ws.website_session_id = o.website_session_id  
WHERE ws.created_at < '2013-01-01'
GROUP BY yr, mo;


-- Query 2
-- yr 	mo		sessions	orders
-- beginning of week (2012)
SELECT 
 	YEAR(ws.created_at) AS yr,
 	WEEK(ws.created_at) AS wk,
    MIN(DATE(ws.created_at)) AS wk_start,
	COUNT(DISTINCT ws.website_session_id) AS n_sessions,
	COUNT(DISTINCT o.order_id) AS n_orders
FROM website_sessions ws
	LEFT JOIN orders o
	ON ws.website_session_id = o.website_session_id  
WHERE ws.created_at < '2013-01-01'
GROUP BY 1,2;


-- 70. ASSIGNMENT: Analyzing Business Patterns
-- hr weekday
-- sep 15-11/15

SELECT 
 	hr,
	ROUND(AVG(CASE WHEN wd=0 THEN n_sessions ELSE NULL END),1) AS Mon,	
    ROUND(AVG(CASE WHEN wd=1 THEN n_sessions ELSE NULL END),1) AS Tue,
    ROUND(AVG(CASE WHEN wd=2 THEN n_sessions ELSE NULL END),1) AS Wed,

    ROUND(AVG(CASE WHEN wd=3 THEN n_sessions ELSE NULL END),1) AS Thu,
    ROUND(AVG(CASE WHEN wd=4 THEN n_sessions ELSE NULL END),1) AS Fri,
    ROUND(AVG(CASE WHEN wd=5 THEN n_sessions ELSE NULL END),1) AS Sat,
    ROUND(AVG(CASE WHEN wd=6 THEN n_sessions ELSE NULL END),1) AS Sun
FROM 
	(SELECT
		DATE(created_at) AS dt, 
        WEEKDAY(created_at) AS wd,
        HOUR(created_at) AS hr,
		COUNT(DISTINCT website_session_id) AS n_sessions         
	FROM website_sessions
	WHERE created_at BETWEEN '2012-09-15' AND '2012-11-15'
	GROUP BY 1,2,3) AS daily_hourly
GROUP BY 1;

SELECT
		DATE(created_at) AS dt, 
        WEEKDAY(created_at) AS wd,
        HOUR(created_at) AS hr,
		COUNT(DISTINCT website_session_id) AS n_sessions         
	FROM website_sessions
	WHERE created_at BETWEEN '2012-09-15' AND '2012-11-15'
	GROUP BY 1,2,3;

-- Section 9: Product Analysis
-- price_usd is revenue for order in this database

-- 74. ASSIGNMENT: Product-Level Sales Analysis
-- yr 	mo 	num_sales   tot_rev	total_margin
-- up to 1/4/2013
SELECT 
 	YEAR(o.created_at) AS yr,
 	MONTH(o.created_at) AS mo,
	COUNT(DISTINCT o.order_id) AS n_sales,
	SUM(o.price_usd) AS tot_rev,
	SUM(o.price_usd-o.cogs_usd) AS tot_margin    
FROM orders o
WHERE o.created_at < '2013-01-04'
GROUP BY 1, 2;

-- 76. ASSIGNMENT: Analyzing Product Launches
-- year    	mo 		n_orders    conv_rate    rev_session      n_product1_orders     n_product2_orders
-- 4/1/2012 - 4/5/2013
SELECT 
 	YEAR(ws.created_at) AS yr,
 	MONTH(ws.created_at) AS mo,
	COUNT(DISTINCT ws.website_session_id) AS n_sessions,
	COUNT(DISTINCT o.order_id) AS n_sales,
	COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id) AS conv_rate,
    SUM(o.price_usd)/COUNT(DISTINCT ws.website_session_id) AS rev_session,
    COUNT(DISTINCT CASE WHEN o.primary_product_id = 1 THEN o.website_session_id ELSE NULL END) as n_prod1_orders,
    COUNT(DISTINCT CASE WHEN o.primary_product_id = 2 THEN o.website_session_id ELSE NULL END) as n_prod2_orders
FROM website_sessions ws
	LEFT JOIN orders o
		USING(website_session_id)
WHERE ws.created_at BETWEEN '2012-04-01' AND '2013-04-05'
GROUP BY 1, 2;

-- bulid off this query for # 78
SELECT 
	wp.pageview_url AS url,
	COUNT(DISTINCT wp.website_session_id) AS n_sessions,
	COUNT(DISTINCT o.order_id) AS n_orders,
	COUNT(DISTINCT o.order_id)/COUNT(DISTINCT wp.website_session_id) AS conv_rate
FROM website_pageviews wp
	LEFT JOIN orders o
		USING(website_session_id)
WHERE wp.pageview_url IN ('/the-forever-love-bear','/the-original-mr-fuzzy') 
	AND o.created_at BETWEEN '2013-01-06' AND '2014-04-06'
GROUP BY 1;

-- 79. ASSIGNMENT: Product-Level Website Pathing
-- how many customers are hitting products page and then do next
-- some will click thru, some will abandon
-- analyze 3 months up to launch, then 3 months after
-- time-period									n_sessions		n_sessions_w_next_page 	pct_next_page	cnt_fuzzy   pct_fuzzy cnt_bear   pct_bear
-- pre-product (3 months prior to 1/6/2014)
-- post-product (3 mo's up to 4/6/2014)

-- first session where new product love bear launched
-- IS 63562
SELECT
	MIN(wp.website_session_id)
FROM website_pageviews wp
WHERE wp.created_at < '2013-01-07'
	AND wp.pageview_url ='/the-forever-love-bear';

CREATE TEMPORARY TABLE product_sessions
SELECT 
	wp.website_session_id
FROM website_pageviews wp
WHERE wp.created_at BETWEEN '2012-10-06' AND '2013-04-06'
	AND wp.pageview_url IN ('/products'); 

CREATE TEMPORARY TABLE the_counts
SELECT
	wp.website_session_id,
    COUNT(DISTINCT wp.pageview_url) as the_count   
FROM website_pageviews wp
INNER JOIN product_sessions USING (website_session_id)
GROUP BY wp.website_session_id;

SELECT
	CASE
		WHEN wp.created_at >= '2013-01-06' THEN 'Post-launch Product 2' 
        WHEN wp.created_at < '2013-01-06' THEN 'Pre-launch Product 2'
        ELSE 'Launch'
    END as period,
	COUNT(DISTINCT CASE WHEN wp.pageview_url = '/products' THEN wp.website_session_id ELSE NULL END) AS n_sessions,
	COUNT(DISTINCT CASE WHEN tc.the_count>2 THEN tc.website_session_id ELSE NULL END) AS ctr,
	COUNT(DISTINCT CASE WHEN tc.the_count>2 THEN tc.website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN wp.pageview_url = '/products' THEN wp.website_session_id ELSE NULL END) AS pct_ctr,
	COUNT(DISTINCT CASE WHEN wp.pageview_url = '/the-original-mr-fuzzy' THEN wp.website_session_id ELSE NULL END) AS fuzzy_sessions,
	COUNT(DISTINCT CASE WHEN wp.pageview_url = '/the-original-mr-fuzzy' THEN wp.website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN wp.pageview_url = '/products' THEN wp.website_session_id ELSE NULL END) AS pct_fuzzy_sessions,
	COUNT(DISTINCT CASE WHEN wp.pageview_url = '/the-forever-love-bear' THEN wp.website_session_id ELSE NULL END) AS bear_sessions,
	COUNT(DISTINCT CASE WHEN wp.pageview_url = '/the-forever-love-bear' THEN wp.website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN wp.pageview_url = '/products' THEN wp.website_session_id ELSE NULL END) AS pct_bear_sessions
FROM website_pageviews wp
INNER JOIN the_counts tc USING (website_session_id)
WHERE wp.created_at BETWEEN '2012-10-06' AND '2013-04-06'
	AND wp.pageview_url IN ('/products','/the-forever-love-bear','/the-original-mr-fuzzy') 
GROUP BY period
ORDER BY n_sessions desc;

SELECT *
FROM website_pageviews wp
	LEFT JOIN the_counts tc USING (website_session_id)
WHERE wp.created_at BETWEEN '2012-10-06' AND '2013-04-06'
	AND wp.pageview_url IN ('/products','/the-forever-love-bear','/the-original-mr-fuzzy') 
GROUP BY period;

select
	count(distinct website_session_id) as past_prod
FROM (SELECT
	wp.website_session_id,
    COUNT(DISTINCT wp.pageview_url) as the_count   
FROM website_pageviews wp
INNER JOIN product_sessions USING (website_session_id)
GROUP BY wp.website_session_id) AS the_counts
WHERE the_count>2;

SELECT * FROM website_pageviews where website_session_id>31513;

-- 81. ASSIGNMENT: Building Product-Level Conversion Funnels
-- from jan 6 - april 10, 2013 (web shows 2014, but I think this is wrong)
-- product		n_sessions	to_cart	to_ship  to_billing   to_thankyou
-- lovebear
-- mrfuzzy

-- product		ctr_product	ctr_cart	ctr_ship  ctr_billing   
-- lovebear			
-- mrfuzzy

CREATE TEMPORARY TABLE product_ids
SELECT
	wp.website_session_id,
	CASE 
		WHEN wp.pageview_url = '/the-original-mr-fuzzy' THEN 'mrfuzzy'
        WHEN wp.pageview_url = '/the-forever-love-bear' THEN 'lovebear'
        ELSE 'oops' 
	END as product
FROM website_pageviews wp
WHERE wp.created_at BETWEEN '2013-01-06' AND '2013-04-10'
	AND wp.pageview_url IN ('/the-forever-love-bear','/the-original-mr-fuzzy');

SELECT
	wp.website_session_id,
    wp.pageview_url 
FROM website_pageviews wp
WHERE wp.created_at BETWEEN '2013-01-06' AND '2013-04-10';

CREATE TEMPORARY TABLE funnels
SELECT
	pd.product, 
    COUNT(DISTINCT wp.website_session_id) AS n_sessions,
	COUNT(DISTINCT CASE WHEN wp.pageview_url = '/cart' THEN wp.website_session_id ELSE NULL END) AS to_cart,
	COUNT(DISTINCT CASE WHEN wp.pageview_url = '/shipping' THEN wp.website_session_id ELSE NULL END) AS to_shipping,
	COUNT(DISTINCT CASE WHEN wp.pageview_url = '/billing-2' THEN wp.website_session_id ELSE NULL END) AS to_billing,
	COUNT(DISTINCT CASE WHEN wp.pageview_url = '/thank-you-for-your-order' THEN wp.website_session_id ELSE NULL END) AS to_thankyou
FROM website_pageviews wp
	INNER JOIN product_ids pd USING (website_session_id)
GROUP BY product;

select * from funnels;

SELECT
	f.product, 
    f.to_cart/f.n_sessions AS product_ctr,
    f.to_shipping/f.to_cart AS cart_ctr,
    f.to_billing/f.to_shipping AS shipping_ctr,
    f.to_thankyou/f.to_billing AS billing_ctr
FROM funnels f
GROUP BY product;


-- 83. Cross-Selling & Product Portfolio Analysis
-- if is_primary_item=0, then item is a cross sell
Select * from order_items;

SELECT
	o.primary_product_id, 
--	oi.product_id AS x_sell_product,
    COUNT(DISTINCT o.order_id) AS n_orders,
    COUNT(DISTINCT CASE WHEN oi.product_id=1 THEN o.order_id ELSE NULL END) AS x_sell1,
    COUNT(DISTINCT CASE WHEN oi.product_id=2 THEN o.order_id ELSE NULL END) AS x_sell2,
    COUNT(DISTINCT CASE WHEN oi.product_id=3 THEN o.order_id ELSE NULL END) AS x_sell3,
    COUNT(DISTINCT CASE WHEN oi.product_id=1 THEN o.order_id ELSE NULL END)/COUNT(DISTINCT o.order_id) AS x_sell1_rt,
    COUNT(DISTINCT CASE WHEN oi.product_id=2 THEN o.order_id ELSE NULL END)/COUNT(DISTINCT o.order_id) AS x_sell2_rt,
    COUNT(DISTINCT CASE WHEN oi.product_id=3 THEN o.order_id ELSE NULL END)/COUNT(DISTINCT o.order_id) AS x_sell3_rt
FROM orders o
	LEFT JOIN order_items oi  
    ON oi.order_id=o.order_id
		AND oi.is_primary_item=0 -- cross sell only
WHERE o.order_id BETWEEN 10000 AND 11000
GROUP BY 1;


-- 84. ASSIGNMENT: Cross-Sell Analysis
-- if items_purchased>1, then cross-sell happened
-- 2013-09-25, could add two products to cart
-- compare month prior w month after this change

-- 				CTR from /cart		avg_proudcts_per_order		AOV		rev_cart_view 
-- pre-change
-- post-change

DROP TEMPORARY TABLE xsell_analysis;
CREATE TEMPORARY TABLE xsell_analysis
SELECT
	CASE 
		WHEN wp.created_at >='2013-09-25' THEN 'post-change'
		WHEN wp.created_at <'2013-09-25' THEN 'pre-change'
        ELSE 'chack'
	END AS period,
	COUNT(DISTINCT CASE WHEN wp.pageview_url = '/cart' THEN wp.website_session_id ELSE NULL END) AS to_cart,
	COUNT(DISTINCT CASE WHEN wp.pageview_url = '/shipping' THEN wp.website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN wp.pageview_url = '/cart' THEN wp.website_session_id ELSE NULL END) AS cart_ctr	
FROM website_pageviews wp
WHERE wp.created_at BETWEEN '2013-08-25' AND '2013-10-25'
GROUP BY 1;
DROP TEMPORARY TABLE order_analysis;

CREATE TEMPORARY TABLE order_analysis
SELECT
	CASE 
		WHEN o.created_at >='2013-09-25' THEN 'post-change'
		WHEN o.created_at <'2013-09-25' THEN 'pre-change'
        ELSE 'chack'
	END AS period,
	COUNT(DISTINCT o.order_id) AS n_orders,
	SUM(o.items_purchased) AS n_prodx,
	SUM(o.items_purchased)/COUNT(DISTINCT o.order_id) AS avg_prodx_per_order,
    SUM(o.price_usd) AS revenue
FROM orders o 
WHERE o.created_at BETWEEN '2013-08-25' AND '2013-10-25'
GROUP BY 1;

SELECT
	period,
    to_cart,
	cart_ctr,
    n_orders,
    avg_prodx_per_order,
    revenue/n_orders AS aov,
    revenue/to_cart AS rev_cart_view
FROM xsell_analysis
	INNER JOIN order_analysis USING (period);

SELECT
	COUNT(DISTINCT o.order_id) AS n_orders,
	SUM(o.items_purchased) AS n_prodx,
	SUM(o.items_purchased)/COUNT(DISTINCT o.order_id) AS avg_prodx_per_order,
    SUM(o.price_usd)
FROM orders o 
WHERE o.created_at BETWEEN '2013-08-25' AND '2013-10-25';
 

-- 86. ASSIGNMENT: Product Portfolio Expansion
-- third product luanched 12/12/2013
-- 			session_to_order_conv_rate		prodx_order		rev_session
-- pre
-- post
-- 	period
    
-- FROM (

SELECT
    CASE 
		WHEN ws.created_at >='2013-12-12' THEN 'post-change'
		WHEN ws.created_at <'2013-12-12' THEN 'pre-change'
		ELSE 'chack'
	END as period,
	COUNT(DISTINCT ws.website_session_id) AS n_sessions,
	COUNT(DISTINCT o.order_id) AS n_orders,
	COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id) AS cvr_rate,
	SUM(o.price_usd) as revenue,
	sum(o.items_purchased) as products_purchased,
	sum(o.items_purchased)/COUNT(DISTINCT o.order_id) AS productsp_order,
	sum(o.price_usd)/COUNT(DISTINCT o.order_id) as AOV,
	sum(o.price_usd)/COUNT(DISTINCT ws.website_session_id) rev_session   
FROM website_sessions ws
		LEFT JOIN orders o USING (website_session_id) 
WHERE ws.created_at BETWEEN '2013-11-12' AND '2014-01-12'
GROUP BY 1;

-- 90. SOLUTION: Analyzing Product Refund Rates
 -- replaced 9/16/2014
 -- monthly refund rates from august 2014 by product
 
--  year 	month  p1_orders  p1_refund p1_refund_rt  p2_orders  p2_refunds  p2_refund_rt  p3_orders  p3_refund p3_refund_rt  p4_orders  p4_refund p4_refund_rt

DROP TEMPORARY TABLE refund_analysis;

CREATE TEMPORARY TABLE refund_analysis
SELECT 
	YEAR(oi.created_at) AS yr,
    MONTH(oi.created_at) AS mo,
    oi.order_item_id as order_item_id,
    ref.order_item_id AS refund_item_id,
    oi.product_id as product 
FROM order_items oi 
	LEFT JOIN order_item_refunds ref USING (order_item_id)
WHERE oi.created_at BETWEEN '2013-09-01' AND '2014-10-15';

SELECT 
	yr,
    mo,
--    COUNT(DISTINCT ra.order_id) AS n_orders,
    COUNT(DISTINCT CASE WHEN product=1 THEN ra.order_item_id ELSE NULL END) as prod1_order,
    COUNT(DISTINCT CASE WHEN product=1 THEN ra.refund_item_id ELSE NULL END) as prod1_refund,
    COUNT(DISTINCT CASE WHEN product=1 THEN ra.refund_item_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN product=1 THEN ra.order_item_id ELSE NULL END) as prod1_ref_rt,

    COUNT(DISTINCT CASE WHEN product=2 THEN ra.order_item_id  ELSE NULL END) as prod2_order,
    COUNT(DISTINCT CASE WHEN product=2 THEN ra.refund_item_id ELSE NULL END) as prod2_refund,
    COUNT(DISTINCT CASE WHEN product=2 THEN ra.refund_item_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN product=2 THEN ra.order_item_id ELSE NULL END) as prod2_ref_rt,

    COUNT(DISTINCT CASE WHEN product=3 THEN ra.order_item_id  ELSE NULL END) as prod3_order,
    COUNT(DISTINCT CASE WHEN product=3 THEN ra.refund_item_id ELSE NULL END) as prod3_refund,
    COUNT(DISTINCT CASE WHEN product=3 THEN ra.refund_item_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN product=3 THEN ra.order_item_id ELSE NULL END) as prod3_ref_rt,
    COUNT(DISTINCT CASE WHEN product=4 THEN ra.order_item_id  ELSE NULL END) as prod4_order,
    COUNT(DISTINCT CASE WHEN product=4 THEN ra.refund_item_id ELSE NULL END) as prod4_refund,
    COUNT(DISTINCT CASE WHEN product=4 THEN ra.refund_item_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN product=4 THEN ra.order_item_id ELSE NULL END) as prod4_ref_rt
FROM refund_analysis ra
GROUP BY 1,2;

-- -------------------------- -------------------------- -------------------------- -------------------------- -------------------------- 
-- Last part before Final project
-- -------------------------- -------------------------- -------------------------- -------------------------- -------------------------- 
-- 93. ASSIGNMENT: Identifying Repeat Visitors
-- 2014 to 11/1/2014
-- # visitors with repeat sessions (note these aren't necessarily customers)
-- repeat_sessions 		n_users
-- answers below:
-- 0	126804
-- 1	14084
-- 2	316			kind of strange that 2 repeat visits drop off a lot and goes up again for 3 repeats
-- 3	4685		overall, there is over 10% of users that come back 1 or more times

DROP TEMPORARY TABLE repeats;

CREATE TEMPORARY TABLE repeats
SELECT
	new_sessions.user_id,
    new_sessions.website_session_id AS new_session_id,
    ws.website_session_id  AS repeat_sessions
FROM (SELECT
	user_id,
    website_session_id
    FROM website_sessions
	WHERE created_at BETWEEN '2014-01-01' AND '2014-11-01'
		AND is_repeat_session=0) AS new_sessions
	LEFT JOIN website_sessions ws 
		ON ws.user_id = new_sessions.user_id
        AND ws.is_repeat_session = 1
        AND ws.website_session_id > new_sessions.website_session_id        
		AND ws.created_at BETWEEN '2014-01-01' AND '2014-11-01';

SELECT
    rpts,
	COUNT(DISTINCT user_id) AS ids
FROM (SELECT
	COUNT(DISTINCT repeat_sessions) AS rpts,
    user_id 
FROM repeats
GROUP BY user_id) AS test
GROUP BY 1;

-- 95. ASSIGNMENT: Analyzing Time to Repeat 
-- avg_days_first_to_2nd		min_days_first_to_2nd		max_days_first_to_2nd		
-- 01-01-2014 till 11/3/2014
DROP TEMPORARY TABLE waits;

CREATE TEMPORARY TABLE waits 
SELECT
	new_sessions.user_id,
    new_sessions.website_session_id AS new_session_id,
	new_sessions.created_at AS first_date,
    ws.website_session_id  AS repeat_sessions,
	ws.created_at AS repeat_date,
	DATEDIFF(ws.created_at,new_sessions.created_at) AS wait_days
FROM (SELECT
	user_id,
    created_at,
    website_session_id
    FROM website_sessions
	WHERE created_at BETWEEN '2014-01-01' AND '2014-11-03'
		AND is_repeat_session=0) AS new_sessions
	LEFT JOIN website_sessions ws 
		ON ws.user_id = new_sessions.user_id
        AND ws.is_repeat_session = 1
        AND ws.created_at > new_sessions.website_session_id        
		AND ws.created_at >= '2014-01-01' 
        AND ws.created_at < '2014-11-03'
	WHERE ws.website_session_id IS NOT NULL;

SELECT
	AVG(wait_1st_to_2nd) AS avg_1st_to_2nd,
	min(wait_1st_to_2nd) AS min_1st_to_2nd,
	max(wait_1st_to_2nd) AS max_1st_to_2nd    
FROM (SELECT
	user_id,
    MIN(wait_days) AS wait_1st_to_2nd
FROM waits
GROUP BY user_id) AS the_waits;

-- 97. ASSIGNMENT: Analyzing Repeat Channel Behavior
-- channel_group		newsessions		repeatsessions

-- NOTE, the following may have repeat sessions that have origination prior to 1/1/2014; we don't filter out
-- to include only repeats that have new sessiosn in the new year
SELECT
-- 	utm_source,
-- 	utm_campaign,
-- 	http_referer,
    CASE
		WHEN http_referer IS NULL THEN 'direct_type_in'
        WHEN http_referer = 'https://www.gsearch.com' AND utm_source IS NULL THEN 'search_organic'
        WHEN http_referer = 'https://www.gsearch.com' AND utm_campaign='brand' THEN 'paid_brand'
        WHEN http_referer = 'https://www.gsearch.com' AND utm_campaign='nonbrand' THEN 'paid_nonbrand'
        WHEN http_referer = 'https://www.bsearch.com' AND utm_source IS NULL THEN 'search_organic'
        WHEN http_referer = 'https://www.bsearch.com' AND utm_campaign='brand' THEN 'paid_brand'
        WHEN http_referer = 'https://www.bsearch.com' AND utm_campaign='nonbrand' THEN 'paid_nonbrand'
        WHEN utm_source= 'socialbook' THEN 'paid_social'        
		ELSE 'other' 
	END AS channel,
    COUNT(CASE WHEN is_repeat_session=0 THEN website_session_id ELSE NULL END) AS new_sessions,
    COUNT(CASE WHEN is_repeat_session=1 THEN website_session_id ELSE NULL END) AS repeat_sessions    
FROM website_sessions ws
WHERE created_at >= '2014-01-01' 
        AND created_at < '2014-11-05'
GROUP BY 1
ORDER BY 3 DESC;

-- 99. ASSIGNMENT: Analyzing New & Repeat Conversion Rates
-- is_repeat		sessions	conv_rate	rev_per_session
-- 0
-- 1
SELECT
	ws.is_repeat_session,
    COUNT(DISTINCT ws.website_session_id) AS n_sessions,
    COUNT(DISTINCT o.website_session_id)/COUNT(DISTINCT ws.website_session_id) AS conv_rate,
    SUM(o.price_usd)/COUNT(DISTINCT ws.website_session_id) AS rev_per_session
FROM website_sessions ws
	LEFT JOIN orders o
		ON ws.website_session_id = o.website_session_id
WHERE ws.created_at >= '2014-01-01' 
        AND ws.created_at < '2014-11-08'
GROUP BY 1;
