CREATE PROCEDURE project.AddCity @CityName varchar(255),
                         @CountryName varchar(255)
AS
BEGIN
    SET
NOCOUNT ON
BEGIN TRY
IF EXISTS(
                SELECT *
                FROM project.Cities
                WHERE CityName = @CityName
            )
BEGIN
                ;
                THROW
52000, N'Już jest takie miasto', 1
END
        IF
NOT EXISTS(
                SELECT *
                FROM project.Countries
                where CountryName = @CountryName
            )
BEGIN
                ;
                THROW
52000, N'Nie ma takiego państwa w bazie', 1
END
        DECLARE
@CountryID INT
SELECT @CountryID = CountryID
FROM project.Countries
WHERE CountryName = @CountryName
    INSERT
INTO project.Cities(CityName, CountryID)
VALUES (@CityName, @CountryID)
END TRY
BEGIN CATCH
        DECLARE
@msg nvarchar(2048)
            =N'Błąd dodania nowego miasta: ' + ERROR_MESSAGE();
        THROW
52000, @msg, 1
END CATCH
end
go

grant execute on AddCity to moderator
go

CREATE PROCEDURE project.AddCompany @Phone varchar(16),
                            @Email varchar(255),
                            @CompanyName varchar(255),
                            @NIP varchar(255),
                            @City varchar(255),
                            @Street varchar(255),
                            @PostalCode varchar(6)
AS
BEGIN
    SET
NOCOUNT ON
BEGIN TRAN
BEGIN TRY
IF EXISTS(
                    SELECT *
                    FROM project.Clients
                    WHERE Phone = @Phone
                )
BEGIN
                    ;
                    THROW
52000, N'Numer telefonu jest już w bazie', 1
END
            IF
EXISTS(
                    SELECT *
                    FROM project.Clients
                    WHERE Email = @Email
                )
BEGIN
                    ;
                    THROW
52000, N'Email jest już w bazie', 1
END
            IF
EXISTS(
                    SELECT *
                    FROM project.Companies
                    WHERE NIP = @NIP
                )
BEGIN
                    ;
                    THROW
52000, N'Firma o podanym NIPie jest już w bazie', 1
END
            IF
NOT EXISTS(
                    SELECT *
                    FROM project.Cities
                    WHERE CityName = @City
                )
BEGIN
                    ;
                    THROW
52000, N'Nie ma podanego miasta w bazie', 1
END
            DECLARE
@ClientID INT
SELECT @ClientID = ISNULL(MAX(ClientID), 0) + 1
FROM project.Clients
    INSERT
INTO project.Clients(ClientID, Phone, Email)
VALUES (@ClientID, @Phone, @Email);
DECLARE
@CityID INT
SELECT @CityID = CityID
FROM project.Cities
WHERE CityName = @City
    INSERT
INTO project.Companies(CompanyID, CompanyName, NIP, CityID, Street, PostalCode)
VALUES (@ClientID, @CompanyName, @NIP, @CityID, @Street, @PostalCode)
    COMMIT TRANSACTION
END TRY
BEGIN CATCH
ROLLBACK TRANSACTION
            DECLARE
@msg nvarchar(2048)
                =N'Błąd dodania firmy: ' + ERROR_MESSAGE();
            THROW
52000, @msg, 1
END CATCH
END
go

grant execute on AddCompany to moderator
go

CREATE PROCEDURE project.AddDiscount @ClientID int
AS
BEGIN
    IF
NOT EXISTS(SELECT * FROM project.IndividualClients WHERE @ClientID = ClientID)
BEGIN
            ;
            THROW
52000, N'Taki klient nie istnieje', 1
end
    IF
(project.checkIfClientHasActiveDiscount(@ClientID) = 1)
BEGIN
            ;
            THROW
52000, N'Ten klient ma już aktywną zniżkę', 1
end
    DECLARE
@AvailableDiscounts int = 0;
    IF
(EXISTS(SELECT * FROM project.ClientsWithAvailableSecondDiscount WHERE ClientID = @ClientID) AND
        (@ClientID not in (SELECT DISTINCT ClientID FROM project.Discounts)))
Begin
SELECT @AvailableDiscounts = @AvailableDiscounts + 1;
INSERT INTO project.DiscountDetails(StartDate, EndDate, Avaliable, PercentageValue)
VALUES (GETDATE(), DATEADD(DAY, 7, GETDATE()), 1,
        (SELECT d.Value FROM project.DictionaryValues as d WHERE d.ValueID = 5))
