use northwind

-- Wybierz nazwy i numery telefonów klientów , którym w 1997 roku przesyłki 
-- dostarczała firma United Package. (bez podzapytań i z podzapytaniem 1) z użyciem in 2) z użyciem exists)

select distinct C.CompanyName, C.Phone
from Customers C
inner join Orders O on c.CustomerID = O.CustomerID
inner join Shippers S on O.ShipVia = S.ShipperID
where S.CompanyName = 'United Package' and year(O.ShippedDate) = 1997

select CompanyName, Phone
from Customers C
where C.CustomerID in (select CustomerID
                       from Orders O
                       inner join Shippers S on O.ShipVia = S.ShipperID
                       where S.CompanyName = 'United Package' and year(O.ShippedDate) = 1997)

select CompanyName, Phone
from Customers C
where exists(select *
    from Orders O
    inner join Shippers S on S.ShipperID = O.ShipVia
    where O.CustomerID = C.CustomerID and S.CompanyName = 'United Package' and year(O.ShippedDate) = 1997)

-- Wybierz nazwy i numery telefonów klientów, którzy kupowali produkty z kategorii
-- Confections. (bez podzapytań i z podzapytaniem) (bez podzapytań i z podzapytaniem 1) z użyciem in 2) z użyciem exists)

select distinct CompanyName, Phone
from Customers C
inner join Orders O on C.CustomerID = O.CustomerID
inner join [Order Details] [O D] on O.OrderID = [O D].OrderID
inner join Products P on P.ProductID = [O D].ProductID
inner join Categories C2 on C2.CategoryID = P.CategoryID
where C2.CategoryName = 'Confections'

select CompanyName, Phone
from Customers C
where C.CustomerID in (select CustomerID
                       from Orders O
                       inner join [Order Details] [O D] on O.OrderID = [O D].OrderID
                       inner join Products P on P.ProductID = [O D].ProductID
                       inner join Categories C2 on C2.CategoryID = P.CategoryID
                       where C2.CategoryName = 'Confections')

select CompanyName, Phone
from Customers C
where exists(select *
    from Orders O
    inner join [Order Details] [O D] on O.OrderID = [O D].OrderID
    inner join Products P on P.ProductID = [O D].ProductID
    inner join Categories C2 on C2.CategoryID = P.CategoryID
    where C2.CategoryName = 'Confections' and O.CustomerID = C.CustomerID)


-- Wybierz nazwy i numery telefonów klientów, którzy nie kupowali produktów z
-- kategorii Confections.

select CompanyName, Phone
from Customers C
where C.CustomerID not in (select CustomerID
                       from Orders O
                       inner join [Order Details] [O D] on O.OrderID = [O D].OrderID
                       inner join Products P on P.ProductID = [O D].ProductID
                       inner join Categories C2 on C2.CategoryID = P.CategoryID
                       where C2.CategoryName = 'Confections')

select CompanyName, Phone
from Customers C
where not exists(select *
    from Orders O
    inner join [Order Details] [O D] on O.OrderID = [O D].OrderID
    inner join Products P on P.ProductID = [O D].ProductID
    inner join Categories C2 on C2.CategoryID = P.CategoryID
    where C2.CategoryName = 'Confections' and O.CustomerID = C.CustomerID)

-- Dla każdego produktu podaj maksymalną liczbę zamówionych jednostek

select P.ProductName, max([O D].Quantity) as 'max'
from Products P
inner join [Order Details] [O D] on P.ProductID = [O D].ProductID
group by P.ProductName
order by P.ProductName

select P.ProductName, (select max(quantity)
                     from [Order Details] [OD]
                     where P.ProductID = [OD].ProductID) as 'max'
from Products P
order by P.ProductName

-- Podaj wszystkie produkty których cena jest mniejsza niż średnia cena produktu

select P.ProductName, P.UnitPrice
from Products P
where P.UnitPrice < (select avg(UnitPrice)
                       from Products P2)

-- Podaj wszystkie produkty których cena jest mniejsza niż średnia cena produktu
-- danej kategorii

select P.ProductName, (select avg(UnitPrice)
                       from Products P2
                       where P2.CategoryID = P.CategoryID) as 'avg'
from Products P
where P.UnitPrice < (select avg(UnitPrice)
                       from Products P2
                       where P2.CategoryID = P.CategoryID)

-- Dla każdego produktu podaj jego nazwę, cenę, średnią cenę wszystkich
-- produktów oraz różnicę między ceną produktu a średnią ceną wszystkich
-- produktów

select ProductName, UnitPrice, (select avg(UnitPrice)
                                from Products) as 'avg',
    abs(UnitPrice - (select avg(UnitPrice)
                                from Products)) as 'diff'
from Products P

-- Dla każdego produktu podaj jego nazwę kategorii, nazwę produktu, cenę, średnią
-- cenę wszystkich produktów danej kategorii oraz różnicę między ceną produktu a
-- średnią ceną wszystkich produktów danej kategorii

select ProductID, ProductName, C.CategoryName, UnitPrice,
       (select avg(UnitPrice)
        from Products P2
        where P2.CategoryID = P.CategoryID) as 'avg',
        abs(UnitPrice - (select avg(UnitPrice)
        from Products P2
        where P2.CategoryID = P.CategoryID)) as 'dif'
