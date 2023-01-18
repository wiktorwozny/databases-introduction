CREATE   FUNCTION project.canClientHaveReservation(@ClientID int, @Products project.OrderMeals readonly)
    RETURNS BIT AS
BEGIN
    IF (@ClientID IN (SELECT CompanyID FROM Companies))
        BEGIN
            RETURN 1
        end
    IF (@ClientID IN (SELECT ClientID FROM IndividualClients))
        BEGIN
            DECLARE @WZ as int;
            SET @WZ = project.getActualWZ();
            DECLARE @Value as float;
            SET @Value = project.getValueOfProducts(@Products);
            DECLARE @WK as int;
            SET @WK = project.getActualWK();
            DECLARE @PreviousOrders as int;
            SELECT @PreviousOrders = COUNT(*) FROM Orders WHERE ClientID = @ClientID
            IF (@PreviousOrders >= @WK) AND (@Value >= @WZ)
                BEGIN
                    RETURN 1
                end
        end
    RETURN 0
END
go

CREATE   FUNCTION project.canOrderHasSeafood(@OrderDate datetime, @ReservationDate datetime, @TakeawayDate datetime)
RETURNS BIT AS
    BEGIN
    DECLARE @Weekday int;
    DECLARE @Days int;
    IF @ReservationDate IS NOT NULL
        BEGIN
            -- Podana jest data rezerwacji
            SET @Days = DATEDIFF(DAY, @OrderDate, @ReservationDate)
            SET @Weekday = DATEPART(WEEKDAY, @ReservationDate)
        END
    IF @TakeawayDate IS NOT NULL
        BEGIN
            -- Podana jest data rezerwacji
            SET @Days = DATEDIFF(DAY, @OrderDate, @TakeawayDate)
            SET @Weekday = DATEPART(WEEKDAY, @TakeawayDate)
        END
    IF (@Weekday IN (5, 6, 7)) AND @Days > 2
        BEGIN
            RETURN 1
        END
    RETURN 0
    END
go

create function project.checkIfClientHasActiveDiscount(@ClientID int)
    returns bit as
begin
    return case
               when (@ClientID in (SELECT DISTINCT ClientID
                                   FROM project.Discounts)) AND ((SELECT DD.EndDate
                                                                  FROM project.Discounts
                                                                           INNER JOIN project.DiscountDetails DD on DD.DiscountID = Discounts.DiscountID
                                                                  WHERE @ClientID = ClientID) >=
                                                                 GETDATE()) AND ((SELECT DD.Avaliable
                                                                                  FROM project.Discounts
                                                                                           INNER JOIN project.DiscountDetails DD on DD.DiscountID = Discounts.DiscountID
                                                                                  WHERE @ClientID = ClientID) =
                                                                                 1)
                   then 1
               else 0
        end
end
go

CREATE   FUNCTION project.customerExists(@CustomerID int)
    RETURNS BIT AS
BEGIN
    IF @CustomerID IN (SELECT ClientID FROM project.Clients)
        BEGIN
            RETURN 1
        END
    RETURN 0
END
go

CREATE   FUNCTION project.getActualWK()
    RETURNS INT AS
BEGIN
    DECLARE @WK as int;
    SELECT @WK = WK FROM WZWK WHERE ValidTo IS NULL
    RETURN @WK
END
go

CREATE   FUNCTION project.getActualWZ()
    RETURNS INT AS
BEGIN
    DECLARE @WZ as int;
    SELECT @WZ = WZ FROM WZWK WHERE ValidTo IS NULL
    RETURN @WZ
END
go

create function project.getFreeTables(@startDate datetime, @endDate datetime)
    returns table as
        return
        select TableNumber
        from project.Tables T
        where TableNumber not in (select TableID
                                  from project.ReservationDetails RD
                                           inner join project.Reservations R2 on R2.ReservationID = RD.ReservationID
                                  where (@startDate < R2.EndDate and @startDate > R2.StartDate) or (@endDate > R2.StartDate and @endDate < R2.EndDate))
go

CREATE   FUNCTION project.getStartDateOfReservation(@ReservationID int)
RETURNS DATETIME AS
    BEGIN
    RETURN (SELECT TOP 1 StartDate FROM
    project.Reservations R
    WHERE R.ReservationID = @ReservationID)
    END
go

CREATE   FUNCTION project.getValueOfProducts(@Products project.OrderMeals readonly)
    RETURNS FLOAT AS
BEGIN
    DECLARE @Value as float;
    SELECT @Value = Quantity * Menus.UnitPrice
    FROM @Products P
             INNER JOIN project.Menus Menus ON Menus.MenuID = P.MenuID
    RETURN ROUND(@Value, 2)
END
go

CREATE   FUNCTION project.haveMealsSomeSeafood(@Meals project.OrderMeals readonly)
    RETURNS BIT AS
BEGIN
    DECLARE @MenuID as int
    DECLARE ProductCursor CURSOR FOR SELECT MenuID FROM @Meals;
    OPEN ProductCursor;
    FETCH NEXT FROM ProductCursor INTO @MenuID;
    WHILE @@FETCH_STATUS = 0
        BEGIN
            IF project.isSeaFoodMeal(@MenuID) = 1
                BEGIN
                   RETURN 1
                END
            FETCH NEXT FROM ProductCursor INTO @MenuID;
        END;
    RETURN 0;
END
go

CREATE   FUNCTION project.isMenuItemAvailable(@MenuID int)
    RETURNS BIT AS
BEGIN
    IF @MenuID IN (SELECT MenuID FROM project.CurrentMenu)
        BEGIN
            RETURN 1
        END
    RETURN 0
END
go

CREATE   FUNCTION project.isMenuItemInStock(@MenuID int, @RequiredQuantity int)
    RETURNS BIT AS
BEGIN
    DECLARE @AvailableQuantity int
    SELECT @AvailableQuantity = UnitInStock
    FROM project.CurrentMenu
    WHERE @MenuID = MenuID
    IF @AvailableQuantity >= @RequiredQuantity
        BEGIN
            RETURN 1
        END
    RETURN 0
END
go

CREATE   FUNCTION project.isSeaFoodMeal(@MenuID int)
    RETURNS BIT AS
BEGIN
    DECLARE @MealID int;
    SELECT @MealID = MealID FROM project.Menus WHERE MenuID = @MenuID
    IF (@MealID IN (SELECT MealID FROM project.SeafoodMeals))
        BEGIN
            RETURN 1
        end
    RETURN 0
END
go

CREATE   FUNCTION project.mealExists(@MealID int)
    RETURNS BIT AS
BEGIN
    IF @MealID IN (SELECT MealID FROM project.Meals)
        BEGIN
            RETURN 1
        END
    RETURN 0
END
go

CREATE   FUNCTION project.orderExists(@OrderID int)
    RETURNS BIT AS
BEGIN
    IF @OrderID IN (SELECT OrderID FROM project.Orders)
        BEGIN
            RETURN 1
        END
    RETURN 0
END
go