end
ELSE
        IF EXISTS(SELECT *
                  FROM project.ClientsWithAvailableFirstDiscount
                  WHERE ClientID = @ClientID)
Begin
SELECT @AvailableDiscounts = @AvailableDiscounts + 1;
INSERT INTO project.DiscountDetails(StartDate, EndDate, Avaliable, PercentageValue)
VALUES (GETDATE(), null, 1,
        (SELECT d.Value FROM project.DictionaryValues as d WHERE d.ValueID = 3))
end

    IF
(@AvailableDiscounts = 0)
BEGIN
            ;
            THROW
52000, N'Klientowi nie przysługuje żadna zniżka', 1
END
ELSE
BEGIN
            DECLARE
@DiscountID int;
SELECT @DiscountID = MAX(DiscountDetails.DiscountID)
FROM project.DiscountDetails
    INSERT
INTO project.Discounts(DiscountID, ClientID)
VALUES (@DiscountID, @ClientID)
end
end
go

grant execute on AddDiscount to moderator
go

grant execute on AddDiscount to worker
go

CREATE PROCEDURE project.AddEmployee @CompanyName varchar(255),
                                      @FirstName varchar(255),
                                      @LastName varchar(255)
AS
BEGIN
    SET
NOCOUNT ON
BEGIN TRY
IF EXISTS(
                SELECT *
                FROM project.Employees as E
                         INNER JOIN project.Companies C on E.CompanyID = C.CompanyID
                WHERE @FirstName = E.FirstName
                  AND @LastName = E.LastName
                  AND @CompanyName = C.CompanyName
            )
BEGIN
                ;
                THROW
52000, N'Pracownik jest już w bazie', 1
END
        IF
NOT EXISTS(
                SELECT *
                FROM project.Companies
                WHERE @CompanyName = CompanyName
            )
BEGIN
                ;
                THROW
52000, 'Nie ma takiej firmy', 1
end
        DECLARE
@CompanyID INT
SELECT @CompanyID = CompanyID
FROM project.Companies
WHERE @CompanyName = CompanyName
    INSERT
INTO project.Employees(CompanyID, FirstName, LastName)
VALUES (@CompanyID, @FirstName, @LastName)
END TRY
BEGIN CATCH
        DECLARE
@msg nvarchar(2048)
            =N'Błąd dodania pracownika: ' + ERROR_MESSAGE();
        THROW
52000, @msg, 1
END CATCH
END
go

grant execute on AddEmployee to moderator
go

CREATE PROCEDURE project.AddEmployeeReservation @ClientID int,
                                                         @Products project.OrderMeals readonly ,
                                                         @PaymentID int = null,
                                                         @TypeOfPayment varchar(255),
                                                         @ReservationStartDate datetime,
                                                         @ReservationEndDate datetime,
                                                         @Employees ListOfIDs readonly
AS
BEGIN
    SET
NOCOUNT ON
    DECLARE
@Name varchar(20) = 'AddOrderRN'
BEGIN TRAN
@Name
        SAVE TRAN @Name
BEGIN TRY
IF project.canClientHaveReservation(@ClientID, @Products) = 0
BEGIN
                    THROW
52000, N'Klient nie może złożyć rezerwacji', 1
END
            DECLARE
@ResID int;
            DECLARE
@ReservationSize int;
SELECT @ReservationSize = COUNT(*)
FROM @Employees EXECUTE project.AddReservation @ReservationStartDate, @ReservationEndDate, 2,
                    @ReservationID = @ResID OUTPUT
            IF EXISTS(SELECT * FROM @Products)
BEGIN
EXECUTE project.AddOrder @ClientID, @Products, @PaymentID, @TypeOfPayment, 0, null, @ResID
END
Insert Into project.ComapnyReservations(ReservationID, CompanyID)
VALUES (@ResID, @ClientID)
DECLARE
@EmployeeID as int
            DECLARE
EmployeeCursor CURSOR FOR
SELECT *
FROM @Employees;
OPEN EmployeeCursor;
FETCH NEXT FROM EmployeeCursor INTO @EmployeeID;
WHILE
@@FETCH_STATUS = 0
BEGIN
EXECUTE project.AddEmployeeToReservation @ResID, @EmployeeID
                    FETCH NEXT FROM EmployeeCursor INTO @EmployeeID;
END;
COMMIT TRAN @Name
END TRY
BEGIN CATCH
ROLLBACK TRAN @Name
            DECLARE
