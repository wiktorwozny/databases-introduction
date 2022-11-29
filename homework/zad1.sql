use library

-- cwiczenie 1
-- Napisz polecenie select, za pomocą którego uzyskasz tytuł
-- i numer książki

select title, title_no
from title

-- Napisz polecenie, które wybiera tytuł o numerze 10

select title
from title
where title_no = 10

-- Napisz polecenie, które wybiera numer czytelnika i karę
-- dla tych czytelników, którzy mają kary między $8 a $9

select member_no, fine_assessed
from loanhist
where fine_assessed between 8 and 9

-- Napisz polecenie select, za pomocą którego uzyskasz
-- numer książki i autora dla wszystkich książek, których
-- autorem jest Charles Dickens lub Jane Austen

select title_no, author
from title
where author in ('Charles Dickens', 'Jane Austen')

-- Napisz polecenie, które wybiera numer tytułu i tytuł dla
-- wszystkich rekordów zawierających string „adventures”
-- gdzieś w tytule.

select title_no, title
from title
where title like '%adventures%'

-- Napisz polecenie, które wybiera numer czytelnika, karę
-- oraz zapłaconą karę dla wszystkich, którzy jeszcze nie
-- zapłacili.

select distinct member_no, fine_assessed, fine_paid
from loanhist
where fine_assessed - isnull(fine_paid, 0) - isnull(fine_waived, 0) > 0
order by member_no

-- Napisz polecenie, które wybiera wszystkie unikalne pary
-- miast i stanów z tablicy adult.

select distinct city, state
from adult
order by city, state

-- cwiczenie 2

-- Napisz polecenie, które wybiera wszystkie tytuły z tablicy
-- title i wyświetla je w porządku alfabetycznym.

select title
from title
order by title

-- Napisz polecenie, które:
-- wybiera numer członka biblioteki, isbn książki i wartość
-- naliczonej kary dla wszystkich wypożyczeń, dla których
-- naliczono karę

select distinct member_no, isbn, fine_assessed, 2 * fine_assessed as 'double fine'
from loanhist
where isnull(fine_assessed, 0) > 0
order by member_no

-- tu z duplikatami
select member_no, isbn, fine_assessed, 2 * fine_assessed as 'double_fine'
from loanhist
where fine_assessed != 0

-- Napisz polecenie, które
-- generuje pojedynczą kolumnę, która zawiera kolumny: imię
-- członka biblioteki, inicjał drugiego imienia i nazwisko dla
-- wszystkich członków biblioteki, którzy nazywają się Anderson

select firstname + ' ' + middleinitial + '. ' + lastname as 'email_name'
from member
where lastname = 'Anderson'

-- zmodyfikuj polecenie, tak by zwróciło „listę proponowanych
-- loginów e-mail” utworzonych przez połączenie imienia członka
-- biblioteki, z inicjałem drugiego imienia i pierwszymi dwoma
-- literami nazwiska (wszystko małymi literami).

select lower(firstname) + lower(middleinitial) + lower(substring(lastname, 1, 2)) as 'email_name', firstname, middleinitial, lastname
from member
where lastname = 'Anderson'

-- Napisz polecenie, które wybiera title i title_no z tablicy
-- title. Wynikiem powinna być pojedyncza kolumna o formacie jak w
-- przykładzie poniżej:
-- The title is: Poems, title number 7

select 'The title is: ' + title + ', title number: ' + convert(char, title_no)
from title
