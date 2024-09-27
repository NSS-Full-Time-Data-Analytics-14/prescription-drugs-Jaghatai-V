--MVP PRESCRIPTION QUESTIONS

--1.For this question, you will be looking for which county (or counties) had the most months with
--an unemployment rate above the state average.
--1A: Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT *
FROM prescriber;
SELECT *
FROM prescription;
SELECT COUNT(drug_name)
FROM drug;
SELECT COUNT(DISTINCT drug_name)
FRom drug;

SELECT npi, total_claim_count            -- I want the prescriber(so, npi) & total number of claims (totaled over all drugs)
FROM prescriber                          -- Start w/ 'prescriber'
	INNER JOIN prescription				  --inner join 'prescription' as it has the total claims; inner because we want just a few columns joined together & displayed
		USING(npi)                        --join with 'npi' & we use USING() function as both tables have that field in common
ORDER BY total_claim_count DESC;          
--1A: NPI; 1912011792 TCC 4538

-- b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
SELECT nppes_provider_first_name, nppes_provider_last_org_name, specialty_description,
		total_claim_count
FROM prescriber
	INNER JOIN prescription             
		USING(npi)
ORDER BY total_claim_count DESC;
--1B: David Coffey, Family Practice, 4538


--#2 a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT specialty_description, SUM(total_claim_count)
FROM prescriber
INNER JOIN prescription
		USING(npi)
GROUP BY specialty_description
ORDER BY SUM(total_claim_count) DESC;
-- Family Practice 9752347
	