@msg nvarchar(2048)
                =N'Błąd dodawania zamówienia: ' + ERROR_MESSAGE();
            THROW
52000, @msg, 1
END catch
END
go

CREATE PROCEDURE project.AddEmployeeToReservation @ReservationID int,
                                                   @EmployeeID int
AS
BEGIN
    SET
NOCOUNT ON
BEGIN TRY
        Declare
@CompanyID int

SELECT @CompanyID = CompanyID
FROM project.ComapnyReservations
WHERE ReservationID = @ReservationID IF NOT EXISTS(SELECT * FROM project.Reservations WHERE ReservationID = @ReservationID)
BEGIN
                THROW
52000, N'Taka rezerwacja nie isnieje', 1
end
        IF
NOT EXISTS(SELECT * FROM project.Employees WHERE EmployeeID = @EmployeeID)
BEGIN
                THROW
52000, N'W bazie nie ma takiego pracownika', 1
end
INSERT INTO project.CompanyPersonalReservation(EmployeeID, ReservationID)
VALUES (@EmployeeID, @ReservationID)
END TRY
BEGIN CATCH
        DECLARE
@msg nvarchar(2048)
            =N'Błąd dodawania zamówienia: ' + ERROR_MESSAGE();
        THROW
52000, @msg, 1
END CATCH
END
go

CREATE PROCEDURE project.AddIndividualClient @Phone varchar(16),
                                     @Email varchar(255),
                                     @FirstName varchar(255),
                                     @LastName varchar(255)
AS
BEGIN
    SET
NOCOUNT ON
BEGIN TRAN
BEGIN TRY
IF EXISTS(
                    SELECT *
                    FROM project.Clients
                    WHERE Phone = @Phone
                )
BEGIN
                    ;
                    THROW
52000, N'Numer telefonu jest już w bazie', 1
END
            IF
EXISTS(
                    SELECT *
                    FROM project.Clients
                    WHERE Email = @Email
                )
BEGIN
                    ;
                    THROW
52000, N'Email jest już w bazie', 1
END
            DECLARE
@ClientID INT
SELECT @ClientID = ISNULL(MAX(ClientID), 0) + 1
FROM project.Clients
    INSERT
INTO project.Clients(ClientID, Phone, Email)
VALUES (@ClientID, @Phone, @Email);
INSERT INTO project.IndividualClients(ClientID, FirstName, LastName)
VALUES (@ClientID, @FirstName, @LastName) COMMIT TRANSACTION
END TRY
BEGIN CATCH
ROLLBACK TRANSACTION
            DECLARE
@msg nvarchar(2048)
                =N'Błąd dodania klienta indywidualnego: ' + ERROR_MESSAGE();
            THROW
52000, @msg, 1
END CATCH
END
go

grant execute on AddIndividualClient to moderator
go

CREATE PROCEDURE project.AddMeal @Name varchar(255),
                                  @CategoryName varchar(255),
                                  @Description varchar(255),
                                  @UnitInStock int
AS
BEGIN
    SET
NOCOUNT ON
BEGIN TRY
IF EXISTS(
                SELECT *
                FROM project.Meals
                WHERE Name = @Name
            )
BEGIN
                ;
                THROW
52000, N'Potrawa jest już dodana', 1
END
        IF
NOT EXISTS(
                SELECT *
                FROM project.Categories
                WHERE CategoryName = @CategoryName
            )
BEGIN
                ;
                THROW
52000, 'Nie ma takiej kategorii', 1
END
        DECLARE
@CategoryID INT
SELECT @CategoryID = CategoryID
FROM project.Categories
WHERE CategoryName = @CategoryName
DECLARE
@MealID INT
SELECT @MealID = ISNULL(MAX(MealID), 0) + 1
FROM project.Meals
    INSERT
INTO project.Meals(Name, MealID, CategoryID, Description, UnitInStock)
VALUES (@Name, @MealID, @CategoryID, @Description, @UnitInStock);
END TRY
BEGIN CATCH
        DECLARE
@msg nvarchar(2048)
            =N'Błąd dodania potrawy: ' + ERROR_MESSAGE();
        THROW
52000, @msg, 1;
END CATCH
END
go

grant execute on AddMeal to moderator
go

grant execute on AddMeal to worker
go

CREATE PROCEDURE project.AddMealToMenu @Name varchar(255),
                                        @Price money,
                                        @StartDate varchar(255)
AS
BEGIN
    SET
