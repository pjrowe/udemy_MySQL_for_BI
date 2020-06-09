USE mavenfuzzyfactory;

-- ------------ ------------ ------------ ------------ ------------ ------------ ----------
-- FINAL PROJECT
-- ------------ ------------ ------------ ------------ ------------ ------------ ----------

-- 1. 	Show Volume growth.  Pull Overall session and order volume, trended by quarter for the life of the business.  
--  	Since the most recent uarter is incomplete, you can decide how to handle it.

-- 2. 	Next, let's showcase all of our efficiency imporvements.  I would love to show quarterly figures since we 
-- 		launched, for session to order conversion rate, rev per order, and rev per session.

-- 3. 	I'd like to show how we've grown specific channels. Could you pull a quarterly view of orders from gsearch
-- 		nonbrand, bsearch nonbrand, brand search overall, organic search, and direct type-in?

-- 4.  Next, let's show the overall session-to-0rder conversion rate trends for those same channels, by quarter. 
-- 		Please also make a note of any periods where we made major improvements or optimizations.

-- 5. 	We've come a long way since the days of selling a single product.  Let's pull monthly trending for revenue
-- 		and margin by product, along with total sales and revenue.  Note anything you notice about seasonality.

-- 6. 	Let's dive deeper into the impact of introducing new products.  Please pull monthly sessions to the products page,
-- 		and show how the % of those sessions clicking thru another page has changed over time, along with a view
-- 		of how conversion from /products to placing an order has improved.alter

-- 	7. 	We made our 4th product available as a primary product on Dec 5, 2014 (it was previously only a cross-sell
-- 		item).  Could you please pull sales date since then, and show how well each product cross-sells from one alter
-- 		another?

-- 	8.	In addition to telling investors about what we've already achieved, let's show them that we still have plenty 
-- 		of gas in the tank.  Based on all the analysis you've done, could you share some recommendations and opportunities
-- 		for us going forward?  No right or wrong answer here -- I'd just like to hear your perspective.
-- 		

-- ------------ ------------ ------------ ------------ ------------ ------------ ----------
-- 1. 	Show Volume growth.  Pull Overall session and order volume, trended by quarter for the life of the business.  
--  	Since the most recent uarter is incomplete, you can decide how to handle it.
-- ------------ ------------ ------------ ------------ ------------ ------------ ----------
SELECT
	YEAR(ws.created_at) AS yr,
	QUARTER(ws.created_at) AS Q,
    COUNT(DISTINCT ws.website_session_id) AS n_sessions,
    COUNT(DISTINCT o.website_session_id) AS n_orders
FROM website_sessions ws
LEFT JOIN orders o
	ON ws.website_session_id = o.website_session_id 
WHERE YEAR(ws.created_at)<2015
GROUP BY 1, 2;

SELECT MAX(DAY(created_at)) FROM website_sessions;

-- ------------ ------------ ------------ ------------ ------------ ------------ ----------
-- 2. 	Next, let's showcase all of our efficiency imporvements.  I would love to show quarterly figures since we 
-- 		launched, for session to order conversion rate, rev per order, and rev per session.
-- ------------ ------------ ------------ ------------ ------------ ------------ ----------
SELECT
	YEAR(ws.created_at) AS yr,
	QUARTER(ws.created_at) AS Q,
    COUNT(DISTINCT o.website_session_id)/COUNT(DISTINCT ws.website_session_id) AS session_to_order_cvr,
    SUM(o.price_usd)/COUNT(DISTINCT ws.website_session_id) AS rev_per_session,
    SUM(o.price_usd)/COUNT(DISTINCT o.website_session_id) AS rev_per_order    
FROM website_sessions ws
LEFT JOIN orders o
	ON ws.website_session_id = o.website_session_id 
WHERE YEAR(ws.created_at)<2015
GROUP BY 1, 2;

-- ------------ ------------ ------------ ------------ ------------ ------------ ----------
-- 3. 	I'd like to show how we've grown specific channels. Could you pull a quarterly view of orders from gsearch
-- 		nonbrand, bsearch nonbrand, brand search overall, organic search, and direct type-in?
-- ------------ ------------ ------------ ------------ ------------ ------------ ----------
SELECT
	YEAR(ws.created_at) AS yr,
	QUARTER(ws.created_at) AS Q,
    COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND ws.http_referer IS NULL THEN o.website_session_id ELSE NULL END) AS direct_type_in,
    COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND ws.http_referer IS NOT NULL THEN o.website_session_id ELSE NULL END) AS search_organic,
    COUNT(DISTINCT CASE WHEN ws.utm_campaign='brand' THEN o.website_session_id ELSE NULL END) AS paid_brand,
    COUNT(DISTINCT CASE WHEN ws.http_referer = 'https://www.gsearch.com' AND ws.utm_campaign='nonbrand' THEN o.website_session_id ELSE NULL END) AS gsearch_nonbrand,
    COUNT(DISTINCT CASE WHEN ws.http_referer = 'https://www.bsearch.com' AND ws.utm_campaign='nonbrand' THEN o.website_session_id ELSE NULL END) AS bsearch_nonbrand
