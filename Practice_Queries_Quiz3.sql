USE mavenfuzzyfactory;

-- pivot table 
SELECT 
	primary_product_id,
    COUNT(DISTINCT CASE WHEN items_purchased = 1 THEN order_id ELSE NULL END) AS orders_w_1_items,
	COUNT(DISTINCT CASE WHEN items_purchased = 2 THEN order_id ELSE NULL END) AS orders_w_2_items,
    count(DISTINCT order_id) AS total_orders
FROM orders
WHERE order_id BETWEEN 100 AND 100000
GROUP BY 1;

/* KEY TABLES */
-- session is when a user enters website somewhere
SELECT * FROM website_sessions WHERE website_session_id=1059 ;

-- pageviews: with each session id, there is a group of pages user visited
SELECT * FROM website_pageviews WHERE website_session_id=1059 ;
-- orders
SELECT * FROM orders WHERE website_session_id=1059 ;

/* 21. ASSIGNMENT: Finding Top Traffic  Sources */
-- Result grid: UTM source, utm_campagin, referring domain, # of sessions 
-- sessions in line 1 is 3611, not 3613 as shown in solution
SELECT 
    utm_source, utm_campaign, http_referer, COUNT(DISTINCT website_session_id) as sessions 
FROM website_sessions
WHERE created_at <= '2012-04-12'
GROUP BY utm_source, utm_campaign, http_referer
ORDER BY sessions DESC;

/* 23.  ASSIGNMENT: Traffic Source Conversion Rates */
-- sessions, orders, session_to_order_conv_rate
-- course answer is 3895  112 0.0288
SELECT 
    COUNT(DISTINCT w.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS totorders,
    COUNT(DISTINCT o.order_id)/COUNT(DISTINCT w.website_session_id) AS cvr
FROM website_sessions AS w
	LEFT JOIN orders AS o
		ON w.website_session_id = o.website_session_id
WHERE w.created_at < '2012-04-12' 
	AND w.utm_source='gsearch' 
    AND w.utm_campaign='nonbrand';

/* 26. ASSIGNMENT: Traffic Source Trending  */
-- 			from Advanced SQL Udemy Course April 2020            

SELECT 
    MIN(DATE(created_at)) AS week_start_date,
    COUNT(DISTINCT website_session_id) as sessions 
FROM website_sessions
WHERE website_sessions.created_at < '2012-05-10' 
	AND utm_source='gsearch' 
    AND utm_campaign='nonbrand'
GROUP BY WEEK(created_at); -- we can group by even if we do not include in select, but be careful doing this

-- ------------------------------------------------------------------------------------------------------------------------------
/* 28. ASSIGNMENT:  Bid Optimization for Paid Traffic    */
-- device_type, sessions, orders, session_to_order_conversion_rate
-- seeing the conversion rate my device type will help optimize bids

SELECT 
	device_type,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) as session_to_order_conv_rate
FROM website_sessions
	LEFT JOIN orders 
		USING (website_session_id) -- ON website_sessions.website_session_id = orders.website_session_id 
WHERE website_sessions.created_at < '2012-05-11' 
	AND utm_source='gsearch' 
    AND utm_campaign='nonbrand'
GROUP BY device_type;

-- ------------------------------------------------------------------------------------------------------------------------------
/* 30. ASSIGNMENT: Trending w/ Granular Segments */
--  Weekly trend data by device type 
SELECT 
    MIN(DATE(created_at)) AS week_start_date,
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) AS dtop_sessions,
	COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mob_sessions
FROM website_sessions
WHERE website_sessions.created_at BETWEEN '2012-04-15'AND '2012-06-09' 
	AND utm_source='gsearch' 
    AND utm_campaign='nonbrand'
GROUP BY WEEK(created_at); -- we can group by even if we do not include in select, but be careful doing this

/* counting pageviews, some of my own scribble work */
-- this is to find the total # pages (16) and # pageviews (1188000), which we use in next query as constant to calc pct_views
SELECT 
	COUNT(DISTINCT pageview_url) as num_pages, 
	count(DISTINCT website_pageview_id)/1000 AS total_views
FROM website_pageviews;

SELECT 
	pageview_url,
	round(COUNT(DISTINCT website_pageview_id)/1000,1) AS pvs,
	round(COUNT(DISTINCT website_pageview_id)/1188000,3) AS pct_views
