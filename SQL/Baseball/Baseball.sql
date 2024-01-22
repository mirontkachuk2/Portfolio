USE BaseballDB;
-- Let's explore the baseball database and find out if younger players play more than old players

-- Check how the table looks like
SELECT * FROM players
LIMIT 10;

-- How many distinct players we have?
-- Do we have several rows for some players?
SELECT count(distinct Name, Age)
FROM players
UNION ALL
SELECT count(*)
FROM players;


-- Let's check if there are players with the same name but with different age 
SELECT Name
FROM players
GROUP BY 1
HAVING MAX(age) <> MIN(age);


-- Those could be the same players in different moments of time of just people with the same name
-- Let's exclude them for simplicity
-- As we could have several rows for some players let's group them and take the sum of games for each
DROP TABLE IF EXISTS players_games;
CREATE TABLE players_games as
SELECT  Name, 
	Age,
        SUM(G) AS total_games
FROM players
WHERE Name NOT IN ('David Carpenter', 'Matt Duffy', 'Jose Ramirez', 'Chris Young')
GROUP BY 1,2;

-- We got 1330 unique combinations of player+age
SELECT COUNT(*)
FROM players_games
LIMIT 10;

-- Calculating percentiles to see how distribution of games played look like
DROP TABLE IF EXISTS players_games_percentile;
CREATE TEMPORARY TABLE players_games_percentile as
SELECT  Name,
	Age,
        total_games,
        ROUND(CAST(PERCENT_RANK() OVER (ORDER BY total_games) AS FLOAT), 2) as percentile
FROM players_games;

-- Positively skewed distribution, long right tale
SELECT 	percentile,
	total_games
FROM players_games_percentile
WHERE percentile in (0.25, 0.50, 0.75, 1)
GROUP BY 1,2;

-- Let's look at average age for each quantile
SELECT 	CASE WHEN (percentile <= 0.25) THEN '4th Quantile'
	     WHEN (percentile <= 0.5) THEN '3rd Quantile'
             WHEN (percentile <= 0.75) THEN '2nd Quantile'
             WHEN (percentile <= 1) THEN '1st Quantile'
	     END AS quantile,
	AVG(AGE) as avg_age
FROM players_games_percentile
GROUP BY 1;
-- From the result avg age is lower for smaller amount of games played, however it does not look statistically significant
-- Probably, coaches prefer to rely on more expirienced players and make them play more matches

-- Let's check correlation coefficient to understand the significance of relationship
-- H0: age is positively correlated with the number of games

SELECT SUM( ( age - avg_games ) * ( total_games - avg_games) ) / ((COUNT(*) - 1) * std_age * std_games) 
FROM players_games
INNER JOIN LATERAL
(SELECT 	AVG(age) as avg_age, 
		AVG(total_games) as avg_games,
		STDDEV_SAMP(age) as std_age,
		STDDEV_SAMP(total_games) as std_games
FROM players_games) AS metrics_table
ON TRUE;

-- We can see weak positive correlation implying that older players tend to play slightly more