FROM website_sessions ws
INNER JOIN orders o -- ONLY looking at orders volume by # of orders by channel, not general sessions
	ON ws.website_session_id = o.website_session_id 
WHERE YEAR(ws.created_at)<2015
GROUP BY 1, 2;

-- ------------ ------------ ------------ ------------ ------------ ------------ ----------
-- 4.  Next, let's show the overall session-to-order conversion rate trends for those same channels, by quarter. 
-- 		Please also make a note of any periods where we made major improvements or optimizations.
-- ------------ ------------ ------------ ------------ ------------ ------------ ----------
SELECT
	YEAR(ws.created_at) AS yr,
	QUARTER(ws.created_at) AS Q,
    COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND ws.http_referer IS NULL THEN o.website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND ws.http_referer IS NULL THEN ws.website_session_id ELSE NULL END) AS direct_type_in_cvr,
    COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND ws.http_referer IS NOT NULL THEN o.website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND ws.http_referer IS NOT NULL THEN ws.website_session_id ELSE NULL END) AS search_organic,
    COUNT(DISTINCT CASE WHEN ws.utm_campaign='brand' THEN o.website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN ws.utm_campaign='brand' THEN ws.website_session_id ELSE NULL END) AS paid_brand,
    COUNT(DISTINCT CASE WHEN ws.http_referer = 'https://www.gsearch.com' AND ws.utm_campaign='nonbrand' THEN o.website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN ws.http_referer = 'https://www.gsearch.com' AND ws.utm_campaign='nonbrand' THEN ws.website_session_id ELSE NULL END) AS gsearch_nonbrand,
    COUNT(DISTINCT CASE WHEN ws.http_referer = 'https://www.bsearch.com' AND ws.utm_campaign='nonbrand' THEN o.website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN ws.http_referer = 'https://www.bsearch.com' AND ws.utm_campaign='nonbrand' THEN ws.website_session_id ELSE NULL END) AS bsearch_nonbrand
FROM website_sessions ws
LEFT JOIN orders o  -- need access to all sessions, not just orders
	ON ws.website_session_id = o.website_session_id 
WHERE YEAR(ws.created_at)<2015
GROUP BY 1, 2;

-- ------------ ------------ ------------ ------------ ------------ ------------ ----------
-- 5. 	We've come a long way since the days of selling a single product.  Let's pull monthly trending for revenue
-- 		and margin by product, along with total sales and revenue.  Note anything you notice about seasonality.
-- ------------ ------------ ------------ ------------ ------------ ------------ ----------
SELECT
	YEAR(oi.created_at) AS yr,
	month(oi.created_at) AS mo,
	COUNT(DISTINCT oi.order_item_id) AS n_items,
    COUNT(DISTINCT oi.order_id) AS n_orders,
    SUM(oi.price_usd) AS tot_revenue,
    SUM(oi.cogs_usd) AS tot_cogs,
    SUM(oi.price_usd)-SUM(oi.cogs_usd) AS tot_profit,
    round((SUM(oi.price_usd)-SUM(oi.cogs_usd))/SUM(oi.price_usd),3) AS tot_margin,
    SUM(CASE WHEN oi.product_id = 1 THEN oi.price_usd ELSE NULL END) AS prod_1_rev,
    SUM(CASE WHEN oi.product_id = 1 THEN (oi.price_usd-oi.cogs_usd) ELSE NULL END)/SUM(CASE WHEN oi.product_id = 1 THEN oi.price_usd ELSE NULL END) AS prod_1_mrgn,
    SUM(CASE WHEN oi.product_id = 2 THEN oi.price_usd ELSE NULL END) AS prod_2_rev,
    SUM(CASE WHEN oi.product_id = 2 THEN (oi.price_usd-oi.cogs_usd) ELSE NULL END)/SUM(CASE WHEN oi.product_id = 2 THEN oi.price_usd ELSE NULL END) AS prod_2_mrgn,
    SUM(CASE WHEN oi.product_id = 3 THEN oi.price_usd ELSE NULL END) AS prod_3_rev,
    SUM(CASE WHEN oi.product_id = 3 THEN (oi.price_usd-oi.cogs_usd) ELSE NULL END)/SUM(CASE WHEN oi.product_id = 3 THEN oi.price_usd ELSE NULL END) AS prod_3_mrgn,
    SUM(CASE WHEN oi.product_id = 4 THEN oi.price_usd ELSE NULL END) AS prod_4_rev,
    SUM(CASE WHEN oi.product_id = 4 THEN (oi.price_usd-oi.cogs_usd) ELSE NULL END)/SUM(CASE WHEN oi.product_id = 4 THEN oi.price_usd ELSE NULL END) AS prod_4_mrgn
