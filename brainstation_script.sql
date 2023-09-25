-- Shahnaj Ullah SQL script for Brainstation DataScience bootcamp admission challenge

USE kickstarter;

-- Counting the number of records in the data
SELECT COUNT(*) FROM campaign;
-- The resulting query shows there is 15000 records

-- Check data for the possibility of having duplicate entries
SELECT COUNT(DISTINCT(name)) 
FROM campaign;
-- the query results shows there are 14990 unique project names therefore 10 potential duplicate projects

-- Here we will identify the duplicate project titles by counting the number of projects with the same name
SELECT name,
	COUNT(*)
FROM campaign
GROUP BY name
ORDER BY COUNT(*) DESC;
-- This query showed the project names 'New EP/Music Development', 'Under the Sun', 'Project cancelled (Canceled)', 'Sausage Fest Travel', 'Cancelled (Canceled)', 'Champions of Hara', 'The Gift' 
-- 'Behind the Mask' and 'Chipembele Film Project' have multiple records. 

-- Further analyzing whether these entries are indeed duplicate by verifying whether their field entries all have identical entries i.e. their dates, goals, outcomes, etc.
SELECT *
FROM campaign
WHERE name IN ('New EP/Music Development', 
				'Under the Sun', 
                'Project cancelled (Canceled)', 
                'Sausage Fest Travel', 
                'Cancelled (Canceled)', 
                'Champions of Hara', 
                'The Gift', 
                'Behind the Mask', 
                'Chipembele Film Project')
ORDER BY name ASC; 
-- The resulting query shows all of these projects actually have different entries therefore we will not count them as duplicate records.  
-- We will ignore data where the outcome are defined as 'undefined' or 'canceled' as their classification of being 'successful' or 'failed' is unclear for our analysis purpose

-- Analyze all the possible outcomes
SELECT DISTINCT(outcome)
FROM campaign;
-- The resulting output shows the possible outcomes are failed, successful, canceled, suspended, undefined and live
-- Our analysis focuses strictly on successful and failed outcomes as the others implication are unclear as mentioned earlier

-- Analyzing the number of possible currencies the projects are in
SELECT DISTINCT(currency_id)
FROM campaign;
-- There are 13 currencies

-- Analyzing the number of possible countries
SELECT DISTINCT(country_id)
FROM campaign;
-- There are 22 countries

-- Analyzing the number of possible categories
SELECT DISTINCT *
FROM category;
-- There 15 possible categories
-- Category  with id = 7 and named 'Games' is the category we will assume board games fall into as there are no specific category named 'board games'

-- Analyzing the number of possible subcategories
SELECT DISTINCT *
FROM sub_category;
-- There are 159 subcategories 

-- We can also analyze what sub categories exist falling under the category 'Games'
SELECT DISTINCT *
FROM sub_category
WHERE category_id = 7;
-- We can see Games related categories have sub categories of:
-- 'Games' - id = 13
-- 'Tabletop Games' - id = 14
-- 'Video Games' - id= 44
-- 'Mobile Games' - id = 66
-- 'Playing Cards' - id = 70
-- 'Puzzles' - id = 113
-- 'Live Games' - id = 122
-- 'Gaming Hardware' - id = 134

-- Board games are considered tabletop games so for our analysis when it is required to look more closely 
-- at our category of campaigns, we will focus on the campaigns with sub category 'Tabletop Games' i.e. subcatergory id = 14


-- Reviewing contents in the currency table
SELECT * FROM currency;
-- We are assuming the campaign table's pledged and goal dollar values are stated in the currency defined by the currency_id column. As such we need to make all the dollars be comparable by having 
-- them in the same currency. To do this we will add a CAD currency multiplier column in the currency table which will allow us to convert the pledged and goal dollars all to CAD currency values

-- Adding a CAD currency multiplier so that we can later exchange the pledged and goal amount to the same currency unit for better comparison. 
-- These rates are taken from www.xe.com on August 22, 2023 at around 10:50pm ET. In an ideal world we would want to connect this date to a 
-- server that gets live updates continously
ALTER TABLE currency
	ADD COLUMN CAD_rate_multiplier DECIMAL(8,4) AFTER name;
   
-- Adding CAD exchange rate multiplier to their respective countries
UPDATE currency
SET CAD_rate_multiplier = '1.7250'
WHERE id = 1;

UPDATE currency
SET CAD_rate_multiplier = '1.3540'
WHERE id = 2;

UPDATE currency
SET CAD_rate_multiplier = '1.0000'
WHERE id = 3;

UPDATE currency
SET CAD_rate_multiplier = '0.8725'
WHERE id = 4;

UPDATE currency
SET CAD_rate_multiplier = '0.1277'
WHERE id = 5;