NOCOUNT ON
BEGIN TRY
IF NOT EXISTS(
                SELECT *
                FROM project.Meals
                WHERE Name = @Name
            )
BEGIN
                ;
                THROW
52000, 'Nie ma takiej potrawy', 1
END

        DECLARE
@MealID INT
SELECT @MealID = MealID
FROM project.Meals
WHERE Name = @Name IF EXISTS(
                SELECT *
                FROM project.Menus
                WHERE MealID = @MealID
                  AND (RemoveFromMenuDate IS NULL OR RemoveFromMenuDate > @StartDate)
            )
BEGIN
                ;
                THROW
52000, N'W menu istnieje już taka potrawa', 1
END

        DECLARE
@MenuID INT
SELECT @MenuID = ISNULL(MAX(MenuID), 0) + 1
FROM project.Menus
    INSERT
INTO project.Menus(MenuID, MealID, AddToMenuDate, RemoveFromMenuDate, UnitPrice)
VALUES (@MenuID, @MealID, @StartDate, null, @Price);
END TRY
BEGIN CATCH
        DECLARE
@msg nvarchar(2048)
            =N'Błąd dodania potrawy do menu: ' + ERROR_MESSAGE();
        THROW
52000, @msg, 1
END CATCH
END
go

grant execute on AddMealToMenu to moderator
go

grant execute on AddMealToMenu to worker
go

CREATE PROCEDURE project.AddMealToOrder @OrderID int,
                                                 @Quantity int,
                                                 @MenuID int
AS
BEGIN
    SET
NOCOUNT ON
BEGIN TRY
IF project.isMenuItemAvailable(@MenuID) = 0
BEGIN
                    THROW
52000, N'Ta potrawa nie jest aktualnie dostępna', 1
END
            IF
project.orderExists(@OrderID) = 0
BEGIN
                    THROW
52000, N'Nie ma takiego zamówienia', 1
end
            IF
project.isMenuItemInStock(@MenuID, @Quantity) = 0
BEGIN
                    THROW
52000, N'Nie jest dostępna taka ilość', 1
end
            DECLARE
@MealID int
SELECT @MealID = C.MealID
FROM project.CurrentMenu C
WHERE C.MenuID = @MenuID
    INSERT
INTO project.OrderDetails(MenuID, OrderId, Quantity)
VALUES (@MenuID, @OrderID, @Quantity)
UPDATE project.Meals
SET UnitInStock = UnitInStock - @Quantity
WHERE MealID = @MealID
END TRY
BEGIN CATCH
            DECLARE
@msg nvarchar(2048)
                =N'Błąd dodawania produktu do zamówienia: ' + ERROR_MESSAGE();
            THROW
52000, @msg, 1
END CATCH
END
go

CREATE PROCEDURE project.AddOrder @ClientID int,
                                           @Products project.OrderMeals readonly,
                                           @PaymentID int = null,
                                           @TypeOfPayment varchar(255) = null,
                                           @IsTakeaway bit,
                                           @TakeawayTime datetime = null,
                                           @ReservationID int
AS
BEGIN
    SET
NOCOUNT ON
    DECLARE
@Name varchar(20) = 'AddOrder'
BEGIN TRAN
@Name
        SAVE TRAN @Name
BEGIN TRY
IF project.customerExists(@ClientID) = 0
BEGIN
                    THROW
52000, N'Taki klient nie istnieje!', 1
END
            DECLARE
@OrderDate datetime
            SET @OrderDate = GETDATE()
            DECLARE
@ReservationStartDate datetime
            SET @ReservationStartDate = project.getStartDateOfReservation(@ReservationID)
            IF (project.haveMealsSomeSeafood(@Products) = 1) AND
               (project.canOrderHasSeafood(@OrderDate, @ReservationStartDate, @TakeawayTime) = 0)
BEGIN
                    THROW
52000, N'Zamówienie zawiera owoce morza ale nie może zostać zrealizowane!', 1
END
            DECLARE
@VarPaymentID int;
            SET
@VarPaymentID = @PaymentID
            IF @PaymentID IS NULL
BEGIN
EXECUTE project.AddPayment DEFAULT, @TypeOfPayment, @PaymentID = @VarPaymentID OUTPUT
end
            DECLARE
@TakeAwayID int
            IF @IsTakeaway = 1
BEGIN
EXECUTE project.AddTakeaway @TakeawayTime, @TakeAwayID
END
            DECLARE
@OrderID int
SELECT @OrderID = ISNULL(MAX(OrderID), 0) + 1
FROM project.Orders
    INSERT
