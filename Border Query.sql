/* 
Data Cleaning and Data Exploration of the Poland Ukraine border between January and March 2022

skills used: CTE's,Temp Table,Aggregate Functions, Creating Views, Converting Data Types e.t.c

*/

---------------------------------------DATA CLEANING-----------------------------------------------

select * from dbo.Border_Data


--Standardized Date Format

select Date_of_Crossing ,(CONVERT(DATE,Date_of_Crossing)) 
from Border_Data

ALTER TABLE Border_Data
ADD Crossing_Date DATE;

UPDATE Border_Data 
SET Crossing_Date = (CONVERT(DATE,Date_of_Crossing)) 


----POPULATE Border_crossing DATA

select Border_crossing from Border_Data
where Border_crossing IS NULL

UPDATE Border_Data 
SET   Border_crossing = ISNULL(Border_crossing , 'Dorohusk-Jagodzin')



---Separating Column	DirectiontoFromPoland

select Direction_to_from_Poland,
substring(Direction_to_from_Poland, 1,  PATINDEX('% %' , Direction_to_from_Poland)) as Direction
from dbo.Border_Data

ALTER TABLE Border_Data
ADD Direction nvarchar(255);

UPDATE Border_Data 
SET   Direction = substring(Direction_to_from_Poland, 1,  PATINDEX('% %' , Direction_to_from_Poland))



--Replacing '0' with 'Nill' in the UESchengen Column

select distinct(UE_Schengen),count(UE_Schengen)
from Border_Data
Group by UE_Schengen
Order by 2

Select  UE_Schengen,
case when  UE_Schengen = '0' then 'Nill'
	 Else  UE_Schengen
	 End
from Border_Data

UPDATE Border_Data
SET UE_Schengen = case when  UE_Schengen = '0' then 'Nill'
	 Else  UE_Schengen
	 End


---- Dropping unused Columns

select * from dbo.Border_Data

ALTER TABLE Border_Data
Drop Column Date_of_Crossing

---------------------------------------DATA EXPLORATION----------------------------------------------------
-----------------------------------------------------------------------------------------------------------

select * from dbo.Border_Data


--- Country with the highest number of people(Refugees) entering Poland from Ukraine since the war began 
-- The war started 24th february 2022

select Citizenship_code,sum(Number_of_persons_checked_in) AS Highest_Arrival
from Border_Data
where Direction_to_from_Poland = 'arrival in Poland' and (Crossing_Date) > '2022-02-23'
Group by Citizenship_code
Order BY 2 desc


--Country with the highest number of people entering Ukraine from Poland since the war began

select Citizenship_code,sum(Number_of_persons_checked_in) AS Highest_Departure
from Border_Data
where Direction_to_from_Poland = 'departure from Poland' and (Crossing_Date) > '2022-02-23'
Group by Citizenship_code
Order BY 2 desc


--Days with the highest arrival of refugees

select Crossing_Date, sum(Number_of_persons_checked_in) as Highest_Refugee_Day
from Border_Data
where Direction_to_from_Poland = 'arrival in Poland' and (Crossing_Date) > '2022-02-23'
Group by Crossing_Date
Order BY 2 desc


--Increase in Refugees by Country as the war lingers

select Citizenship_code,Crossing_Date,Number_of_persons_checked_in,sum(Number_of_persons_checked_in) 
OVER (partition by Citizenship_code order  by Citizenship_code,Crossing_Date) as Refugee_by_Country
from Border_Data
where Direction_to_from_Poland = 'arrival in Poland' and (Crossing_Date) > '2022-02-23'



--Using CTE's to perform calculation on Partition by in the previous Query

with Refugees (Citizenship_code,Crossing_Date,Number_of_persons_checked_in,Refugees_by_country)
as
(
select Citizenship_code,Crossing_Date,Number_of_persons_checked_in,sum(convert(bigint, Number_of_persons_checked_in)) 
OVER (partition by Citizenship_code order  by Citizenship_code,Crossing_Date) as Refugees_by_Country
from Border_Data 
where Direction_to_from_Poland = 'arrival in Poland' and (Crossing_Date) > '2022-02-23'
)
select * from Refugees



-- Using Temp Table to perform calculation on Partition by in the previous Query

Drop Table if exists #Refugees_in_Poland
create Table #Refugees_in_Poland
(
Citizenship_code nvarchar(255),
Crossing_Date datetime,
Number_of_persons_checked_in numeric,
Refugees_by_Country numeric
)
insert into #Refugees_in_Poland
select Citizenship_code,Crossing_Date,Number_of_persons_checked_in,sum(convert(bigint, Number_of_persons_checked_in)) 
OVER (partition by Citizenship_code order  by Citizenship_code,Crossing_Date) as Refugees_by_Country
from Border_Data 
where Direction_to_from_Poland = 'arrival in Poland' and (Crossing_Date) > '2022-02-23'
select * from #Refugees_in_Poland



-- Creating Views to store data

Create view Refugees_entering_Poland  as
select Citizenship_code,Crossing_Date,Number_of_persons_checked_in,sum(convert(bigint, Number_of_persons_checked_in)) 
OVER (partition by Citizenship_code order  by Citizenship_code,Crossing_Date) as Refugees_by_Country
from Border_Data 
where Direction_to_from_Poland = 'arrival in Poland' and (Crossing_Date) > '2022-02-23'