FROM website_pageviews
GROUP BY pageview_url
ORDER BY pvs DESC;
-- ------------------------------------------------------------------------------------------------------------------------------
/* CREATION OF TEMPORARY TABLES - this is advanced SQL now */
-- CREATE TEMPORARY TABLE test -- last only for current workbench session; so keep code in file;

CREATE TEMPORARY TABLE first_pageview
SELECT 
	website_session_id,
    MIN(website_pageview_id) AS min_pv_id
FROM website_pageviews
GROUP BY website_session_id;

-- # of distinct session IDs in our database = 472871
SELECT 
	COUNT(DISTINCT website_session_id)
FROM website_pageviews;
    
-- what are these /lander-2 -3 and other landing pages??
-- amazing that no one enters site except thru home or these lander pages, whatever they are
SELECT
    website_pageviews.pageview_url AS landing_page, -- aka entry page
	COUNT(DISTINCT first_pageview.website_session_id) AS sessions_hitting_this_lander,
    COUNT(DISTINCT first_pageview.website_session_id)/472871 AS pct_landed
FROM first_pageview
	LEFT JOIN website_pageviews
		ON first_pageview.min_pv_id = website_pageviews.website_pageview_id
GROUP BY website_pageviews.pageview_url
ORDER BY sessions_hitting_this_lander DESC;

-- # hitting lander vs. total views (and how many views per session, on average)
SELECT
	(SELECT COUNT(DISTINCT website_pageview_id) AS total FROM website_pageviews) as totals,
	COUNT(DISTINCT first_pageview.website_session_id) AS sessions_hitting_this_lander,
	round((SELECT COUNT(DISTINCT website_pageview_id) AS total FROM website_pageviews)/COUNT(DISTINCT first_pageview.website_session_id),2) 
		AS page_views_per_session
FROM first_pageview
	LEFT JOIN website_pageviews
		ON first_pageview.min_pv_id = website_pageviews.website_pageview_id;

-- # total page views around 1.2 MILLION
SELECT COUNT(DISTINCT website_pageview_id) AS total FROM website_pageviews;

-- ------------------------------------------------------------------------------------------------------------------------------
/* 34. ASSIGNMENT - FINDING  TOP WEBSITE PAGES */
-- most viewed website pages rnaked by session volume
-- pageview_url  	num_sessions before 6/9/2012
/*  this doesn't double count same page if viewed twice in same session (e.g., if browsed
	away from page and then revisit */
SELECT
	pageview_url AS pageview_url,
    COUNT(DISTINCT website_session_id) AS num_sessions
FROM website_pageviews
WHERE created_at < '2012-06-09'  
GROUP BY pageview_url
ORDER BY num_sessions DESC;

-- how many sessions before June 9; there are more than this # of pageviews because users look at 
-- more than one page per session; 10,398 sessions
SELECT 
	COUNT(DISTINCT website_session_id)
FROM website_pageviews
WHERE created_at < '2012-06-09';

 /* 36. ASSIGNMENT - FINDING  TOP WEBSITE PAGES */
-- landing_page   sessions_hitting_this_landpage
-- very similar to example under temporary table example, but we will add date description<June 9
    
-- before June 12 in video, all landing pages are /home ; 10,711 sessions
SELECT 
	COUNT(DISTINCT website_session_id)
FROM website_pageviews
	WHERE created_at < '2012-06-12';

SELECT
    website_pageviews.pageview_url AS landing_page, -- aka entry page
	COUNT(DISTINCT first_pageview.website_session_id) AS sessions_hitting_this_lander,
    COUNT(DISTINCT first_pageview.website_session_id)/10711 AS pct_landed
FROM first_pageview
	LEFT JOIN website_pageviews
		ON first_pageview.min_pv_id = website_pageviews.website_pageview_id
WHERE website_pageviews.created_at < '2012-06-12'
	GROUP BY website_pageviews.pageview_url
	ORDER BY sessions_hitting_this_lander DESC;
-- ------------------------------------------------------------------------------------------------------------------------------
-- 38. Bounce rates of landing pages    
-- next step, check what % of sessions terminate on home (landing page) vs. % moving on
-- (bounces have no pageviews after landing)
-- STEP 1. find first website_pageview_id for session
-- STEP 2: identify landing page of each session - NOTE: we've already done this in prior problems
-- STEP 3: counting pageviews for each session, to identify 'bounces'
-- STEP 4: summarize total sessions and bounced sessions, by landing page