INTO project.Orders(OrderID, ClientID, OrderDate, PaymentID, TakeawayID, ReservationID)
VALUES (@OrderID, @ClientID, @OrderDate, @VarPaymentID, @TakeAwayID, @ReservationID)
DECLARE
@MenuID as int
            DECLARE
@Quantity as int
            DECLARE
ProductCursor CURSOR FOR
SELECT *
FROM @Products;
OPEN ProductCursor;
FETCH NEXT FROM ProductCursor INTO @MenuID, @Quantity;
WHILE
@@FETCH_STATUS = 0
BEGIN
EXECUTE project.AddMealToOrder @OrderID, @Quantity, @MenuID
                    FETCH NEXT FROM ProductCursor INTO @MenuID, @Quantity;
END;
COMMIT TRAN
END TRY
BEGIN CATCH
ROLLBACK TRAN @Name
            DECLARE
@msg nvarchar(2048)
                =N'Błąd dodawania zamówienia: ' + ERROR_MESSAGE();
            THROW
52000, @msg, 1
END catch
END
go

grant execute on AddOrder to moderator
go

grant execute on AddOrder to worker
go

CREATE PROCEDURE project.AddOrderWithEmployeeReservation @ClientID int,
                                                                  @Products project.OrderMeals readonly,
                                                                  @PaymentID int = null,
                                                                  @TypeOfPayment varchar(255),
                                                                  @ReservationStartDate datetime,
                                                                  @ReservationEndDate datetime,
                                                                  @Employees ListOfIDs readonly
AS
BEGIN
    SET
NOCOUNT ON
    DECLARE
@Name varchar(20) = 'AddOrderRN'
BEGIN TRAN
@Name
        SAVE TRAN @Name
BEGIN TRY
            DECLARE
@CanAddReservation BIT
            SET @CanAddReservation = project.canClientHaveReservation(@ClientID, @Products)
            IF @CanAddReservation = 0
BEGIN
                    THROW
52000, N'Klient nie może złożyć rezerwacji', 1
END
            DECLARE
@ReservationID int;
            DECLARE
@ReservationSize int;
SELECT @ReservationSize = COUNT(*) SELECT *
FROM @Employees
    EXECUTE project.AddReservation @ReservationStartDate, @ReservationEndDate, @ReservationSize, @ReservationID = @ReservationID
    EXECUTE project.AddOrder @ClientID, @Products, @PaymentID, @TypeOfPayment, 0, null, @ReservationID
DECLARE
@EmployeeID as int
            DECLARE
EmployeeCursor CURSOR FOR
SELECT *
FROM @Employees;
OPEN EmployeeCursor;
FETCH NEXT FROM EmployeeCursor INTO @EmployeeID;
WHILE
@@FETCH_STATUS = 0
BEGIN
EXECUTE project.AddEmployeeToReservation @ReservationID, @EmployeeID
                    FETCH NEXT FROM EmployeeCursor INTO @EmployeeID;
END;
COMMIT TRAN
END TRY
BEGIN CATCH
ROLLBACK TRAN @Name
            DECLARE
@msg nvarchar(2048)
                =N'Błąd dodawania zamówienia: ' + ERROR_MESSAGE();
            THROW
52000, @msg, 1
END catch
END
go

CREATE PROCEDURE project.AddOrderWithSizeReservation @ClientID int,
                                                              @Products project.OrderMeals readonly,
                                                              @PaymentID int = null,
                                                              @TypeOfPayment varchar(255),
                                                              @ReservationStartDate datetime,
                                                              @ReservationEndDate datetime,
                                                              @ReservationSize int
AS
BEGIN
    SET
NOCOUNT ON
    DECLARE
@Name varchar(20) = 'AddOrderRS'
BEGIN TRAN
@Name
        SAVE TRAN @Name
BEGIN TRY
            DECLARE
@CanAddReservation BIT
            SET @CanAddReservation = project.canClientHaveReservation(@ClientID, @Products)
            IF @CanAddReservation = 0
BEGIN
                    THROW
52000, N'Klient nie może złożyć rezerwacji', 1
END
            DECLARE
@ResID int;
EXECUTE project.AddReservation @ReservationStartDate, @ReservationEndDate, @ReservationSize,
                    @ReservationID = @ResID OUTPUT
            EXECUTE project.AddOrder @ClientID, @Products, @PaymentID, @TypeOfPayment, 0, null, @ResID
