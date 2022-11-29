-- 1. Wypisz wszystkich członków biblioteki z adresami i info czy jest dzieckiem czy nie i
-- ilość wypożyczeń w poszczególnych latach i miesiącach.
-- left join bo nie kazdy czlonek cos wypozyczyl a mamy wyswietlic wszystkich

use library

select m.member_no, firstname + ' ' + lastname as 'name', street + ' ' + city + ' ' + state as 'address',
       'NIE' as 'czy bobo', month(out_date) as 'month', year(out_date) as 'year', count(isbn) as 'amount'
from member m
inner join adult a on m.member_no = a.member_no
left join loanhist l on m.member_no = l.member_no
group by m.member_no, firstname + ' ' + lastname, street + ' ' + city + ' ' + state, month(out_date), year(out_date)
union
select m.member_no, firstname + ' ' + lastname as 'name', street + ' ' + city + ' ' + state as 'address',
       'TAK' as 'czy bobo', month(out_date) as 'month', year(out_date) as 'year', count(isbn) as 'amount'
from member m
inner join juvenile j on m.member_no = j.member_no
inner join adult a on j.adult_member_no = a.member_no
left join loanhist l on m.member_no = l.member_no
group by m.member_no, firstname + ' ' + lastname, street + ' ' + city + ' ' + state, month(out_date), year(out_date)
order by 1

-- 2. Zamówienia z Freight większym niż AVG danego roku.

use Northwind

select OrderID, (select avg(Freight)
                 from Orders O2
                 where year(O2.OrderDate) = year(O.OrderDate)) as 'avg'
from Orders O
where Freight > (select avg(Freight)
                 from Orders O2
                 where year(O2.OrderDate) = year(O.OrderDate))

-- 3. Klienci, którzy nie zamówili nigdy nic z kategorii 'Seafood'.

select CompanyName
from Customers C
where C.CustomerID not in (select C2.CustomerID
                           from Customers C2
                           inner join Orders O on C2.CustomerID = O.CustomerID
                           inner join [Order Details] [O D] on O.OrderID = [O D].OrderID
                           inner join Products P on P.ProductID = [O D].ProductID
                           inner join Categories C3 on C3.CategoryID = P.CategoryID
                           where C3.CategoryName = 'Seafood')

-- 4. Dla każdego klienta najczęściej zamawianą kategorię w dwóch wersjach.

select CustomerID, (select top 1 CategoryName
                    from Categories C2
                    inner join Products P on C2.CategoryID = P.CategoryID
                    inner join [Order Details] [O D] on P.ProductID = [O D].ProductID
                    inner join Orders O on O.OrderID = [O D].OrderID
                    where O.CustomerID = C.CustomerID
                    group by CategoryName
                    order by count(*) desc) as 'most common'
from Customers C

-- Zad.1. Wyświetl produkt, który przyniósł najmniejszy, ale niezerowy, przychód w 1996 roku

select top 1 ProductName, round(sum(Quantity * [O D].UnitPrice * (1 - Discount)), 2) as 'przychod'
from Products P
inner join [Order Details] [O D] on P.ProductID = [O D].ProductID
inner join Orders O on O.OrderID = [O D].OrderID
where year(O.OrderDate) = 1996
group by ProductName
having sum(Quantity * [O D].UnitPrice * (1 - Discount)) > 0
order by sum(Quantity * [O D].UnitPrice * (1 - Discount))

-- Zad.2. Wyświetl wszystkich członków biblioteki (imię i nazwisko, adres)
-- rozróżniając dorosłych i dzieci (dla dorosłych podaj liczbę dzieci),
-- którzy nigdy nie wypożyczyli książki
-- left join przy doroslych, bo nie kazdy dorosly ma przeciez dzieciora

use library

select firstname + ' ' + lastname as 'name', street + ' ' + city + ' ' + state, 'stary', count(j.adult_member_no) as 'kidos'
from member m
inner join adult a on m.member_no = a.member_no
left join juvenile j on a.member_no = j.adult_member_no
where m.member_no not in (select member_no
                          from loanhist
                          union
                          select member_no
                          from loan)
