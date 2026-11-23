-- 1. Handle divide by zero error
BEGIN TRY
    DECLARE @A INT = 10, @B INT = 0, @RESULT INT;
    SET @RESULT = @A / @B;
    PRINT 'Result = ' + CAST(@RESULT AS VARCHAR(20));
END TRY
BEGIN CATCH
    PRINT 'Error occurs that is - ' + ERROR_MESSAGE();
END CATCH
-- Output: Error occurs that is - Divide by zero error encountered.
GO


-- 2. Convert string to integer and handle the error
BEGIN TRY
    DECLARE @TEXT VARCHAR(20) = 'ABC', @NUM INT;
    SET @NUM = CAST(@TEXT AS INT);
    PRINT 'Converted value = ' + CAST(@NUM AS VARCHAR(20));
END TRY
BEGIN CATCH
    PRINT 'Error occurs that is - ' + ERROR_MESSAGE();
END CATCH
-- Output: Error occurs that is - Conversion failed when converting the varchar value 'ABC' to data type int.
GO


-- 3. Procedure to print the sum of two numbers, handling all error functions
--    Parameters are VARCHAR so the conversion happens INSIDE the procedure
--    and can be caught by its own CATCH block.
CREATE OR ALTER PROCEDURE PR_SUM_OF_TWO
    @NUM1 VARCHAR(20),
    @NUM2 VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @N1 INT = CAST(@NUM1 AS INT);
        DECLARE @N2 INT = CAST(@NUM2 AS INT);

        PRINT 'Sum of ' + @NUM1 + ' and ' + @NUM2 + ' = ' + CAST(@N1 + @N2 AS VARCHAR(20));
    END TRY
    BEGIN CATCH
        PRINT 'Error Number    : ' + CAST(ERROR_NUMBER()   AS VARCHAR(20));
        PRINT 'Error Severity  : ' + CAST(ERROR_SEVERITY() AS VARCHAR(20));
        PRINT 'Error State     : ' + CAST(ERROR_STATE()    AS VARCHAR(20));
        PRINT 'Error Procedure : ' + ISNULL(ERROR_PROCEDURE(), 'N/A');
        PRINT 'Error Line      : ' + CAST(ERROR_LINE()     AS VARCHAR(20));
        PRINT 'Error Message   : ' + ERROR_MESSAGE();
    END CATCH
END
GO

EXEC PR_SUM_OF_TWO '10', '20';     -- Sum of 10 and 20 = 30
EXEC PR_SUM_OF_TWO '10', 'abc';    -- prints all error details
GO


-- 3 (alternative). Parameters declared as INT.
--    A string such as 'abc' fails while the parameter is being bound, i.e.
--    BEFORE the procedure body runs, so the procedure's own CATCH can never
--    see it. The call itself has to be wrapped in TRY...CATCH.
CREATE OR ALTER PROCEDURE PR_SUM_OF_TWO_INT
    @NUM1 INT,
    @NUM2 INT
AS
BEGIN
    SET NOCOUNT ON;
    PRINT 'Sum = ' + CAST(@NUM1 + @NUM2 AS VARCHAR(20));
END
GO

BEGIN TRY
    EXEC PR_SUM_OF_TWO_INT 10, 'abc';
END TRY
BEGIN CATCH
    PRINT 'Error Number    : ' + CAST(ERROR_NUMBER()   AS VARCHAR(20));
    PRINT 'Error Severity  : ' + CAST(ERROR_SEVERITY() AS VARCHAR(20));
    PRINT 'Error State     : ' + CAST(ERROR_STATE()    AS VARCHAR(20));
    PRINT 'Error Procedure : ' + ISNULL(ERROR_PROCEDURE(), 'N/A');
    PRINT 'Error Line      : ' + CAST(ERROR_LINE()     AS VARCHAR(20));
    PRINT 'Error Message   : ' + ERROR_MESSAGE();
END CATCH
GO


-- 4. Handle primary key violation while inserting into STUDENT_INFO
BEGIN TRY
    INSERT INTO STUDENT_INFO (RNO, NAME, BRANCH)
    VALUES (101, 'KIRAN', 'CE');          -- RNO 101 already exists
    PRINT 'Record inserted successfully.';
END TRY
BEGIN CATCH
    PRINT 'Error Message  : ' + ERROR_MESSAGE();
    PRINT 'Error Number   : ' + CAST(ERROR_NUMBER()   AS VARCHAR(20));   -- 2627
    PRINT 'Error Severity : ' + CAST(ERROR_SEVERITY() AS VARCHAR(20));   -- 14
    PRINT 'Error State    : ' + CAST(ERROR_STATE()    AS VARCHAR(20));