DECLARE
@OrderID as int;
SELECT @OrderID = ISNULL(MAX(OrderID), 0)
FROM project.Orders IF EXISTS(SELECT * FROM project.IndividualClients WHERE ClientID = @ClientID)
BEGIN
INSERT INTO project.IndividualClientReservations(ReservationID, IndividualClientID, OrderID)
VALUES (@ResID, @ClientID, @OrderID)
end
            IF
EXISTS(SELECT * FROM project.Companies WHERE CompanyID = @ClientID)
BEGIN
Insert Into project.ComapnyReservations(ReservationID, CompanyID)
VALUES (@ResID, @ClientID)
end
COMMIT TRAN
END TRY
BEGIN CATCH
ROLLBACK TRAN @Name
            DECLARE
@msg nvarchar(2048)
                =N'Błąd dodawania zamówienia z rezerwacją: ' + ERROR_MESSAGE();
            THROW
52000, @msg, 1
END catch
END
go

grant execute on AddOrderWithSizeReservation to moderator
go

grant execute on AddOrderWithSizeReservation to worker
go

CREATE PROCEDURE project.AddPayment @PaymentStatus bit = 0,
                                             @TypeOfPayment varchar(255),
                                             @PaymentID int OUTPUT
AS
BEGIN
    SET
NOCOUNT ON
BEGIN TRY
INSERT INTO project.PaymentDetails(PaymentStatus, TypeOfPayment)
        VALUES (@PaymentStatus, @TypeOfPayment)
SELECT @PaymentID = MAX(PaymentID)
FROM project.PaymentDetails
end try
begin catch
        DECLARE
@msg nvarchar(2048)
            =N'Błąd dodawania płatności: ' + ERROR_MESSAGE();
        THROW
52000, @msg, 1
end catch
END
go

CREATE PROCEDURE project.AddReservation @ReservationStartDate datetime,
                                                 @ReservationEndDate datetime,
                                                 @ReservationSize int,
                                                 @ReservationID int OUTPUT
AS
BEGIN
    SET
NOCOUNT ON
BEGIN TRY
SELECT @ReservationID = ISNULL(MAX(ReservationID), 0) + 1
FROM project.Reservations
    INSERT
INTO project.Reservations(ReservationID, StartDate, EndDate, Status, SizeOfReservation)
VALUES (@ReservationID, @ReservationStartDate, @ReservationEndDate, 'pending', @ReservationSize)
END TRY
BEGIN CATCH
        DECLARE
@msg nvarchar(2048)
            =N'Błąd dodawania rezerwacji: ' + ERROR_MESSAGE();
        THROW
52000, @msg, 1
END CATCH
end
go

grant execute on AddReservation to moderator
go

grant execute on AddReservation to worker
go

CREATE PROCEDURE project.AddTable @Capacity int
AS
BEGIN
    SET
NOCOUNT ON
BEGIN TRY
INSERT INTO project.Tables(Capacity)
        VALUES (@Capacity);
END TRY
BEGIN CATCH
        DECLARE
@msg nvarchar(2048)
            =N'Błąd dodawania stolika: ' + ERROR_MESSAGE();
        THROW
52000, @msg, 1
END CATCH
END
go

grant execute on AddTable to moderator
go

grant execute on AddTable to worker
go

CREATE PROCEDURE project.AddTableToReservation @ReservationID int,
                                               @TableID int
AS
BEGIN
    SET
NOCOUNT ON
BEGIN TRY
IF NOT EXISTS(
                SELECT *
                FROM project.Tables
                WHERE TableNumber = @TableID
            )
BEGIN
                ;
                THROW
52000, N'Nie ma stolika o podanym ID', 1
END
        IF
EXISTS(
                SELECT *
                FROM project.ReservationDetails
                WHERE TableID = @TableID
            )
BEGIN
                ;
                THROW
52000, N'Ten stolik jest już przydzielony do tej rezerwacji', 1
END

        DECLARE
@StartDate DATE
SELECT @StartDate = StartDate
from project.Reservations R
where R.ReservationID = @ReservationID
DECLARE
@EndDate DATE
SELECT @EndDate = EndDate
from project.Reservations R
where R.ReservationID = @ReservationID IF @TableID not in (select * from project.getFreeTables(@StartDate, @EndDate))
BEGIN
                ;
                THROW
52000, N'Ten stolik jest zajęty w tych godzinach!', 1
END

BEGIN
INSERT INTO project.ReservationDetails(ReservationID, TableID)
VALUES (@ReservationID, @TableID)
END
END TRY
BEGIN CATCH
        DECLARE