group by firstname + ' ' + lastname, street + ' ' + city + ' ' + state
union
select firstname + ' ' + lastname as 'name', street + ' ' + city + ' ' + state, 'mlody', null as 'kidos'
from member m
inner join juvenile j on m.member_no = j.member_no
inner join adult a2 on a2.member_no = j.adult_member_no
where m.member_no not in (select member_no
                          from loanhist
                          union
                          select member_no
                          from loan)


-- Zad.3. Wyświetl podsumowanie zamówień (całkowita cena + fracht) obsłużonych
-- przez pracowników w lutym 1997 roku, uwzględnij wszystkich, nawet jeśli suma
-- wyniosła 0.

use Northwind

select FirstName + ' ' + LastName as 'name', round((select sum(Freight) + sum(Quantity * UnitPrice * (1 - Discount))
                                              from [Order Details] [O D]
                                              inner join Orders O on O.OrderID = [O D].OrderID
                                              where month(OrderDate) = 2 and year(OrderDate) = 1997 and O.EmployeeID = E.EmployeeID) +
                                             (select sum(Freight)
                                              from Orders O
                                              where month(OrderDate) = 2 and year(OrderDate) = 1997 and O.EmployeeID = E.EmployeeID), 2) as 'overall'
from Employees E
order by 2 desc

-- 4. Dla każdego czytelnika imię nazwisko, suma książek wypożyczony przez tą osobę i
-- jej dzieci, który żyje w Arizona ma mieć więcej niż 2 dzieci lub kto żyje w Kalifornii
-- ma mieć więcej niż 3 dzieci

use library

select firstname + ' ' + lastname as 'name', (select count(*)
                                              from loanhist l
                                              where l.member_no = m.member_no) as 'parent',
    (select count(*)
     from loanhist l
     inner join juvenile j on l.member_no = j.member_no
     where j.adult_member_no = m.member_no) as 'kids'
from member m
inner join adult a on m.member_no = a.member_no
where (a.state = 'AZ' and (select count(*) from juvenile j where j.adult_member_no = a.member_no) > 2)
or (a.state = 'CA' and (select count(*) from juvenile j where j.adult_member_no = a.member_no) > 3)

-- 1. Jaki był najpopularniejszy autor wśród dzieci w Arizonie w 2001

select author, count(*) as 'amount'
from title t
inner join loanhist l on t.title_no = l.title_no
inner join juvenile j on l.member_no = j.member_no
inner join adult a on j.adult_member_no = a.member_no
where year(l.out_date) = 2001 and state = 'AZ'
group by author
order by count(*) desc

-- 2. Dla każdego dziecka wybierz jego imię nazwisko, adres, imię i nazwisko rodzica i
-- ilość książek, które oboje przeczytali w 2001

select m.firstname + ' ' + m.lastname as 'kid name', street + ' ' + city as 'address', m2.firstname + ' ' + m2.lastname as 'parent name',
       (select count(*)
        from loanhist l
        where (l.member_no = m.member_no and year(in_date) = 2001) or (l.member_no = m2.member_no and year(in_date) = 2001)) as 'books'
from member m
inner join juvenile j on m.member_no = j.member_no
inner join adult a on a.member_no = j.adult_member_no
inner join member m2 on a.member_no = m2.member_no
order by 4 desc

-- 3. Kategorie które w roku 1997 grudzień były obsłużone wyłącznie przez ‘United
-- Package’

use Northwind

select categoryname, count(companyname) as 'amount'
from (
select distinct CategoryName as 'categoryname', S.CompanyName as 'companyname'
from Categories C
inner join Products P on C.CategoryID = P.CategoryID
inner join [Order Details] [O D] on P.ProductID = [O D].ProductID
inner join Orders O on O.OrderID = [O D].OrderID
inner join Shippers S on S.ShipperID = O.ShipVia
where year(ShippedDate) = 1997 and month(ShippedDate) = 12
    ) as main
group by categoryname
having count(companyname) = 1


-- 4. Wybierz klientów, którzy kupili przedmioty wyłącznie z jednej kategorii w marcu
-- 1997 i wypisz nazwę tej kategorii

select id, count(categoryname) as 'amount', (select top 1 CategoryName
                                             from Categories
                                             inner join Products P2 on Categories.CategoryID = P2.CategoryID
                                             inner join [Order Details] [O D2] on P2.ProductID = [O D2].ProductID
                                             inner join Orders O2 on O2.OrderID = [O D2].OrderID
                                             where O2.CustomerID = id and year(OrderDate) = 1997 and month(OrderDate) = 3)
