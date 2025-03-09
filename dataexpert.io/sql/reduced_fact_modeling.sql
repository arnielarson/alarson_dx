/*
 * Example of generating a Reduced Fact Table - aggregated on the month (month_date)
 * Much quicker than a daily aggregate, with a ton of added complexity in the queries.
 * 
 * Note - to maintain this dataset, assumes any dimension tables are effectively fixed for the month.
 * 
 * 1. Create the metrics table "array_metrics"
 * 2. Create the accumulation query -> full outer join new event data with data from the array_metrics 
 *    (Is basically idempotent, uses INSERT INTO .. ON CONFLICT UPDATE .. )
 *    (Array aggregation is a little gnarley, to make sure that all users have a value for each day processed..)
 * 
 * 3. Does a INSERT INTO [SELECT] ON CONFLICT UPDATE set ..
 *    Since is being partitioned on a date, this could be used to do a backfill..  e.g. 
 */
--CREATE TABLE postgres.public.array_metrics ( 
--  user_id NUMERIC, 
--  month_start DATE, 
--  metric_name TEXT, 
--  metric_array INTEGER[],
--  PRIMARY KEY (user_id, month_start, metric_name)
--
--)
--

WITH daily_agg AS (
	SELECT 
		user_id, 
		CAST(event_time AS DATE) AS date,
		COUNT(*) num_hits
	FROM postgres.public.events
	WHERE CAST(event_time AS DATE) = DATE('2023-01-06')
	AND user_id IS NOT NULL 
	GROUP BY user_id, CAST(event_time AS DATE)
	
), yesterday_agg AS (
	SELECT * FROM postgres.public.array_metrics 
	WHERE month_start = DATE('2023-01-01')  -- This really should be 
)
INSERT INTO postgres.public.array_metrics
SELECT 
	COALESCE(da.user_id, ya.user_id) user_id,
	COALESCE(ya.month_start, DATE_TRUNC('month', da.date)) month_start,
	'site_hits' AS metric_name,
	CASE 
		-- First Case is a concat operator, adding a new element to the existing array 
		-- Second case is a new user, need to add a array filled with 0's if you want to maintain the daily order of the metric_array 
		WHEN ya.metric_array IS NOT NULL THEN ya.metric_array || ARRAY[COALESCE(da.num_hits, 0)]
		WHEN ya.metric_array IS NULL THEN ARRAY_FILL(0, ARRAY[COALESCE(date - DATE(DATE_TRUNC('month',date)),0)] ) || ARRAY[COALESCE(da.num_hits, 0)]
	END AS metric_array
		
FROM daily_agg da FULL OUTER JOIN yesterday_agg ya
ON da.user_id = ya.user_id 
ON CONFLICT(user_id, month_start, metric_name)
DO 
	UPDATE SET metric_array = EXCLUDED.metric_array;



-- 16k events, 1.4k users, 400 urls..
-- Time frame: 01-01 to 01-31 (2023)
-- SELECT MIN(CAST(event_time AS DATE)) date_start, MAX(CAST(event_time AS DATE)) date_end, COUNT(*) T, COUNT(DISTINCT user_id) USERS, COUNT(DISTINCT url) URLS FROM postgres.public.events


SELECT 
  UNNEST(ARRAY_FILL(3,ARRAY[1])) r
  
  
SELECT EXTRACT(MONTH FROM NOW())


