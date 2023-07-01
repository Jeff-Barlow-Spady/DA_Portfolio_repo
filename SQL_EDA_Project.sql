--SELECT *
--From SqlProject.dbo.CovidDeathsTrun$
--order by 3, 4




--SELECT *
--FROM SqlProject.dbo.CovidVaccinations$
--order by 3, 4


--Selecting Data we'll be using
--SELECT location, date, total_cases, new_cases, total_deaths, population
--FROM SqlProject..CovidDeathsTrun$
--order by 1, 2
-- Total Deaths vs Total Cases
SELECT location, date, 
		total_cases,
		total_deaths, 
		(total_deaths/total_cases)*100 as DeathPcnt -- Create new column
FROM SqlProject..CovidDeathsTrun$
WHERE location like '%canada%'
order by 1,2

-- Total Deaths vs Population - Percentage of population who have contracted Covid
SELECT location, date,
	   population, total_deaths, 
	   (total_deaths/population)*100 as DeathPopPcnt -- Create another column
FROM SqlProject..CovidDeathsTrun$
WHERE location like '%canada%'
order by 1,2


-- Looking at countries with highest infection rate compared to population
SELECT location, population,
		max(total_cases) as HighestInfecRate, --New column for highest count of infections
		MAX((total_cases/population))*100 as PercentInfected -- Column for percentage
FROM SqlProject..CovidDeathsTrun$
group by location, population
order by PercentInfected DESC

-- Highest Death Count by population
SELECT location, max(cast(total_deaths as int)) as TotalDeathCount
FROM SqlProject.dbo.CovidDeathsTrun$
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Percentage
SELECT location,
       MAX(cast(total_deaths as int)) as HighestDeathRate,
       MAX(total_deaths/population)*100 as MaxDeathPct
FROM SqlProject..CovidDeathsTrun$
--WHERE continent is not null
GROUP BY location
ORDER BY MaxDeathPct DESC


-- By Continent


-- Highest Death Count by continent
SELECT location, max(cast(total_deaths as int)) as TotalDeathCount
FROM SqlProject.dbo.CovidDeathsTrun$

WHERE continent is null

GROUP BY location

ORDER BY TotalDeathCount DESC


--Global Numbers

SELECT  SUM(cast(new_cases as int)) as total_cases,
		SUM(cast(new_deaths as int)) as total_deaths, 
		SUM(cast(new_deaths as int)) / SUM(new_cases)*100 as DeathPcnt -- Create new column
FROM SqlProject..CovidDeathsTrun$
--WHERE location like '%canada%
WHERE continent is not null
--GROUP BY date
order by 1,2



-- Joining tables

Select dea.continent, dea.location,
       dea.date, dea.population, 
	   vac.new_vaccinations,
	   SUM(CONVERT(int,vac.new_vaccinations)) OVER (partition by dea.location 
	   ORDER BY dea.location, dea.date) as RollingVaccination
FROM SqlProject..CovidDeathsTrun$ dea
JOIN SqlProject..CovidVaccinations$_xlnm#_FilterDatabase vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3


WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingVaccination)
as
(
Select dea.continent, dea.location,
       dea.date, dea.population, 
	   vac.new_vaccinations,
	   SUM(CONVERT(int,vac.new_vaccinations)) OVER (partition by dea.location ORDER BY dea.location, dea.date) as RollingVaccination
FROM SqlProject..CovidDeathsTrun$ dea
JOIN SqlProject..CovidVaccinations$_xlnm#_FilterDatabase vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *, (RollingVaccination/population)*100 as PercentPopulationVaccinated
FROM PopvsVac


--USING TEMP TABLE
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
PercentPopulationVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingVaccinations
--, (RollingPeopleVaccinated/population)*100
From SqlProject..CovidDeathsTrun$ dea
Join SqlProject..CovidVaccinations$_xlnm#_FilterDatabase vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingVaccinations/Population)*100
From #PercentPopulationVaccinated


CREATE view PercentPopulationVaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingVaccinations
--, (RollingPeopleVaccinated/population)*100
From SqlProject..CovidDeathsTrun$ dea
Join SqlProject..CovidVaccinations$_xlnm#_FilterDatabase vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3

SELECT * FROM PercentPopulationVaccinated