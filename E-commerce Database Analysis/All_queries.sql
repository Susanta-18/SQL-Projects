/* New Massage from CEO on April 12, 2012
Good Morning,
We have been live almost a month now we are starting to generate sales.
Can you help me understand where the bulk of our website session are coming form
through yeasterday?
I would like to see a breakdown by UTM source, Campaign, and referring domain if possible.
Thanks
*/

SELECT * FROM website_sessions;

SELECT 
utm_source, utm_campaign, http_referer, 
COUNT(DISTINCT(website_session_id)) AS `Session`
FROM 
website_sessions
WHERE created_at < '2012-04-12'
GROUP BY 
utm_source, utm_campaign,http_referer
ORDER BY `Session` DESC;
 -- it seems like we should probably dig into gsearch nonbrand a bit deeper to see what we can do to optimize there.
 
 /* New Massage from Marketing Director on April 14, 2012
Hi there,
Sounds like gsearch nonbrand is our major traffic source, but we need to understand if those sessions are driving sales.
Could you please calculate the conversion rate (CVR) from session to order? Based on what we're paying for clicks, 
we’ll need a CVR of at least 4% to make the numbers work.
If we're much lower, we’ll need to reduce bids. If we’re
higher, we can increase bids to drive more volume.
Thanks, Tom
 */ 
 
SELECT 
utm_source, utm_campaign, http_referer, 
COUNT(DISTINCT(website_sessions.website_session_id)) AS `Session`,
COUNT(orders.order_id) as Total_orders,
COUNT(orders.order_id) / COUNT(DISTINCT(website_sessions.website_session_id)) AS CVR
FROM website_sessions
LEFT JOIN orders ON orders.website_session_id = website_sessions.website_session_id
WHERE
website_sessions.created_at < '2012-04-14'
GROUP BY 
utm_source, utm_campaign,http_referer
ORDER BY Total_orders DESC;


/*New Massage from Marketing Director on May 12, 2012
Hi there,
Based on your conversion rate analysis, we bid down gsearch nonbrand on 2012-04-15.
Can you pull gsearch nonbrand trended session volume, by week, to see if the bid changes have caused volume to drop at all?
Thanks, Tom
 */ 
 
SELECT 
MIN(DATE(created_at)) as Week_start_date,
COUNT(DISTINCT(website_session_id)) AS `Session`
FROM 
website_sessions
WHERE created_at < '2012-05-10' AND utm_source = 'gsearch' AND utm_campaign = 'nonbrand'
GROUP BY 
YEARWEEK(created_at);


/* New massage from Marketing Director on May 11, 2012
Hi there,
I was trying to use our site on my mobile device the other day, and the experience was not great.
Could you pull conversion rates from session to order, by
device type?
If desktop performance is better than on mobile we may be able to bid up for desktop specifically to get more volume?
Thanks, Tom
 */
SELECT 
device_type,
COUNT(DISTINCT(website_sessions.website_session_id)) AS Sessions,
COUNT(DISTINCT(orders.order_id)) AS Orders,
COUNT(DISTINCT(orders.order_id)) / COUNT(DISTINCT(website_sessions.website_session_id)) AS CVR
FROM 
website_sessions
LEFT JOIN orders ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at <'2012-05-11' AND utm_source = 'gsearch' AND utm_campaign = 'nonbrand'
GROUP BY 
device_type;

/* New massage from Marketing Director on June 09, 2012
Hi there,
After your device-level analysis of conversion rates, we realized desktop was doing well, 
so we bid our gsearch nonbrand desktop campaigns up on 2012-05-19.
Could you pull weekly trends for both desktop and mobile
so we can see the impact on volume?
You can use 2012-04-15 until the bid change as a baseline. Thanks, Tom
 */