from Products P
inner join Categories C on C.CategoryID = P.CategoryID

-- Podaj łączną wartość zamówienia o numerze 1025 (uwzględnij cenę za przesyłkę)

select OrderID, round(O.Freight + (select sum(UnitPrice * Quantity * (1 - Discount))
                 from [Order Details] [OD]
                 where [OD].OrderID = O.OrderID), 2)
from Orders O
where O.OrderID = 10250

-- Podaj łączną wartość zamówień każdego zamówienia (uwzględnij cenę za
-- przesyłkę)

select OrderID, round(O.Freight + (select sum(UnitPrice * Quantity * (1 - Discount))
                 from [Order Details] [OD]
                 where [OD].OrderID = O.OrderID), 2)
from Orders O

-- Czy są jacyś klienci którzy nie złożyli żadnego zamówienia w 1997 roku, jeśli tak
-- to pokaż ich dane adresowe

select CompanyName, Address
from Customers C
where C.CustomerID not in (select CustomerID
                           from Orders
                           where year(OrderDate) = 1997)

-- Podaj produkty kupowane przez więcej niż jednego klienta
-- ??????????????????????

select productname, count(id) as 'number of clients'
from (
select distinct ProductName as 'productname', O.CustomerID as 'id'
from Products P
inner join [Order Details] [O D] on P.ProductID = [O D].ProductID
inner join Orders O on O.OrderID = [O D].OrderID
) as main
group by productname
having count(id) > 1

-- Dla każdego pracownika (imię i nazwisko) podaj łączną wartość zamówień
-- obsłużonych przez tego pracownika (przy obliczaniu wartości zamówień
-- uwzględnij cenę za przesyłkę)

select FirstName + ' ' + LastName as 'name', round((select sum(UnitPrice * Quantity * (1 - Discount))
                                              from [Order Details] OD
                                              inner join Orders O on O.OrderID = OD.OrderID
                                              where O.EmployeeID = E.EmployeeID) + (
                                                  select sum(Freight)
                                                  from Orders O2
                                                  where O2.EmployeeID = E.EmployeeID), 2) as 'value'
from Employees E

-- Który z pracowników obsłużył najaktywniejszy (obsłużył zamówienia o
-- największej wartości) w 1997r, podaj imię i nazwisko takiego pracownika

select top 1 FirstName + ' ' + LastName as 'name', round((select sum(UnitPrice * Quantity * (1 - Discount))
                                                    from [Order Details] OD
                                                    inner join Orders O on O.OrderID = OD.OrderID
                                                    where O.EmployeeID = E.EmployeeID and year(O.ShippedDate) = 1997), 2) as 'value'
from Employees E
order by 2 desc

-- Ogranicz wynik z pkt 1 tylko do pracowników
-- a) którzy mają podwładnych
-- b) którzy nie mają podwładnych

select FirstName + ' ' + LastName as 'name', round((select sum(UnitPrice * Quantity * (1 - Discount))
                                              from [Order Details] OD
                                              inner join Orders O on O.OrderID = OD.OrderID
                                              where O.EmployeeID = E.EmployeeID) + (
                                                  select sum(Freight)
                                                  from Orders O2
                                                  where O2.EmployeeID = E.EmployeeID), 2) as 'value'
from Employees E
where E.EmployeeID in (select distinct szef.EmployeeID
                       from Employees szef
                       inner join Employees podwladny
                       on szef.EmployeeID = podwladny.ReportsTo)

select EmployeeID, FirstName + ' ' + LastName as 'name', round((select sum(UnitPrice * Quantity * (1 - Discount))
                                              from [Order Details] OD
                                              inner join Orders O on O.OrderID = OD.OrderID
                                              where O.EmployeeID = E.EmployeeID) + (
                                                  select sum(Freight)
                                                  from Orders O2
                                                  where O2.EmployeeID = E.EmployeeID), 2) as 'value'
from Employees E
where E.EmployeeID in (select szef.EmployeeID
                       from Employees szef
                       left join Employees podwladny
                       on szef.EmployeeID = podwladny.ReportsTo
                       where podwladny.EmployeeID is null)

-- Zmodyfikuj rozwiązania z pkt 3 tak aby dla pracowników pokazać jeszcze datę
-- ostatnio obsłużonego zamówienia

select FirstName + ' ' + LastName as 'name', round((select sum(UnitPrice * Quantity * (1 - Discount))
                                              from [Order Details] OD
                                              inner join Orders O on O.OrderID = OD.OrderID
                                              where O.EmployeeID = E.EmployeeID) + (
                                                  select sum(Freight)
                                                  from Orders O2
                                                  where O2.EmployeeID = E.EmployeeID), 2) as 'value',
    (select top 1 O3.ShippedDate
     from Orders O3
     where O3.EmployeeID = E.EmployeeID
     order by 1 desc)
from Employees E
where E.EmployeeID in (select distinct szef.EmployeeID
                       from Employees szef
                       inner join Employees podwladny
                       on szef.EmployeeID = podwladny.ReportsTo)
