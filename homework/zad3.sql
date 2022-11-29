use northwind

-- Dla każdego zamówienia podaj łączną liczbę zamówionych jednostek towaru oraz
-- nazwę klienta.

select O.OrderID, sum(quantity) as 'sum', CompanyName
from [Order Details]
inner join Orders O on [Order Details].OrderID = O.OrderID
inner join Customers C on O.CustomerID = C.CustomerID
group by O.OrderID, CompanyName
-- order by sum(quantity) desc

-- Zmodyfikuj poprzedni przykład, aby pokazać tylko takie zamówienia, dla których
-- łączna liczbę zamówionych jednostek jest większa niż 250

select O.OrderID, sum(quantity) as 'sum', CompanyName
from [Order Details]
inner join Orders O on [Order Details].OrderID = O.OrderID
inner join Customers C on O.CustomerID = C.CustomerID
group by O.OrderID, CompanyName
having sum(Quantity) > 250
order by sum(Quantity) desc

-- Dla każdego zamówienia podaj łączną wartość tego zamówienia oraz nazwę
-- klienta.

select Orders.orderid, sum(quantity * UnitPrice) as 'sum', CompanyName
from [Order Details]
inner join Orders
on [Order Details].OrderID = Orders.OrderID
inner join Customers
on Orders.CustomerID = Customers.CustomerID
group by Orders.OrderID, CompanyName
order by sum(quantity * UnitPrice) desc

-- Zmodyfikuj poprzedni przykład, aby pokazać tylko takie zamówienia, dla których
-- łączna liczba jednostek jest większa niż 250

select Orders.orderid, sum(quantity * UnitPrice) as 'sum', CompanyName
from [Order Details]
inner join Orders
on [Order Details].OrderID = Orders.OrderID
inner join Customers
on Orders.CustomerID = Customers.CustomerID
group by Orders.OrderID, CompanyName
having sum(quantity) > 250

-- Zmodyfikuj poprzedni przykład tak żeby dodać jeszcze imię i nazwisko
-- pracownika obsługującego zamówienie

select Orders.orderid, round(sum(quantity * UnitPrice * (1 - Discount)), 2) as 'sum', CompanyName, firstname, lastname
from [Order Details]
inner join Orders
on [Order Details].OrderID = Orders.OrderID
inner join Customers
on Orders.CustomerID = Customers.CustomerID
inner join Employees E on Orders.EmployeeID = E.EmployeeID
group by Orders.OrderID, CompanyName, FirstName, LastName
having sum(quantity) > 250
order by 2 desc

-- Dla każdej kategorii produktu (nazwa), podaj łączną liczbę zamówionych przez
-- klientów jednostek towarów z tej kategorii.

select categoryname, sum(quantity) as 'sum'
from Categories
inner join Products P on Categories.CategoryID = P.CategoryID
inner join [Order Details] [O D] on P.ProductID = [O D].ProductID
group by categoryname
order by 2 desc

-- Dla każdej kategorii produktu (nazwa), podaj łączną wartość zamówionych przez
-- klientów jednostek towarów z tek kategorii.

select categoryname, round(sum(quantity * P.UnitPrice * (1 - Discount)), 2) as 'sum'
from Categories
inner join Products P on Categories.CategoryID = P.CategoryID
inner join [Order Details] [O D] on P.ProductID = [O D].ProductID
group by categoryname
order by 2 desc

-- Posortuj wyniki w zapytaniu z poprzedniego punktu wg:
-- a) łącznej wartości zamówień

select categoryname, sum(quantity * P.UnitPrice) as 'sum'
from Categories
inner join Products P on Categories.CategoryID = P.CategoryID
inner join [Order Details] [O D] on P.ProductID = [O D].ProductID
group by categoryname
order by sum(quantity * P.UnitPrice)

-- b) łącznej liczby zamówionych przez klientów jednostek towarów.

select categoryname, sum(quantity * P.UnitPrice) as 'sum'
from Categories
inner join Products P on Categories.CategoryID = P.CategoryID
inner join [Order Details] [O D] on P.ProductID = [O D].ProductID
group by categoryname
order by sum(quantity)

-- Dla każdego zamówienia podaj jego wartość uwzględniając opłatę za przesyłkę

select Orders.orderid, sum(UnitPrice * Quantity * (1 - Discount)) + Orders.Freight as 'sum'
from Orders
inner join [Order Details]
on Orders.OrderID = [Order Details].OrderID
group by Orders.orderid, Freight
order by 2 desc

