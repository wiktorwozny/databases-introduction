use Northwind
select * from Customers

select companyname, Country
from Suppliers
where Country in ('Japan', 'Italy')

select orderid, OrderDate, CustomerID, ShippedDate
from Orders
where ((ShippedDate is NULL) or (ShippedDate > getdate())) and ShipCountry = 'Argentina'

select CompanyName, Country
from Customers
order by Country, CompanyName

select CategoryID, ProductName, UnitPrice
from Products
order by CategoryID, UnitPrice desc

select CompanyName, Country
from Customers
where Country in ('Italy', 'Japan')
order by Country

select CompanyName, 'telefon: ' + phone + ' fax: ' + fax as TelefonIFax
from Suppliers
where phone is not null and fax is not null

-- żeby nie było nulla
select CompanyName, concat('tel: ', phone, ' fax: ', fax)
from Suppliers

-- ISNULL WAZNY :DD
select CompanyName, 'nr tel: ' + phone + ' fax: ' + isnull(fax, '')
from Suppliers

select top 5 OrderID, ProductID, Quantity
from [Order Details]
order by Quantity desc

select top 5 with ties OrderID, ProductID, Quantity
from [Order Details]
order by Quantity desc

select count(*)
from Products
where UnitPrice < 10 or UnitPrice > 20

select max(unitprice)
from Products
where UnitPrice < 20

select max(UnitPrice), min(UnitPrice), avg(UnitPrice)
from Products
where QuantityPerUnit like '%bottle%'

select *
from Products
where UnitPrice > (select avg(UnitPrice) from Products)

select round(sum(Quantity * UnitPrice * (1 - Discount)), 2) as RoundedAveragePrice
from [Order Details]
where OrderID = 10250