FROM order_items oi
GROUP BY 1, 2;

-- ------------ ------------ ------------ ------------ ------------ ------------ ----------
-- 6. 	Let's dive deeper into the impact of introducing new products.  Please pull monthly sessions to the products page,
-- 		and show how the % of those sessions clicking thru another page has changed over time, along with a view
-- 		of how conversion from /products to placing an order has improved. 
-- ------------ ------------ ------------ ------------ ------------ ------------ ----------
SELECT
	YEAR(wp.created_at) AS yr,
	month(wp.created_at) AS mo,
	COUNT(DISTINCT CASE WHEN pageview_url='/products' THEN wp.website_session_id ELSE NULL END) AS n_sessions,
	COUNT(DISTINCT CASE WHEN pageview_url IN ('/the-birthday-sugar-panda', '/the-original-mr-fuzzy', '/the-forever-love-bear','/the-hudson-river-mini-bear') THEN wp.website_session_id ELSE NULL END) AS cthru_sessions,
	COUNT(DISTINCT CASE WHEN pageview_url IN ('/the-birthday-sugar-panda', '/the-original-mr-fuzzy', '/the-forever-love-bear','/the-hudson-river-mini-bear') THEN wp.website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN pageview_url='/products' THEN wp.website_session_id ELSE NULL END) AS ct_rate,
	COUNT(DISTINCT CASE WHEN pageview_url='/thank-you-for-your-order' THEN wp.website_session_id ELSE NULL END) AS cthruorder_sessions,
	COUNT(DISTINCT CASE WHEN pageview_url='/thank-you-for-your-order' THEN wp.website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN pageview_url='/products' THEN wp.website_session_id ELSE NULL END) AS ct_orderrate
 
FROM website_pageviews wp 
WHERE wp.pageview_url IN ('/products','/the-birthday-sugar-panda', '/the-original-mr-fuzzy', '/the-forever-love-bear','/the-hudson-river-mini-bear','/thank-you-for-your-order')
GROUP BY 1, 2;
-- ------------ ------------ ------------ ------------ ------------ ------------ ----------
-- 	7. 	We made our 4th product available as a primary product on Dec 5, 2014 (it was previously only a cross-sell
-- 		item).  Could you please pull sales date since then, and show how well each product cross-sells from one 
-- 		another?
-- ------------ ------------ ------------ ------------ ------------ ------------ ----------
SELECT
	COUNT(DISTINCT o.order_id) AS n_orders,
    o.primary_product_id AS prod,
    COUNT(DISTINCT CASE WHEN oi.product_id=1 AND oi.is_primary_item=0 THEN order_id ELSE NULL END) AS 1_cr_sold,
    COUNT(DISTINCT CASE WHEN oi.product_id=2 AND oi.is_primary_item=0 THEN order_id ELSE NULL END) AS 2_cr_sold,
    COUNT(DISTINCT CASE WHEN oi.product_id=3 AND oi.is_primary_item=0 THEN order_id ELSE NULL END) AS 3_cr_sold,
    COUNT(DISTINCT CASE WHEN oi.product_id=4 AND oi.is_primary_item=0 THEN order_id ELSE NULL END) AS 4_cr_sold,
    COUNT(DISTINCT CASE WHEN oi.product_id=1 AND oi.is_primary_item=0 THEN order_id ELSE NULL END)/COUNT(DISTINCT o.order_id) AS 1_cr_sold_rt,
    COUNT(DISTINCT CASE WHEN oi.product_id=2 AND oi.is_primary_item=0 THEN order_id ELSE NULL END)/COUNT(DISTINCT o.order_id) AS 2_cr_sold_rt,
    COUNT(DISTINCT CASE WHEN oi.product_id=3 AND oi.is_primary_item=0 THEN order_id ELSE NULL END)/COUNT(DISTINCT o.order_id) AS 3_cr_sold_rt,
    COUNT(DISTINCT CASE WHEN oi.product_id=4 AND oi.is_primary_item=0 THEN order_id ELSE NULL END)/COUNT(DISTINCT o.order_id) AS 4_cr_sold_rt

FROM order_items oi 
	LEFT JOIN orders o USING (order_id)
WHERE o.created_at >='2014-12-05'
GROUP BY 2;