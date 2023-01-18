create view project.ClientsWithAvailableFirstDiscount as
SELECT ClientID
FROM project.Clients AS C
WHERE (SELECT COUNT(underQuery.orderId)
       FROM (SELECT OrderID as orderId
             FROM project.Orders
             WHERE Orders.ClientID = C.ClientID
               AND (SELECT Value
                    FROM project.OrderSummaries
                    WHERE OrderSummaries.OrderID = Orders.OrderID) >=
                   (SELECT dv.Value FROM project.DictionaryValues as dv WHERE dv.ValueID = 2)) underQuery) >
      (SELECT dv.Value FROM project.DictionaryValues as dv WHERE dv.ValueID = 1)
go

grant select on ClientsWithAvailableFirstDiscount to moderator
go

grant select on ClientsWithAvailableFirstDiscount to worker
go

create view project.ClientsWithAvailableSecondDiscount as
SELECT ClientID
FROM project.Clients AS C
WHERE (SELECT SUM(underQuery.value)
       FROM (SELECT (SELECT Value
                     FROM project.OrderSummaries
                     WHERE OrderSummaries.OrderID = Orders.OrderID) as value
             FROM project.Orders
             WHERE Orders.ClientID = C.ClientID) underQuery) >
      (SELECT dv.Value FROM project.DictionaryValues as dv WHERE dv.ValueID = 4)
go

grant select on ClientsWithAvailableSecondDiscount to moderator
go

grant select on ClientsWithAvailableSecondDiscount to worker
go

CREATE view project.CompaniesSummaryMonthly as
select ClientID, CompanyName, Year, Month, COUNT(Month) as 'Orders', SUM(Value) as 'Value'
FROM (select ClientID, YEAR(OrderDate) as 'Year', MONTH(OrderDate) as 'Month', (
    SELECT SUM(Quantity*UnitPrice)
    FROM project.OrderDetails OD
    INNER JOIN project.Menus M on M.MenuID = OD.MenuID
    WHERE O.OrderID = OD.OrderId
    GROUP BY OD.OrderID) as 'Value'
from project.Orders O
) SAD
inner join project.Companies C ON C.CompanyID = ClientID
group by ClientID, CompanyName, Year, Month
go

grant select on CompaniesSummaryMonthly to moderator
go

grant select on CompaniesSummaryMonthly to worker
go

create view project.CompaniesSummaryOverall as

select Comp.CompanyID,
       (select count(ASD.OrderID)
        from (select Orders.OrderId
              From project.Orders
              where ClientID = Comp.CompanyID) ASD) as 'Orders',
       (select sum(DAS.Value)
        from (select Quantity * UnitPrice * (ISNULL(1 - PercentageValue, 1)) as 'Value'
              From project.Orders O
                       inner join project.OrderDetails OD on O.OrderID = OD.OrderId
                       inner join project.Menus M on M.MenuID = OD.MenuID
                       inner join project.Meals M2 on M2.MealID = M.MealID
                       left join project.Discounts D on O.ClientID = D.ClientID
                       left join project.DiscountDetails DD on DD.DiscountID = D.DiscountID
              where O.ClientID = Comp.CompanyID) DAS) as 'Value'
FROM project.Companies Comp
where (select sum(DAS.Value)
       from (select Quantity * UnitPrice * (ISNULL(1 - PercentageValue, 1)) as 'Value'
             From project.Orders O
                      inner join project.OrderDetails OD on O.OrderID = OD.OrderId
                      inner join project.Menus M on M.MenuID = OD.MenuID
                      inner join project.Meals M2 on M2.MealID = M.MealID
                      left join project.Discounts D on O.ClientID = D.ClientID
                      left join project.DiscountDetails DD on DD.DiscountID = D.DiscountID
             where O.ClientID = Comp.CompanyID) DAS) is not null
go

grant select on CompaniesSummaryOverall to moderator
go

grant select on CompaniesSummaryOverall to worker
go

CREATE view project.CompaniesSummaryWeekly as
select ClientID, CompanyName, Year, Week, COUNT(Week) as 'Orders', SUM(Value) as 'Value'
FROM (select ClientID, YEAR(OrderDate) as 'Year', DATEPART(week, OrderDate) as 'Week', (
    SELECT SUM(Quantity*UnitPrice)
    FROM project.OrderDetails OD
    INNER JOIN project.Menus M on M.MenuID = OD.MenuID
    WHERE O.OrderID = OD.OrderId
    group by OD.OrderID) as 'Value'
from project.Orders O
) SAD
inner join project.Companies C ON C.CompanyID = ClientID
group by ClientID, CompanyName, Year, Week
go

grant select on CompaniesSummaryWeekly to moderator
go

