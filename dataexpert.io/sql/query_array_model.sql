/*
 * Aggregation Example - the table array_metrics is a reduced fact data example, where the daily
 * data is being cumulated and maintained within an array.  First array element (index 1) is the 
 * 1st day in the month..  So this query does a global aggregation on the metric, and explodes 
 * the monthly data into daily values..
 * 
 * Recall: Date + Int => Date in PSQL, so using the index from the ORDINALITY in the CROSS JOIN UNNEST
 * allows recreation of the daily_date
 * 
 * From Data with Zac - December 2024 - "How Meta Models Big Volume Event Data"
 */
WITH agg AS (

  SELECT 
  	metric_name, month_start, 
  	ARRAY[ SUM(metric_array[1]),
			SUM(metric_array[2]),
			SUM(metric_array[3]),
			SUM(metric_array[4]),
			SUM(metric_array[5]) ] AS summed_array
  FROM postgres.public.array_metrics 
  GROUP BY metric_name, month_start
)
SELECT 
  metric_name, month_start+CAST(i-1 AS INT), e AS VA
  LUE, i AS IDX
FROM agg CROSS JOIN UNNEST(agg.summed_array) WITH ORDINALITY AS a(e, i)