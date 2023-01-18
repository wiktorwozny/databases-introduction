use library

--left join dla rodzica bo nie kazdy rodzic ma dziecko

-- a)

select firstname + ' ' + lastname as 'name', street + ' ' + city + ' ' + state, 'rodzic', count(j.adult_member_no) as 'liczba dzieci'
from member m
inner join adult a on m.member_no = a.member_no
left join juvenile j on a.member_no = j.adult_member_no
left join loanhist l on m.member_no = l.member_no
left join loan l2 on m.member_no = l2.member_no
where l.member_no is null and l2.member_no is null
group by firstname + ' ' + lastname, street + ' ' + city + ' ' + state
union
select firstname + ' ' + lastname as 'name', street + ' ' + city + ' ' + state, 'dziecko', null as 'liczba dzieci'
from member m
inner join juvenile j on m.member_no = j.member_no
inner join adult a2 on a2.member_no = j.adult_member_no
left join loanhist l on m.member_no = l.member_no
left join loan l2 on m.member_no = l2.member_no
where l.member_no is null and l2.member_no is null

-- b)

select firstname + ' ' + lastname as 'name', street + ' ' + city + ' ' + state, 'rodzic', count(j.adult_member_no) as 'liczba dzieci'
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
select firstname + ' ' + lastname as 'name', street + ' ' + city + ' ' + state, 'dziecko', null as 'liczba dzieci'
from member m
inner join juvenile j on m.member_no = j.member_no
inner join adult a2 on a2.member_no = j.adult_member_no
where m.member_no not in (select member_no
                          from loanhist
                          union
                          select member_no
                          from loan)

-- c)

select firstname + ' ' + lastname as 'name', street + ' ' + city + ' ' + state, 'rodzic', count(j.adult_member_no) as 'liczba dzieci'
from member m
inner join adult a on m.member_no = a.member_no
left join juvenile j on a.member_no = j.adult_member_no
where not exists (select member_no
                  from loanhist
                  where m.member_no = loanhist.member_no
                  union
                  select member_no
                  from loan
                  where m.member_no = loan.member_no
)
group by firstname + ' ' + lastname, street + ' ' + city + ' ' + state
union
select firstname + ' ' + lastname as 'name', street + ' ' + city + ' ' + state, 'dziecko', null as 'liczba dzieci'
from member m
inner join juvenile j on m.member_no = j.member_no
inner join adult a2 on a2.member_no = j.adult_member_no
where not exists (select member_no
                  from loanhist
                  where m.member_no = loanhist.member_no
                  union
                  select member_no
                  from loan
                  where m.member_no = loan.member_no
)

use Northwind

select OrderID, CompanyName, (select avg(Freight)
                              from Orders O2
                              where year(O2.OrderDate) = year(O.OrderDate)) as 'avg'
from Orders O
inner join Customers C on O.CustomerID = C.CustomerID
where Freight > (select avg(Freight)
                 from Orders O2
                 where year(O2.OrderDate) = year(O.OrderDate))

use library

select firstname + ' ' + lastname as 'name', (select count(*)
                                              from loanhist l
                                              where l.member_no = m.member_no and year(out_date) = 2001 and month(out_date) = 12) +
                                             (select count(*)
                                              from loanhist l
                                              inner join juvenile j on l.member_no = j.member_no
                                              where j.adult_member_no = m.member_no and year(out_date) = 2001 and month(out_date) = 12) as 'suma'
from member m
inner join adult a on m.member_no = a.member_no
where (a.state = 'AZ' and (select count(*) from juvenile j where j.adult_member_no = a.member_no) > 2)
or (a.state = 'CA' and (select count(*) from juvenile j where j.adult_member_no = a.member_no) > 3)