UPDATE currency
SET CAD_rate_multiplier = '1.4697'
WHERE id = 6;

UPDATE currency
SET CAD_rate_multiplier = '0.0801'
WHERE id = 7;

UPDATE currency
SET CAD_rate_multiplier = '0.1240'
WHERE id = 8;

UPDATE currency
SET CAD_rate_multiplier = '0.8068'
WHERE id = 9;

UPDATE currency
SET CAD_rate_multiplier = '1.5381'
WHERE id = 10;

UPDATE currency
SET CAD_rate_multiplier = '0.1972'
WHERE id = 11;

UPDATE currency
SET CAD_rate_multiplier = '0.1728'
WHERE id = 12;	

UPDATE currency
SET CAD_rate_multiplier = '1.7247'
WHERE id = 13;

UPDATE currency
SET CAD_rate_multiplier = '0.0093'
WHERE id = 14;
-- ----------------------------------------------------------------------------
-- Answering the preliminary Data Analysis Questions

-- 1. Are the goals for dollars raised significantly different between campaigns that are successful and unsuccessful?
SELECT 
	outcome,
	MIN(campaign.goal * currency.CAD_rate_multiplier) AS min_goal,
	MAX(campaign.goal * currency.CAD_rate_multiplier) AS max_goal,
	AVG(campaign.goal * currency.CAD_rate_multiplier) AS avg_goal,
	STDDEV(campaign.goal * currency.CAD_rate_multiplier) AS stdv_goal
FROM campaign
JOIN currency ON campaign.currency_id = currency.id
WHERE outcome IN ('failed', 'successful')
GROUP BY outcome;
-- The resulting output shows the min, max, average and standard deviation of the goals set in CAD dollars for failed and successful campaigns
-- Failed goals:
-- --		min = $1.35
-- --		max = $135,400,000
-- --		avg = $133,976
-- --		stdv = $3,182,497
-- Successful goals:
-- --		min = $0.65
-- --		max = $2,708,000
-- --		avg = $13,274
-- --		stdv = $49,676
-- We can see the successful campaigns have MUCH lower goals

-- --------------------------------------------------------------------------------------
-- 2. What are the top/bottom 3 categories with THE MOST backers? What are the top/bottom 3 subcategories by backers?
-- This question is unclear as to whether it is asking for the top 6 categoaries/subcategories with the most number of backers in which case the lower three of the 
-- sorted top 6 categories/subcategories would be considered the bottom 3 categories/subcategories with THE MOST number of backers
-- OR whether it is asking for the top 3 categories/subcategories with most number of backers and the lowest 3 categories/subcategories with fewest number of backers.
-- We will assume the latter is being asked as it may present more interesting useful insight with regards to what categories/subcategories had fewer backers which in 
-- return might come in as more useful later in proposing the business solution. 
-- For this section analysis we will consider both failed and successful campaigns as it is not clear whether we should focus on just successful campaigns

-- First we'll analyze the top 3 categories/subcategories with THE MOST backers
SELECT campaign.name AS project_name,
	sub_category.name AS subcategory_name,
	category.name AS category_name,
    campaign.backers AS number_of_backers,
    campaign.outcome AS outcome
FROM campaign
INNER JOIN sub_category ON campaign.sub_category_id = sub_category.id
INNER JOIN category ON sub_category.category_id = category.id
WHERE LOWER(outcome) IN ('failed', 'successful')
ORDER BY campaign.backers DESC
LIMIT 3;
-- This query output shows the top 3 category and subcategory by most backers
-- 1st Top: 105,857 backers - category = technology - sub category = Web - Title = 'Bring Reading Rainbow Back for Every Child, Everywhere!'
-- 2nd Top: 46,520 backers - category = film & Video - sub category = Narrative film - Title = 'WISH I WAS HERE'
-- 3rd top: 40,642 backers - category = Games - sub category = Tabletop games - Title = 'Gloomhaven (Second Printing)'

-- Second we'll analyze the bottom 3 categories/subcategories with fewer backers. The lowest possible number of backers for the campaigns is 0
-- and because the combination of categories/subcategories having 0 backers vary greatly and there's simply many with 0 backers, we will define
-- a category/subcategory being at the lowest 3 by analyzing which category has the most number of occurence with 0 backers
SELECT category.name AS category_name,
	COUNT(category.name) AS category_count
FROM campaign
INNER JOIN sub_category ON campaign.sub_category_id = sub_category.id
INNER JOIN category ON sub_category.category_id = category.id
WHERE (LOWER(outcome) IN ('failed', 'successful')) 
	AND campaign.backers = 0
GROUP BY category.name
ORDER BY COUNT(category.name) DESC
LIMIT 3;
-- This query output shows the bottom 3 categories with fewest backers
-- 1st lowest category = Film & Video with an occurence of 311 times 0 backers
-- 2nd lowest category = Publishing with an occurence of 243 times 0 backers
-- 3rd lowest category = Music with an occurence of 202 times 0 backers

