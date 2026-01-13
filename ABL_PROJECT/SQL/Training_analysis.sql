USE abl_training ;
DESCRIBE training_management;

-- REMOVE UNNECESSARY COLUMNS

ALTER TABLE training_management
DROP MyUnknownColumn;

-- STANDARDIZE COLUMN NAMES

ALTER TABLE training_management
CHANGE `NAME` name VARCHAR(150),
CHANGE `GENDER` gender VARCHAR(150),
CHANGE `EMAIL_ID` email_id VARCHAR(150),
CHANGE `LDC_UPLINE` assigned_lead VARCHAR(150);

-- UPDATE THE VALUES IN THE COLUMN

SET SQL_SAFE_UPDATES =0;
UPDATE  training_management
SET gender = UPPER(TRIM(gender));

UPDATE training_management
SET name = upper(TRIM(name));


UPDATE  training_management
SET gender = 'Male'
WHERE gender IN ('MaleÂ ','MALE');


UPDATE  training_management
SET gender = 'Female'
WHERE gender IN ('FEMALE');

UPDATE training_management
SET gender = UPPER(TRIM(gender));

UPDATE training_management
SET name = REPLACE(name, 'Â','');

UPDATE training_management
SET assigned_lead = REPLACE(assigned_lead, 'Â','');


UPDATE training_management
SET Mail_Replied = 'No'
WHERE Mail_Replied IN ('');

-- 1. Count the total number of participants in the dataset.
SELECT COUNT(name) FROM  training_management;

-- 2. Display gender-wise attendance count.
SELECT gender ,COUNT(name) FROM  training_management
group by gender;

-- 3. Show location-wise participant count.
SELECT location,COUNT(name) FROM  training_management
group by location;

-- 4. Calculate overall mail reply percentage.
SELECT ROUND(((SELECT COUNT(Mail_Replied) FROM  training_management
WHERE Mail_Replied = "Yes")*100)/COUNT(*),2) AS mail_replied_perc
FROM training_management;


-- 5. Show gender-wise replied vs not replied count.
SELECT gender,
SUM(CASE WHEN Mail_Replied ="Yes" THEN 1 else 0 END) AS mail_Replied,
SUM(CASE WHEN Mail_Replied ="No" THEN 1 else 0 END) AS Mail_Not_Replied
from  training_management group by gender ;


-- 6. Display Assigned_Lead-wise total participants.
SELECT assigned_lead, COUNT(*)
from training_management
group by assigned_lead;

-- 7. Calculate Assigned_Lead-wise reply rate percentage.
SELECT assigned_lead ,
COUNT(*) as total,
SUM(CASE WHEN Mail_Replied = "Yes" THEN 1 else 0 END) AS Replied,
ROUND(SUM(CASE WHEN Mail_Replied = "Yes" THEN 1 else 0 END) * 100.0/ Count(*),2)  AS rate_percent 
FROM training_management
group by assigned_lead;

-- 8. Find Assigned_Leads with reply rate less than 50%.
SELECT assigned_lead,
COUNT(*) AS Total,
ROUND(SUM(CASE WHEN Mail_Replied = "Yes" THEN 1 ELSE 0 END) * 100.0/ COUNT(*),2) AS reply_rate
FROM training_management
GROUP BY assigned_lead
HAVING reply_rate < 50;

-- 9. Rank Assigned_Leads based on reply rate.
SELECT assigned_lead, 
SUM(CASE WHEN Mail_Replied ="Yes" THEN 1 ELSE 0 END)*100.0/COUNT(*) as reply_rate,
DENSE_RANK()over( order by SUM(CASE WHEN Mail_Replied ="Yes" THEN 1 ELSE 0 END)*100/COUNT(*) DESC) as rn
FROM training_management
group by assigned_lead;

-- 10. Identify the top 3 Assigned_Leads by engagement.

WITH X AS 
(SELECT assigned_lead, 
SUM(CASE WHEN Mail_Replied ="Yes" THEN 1 ELSE 0 END)*100.0/COUNT(*) as reply_rate 
FROM training_management
GROUP BY assigned_lead
) 
SELECT * FROM X 
order by reply_rate DESC
LIMIT 3;


-- 11. Show location-wise reply rate.
SELECT location,COUNT(*) AS TOTAL, 
ROUND(SUM(CASE WHEN Mail_Replied = "Yes" THEN 1 ELSE 0 END) * 100.0/ COUNT(*),2) AS Reply_rate FROM training_management
GROUP BY location;

-- 12. List participants who have not replied and require follow-up.
SELECT name, Mail_Replied,assigned_lead FROM training_management
WHERE Mail_Replied ="No";

-- 13. Identify duplicate email IDs in the dataset.
SELECT email_id, COUNT(*) AS Duplicate_email FROM training_management
GROUP BY email_id
HAVING COUNT(*) > 1;

-- 14. Assign participants into 8 balanced teams based on gender.
SELECT *, ROW_NUMBER() OVER (PARTITION BY Gender ORDER BY Email_Id) AS rn
FROM training_management;

WITH gender_ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY Gender ORDER BY Email_Id) AS rn
    FROM training_management
)
SELECT
    Name,
    Gender,
    Email_Id,
    Location,
    assigned_lead,rn,
    ((rn - 1) % 8) + 1 AS Team_No
FROM gender_ranked;

-- 15. Show team-wise male and female count.

WITH x AS 
( SELECT *,
ROW_NUMBER()OVER(PARTITION BY gender) AS rn
FROM training_management
)
SELECT 
gender,
COUNT(*),
((rn-1)% 8)+1 AS TEAM_NO 
FROM x
GROUP BY gender,TEAM_NO;

-- 16. Calculate percentage contribution of each location to total participants.
SELECT location, ROUND((COUNT(*)*100.0)/(SELECT COUNT(*) FROM training_management),2) AS contribution_perc FROM training_management
GROUP BY location;

-- 17. Find the city with the highest response rate.

SELECT location,
ROUND(SUM(CASE WHEN Mail_Replied = "yes" THEN 1 ELSE 0 END) *100.0/COUNT(*),2)  as response_rate
FROM training_management
group by location
order by response_rate DESC
LIMIT 1;

-- 18. Create a SQL view showing Assigned_Lead-wise engagement summary.

CREATE OR REPLACE VIEW assigned_lead_wise_engagement AS 
SELECT assigned_lead,COUNT(*) as Total,
SUM(CASE WHEN Mail_Replied = "Yes" THEN 1 ELSE 0 END) AS Replies,
SUM(CASE WHEN Mail_Replied = "Yes" THEN 1 ELSE 0 END * 100.0 / COUNT(*)) AS Reply_rate
FROM training_management
GROUP BY assigned_lead;
SELECT * FROM assigned_lead_wise_engagement
;

-- 19. Display participants grouped by location and gender.
SELECT location,gender, COUNT(*) FROM training_management
GROUP BY location ,gender
order by location ,gender;

-- 20. Identify Assigned_Leads managing participants from more than 2 locations.
SELECT assigned_lead,COUNT(DISTINCT location) FROM training_management
GROUP BY assigned_lead
HAVING COUNT(DISTINCT location) > 2;