END CATCH
GO


-- 5. Throw custom exception if RNO is not available in the database
CREATE OR ALTER PROCEDURE PR_STUDENT_CHECK_RNO
    @RNO INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM STUDENT_INFO WHERE RNO = @RNO)
    BEGIN
        THROW 50005, 'No RNO is available in database.', 1;
    END

    SELECT RNO, NAME, BRANCH FROM STUDENT_INFO WHERE RNO = @RNO;
END
GO

EXEC PR_STUDENT_CHECK_RNO 101;    -- returns the student
EXEC PR_STUDENT_CHECK_RNO 999;    -- Msg 50005: No RNO is available in database.
GO


/* ############################### PART - B ############################### */

-- 6. Update employee salary; throw custom exception if salary <= 0
CREATE OR ALTER PROCEDURE PR_EMPLOYEE_UPDATE_SALARY
    @EID    INT,
    @SALARY DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    IF @SALARY IS NULL OR @SALARY <= 0
    BEGIN
        THROW 50006, 'Salary must be greater than zero.', 1;
    END

    IF NOT EXISTS (SELECT 1 FROM EMPLOYEE WHERE EID = @EID)
    BEGIN
        THROW 50007, 'Employee does not exist.', 1;
    END

    UPDATE EMPLOYEE SET SALARY = @SALARY WHERE EID = @EID;
    PRINT 'Salary updated successfully.';
END
GO

EXEC PR_EMPLOYEE_UPDATE_SALARY 101, 13000;    -- updated
EXEC PR_EMPLOYEE_UPDATE_SALARY 101, 0;        -- Msg 50006
EXEC PR_EMPLOYEE_UPDATE_SALARY 101, -500;     -- Msg 50006
GO


-- 7. Handle foreign key violation while inserting into RESULT
--    Error 547 is used for BOTH foreign key and check constraint violations,
--    so the message text is checked to tell them apart.
BEGIN TRY
    INSERT INTO RESULT (RESULTID, SPI, RNO)
    VALUES (17, 8.5, 999);                -- RNO 999 does not exist in STUDENT_INFO
    PRINT 'Record inserted successfully.';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 547 AND ERROR_MESSAGE() LIKE '%FOREIGN KEY%'
        PRINT 'Foreign key violation: this RNO does not exist in STUDENT_INFO. Add the student first.';
    ELSE IF ERROR_NUMBER() = 547
        PRINT 'Constraint violation: SPI must be between 0 and 10.';
    ELSE
        PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH
GO


-- 8. Handle invalid date format while inserting into DEPOSIT
--    Error 241 = bad format ('ABC'), error 242 = out of range ('2026-02-31')
DECLARE @DT VARCHAR(20) = '2026-02-31';   -- invalid date; try '2026-02-15' for a valid one

BEGIN TRY
    INSERT INTO DEPOSIT (ACTNO, CNAME, BNAME, AMOUNT, ADATE)
    VALUES (112, 'KEVAL', 'MAVDI', 4500, @DT);
    PRINT 'Record inserted successfully.';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (241, 242)
        PRINT 'Invalid date format. Please enter a valid date as YYYY-MM-DD.';
    ELSE
        PRINT 'Error: ' + ERROR_MESSAGE();

    PRINT 'Error Number  : ' + CAST(ERROR_NUMBER() AS VARCHAR(20));
    PRINT 'Error Message : ' + ERROR_MESSAGE();
END CATCH
GO


-- 9. Validate gender; throw error if value is not MALE or FEMALE
CREATE OR ALTER PROCEDURE PR_EMPLOYEE_INSERT
    @EID         INT,
    @FIRSTNAME   VARCHAR(50),
    @LASTNAME    VARCHAR(50),
    @DEPARTMENT  VARCHAR(50),
    @SALARY      DECIMAL(10,2),
    @GENDER      VARCHAR(15),
    @JOININGYEAR DATE,
    @CITY        VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @GENDER IS NULL
       OR UPPER(LTRIM(RTRIM(@GENDER))) NOT IN ('MALE', 'FEMALE')
    BEGIN
        THROW 50001, 'Invalid gender. Only MALE or FEMALE is allowed.', 1;
    END

    INSERT INTO EMPLOYEE
        (EID, FIRSTNAME, LASTNAME, DEPARTMENT, SALARY, CITY, GENDER, JOININGYEAR)
    VALUES
        (@EID, @FIRSTNAME, @LASTNAME, @DEPARTMENT, @SALARY, @CITY,
         UPPER(LTRIM(RTRIM(@GENDER))), @JOININGYEAR);
END
GO