SELECT 
	MIN(DATE(created_at)) as Week_start_date,
	COUNT(CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS device_type_M,
	COUNT(CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) AS device_type_D
FROM 
	website_sessions
WHERE 
	created_at > '2012-4-15' 
    AND created_at < '2012-6-09' 
    AND utm_source = 'gsearch' 
    AND utm_campaign = 'nonbrand'
GROUP BY
	YEARWEEK(created_at);
    
-- *******************************************
-- BUSINESS CONCEPT: Website Measurement & Testing
-- *******************************************

/*Website content analysis is about understanding which pages are seen the most by your users, 
to identify where to focus on improving your business */

 /* Massage from Website Manager on June 9, 2012
 Hi there!
I’m Morgan, the new Website Manager.
Could you help me get my head around the site by pulling the most-viewed website pages, ranked by session volume?
Thanks!
-Morgan
*/   
    
SELECT
pageview_url,
COUNT(DISTINCT website_pageview_id) AS Sessions
FROM 
website_pageviews
WHERE 
created_at < '2012-06-09'
GROUP BY
pageview_url
ORDER BY 
Sessions DESC;


/* Massage from Website Manager on June 12, 2012
Hi there!
Would you be able to pull a list of the top entry pages? I want to confirm where our users are hitting the site.
If you could pull all entry pages and rank them on entry volume, that would be great.
Thanks!
-Morgan
 */

CREATE TEMPORARY TABLE First_Page_view
SELECT
website_session_id,
MIN(website_pageview_id) FPV -- FIRST PAGE VIEW
FROM 
website_pageviews
WHERE created_at < '2012-06-12'
GROUP BY website_session_id;

select * from First_Page_view;

SELECT 
website_pageviews.pageview_url AS Landing_Page,
COUNT(DISTINCT First_Page_view.website_session_id) AS session_hitting_this_landing_page
FROM 
First_Page_view
LEFT JOIN 
website_pageviews 
ON website_pageviews.website_pageview_id = First_Page_view.FPV
GROUP BY
Landing_Page;


-- STEP 1: Finding the first website_pageview_id for relevant session
-- STEP 2: identifying the landing page for each session
-- STEP 3: counting page view for each session to identify "bounces"
-- STEP 4: summarizing by counting total session and bounced sessions 

-- STEP 1: Finding the first website_pageview_id for relevant session
CREATE TEMPORARY TABLE first_wpview
SELECT
website_session_id,
MIN(website_pageview_id) AS first_wpview_id
FROM 
website_pageviews
WHERE 
created_at < '2012-06-14'
GROUP BY
website_session_id;

SELECT * FROM first_wpview;

-- STEP 2: identifying the landing page for each session

CREATE TEMPORARY TABLE session_w_home_landing_page
SELECT
first_wpview.website_session_id,
website_pageviews.pageview_url
FROM 
first_wpview
LEFT JOIN website_pageviews ON 
website_pageviews.website_pageview_id = first_wpview.first_wpview_id
WHERE 
website_pageviews.pageview_url = '/home';

SELECT * FROM session_w_home_landing_page;

-- STEP 3: counting page view for each session to identify "bounces"

CREATE TEMPORARY TABLE bounced_session
SELECT 
session_w_home_landing_page.website_session_id,
session_w_home_landing_page.pageview_url,
COUNT(DISTINCT website_pageviews.website_pageview_id) AS total_page_view
FROM session_w_home_landing_page
LEFT JOIN website_pageviews ON
website_pageviews.website_session_id = session_w_home_landing_page.website_session_id
GROUP BY 
session_w_home_landing_page.website_session_id,
session_w_home_landing_page.pageview_url
HAVING
total_page_view = 1;

SELECT * FROM bounced_session;

-- -- STEP 4: summarizing by counting total session and bounced sessions 

SELECT 
COUNT(DISTINCT session_w_home_landing_page.website_session_id) AS Sessions,
COUNT(DISTINCT bounced_session.website_session_id) AS bounced_sessions,
COUNT(DISTINCT bounced_session.website_session_id) / COUNT(DISTINCT session_w_home_landing_page.website_session_id) AS bounce_rate
FROM 
session_w_home_landing_page
LEFT JOIN bounced_session ON 
bounced_session.website_session_id = session_w_home_landing_page.website_session_id;


/* 
Massage from Website Manager on JULY 28, 2012
Hi there!
Based on your bounce rate analysis, we ran a new custom landing page (/lander-1)
in a 50/50 test against the homepage (/home) for our gsearch nonbrand traffic.
Can you pull bounce rates for the two groups so we can evaluate the new page? 
Make sure to just look at the time period where /lander-1 was getting traffic, so that it is a fair comparison.
Thanks, Morgan
 */ 

-- STEP 1: Finding the first website_pageview_id for relevant session
-- STEP 2: identifying the landing page for each session
-- STEP 3: counting page view for each session to identify "bounces"
-- STEP 4: summarizing by counting total session and bounced sessions 

-- STEP 1: Finding the first website_pageview_id for relevant session

CREATE TEMPORARY TABLE first_webpv_1
SELECT 
website_pageviews.website_session_id,
MIN(website_pageviews.website_pageview_id) AS first_webpv_id
FROM 
website_pageviews
INNER JOIN website_sessions ON 
website_sessions.website_session_id = website_pageviews.website_session_id
AND website_sessions.created_at < '2012-07-28'
AND website_pageviews.website_pageview_id > 23504
AND website_sessions.utm_source = 'gsearch'
AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY 
website_pageviews.website_session_id;

SELECT * FROM first_webpv_1;

-- STEP 2: identifying the landing page for each session

CREATE TEMPORARY TABLE session_w_first_webpv_1
SELECT
first_webpv_1.website_session_id,
website_pageviews.pageview_url
FROM 
first_webpv_1
LEFT JOIN website_pageviews ON 
website_pageviews.website_pageview_id = first_webpv_1.first_webpv_id
WHERE 
website_pageviews.pageview_url IN ('/lander-1','/home');

SELECT * FROM session_w_first_webpv_1;

-- STEP 3: counting page view for each session to identify "bounces"

CREATE TEMPORARY TABLE bounced_sessions_3
SELECT 
session_w_first_webpv_1.website_session_id,
session_w_first_webpv_1.pageview_url,
COUNT( DISTINCT website_pageview_id) AS total_webpv
FROM
session_w_first_webpv_1
LEFT JOIN website_pageviews ON
website_pageviews.website_session_id = session_w_first_webpv_1.website_session_id
GROUP BY 
session_w_first_webpv_1.website_session_id,
session_w_first_webpv_1.pageview_url
HAVING total_webpv = 1;

SELECT * FROM bounced_sessions_3;

-- STEP 4: summarizing by counting total session and bounced sessions 

SELECT 
session_w_first_webpv_1.pageview_url,
COUNT(DISTINCT session_w_first_webpv_1.website_session_id) AS Sessions,
COUNT(DISTINCT bounced_sessions_3.website_session_id) AS bounced_sessions,
COUNT(DISTINCT bounced_sessions_3.website_session_id) / COUNT(DISTINCT session_w_first_webpv_1.website_session_id) AS bounce_rate
FROM 
session_w_first_webpv_1
LEFT JOIN bounced_sessions_3 ON
bounced_sessions_3.website_session_id = session_w_first_webpv_1.website_session_id
GROUP BY 
session_w_first_webpv_1.pageview_url;

/* Massage from Website Manager on August 31, 2012
Hi there,
Could you pull the volume of paid search nonbrand traffic landing on /home and /lander-1, 
trended weekly since June 1st? I want to confirm the traffic is all routed correctly.
Could you also pull our overall paid search bounce rate trended weekly? 
I want to make sure the lander change has improved the overall picture.
Thanks!
 */

-- STEP 1: Finding the first website_pageview_id for relevant session
-- STEP 2: identifying the landing page for each session
-- STEP 3: counting page view for each session to identify "bounces"
-- STEP 4: summarizing by counting total session and bounced sessions 

CREATE TEMPORARY TABLE session_w_firstwpv_and_totalpv
SELECT 
website_sessions.website_session_id,
MIN(website_pageviews.website_pageview_id) first_webpv_id,
COUNT(website_pageviews.website_pageview_id) AS total_pv
FROM 
website_sessions
LEFT JOIN website_pageviews 
ON website_pageviews.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at > '2012-06-01' 
AND website_sessions.created_at < '2012-08-31'
AND website_sessions.utm_source = 'gsearch'
AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY 
website_sessions.website_session_id;

SELECT * FROM session_w_firstwpv_and_totalpv;

CREATE TEMPORARY TABLE session_w_landingpage
SELECT 
session_w_firstwpv_and_totalpv.website_session_id,
session_w_firstwpv_and_totalpv.first_webpv_id,
session_w_firstwpv_and_totalpv.total_pv,
website_pageviews.pageview_url AS landing_page,
website_pageviews.created_at AS session_created_at
FROM 
session_w_firstwpv_and_totalpv
LEFT JOIN website_pageviews ON
website_pageviews.website_pageview_id = session_w_firstwpv_and_totalpv.first_webpv_id;

SELECT * FROM session_w_landingpage;

SELECT
MIN(DATE(session_created_at)) AS week_start_date,
COUNT(DISTINCT website_session_id) AS total_session,
COUNT(DISTINCT CASE WHEN total_pv = 1 THEN website_session_id ELSE NULL END) AS bounced_session,
COUNT(DISTINCT CASE WHEN total_pv = 1 THEN website_session_id ELSE NULL END)/ COUNT(DISTINCT website_session_id) AS bounced_rate,
COUNT(DISTINCT CASE WHEN landing_page = '/home' THEN website_session_id ELSE NULL END) AS home_session,
COUNT(DISTINCT CASE WHEN landing_page = '/lander-1' THEN website_session_id ELSE NULL END) AS lander_session
FROM 
session_w_landingpage
GROUP BY 
YEARWEEK(session_created_at);


/* Massage from Website Manager on Sept 5, 2012
Hi there!
I’d like to understand where we lose our gsearch visitors between the new /lander-1 page and placing an order. 
Can you build us a full conversion funnel, analyzing how many customers make it to each step?
Start with /lander-1 and build the funnel all the way to our
thank you page. Please use data since August 5th.

Thanks!
-Morgan
 */ 
 
 SELECT 
 website_sessions.website_session_id,
 website_pageviews.pageview_url,
 website_pageviews.created_at,
 (CASE WHEN website_pageviews.pageview_url = '/lander-1' THEN 1 ELSE 0 END) AS lander_page,
 (CASE WHEN website_pageviews.pageview_url = '/products' THEN 1 ELSE 0 END) AS products_page,
 (CASE WHEN website_pageviews.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END) AS mr_fuzzy_page,
 (CASE WHEN website_pageviews.pageview_url = '/cart' THEN 1 ELSE 0 END) AS cart_page,
 (CASE WHEN website_pageviews.pageview_url = '/shipping' THEN 1 ELSE 0 END) AS shipping_page,
 (CASE WHEN website_pageviews.pageview_url = '/billing' THEN 1 ELSE 0 END) AS billing_page,
 (CASE WHEN website_pageviews.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END) AS thankyou_page
 FROM 
 website_sessions
	LEFT JOIN website_pageviews 
		ON website_pageviews.website_session_id = website_sessions.website_session_id
			WHERE website_sessions.created_at > '2012-08-05'
			AND website_sessions.created_at < '2012-09-05'
			AND website_sessions.utm_source = 'gsearch'
			AND website_sessions.utm_campaign = 'nonbrand'
			AND website_pageviews.pageview_url IN 
			('/lander-1', '/products', '/the-original-mr-fuzzy', '/cart','/shipping','/billing','/thank-you-for-your-order')
 ORDER BY
	website_sessions.website_session_id;
    
CREATE TEMPORARY TABLE lander_1_funnels
SELECT 
website_session_id,
MAX(lander_page) AS lander_page,
MAX(products_page) AS products_page,
MAX(mr_fuzzy_page) AS mr_fuzzy_page,
MAX(cart_page) AS cart_page,
MAX(shipping_page) AS shipping_page,
MAX(billing_page) AS billing_page,
MAX(thankyou_page) AS thankyou_page
FROM
( SELECT 
 website_sessions.website_session_id,
 website_pageviews.pageview_url,
 website_pageviews.created_at,
 (CASE WHEN website_pageviews.pageview_url = '/lander-1' THEN 1 ELSE 0 END) AS lander_page,
 (CASE WHEN website_pageviews.pageview_url = '/products' THEN 1 ELSE 0 END) AS products_page,
 (CASE WHEN website_pageviews.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END) AS mr_fuzzy_page,
 (CASE WHEN website_pageviews.pageview_url = '/cart' THEN 1 ELSE 0 END) AS cart_page,
 (CASE WHEN website_pageviews.pageview_url = '/shipping' THEN 1 ELSE 0 END) AS shipping_page,
 (CASE WHEN website_pageviews.pageview_url = '/billing' THEN 1 ELSE 0 END) AS billing_page,
 (CASE WHEN website_pageviews.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END) AS thankyou_page
 FROM 
 website_sessions
	LEFT JOIN website_pageviews 
		ON website_pageviews.website_session_id = website_sessions.website_session_id
			WHERE website_sessions.created_at > '2012-08-05'
			AND website_sessions.created_at < '2012-09-05'
			AND website_sessions.utm_source = 'gsearch'
			AND website_sessions.utm_campaign = 'nonbrand'
			AND website_pageviews.pageview_url IN 
			('/lander-1', '/products', '/the-original-mr-fuzzy', '/cart','/shipping','/billing','/thank-you-for-your-order')
 ORDER BY
	website_sessions.website_session_id
) AS pageview_lavel
GROUP BY 
website_session_id;

SELECT * FROM lander_1_funnels;

SELECT
COUNT(DISTINCT website_session_id) AS total_session,
-- COUNT(DISTINCT CASE WHEN lander_page = 1 THEN website_session_id ELSE NULL END) AS lander_page ,
COUNT(DISTINCT CASE WHEN products_page = 1 THEN website_session_id ELSE NULL END) AS products_page ,
COUNT(DISTINCT CASE WHEN mr_fuzzy_page=1 THEN website_session_id ELSE NULL END ) AS mr_fuzzy_page ,
COUNT(DISTINCT CASE WHEN cart_page=1 THEN website_session_id ELSE NULL END)AS cart_page,
COUNT( DISTINCT CASE WHEN shipping_page=1 THEN website_session_id ELSE NULL END) AS shipping_page,
COUNT(DISTINCT CASE WHEN billing_page= 1 THEN website_session_id ELSE NULL END) AS billing_page ,
COUNT(DISTINCT CASE WHEN thankyou_page=1 THEN website_session_id ELSE NULL END) AS thankyou_page
FROM lander_1_funnels;


SELECT
	COUNT(DISTINCT website_session_id) AS total_session,
	COUNT(DISTINCT CASE WHEN products_page = 1 THEN website_session_id ELSE NULL END)/
	COUNT(DISTINCT website_session_id) 
    AS clickedto_products_page ,
	COUNT(DISTINCT CASE WHEN mr_fuzzy_page=1 THEN website_session_id ELSE NULL END )/
	COUNT(DISTINCT CASE WHEN products_page = 1 THEN website_session_id ELSE NULL END) 
    AS clickedto_mr_fuzzy_page ,
	COUNT(DISTINCT CASE WHEN cart_page=1 THEN website_session_id ELSE NULL END)/
	COUNT(DISTINCT CASE WHEN mr_fuzzy_page=1 THEN website_session_id ELSE NULL END ) 
    AS clickedto_cart_page,
	COUNT( DISTINCT CASE WHEN shipping_page=1 THEN website_session_id ELSE NULL END)/
	COUNT(DISTINCT CASE WHEN cart_page=1 THEN website_session_id ELSE NULL END) 
    AS clickedto_shipping_page,
	COUNT(DISTINCT CASE WHEN billing_page= 1 THEN website_session_id ELSE NULL END)/
	COUNT( DISTINCT CASE WHEN shipping_page=1 THEN website_session_id ELSE NULL END)
    AS clickedto_billing_page ,
	COUNT(DISTINCT CASE WHEN thankyou_page=1 THEN website_session_id ELSE NULL END)/
	COUNT(DISTINCT CASE WHEN billing_page= 1 THEN website_session_id ELSE NULL END) 
    AS clickedto_thankyou_page
FROM lander_1_funnels;

/*Massage from Website Manager on Nov 10, 2012
Hello!
We tested an updated billing page based on your funnel analysis. 
Can you take a look and see whether /billing-2 is doing any better than the original /billing page?
We’re wondering what % of sessions on those pages end up placing an order. 
FYI – we ran this test for all traffic, not just for our search visitors.

Thanks!
-Morgan
 */ 

SELECT
website_pageview_id,
MIN(created_at)
FROM 
website_pageviews
WHERE pageview_url = '/billing-2';

SELECT
pageview_url AS page_url,
COUNT(DISTINCT website_session_id) AS sessions,
COUNT(DISTINCT order_id) AS total_orders,
COUNT(DISTINCT order_id) / COUNT(DISTINCT website_session_id) AS bill_to_order_percentage
FROM(
SELECT
website_pageviews.website_session_id,
website_pageviews.pageview_url,
orders.order_id
FROM
website_pageviews
LEFT JOIN orders ON orders.website_session_id = website_pageviews.website_session_id
WHERE website_pageviews.created_at < '2012-11-10'
AND website_pageviews.website_pageview_id >= 53550
AND website_pageviews.pageview_url IN ('/billing', '/billing-2')) AS billing_session_w_orders
GROUP BY 
pageview_url;


/* Massage from CEO on Nov 27, 2012
Good morning,
I need some help preparing a presentation for the board meeting next week.
The board would like to have a better understanding of our growth story over our first 8 months. 
This will also be a good excuse to show off our analytical capabilities a bit.
-Cindy
*/

/*Gsearch seems to be the biggest driver of our business. Could you pull monthly trends for gsearch sessions
and orders so that we can showcase the growth there?
 */

SELECT 
YEAR(website_sessions.created_at) AS `year`,
MONTH(website_sessions.created_at) AS `month`,
COUNT(website_sessions.website_session_id) AS sessions,
COUNT(orders.order_id) AS orders,
COUNT(orders.order_id) / COUNT(website_sessions.website_session_id) AS CVR
FROM 
website_sessions
	LEFT JOIN orders ON orders.website_session_id = website_sessions.website_session_id
    WHERE website_sessions.utm_source = 'gsearch'
    AND website_sessions.created_at < '2012-11-27'
GROUP BY 
	1,2;


/*Next, it would be great to see a similar monthly trend for Gsearch, but this time splitting out nonbrand and brand campaigns separately. 
I am wondering if brand is picking up at all. If so, this is a good story to tell. */

SELECT 
YEAR(website_sessions.created_at) AS `year`,
MONTH(website_sessions.created_at) AS `month`,
COUNT(website_sessions.website_session_id) AS total_sessions,
COUNT(CASE WHEN website_sessions.utm_campaign = 'brand' THEN website_sessions.website_session_id ELSE NULL END) AS brand_sessions,
COUNT(CASE WHEN website_sessions.utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS nonbrand_sessions,
COUNT(orders.order_id) AS total_orders,
COUNT(CASE WHEN website_sessions.utm_campaign = 'brand' THEN orders.order_id ELSE NULL END) AS brand_orders,
COUNT(CASE WHEN website_sessions.utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END) AS nonbrand_orders
FROM 
website_sessions
	LEFT JOIN orders ON orders.website_session_id = website_sessions.website_session_id
    WHERE website_sessions.utm_source = 'gsearch'
    -- AND website_sessions.utm_campaign IN ('brand','nonbrand')
    AND website_sessions.created_at < '2012-11-27'
GROUP BY 
	1,2;
    
    
/* While we’re on Gsearch, could you dive into nonbrand, and pull monthly sessions and orders split by device
type? I want to flex our analytical muscles a little and show the board we really know our traffic sources.
*/ 

SELECT 
YEAR(website_sessions.created_at) AS `year`,
MONTH(website_sessions.created_at) AS `month`,
COUNT(website_sessions.website_session_id) AS total_nonbrand_sessions,
COUNT(CASE WHEN website_sessions.device_type = 'mobile' THEN website_sessions.website_session_id ELSE NULL END) AS M_sessions,
COUNT(CASE WHEN website_sessions.device_type = 'desktop' THEN website_sessions.website_session_id ELSE NULL END) AS D_sessions,
COUNT(CASE WHEN website_sessions.utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END) AS total_nonbrand_orders,
COUNT(CASE WHEN website_sessions.device_type = 'mobile' THEN orders.order_id ELSE NULL END) AS M_orders,
COUNT(CASE WHEN website_sessions.device_type = 'desktop' THEN orders.order_id ELSE NULL END) AS D_orders
FROM 
website_sessions
	LEFT JOIN orders ON orders.website_session_id = website_sessions.website_session_id
    WHERE website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign IN ('nonbrand')
    AND website_sessions.created_at < '2012-11-27'
GROUP BY 
	1,2;
	

/*I’m worried that one of our more pessimistic board members may be concerned about the large % of traffic from
Gsearch. Can you pull monthly trends for Gsearch, alongside monthly trends for each of our other channels?
 */
 
SELECT 
YEAR(website_sessions.created_at) AS `year`,
MONTH(website_sessions.created_at) AS `month`,
COUNT( DISTINCT website_sessions.website_session_id) AS total_sessions,
COUNT(CASE WHEN website_sessions.utm_source = 'gsearch' THEN website_sessions.website_session_id ELSE NULL END) AS gsearch_sessions,
COUNT(CASE WHEN website_sessions.utm_source = 'bsearch' THEN website_sessions.website_session_id ELSE NULL END) AS bsearch_sessions,
COUNT(CASE WHEN website_sessions.utm_source IS NULL AND http_referer IS NOT NULL THEN website_sessions.website_session_id ELSE NULL END) AS organic_sessions,
COUNT(CASE WHEN website_sessions.utm_source IS NULL AND http_referer IS NULL THEN website_sessions.website_session_id ELSE NULL END) AS direct_sessions
FROM 
website_sessions
WHERE website_sessions.created_at < '2012-11-27'
GROUP BY
1,2;

/*I’d like to tell the story of our website performance improvements over the course of the first 8 months.
Could you pull session to order conversion rates, by month?
 */

SELECT 
YEAR(website_sessions.created_at) AS `year`,
MONTH(website_sessions.created_at) AS `months`,
COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
COUNT(DISTINCT orders.order_id) AS orders,
COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS CVR
FROM 
website_sessions
LEFT JOIN orders ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
GROUP BY
1,2;

/*For the gsearch lander test, please estimate the revenue that test earned us 
(Hint: Look at the increase in CVR from the test (Jun 19 – Jul 28), and 
use nonbrand sessions and revenue since then to calculate incremental value) */

SELECT 
MIN(website_pageview_id)
FROM website_pageviews
WHERE pageview_url = '/lander-1'; -- 23504

CREATE TEMPORARY TABLE first_pvid
SELECT 
website_sessions.website_session_id,
MIN(website_pageviews.website_pageview_id) AS first_landing_page_id
FROM 
website_pageviews
INNER JOIN website_sessions ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE 
website_sessions.created_at < '2012-7-28'
AND website_pageviews.website_pageview_id >= 23504
AND website_sessions.utm_source = 'gsearch'
AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY
website_sessions.website_session_id;

SELECT * FROM first_pvid;

CREATE TEMPORARY TABLE first_pvurl
SELECT 
first_pvid.website_session_id,
website_pageviews.pageview_url
FROM
first_pvid
LEFT JOIN website_pageviews ON website_pageviews.website_session_id = first_pvid.website_session_id
WHERE website_pageviews.pageview_url IN ('/home','/lander-1');

SELECT * FROM first_pvurl;

CREATE TEMPORARY TABLE 	order_table
SELECT 
first_pvurl.website_session_id,
first_pvurl.pageview_url,
orders.order_id
FROM 
first_pvurl
LEFT JOIN orders ON orders.website_session_id = first_pvurl.website_session_id;

SELECT * FROM order_table;

SELECT 
pageview_url,
COUNT(DISTINCT website_session_id) AS sessions,
COUNT(DISTINCT order_id) AS orders,
COUNT(DISTINCT order_id)/COUNT(DISTINCT website_session_id) AS CVR
FROM
order_table
GROUP BY
1;


/* Massage from CEO on Nov 27, 2012
Good morning,
I need some help preparing a presentation for the board meeting next week.
The board would like to have a better understanding of our growth story over our first 8 months. 
This will also be a good excuse to show off our analytical capabilities a bit.
-Cindy
*/

/*Gsearch seems to be the biggest driver of our business. Could you pull monthly trends for gsearch sessions
and orders so that we can showcase the growth there?
 */

SELECT 
YEAR(website_sessions.created_at) AS `year`,
MONTH(website_sessions.created_at) AS `month`,
COUNT(website_sessions.website_session_id) AS sessions,
COUNT(orders.order_id) AS orders,
COUNT(orders.order_id) / COUNT(website_sessions.website_session_id) AS CVR
FROM 
website_sessions
	LEFT JOIN orders ON orders.website_session_id = website_sessions.website_session_id
    WHERE website_sessions.utm_source = 'gsearch'
    AND website_sessions.created_at < '2012-11-27'
GROUP BY 
	1,2;


/*Next, it would be great to see a similar monthly trend for Gsearch, but this time splitting out nonbrand and brand campaigns separately. 
I am wondering if brand is picking up at all. If so, this is a good story to tell. */

SELECT 
YEAR(website_sessions.created_at) AS `year`,
MONTH(website_sessions.created_at) AS `month`,
COUNT(website_sessions.website_session_id) AS total_sessions,
COUNT(CASE WHEN website_sessions.utm_campaign = 'brand' THEN website_sessions.website_session_id ELSE NULL END) AS brand_sessions,
COUNT(CASE WHEN website_sessions.utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS nonbrand_sessions,
COUNT(orders.order_id) AS total_orders,
COUNT(CASE WHEN website_sessions.utm_campaign = 'brand' THEN orders.order_id ELSE NULL END) AS brand_orders,
COUNT(CASE WHEN website_sessions.utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END) AS nonbrand_orders
FROM 
website_sessions
	LEFT JOIN orders ON orders.website_session_id = website_sessions.website_session_id
    WHERE website_sessions.utm_source = 'gsearch'
    -- AND website_sessions.utm_campaign IN ('brand','nonbrand')
    AND website_sessions.created_at < '2012-11-27'
GROUP BY 
	1,2;
    
    
/* While we’re on Gsearch, could you dive into nonbrand, and pull monthly sessions and orders split by device
type? I want to flex our analytical muscles a little and show the board we really know our traffic sources.
*/ 

SELECT 
YEAR(website_sessions.created_at) AS `year`,
MONTH(website_sessions.created_at) AS `month`,
COUNT(website_sessions.website_session_id) AS total_nonbrand_sessions,
COUNT(CASE WHEN website_sessions.device_type = 'mobile' THEN website_sessions.website_session_id ELSE NULL END) AS M_sessions,
COUNT(CASE WHEN website_sessions.device_type = 'desktop' THEN website_sessions.website_session_id ELSE NULL END) AS D_sessions,
COUNT(CASE WHEN website_sessions.utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END) AS total_nonbrand_orders,
COUNT(CASE WHEN website_sessions.device_type = 'mobile' THEN orders.order_id ELSE NULL END) AS M_orders,
COUNT(CASE WHEN website_sessions.device_type = 'desktop' THEN orders.order_id ELSE NULL END) AS D_orders
FROM 
website_sessions
	LEFT JOIN orders ON orders.website_session_id = website_sessions.website_session_id
    WHERE website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign IN ('nonbrand')
    AND website_sessions.created_at < '2012-11-27'
GROUP BY 
	1,2;
	

/*I’m worried that one of our more pessimistic board members may be concerned about the large % of traffic from
Gsearch. Can you pull monthly trends for Gsearch, alongside monthly trends for each of our other channels?
 */
 
SELECT 
YEAR(website_sessions.created_at) AS `year`,
MONTH(website_sessions.created_at) AS `month`,
COUNT( DISTINCT website_sessions.website_session_id) AS total_sessions,
COUNT(CASE WHEN website_sessions.utm_source = 'gsearch' THEN website_sessions.website_session_id ELSE NULL END) AS gsearch_sessions,
COUNT(CASE WHEN website_sessions.utm_source = 'bsearch' THEN website_sessions.website_session_id ELSE NULL END) AS bsearch_sessions,
COUNT(CASE WHEN website_sessions.utm_source IS NULL AND http_referer IS NOT NULL THEN website_sessions.website_session_id ELSE NULL END) AS organic_sessions,
COUNT(CASE WHEN website_sessions.utm_source IS NULL AND http_referer IS NULL THEN website_sessions.website_session_id ELSE NULL END) AS direct_sessions
FROM 
website_sessions
WHERE website_sessions.created_at < '2012-11-27'
GROUP BY
1,2;

/*I’d like to tell the story of our website performance improvements over the course of the first 8 months.
Could you pull session to order conversion rates, by month?
 */

SELECT 
YEAR(website_sessions.created_at) AS `year`,
MONTH(website_sessions.created_at) AS `months`,
COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
COUNT(DISTINCT orders.order_id) AS orders,
COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS CVR
FROM 
website_sessions
LEFT JOIN orders ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
GROUP BY
1,2;

/*For the gsearch lander test, please estimate the revenue that test earned us 
(Hint: Look at the increase in CVR from the test (Jun 19 – Jul 28), and 
use nonbrand sessions and revenue since then to calculate incremental value) */

SELECT 
MIN(website_pageview_id)
FROM website_pageviews
WHERE pageview_url = '/lander-1'; -- 23504

CREATE TEMPORARY TABLE first_pvid
SELECT 
website_sessions.website_session_id,
MIN(website_pageviews.website_pageview_id) AS first_landing_page_id
FROM 
website_pageviews
INNER JOIN website_sessions ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE 
website_sessions.created_at < '2012-7-28'
AND website_pageviews.website_pageview_id >= 23504
AND website_sessions.utm_source = 'gsearch'
AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY
website_sessions.website_session_id;

SELECT * FROM first_pvid;

CREATE TEMPORARY TABLE first_pvurl
SELECT 
first_pvid.website_session_id,
website_pageviews.pageview_url
FROM
first_pvid
LEFT JOIN website_pageviews ON website_pageviews.website_session_id = first_pvid.website_session_id
WHERE website_pageviews.pageview_url IN ('/home','/lander-1');

SELECT * FROM first_pvurl;

CREATE TEMPORARY TABLE 	order_table
SELECT 
first_pvurl.website_session_id,
first_pvurl.pageview_url,
orders.order_id
FROM 
first_pvurl
LEFT JOIN orders ON orders.website_session_id = first_pvurl.website_session_id;

SELECT * FROM order_table;

SELECT 
pageview_url,
COUNT(DISTINCT website_session_id) AS sessions,
COUNT(DISTINCT order_id) AS orders,
COUNT(DISTINCT order_id)/COUNT(DISTINCT website_session_id) AS CVR
FROM
order_table
GROUP BY
1;

/*For the landing page test you analyzed previously, it would be great to show a full conversion funnel from each of the two pages to orders. 
You can use the same time period you analyzed last time (Jun 19 – Jul 28). */

CREATE TEMPORARY TABLE session_flag
SELECT 
website_session_id,
MAX(Home_page) AS saw_homepage,
MAX(lander_page) AS saw_landerpage,
MAX(products_page) AS products_page,
MAX(fuzzy_page) AS fuzzy_page,
MAX(cart_page) AS cart_page,
MAX(shipping_page) AS shipping_page,
MAX(billing_page) AS billing_page,
MAX(thanks_page) AS thankyou
FROM(
SELECT
website_sessions.website_session_id,
website_pageviews.pageview_url,
	CASE WHEN website_pageviews.pageview_url = '/home' THEN 1 ELSE 0 END AS Home_page,
   	CASE WHEN website_pageviews.pageview_url = '/lander-1' THEN 1 ELSE 0 END AS lander_page,
	CASE WHEN website_pageviews.pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
    	CASE WHEN website_pageviews.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS fuzzy_page,
	CASE WHEN website_pageviews.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    	CASE WHEN website_pageviews.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    	CASE WHEN website_pageviews.pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
    	CASE WHEN website_pageviews.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thanks_page  
FROM 
website_sessions
	LEFT JOIN website_pageviews ON website_pageviews.website_session_id = website_sessions.website_session_id
    	WHERE website_sessions.created_at <= '2012-07-28' AND website_sessions.created_at >= '2012-06-19'
    	AND website_sessions.utm_source = 'gsearch'
	AND website_sessions.utm_campaign = 'nonbrand'
ORDER BY
	website_sessions.website_session_id,
    	website_pageviews.created_at) AS pageview_levels
GROUP BY 
	website_session_id;
    
SELECT * FROM session_flag;


SELECT 
CASE 
    WHEN saw_homepage = 1 THEN 'home_page'
    WHEN saw_landerpage = 1 THEN 'lander_page'
    ELSE 'CHECK LOGIC'
    END AS segmnets,
 COUNT(DISTINCT website_session_id) AS sessions,
 COUNT(DISTINCT CASE WHEN products_page = 1 THEN website_session_id ELSE NULL END) AS PP,
 COUNT(DISTINCT CASE WHEN fuzzy_page = 1 THEN website_session_id ELSE NULL END) AS FP,
 COUNT(DISTINCT CASE WHEN cart_page = 1 THEN website_session_id ELSE NULL END) AS CP,
 COUNT(DISTINCT CASE WHEN shipping_page = 1 THEN website_session_id ELSE NULL END) AS SP,
 COUNT(DISTINCT CASE WHEN billing_page = 1 THEN website_session_id ELSE NULL END) AS BP,
 COUNT(DISTINCT CASE WHEN thankyou = 1 THEN website_session_id ELSE NULL END) AS TP
FROM
	session_flag
GROUP BY
	1;
    
    
SELECT 
CASE 
    WHEN saw_homepage = 1 THEN 'home_page'
    WHEN saw_landerpage = 1 THEN 'lander_page'
    ELSE 'CHECK LOGIC'
    END AS segmnets,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN products_page = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT website_session_id) AS PP_CVR, -- CVR = conversion rate
    COUNT(DISTINCT CASE WHEN fuzzy_page = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN products_page = 1 THEN website_session_id ELSE NULL END) AS FP_CVR,
    COUNT(DISTINCT CASE WHEN cart_page = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN fuzzy_page = 1 THEN website_session_id ELSE NULL END) AS CP_CVR,
    COUNT(DISTINCT CASE WHEN shipping_page = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN cart_page = 1 THEN website_session_id ELSE NULL END) AS SP_CVR,
    COUNT(DISTINCT CASE WHEN billing_page = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN shipping_page = 1 THEN website_session_id ELSE NULL END) AS BP_CVR,
    COUNT(DISTINCT CASE WHEN thankyou = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN billing_page = 1 THEN website_session_id ELSE NULL END) AS TP_CVR
FROM
	session_flag
GROUP BY
	1;
    
/*I’d love for you to quantify the impact of our billing test, as well. Please analyze the lift generated from the test (Sep 10 – Nov 10), 
in terms of revenue per billing page session, and then pull the number of billing page sessions for the past month to understand monthly impact.*/ 

SELECT
pageview_url,
COUNT(DISTINCT website_session_id) AS sessions,
SUM(price_usd)/COUNT(DISTINCT website_session_id) AS revenue_per_billing_page
FROM (
SELECT
website_pageviews.website_session_id,
website_pageviews.pageview_url,
orders.order_id,
orders.price_usd
FROM 
website_pageviews
LEFT JOIN orders ON orders.website_session_id = website_pageviews.website_session_id
WHERE 
website_pageviews.created_at >= '2012-09-10' AND website_pageviews.created_at <= '2012-11-10'
AND website_pageviews.pageview_url IN ('/billing', '/billing-2')) AS billing_session
GROUP BY
1;
-- billing page total session = 657 and revenue per billing page is 22.826
-- billing-2 page total session 654 and revenue per billing page is 31.339
-- lift generated 8.51

SELECT
COUNT(website_pageviews.website_session_id) AS total_sessions
FROM 
website_pageviews
WHERE 
website_pageviews.created_at >= '2012-10-27' AND website_pageviews.created_at <= '2012-11-27'
AND website_pageviews.pageview_url IN ('/billing', '/billing-2'); -- 1193 total session last month

-- lift generated (8.51 X 1193) = 10152.43 


-- CHANNEL PORTFOLIO OPTIMIZATION

/*Message received from Marketing Director on Nov. 29, 2012
Hi there,
With gsearch doing well and the site performing better, we launched a second paid search channel, bsearch, around August 22.
Can you pull weekly trended session volume since then and compare to gsearch nonbrand so I can get a sense for how important 
this will be for the business?
Thanks, Tom
 */
 
 SELECT 
 MIN(DATE(created_at)) AS week_start_date,
 COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN website_session_id ELSE NULL END) AS gsearch_sessions,
 COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN website_session_id ELSE NULL END) AS bsearch_sessions
 FROM 
 website_sessions
 WHERE website_sessions.created_at >= '2012-08-22' AND website_sessions.created_at <= '2012-11-29'
 AND utm_campaign = 'nonbrand'
 GROUP BY
 YEARWEEK(created_at);
 
 
 /*Message received from Marketing Director on Nov. 30, 2012
 Hi there,
I’d like to learn more about the bsearch nonbrand campaign. Could you please pull the percentage of traffic coming on Mobile, 
and compare that to gsearch?
Feel free to dig around and share anything else you find interesting. Aggregate data since August 22nd is great, 
no need to show trending at this point.
Thanks, Tom
 */
 
 
