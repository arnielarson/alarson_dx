/*
	Examining a mysterious data set - basic exploratory analysis
*/
DROP TABLE IF EXISTS public.mystery;

CREATE TABLE IF NOT EXISTS public.mystery (
	ID INTEGER,
	D1 NUMERIC,
	T1 TEXT,
	D2 NUMERIC,
	ID2 INTEGER,
	T2 TEXT,
	PRIMARY KEY (id)
);


COPY public.mystery 
FROM '/Users/arnie/Data/prob1.txt'
DELIMITER ','
CSV;


SELECT 
COUNT(1), COUNT(DISTINCT ID), MIN(ID), MAX(ID) 
FROM public.mystery ;

SELECT 
COUNT(DISTINCT T1), COUNT(DISTINCT T2), MAX(D1), MIN(D1), MAX(D2), MIN(D2), MAX(ID), MAX(ID2)
FROM public.mystery ;

SELECT AVG(D1), AVG(D2), AVG(ID2) FROM public.mystery ;

SELECT T1, COUNT(1) N
FROM public.mystery
GROUP BY T1 ORDER BY COUNT(1) DESC
LIMIT 100;

SELECT T2, COUNT(1) N
FROM public.mystery
GROUP BY T2 ORDER BY COUNT(1) DESC
LIMIT 100;