-- We can do the same analysis to identify the 3 bottom subcategories with fewest backers
SELECT sub_category.name AS subcategory_name,
	COUNT(sub_category.name) as subcategory_count
FROM campaign
INNER JOIN sub_category ON campaign.sub_category_id = sub_category.id
WHERE (LOWER(outcome) IN ('failed', 'successful')) 
	AND campaign.backers = 0
GROUP BY sub_category.name
ORDER BY COUNT(sub_category.name) DESC
LIMIT 5;
-- This query output shows the bottom 3 subcategories with fewest backers
-- 1st lowest subcategory = Documentary with an occurence of 78 times 0 backers
-- 2nd lowest subcategory = Publishing & Music have a tie with an occurence of 69 times 0 backers
-- 3rd lowest subcategory = Film & Video with an occurence of 66 times 0 backers
-- Limiting the query to 5 records shows Film & Video does not have a tie with the following subcategory

-- -----------------------------------------------------------------------------------
-- 3. What are the top/bottom 3 categories that have raised the most money? What are the top/bottom 3 subcategories that have raised the most money?
-- Like in the preliminary analysis question 2, the question is unclear in the same manner therefore we will
-- assume the question is asking for the top 3 categories and top 3 subcategories having raised the most money
-- as well as what is the lowest category and subcategory having raised the least amount of money
-- For this section analysis we will consider both failed and successful campaigns as it is not clear whether we should focus on just successful campaigns

-- We will firstly analyze the top 3 categories and subcategories with most amount of money pledged
SELECT campaign.name AS project_name,
	sub_category.name AS subcategory_name,
	category.name AS category_name,
	campaign.pledged * currency.CAD_rate_multiplier AS pledged_dollar_in_CAD
FROM campaign
INNER JOIN currency ON campaign.currency_id = currency.id
INNER JOIN sub_category ON campaign.sub_category_id = sub_category.id
INNER JOIN category ON sub_category.category_id = category.id
WHERE LOWER(outcome) IN ('failed', 'successful')
ORDER BY pledged_dollar_in_CAD DESC
LIMIT 3;
-- This query output shows the top 3 category and subcategory by that with the most pledged dollar in CAD $
-- 1st Top: Title = Bring Reading Rainbow Back for Every Child, Everywhere! - 	Pledged $7,323,674 - Category = technology - Sub category = Web
-- 2nd top: Title = Gloomhaven (Second printing) -	 Pledged $5,415,723 - category = Games - sub category = Tabletop games
-- 3rd Top: Title = WISH I WAS HERE - 	Pledged $4,204,811 - category = film & Video - sub category = Narrative film

-- Second we'll analyze the bottom 3 categories/subcategories with least amount of money pledged. The lowest possible amount of money pledged is 0
-- and because the combination of categories/subcategories having pledged $0 vary greatly and there's many that pledged $0, we will define
-- a category/subcategory being at the lowest 3 by analyzing which category has the most number of occurence with $0 pledged
SELECT category.name AS category_name,
	COUNT(category.name) AS category_count
FROM campaign 
INNER JOIN sub_category ON campaign.sub_category_id = sub_category.id
INNER JOIN category ON sub_category.category_id = category.id
INNER JOIN currency ON campaign.currency_id = currency.id
WHERE (LOWER(outcome) IN ('failed', 'successful')) 
	AND  (campaign.pledged * currency.CAD_rate_multiplier = 0)
GROUP BY category.name
ORDER BY COUNT(category.name) DESC
LIMIT 3;
-- This query output shows the bottom 3 categories with most $0 pledged
-- 1st lowest category = Film & Video with an occurence of 309 
-- 2nd lowest category = Publishing with an occurence of 243
-- 3rd lowest category = Music with an occurence of 192

-- We can do the same analysis to identify the 3 bottom subcategories with $0 pledged
SELECT sub_category.name AS subcategory_name,
	COUNT(sub_category.name) AS subcategory_count
FROM campaign 
INNER JOIN sub_category ON campaign.sub_category_id = sub_category.id
INNER JOIN currency ON campaign.currency_id = currency.id
WHERE (LOWER(outcome) IN ('failed', 'successful')) 
	AND  (campaign.pledged * currency.CAD_rate_multiplier = 0)
GROUP BY sub_category.name
ORDER BY COUNT(sub_category.name) DESC
LIMIT 3;
-- This query output shows the bottom 3 subcategories with the most $0 pledged
-- 1st lowest subcategory = Documentary with an occurence of 78 times 
-- 2nd lowest subcategory = Fiction with an occurence of 69 times 
-- 3rd lowest subcategory = Film & Video with an occurence of 64 times

