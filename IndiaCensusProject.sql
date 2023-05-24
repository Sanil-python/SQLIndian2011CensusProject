select * from PortfolioProject..Data1
select * from PortfolioProject..Data2
---------------------------------------------------------------------------
-- number of rows into our dataset
select COUNT(*) from PortfolioProject..Data1
select COUNT(*) from PortfolioProject..Data2
---------------------------------------------------------------------------
-- dataset for Odisha and Maharashtra
select * from PortfolioProject..Data1 where state in ('Odisha', 'Maharashtra')
---------------------------------------------------------------------------
-- population of India
select sum(population) from PortfolioProject..Data2
---------------------------------------------------------------------------
-- avg growth
select state, avg(Growth)*100 as Growth_Avg from PortfolioProject..Data1 group by State
---------------------------------------------------------------------------
-- avg sex ratio
select state, round(avg(Sex_Ratio), 0) as Avg_Sex_Ratio_Per_Ratio from PortfolioProject..Data1 group by State
---------------------------------------------------------------------------------------------------------------------
-- avg literacy rate > 90
select State, AVG(literacy) as Avg_literacy_per_State from PortfolioProject..Data1 group by State
having AVG(literacy) > 90 order by Avg_literacy_per_State desc
---------------------------------------------------------------------------------------------------------------------
-- top 3 state showing highest growth ratio
select top 3 state, avg(growth)*100 as Highest_Growth_Rate from PortfolioProject..Data1
group by State order by avg(growth) desc
---------------------------------------------------------------------------------------------------------------------
--bottom 3 state showing lowest sex ratio
select top 3 state,round(avg(sex_ratio),0) avg_sex_ratio from PortfolioProject..data1 group by state order by avg_sex_ratio asc;
---------------------------------------------------------------------------------------------------------------------
-- top and bottom 3 states in literacy state
drop table if exists #topstates;
create table #topstates
( state nvarchar(255), topstate float)

insert into #topstates
select state,round(avg(literacy),0) avg_literacy_ratio from PortfolioProject..data1 
group by state order by avg_literacy_ratio desc;

drop table if exists #bottomstates;
create table #bottomstates
( state nvarchar(255), bottomstate float)

insert into #bottomstates
select state,round(avg(literacy),0) avg_literacy_ratio from PortfolioProject..data1 
group by state order by avg_literacy_ratio desc;
------------------------------------------------------------------------------------------------
--union opertor
select * from(select top 3 * from #topstates order by #topstates.topstate desc) as a
union
select * from(select top 3 * from #bottomstates order by #bottomstates.bottomstate asc) as b
------------------------------------------------------------------------------------------------
-- states starting with letter a
select state from PortfolioProject..Data1 where State like 'm%' group by State
------------------------------------------------------------------------------------------------
-- joining both table

--total males and females
		--(females/males = sex_ratio------------1
		--	females + males = population--------2
		--	females = population - males--------3
		--	population-males = sex_ratio*males
		--	population = males(sex_ratio+1)
		--	males = population/(sex_ratio+1)-----males
		--	females = population-population/(sex_ratio+1)----females)
select d.State, sum(d.Males), sum(d.Females) from
(select c.District, c.State, round(c.Population/(c.Sex_Ratio+1), 0) as Males, round((c.Population*c.Sex_Ratio)/(c.Sex_Ratio+1), 0) as Females from
(select a.District, a.State, a.Sex_Ratio/1000 as Sex_Ratio, b.Population from PortfolioProject..Data1 as a join PortfolioProject..Data2 as b on a.District = b.District) as c) as d
group by State
--------------------------------------------------------------------------------------------------------------------------------------
-- total literacy rate
		--(total literate people/population = literacy_ratio
		--total literate people = literacy_ratio*population
		--total illiterate people = (1-literacy_ration)*population)
select d.State, sum(d.literate_people) as Literate_People, sum(d.iliterate_people) as Iliterate_People from
(select c.District, c.State, round(c.literacy_ratio*c.Population, 0) as literate_people, round((1-c.literacy_ratio)*c.Population, 0) as iliterate_people from
(select a.District, a.State, a.Literacy/100 as literacy_ratio, b.Population from PortfolioProject..Data1 as a join PortfolioProject..Data2 as b on a.District = b.District) as c) as d
group by State
--------------------------------------------------------------------------------------------------------------------------------------
-- population in previous census
		--(previous_census+growth*previous_census = population
		--previous_census = population/(1+growth))
select sum(e.Current_Census_Population) as Current_Census_Population, sum(e.Previous_Census_Population) as Previous_Census_Population from
(select d.State, sum(d.current_census_population) as Current_Census_Population, sum(d.previous_census_population) as Previous_Census_Population from
(select c.District, c.State, round(c.Population/(1+c.Growth), 0) as previous_census_population, c.Population as current_census_population from
(select a.District, a.State, a.Growth, b.Population from PortfolioProject..Data1 as a join PortfolioProject..Data2 as b on a.District = b.District)as c) as d
group by State)e
--------------------------------------------------------------------------------------------------------------------------------------
-- population vs area
select (g.total_area/g.previous_census_population) as area_per_previous_census_population, (g.total_area/g.current_census_population) as 
area_per_current_census_population from
(select q.*,r.total_area from (

select '1' as keyy,n.* from
(select sum(m.previous_census_population) previous_census_population,sum(m.current_census_population) current_census_population from(
select e.state,sum(e.previous_census_population) previous_census_population,sum(e.current_census_population) current_census_population from
(select d.district,d.state,round(d.population/(1+d.growth),0) previous_census_population,d.population current_census_population from
(select a.district,a.state,a.growth growth,b.population from PortfolioProject..data1 a inner join PortfolioProject..data2 b on a.district=b.district) d) e
group by e.state)m) n) q inner join (

select '1' as keyy,z.* from (
select sum(area_km2) total_area from PortfolioProject..data2)z) r on q.keyy=r.keyy)g
--------------------------------------------------------------------------------------------------------------------------------------
--window function
--output top 3 districts from each state with highest literacy rate
select a.* from
(select District, State, Literacy, RANK() over(partition by state order by literacy desc) as rnk from PortfolioProject..Data1) as a
where a.rnk in (1,2,3) order by State