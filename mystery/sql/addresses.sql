/*
	School Data
	Data Set 1: nces
	Data Set 2: headstart

  Goal: Determine overlap by address of the two data sets, identify and perform some normalization of the address fields
  
*/

DROP TABLE IF EXISTS public.nces;

CREATE TABLE IF NOT EXISTS public.nces (
NCES_School_ID BIGINT,
State_School TEXT,
NCES_District_ID INTEGER,
State_District_ID TEXT,
Low_Grade VARCHAR(2),
High_Grade VARCHAR(2),
School_Name TEXT,
District TEXT,
County_Name TEXT,
Street_Address TEXT,
City TEXT,
State TEXT,
ZIP INTEGER,
ZIP4 INTEGER,
Phone TEXT,
Locale_Code TEXT,
Locale TEXT,
Charter TEXT,
Magnet TEXT,
Title_I_School TEXT,
Title__School_Wide TEXT,
Students TEXT,
Teachers TEXT,
Student_Teacher_Ratio TEXT,
Free_Lunch TEXT,
Reduced_Lunch TEXT
)

SELECT COUNT(1) FROM public.nces;


COPY public.nces 
FROM '/Users/arnie/Data/nce.csv'
DELIMITER ','
CSV;

SELECT * FROM public.nces LIMIT 200


SELECT street_address, ZIP::INTEGER FROM public.nces LIMIT 200

DROP TABLE public.headstart; 

CREATE TABLE IF NOT EXISTS public.headstart (
        name    TEXT,
        typeString      TEXT,
        addressLineOne  TEXT,
        addressLineTwo  TEXT,
        city    TEXT,
        state   TEXT,
        zipFive TEXT,
        zipFour TEXT,
        county  TEXT,
        isPoBoxLocation TEXT,
        phone   TEXT,
        drivingDirectionsLink   TEXT,
        grantNumber     TEXT,
        delegateNumber  TEXT,
        programName     TEXT,
        programAddressLineOne   TEXT,
        programAddressLineTwo   TEXT,
        programCity     TEXT,
        programState    TEXT,
        programZipFive  TEXT,
        programZipFour  TEXT,
        programCounty   TEXT,
        programPhone    TEXT,
        programRegistrationPhone        TEXT,
        latitude        REAL,
        longitude       REAL
)


/*
 * Now interested in looking at overlap..  
 * 
*/
SELECT COUNT(1) FROM public.headstart

SELECT * FROM public.headstart LIMIT 300

/*
 * Check the ZIP fields in both datasets, check
 */
SELECT LENGTH(zipfive) lz, COUNT(1) N FROM public.headstart GROUP BY LENGTH(zipfive)

SELECT LENGTH(CAST(ZIP AS TEXT)) lz, COUNT(1) N FROM public.nces GROUP BY LENGTH(CAST(ZIP AS TEXT))

/*
 * Explore normalizations then look at the overlap.
 * Naive overlap of non-normalized data was 40?
 * After normalization and deduplication get 63
 * Matching on street address + zip5
 */
WITH ncse_addr AS (
  SELECT 
    street_address addr1, ZIP::TEXT zip5,
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
    REPLACE(REPLACE(TRIM(UPPER(street_address)), '-', ' '),'"',''),'.',''),' DRIVE', ' DR')
    ,' ROAD',' RD'),' AVENUE',' AVE'),' STREET', ' ST'), ' BOULEVARD', ' BLVD') AS norm_address 
  FROM public.nces
), hs_addr AS (
  SELECT 
    addressLineOne addr1, zipFive zip5,
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
    REPLACE(REPLACE(TRIM(UPPER(addressLineOne)), '-', ' '),'"',''),'.',''),' DRIVE', ' DR')
    ,' ROAD',' RD'),' AVENUE',' AVE'),' STREET', ' ST'), ' BOULEVARD', ' BLVD') AS norm_address 
  FROM public.headstart
)
SELECT COUNT(1) 
FROM 
(SELECT DISTINCT CONCAT(norm_address, zip5) addr_tag FROM ncse_addr) nc 
INNER JOIN 
(SELECT DISTINCT CONCAT(norm_address, zip5) addr_tag FROM hs_addr) hs 
ON hs.addr_tag=nc.addr_tag 

