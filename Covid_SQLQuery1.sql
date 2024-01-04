SELECT *
FROM covid_file..[covid-test]
ORDER BY 2,3

SELECT *
FROM covid_file..[covid-info]
ORDER BY 1,2


-- Select location, date, total_cases, new_cases, total_deaths, population ffrom the table
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_file..[covid-info]
ORDER BY 1,2

-- Total cases vs Total deaths
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS float)/ CAST(total_cases AS float)) * 100 as Death_Percentage
FROM covid_file..[covid-info]
WHERE location like '%states%'
ORDER BY 1,2

-- Toatl cases vs Population (percentage of population got covid)
SELECT location, date, total_cases, total_deaths, (CAST(total_cases AS float)/ CAST(population AS float)) * 100 as cases_Percentage
FROM covid_file..[covid-info]
WHERE location like '%states%'
ORDER BY 1,2

-- looking at countries with highest infection rate compared to population
SELECT location, population, MAX(CAST(total_cases AS float)) AS Highest_cases, MAX(CAST(total_cases AS float)/ CAST(population AS float)) * 100 as cases_Percentage
FROM covid_file..[covid-info]
GROUP BY location, population
ORDER BY cases_Percentage desc

-- showing Countries with Higest Death
SELECT location, MAX(CAST(total_deaths as int)) AS Highest_Death_cases
FROM covid_file..[covid-info]
WHERE continent is not null  -- becasue come continet is null, are getting wrong output
GROUP BY location
ORDER BY Highest_Death_cases desc

-- checking the death cases by continent
SELECT continent, MAX(CAST(total_deaths as int)) AS Highest_Death_cases
FROM covid_file..[covid-info]
WHERE continent is not null  -- becasue come continet is null, are getting wrong output
GROUP BY continent
ORDER BY Highest_Death_cases desc

-- Global Cases
-- checking the death cases by continent
SELECT SUM(CAST(new_cases as int)) as total_new_cases,
		SUM(CAST(new_deaths as int)) as total_new_deaths,
		-- use NULLIF, because some denominator is zero, to avoid error
		SUM(CAST(new_deaths as int)) / NULLIF(SUM(CAST(new_cases as int)),0)*100 AS Highest_Death_cases
FROM covid_file..[covid-info]
WHERE continent is not null  -- becasue come continet is null, are getting wrong output
--GROUP BY date
ORDER BY Highest_Death_cases desc


--EXploring the two tables
--JOINING THE COVID INFO AND COVID TEST TABLE TOGETHER
SELECT *
FROM covid_file..[covid-info] as inf
	JOIN covid_file..[covid-data] AS dat
	ON inf.location = dat.location
	AND inf.date = dat.date

-- Exploring the total population vs people who took vaccine
SELECT inf.population, inf.continent, inf.date, inf.location, new_vaccinations,
		--used bigint to avoid artimetic overflow, becasue of null values
		SUM(CAST(dat.new_vaccinations as bigint)) OVER (partition by inf.location ORDER BY inf.location, inf.date) as people_vaccinatd
FROM covid_file..[covid-info] as inf
	JOIN covid_file..[covid-data] AS dat
	ON inf.location = dat.location
	AND inf.date = dat.date
WHERE inf.continent is not null
order by 2,3


--USING CTE
-- Because we can't call alias for usage

with popvsvac (population, continent, date, location, new_vaccinations,people_vaccinatd)
as 
(
-- Exploring the total population vs people who took vaccine
SELECT inf.population, inf.continent, inf.date, inf.location, new_vaccinations,
		--used bigint to avoid artimetic overflow, becasue of null values
		SUM(CAST(dat.new_vaccinations as bigint)) OVER (partition by inf.location ORDER BY inf.location, inf.date) as people_vaccinatd
FROM covid_file..[covid-info] as inf
	JOIN covid_file..[covid-data] AS dat
	ON inf.location = dat.location
	AND inf.date = dat.date
WHERE inf.continent is not null

)
SELECT * , (people_vaccinatd/population)*100 as percentage_vac
FROM popvsvac


--CREATING TEMP
-- Let Create and Insert into table
-- DROP Table if exist #vaccinate
CREATE TABLE #vaccinate (
population numeric, 
continent nvarchar(255), 
date datetime, 
location nvarchar(255), 
new_vaccinations numeric,
people_vaccinatd numeric
)

INSERT INTO #vaccinate
SELECT inf.population, inf.continent, inf.date, inf.location, new_vaccinations,
		--used bigint to avoid artimetic overflow, becasue of null values
		SUM(CAST(dat.new_vaccinations as bigint)) OVER (partition by inf.location ORDER BY inf.location, inf.date) as people_vaccinatd
FROM covid_file..[covid-info] as inf
	JOIN covid_file..[covid-data] AS dat
	ON inf.location = dat.location
	AND inf.date = dat.date
WHERE inf.continent is not null

SELECT *
FROM #vaccinate



--Creating Views
CREATE VIEW vaccine as
SELECT inf.population, inf.continent, inf.date, inf.location, new_vaccinations,
		--used bigint to avoid artimetic overflow, becasue of null values
		SUM(CAST(dat.new_vaccinations as bigint)) OVER (partition by inf.location ORDER BY inf.location, inf.date) as people_vaccinatd
FROM covid_file..[covid-info] as inf
	JOIN covid_file..[covid-data] AS dat
	ON inf.location = dat.location
	AND inf.date = dat.date
WHERE inf.continent is not null

SELECT *
FROM vaccine