grant select on CompaniesSummaryWeekly to worker
go

create view project.CurrentMenu as
select MenuID, Menus.MealID, Name, UnitPrice, UnitInStock, Description, CategoryName, AddToMenuDate from project.Menus
              inner join project.Meals M on M.MealID = Menus.MealID
              inner join project.Categories C on C.CategoryID = M.CategoryID
              where RemoveFromMenuDate IS null
go

grant select on CurrentMenu to moderator
go

grant select on CurrentMenu to worker
go

CREATE view project.DiscountsMonthlyStat as
select YEAR(StartDate) as 'Year', MONTH(StartDate) as 'Month', COUNT(*) as 'CountOfDiscounts'
from project.DiscountDetails
group by YEAR(StartDate), MONTH(StartDate)
go

grant select on DiscountsMonthlyStat to moderator
go

grant select on DiscountsMonthlyStat to worker
go

CREATE view project.DiscountsWeeklyStat as
select YEAR(StartDate) as 'Year', DATEPART(week, StartDate) as 'Week',
       COUNT(*) as 'CountOfDiscounts'
from project.DiscountDetails
group by YEAR(StartDate), DATEPART(week, StartDate)
go

grant select on DiscountsWeeklyStat to moderator
go

grant select on DiscountsWeeklyStat to worker
go

CREATE view project.IndividualClientsSummaryMonthly as
select IC.ClientID, FirstName, LastName, Year, Month, COUNT(Month) as 'Orders', ROUND(SUM(Value), 2) as 'Value'
FROM (select ClientID,
             YEAR(OrderDate)       as 'Year',
             MONTH(OrderDate)      as 'Month',
             (SELECT ROUND(SUM(Quantity * UnitPrice *
                               ROUND((CAST(ISNULL(100 - PercentageValue, 100) AS FLOAT) / CAST(100 AS FLOAT)), 2)), 2)
              FROM project.OrderDetails OD
                       INNER JOIN project.Menus M on M.MenuID = OD.MenuID
                       left join project.Discounts D on O.ClientID = D.ClientID
                       left join project.DiscountDetails DD on DD.DiscountID = D.DiscountID
              WHERE O.OrderID = OD.OrderId
              group by OD.OrderID) as 'Value'
      from project.Orders O) SAD
         inner join project.IndividualClients IC ON IC.ClientID = SAD.ClientID
group by IC.ClientID, FirstName, LastName, Year, Month
go

grant select on IndividualClientsSummaryMonthly to moderator
go

grant select on IndividualClientsSummaryMonthly to worker
go

CREATE view project.IndividualClientsSummaryOverall as
select IC.ClientID,
       (select count(ASD.OrderID)
        from (select Orders.OrderId
              From project.Orders
              where ClientID = IC.ClientID) ASD)   as 'Orders',
       (select ROUND(sum(DAS.Value), 2)
        from (select Quantity * UnitPrice *
                     ROUND((CAST(ISNULL(100 - PercentageValue, 100) AS FLOAT) / CAST(100 AS FLOAT)), 2)
                         as 'Value'
              From project.Orders O
                       inner join project.OrderDetails OD on O.OrderID = OD.OrderId
                       inner join project.Menus M on M.MenuID = OD.MenuID
                       inner join project.Meals M2 on M2.MealID = M.MealID
                       left join project.Discounts D on O.ClientID = D.ClientID
                       left join project.DiscountDetails DD on DD.DiscountID = D.DiscountID
              where O.ClientID = IC.ClientID) DAS) as 'Value'
FROM project.IndividualClients IC
where (select ROUND(sum(DAS.Value), 2)
       from (select Quantity * UnitPrice *
                    ROUND((CAST(ISNULL(100 - PercentageValue, 100) AS FLOAT) / CAST(100 AS FLOAT)), 2)
                        as 'Value'
             From project.Orders O
                      inner join project.OrderDetails OD on O.OrderID = OD.OrderId
                      inner join project.Menus M on M.MenuID = OD.MenuID
                      inner join project.Meals M2 on M2.MealID = M.MealID
                      left join project.Discounts D on O.ClientID = D.ClientID
                      left join project.DiscountDetails DD on DD.DiscountID = D.DiscountID
             where O.ClientID = IC.ClientID) DAS) is not null
go

grant select on IndividualClientsSummaryOverall to moderator
go

grant select on IndividualClientsSummaryOverall to worker
go

