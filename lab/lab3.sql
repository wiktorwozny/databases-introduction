use Northwind

-- Podaj liczbę produktów o cenach mniejszych niż 10$ lub większych niż
-- 20$

select count(*) as 'amount'
from Products
where UnitPrice < 10 or UnitPrice > 20

-- Podaj maksymalną cenę produktu dla produktów o cenach poniżej 20$

select top 1 UnitPrice
from Products
where UnitPrice < 20
order by UnitPrice desc

-- Podaj maksymalną i minimalną i średnią cenę produktu dla produktów o
-- produktach sprzedawanych w butelkach (‘bottle’)

select max(UnitPrice) as 'max', min(UnitPrice) as 'min', avg(UnitPrice) as 'avg'
from Products
where QuantityPerUnit like '%bottle%'

-- Wypisz informację o wszystkich produktach o cenie powyżej średniej

select *
from Products
where UnitPrice > (select avg(UnitPrice) from Products)

-- Podaj wartość zamówienia o numerze 10250

select sum((Quantity * (1 - Discount) * UnitPrice))
from [Order Details]
where OrderID = 10250

-- Podaj maksymalną cenę zamawianego produktu dla każdego zamówienia

select orderid, max(UnitPrice) as 'max_price'
from [Order Details]
group by orderid

-- Posortuj zamówienia wg maksymalnej ceny produktu

select orderid, max(UnitPrice) as 'max_price'
from [Order Details]
group by orderid
order by max_price desc

-- Podaj maksymalną i minimalną cenę zamawianego produktu dla każdego
-- zamówienia

select orderid, min(UnitPrice) as 'min_price', max(UnitPrice) as 'max_price'
from [Order Details]
group by orderid

-- Podaj liczbę zamówień dostarczanych przez poszczególnych spedytorów
-- (przewoźników

select ShipVia, count(*)
from Orders
group by ShipVia

-- Który z spedytorów był najaktywniejszy w 1997 roku

select top 1 ShipVia, count(orderid) as 'amount'
from Orders
where year(ShippedDate) = 1997
group by ShipVia
order by amount desc

-- Wyświetl zamówienia dla których liczba pozycji zamówienia jest większa niż 5

select orderid, count(*) as amount
from [Order Details]
group by orderid
having count(*) > 5

-- Wyświetl klientów dla których w 1998 roku zrealizowano więcej niż 8 zamówień
-- (wyniki posortuj malejąco wg łącznej kwoty za dostarczenie zamówień dla
-- każdego z klientów)

select CustomerID, count(*) as amount, sum(Freight) as price
from Orders
where year(ShippedDate) = 1998
group by CustomerID
having count(*) > 8
order by price desc

-- str 15 w pdf za pomoca poznanych juz komend

select Null, Null, sum(quantity) as total_quantity
from orderhist

-- ...

-- ile lat przepracowal w firmie kazdy z pracownikow

select EmployeeID, -datediff(YEAR, getdate(), HireDate) as ile_lat
from Employees

-- policz sume lat przepracowanych przez pracownikow i sredni czas pracy w firmie
select sum(-datediff(YEAR, getdate(), HireDate)) as suma
from Employees

-- policz z ilu liter sklada sie najkrotsze imie pracownika
select min(len(FirstName)) as najmniej
from Employees


