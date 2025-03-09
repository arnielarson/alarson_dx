/*
 *	Funnel Analysis.. 
 *
 *  2 events, conversion came after hypothesis object
 *  Where event2 came after event1 - can find conversion rates..
 * 
 *	user_id, url, event_time, event_date
 *
 *	1. Deduplicate (issues with the logger?) group by the primary key
 *
 *	2. Events - ('/signup', 'api/v1/users')  Note, this is not in the data
 *
 *	3. Self join on deduplicated data - and look for funnel matches:
 *  	Join on user_id, on date, where d2.event_time > d1.event_time
 * 
 *  4. Count conversions -> get converted users when they hit the destination url
 *     MAX(CASE WHEN dest_url = '/api/v1/users'THEN 1 ELSE 0 ) 
 *     GROUP BY user_id
 * 
 * 	5. Can create a conversion rate - (number of converts against people who clicked signups)
 * 
 * 	6. Can also look at any page that lead to a conversion..  
 */

SELECT url, COUNT(*) 
FROM public.events WHERE url LIKE '%api%'	
GROUP BY 1
ORDER BY 2 DESC

/*
 * 	His example doesn't WORK exactly, 
 *  So still going to write through the code.. could use the /api/v1/login maybe?
 */ 

WITH deduped AS (
	SELECT
		user_id, url, event_time, DATE(event_time) event_date
	FROM public.events 
	WHERE user_id IS NOT NULL AND url IN ('/signup', '/api/search?folderIds=0','/api/v1/login')
	GROUP BY 1, 2, 3, 4
)
SELECT d1.user_id, d1.url first_url, d2.url second_url, d1.event_date, d1.event_time t1, d2.event_time t2
FROM deduped d1 JOIN deduped d2 
ON d1.user_id = d2.user_id 
AND d1.event_date = d2.event_date
AND d2.event_time > d1.event_time
AND d1.url <> d2.url

