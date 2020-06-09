/*  MIDCOURSE PROJECT
Advanced SQL + MySQL for Analytics & Business Intelligence
started April 30, 2020
1.	Gsearch seems to be the biggest driver of business.  Pull monthly trends for gsearch sessions and orders
2.	Do same gsearch monthly trend but by nonbrand and brand campagins separately, to see if brand is growing
3.	Pull Nonbrand monthly sessions and orders, split by device type
4.	Pull monthly trends for gsearch alongside trends for other channels (showing comparative growth)
5.	Show website performance improvements over the course of the first 8 months:  
	Find session to order conversion rates, by month.
6.	For gsearch lander test, estimate the rev that test earned (look at increase in CVR from test June 19-Jul 28 
	and use nonbrand sessions and revenue since then to calculate incremental value.
7.	For landing page test analyzed previously, show a full conversion funnel from each of the two pages to orders.  
	Use same time period Jun 19-Jul 28.
    
8.	Quantify impact of billing test.  Analyze lift generated from the test (Sep 10 – Nov 10), in terms of 
	revenue per billing page session, and then pull the number of billing page sessions for the past month to 
	understand monthly impact 
	(date of request for analysis is Nov 27, 2012, so Oct 27-nOV 27, 2012 would be ‘last month’).
 */  

USE mavenfuzzyfactory;

/* 1.	Gsearch seems to be the biggest driver of business.  Pull monthly trends for gsearch sessions and orders 

		year    month	n_sessions		n_orders      one_item_orders  order_volume conv_rate
1494 orders  
*/

SELECT 
	YEAR(ws.created_at) AS year,
	MONTH(ws.created_at) AS month,
    COUNT(DISTINCT ws.website_session_id) AS n_sessions,
	COUNT(DISTINCT o.order_id) AS n_orders,
	COUNT(DISTINCT CASE WHEN o.items_purchased=1 THEN o.order_id ELSE NULL END) AS one_item_orders,
--	COUNT(DISTINCT CASE WHEN o.items_purchased=2 THEN o.order_id ELSE NULL END) AS two_item_orders,
    SUM(items_purchased*price_usd) AS order_volume,
    COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id) AS conv_rate
FROM website_sessions AS ws
	LEFT JOIN orders AS o
		ON ws.website_session_id = o.website_session_id
	WHERE ws.created_at <'2012-11-27'
    AND ws.utm_source='gsearch'
GROUP BY 1,2;

-- PROBLEM 2.	Do same gsearch monthly trend but by nonbrand and brand campagins separately, to see if brand is growing

SELECT 
	YEAR(ws.created_at) AS yr,
	MONTH(ws.created_at) AS mo,
    COUNT(DISTINCT ws.website_session_id) AS n_sessions,
	COUNT(DISTINCT o.order_id) AS n_orders,
	COUNT(DISTINCT CASE WHEN utm_campaign='nonbrand' THEN ws.website_session_id ELSE NULL END) AS nb_sessions,
	COUNT(DISTINCT CASE WHEN utm_campaign='nonbrand' THEN o.order_id ELSE NULL END) AS nb_orders,
	COUNT(DISTINCT CASE WHEN utm_campaign='nonbrand' THEN o.order_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN utm_campaign='nonbrand' THEN ws.website_session_id ELSE NULL END) AS nonbrand_cvr,
	
    COUNT(DISTINCT CASE WHEN utm_campaign='brand' THEN ws.website_session_id ELSE NULL END) AS brand_sessions,
	COUNT(DISTINCT CASE WHEN utm_campaign='brand' THEN o.order_id ELSE NULL END) AS brand_orders,
	COUNT(DISTINCT CASE WHEN utm_campaign='brand' THEN o.order_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN utm_campaign='brand' THEN ws.website_session_id ELSE NULL END) AS brand_cvr