SELECT 
utm_source,
COUNT(DISTINCT website_session_id) AS total_session,
COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mobile_sessions,
COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS session_percentage
FROM 
website_sessions
WHERE
website_sessions.created_at >= '2012-08-22' AND website_sessions.created_at <= '2012-11-30'
AND utm_campaign = 'nonbrand'
GROUP BY 
utm_source;

/*
Hi there,
I’m wondering if bsearch nonbrand should have the same bids as gsearch. Could you pull nonbrand conversion rates from session to order 
for gsearch and bsearch, and slice the data by device type?
Please analyze data from August 22 to September 18; we ran a special pre-holiday campaign for gsearch starting on September 19th, 
so the data after that isn’t fair game.

Thanks, Tom
 */
 
SELECT 
website_sessions.device_type,
website_sessions.utm_source,
COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
COUNT(DISTINCT orders.order_id) AS total_orders,
COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS CVR
FROM 
website_sessions
LEFT JOIN orders ON orders.website_session_id = website_sessions.website_session_id
WHERE 
website_sessions.created_at >= '2012-08-22' AND website_sessions.created_at <= '2012-09-19'
AND utm_campaign = 'nonbrand'
GROUP BY
website_sessions.device_type,
website_sessions.utm_source
ORDER BY
CVR DESC;


