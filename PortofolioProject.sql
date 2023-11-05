select * from PortofolioProject.dbo.CovidDeaths
order by 3,4

--Select * from CovidVaccinations
--order by 3,4

--Select Data That we are going to be using
select 
Location, 
date, 
total_cases,
new_cases,
total_deaths,
population
from CovidDeaths
order by 1,2


--Total Casses vs Total Deaths
-- show likelihood of dying if you contract in your country
select 
Location, 
date, 
total_cases,
total_deaths,
(total_deaths/total_cases)*100 as DeathPercentage
from PortofolioProject.dbo.CovidDeaths
where location like '%indonesia%'
and continent is not null
order by 1,2

--Total cases vs Population
-- Shows what percentage of population infected with Covid

select 
Location, 
date, 
total_cases,
population,
(total_cases/population)*100 as PopulationPercentage
from CovidDeaths
where location like '%indonesia%'
order by 1,2


--countries with highest infection rate compared to Population

select 
Location,  
population,
Max(total_cases) as HighestInfectionCount,
Max((total_cases/population))*100 as PercentPopulationInfected
from PortofolioProject.dbo.CovidDeaths
--where location like '%Indonesia%'
Group by Location, Population
order by PercentPopulationInfected desc


--Countries with Highest Death Count per Population

select 
Location,  
population,
Max(cast(total_deaths as int)) as TotalDeathCount,
Max((total_deaths/population))*100 as PercentPopulationDeath
from PortofolioProject.dbo.CovidDeaths
--where location like '%Indonesia%'
where continent is not null
Group by Location, Population
order by TotalDeathCount desc

--continents with the highest death per population
select 
continent,
Max(cast(total_deaths as int)) as TotalDeathCount
from PortofolioProject.dbo.CovidDeaths
--where location like '%Indonesia%'
WHERE continent is not null
Group by continent
order by TotalDeathCount desc

--GLOBAL NUMBERS
SELECT 
    date, 
    SUM(new_cases) AS TotalNewCases,
    SUM(CAST(new_deaths AS INT)) AS TotalNewDeaths,
    (SUM(CAST(new_deaths AS INT)) / NULLIF(SUM(new_cases), 0)) * 100 AS DeathPercentage
FROM PortofolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
    AND new_cases IS NOT NULL
GROUP BY date
ORDER BY 1,2

SELECT 
    SUM(new_cases) AS TotalNewCases,
    SUM(CAST(new_deaths AS INT)) AS TotalNewDeaths,
    (SUM(CAST(new_deaths AS INT)) / NULLIF(SUM(new_cases), 0)) * 100 AS DeathPercentage
FROM PortofolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
    AND new_cases IS NOT NULL
--GROUP BY date
ORDER BY 1,2


-- Total population vs vaccination
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

select
CD.continent,
CD.location,
CD.date,
CD.population,
CV.new_vaccinations,
SUM(Convert(int,CV.new_vaccinations)) OVER(Partition by CD.LOCATION order by CD.location, 
CD.Date) as RollingPeopleVaccinated	
from CovidDeaths CD
join CovidVaccinations CV
on CD.location = CV.location
AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
ORDER BY 2,3

-- Using CTE to perform Calculation on Partition By in previous query
with PopvsVac (Continent, location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as (
select
CD.continent,
CD.location,
CD.date,
CD.population,
CV.new_vaccinations,
SUM(Convert(int,CV.new_vaccinations)) OVER(Partition by CD.LOCATION order by CD.location, 
CD.Date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
from CovidDeaths CD
join CovidVaccinations CV
on CD.location = CV.location
AND CD.date = CV.date
WHERE CD.continent IS NOT NULL)
--ORDER BY 2,3

select *, (RollingPeopleVaccinated/population)*100
from PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

Drop table if exists #PercentPopulationVaccinated

create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated
select
CD.continent,
CD.location,
CD.date,
CD.population,
CV.new_vaccinations,
SUM(cast(CV.new_vaccinations as bigint)) OVER(Partition by CD.LOCATION order by CD.location, 
CD.Date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
from CovidDeaths CD
join CovidVaccinations CV
on CD.location = CV.location
AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
--ORDER BY 2,3

select *, (RollingPeopleVaccinated/population)*100
from #PercentPopulationVaccinated


--Creating view to store data for later visualization


create view PercentPopulationVaccinated AS
select
CD.continent,
CD.location,
CD.date,
CD.population,
CV.new_vaccinations,
SUM(cast(CV.new_vaccinations as bigint)) OVER(Partition by CD.LOCATION order by CD.location, 
CD.Date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
from CovidDeaths CD
join CovidVaccinations CV
on CD.location = CV.location
AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
--ORDER BY 2,3

SELECT * FROM PercentPopulationVaccinated 