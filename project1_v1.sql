USE PROJECT1
/*select top 10 *
from PROJECT1.dbo.CovidDeaths$
order by 3,4

select top 10 *
from PROJECT1.dbo.CovidVaccinaions$
order by 3,4
*/

-- Select data that I am going to use
SELECT
	Location, date, total_cases, new_cases, total_deaths, population
FROM
	PROJECT1.dbo.CovidDeaths$
WHERE continent is not null
ORDER BY 1,2

-- Looking at total cases vs total deaths in Unites States

SELECT
	Location, date, total_cases, total_deaths, 
	cast(total_deaths as float)/cast(total_cases as float)*100 as DeathPercentage
FROM
	PROJECT1.dbo.CovidDeaths$
WHERE continent is not null
AND location = 'United States'
ORDER BY 1,2

--Looking at total cases vs population in Unites States

SELECT
	Location, date, total_cases, population,
	cast(total_cases as float)/population *100 as CasePercentage
FROM
	PROJECT1.dbo.CovidDeaths$
WHERE continent is not null
AND location = 'United States'
ORDER BY 1,2

--Looking at countries with highest infection rate compared to population

SELECT
	Location, max(cast(total_cases as float)) as HighestCaseByCountry, population,
	max(cast(total_cases as float))/population *100 as PercentPopulationInfected
FROM
	PROJECT1.dbo.CovidDeaths$
WHERE continent is not null
GROUP BY Location, population
ORDER BY PercentPopulationInfected desc

--Looking at countries with highest death count
--Unites States has a highest death count 

SELECT
	Location, max(cast(total_deaths as float)) as HighestDeathCount
FROM
	PROJECT1.dbo.CovidDeaths$
WHERE continent is not null
GROUP BY Location
ORDER BY HighestDeathCount desc

--Looking at continent with highest death count

SELECT
	continent, max(cast(total_deaths as float)) as HighestContinentDeathCount
FROM
	PROJECT1.dbo.CovidDeaths$
WHERE continent is not null
GROUP BY continent
ORDER BY HighestContinentDeathCount desc

--Looking at Global percentage of total death vs total new cases 

SELECT
	sum(cast(new_cases as float)) as GlobalCases,  sum(cast(new_deaths as float)) as GlobalDeaths,
	sum(cast(new_deaths as float))/sum(cast(new_cases as float))*100 as GlobalDeathPercentage
FROM
	PROJECT1.dbo.CovidDeaths$
WHERE continent is not null

--Looking at total population vs total vaccination
SELECT
	De.continent, De.location, De.date, De.population, Va.new_vaccinations,
	SUM (cast(Va.new_vaccinations as float)) OVER (PARTITION BY De.location ORDER BY De.location, De.date)
	as PeopleVaccination
FROM PROJECT1.dbo.CovidDeaths$ De
JOIN PROJECT1.dbo.CovidVaccinaions$ Va
	ON De.location = Va.location
	AND De.date = Va.date  
WHERE De.continent is not null
ORDER BY 2,3

--Using CTE
With PopVSVac (Continent, Location, Date, Population, New_vacinations, PeopleVaccination)
as (
SELECT
	De.continent, De.location, De.date, De.population, Va.new_vaccinations,
	SUM (cast(Va.new_vaccinations as float)) OVER (PARTITION BY De.location ORDER BY De.location, De.date)
	as PeopleVaccination
FROM PROJECT1.dbo.CovidDeaths$ De
JOIN PROJECT1.dbo.CovidVaccinaions$ Va
	ON De.location = Va.location
	AND De.date = Va.date  
WHERE De.continent is not null
)
SELECT * , PeopleVaccination/population*100 as PercentageVacOnPop
FROM PopVSVac

--Create temp table
DROP TABLE IF exists #PercentagePopulationVaccinated
CREATE TABLE #PercentagePopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
PeopleVaccination numeric,
)
INSERT INTO #PercentagePopulationVaccinated
SELECT
	De.continent, De.location, De.date, De.population, Va.new_vaccinations,
	SUM (cast(Va.new_vaccinations as float)) OVER (PARTITION BY De.location 
	ORDER BY De.location, De.date)
	as PeopleVaccination
FROM PROJECT1.dbo.CovidDeaths$ De
JOIN PROJECT1.dbo.CovidVaccinaions$ Va
	ON De.location = Va.location
	AND De.date = Va.date  
WHERE De.continent is not null

SELECT *, PeopleVaccination/Population*100 as PercentageVacOnPop
FROM #PercentagePopulationVaccinated

--Create view to store data for virtualization later on

--Create view for Percentage of infeted population
CREATE VIEW PercentageInfectedPopulation AS
SELECT
	Location, max(cast(total_cases as float)) as HighestCaseByCountry, population,
	max(cast(total_cases as float))/population *100 as PercentPopulationInfected
FROM
	PROJECT1.dbo.CovidDeaths$
WHERE continent is not null
GROUP BY Location, population



--Create view for Percentage of vaccinated population
CREATE VIEW PercentagePopulationVaccinated AS
SELECT
	De.continent, De.location, De.date, De.population, Va.new_vaccinations,
	SUM (cast(Va.new_vaccinations as float)) OVER (PARTITION BY De.location 
	ORDER BY De.location, De.date)
	as PeopleVaccination
FROM PROJECT1.dbo.CovidDeaths$ De
JOIN PROJECT1.dbo.CovidVaccinaions$ Va
	ON De.location = Va.location
	AND De.date = Va.date  
WHERE De.continent is not null

