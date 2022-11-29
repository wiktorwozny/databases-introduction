use Northwind

-- Napisz polecenie, które oblicza wartość sprzedaży dla każdego zamówienia i
-- zwraca wynik posortowany w malejącej kolejności (wg wartości sprzedaży).

select OrderID, round(sum(UnitPrice * Quantity * (1 - Discount)), 2) as value
from [Order Details]
group by OrderID
order by value desc

-- Zmodyfikuj zapytanie z poprzedniego punktu, tak aby zwracało pierwszych
-- 10 wierszy

select top 10 OrderID, round(sum(UnitPrice * Quantity * (1 - Discount)), 2) as value
from [Order Details]
group by OrderID
order by value desc

-- Podaj liczbę zamówionych jednostek produktów dla produktów, dla których
-- productid < 3

select ProductID, sum(Quantity) as amount
from [Order Details]
where ProductID < 3
group by ProductID

-- Zmodyfikuj zapytanie z poprzedniego punktu, tak aby podawało liczbę
-- zamówionych jednostek produktu dla wszystkich produktów

select ProductID, sum(Quantity) as amount
from [Order Details]
-- where ProductID < 3
group by ProductID

-- Podaj nr zamówienia oraz wartość zamówienia, dla zamówień, dla których
-- łączna liczba zamawianych jednostek produktów jest > 250

select OrderID, round(sum(Quantity * (1 - Discount) * UnitPrice), 2)
from [Order Details]
group by OrderID
having sum(Quantity) > 250

-- Dla każdego pracownika podaj liczbę obsługiwanych przez niego zamówień

select EmployeeID, count(*) as 'amount of orders'
from Orders
group by EmployeeID

-- Dla każdego spedytora/przewoźnika podaj wartość "opłata za przesyłkę"
-- przewożonych przez niego zamówień

select ShipVia, sum(Freight) as 'opłata za przesyłkę'
from Orders
group by ShipVia
order by ShipVia

-- Dla każdego spedytora/przewoźnika podaj wartość "opłata za przesyłkę"
-- przewożonych przez niego zamówień w latach o 1996 do 1997

select ShipVia, sum(Freight) as 'opłata za przesyłkę'
from Orders
where year(ShippedDate) between 1996 and 1997
group by ShipVia
order by ShipVia

-- Dla każdego pracownika podaj liczbę obsługiwanych przez niego zamówień z
-- podziałem na lata i miesiące

select EmployeeID, year(RequiredDate) as year, month(RequiredDate) as month, count(*) as amount
from Orders
group by EmployeeID, year(RequiredDate), month(RequiredDate)
with rollup
order by EmployeeID

select EmployeeID, year(RequiredDate) as year, month(RequiredDate) as month, count(*) as amount
from Orders
group by EmployeeID, year(RequiredDate), month(RequiredDate)
order by EmployeeID

-- Dla każdej kategorii podaj maksymalną i minimalną cenę produktu w tej
-- kategori

select CategoryId, min(UnitPrice) as minPrice, max(UnitPrice) as maxPrice
from Products
group by CategoryId