--b. Which specialty had the most total number of claims for opioids?
SELECT specialty_description, SUM(total_claim_count) AS claim_count
FROM prescriber
INNER JOIN prescription
	USING(npi)
 INNER JOIN drug
	USING (drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY claim_count DESC;
  --NURSE PRACTITIONER; 525 claims
  
--c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT specialty_description, SUM(total_claim_count) AS claim_count
FROM prescriber
FULL JOIN prescription
	USING(npi)
GROUP BY specialty_description
HAVING SUM(total_claim_count) IS NULL;
 -- YES, 15 results


--D. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* 
--For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
-- for each specialty find percentages of total claims that were for opioids

WITH opioid_total AS (SELECT specialty_description, SUM(total_claim_count) AS opioid_claim_count
FROM prescriber
INNER JOIN prescription
	USING(npi)
INNER JOIN drug
	USING (drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description)


SELECT opioid_total.specialty_description, opioid_claim_count/SUM(rx.total_claim_count)*100 AS opioid_claim_percent
FROM opioid_total
INNER JOIN prescriber AS pr
	ON opioid_total.specialty_description = pr.specialty_description
INNER JOIN prescription as rx
		USING(NPI)
GROUP By opioid_total.specialty_description, opioid_total.opioid_claim_count
ORDER BY opioid_claim_percent DESC;








--3. a. Which drug (generic_name) had the highest total drug cost?
SELECT DISTINCT *
FROM drug;
SELECT *
FROM prescription;
--(SELECT DISTINCT generic_name, total_drug_cost
--FROM drug
--INNER JOIN presciption
	--USING(drug_name);

SELECT DISTINCT generic_name, SUM(total_drug_cost)::MONEY
FROM prescription
INNER JOIN drug
using(drug_name)
GROUP BY generic_name
ORDER BY SUM(total_drug_cost)::MONEY DESC;
-- 3A ANSWER: INSULIN GLARGINE,HUM.REC.ANLOG / 104264066.35

-- 3B:Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
SELECT generic_name, ROUND(SUM(total_drug_cost/total_day_supply), 2)::MONEY AS cost_per_day
FROM prescription
INNER JOIN drug
	USING(drug_name)
GROUP BY generic_name
ORDER BY cost_per_day DESC;
--LEDIPASVIR/SOFOSBUVIR :: 88270.87/day


--#4A: For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which 
--have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this.
SELECT *
FROM drug;

SELECT drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		 WHEN opioid_drug_flag = 'N' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type
FROM drug;


--4B Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. 
--Hint: Format the total costs as MONEY for easier comparision.

SELECT drug_name, total_drug_cost:: MONEY, 
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN opioid_drug_flag = 'N' THEN 'antibiotic'
			ELSE 'neither' END AS drug_type
FROM drug
INNER JOIN prescription
	USING(drug_name)
ORDER BY total_drug_cost;




--#5: 5A. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT COUNT(*)
FROM cbsa
WHERE cbsaname ILIKE '%TN%';
--58

--5B. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT *
FROM cbsa;
SELECT *
FROM population;
SELECT *
FROM fips_county;

SELECT cbsa, county, population
FROM cbsa
INNER JOIN fips_county
	USING(fipscounty)
INNER JOIN population
	ON fips_county.fipscounty = population.fipscounty
ORDER BY population DESC;
-- cbsa= 32820, Shelby Co. TN pop=937847


--5C What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT county, population
	FROM population
	 JOIN fips_county
		USING (fipscounty)
EXCEPT
SELECT county, population
	FROM cbsa
	INNER JOIN population
		USING(fipscounty)
	INNER join fips_county
		USING(fipscounty)
	WHERE cbsa IS NULL;

SELECT county, population
FROM cbsa 
RIGHT JOIN population 
USING(fipscounty)
INNER JOIN fips_county 
USING(fipscounty)
WHERE cbsa IS NULL
ORDER BY population DESC;





--#6: 6A. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;


--6B: For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT drug_name, total_claim_count, opioid_drug_flag
FROM prescription
INNER JOIN drug
	USING(drug_name)
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC;

-- 6C: Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT *
FROM prescriber;

SELECT nppes_provider_last_org_name, nppes_provider_first_name, drug_name, total_claim_count, opioid_drug_flag
FROM prescription
INNER JOIN drug
	USING(drug_name)
INNER JOIN prescriber
	ON prescription.npi = prescriber.npi
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC


--#7:The goal of this exercise is to generate a full list of all pain management specialists in Nashville 
--and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--7A;  First, create a list of all npi/drug_name combinations for pain management specialists 
--(specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), 
--where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. 
--You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT npi, drug_name opioid_drug_flag
FROM prescriber
INNER JOIN prescription
	USING(npi)
INNER JOIN drug
	USING(drug_name)
WHERE specialty_description = 'Pain Management' 
				AND nppes_provider_city = 'NASHVILLE'
						AND opioid_drug_flag = 'Y';



--7B: Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. 
--You should report the npi, the drug name, and the number of claims (total_claim_count).
SELECT npi, drug.drug_name, total_claim_count
FROM prescriber
CROSS JOIN drug
FULL JOIN prescription
USING(npi, drug_name)
WHERE specialty_description = 'Pain Management' 
				AND nppes_provider_city = 'NASHVILLE'
						AND opioid_drug_flag = 'Y';
ORDER BY total_claim_count DESC


-- 7C; Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.


-- BONUS README QUESTIONS
--#1: How many npi numbers appear in the prescriber table but not in the prescription table?
SELECT DISTINCT npi
FROM prescriber
EXCEPT
SELECT DISTINCT npi
FROM prescription
--4458


--#2:
  --2A; a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.
SELECT *
FROM prescriber
INNER JOIN prescription
	on prescriber.npi = prescription.npi
INNER JOIN drug
	USING(drug_name)
WHERE specialty_description = 'Family Practice'
LIMIT 5;


SELECT DISTINCT generic_name, SUM(total_claim_count) AS drug_claim
from drug
INNER JOIN prescription
USING(drug_name)
INNER JOIN prescriber
 ON prescriber.npi = prescription.npi
 WHERE specialty_description = 'Family Practice'
GROUP by generic_name
ORDER BY drug_claim DESC
LIMIT 5;


 --2B: Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.
	
SELECT DISTINCT generic_name, SUM(total_claim_count) AS drug_claim
FROM drug
INNER JOIN prescription
USING(drug_name)
INNER JOIN prescriber
 ON prescriber.npi = prescription.npi
 WHERE specialty_description = 'Cardiology'
GROUP by generic_name
ORDER BY drug_claim DESC
LIMIT 5;



  --2C: Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? 
  --Combine what you did for parts a and b into a single query to answer this question.

SELECT DISTINCT generic_name, SUM(total_claim_count) AS drug_claim
FROM drug
INNER JOIN prescription
USING(drug_name)
INNER JOIN prescriber
 ON prescriber.npi = prescription.npi
 WHERE specialty_description = 'Cardiology'
 					OR specialty_description = 'Family Practice'
GROUP by generic_name
ORDER BY drug_claim DESC
LIMIT 5;


--#3: Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
--  3A; First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. 
--Report the npi, the total number of claims, and include a column showing the city.


(SELECT prescriber.npi, nppes_provider_last_org_name, nppes_provider_city, SUM(total_claim_count) AS drug_claim
FROM prescriber
INNER JOIN prescription
	USING(npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY prescriber.npi, nppes_provider_last_org_name, nppes_provider_city
ORDER BY drug_claim DESC
LIMIT 5);


--3B; Now, report the same for Memphis.
SELECT prescriber.npi, nppes_provider_last_org_name, nppes_provider_city, SUM(total_claim_count) AS drug_claim
FROM prescriber
INNER JOIN prescription
	USING(npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP BY prescriber.npi, nppes_provider_last_org_name, nppes_provider_city
ORDER BY drug_claim DESC
LIMIT 5;

--3C; Combine your results from a and b, along with the results for Knoxville and Chattanooga.

(SELECT prescriber.npi, nppes_provider_last_org_name, nppes_provider_city, SUM(total_claim_count) AS drug_claim
FROM prescriber
INNER JOIN prescription
	USING(npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY prescriber.npi, nppes_provider_last_org_name, nppes_provider_city
ORDER BY drug_claim DESC
LIMIT 5)
			UNION
(SELECT prescriber.npi, nppes_provider_last_org_name, nppes_provider_city, SUM(total_claim_count) AS drug_claim
FROM prescriber
INNER JOIN prescription
	USING(npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY prescriber.npi, nppes_provider_last_org_name, nppes_provider_city
ORDER BY drug_claim DESC
LIMIT 5)
 			UNION
(SELECT prescriber.npi, nppes_provider_last_org_name, nppes_provider_city, SUM(total_claim_count) AS drug_claim
FROM prescriber
INNER JOIN prescription
	USING(npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY prescriber.npi, nppes_provider_last_org_name, nppes_provider_city
ORDER BY drug_claim DESC
LIMIT 5)








--#4: Find all counties which had an above-average number of overdose deaths. 
--Report the county name and number of overdose deaths.

SELECT *
FROM overdose_deaths;
SELECT *
FROM fips_county;
(SELECT avg(overdose_deaths)
FROM overdose_deaths);

SELECT county, SUM(overdose_deaths) as death_toll
FROM overdose_deaths
INNER JOIN fips_county
	ON overdose_deaths.fipscounty = fips_county.fipscounty::NUMERIC
WHERE overdose_deaths >= (SELECT avg(overdose_deaths)
							FROM overdose_deaths)
GROUP BY county
ORDER BY death_toll DESC;


--#5:
 --5A; Write a query that finds the total population of Tennessee
SELECT state, SUM(population) AS total_population
FROM population
INNER JOIN fips_county
	USING (fipscounty)
GROUP BY state;
-- 5a total TN pop 6597381

--5B; Build off of the query that you wrote in part a to write a query that returns for each county that county's name, 
--its population, and the percentage of the total population of Tennessee that is contained in that county.

WITH total_tn_pop AS (SELECT state, SUM(population) AS total_population
				FROM population
				INNER JOIN fips_county
						USING (fipscounty)
				GROUP BY state)
SELECT county, population AS county_pop, ROUND((population/total_population*100),6) AS pop_percent
FROM fips_county
INNER JOIN population
	USING(fipscounty)
INNER JOIN total_tn_pop
	USING(state)
ORDER BY population DESC;