-- ----------------------------------------------------------
-- 4. What was the amount the most successful board game company raised? How many backers did they have?
-- We know board games fall under the subcategory of 'Tabletop Games' which has a subcategory id of 14
SELECT campaign.name AS project_name,
	campaign.sub_category_id AS subcategory_id,
	campaign.backers AS number_of_backers,
	campaign.pledged * currency.CAD_rate_multiplier AS pledged_dollar_in_CAD
FROM campaign
INNER JOIN currency ON campaign.currency_id = currency.id
WHERE LOWER(outcome) = 'successful' 
	AND campaign.sub_category_id = '14'
ORDER BY pledged_dollar_in_CAD  DESC
LIMIT 1;
-- The Query above shows the most successful board game is 'Gloomhaven (Second Printing)' and they pledged a total of $5,415,723 CAD while having 40,642 backers

-- -------------------------------------------------------
-- 5. Rank the top three countries with the most successful campaigns in terms of dollars (total amount pledged), and in terms of the number of campaigns backed.
SELECT country.name AS country_name,
	SUM(campaign.backers) AS total_number_of_backers,
	SUM(campaign.pledged * currency.CAD_rate_multiplier) AS total_pledged_dollar_in_CAD
FROM campaign
INNER JOIN currency ON campaign.currency_id = currency.id
INNER JOIN country ON campaign.country_id = country.id
WHERE LOWER(outcome) = 'successful'
GROUP BY country_name
ORDER BY total_pledged_dollar_in_CAD  DESC
LIMIT 3;
-- This query outputs the top 3 countries that pledged the most total dollars in CAD having considered only projects with a successful outcome:
-- The top three countries in order of 1st to 3rd rank: 
-- 1st : US - pledged $136,716,079 CAD - Backers 1,295,509
-- 2nd : GB - pledged $14,688,059 CAD - Backers 90,729
-- 3rd : CA - pledged $1,804,147 CAD - Backers 28,466

-- Here we will rank the top countries with the most successful campaigns in terms of number of backers
SELECT country.name AS country_name,
	SUM(campaign.backers) AS total_number_of_backers,
	SUM(campaign.pledged * currency.CAD_rate_multiplier) AS total_pledged_dollar_in_CAD
FROM campaign
INNER JOIN currency ON campaign.currency_id = currency.id
INNER JOIN country ON campaign.country_id = country.id
WHERE LOWER(outcome) = 'successful'
GROUP BY country_name
ORDER BY total_number_of_backers  DESC
LIMIT 3;
-- The resulting output shows US and GB still at the top 1st and 2nd however in 3rd place we now have AU with 29,704 backers and a total pledge of $1,491,848
-- This is when we are ranking the top countries in terms of the most numbers of backers

-- --------------------------------------------------------------------------
-- 6. Do longer, or shorter campaigns tend to raise more money? Why?
SELECT DATEDIFF(campaign.deadline, campaign.launched) AS duration_of_campaign,
	AVG(campaign.pledged * currency.CAD_rate_multiplier) AS avg_pledged_dollar,
    STDDEV(campaign.pledged * currency.CAD_rate_multiplier) AS stdv_pledged_dollar
FROM campaign
INNER JOIN currency ON campaign.currency_id = currency.id
WHERE outcome IN ('failed', 'successful')
GROUP BY duration_of_campaign
ORDER BY duration_of_campaign ASC;
-- This is difficult to answer without a graph but for the most part it appears that longer campaigns do tend to have higher odds of raising more money however I am noticing 
-- a lot of similar durations for the various campaigns having pledged different ranges of money. When a campaign passes a duration of more than 73 days we do see more campaigns 
-- experience less pledge


-- ------------------------------------
-- for the visualization analysis it will help to have our goals and pledged dollar amount already converted to the same CAD currency while also 
-- replacing id values with their respective meaningful values. We can clean the data to remove any records who's outcome is not successful or failed 
-- and then export the result to excel
SELECT c.id AS id,
	c.name AS name,
    sub_category.name AS subcategory_name,
    country.name AS country,
    currency.name AS currency,
    c.launched AS launched_date,
    c.deadline AS deadline_date,
    DATEDIFF(c.deadline, c.launched) AS campaign_duration,
    (c.goal * currency.CAD_rate_multiplier) AS goal_in_CAD,
    (c.pledged * currency.CAD_rate_multiplier) AS amount_pledged_in_CAD,
    c.backers AS number_of_backers,
    c.outcome AS outcome
FROM campaign c
INNER JOIN sub_category ON c.sub_category_id = sub_category.id
INNER JOIN country ON c.country_id = country.id
INNER JOIN currency ON c.currency_id = currency.id
WHERE outcome IN ('failed', 'successful');

    