-- time period of videowas BETWEEN '2014-01-01' AND '2014-02-01'
--  video shows:	page	sessions	bounced	bounce 	rate
-- 					home 	4093 		1575			0.3848 
-- 					land-2	6500		2855			0.4392
-- 					land-3	4232		2606			0.61
-- 				
CREATE TEMPORARY TABLE first_pageview_short
SELECT 
	website_session_id,
    MIN(website_pageview_id) AS min_pv_id
FROM website_pageviews
WHERE website_pageviews.created_at BETWEEN '2014-01-01' AND '2014-02-01'
GROUP BY website_session_id;

SELECT * FROM first_pageview_short;

CREATE TEMPORARY TABLE sessions_and_landing
SELECT
	first_pageview_short.website_session_id,
    website_pageviews.pageview_url AS landing_page 
FROM first_pageview_short
	LEFT JOIN website_pageviews
		ON first_pageview_short.min_pv_id = website_pageviews.website_pageview_id;

SELECT * FROM sessions_and_landing;

CREATE TEMPORARY TABLE bounced_only
SELECT
	sessions_and_landing.website_session_id,
	sessions_and_landing.landing_page,
	COUNT(website_pageviews.website_pageview_id) AS views
FROM sessions_and_landing
	LEFT JOIN website_pageviews
		ON sessions_and_landing.website_session_id = website_pageviews.website_session_id
GROUP BY sessions_and_landing.website_session_id,
	sessions_and_landing.landing_page
	HAVING views=1;

SELECT 
	sessions_and_landing.landing_page,	
	COUNT(DISTINCT sessions_and_landing.website_session_id) AS sessions,
	COUNT(DISTINCT bounced_only.website_session_id) AS bounced,
	COUNT(DISTINCT bounced_only.website_session_id)/COUNT(DISTINCT sessions_and_landing.website_session_id) AS bounce_rate
FROM sessions_and_landing
	LEFT JOIN bounced_only
		ON sessions_and_landing.website_session_id = bounced_only.website_session_id
	GROUP BY sessions_and_landing.landing_page;

-- ------------------------------------------------------------------------------------------------------------------------------
/* 39. ASSIGNMENT Calc Bounce Rate */
-- sessions, bounced_sessions, bounce_rate for traffic landing on homepage

-- first_pageview finds id of landing pages, which we join here
CREATE TEMPORARY TABLE first_pageview
SELECT 
	website_session_id,
    MIN(website_pageview_id) AS min_pv_id
FROM website_pageviews
WHERE CREATED_AT <'2012-06-14'
GROUP BY website_session_id;

CREATE TEMPORARY TABLE sessions_and_landing_b
SELECT
	first_pageview.website_session_id,
    website_pageviews.pageview_url AS landing_page 
FROM first_pageview 
	LEFT JOIN website_pageviews
		ON first_pageview.min_pv_id = website_pageviews.website_pageview_id;

SELECT * FROM sessions_and_landing_b;

-- session_id, lpage, views=1 
CREATE TEMPORARY TABLE bounced_only_b
SELECT
	sessions_and_landing_b.website_session_id,
	sessions_and_landing_b.landing_page,
	COUNT(website_pageviews.website_pageview_id) AS views
FROM sessions_and_landing_b
	LEFT JOIN website_pageviews
		ON sessions_and_landing_b.website_session_id = website_pageviews.website_session_id
GROUP BY sessions_and_landing_b.website_session_id,
	sessions_and_landing_b.landing_page
	HAVING views=1;
SELECT * FROM bounced_only_b;


