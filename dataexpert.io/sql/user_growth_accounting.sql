/*
 *  User Growth Accounting
 * 
 *  Example from dataexpert.io - basic extension of the cumulative user pattern..
 *
 *	In this case, goal is to track user states (DAU, 
 *
 */


CREATE TABLE public.user_growth (
	user_id TEXT, 
	first_active_date DATE,
	last_active_date DATE,
	daily_active_state TEXT,
	dates_active DATE[],
	date DATE,
	PRIMARY KEY (user_id, date)
)

DELETE FROM public.user_growth

/* Evetns has user_id, event_time (as TEXT) 
SELECT * FROM postgres.public.events e -- 
*/

INSERT INTO public.user_growth
WITH e AS (
	SELECT CAST(user_id AS TEXT) user_id, DATE(event_time) date
	FROM postgres.public.events 
	WHERE user_id IS NOT NULL
), yesterday AS (
	SELECT * FROM public.user_growth
	WHERE date = DATE('2023-01-29')
), today AS (
	SELECT 
		user_id, date AS today_date, COUNT(1) cnt
	FROM e 
	WHERE date = DATE('2023-01-30')
	GROUP BY user_id, date
)
SELECT
	COALESCE(t.user_id, y.user_id) user_id,
	COALESCE(y.first_active_date, t.today_date) first_active_date, -- IF EXISTS, KEEP 
	COALESCE(t.today_date, y.last_active_date) last_active_date,  -- IF today, KEEP 
	CASE  -- how TO determine the states: NEW, retained, resurrected, stale, chrned
	  WHEN y.user_id IS NULL AND t.user_id IS NOT NULL THEN 'new'
	  WHEN y.last_active_date = t.today_date - INTERVAL '1 day' THEN 'retainied' -- IS NOT NULL AND t.user_id 
	  WHEN y.last_active_date < t.today_date - INTERVAL '1 day' THEN 'resurrected' -- skipped a DAY..
	  WHEN t.today_date IS NULL AND y.last_active_date = y.date THEN 'churned'   -- Churn IF they were active yesterday..
	  WHEN t.today_date IS NULL AND y.last_active_date < y.date THEN 'stale'     -- IN this CASE, 2 DAY stale..
	END daily_active_state,
	COALESCE(y.dates_active, ARRAY[]::DATE[]) || CASE WHEN t.user_id IS NOT NULL THEN ARRAY[t.today_date] ELSE ARRAY[]::DATE[] END date_list,
	COALESCE(t.today_date, y.date + INTERVAL '1 day') date
FROM today t 
FULL OUTER JOIN yesterday y
ON t.user_id = y.user_id

SELECT * FROM user_growth ORDER BY user_id

SELECT date, daily_active_state, COUNT(*) CNT FROM user_growth GROUP BY date, daily_active_state ORDER BY daily_active_state 

SELECT COUNT(*), COUNT(DISTINCT user_id) FROM user_growth
-- SELECT date, count(*) total FROM e GROUP BY date ORDER BY date

/*
 * 	Ok - with growth accounting table, can do some sort of survivor analysis...
 *  Look at days since first active (oops, mispelled retained..
 *  1. Look at a cohort (all with first_active_date = 'some-date'
 *  2. Look at all users, as days since first active, (could further segment, e.g. day of week, dow, EXTRACT(dow FROM date)
 *  3. Zach adds DOW EXTRACT(DOW FROM first_active_date) as example of how to further slice/segment/analyze..
 */
SELECT -- FIRST query
	date,
  	COUNT(CASE WHEN daily_active_state IN ('new','retainied', 'resurrected') THEN 1 END),
  	COUNT(1) 
 FROM user_growth
 WHERE first_active_date='2023-01-01'
 GROUP BY date
 ORDER BY date

 
 SELECT -- expanding the cohorts
	date - first_active_date days_since_active,
  	COUNT(CASE WHEN daily_active_state IN ('new','retainied', 'resurrected') THEN 1 END) active,
  	COUNT(1) total,
  	ROUND(CAST(COUNT(CASE WHEN daily_active_state IN ('new','retainied', 'resurrected') THEN 1 END) AS NUMERIC) / COUNT(1), 2) prct_active
 FROM user_growth
 GROUP BY date - first_active_date
 ORDER BY date - first_active_date

 