from (
    select distinct C.CustomerID as 'id', CategoryName as 'categoryname'
from Customers C
inner join Orders O on C.CustomerID = O.CustomerID
inner join [Order Details] [O D] on O.OrderID = [O D].OrderID
inner join Products P on P.ProductID = [O D].ProductID
inner join Categories C2 on C2.CategoryID = P.CategoryID
where year(OrderDate) = 1997 and month(OrderDate) = 3
     ) as main
group by id
having count(categoryname) = 1

select CustomerID, (select count(distinct C2.CategoryID)
                    from Categories C2
                    inner join Products P on C2.CategoryID = P.CategoryID
                    inner join [Order Details] [O D] on P.ProductID = [O D].ProductID
                    inner join Orders O on O.OrderID = [O D].OrderID
                    where O.CustomerID = C.CustomerID and year(OrderDate) = 1997 and month(OrderDate) = 3),
                    (select top 1 C2.CategoryName
                    from Categories C2
                    inner join Products P on C2.CategoryID = P.CategoryID
                    inner join [Order Details] [O D] on P.ProductID = [O D].ProductID
                    inner join Orders O on O.OrderID = [O D].OrderID
                    where O.CustomerID = C.CustomerID and year(OrderDate) = 1997 and month(OrderDate) = 3)
from Customers C
where (select count(distinct C2.CategoryID)
                    from Categories C2
                    inner join Products P on C2.CategoryID = P.CategoryID
                    inner join [Order Details] [O D] on P.ProductID = [O D].ProductID
                    inner join Orders O on O.OrderID = [O D].OrderID
                    where O.CustomerID = C.CustomerID and year(OrderDate) = 1997 and month(OrderDate) = 3) = 1

-- 1. Wybierz dzieci wraz z adresem, które nie wypożyczyły książek w lipcu 2001
-- autorstwa ‘Jane Austin

use library

select distinct firstname + ' ' + lastname as 'name', street + ' ' + city + ' ' + state as 'address'
from member m
inner join juvenile j on m.member_no = j.member_no
inner join adult a on a.member_no = j.adult_member_no
where m.member_no not in (select l.member_no
                          from loanhist l
                          inner join title t on l.title_no = t.title_no
                          where t.author = 'Jane Austin' and year(out_date) = 2001 and month(out_date) = 7)

-- 2. Wybierz kategorię, która w danym roku 1997 najwięcej zarobiła, podział na miesiące

use Northwind

select CategoryName, month(OrderDate) as 'month', round(sum(Quantity * [O D].UnitPrice * (1 - Discount)), 2) as 'earned'
from Categories C
inner join Products P on C.CategoryID = P.CategoryID
inner join [Order Details] [O D] on P.ProductID = [O D].ProductID
inner join Orders O on O.OrderID = [O D].OrderID
where year(OrderDate) = 1997 and CategoryName = (select top 1 CategoryName
                                                from Categories C
                                                inner join Products P on C.CategoryID = P.CategoryID
                                                inner join [Order Details] [O D] on P.ProductID = [O D].ProductID
                                                inner join Orders O on O.OrderID = [O D].OrderID
                                                where year(OrderDate) = 1997
                                                group by CategoryName
                                                order by sum(Quantity * [O D].UnitPrice * (1 - Discount)) desc)
group by CategoryName, month(OrderDate)

-- 3. Dane pracownika i najczęstszy dostawca pracowników bez podwładnych

select E.EmployeeID, E.FirstName, E.LastName, (select top 1 CompanyName
                             from Shippers S
                             inner join Orders O on S.ShipperID = O.ShipVia
                             where O.EmployeeID = E.EmployeeID
                             group by CompanyName
                             order by count(*) desc)
from Employees E
left join Employees podwladny
on E.EmployeeID = podwladny.reportsTo
where podwladny.ReportsTo is null

-- 4. Wybierz tytuły książek, gdzie ilość wypożyczeń książki jest większa od średniej ilości
-- wypożyczeń książek tego samego autora.

