/*
 * 	Examples of grouping..  GROUPING SETS
 *  I did put the GROUPING SETS output into public.events_dashboard
 * 
 *  CUBE also does ALL NULL aggregations -> 
 *  ROLLUP does NULL aggregation left to right, e.g.
 *  -- GROUP BY ROLLUP(os_type,device_type,browser_type)
 */
--CREATE TABLE public.events_dashboard AS 


WITH events_augmented AS (
	SELECT 
		COALESCE(d.os_type, 'unknown') os_type,
		COALESCE(d.device_type, 'unknown') device_type,
		COALESCE(d.browser_type, 'unknown') browser_type,
		url,
		user_id
	FROM postgres.public.events e JOIN postgres.public.devices d 
	ON e.device_id = d.device_id
)
SELECT 
	GROUPING(os_type) os_group,
	GROUPING(device_type) device_group,
	GROUPING(browser_type) browser_group,
	CASE 
		WHEN GROUPING(os_type) = 0 AND GROUPING(device_type)=0 AND GROUPING(browser_type)=0 THEN '_all_'
		WHEN GROUPING(os_type) = 0 THEN '_os_'
		WHEN GROUPING(device_type)=0 THEN '_device_'
		WHEN GROUPING(browser_type)=0 THEN '_browser_'
	END AS aggregation_level,
	COALESCE(os_type, '(overall)') os_type,
	COALESCE(device_type, '(overall)') device_type,
	COALESCE(browser_type, '(overall)') browser_type,
	COUNT(1) hits
	FROM events_augmented 
	GROUP BY ROLLUP(os_type,device_type,browser_type)
	ORDER BY hits DESC
	
	GROUP BY GROUPING SETS(
	  (os_type,device_type,browser_type),
	  (os_type),
	  (device_type),
	  (browser_type)
	)
	ORDER BY hits DESC
	

SELECT * FROM public.events_dashboard