FROM website_sessions AS ws
	LEFT JOIN orders AS o
		ON ws.website_session_id = o.website_session_id
	WHERE ws.created_at <'2012-11-27'
    AND ws.utm_source='gsearch'
GROUP BY 1,2;

-- 3.	Pull Nonbrand monthly sessions and orders, split by device type
SELECT 
	YEAR(ws.created_at) AS year,
	MONTH(ws.created_at) AS month,
    COUNT(DISTINCT ws.website_session_id) AS n_sessions,
	COUNT(DISTINCT o.order_id) AS n_orders,
	COUNT(DISTINCT CASE WHEN device_type='desktop' THEN ws.website_session_id ELSE NULL END) AS desktop_sessions,
	COUNT(DISTINCT CASE WHEN device_type='desktop' THEN o.order_id ELSE NULL END) AS desktop_orders,
	COUNT(DISTINCT CASE WHEN device_type='mobile' THEN ws.website_session_id ELSE NULL END) AS mobile_sessions,
	COUNT(DISTINCT CASE WHEN device_type='mobile' THEN o.order_id ELSE NULL END) AS mobile_orders
FROM website_sessions AS ws
	LEFT JOIN orders AS o
		ON ws.website_session_id = o.website_session_id
	WHERE ws.created_at <'2012-11-27'
    AND ws.utm_source='gsearch'
    AND  ws.utm_campaign='nonbrand'
GROUP BY 1,2;

-- 4.	Pull monthly trends for gsearch alongside trends for other search channels (showing comparative growth)
-- four types of traffic gsearch_paid_sessions, bsearch_paid_sessions, organic_search_sessions, direct_type_in_sessions
-- last two types of traffic do not require payment to search engines; pure profit

SELECT distinct
	utm_source,
    utm_campaign,
    http_referer
FROM website_sessions
WHERE created_at <'2012-11-27';

SELECT 
	YEAR(ws.created_at) AS year,
	MONTH(ws.created_at) AS month,
	COUNT(DISTINCT CASE WHEN utm_source='gsearch' THEN ws.website_session_id ELSE NULL END) AS gsearch_paid_sessions,
	COUNT(DISTINCT CASE WHEN utm_source='bsearch' THEN ws.website_session_id ELSE NULL END) AS bsearch_paid_sessions,
	COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN ws.website_session_id ELSE NULL END) AS direct_type_in_sessions,
	COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN ws.website_session_id ELSE NULL END) AS organic_search_sessions
FROM website_sessions AS ws
	LEFT JOIN orders AS o
		ON ws.website_session_id = o.website_session_id
	WHERE ws.created_at <'2012-11-27'
GROUP BY 1,2;

-- 5.	Show website performance improvements over the course of the first 8 months:  
-- 	Find session to order conversion rates, by month; don't limit to gsearch
SELECT 
	YEAR(ws.created_at) AS year,
	MONTH(ws.created_at) AS month,
    COUNT(DISTINCT ws.website_session_id) AS n_sessions,
	COUNT(DISTINCT o.order_id) AS n_orders,
	COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id) AS cvr_overall,
    
    COUNT(DISTINCT CASE WHEN utm_source IS NULL THEN ws.website_session_id ELSE NULL END) AS n_None,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN ws.website_session_id ELSE NULL END) AS n_bsearch,
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN ws.website_session_id ELSE NULL END) AS n_gsearch,
	COUNT(DISTINCT CASE WHEN utm_source IS NULL THEN o.order_id ELSE NULL END) AS null_orders,
	COUNT(DISTINCT CASE WHEN utm_source = 'bsearch'THEN o.order_id ELSE NULL END) AS bsearch_orders,
	COUNT(DISTINCT CASE WHEN utm_source = 'gsearch'THEN o.order_id ELSE NULL END) AS gsearch_orders,

    round(COUNT(DISTINCT CASE WHEN utm_source IS NULL THEN o.order_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN utm_source IS NULL THEN ws.website_session_id ELSE NULL END),3) AS cvr_Null,
    round(COUNT(DISTINCT CASE WHEN utm_source = 'bsearch'THEN o.order_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN ws.website_session_id ELSE NULL END),3) AS cvr_bsearch,
    round(COUNT(DISTINCT CASE WHEN utm_source = 'gsearch'THEN o.order_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN ws.website_session_id ELSE NULL END),3) AS cvr_gsearch
	  