-- wszystkie ksiazki sa wypozyczone 1040 razy wiec XD

use library

select title, (select avg(cnt)
               from (
                   select count(title) as 'cnt'
                   from title t1
                   inner join loanhist l on t1.title_no = l.title_no
                   where t1.author = t.author
                   group by t1.title
                    ) main )
from title t
inner join loanhist l2 on t.title_no = l2.title_no
where (select count(*)
       from loanhist
       where loanhist.title_no = t.title_no) > (select avg(cnt)
                                                from (
                                                    select count(title) as 'cnt'
                                                    from title t1
                                                    inner join loanhist l on t1.title_no = l.title_no
                                                    where t1.author = t.author
                                                    group by t1.title
                                                     ) main )

-- Dla każdego pracownika znaleźć najczęstszego dostawcę produktów z obsługiwanych
-- przez nich zamówień (z podwladnymi)

use Northwind

select FirstName + ' ' + LastName as 'name', (select top 1 CompanyName
                                              from Shippers S
                                              inner join Orders O on S.ShipperID = O.ShipVia
                                              where O.EmployeeID = E.EmployeeID
                                              group by CompanyName
                                              order by count(*) desc)
from Employees E
where E.EmployeeID in (select E2.EmployeeID
                       from Employees E2
                       inner join Employees E3
                       on E2.EmployeeID = E3.ReportsTo)


-- Dla każdego klienta najczęściej zamawianą kategorię

select C.CustomerID, (select top 1 CategoryName
                     from Categories C2
                     inner join Products P on C2.CategoryID = P.CategoryID
                     inner join [Order Details] [O D] on P.ProductID = [O D].ProductID
                     inner join Orders O on O.OrderID = [O D].OrderID
                     where O.CustomerID = C.CustomerID
                     group by CategoryName
                     order by sum(Quantity) desc)
from Customers C
order by 1

-- 1.Podaj listę dzieci będących członkami biblioteki, które w dniu '2001-12-14'
-- zwróciły do biblioteki książkę o tytule 'Walking'

use library

select m.member_no, firstname + ' ' + lastname as 'name'
from member m
inner join juvenile j on m.member_no = j.member_no
inner join loanhist l on m.member_no = l.member_no
inner join title t on l.title_no = t.title_no
where year(in_date) = 2001 and month(in_date) = 12 and day(in_date) = 14 and title = 'Walking'

-- 2.Wyświetl klientów wraz z informacjami jaką kategorię produktow najczęściej zamawiali w 1997 roku

use Northwind

select CustomerID, (select top 1 CategoryName
                    from Categories C1
                    inner join Products P on C1.CategoryID = P.CategoryID
                    inner join [Order Details] [O D] on P.ProductID = [O D].ProductID
                    inner join Orders O on O.OrderID = [O D].OrderID
                    where O.CustomerID = C.CustomerID and year(O.OrderDate) = 1997
                    group by CategoryName
                    order by count(*) desc) as 'category'
from Customers C

-- 3.Dla każdego dziecka będącego członkiem biblioteki jego imię i nazwisko, adres,
-- imię i nazwisko opiekuna oraz informację ile książek oddali dziecko i rodzic w grudniu 2001

use library

select m.member_no, firstname + ' ' + lastname as 'name', street + ' ' + city + ' ' + state as 'address',
       (select count(isbn)
        from loanhist l
        where l.member_no = j.member_no and year(in_date) = 2001 and month(in_date) = 12) +
       (select count(isbn)
        from loanhist l
        where l.member_no = a.member_no and year(in_date) = 2001 and month(in_date) = 12) as 'amount'
from member m
inner join juvenile j on m.member_no = j.member_no
inner join adult a on a.member_no = j.adult_member_no

-- Ile zarobiły poszczególne kategorie w roku 1997, podział na miesiące

use Northwind

select CategoryName, month(OrderDate) as 'month', round(sum([O D].UnitPrice * Quantity * (1 - Discount)), 2) as 'amount'
from Categories C
inner join Products P on C.CategoryID = P.CategoryID
inner join [Order Details] [O D] on P.ProductID = [O D].ProductID
inner join Orders O on O.OrderID = [O D].OrderID
where year(OrderDate) = 1997
group by CategoryName, month(OrderDate)
order by 1
