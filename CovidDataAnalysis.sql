/*

Covid 19 Data Exploration

Skills used: 
Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/



Select *
From PortfolioProject..CovidDeaths
Where continent is not null
Order by 3,4



-- Select Data needed for analysis

Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null
Order by 1,2



-- Total Cases vs Total Deaths
-- Shows the Death Percentage in United States

Select location, date, total_cases, total_deaths, Format(Round((total_deaths/Cast(total_cases as float))*100, 2), '##.00') as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
	And continent is not null
Order by 1,2



-- Total Cases vs Population
-- Shows what percentage of population is infected with Covid

Select location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Order by 1,2



-- Countries with Highest Infection Rate compared to Population

Select location, population, Max(total_cases) as HighestInfectionCount, Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by location, population
Order by PercentPopulationInfected Desc



-- Countries with Highest Death Count per Population

Select location, Max(Cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
Group by location
order by TotalDeathCount Desc



-- BREAKING THINGS DOWN BY CONTINENT
-- Shows continents with the Highest Death Count per Population

Select continent, Max(Cast(total_deaths as int)) as TotalDeathCount
From CovidDeaths
Where continent is not null
Group by continent
Order by TotalDeathCount Desc



-- Shows Death Percentage by Date

Select date, Sum(new_cases) as total_cases, Sum(new_deaths) as total_deaths, (Sum(new_deaths)/Sum(new_cases))*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
	And new_cases != 0
Group by date
Order by 1,2



-- GLOBAL NUMBERS

Select Sum(new_cases) as total_cases, Sum(new_deaths) as total_deaths, (Sum(new_deaths)/Sum(new_cases))*100 as GlobalDeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
Order by 1,2



-- Total Population vs Vaccinations

Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
From PortfolioProject..CovidDeaths cd
Join PortfolioProject..CovidVaccinations cv
	On cd.location = cv.location
	And cd.date = cv.date
Where cd.continent is not null 
	And cv.new_vaccinations is not null
Order by 2, 3



-- Shows Rolling Total of Population that has received at least one Covid Vaccine

Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	Sum(Cast(cv.new_vaccinations as Bigint)) Over (Partition by cd.location 
	Order by cd.location, cd.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths cd
Join PortfolioProject..CovidVaccinations cv
	On cd.location = cv.location
	And cd.date = cv.date
Where cd.continent is not null 
	--And cv.new_vaccinations is not null
Order by 2, 3



-- Using CTE to perform calculation on Partition BY in above query
-- Shows Percentage of Population that has received at least one Covid Vaccine

With PopVsVac --(continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
	Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
		Sum(Cast(cv.new_vaccinations as Bigint)) Over (Partition by cd.location
		Order by cd.location, cd.date) as RollingPeopleVaccinated
	From PortfolioProject..CovidDeaths cd
	Join PortfolioProject..CovidVaccinations cv
		On cd.location = cv.location
		And cd.date = cv.date
	Where cd.continent is not null
	 --Order by 2,3
)

Select *, (RollingPeopleVaccinated/Population)*100 as PercentVaccinated
From PopVsVac
Order by 2, 3



-- Using Temp Table to perform calculation in the above query

Drop Table if exists PercentPopulationVaccinated

Create Table PercentPopulationVaccinated
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	RollingPeopleVaccinated numeric
)

Insert into PercentPopulationVaccinated
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	Sum(Cast(cv.new_vaccinations as Bigint)) Over (Partition by cd.location
	Order by cd.location, cd.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths cd
Join PortfolioProject..CovidVaccinations cv
	On cd.location = cv.location
	And cd.date = cv.date
Where cd.continent is not null


Select *
From PercentPopulationVaccinated
Order by 2, 3



-- Creating View to store date for later visualizations

Create View PercentPopulationVaccinatedViz as
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	Sum(Cast(cv.new_vaccinations as Bigint)) Over (Partition by cd.location
	Order by cd.location, cd.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths cd
Join PortfolioProject..CovidVaccinations cv
	On cd.location = cv.location
	And cd.date = cv.date
Where cd.continent is not null