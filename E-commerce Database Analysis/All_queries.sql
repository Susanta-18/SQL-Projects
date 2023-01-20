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