/* December 22, 2012
Hi there,
Based on your last analysis, we bid down bsearch nonbrand on December 2nd.
Can you pull weekly session volume for gsearch and bsearch nonbrand, broken down by device, since November 4th?
If you can include a comparison metric to show bsearch as a percent of gsearch for each device, that would be great too.
Thanks, Tom
 */
 
SELECT
MIN(DATE(created_at)) AS week_start_date,
COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END) AS g_dtop_sessions,
COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END) AS b_dtop_sessions,
COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END)/
COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END) AS b_pct_of_g_dtop,
COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'mobile' THEN website_session_id ELSE NULL END) AS g_mob_sessions,
COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'mobile' THEN website_session_id ELSE NULL END) AS b_mob_sessions,
COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'mobile' THEN website_session_id ELSE NULL END)/
COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'mobile' THEN website_session_id ELSE NULL END) AS b_pct_of_g_mob
FROM 
website_sessions
WHERE 
website_sessions.created_at >= '2012-11-04' AND website_sessions.created_at <= '2012-12-22'
AND utm_campaign = 'nonbrand'
GROUP BY 
YEARWEEK(created_at);


/*December 23, 2012
Good morning,
A potential investor is asking if we’re building any
momentum with our brand or if we’ll need to keep relying
on paid traffic.
Could you pull organic search, direct type in, and paid brand search sessions by month, 
and show those sessions as a % of paid search nonbrand?
-Cindy
 */
 