CREATE view project.IndividualClientsSummaryWeekly as
select IC.ClientID, FirstName, LastName, Year, Week, COUNT(Week) as 'Orders', SUM(Value) as 'Value'
FROM (select ClientID,
             YEAR(OrderDate)           as 'Year',
             DATEPART(week, OrderDate) as 'Week',
             (SELECT ROUND(SUM(Quantity * UnitPrice *
                               ROUND((CAST(ISNULL(100 - PercentageValue, 100) AS FLOAT) / CAST(100 AS FLOAT)), 2)), 2)
              FROM project.OrderDetails OD
                       INNER JOIN project.Menus M on M.MenuID = OD.MenuID
                       left join project.Discounts D on O.ClientID = D.ClientID
                       left join project.DiscountDetails DD on DD.DiscountID = D.DiscountID
              WHERE O.OrderID = OD.OrderId
              group by OD.OrderID)     as 'Value'
      from project.Orders O) SAD
         inner join project.IndividualClients IC ON IC.ClientID = SAD.ClientID
group by IC.ClientID, FirstName, LastName, Year, Week
go

grant select on IndividualClientsSummaryWeekly to moderator
go

grant select on IndividualClientsSummaryWeekly to worker
go

CREATE view project.MealsIncomeStats as
select M2.MealID, M2.Name, sum(Quantity * M.UnitPrice * ROUND((ISNULL(100 - PercentageValue, 100) / 100), 2)) as 'amount' from project.Orders O
inner join project.OrderDetails OD on O.OrderID = OD.OrderId
inner join project.Menus M on M.MenuID = OD.MenuID
    inner join project.Meals M2 on M2.MealID = M.MealID
left join project.Discounts D on O.ClientID = D.ClientID
left join project.DiscountDetails DD on DD.DiscountID = D.DiscountID
group by M2.MealID, M2.Name
go

grant select on MealsIncomeStats to moderator
go

grant select on MealsIncomeStats to worker
go

create view project.MealsLongerThanTwoWeeksInMenu as
SELECT m.MealID, DATEDIFF(DAY, m.AddToMenuDate, getdate()) as 'How long in menu (days)'
FROM project.Menus as m
WHERE( m.RemoveFromMenuDate>=GETDATE() OR  m.RemoveFromMenuDate IS NULL)
AND DATEDIFF(DAY, m.AddToMenuDate, getdate())>14
go

grant select on MealsLongerThanTwoWeeksInMenu to moderator
go

grant select on MealsLongerThanTwoWeeksInMenu to worker
go

create view project.MealsSoldStatsMonthly as
select year(OrderDate) as 'year', month(OrderDate) as 'month', M.MealID, M.Name, sum(Quantity) as 'amount' from project.Meals M
inner join project.Menus M2 on M.MealID = M2.MealID
inner join project.OrderDetails OD on M2.MenuID = OD.MenuID
                                                          inner join project.Orders O on O.OrderID = OD.OrderId
group by M.MealID, M.Name, year(OrderDate), month(OrderDate)
go

grant select on MealsSoldStatsMonthly to moderator
go

grant select on MealsSoldStatsMonthly to worker
go

create view project.MealsSoldStatsOverall as
select M.MealID, M.Name, sum(Quantity) as 'amount' from project.Meals M
inner join project.Menus M2 on M.MealID = M2.MealID
inner join project.OrderDetails OD on M2.MenuID = OD.MenuID
group by M.MealID, M.Name
go

grant select on MealsSoldStatsOverall to moderator
go

grant select on MealsSoldStatsOverall to worker
go

CREATE view project.MonthlyIncome as
select year(OrderDate) as 'year', month(OrderDate) as 'month', sum(Quantity * M.UnitPrice * ROUND((ISNULL(100 - PercentageValue, 100) / 100), 2)) as 'amount' from project.Orders O
inner join project.OrderDetails OD on O.OrderID = OD.OrderId
inner join project.Menus M on M.MenuID = OD.MenuID
left join project.Discounts D on O.ClientID = D.ClientID
left join project.DiscountDetails DD on DD.DiscountID = D.DiscountID
group by year(OrderDate), month(OrderDate)
go

grant select on MonthlyIncome to moderator
go

grant select on MonthlyIncome to worker
go

create view project.NotUsedMealsInStock as
select Name, MealID, UnitInStock
FROM project.Meals
where MealID NOT IN (select Menus.MealID
                     from project.Menus
                              inner join project.Meals M on M.MealID = Menus.MealID
                     where RemoveFromMenuDate IS NULL)
  and UnitInStock > 0
go

exec sp_addextendedproperty 'MS_Description', 'Dania które sa na magazynie ale nie w aktualnym menu', 'SCHEMA',
     'project', 'VIEW', 'NotUsedMealsInStock'
go

grant select on NotUsedMealsInStock to moderator
go

grant select on NotUsedMealsInStock to worker
go

