/*
 * Data with Zach - has done a couple of interesting sessions on this problem
 * 
 * How many players have scored 20+ points in 5 consecutive seasons?
 * Much harder than have scored 20+ points in 5 seasons..
 *
 * How to identify streaks...
 * Use LAG to get previous seasons pts per game
 * Identify streak condition and assigne a 0, (first entry will be 1)
 * Now the identifier can be used in a group by

SELECT player_name, COUNT(CASE WHEN pts > 20 THEN 1 END) 
FROM public.player_seasons 
GROUP BY PLAYER_NAME
HAVING COUNT(CASE WHEN pts > 20 THEN 1 END) >= 5
*/

/*
 * The top few season by pts
 */
SELECT * FROM public.player_seasons
WHERE pts >= 30
ORDER BY pts DESC
LIMIT 100

/*
 * Data goes from 1996 to 2022, has about 500 players data per season
 */
SELECT season, COUNT(*) FROM public.player_seasons
GROUP BY season ORDER BY season DESC

/*
 * Query to identify streaks.. in this case 20 point seasons
 * Who has the longest streaks?
 */ 
WITH lagged AS (
	SELECT 
	player_name, pts, season, 
	LAG(pts, 1) OVER(PARTITION BY player_name ORDER BY season ) pts_last_season
	FROM public.player_seasons
), streaked AS (
	SELECT 	player_name, pts, season, CASE WHEN pts > 20 AND pts_last_season > 20 THEN 0 ELSE 1 END AS broke_streak
	FROM lagged
	--WHERE player_name = 'LeBron James'
	ORDER BY player_name, season
), identified AS (  
  	SELECT player_name, pts, season, 
  	SUM(broke_streak) OVER (PARTITION BY player_name ORDER BY season) AS streak_group
  	FROM streaked
 )
SELECT player_name, MAX(pts), MIN(pts), MIN(season), MAX(season),
MAX(season) - MIN(season) + 1 AS num_season 
FROM identified
GROUP BY player_name, streak_group
HAVING COUNT(*) > 3
ORDER BY (MAX(season) - MIN(season)) DESC, player_name