-- Dla każdego przewoźnika (nazwa) podaj liczbę zamówień które przewieźli w 1997r

select CompanyName, count(orderid) as 'amount'
from Shippers
inner join Orders O on Shippers.ShipperID = O.ShipVia and year(ShippedDate) = 1997
group by CompanyName

select CompanyName, count(*)
from Shippers
inner join Orders O on Shippers.ShipperID = O.ShipVia
where year(ShippedDate) = 1997
group by CompanyName, ShipperID

-- Który z przewoźników był najaktywniejszy (przewiózł największą liczbę
-- zamówień) w 1997r, podaj nazwę tego przewoźnika

select top 1 CompanyName, count(orderid)
from Shippers
inner join Orders O on Shippers.ShipperID = O.ShipVia and year(ShippedDate) = 1997
group by CompanyName
order by count(orderid) desc

-- Dla każdego pracownika (imię i nazwisko) podaj łączną wartość zamówień
-- obsłużonych przez tego pracownika

select firstname, lastname, round(sum(Quantity * UnitPrice * (1 - Discount)), 2) as 'sum'
from Employees E
inner join Orders O
on E.EmployeeID = O.EmployeeID
inner join [Order Details] [O D] on O.OrderID = [O D].OrderID
group by firstname, lastname, E.EmployeeID -- musi byc jeszcze cos unikalnego w grupowaniu!!
order by 3 desc

-- Który z pracowników obsłużył największą liczbę zamówień w 1997r, podaj imię i
-- nazwisko takiego pracownika

select top 1 firstname, lastname, count(*) as 'amount'
from Employees E
inner join Orders O on E.EmployeeID = O.EmployeeID and year(OrderDate) = 1997
group by firstname, lastname, E.EmployeeID
order by count(*) desc

-- Który z pracowników obsłużył najaktywniejszy (obsłużył zamówienia o
-- największej wartości) w 1997r, podaj imię i nazwisko takiego pracownika

select top 1 firstname, lastname, sum(quantity * unitprice)
from Employees E
inner join Orders O on E.EmployeeID = O.EmployeeID and year(OrderDate) = 1997
inner join [Order Details] [O D] on O.OrderID = [O D].OrderID
group by firstname, lastname
order by sum(quantity * unitprice) desc

-- Dla każdego pracownika (imię i nazwisko) podaj łączną wartość zamówień
-- obsłużonych przez tego pracownika
-- – Ogranicz wynik tylko do pracowników
-- a) którzy mają podwładnych

select distinct E.firstname, E.lastname, round(sum(quantity * unitprice * (1 - Discount)), 2) as 'wartosc'
from Employees E
inner join Employees E2
on E.EmployeeID = E2.ReportsTo
inner join Orders O on E.EmployeeID = O.EmployeeID
inner join [Order Details] [O D] on O.OrderID = [O D].OrderID
group by E.firstname, E.lastname, E.EmployeeID, E2.EmployeeID -- wazne zeby grupowac jeszcze po id podwladnego

select FirstName + ' ' + LastName as 'name', round((select sum(Quantity * (1 - Discount) * UnitPrice)
                                    from [Order Details] [O D]
                                    inner join Orders O on O.OrderID = [O D].OrderID
                                    where E.EmployeeID = O.EmployeeID), 2) as 'wartosc'
from Employees E
where E.EmployeeID in (select E2.EmployeeID
                       from Employees E2
                       inner join Employees E3
                       on E2.EmployeeID = E3.ReportsTo)


-- b) którzy nie mają podwładnych

select E.firstname, E.lastname, round(sum(quantity * unitprice * (1 - Discount)), 2)
from Employees E
left outer join Employees E2
on E.EmployeeID = E2.ReportsTo
inner join Orders O on E.EmployeeID = O.EmployeeID
inner join [Order Details] [O D] on O.OrderID = [O D].OrderID
where E2.EmployeeID is null
group by E.firstname, E.lastname, E.EmployeeID

select FirstName + ' ' + LastName as 'name', round((select sum(Quantity * (1 - Discount) * UnitPrice)
                                    from [Order Details] [O D]
                                    inner join Orders O on O.OrderID = [O D].OrderID
                                    where E.EmployeeID = O.EmployeeID), 2) as 'wartosc'
from Employees E
where E.EmployeeID not in (select E2.EmployeeID
                       from Employees E2
                       inner join Employees E3
                       on E2.EmployeeID = E3.ReportsTo)

