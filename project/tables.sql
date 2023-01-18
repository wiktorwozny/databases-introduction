create type ListOfIDs as table
(
    ID int
)
go

create type OrderMeals as table
(
    MenuID   int,
    Quantity int
)
go

create table Categories
(
    CategoryID   int          not null
        constraint Categories_pk
            primary key,
    CategoryName varchar(255) not null
)
go

create index CategoriesName
    on Categories (CategoryName)
go

create table Clients
(
    ClientID int          not null
        constraint Clients_pk
            primary key,
    Phone    varchar(16)  not null
        constraint phone_check
            check ([Phone] like '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
    Email    varchar(255) not null
        constraint email_pk
            unique
        constraint email_check
            check ([Email] like '%@%.%')
)
go

create unique index UniquePhone
    on Clients (Phone)
go

create unique index UniqueEmail
    on Clients (Email)
go

create index ClientPhone
    on Clients (Phone)
go

create index ClientEmail
    on Clients (Email)
go

create table Countries
(
    CountryID   int identity
        constraint Countries_pk
            primary key,
    CountryName varchar(255) not null
)
go

create table Cities
(
    CityID    int identity
        constraint Cities_pk
            primary key,
    CityName  varchar(255) not null,
    CountryID int
        constraint FK_Cities_Countries
            references Countries
)
go

create index CitiesName
    on Cities (CityName)
go

create table Companies
(
    CompanyID   int          not null
        constraint Companies_pk
            primary key
        constraint [CompanyID:ClientID]
            references Clients,
    CompanyName varchar(255) not null,
    NIP         varchar(255)
        constraint nip_pk
            unique
        constraint nipe_check
            check ([NIP] like '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
    CityID      int          not null
        constraint FK_Companies_Cities
            references Cities,
    Street      varchar(255) not null,
    PostalCode  varchar(6)   not null
        constraint postal_code_check
            check ([PostalCode] like '[0-9][0-9]-[0-9][0-9][0-9]')
)
go

create unique index UniqueNIP
    on Companies (NIP)
go

create index CompaniesName
    on Companies (CompanyName)
go

create index CompaniesNIP
    on Companies (NIP)
go

create index CountriesName
    on Countries (CountryName)
go

create table DictionaryValues
(
    ValueID int identity
        constraint SłownikValues_pk
            primary key,
    Value   int not null
)
go

create table Dictionary
(
    ID   int identity
        constraint Słownik_pk
            primary key
        constraint FK_Dictionary_DictionaryValues
            references DictionaryValues,
    Name varchar(255) not null
)
go

create   trigger project.PROPERDICTIONARYVARIABLESCHECK
    on project.DictionaryValues
    for insert
    as
BEGIN
    if (select Value from inserted) <= 0
        BEGIN
            RAISERROR ('Wprowadzono niepoprawny rekord', 16, 1)
            ROLLBACK TRANSACTION
        END
END
go

create table DiscountDetails
(
    DiscountID      int identity
        constraint DiscountDetails_pk
            primary key,
    StartDate       datetime      not null,
    EndDate         datetime,
    Avaliable       bit default 1 not null,
    PercentageValue int           not null
        constraint discount_check
            check ([PercentageValue] > 0 AND [PercentageValue] <= 100),
    constraint date_check
        check ([EndDate] > [StartDate])
)
go

create table Employees
(
    EmployeeID int identity
        constraint Employees_pk
            primary key,
    CompanyID  int          not null
        constraint FK_Employees_Companies
            references Companies,
    FirstName  varchar(255) not null,
    LastName   varchar(255) not null
)
go

create index EmployeesName
    on Employees (FirstName, LastName)
go

create table IndividualClients
(
    ClientID  int          not null
        constraint IndividualClients_pk
            primary key
        constraint [ClientID:ClientID]
            references Clients,
    FirstName varchar(255) not null,
    LastName  varchar(255) not null
)
go

create table Discounts
(
    DiscountID int not null
        constraint FK_Discounts_DiscountDetails
            references DiscountDetails,
    ClientID   int not null
        constraint FK_Discounts_IndividualClients
            references IndividualClients,
    constraint Discounts_pk
        primary key (DiscountID, ClientID)
)
go

create index IndividualClientsName
    on IndividualClients (FirstName, LastName)
go

create table Meals
(
    Name        varchar(255) not null
        constraint name_pk
            unique,
    MealID      int          not null
        constraint Meals_pk
            primary key,
    CategoryID  int          not null
        constraint FK_Meals_Categories
            references Categories,
    Description varchar(255),
    UnitInStock int          not null
        constraint unit_check
            check ([UnitInStock] >= 0)
)
go

create index MealsName
    on Meals (Name)
go

create table Menus
(
    MenuID             int not null
        constraint Menus_pk
            primary key,
    MealID             int not null
        constraint FK_Menus_Meals
            references Meals,
    AddToMenuDate      date,
    RemoveFromMenuDate date,
    UnitPrice          int not null
        constraint unit_price_check
            check ([UnitPrice] >= 0),
    constraint menu_date_check
        check ([RemoveFromMenuDate] > [AddToMenuDate])
)
go

create table PaymentDetails
(
    PaymentID     int identity
        constraint PaymentDetails_pk
            primary key,
    PaymentStatus bit default 0 not null,
    TypeOfPayment varchar(255)  not null
        constraint payment_type_check
            check ([TypeOfPayment] = 'invoice' OR [TypeOfPayment] = 'blik' OR [TypeOfPayment] = 'paypal' OR
                   [TypeOfPayment] = 'card' OR [TypeOfPayment] = 'cash')
)
go

create index PaymentDetailsStatus
    on PaymentDetails (PaymentStatus)
go

create table Reservations
(
    ReservationID     int         not null
        constraint Reservations_pk
            primary key,
    StartDate         datetime    not null
        constraint reservation_date_check_2
            check ([StartDate] > getdate()),
    EndDate           datetime    not null,
    Status            varchar(32) not null
        constraint reservation_status_check
            check ([Status] = 'finished' OR [Status] = 'rejected' OR [Status] = 'accepted' OR [Status] = 'pending'),
    SizeOfReservation int         not null
        constraint size_reservation_check
            check ([SizeOfReservation] >= 2),
    constraint reservation_date_check
        check ([EndDate] > [StartDate])
)
go

create table ComapnyReservations
(
    ReservationID int not null
        constraint ComapnyReservations_pk
            primary key
        constraint [ReservationID:ReservationID(2)]
            references Reservations,
    CompanyID     int not null
        constraint FK_ComapnyReservations_Companies
            references Companies
)
go

create table CompanyPersonalReservation
(
    EmployeeID    int not null
        constraint [EmplyeeID:EmployeeID]
            references Employees,
    ReservationID int not null
        constraint [ReservationID:ReservationID]
            references Reservations,
    constraint CompanyPersonalReservation_pk
        primary key (EmployeeID, ReservationID)
)
go

create index ReservationsStatus
    on Reservations (Status)
go

create table Tables
(
    TableNumber int identity
        constraint Tables_pk
            primary key,
    Capacity    int not null
        constraint capacity_check
            check ([Capacity] >= 1)
)
go

create table ReservationDetails
(
    ReservationID int not null
        constraint ReservationDetails_Reservations_null_fk
            references Reservations,
    TableID       int not null
        constraint ReservationDetails_Tables_null_fk
            references Tables,
    constraint ReservationDetails_pk
        primary key (ReservationID, TableID)
)
go

create index TablesCapacity
    on Tables (Capacity)
go

create table Takeaways
(
    TakeawayID  int identity
        constraint Takeaway_pk
            primary key,
    TakewayTime datetime not null
        constraint takeway_check
            check ([TakewayTime] > getdate())
)
go

create table Orders
(
    OrderID       int      not null
        constraint Orders_pk
            primary key,
    ClientID      int      not null
        constraint FK_Orders_Clients
            references Clients,
    OrderDate     datetime not null,
    PaymentID     int      not null
        constraint FK_Orders_PaymentDetails
            references PaymentDetails,
    TakeawayID    int
        constraint FK_Orders_Takeaways
            references Takeaways,
    ReservationID int
)
go

create table IndividualClientReservations
(
    ReservationID      int not null
        constraint IndividualClientReservations_pk
            primary key,
    IndividualClientID int not null
        constraint FK_IndividualClientReservations_IndividualClients
            references IndividualClients,
    OrderID            int not null
        constraint FK_IndividualClientReservations_Orders
            references Orders
)
go

create table OrderDetails
(
    MenuID   int not null
        constraint FK_OrderDetails_Menus
            references Menus,
    OrderId  int not null
        constraint OrderID_OrderID
            references Orders,
    Quantity int not null
        constraint quantity_check
            check ([Quantity] > 0),
    constraint OrderDetails_pk
        primary key (MenuID, OrderId)
)
go

create index OrdersReservationID
    on Orders (ReservationID)
go

create index OrdersPaymentID
    on Orders (PaymentID)
go

create index OrdersTakeawayID
    on Orders (TakeawayID)
go

create table WZWK
(
    WZ      int not null,
    WK      int not null,
    id      int identity
        constraint WZWK_pk
            primary key,
    ValidTo date
)
go

create   trigger project.PROPERWZWKCHECK
    on project.WZWK
    for insert
    as
BEGIN
    if ((select WZ from inserted) <= 0) or ((select WK from inserted) <= 0)
        BEGIN
            RAISERROR ('Wprowadzono niepoprawny rekord', 16, 1)
            ROLLBACK TRANSACTION
        END
END
go