CREATE view project.OrderSummaries as
select Orders.OrderID,
       ROUND(SUM(Quantity * UnitPrice *
                 ROUND((CAST(ISNULL(100 - PercentageValue, 100) AS FLOAT) / CAST(100 AS FLOAT)), 2)), 2) as 'Value'
from project.Orders
         inner join project.OrderDetails OD on Orders.OrderID = OD.OrderId
         inner join project.Menus M on M.MenuID = OD.MenuID
         left join project.Discounts D on Orders.ClientID = D.ClientID
         left join project.DiscountDetails DD on DD.DiscountID = D.DiscountID
group by Orders.OrderID
go

grant select on OrderSummaries to moderator
go

grant select on OrderSummaries to worker
go

create view project.CurrentReservations as
select * from project.Reservations R
where Status = 'pending'
go

grant select on PendingReservations to moderator
go

grant select on PendingReservations to worker
go

create view project.ReservationsInfo as
select R.ReservationID, R.SizeOfReservation, T.TableNumber, T.Capacity from project.Reservations R
inner join project.ReservationDetails RD on R.ReservationID = RD.ReservationID
                       inner join project.Tables T on T.TableNumber = RD.TableID
where Status = 'accepted'
go

grant select on ReservationsInfo to moderator
go

grant select on ReservationsInfo to worker
go

CREATE view project.SeafoodMeals as
SELECT MealID, Name, Description, UnitInStock
FROM project.Meals M
INNER JOIN project.Categories C ON C.CategoryID = M.CategoryID
WHERE CategoryName = 'Seafood'
go

grant select on SeafoodMeals to moderator
go

grant select on SeafoodMeals to worker
go

CREATE view project.SeafoodMealsStats as
select M.MealID, OrderDetails.OrderId, Quantity from project.OrderDetails
inner join project.Orders O on O.OrderID = OrderDetails.OrderId
inner join project.Menus M on M.MenuID = OrderDetails.MenuID
inner join project.Meals M2 on M2.MealID = M.MealID
left join project.Reservations R on R.ReservationID = O.ReservationID
where (M.MealID in (SELECT MealID FROM project.SeafoodMeals)) and GETDATE() < R.StartDate and DATEDIFF(DAY, getdate(), R.StartDate) < 7
union
select M.MealID, OrderDetails.OrderId, Quantity from project.OrderDetails
inner join project.Orders O on O.OrderID = OrderDetails.OrderId
inner join project.Menus M on M.MenuID = OrderDetails.MenuID
inner join project.Meals M2 on M2.MealID = M.MealID
left join project.Takeaways T on T.TakeawayID = O.TakeawayID
where (M.MealID in (SELECT MealID FROM project.SeafoodMeals)) and GETDATE() < T.TakewayTime and DATEDIFF(DAY, getdate(), T.TakewayTime) < 7
go

grant select on SeafoodMealsStats to moderator
go

grant select on SeafoodMealsStats to worker
go

create view project.TablesMonthly as
select  YEAR(StartDate) as 'Year', MONTH(StartDate) as 'Month', TableID, Capacity, COUNT(TableID) as 'Count'
from project.Tables T
         inner join project.ReservationDetails RD on T.TableNumber = RD.TableID
         inner join project.Reservations R2 on R2.ReservationID = RD.ReservationID
group by TableID, YEAR(StartDate), MONTH(StartDate), Capacity
go

grant select on TablesMonthly to moderator
go

grant select on TablesMonthly to worker
go

create view project.TablesWeekly as
select YEAR(StartDate) as 'Year', DATEPART(week, StartDate) as 'Week', TableID, Capacity, COUNT(TableID) as 'Count'
from project.Tables T
         inner join project.ReservationDetails RD on T.TableNumber = RD.TableID
         inner join project.Reservations R2 on R2.ReservationID = RD.ReservationID
group by TableID, YEAR(StartDate), DATEPART(week, StartDate), Capacity
go

grant select on TablesWeekly to moderator
go

grant select on TablesWeekly to worker
go

CREATE view project.WeeklyIncome as
select year(OrderDate) as 'year', datepart(week, OrderDate) as 'week', sum(Quantity * M.UnitPrice * ROUND((ISNULL(100 - PercentageValue, 100) / 100), 2)) as 'amount' from project.Orders O
inner join project.OrderDetails OD on O.OrderID = OD.OrderId
inner join project.Menus M on M.MenuID = OD.MenuID
left join project.Discounts D on O.ClientID = D.ClientID
left join project.DiscountDetails DD on DD.DiscountID = D.DiscountID
group by year(OrderDate), datepart(week, OrderDate)
go

grant select on WeeklyIncome to moderator
go

grant select on WeeklyIncome to worker
go