FROM website_sessions AS ws
	LEFT JOIN orders AS o
		ON ws.website_session_id = o.website_session_id
	WHERE ws.created_at <'2012-11-27'
GROUP BY 1,2;

-- 6.	For gsearch lander test, estimate the rev that test earned (look at increase in CVR from test June 19-Jul 28 
-- 	and use nonbrand sessions and revenue since then to calculate incremental value.
-- NOTE - This is not a very well defined question.  
-- Let's compare CVR for /home sessions vs. /lander-1 sessions, from June 19-July 28, starting with debut pageview id of lander-1 
-- 	 		n_sessions		n_orders	cvr
-- /home
-- /lander-1

-- 23504 is where lander-1 is started
SELECT 
	MIN(website_pageviews.website_pageview_id) 
FROM website_pageviews 
WHERE website_pageviews.pageview_url='/lander-1';

DROP TEMPORARY TABLE sessions_w_min_pv_id_and_views;

CREATE TEMPORARY TABLE sessions_w_min_pv_id_and_views 
SELECT 
	website_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS min_pv_id,
    COUNT(DISTINCT website_pageviews.website_pageview_id) AS page_views 
FROM website_pageviews
	INNER JOIN website_sessions
		ON website_sessions.website_session_id = website_pageviews.website_session_id 
WHERE website_pageviews.website_pageview_id > 23503 
	AND website_sessions.created_at < '2012-07-28'	
	AND utm_campaign='nonbrand'
	AND utm_source = 'gsearch'
GROUP BY website_pageviews.website_session_id;

SELECT * FROM sessions_w_min_pv_id_and_views;

DROP TEMPORARY TABLE sessions_w_counts_lander_and_created_at;

CREATE TEMPORARY TABLE sessions_w_counts_lander_and_created_at
SELECT
	sessions_w_min_pv_id_and_views.website_session_id,
    sessions_w_min_pv_id_and_views.min_pv_id,
    sessions_w_min_pv_id_and_views.page_views, -- this is how many pages are viewed in the session i.e., past landing if >1
    website_pageviews.pageview_url AS landing,
    website_pageviews.created_at
FROM sessions_w_min_pv_id_and_views
	LEFT JOIN website_pageviews
		ON website_pageviews.website_pageview_id = sessions_w_min_pv_id_and_views.min_pv_id;

SELECT * FROM sessions_w_counts_lander_and_created_at;

SELECT 
	COUNT(DISTINCT website_session_id)
FROM sessions_w_counts_lander_and_created_at
WHERE page_views=7; -- 166 sessions with 7 pageviws, all thru  to the final page, the /thank-you-for-your-order page; 

SELECT * FROM sessions_w_counts_lander_and_created_at;

-- There are two ways to create a useful table; one is pivot table, other is grouped by landing page
-- option 1 - PIVOT TABLE
SELECT 
-- 	(DATE(s.created_at)) AS start_date,
    COUNT(DISTINCT s.website_session_id) AS all_sessions,
	COUNT(DISTINCT o.order_id) AS n_orders,
    COUNT(DISTINCT o.order_id)/COUNT(DISTINCT s.website_session_id) AS conv_rate_total, 

    COUNT(DISTINCT CASE WHEN landing='/home' THEN s.website_session_id ELSE NULL END) AS home_sessions,
    COUNT(DISTINCT CASE WHEN landing='/home' THEN o.website_session_id ELSE NULL END) AS home_orders,
    COUNT(DISTINCT CASE WHEN landing='/home' THEN o.website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN landing='/home' THEN s.website_session_id ELSE NULL END) AS home_cvr,

    COUNT(DISTINCT CASE WHEN landing='/lander-1' THEN s.website_session_id ELSE NULL END) AS lander_sessions,
    COUNT(DISTINCT CASE WHEN landing='/lander-1' THEN o.website_session_id ELSE NULL END) AS lander_orders,
    COUNT(DISTINCT CASE WHEN landing='/lander-1' THEN o.website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN landing='/lander-1' THEN s.website_session_id ELSE NULL END) AS lander_cvr

FROM sessions_w_counts_lander_and_created_at s
	LEFT JOIN 	orders AS o
		ON S.website_session_id = o.website_session_id;

-- option 2 - GROUPED by landing page
SELECT 
    s.landing, 
    COUNT(DISTINCT s.website_session_id) AS all_sessions,
	COUNT(DISTINCT o.order_id) AS n_orders,
    COUNT(DISTINCT o.order_id)/COUNT(DISTINCT s.website_session_id) AS conv_rate 
FROM sessions_w_counts_lander_and_created_at s
	LEFT JOIN 	orders AS o
		ON S.website_session_id = o.website_session_id        
GROUP BY landing;

-- 4.06 is cvr for /lander-1	during test period 
-- 3.19 is cvr for /home 		during test period 
-- 0.87 incremental orders per session

-- last session for /home sourced session is 17145
SELECT 
	MAX(website_pageviews.website_session_id)
FROM website_pageviews
	INNER JOIN website_sessions
		ON website_sessions.website_session_id = website_pageviews.website_session_id 
WHERE website_sessions.created_at < '2012-11-27'	
	AND pageview_url='/home'
    AND utm_campaign='nonbrand'
	AND utm_source = 'gsearch';

-- need # sessions >17145
-- there are 22,972 sessions after test is over; so impact is 
-- 0.0087  extra orders x 22,972 = almost 200 extra orders
SELECT 
	COUNT(DISTINCT website_sessions.website_session_id)
FROM website_sessions
WHERE website_sessions.created_at < '2012-11-27'	
	AND website_session_id>17145 
    AND utm_campaign='nonbrand'
	AND utm_source = 'gsearch';

/* 7.	For landing page test analyzed previously, show a full conversion funnel from each of the two pages to orders.  
	Use same time period Jun 19-Jul 28.  Focus on gsearch??
    
    Note - June 19 is first day that lander-1 is getting some views, July 29 and 30 have some of both, but 
    July 28 is equally split sessions.

	landing_page		n_sessions  ctr_2ndpage	ctr_products   	n_orders  	ctr_billing
    /home				x			x			x				x			x
    /lander-1			x			x			x				x			x

    */

DROP TEMPORARY TABLE sessions_w_min_pv_id_and_views;

CREATE TEMPORARY TABLE sessions_w_min_pv_id_and_views 
SELECT 
	website_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS min_pv_id,
    website_pageviews.pageview_url AS landing 
FROM website_pageviews
	INNER JOIN website_sessions
		ON website_sessions.website_session_id = website_pageviews.website_session_id 
WHERE website_pageviews.created_at between '2012-06-19' AND '2012-07-28'
	AND website_sessions.utm_source='gsearch'
    AND website_pageviews.pageview_url IN ('/home','/lander-1') 
GROUP BY website_pageviews.website_session_id;

SELECT * FROM sessions_w_min_pv_id_and_views;

DROP TEMPORARY TABLE sessions_views_urls;

CREATE TEMPORARY TABLE sessions_views_urls
SELECT  
	wp.website_session_id AS session_id,
    sv.min_pv_id,
	sv.landing,
    wp.website_pageview_id AS pageview_id,
    wp.pageview_url AS url
FROM website_pageviews wp
	INNER JOIN sessions_w_min_pv_id_and_views sv
		ON wp.website_session_id = sv.website_session_id;

SELECT * FROM sessions_views_urls;

DROP TEMPORARY TABLE totals;
CREATE TEMPORARY TABLE totals
SELECT 
    COUNT(DISTINCT session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN url='/products' THEN session_id ELSE NULL END) AS to_products,
    COUNT(DISTINCT CASE WHEN url='/the-original-mr-fuzzy' THEN session_id ELSE NULL END) AS to_fuzzy,
	COUNT(DISTINCT CASE WHEN url='/cart' THEN session_id ELSE NULL END) AS to_cart, 
	COUNT(DISTINCT CASE WHEN url='/shipping' THEN session_id ELSE NULL END) AS to_shipping,
	COUNT(DISTINCT CASE WHEN url='/billing' THEN session_id ELSE NULL END) AS to_billing,
	COUNT(DISTINCT CASE WHEN url='/thank-you-for-your-order' THEN session_id ELSE NULL END) AS to_thanks, 
    landing
FROM sessions_views_urls
GROUP BY landing;

select * from totals;
-- we can create a session level view of navigation path through site using binary coding of visited sites
-- NOTE how MAX and 1 ELSE 0 OR COUNT(1 ELSE NULL) are used
-- I kind of doubt real world data would be as perfect, with few bouncing around inside sight, i.e., going 
-- directly or sequentially from one site to next, without bouncing back and forth from cart to products, etc.
-- perhaps we would use filter to capture furthest part in site that is reached and ignore if last page visited was
-- earlier in sequence
SELECT 
    id,
    MAX(DISTINCT CASE WHEN url='/products' THEN 1 ELSE 0 END) AS to_products,
    COUNT(DISTINCT CASE WHEN url='/the-original-mr-fuzzy' THEN 1 ELSE NULL END) AS to_fuzzy,
	COUNT(DISTINCT CASE WHEN url='/cart' THEN 1 ELSE NULL END) AS to_cart, 
	COUNT(DISTINCT CASE WHEN url='/shipping' THEN 1 ELSE NULL END) AS to_shipping,
	COUNT(DISTINCT CASE WHEN url='/billing' THEN 1 ELSE NULL END) AS to_billing,
	COUNT(DISTINCT CASE WHEN url='/thank-you-for-your-order' THEN 1 ELSE NULL END) AS to_thanks
FROM sessions_views_urls
GROUP BY id;
-- takes too long; can simplify with prior sql
SELECT 
    id,
    CASE WHEN url='/products' THEN 1 ELSE 0 END AS to_products,
    CASE WHEN url='/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS to_fuzzy,
	CASE WHEN url='/cart' THEN 1 ELSE 0 END AS to_cart, 
	CASE WHEN url='/shipping' THEN 1 ELSE 0 END AS to_shipping,
	CASE WHEN url='/billing' THEN 1 ELSE 0 END AS to_billing,
	CASE WHEN url='/thank-you-for-your-order' THEN 1 ELSE 0 END AS to_thanks
FROM sessions_views_urls;

select * from totals;

SELECT 
	landing, 
    sessions, 
    to_products/sessions 	AS landing_ctr,
	to_fuzzy/to_products 	AS products_ctr,
	to_cart/to_fuzzy 		AS fuzzy_ctr, 
	to_shipping/to_cart 	AS cart_ctr,
	to_billing/to_shipping 	AS shipping_ctr,
	to_thanks/to_billing 	AS billing_ctr,
    to_thanks/sessions      AS overall_ctr
FROM totals
GROUP BY landing;

-- shows that there are only 180 orders with gsearch origin during this timeframe
SELECT
	count(distinct o.website_session_id)
FROM sessions_views_urls s
	LEFT JOIN 	orders AS o		-- need to do left join because there are some orders that come from NULL utm_source
		ON s.session_id = o.website_session_id
where o.created_at between '2012-06-19' AND '2012-07-28';
-- wow, results are that ctr's are not that diffeent, but over volume would be important 
-- ctr from lander-1 to products is 46.8% vs. 43.4%; I guess that is a lot over big volume
-- and actual order conversion is 47.8% vs. 44.8%


/* 8. Quantify impact of billing test.  Analyze lift generated from the test (Sep 10 – Nov 10), in terms of 
	revenue per billing page session, and then pull the number of billing page sessions for the past month to 
	understand monthly impact 
	(date of request for analysis is Nov 27, 2012, so Oct 27-nOV 27, 2012 would be ‘last month’).
  
-- Query 1
billing_page	n_sessions		n_orders	order_vol_usd  avg_order_vol_per_bsession
/billing
/billing-2 

 */
-- Query 1
DROP TEMPORARY TABLE billing_sessions;
CREATE TEMPORARY TABLE billing_sessions
SELECT  
	website_session_id AS id,
    pageview_url AS billing_page
FROM website_pageviews 
	WHERE website_pageview_id > 53549  
        AND created_at < '2012-11-10'
		AND pageview_url IN ('/billing','/billing-2');

select * FROM billing_sessions;

-- this approach relies on order being shown by thank you page; but using order number and session id is another way (see alternate solution)
CREATE TEMPORARY TABLE billing_sessions2
SELECT 
	bs.id, 
    bs.billing_page,
    wp.pageview_url
FROM billing_sessions bs
	LEFT JOIN website_pageviews wp
		ON bs.id = wp.website_session_id
	WHERE wp.pageview_url IN ('/billing','/billing-2','/thank-you-for-your-order');

SELECT  
    bs.billing_page AS billing_version_seen,
    COUNT(DISTINCT bs.id) AS sessions,
    COUNT(DISTINCT o.website_session_id) AS n_orders, 
    COUNT(DISTINCT o.website_session_id)/COUNT(DISTINCT bs.id) AS ctr, 
    sum(CASE WHEN bs.pageview_url='/thank-you-for-your-order' THEN o.items_purchased*o.price_usd ELSE NULL END) AS order_vol,
    sum(CASE WHEN bs.pageview_url='/thank-you-for-your-order' THEN o.items_purchased*o.price_usd ELSE NULL END)/COUNT(DISTINCT bs.id) AS avg_order_vol_per_billpage
-- all orders are single item, each $49.99 
FROM billing_sessions2 bs
	LEFT JOIN orders o
		ON o.website_session_id = bs.id
GROUP BY 1;

-- $31.34 per bill page for /billing-2
-- $22.83 per bill page for /billing
-- $8.51 LIFT per billing page view, because Ctr goes from 45.6% to 62.7% from billing to /thankyou

SELECT
	COUNT(website_session_id) AS bill_sessions_last_month
FROM website_pageviews
WHERE website_pageviews.pageview_url IN ('/billing','/billing-2')
	AND created_at BETWEEN '2012-10-27' AND '2012-11-27';
 
-- 1,194 BILLING sessions 10-27 to 11-27
-- $8.51 ==> $10,161 rev per month WILL BE IMPACT

/* followup: how to do embedded query so we do not need extra temporary tables */

SELECT
	billing_page,
	COUNT(DISTINCT bs.id) AS n_sessions,
	COUNT(DISTINCT o.order_id) AS n_orders,
    SUM(o.price_usd) AS volume,
    SUM(o.price_usd)/COUNT(DISTINCT bs.id) AS avg_vol_per_session
FROM (SELECT  
	website_session_id AS id,
    pageview_url AS billing_page
FROM website_pageviews 
	WHERE website_pageview_id > 53549  
        AND created_at < '2012-11-10'
		AND pageview_url IN ('/billing','/billing-2')) AS bs
LEFT JOIN orders o
	ON o.website_session_id = bs.id
GROUP BY 1;

