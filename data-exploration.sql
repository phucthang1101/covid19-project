Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

-- tableau-table-1
-- Looking at Total Case vs Total Deaths and its ration
-- Shows likelihood of dying if you contract covid in your country
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
--where location like '%vietnam%' and continent is not null
where continent is not null
order by 1,2

-- Looking at Total Cases and Population
-- Shows what percentage of population get Covid
Select Location, date, population,  total_cases, (total_cases/population)*100 as PopulationPercentage
From PortfolioProject..CovidDeaths
where location like '%vietnam%' and continent is not null
order by 1,2

-- tableau-table-2
-- Looking at Countries with highest infection rate compare to population
Select Location, population,  MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population)*100) as 
PercentPopulationInfected
From PortfolioProject..CovidDeaths
--where location like '%vietnam%'
where continent is not null
group by location, population
order by PercentPopulationInfected desc

-- tableau-table-3
-- Countries with Highest Infection Rate compared to Population
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as
PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc

-- Showing Countries with Highest Death Count per Population
-- (the type of total_deaths is nvarchar, hence we need to cast it into integer to perform addition
Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
where continent is not null
--where location like '%vietnam%'
group by location
order by TotalDeathCount desc



-- tableau-table-4.
Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Group by Location, Population, date
order by PercentPopulationInfected desc





-- LET'S BREAK THINGS DOWN BY CONTINENT
Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
where continent is null and location not in ('World','European Union','International')
--where location like '%vietnam%'
group by location
order by TotalDeathCount desc


-- GLOBAL NUMBERS
-- The date has highest 
Select SUM(new_cases) as total_cases
, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2


-- here we're using "window_function" in sql:
-- syntax: window_function (columns) OVER ( [ PARTITION BY partition_list ] [ ORDER BY order_list] )
-- window_function: could be any normal function like SUM(), AVG(), MAX(), MIN(), COUNT()
-- columns: The target column. In other words, the name of the column for which we need an aggregated value
-- OVER: Specifies the window clauses for aggregate functions.
-- PARTITION BY (partition_list): Defines the window (set of rows on which window function operates) for window functions
-- ORDER BY (order_list): Sorts the rows within each partition. If ORDER BY is not specified, ORDER BY uses the entire table.


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as numeric(12,0))) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Use CTE (Common Table Expression) to perform calculation on Partition By in previous query

-- Define the CTE expression name and column list.
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
-- Define the CTE query.
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as numeric(12,0))) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
-- Define the outer query referencing the CTE name.
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac
where PopvsVac.Location = 'Canada' 
order by PopvsVac.Date

--Select *
--From PortfolioProject..CovidVaccinations as test
--where test.Location = 'Canada' and test.new_vaccinations is not null
--order by test.Date


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as numeric(12,0))) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinatedView as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as numeric(12,0))) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 


select * from PercentPopulationVaccinatedView as test
where test.location = 'canada'