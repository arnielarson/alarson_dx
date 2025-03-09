/*
 * Data Modeling - NBA basketball players
 * 
 * Uses a custom ENUM type to model Vertices and Edges
 * 
 * Vertices:  Game, Player, Team
 * Edges: connects vertices..
 * 
 * Explores relationships... Team, player, game, edges denote relationships between these entities..
 * 
 * For some reason - DBeaver seems to be having a problem using new TYPEs.. So, I guess just use Text?  or 
 * There is also a CHECK constraint, e.g.
 * vertex_type TEXT CHECK (vertex_type IN ('player','team','game')
 */
DROP TYPE vertex_type CASCADE;
DROP TYPE edge_type CASCADE;
DROP TABLE vertices;
DROP TABLE edges;

CREATE TYPE vertex_type AS ENUM('player','team','game')

CREATE TYPE edge_type AS 
	ENUM('plays_against',
		 'shares_team',
		 'plays_in',
		 'plays_on'
		 );
/*
 * Vertex Types: 'player','game','team'
 */
CREATE TABLE vertices (
	identifier TEXT,
	vertex_type TEXT,     -- TYPES ['player','game','team']
	properties JSON, -- Postgres does not have MAP TYPE, but this IS meant TO just be a MAPPING..
	PRIMARY KEY (identifier, vertex_type) 
)

/*
 * Edge Types: ['plays_against','plays_with','plays_in','plays_on']
 */
CREATE TABLE edges ( 
-- Could have a surrogate key, like edge_id
	subject_identifier TEXT,
	subject_type TEXT,
	object_identifier TEXT,
	object_type TEXT,
	edge_type TEXT,
	properties JSON,
	PRIMARY KEY (subject_identifier, subject_type, object_identifier, object_type, edge_type)
)


/*
 * Look at the data a bit - add games as vertices, game_id + 'game' + info
 * Games - Added 9384 rows
 * Game_details - can aggregate on player_id to create player vertices
 * Players - Added 1496 rows
 * Teams - Added 30 rows.  (The data was duplicated for some reason??)
 */
INSERT INTO vertices
SELECT
  game_id AS identifier,
  'game' AS vertex_type,
  json_build_object(
    'pts_home',pts_home,
    'pts_away',pts_away,
    'winning_team',CASE WHEN home_team_wins = 1 THEN home_team_id ELSE visitor_team_id END
  ) properties
FROM games 


INSERT INTO vertices
WITH player_agg AS (   

SELECT 
  player_id identifier,
  MAX(player_name) player_name,
  COUNT(1) num_games,
  SUM(pts) total_points,
  ARRAY_AGG(DISTINCT team_id) AS teams
FROM game_details
GROUP BY player_id
)
SELECT 
	identifier, 
	'player' vertex_type,
	json_build_object( 
		'player_name',player_name,
		'num_games',num_games,
		'total_points',total_points,
		'teams',teams
	)
FROM player_agg	;

INSERT INTO vertices
SELECT 
	team_id AS identifier,
	'team' AS vertex_type,
	json_build_object(
		'abbreviation',abbreviation,
		'city',city,
		'arena',arena,
		'year_founded',yearfounded
	) AS properties
FROM (SELECT DISTINCT * FROM teams) deduped
-- ON CONFLICT
-- DO
--  UPDATE SET team_id = EXCLUDED.team_id, vertex_type = EXCLUDED.vertex_type, properties = EXCLUDED.properties 


/*
 * Now build out edeges... 
 * game_details has: game_id, team_id, player_id
 */
--CREATE TABLE edges ( 
--	subject_identifier TEXT,
--	subject_type TEXT,
--	object_identifier TEXT,
--	object_type TEXT,
--	edge_type TEXT,
--	properties JSON,
--	PRIMARY KEY (subject_identifier, subject_type, object_identifier, object_type, edge_type)
--)


INSERT INTO edges
WITH deduped AS (
  SELECT 
    *, ROW_NUMBER() OVER (PARTITION BY player_id, game_id) AS row_num 
  FROM game_details
)
SELECT
	player_id subject_identifier,
	'player' subject_type,
	game_id AS object_identiifer,
	'game' object_type,
	'played_in' edge_type,
	json_build_object('start_position',start_position, 'pts',pts, 'team_id',team_id, 'team_abbreviation',team_abbreviation) AS properties
FROM deduped WHERE row_num = 1
  

/*
 * How to query the graph data now?  Let say you want to find..  
 * Not actually interesting - because could just aggregate game details..
 */
SELECT v.properties->>'player_name' player,MAX(CAST(e.properties->>'pts' AS INT)) max_points
FROM vertices v JOIN edges e 
ON v.identifier = e.subject_identifier
AND e.subject_type = v.vertex_type
GROUP BY 1
HAVING MAX(CAST(e.properties->>'pts' AS INT)) IS NOT NULL
ORDER BY 2 DESC 


/*
 * Create an edge that is plays against..
 * subj_id, subj_type, edge_type, properties
 * So for each game, self join on game, to create all of the player_1 <-> player_2 edges
 * Don't really want on the game granularity?, want to aggregate accross player1 <-> player2 + relationship combo
 * 
 * Added 815532 player to player edges..
 */
WITH deduped AS (
  SELECT 
    *, ROW_NUMBER() OVER (PARTITION BY player_id, game_id) AS row_num 
  FROM game_details
), filtered AS (
  SELECT * FROM deduped WHERE row_num = 1
)
INSERT INTO edges
SELECT 
  f1.player_id subject_identifier,
  'player' subject_type, 
  f2.player_id object_identifier,
  'player' object_type,
  CASE WHEN f1.team_id = f2.team_id THEN 'shares_team' ELSE 'plays_against' END AS edge_type,
  json_build_object(
  	'num_games',COUNT(*),
  	'subject_points',SUM(f1.pts),
  	'object_points',SUM(f2.pts)
  )
FROM filtered f1 JOIN filtered f2
ON f1.game_id = f2.game_id AND f1.player_id <> f2.player_id
GROUP BY 1, 3, 5


/*
 * What kinds of interesting queries can be done now?  you have all player<->player relationships, you have player information at vertices..
 *  
 * 
 */
SELECT
	v.properties->>'player_name' player,
	e.properties->>'number of games' AS games
FROM vertices v JOIN edges e 
ON v.identifier = e.subject_identifier
AND v.vertex_type = e.subject_type
WHERE e.object_type = 'player'
