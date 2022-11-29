use Northwind

-- Napisz polecenie zwracające nazwy produktów i firmy je
-- dostarczające (baza northwind) – tak aby produkty bez „dostarczycieli” i „dostarczyciele” bez
-- produktów nie pojawiali się w wyniku.

select ProductName, CompanyName
from Products P
inner join Suppliers S
on P.SupplierID = S.SupplierID

-- Napisz polecenie zwracające jako wynik nazwy klientów, którzy
-- złożyli zamówienia po 01 marca 1998 (baza northwind)

select CompanyName, OrderDate
from Customers C
inner join Orders O
on C.CustomerID = O.CustomerID
where O.OrderDate > '1998-03-01'

-- Napisz polecenie zwracające wszystkich klientów z datami
-- zamówień (baza northwind)

select CompanyName, C.CustomerID, OrderDate
from Customers C
left outer join Orders O
on C.CustomerID = O.CustomerID

-- Wybierz nazwy i ceny produktów (baza northwind) o cenie jednostkowej
-- pomiędzy 20.00 a 30.00, dla każdego produktu podaj dane adresowe dostawcy

select ProductName, UnitPrice, suppliers.address
from Products
inner join Suppliers
on Products.SupplierID = suppliers.SupplierID
where UnitPrice between 20 and 30

-- Wybierz nazwy produktów oraz inf. o stanie magazynu dla produktów
-- dostarczanych przez firmę ‘Tokyo Traders’

select ProductName, UnitsInStock, S.companyname
from Products P
inner join Suppliers S
on P.SupplierID = S.SupplierID
where CompanyName = 'Tokyo Traders'

-- Czy są jacyś klienci którzy nie złożyli żadnego zamówienia w 1997 roku, jeśli tak
-- to pokaż ich dane adresowe

select customers.CustomerID, OrderID, customers.address
from Customers
left outer join Orders
on Orders.CustomerID = Customers.CustomerID and year(OrderDate) = 1997
where Orders.OrderID is null

select CustomerID, Address
from Customers C
where C.CustomerID not in (select CustomerID
                           from Orders
                           where year(OrderDate) = 1997)

-- Wybierz nazwy i numery telefonów dostawców, dostarczających produkty,
-- których aktualnie nie ma w magazynie

select companyname, phone, unitsinstock, ProductID, Products.SupplierID
from Suppliers
left outer join Products
on Suppliers.SupplierID = Products.SupplierID
where UnitsInStock = 0 or UnitsInStock is null

use library

-- Napisz polecenie, które wyświetla listę dzieci będących członkami biblioteki (baza
-- library). Interesuje nas imię, nazwisko i data urodzenia dziecka.

select firstname, lastname, birth_date
from member
inner join juvenile
on member.member_no = juvenile.member_no

-- Napisz polecenie, które podaje tytuły aktualnie wypożyczonych książek

select title, due_date
from loan
inner join title
on loan.title_no = title.title_no
where due_date > getdate()

-- Podaj informacje o karach zapłaconych za przetrzymywanie książki o tytule ‘Tao
-- Teh King’. Interesuje nas data oddania książki, ile dni była przetrzymywana i jaką
-- zapłacono karę

select in_date, datediff(day, in_date, due_date) as 'amount of days', fine_paid, title
from loanhist L
inner join title T
on L.title_no = T.title_no
where title = 'Tao Teh King' and fine_assessed > 0

-- Napisz polecenie które podaje listę książek (mumery ISBN) zarezerwowanych
-- przez osobę o nazwisku: Stephen A. Graff

select isbn, firstname, lastname, middleinitial
from reservation
inner join member
on reservation.member_no = member.member_no
where firstname = 'Stephen' and lastname = 'Graff' and middleinitial = 'A'

-- Wybierz nazwy i ceny produktów (baza northwind) o cenie jednostkowej
-- pomiędzy 20.00 a 30.00, dla każdego produktu podaj dane adresowe dostawcy,
-- interesują nas tylko produkty z kategorii ‘Meat/Poultry’

use Northwind

select productname, UnitPrice, address
from Products P
inner join Suppliers S
on P.SupplierID = S.SupplierID
inner join Categories C
on P.CategoryID = C.CategoryID
where CategoryName = 'Meat/Poultry' and UnitPrice between 20 and 30

-- Wybierz nazwy i ceny produktów z kategorii ‘Confections’ dla każdego produktu
-- podaj nazwę dostawcy.

select ProductName, UnitPrice, CompanyName, CategoryName
from Products P
inner join Suppliers S
on P.SupplierID = S.SupplierID
inner join Categories C
on P.CategoryID = C.CategoryID
where CategoryName = 'Confections'

-- Wybierz nazwy i numery telefonów klientów , którym w 1997 roku przesyłki
-- dostarczała firma ‘United Package’