EXEC PR_EMPLOYEE_INSERT 112, 'ANITA', 'DESAI', 'HR', 11000, 'FEMALE', '2025', 'RAJKOT';  -- inserted
EXEC PR_EMPLOYEE_INSERT 113, 'SAM', 'JOSHI', 'IT', 9000, 'OTHER', '2025', 'SURAT';       -- Msg 50001
GO


-- 10. (Part B) Accept joining year; throw custom exception if it is greater than the current year
CREATE OR ALTER PROCEDURE PR_EMPLOYEE_INSERT_CHECK_YEAR
    @EID         INT,
    @FIRSTNAME   VARCHAR(50),
    @LASTNAME    VARCHAR(50),
    @DEPARTMENT  VARCHAR(50),
    @SALARY      DECIMAL(10,2),
    @GENDER      VARCHAR(15),
    @JOININGYEAR INT,
    @CITY        VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CURRENTYEAR INT = YEAR(GETDATE());

    IF @JOININGYEAR > @CURRENTYEAR
    BEGIN
        DECLARE @MSG NVARCHAR(200) =
            CONCAT('Joining year ', @JOININGYEAR,
                   ' cannot be greater than current year ', @CURRENTYEAR, '.');
        THROW 50008, @MSG, 1;
    END

    -- JOININGYEAR column is DATE, so store the year as 1 January of that year
    INSERT INTO EMPLOYEE
        (EID, FIRSTNAME, LASTNAME, DEPARTMENT, SALARY, CITY, GENDER, JOININGYEAR)
    VALUES
        (@EID, @FIRSTNAME, @LASTNAME, @DEPARTMENT, @SALARY, @CITY,
         @GENDER, DATEFROMPARTS(@JOININGYEAR, 1, 1));

    PRINT 'Employee inserted successfully.';
END
GO

EXEC PR_EMPLOYEE_INSERT_CHECK_YEAR 113, 'KAVYA', 'RAVAL', 'IT', 9500, 'FEMALE', 2025, 'SURAT';  -- inserted
EXEC PR_EMPLOYEE_INSERT_CHECK_YEAR 114, 'NIKHIL', 'JANI', 'HR', 9000, 'MALE', 2035, 'RAJKOT';   -- Msg 50008
GO


/* ############################### PART - C ############################### */

-- 10. (Part C) Delete employee; handle exception if employee does not exist
CREATE OR ALTER PROCEDURE PR_EMPLOYEE_DELETE
    @EID INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM EMPLOYEE WHERE EID = @EID)
        BEGIN
            DECLARE @MSG NVARCHAR(200) =
                CONCAT('Employee with EID ', @EID, ' does not exist.');
            THROW 50003, @MSG, 1;
        END

        DELETE FROM EMPLOYEE WHERE EID = @EID;
        PRINT 'Employee deleted successfully.';
    END TRY
    BEGIN CATCH
        THROW;      -- re-raise the original error to the caller
    END CATCH
END
GO

EXEC PR_EMPLOYEE_DELETE 112;     -- deletes the row added by the test in Q9
EXEC PR_EMPLOYEE_DELETE 999;     -- Msg 50003: Employee with EID 999 does not exist.
GO


-- 11. Throw custom exception if department name is NULL during insertion
CREATE OR ALTER PROCEDURE PR_EMPLOYEE_INSERT_CHECK_DEPT
    @EID         INT,
    @FIRSTNAME   VARCHAR(50),
    @LASTNAME    VARCHAR(50),
    @DEPARTMENT  VARCHAR(50),
    @SALARY      DECIMAL(10,2),
    @GENDER      VARCHAR(15),
    @JOININGYEAR DATE,
    @CITY        VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @DEPARTMENT IS NULL OR LTRIM(RTRIM(@DEPARTMENT)) = ''
    BEGIN
        THROW 50004, 'Department name cannot be NULL or empty.', 1;
    END

    INSERT INTO EMPLOYEE
        (EID, FIRSTNAME, LASTNAME, DEPARTMENT, SALARY, CITY, GENDER, JOININGYEAR)
    VALUES
        (@EID, @FIRSTNAME, @LASTNAME, @DEPARTMENT, @SALARY, @CITY, @GENDER, @JOININGYEAR);
END
GO

EXEC PR_EMPLOYEE_INSERT_CHECK_DEPT 115, 'ANITA', 'DESAI', 'HR', 11000, 'FEMALE', '2025', 'RAJKOT';  -- inserted
EXEC PR_EMPLOYEE_INSERT_CHECK_DEPT 116, 'SAM', 'JOSHI', NULL, 9000, 'MALE', '2025', 'SURAT';        -- Msg 50004
GO