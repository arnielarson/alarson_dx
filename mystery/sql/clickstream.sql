z/*
	Wikepedia Clickstream analysis
	I load in several monthly aggregates of the clickstream data.
	Each file is ~ 1.5GB, 30M+ records and is a break down of: referrer, page, referral_type, count
*/

CREATE TABLE IF NOT EXISTS public.wiki_clickstream_1 (
	referrer TEXT,
	resource TEXT,
	internal TEXT,
	count INT
)

/*
 * Had to remove some lines with: Control-\ in the data to use the COPY method...
 * % awk -F "\t" '$1 !~ /\\$/ && $2 !~ /\\$/ {print}' clickstream-enwiki-2020-01.tsv > clickstream01.tsv
 */
COPY public.wiki_clickstream_1 
FROM '/Users/arnie/Data/clickstream01.tsv' (ON_ERROR ignore);

COPY public.wiki_clickstream_1 
FROM '/Users/arnie/Data/clickstream02.tsv' (ON_ERROR ignore);

COPY public.wiki_clickstream_1 
FROM '/Users/arnie/Data/clickstream03.tsv' (ON_ERROR ignore);

COPY public.wiki_clickstream_1 
FROM '/Users/arnie/Data/clickstream04.tsv' (ON_ERROR ignore);

COPY public.wiki_clickstream_1 
FROM '/Users/arnie/Data/clickstream05.tsv' (ON_ERROR ignore);

COPY public.wiki_clickstream_1 
FROM '/Users/arnie/Data/clickstream06.tsv' (ON_ERROR ignore);


SELECT COUNT(1) FROM public.wiki_clickstream_1 

/*
 *  Best way to do analytics??   Testing on 1 file..
 *  Group By, get top 100.. a little over 1 minute
 */ 
WITH cs01_gb AS (
	SELECT resource, COUNT(1) N FROM public.wiki_clickstream_1 GROUP BY resource
)
SELECT resource, N FROM cs01_gb ORDER BY N DESC LIMIT 100 


/*
 *  doing a window first, then a group by, took about 3 minutes
 *  doing a window first, then a distinct took about 3-4 minutes
 *  doing a more detailed window first, then a filter about 4 minutes
 *  doing a filter before I do a rank over resource by count, 3 and a half minutes..
 *  should be basically linear w data size, but memory?  I am not so sure..
 */
WITH cs01_win1 AS (
	SELECT *, 
	SUM(count) OVER( PARTITION BY resource ) total_count,
	COUNT(1) OVER( PARTITION BY resource ) referrer_pages_total,
	SUM(CASE WHEN internal='external' THEN count END) OVER( PARTITION BY resource ) external_count,
	SUM(CASE WHEN internal='link' THEN count END) OVER( PARTITION BY resource ) link_count
	FROM public.wiki_clickstream_1 
), cs01_win2 AS (
	SELECT *,
	RANK() OVER( PARTITION BY resource ORDER BY count DESC) rnk
	FROM cs01_win1
	WHERE total_count > 1500000
)
SELECT 
  resource, total_count, referrer_pages_total, external_count, link_count, referrer AS top_referrer
FROM cs01_win2 WHERE rnk < 2
ORDER BY total_count DESC LIMIT 100