-- sessions, bounced_sessions, bounce_rate for traffic landing on homepage (no other lpage 
-- for time period in question up to 2012-06-14 
-- RESULT : 11044 sessions, 6536 bounced, 0.59 bounce rate

SELECT 
	COUNT(DISTINCT sessions_and_landing_b.website_session_id) AS sessions,
	COUNT(DISTINCT bounced_only_b.website_session_id) AS bounced,
	COUNT(DISTINCT bounced_only_b.website_session_id)/COUNT(DISTINCT sessions_and_landing_b.website_session_id) AS bounce_rate
FROM sessions_and_landing_b
	LEFT JOIN bounced_only_b
		ON sessions_and_landing_b.website_session_id = bounced_only_b.website_session_id;

-- ------------------------------------------------------------------------------------------------------------------------------
/* 41. Analyzing Landing Page Tests */
-- compare bounce rates of /home vs. /lander-1 (just during when lander-1 was up), gsearch nonbrand traffic
-- sessions, bounced_sessions, bounce_rate for traffic landing on homepage
-- 		lpage  total_sessions bounced_session bounce_rate
-- /home
-- /lander-1

-- STEP 1. find when this period was 
		-- started at created at 2012-06-19
SELECT *
FROM website_pageviews
	WHERE pageview_url = '/lander-1'
ORDER BY website_pageviews.created_at
LIMIT 1;

		-- END on created at < july 28, 2012 
-- STEP 2. find bounce rates for just that period, for both sites (GROUP BY lpage;)
DROP TEMPORARY TABLE first_pageview_c;
CREATE TEMPORARY TABLE first_pageview_c
SELECT 
	website_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS min_pv_id
FROM website_pageviews
	INNER JOIN website_sessions
		ON website_sessions.website_session_id = website_pageviews.website_session_id 
        AND website_pageviews.website_pageview_id >= 23504 -- must start with this because there 
        -- is part of day where just /home is in effect, before / lander-1 is up
        AND website_sessions.created_at < '2012-07-28'
        -- BETWEEN '2012-06-19' AND '2012-07-28'
		AND utm_source='gsearch'
        AND utm_campaign='nonbrand'
GROUP BY website_pageviews.website_session_id;

DROP TEMPORARY TABLE sessions_and_landing_c;
CREATE TEMPORARY TABLE sessions_and_landing_c
SELECT
	first_pageview_c.website_session_id,
    website_pageviews.pageview_url AS landing_page 
FROM first_pageview_c 
	LEFT JOIN website_pageviews
		ON first_pageview_c.min_pv_id = website_pageviews.website_pageview_id;

SELECT * FROM sessions_and_landing_c;

-- session_id, lpage, views=1 
DROP TEMPORARY TABLE bounced_only_c;
CREATE TEMPORARY TABLE bounced_only_c
SELECT
	sessions_and_landing_c.website_session_id,
	sessions_and_landing_c.landing_page,
	COUNT(website_pageviews.website_pageview_id) AS views
FROM sessions_and_landing_c
	LEFT JOIN website_pageviews
		ON sessions_and_landing_c.website_session_id = website_pageviews.website_session_id
GROUP BY sessions_and_landing_c.website_session_id,
	sessions_and_landing_c.landing_page
	HAVING views=1;
SELECT * FROM bounced_only_c;

SELECT 
	sessions_and_landing_c.landing_page,
    COUNT(DISTINCT sessions_and_landing_c.website_session_id) AS sessions,
	COUNT(DISTINCT bounced_only_c.website_session_id) AS bounced,
	COUNT(DISTINCT bounced_only_c.website_session_id)/COUNT(DISTINCT sessions_and_landing_c.website_session_id) AS bounce_rate
FROM sessions_and_landing_c
	LEFT JOIN bounced_only_c
		ON sessions_and_landing_c.website_session_id = bounced_only_c.website_session_id
GROUP BY sessions_and_landing_c.landing_page;
 
-- /home		2260	1319	0.5836
-- /lander-1	2314	1232	0.5324  

-- in example in video, first lander-1 session is excluded
-- but we include it so the # sessions is 2314 vs. 2313 in video, and bounced is also higher 
-- by 1 at 1232 vs. 1231 in video

-- ------------------------------------------------------------------------------------------------------------------------------
/* 43. Landing Page Trend Analysis */
-- pull volume of paid search nonbrand traffic landing on /home and lander-1, trended weekly from launch of buisness
-- also want overall paid search bounce rate, to see if click through (beyond /home or lander-1 page) increased
-- since lander-1 launched
-- week_start_date	bounce_rate		home_sessions	lander_sessions
-- START 6/1/2012 
-- END August 31, 2012

-- step 1 home sessions by week, nonbrand group by lpage
-- step 2 overall bounce_rate by week

DROP TEMPORARY TABLE first_pageview_d;

-- temp table to find first page view of each session (which will be pageview of landing)
CREATE TEMPORARY TABLE first_pageview_d
SELECT 
	website_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS min_pv_id
FROM website_pageviews
	INNER JOIN website_sessions
		ON website_sessions.website_session_id = website_pageviews.website_session_id 
--        AND website_sessions.created_at BETWEEN '2012-06-01' AND '2012-08-31'
		AND website_sessions.created_at >'2012-06-01' 
		AND website_sessions.created_at < '2012-08-31'
		AND utm_source='gsearch'
		AND utm_campaign='nonbrand'
GROUP BY website_pageviews.website_session_id;

SELECT * FROM first_pageview_d;

-- debugging query; to see week start date with daily created_at and landing_page
SELECT
    MIN(DATE(website_pageviews.created_at)) as week_start_date,
	website_pageviews.created_at,
    COUNT(DISTINCT first_pageview_d.website_session_id) AS sessions,
    website_pageviews.pageview_url AS landing_page
FROM first_pageview_d 
	LEFT JOIN website_pageviews
		ON first_pageview_d.min_pv_id = website_pageviews.website_pageview_id
GROUP BY landing_page, website_pageviews.created_at;

-- table with week_start_date, the_week, #sessions, and landing page 
-- DROP TEMPORARY TABLE sessions_and_landing_d;
CREATE TEMPORARY TABLE sessions_and_landing_d
SELECT
    MIN(DATE(website_pageviews.created_at)) as week_start_date,
    WEEK(website_pageviews.created_at) as the_week,
    COUNT(DISTINCT first_pageview_d.website_session_id) AS sessions,
    website_pageviews.pageview_url AS landing_page
FROM first_pageview_d 
	LEFT JOIN website_pageviews
		ON first_pageview_d.min_pv_id = website_pageviews.website_pageview_id
GROUP BY landing_page, the_week;

-- table used to correct discontinuity in start date of week for lander-1, since it starts mid-week
CREATE TEMPORARY TABLE weeks
SELECT
    MIN(DATE(website_pageviews.created_at)) as week_start_date,
    WEEK(website_pageviews.created_at) as the_week
FROM first_pageview_d 
	LEFT JOIN website_pageviews
		ON first_pageview_d.min_pv_id = website_pageviews.website_pageview_id
GROUP BY the_week;

SELECT * FROM weeks;
-- PART 1. THIS IS THE # SESSIONS BY LANDING PAGE
-- we created temp table weeks to avoid discontinuity in week start date due to lander-1 starting on 
-- 6/19 instead of week start date 6/17; we ended up joining on week # using this temp table
CREATE TEMPORARY TABLE result_a
SELECT
    weeks.week_start_date,
	SUM(CASE WHEN landing_page='/home' THEN sessions ELSE 0 END) as home_sessions,
	SUM(CASE WHEN landing_page='/lander-1' THEN sessions ELSE 0 END) as lander_sessions
FROM sessions_and_landing_d
	INNER JOIN weeks
		ON sessions_and_landing_d.the_week=weeks.the_week
GROUP BY week_start_date;

SELECT * FROM result_a;

-- PART 2. NOW WE WORK ON GETTING OVERALL BOUNCE RATE 

DROP TEMPORARY TABLE sessions_and_landing_e;
CREATE TEMPORARY TABLE sessions_and_landing_e
SELECT
	created_at,
    first_pageview_d.website_session_id,
    website_pageviews.pageview_url AS landing_page 
FROM first_pageview_d 
	LEFT JOIN website_pageviews
		ON first_pageview_d.min_pv_id = website_pageviews.website_pageview_id;

SELECT * FROM sessions_and_landing_e;

-- session_id, lpage, views=1 
DROP TEMPORARY TABLE bounced_only_d;
CREATE TEMPORARY TABLE bounced_only_d
SELECT
	sessions_and_landing_e.website_session_id,
	sessions_and_landing_e.landing_page,
	COUNT(website_pageviews.website_pageview_id) AS views
FROM sessions_and_landing_e
	LEFT JOIN website_pageviews
		ON sessions_and_landing_e.website_session_id = website_pageviews.website_session_id
GROUP BY sessions_and_landing_e.website_session_id,
	sessions_and_landing_e.landing_page
	HAVING views=1;
SELECT * FROM bounced_only_d;

CREATE TEMPORARY TABLE bounce_rate_total
SELECT 
    MIN(DATE(created_at)) AS week_start_date,
	COUNT(DISTINCT bounced_only_d.website_session_id)/COUNT(DISTINCT sessions_and_landing_e.website_session_id) AS bounce_rate
FROM sessions_and_landing_e
	LEFT JOIN bounced_only_d
		ON sessions_and_landing_e.website_session_id = bounced_only_d.website_session_id
GROUP BY WEEK(created_at);

-- ------------------------------------------------------------------------------------------------------------------------------
/* 43. Landing Page Trend Analysis */
/* ATTEMPT 1 - FINAL ANSWER - NOTE HOW NO JOIN IS NEEDED */
-- last two lander sessions are 1339 and 1097 if gsearch as utm_source is not specified in beginning
-- video showed 2 temp tables being used vs. 7 for my solution
-- simpler solution found below
SELECT 
	result_a.week_start_date,
	bounce_rate_total.bounce_rate,
    result_a.home_sessions,
    result_a.lander_sessions
FROM result_a, bounce_rate_total
	WHERE bounce_rate_total.week_start_date=result_a.week_start_date;

/* 43. Landing Page Trend Analysis */
/* ATTEMPT 2 - FINAL ANSWER - NOTE HOW NO JOIN IS NEEDED */
/* only 2 temporary tables required before final query */
DROP TEMPORARY TABLE sessions_w_min_pv_id_and_views;

CREATE TEMPORARY TABLE sessions_w_min_pv_id_and_views 
SELECT 
	website_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS min_pv_id,
    COUNT(DISTINCT website_pageviews.website_pageview_id) AS page_views
FROM website_pageviews
	INNER JOIN website_sessions
		ON website_sessions.website_session_id = website_pageviews.website_session_id 
WHERE website_sessions.created_at >'2012-06-01' 
	AND website_sessions.created_at < '2012-08-31'	
    AND utm_source='gsearch'
	AND utm_campaign='nonbrand'
-- 	website_sessions.created_at BETWEEN '2012-06-01' AND '2012-08-31'
GROUP BY website_pageviews.website_session_id;

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
	MIN(DATE(created_at)) AS week_start_date,
	COUNT(DISTINCT CASE WHEN page_views=1 THEN website_session_id ELSE NULL END)*1.0/COUNT(DISTINCT website_session_id) AS bounce_rate,
    COUNT(DISTINCT CASE WHEN landing='/home' THEN website_session_id ELSE NULL END) AS home_sessions,
    COUNT(DISTINCT CASE WHEN landing='/lander-1' THEN website_session_id ELSE NULL END) AS lander_sessions    
FROM sessions_w_counts_lander_and_created_at
GROUP BY YEARWEEK(created_at); -- better to group by yearweek since won't run into problem of created_at being midweek
-- ------------------------------------------------------------------------------------------------------------------------------
/* 46. ASSIGNMENT - Landing Page Trend Analysis */
-- understand conversion funnel for lander-1 page
-- step 1 limit data to between Aug 5 and Sep 5, 2012
-- can be done all in one
-- 7 columns= # sessions and 6 click thru rates: sessions  to_products  to_mrfuzzy  to_cart  to_shipping  to_billing to_thankyou
-- want conversion rate of all these steps; so lander_ctr is % sessions that get thru to products
-- 6 pages after lander means 6 conversion rates or Clickthru rates

-- # sessions, # to_products, # etc. 

-- do count of first temp table; need to exclude sessions that start on /home
DROP TEMPORARY TABLE sessions_views_urls;

CREATE TEMPORARY TABLE sessions_views_urls
SELECT  
	website_pageviews.website_session_id AS id,
    website_pageviews.website_pageview_id AS viewed,
    website_pageviews.pageview_url AS url
FROM website_pageviews 
	INNER JOIN website_sessions
		ON website_pageviews.website_session_id = website_sessions.website_session_id
WHERE website_pageviews.website_session_id > 18238 -- this session has already started prior to Aug 5 
	AND website_pageviews.created_at < '2012-09-05'
	AND website_sessions.utm_source='gsearch' 
    AND website_sessions.utm_campaign='nonbrand'
    AND website_pageviews.website_session_id 
		NOT IN (SELECT website_pageviews.website_session_id 
				FROM website_pageviews 
				WHERE website_pageviews.pageview_url='/home');

-- we do not eliminate views that may occur twice in same session, so # arriving at products may be distorted by 
-- some sessions where customer was surfing a lot back and forth
DROP TEMPORARY TABLE totals;
CREATE TEMPORARY TABLE totals
SELECT 
    COUNT(DISTINCT id) AS sessions,
    COUNT(DISTINCT CASE WHEN url='/products' THEN id ELSE NULL END) AS to_products,
    COUNT(DISTINCT CASE WHEN url='/the-original-mr-fuzzy' THEN id ELSE NULL END) AS to_fuzzy,
	COUNT(DISTINCT CASE WHEN url='/cart' THEN id ELSE NULL END) AS to_cart, 
	COUNT(DISTINCT CASE WHEN url='/shipping' THEN id ELSE NULL END) AS to_shipping,
	COUNT(DISTINCT CASE WHEN url='/billing' THEN id ELSE NULL END) AS to_billing,
	COUNT(DISTINCT CASE WHEN url='/thank-you-for-your-order' THEN id ELSE NULL END) AS to_thanks
FROM sessions_views_urls;

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
	sessions, 
    to_products/sessions 	AS landing_ctr,
	to_fuzzy/to_products 	AS products_ctr,
	to_cart/to_fuzzy 		AS fuzzy_ctr, 
	to_shipping/to_cart 	AS cart_ctr,
	to_billing/to_shipping 	AS shipping_ctr,
	to_thanks/to_billing 	AS billing_ctr
FROM totals;
 
SELECT 
	count(distinct id)
FROM sessions_views_urls
WHERE url='/lander-1';
-- ------------------------------------------------------------------------------------------------------------------------------
/* 48. ASSIGNMENT - Analyzing Conversion Funnel Tests */
--  see if /billing-2 is different than /billing
-- what % of sessions on billing-2 and billing end up placing an order; run for all traffic (not just gsearch)
-- up till 2012-11-10
-- billing page precedes thank you(which shows that order was made)
-- 			sessions 	order  click-thrutoorder-rate
-- /billing		x		x			x
-- /billing-2	x		x			x

-- STEP 1. find id where billing-2 goes live (53550 is the pageview_id, so look for id's > 53549)
-- STEP 2. find which sessions are billing or billing 2; we can finish the job in just two queries
-- STEP 3. calc sessions of billing, billing2, ctr billing, ctr billing2
SELECT  
	MIN(website_pageview_id)
FROM website_pageviews 
WHERE pageview_url ='/billing-2';

DROP TEMPORARY TABLE billing_sessions;
CREATE TEMPORARY TABLE billing_sessions
SELECT  
	website_session_id AS id,
    pageview_url AS billing_version_seen
FROM website_pageviews 
	WHERE website_pageview_id > 53549  
        AND created_at < '2012-11-10'
		AND pageview_url IN ('/billing','/billing-2')
GROUP BY website_session_id;

-- since every session considered here is either billing or billing-2, we only need to count the thank you
-- pages, and then GROUP BY the session type will 
SELECT 
    billing_sessions.billing_version_seen,
    COUNT(DISTINCT billing_sessions.id) AS sessions,
    COUNT(CASE WHEN website_pageviews.pageview_url='/thank-you-for-your-order' THEN 1 ELSE NULL END) AS orders,
    COUNT(CASE WHEN website_pageviews.pageview_url='/thank-you-for-your-order' THEN 1 ELSE NULL END)/COUNT(DISTINCT billing_sessions.id) AS ctr
FROM billing_sessions   -- VERY important to do 'FROM billing_sessions', as that is smaller table  
						--  or make it INNER JOIN; FROM website_pageviews LEFT JOIN billing_sessions won't work because
                        -- it will leave a lot of NULLs as there are a lot of ids on left side that don't have matching 
                        -- ids in billing_sessions
	INNER JOIN website_pageviews 
		ON billing_sessions.id = website_pageviews.website_session_id
GROUP BY billing_sessions.billing_version_seen;
 
-- MIDCOURSE PROJECT - 8 Queries -- SEE midcourse_project.sql