select distinct C.CompanyName, C.Phone
from Customers C
inner join Orders O
on C.CustomerID = O.CustomerID
inner join Shippers S
on O.ShipVia = S.ShipperID
where S.CompanyName = 'United Package' and YEAR(ShippedDate) = 1997

-- Wybierz nazwy i numery telefonów klientów, którzy kupowali produkty z kategorii
-- ‘Confection

select distinct CompanyName, Phone, CategoryName
from Customers C
inner join Orders O on C.CustomerID = O.CustomerID
inner join [Order Details] OD on O.OrderID = OD.OrderID
inner join Products P on OD.ProductID = P.ProductID
inner join Categories C2 on P.CategoryID = C2.CategoryID
where C2.CategoryName = 'Confections'

-- Napisz polecenie, które wyświetla listę dzieci będących członkami biblioteki (baza
-- library). Interesuje nas imię, nazwisko, data urodzenia dziecka i adres
-- zamieszkania dziecka.

use library

select firstname, lastname, birth_date, street, city
from member m
inner join juvenile j on m.member_no = j.member_no
inner join adult a on a.member_no = j.adult_member_no

-- Napisz polecenie, które wyświetla listę dzieci będących członkami biblioteki (baza
-- library). Interesuje nas imię, nazwisko, data urodzenia dziecka, adres
-- zamieszkania dziecka oraz imię i nazwisko rodzica.

select J.firstname, J.lastname, ju.birth_date, ad.street, ad.city, A.firstname, A.lastname
from juvenile ju
inner join member J on J.member_no = ju.member_no
inner join adult ad on ad.member_no = ju.adult_member_no
inner join member A on ad.member_no = A.member_no

-- aliasy muszą różnić się, duże i małe litery nie są rozróżnialne!!!

-- Napisz polecenie, które wyświetla pracowników oraz ich podwładnych (baza
-- northwind

use Northwind

select szef.employeeid as 'szef', podwladny.employeeid as 'podwladny'
from Employees szef
inner join Employees podwladny
on szef.EmployeeID = podwladny.ReportsTo

-- Napisz polecenie, które wyświetla pracowników, którzy nie mają podwładnych
-- (baza northwind)

SELECT szef.EmployeeID, podwładny.EmployeeID, podwładny.ReportsTo
FROM Employees as szef
LEFT OUTER JOIN Employees AS podwładny
ON szef.EmployeeID = podwładny.ReportsTo
WHERE podwładny.EmployeeID IS NULL

SELECT EmployeeID
FROM Employees E
WHERE NOT EXISTS(SELECT E2.EmployeeID FROM Employees E2 WHERE E2.Reportsto = E.EmployeeID)

-- Napisz polecenie, które wyświetla adresy członków biblioteki, którzy mają dzieci
-- urodzone przed 1 stycznia 1996

use library

select street, city
from adult A
where exists(select juvenile.member_no from juvenile
            where year(juvenile.birth_date) < 1996 and juvenile.adult_member_no = A.member_no)

SELECT DISTINCT A.Street, A.city, A.zip, A.member_no
FROM adult A
INNER JOIN juvenile J on J.adult_member_no = A.member_no AND YEAR(J.birth_date) < 1996

-- Napisz polecenie, które wyświetla adresy członków biblioteki, którzy mają dzieci
-- urodzone przed 1 stycznia 1996. Interesują nas tylko adresy takich członków
-- biblioteki, którzy aktualnie nie przetrzymują książek.

SELECT DISTINCT A.Street, A.city, A.member_no
FROM adult A
INNER JOIN juvenile J on J.adult_member_no = A.member_no AND YEAR(J.birth_date) < 1996
LEFT JOIN loan L on A.member_no = L.member_no
WHERE L.out_date IS NULL

-- Napisz polecenie które zwraca imię i nazwisko (jako pojedynczą kolumnę –
-- name), oraz informacje o adresie: ulica, miasto, stan kod (jako pojedynczą
-- kolumnę – address) dla wszystkich dorosłych członków biblioteki

select firstname + ' ' + lastname, street + ' ' + city + ' ' + state
from member
inner join adult a on member.member_no = a.member_no

-- Napisz polecenie, które zwraca: isbn, copy_no, on_loan, title, translation, cover,
-- dla książek o isbn 1, 500 i 1000. Wynik posortuj wg ISBN

select item.isbn, copy_no, on_loan, title, translation, cover
from item
inner join copy c on item.isbn = c.isbn
inner join title t on c.title_no = t.title_no
where item.isbn in (1, 500, 1000)
order by item.isbn

-- Napisz polecenie które zwraca o użytkownikach biblioteki o nr 250, 342, i 1675
-- (dla każdego użytkownika: nr, imię i nazwisko członka biblioteki), oraz informację
-- o zarezerwowanych książkach (isbn, data)

select member.member_no, firstname, lastname, isbn, log_date
from member
inner join reservation
on member.member_no = reservation.member_no
where member.member_no in (250, 342, 1675)