@msg nvarchar(2048)
            =N'Błąd dopisania stolika do rezerwacji: ' + ERROR_MESSAGE();
        THROW
52000, @msg, 1
END CATCH
END
go

grant execute on AddTableToReservation to moderator
go

grant execute on AddTableToReservation to worker
go

CREATE PROCEDURE project.AddTakeaway @TakeawayTime datetime,
                                              @TakeawayID int OUTPUT
AS
BEGIN
    SET
NOCOUNT ON
BEGIN TRY
INSERT INTO project.Takeaways(TakewayTime)
        VALUES (@TakeawayTime)
SELECT @TakeawayID = MAX(TakeawayID)
FROM project.Takeaways
end try
begin catch
        DECLARE
@msg nvarchar(2048)
            =N'Błąd dodawania danych odbioru zamówienia: ' + ERROR_MESSAGE();
        THROW
52000, @msg, 1
end catch
END
go

CREATE PROCEDURE project.ChangePaymentStatus @OrderID int AS
BEGIN
    SET
NOCOUNT ON
BEGIN TRY
IF NOT EXISTS(
                SELECT *
                FROM project.Orders
                WHERE OrderID = @OrderID
            )
BEGIN
                ;
                THROW
52000, N'Nie ma takiego zamówienia', 1
END
        IF
((SELECT PaymentStatus
             FROM project.PaymentDetails
             WHERE PaymentID = (SELECT PaymentID
                                FROM project.Orders
                                WHERE OrderID = @OrderID)) = 1)
BEGIN
                ;
                THROW
52000, N'Zamówienie jest już opłacone', 1
END
        DECLARE
@PaymentID int
SELECT @PaymentID = PaymentID
FROM project.Orders
WHERE OrderID = @OrderID
BEGIN
UPDATE project.PaymentDetails
SET PaymentStatus = 1
WHERE PaymentID = @PaymentID
END
END TRY
BEGIN CATCH
        DECLARE
@msg nvarchar(2048)
            =N'Błąd zmiany statusu platnosci: ' +
             ERROR_MESSAGE();
        THROW
52000, @msg, 1
END CATCH
END
go

grant execute on ChangePaymentStatus to moderator
go

grant execute on ChangePaymentStatus to worker
go

CREATE PROCEDURE project.ChangeReservationStatus @ReservationID int,
                                         @NewStatus varchar(32),
                                         @TableID int
AS
BEGIN
    SET
NOCOUNT ON
BEGIN TRY
IF NOT EXISTS(
                SELECT *
                FROM project.Reservations
                WHERE ReservationID = @ReservationID
            )
BEGIN
                ;
                THROW
52000, N'Nie ma rezerwacji o podanym ID', 1
END
        IF
(
SELECT Status
FROM project.Reservations
WHERE ReservationID = @ReservationID) = @NewStatus
BEGIN
                ;
                THROW
52000, N'Ta rezerwacja ma już taki status', 1
END
BEGIN
UPDATE project.Reservations
SET Status = @NewStatus
WHERE ReservationID = @ReservationID
END
        IF
@NewStatus = 'accepted'
BEGIN
                IF
@TableID is null
BEGIN
                        ;
                        THROW
52000, N'Musisz podać id stolika', 1
END
END
BEGIN
            IF
NOT EXISTS(
                    SELECT *
                    FROM project.Tables
                    WHERE TableNumber = @TableID
                )
BEGIN
                    ;
                    THROW
52000, N'Nie ma stolika o podanym ID', 1
END
END
BEGIN
INSERT INTO project.ReservationDetails(ReservationID, TableID)
VALUES (@ReservationID, @TableID)
END
        -- CODE
END TRY
BEGIN CATCH
        DECLARE
@msg nvarchar(2048)
            =N'Błąd edytowania statusu rezerwacji: ' + ERROR_MESSAGE();
        THROW
52000, @msg, 1
END CATCH
END
go

grant execute on ChangeReservationStatus to moderator
go

grant execute on ChangeReservationStatus to worker
go

CREATE PROCEDURE project.EditTable @TableNumber int,
                                    @NewCapacity int
AS
BEGIN
    SET
NOCOUNT ON
BEGIN TRY
IF NOT EXISTS(
                SELECT *
                FROM project.Tables
                WHERE TableNumber = @TableNumber
            )
BEGIN
                ;
                THROW