SELECT
YEAR(created_at) AS `year`,
MONTH(created_at) AS `months`,
COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END) AS non_brand,
COUNT(DISTINCT CASE WHEN channel_group = 'paid_brand' THEN website_session_id ELSE NULL END) AS brand,
COUNT(DISTINCT CASE WHEN channel_group = 'paid_brand' THEN website_session_id ELSE NULL END)/
COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END) AS brand_pct_on_nonbrand,
COUNT(DISTINCT CASE WHEN channel_group = 'direct_type' THEN website_session_id ELSE NULL END) AS direct,
COUNT(DISTINCT CASE WHEN channel_group = 'direct_type' THEN website_session_id ELSE NULL END)/
COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END) AS direct_pct_on_nonbrand,
COUNT(DISTINCT CASE WHEN channel_group = 'organic_search' THEN website_session_id ELSE NULL END) AS organic,
COUNT(DISTINCT CASE WHEN channel_group = 'organic_search' THEN website_session_id ELSE NULL END)/
COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END) AS organic_pct_on_nonbrand
FROM
(
SELECT
website_session_id,
created_at,
	CASE
	WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com') THEN 'organic_search'
        WHEN utm_campaign = 'brand' THEN 'paid_brand'
	WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
        WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type'
        ELSE 'check logic'
        END AS channel_group
FROM 
website_sessions
WHERE website_sessions.created_at <= '2012-12-23') AS session_w_channel_group
GROUP BY 1,2;