52000, 'Nie ma takiego stolika', 1
END
UPDATE project.Tables
SET Capacity = @NewCapacity
WHERE TableNumber = @TableNumber
END TRY
BEGIN CATCH
        DECLARE
@msg nvarchar(2048)
            =N'Błąd usuwania stolika: ' + ERROR_MESSAGE();
        THROW
52000, @msg, 1
END CATCH
END
go

grant execute on EditTable to moderator
go

grant execute on EditTable to worker
go

CREATE PROCEDURE project.RemoveMealFromMenu @Name varchar(255),
                                    @EndDate varchar(255)
AS
BEGIN
    SET
NOCOUNT ON
BEGIN TRY
IF NOT EXISTS(
                SELECT *
                FROM project.Meals
                WHERE Name = @Name
            )
BEGIN
                ;
                THROW
52000, 'Nie ma takiej potrawy', 1
END

        DECLARE
@MealID INT
SELECT @MealID = MealID
FROM project.Meals
WHERE Name = @Name IF NOT EXISTS(
                SELECT *
                FROM project.Menus
                WHERE MealID = @MealID
                  AND RemoveFromMenuDate IS NULL
            )
BEGIN
                ;
                THROW
52000, 'W menu nie ma takiej potrawy', 1
END
        DECLARE
@MenuID INT
SELECT @MenuID = MenuID
FROM project.Menus
WHERE MealID = @MealID
  AND RemoveFromMenuDate IS NULL;
UPDATE project.Menus
SET RemoveFromMenuDate = @EndDate
WHERE MealID = @MealID
  AND MenuID = @MenuID;
END TRY
BEGIN CATCH
        DECLARE
@msg nvarchar(2048)
            =N'Błąd dodania potrawy do menu: ' + ERROR_MESSAGE();
        THROW
52000, @msg, 1
END CATCH
END
go

grant execute on RemoveMealFromMenu to moderator
go

grant execute on RemoveMealFromMenu to worker
go

CREATE PROCEDURE project.RemoveTable @TableNumber int
AS
BEGIN
    SET
NOCOUNT ON
BEGIN TRY
IF NOT EXISTS(
                SELECT *
                FROM project.Tables
                WHERE TableNumber = @TableNumber
            )
BEGIN
                ;
                THROW
52000, 'Nie ma takiego stolika', 1
END
DELETE
FROM project.Tables
WHERE TableNumber = @TableNumber;
END TRY
BEGIN CATCH
        DECLARE
@msg nvarchar(2048)
            =N'Błąd usuwania stolika: ' + ERROR_MESSAGE();
        THROW
52000, @msg, 1
END CATCH
END
go

grant execute on RemoveTable to moderator
go

grant execute on RemoveTable to worker
go

CREATE PROCEDURE project.ShouldMenuBeChanged
    AS
BEGIN
    SET
NOCOUNT ON
    DECLARE
@MealsToChange FLOAT;
    DECLARE
@MealsInMenu FLOAT;
SELECT @MealsToChange = COUNT(*)
FROM project.MealsLongerThanTwoWeeksInMenu
SELECT @MealsInMenu = COUNT(*)
FROM project.CurrentMenu
DECLARE
@Percentage FLOAT;
SELECT @Percentage = @MealsToChange / @MealsInMenu;
if
(@Percentage>=0.5)
BEGIN
        ;
            THROW
52000, N'Należy zmienić menu!' , 1
end
--     ELSE
--     BEGIN
--         ;
--             THROW 52000, @Percentage, 1
--     end
END
go

grant execute on ShouldMenuBeChanged to moderator
go

grant execute on ShouldMenuBeChanged to worker
go

CREATE PROCEDURE project.AddCategory @CategoryName varchar(255)
AS
BEGIN
    SET
NOCOUNT ON
BEGIN TRY
IF EXISTS(
                SELECT *
                FROM project.Categories
                WHERE @CategoryName = CategoryName
            )
BEGIN
                ;
                THROW
52000, N'Kategoria jest już dodana', 1
end
        DECLARE
@CategoryID INT
SELECT @CategoryID = ISNULL(MAX(CategoryID), 0) + 1
FROM project.Categories
    INSERT
INTO project.Categories(CategoryID, CategoryName)
VALUES (@CategoryID, @CategoryName);
END TRY
BEGIN CATCH
        DECLARE
@msg nvarchar(2048) =
            N'Błąd dodawania kategorii: ' + ERROR_MESSAGE();
        THROW
52000, @msg, 1;
END CATCH
END
go

grant execute on addCategory to moderator
go
