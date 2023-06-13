-- Create database
CREATE DATABASE LibraryManagementSystem;
USE LibraryManagementSystem;

-- Create the Books table
CREATE TABLE Books (
  BookID           VARCHAR(10) PRIMARY KEY,
  Title            VARCHAR(100),
  Author           VARCHAR(100),
  PublicationYear  INT,
  Status           VARCHAR(20)
);

-- Create the Members table
CREATE TABLE Members (
  MemberID       VARCHAR(10) PRIMARY KEY,
  Name           VARCHAR(100),
  Address        VARCHAR(200),
  ContactNumber  VARCHAR(20)
);

-- Create the Loans table
CREATE TABLE Loans (
  LoanID      VARCHAR(10) PRIMARY KEY,
  BookID      VARCHAR(10),
  MemberID    VARCHAR(10),
  LoanDate    DATE,
  ReturnDate  DATE,
  FOREIGN KEY (BookID) REFERENCES Books(BookID),
  FOREIGN KEY (MemberID) REFERENCES Members(MemberID)
);

-- Insert sample data into the Books table
INSERT INTO Books (BookID, Title, Author, PublicationYear, Status)
VALUES
  ('B1', 'The Great Gatsby', 'F. Scott Fitzgerald', 1925, 'Available'),
  ('B2', 'To Kill a Mockingbird', 'Harper Lee', 1960, 'Available'),
  ('B3', '1984', 'George Orwell', 1949, 'Loaned'),
  ('B4', 'Pride and Prejudice', 'Jane Austen', 1813, 'Available'),
  ('B5', 'The Catcher in the Rye', 'J.D. Salinger', 1951, 'Loaned'),
  ('B6', 'The Lord of the Rings', 'J.R.R. Tolkien', 1954, 'Available'),
  ('B7', 'Harry Potter and the Philosopher''s Stone', 'J.K. Rowling', 1997, 'Available'),
  ('B8', 'Brave New World', 'Aldous Huxley', 1932, 'Available'),
  ('B9', 'The Hobbit', 'J.R.R. Tolkien', 1937, 'Loaned'),
  ('B10', 'The Chronicles of Narnia', 'C.S. Lewis', 1950, 'Available');

-- Insert sample data into the Members table
INSERT INTO Members (MemberID, Name, Address, ContactNumber)
VALUES
  ('M1', 'John Smith', '123 Main St, City A', '123-456-7890'),
  ('M2', 'Jane Doe', '456 Elm St, City B', '987-654-3210'),
  ('M3', 'David Johnson', '789 Oak St, City C', '555-123-4567'),
  ('M4', 'Sarah Wilson', '321 Pine St, City D', '444-555-6666'),
  ('M5', 'Michael Brown', '567 Maple St, City E', '777-888-9999'),
  ('M6', 'Emily Davis', '890 Cedar St, City F', '222-333-4444'),
  ('M7', 'Robert Miller', '654 Birch St, City G', '111-222-3333'),
  ('M8', 'Jennifer Anderson', '987 Willow St, City H', '999-888-7777'),
  ('M9', 'Christopher Taylor', '321 Oak St, City I', '444-333-2222'),
  ('M10', 'Amanda Thomas', '567 Elm St, City J', '777-666-5555');

-- Insert sample data into the Loans table
INSERT INTO Loans (LoanID, BookID, MemberID, LoanDate, ReturnDate)
VALUES
  ('L1', 'B3', 'M1', '2023-05-15', '2023-06-12'),
  ('L2', 'B5', 'M2', '2023-05-20', '2023-06-10'),
  ('L3', 'B9', 'M3', '2023-05-25', '2023-06-15'),
  ('L4', 'B1', 'M4', '2023-05-30', '2023-06-13'),
  ('L5', 'B3', 'M5', '2023-06-01', '2023-06-14'),
  ('L6', 'B6', 'M6', '2023-06-03', '2023-06-17'),
  ('L7', 'B4', 'M7', '2023-06-06', '2023-06-20'),
  ('L8', 'B2', 'M8', '2023-06-08', '2023-06-16'),
  ('L9', 'B10', 'M9', '2023-06-10', '2023-06-19'),
  ('L10', 'B8', 'M10', '2023-06-12', '2023-06-21');

-- Trigger to update the Status column in the Books table
CREATE TRIGGER UpdateBookStatus
AFTER INSERT ON Loans
FOR EACH ROW
BEGIN
  IF NEW.ReturnDate IS NULL THEN
    UPDATE Books SET Status = 'Loaned' WHERE BookID = NEW.BookID;
  ELSE
    UPDATE Books SET Status = 'Available' WHERE BookID = NEW.BookID;
  END IF;
END;

-- CTE to retrieve names of members who have borrowed at least three books
WITH BorrowedBooks AS (
  SELECT MemberID, COUNT(*) AS TotalBooks
  FROM Loans
  GROUP BY MemberID
)
SELECT Members.Name
FROM Members
JOIN BorrowedBooks ON Members.MemberID = BorrowedBooks.MemberID
WHERE BorrowedBooks.TotalBooks >= 3;

-- User-defined function to calculate overdue days for a given loan
CREATE FUNCTION CalculateOverdueDays(@LoanID VARCHAR(10))
RETURNS INT
AS
BEGIN
  DECLARE @OverdueDays INT;
  SELECT @OverdueDays = DATEDIFF(DAY, ReturnDate, GETDATE())
  FROM Loans
  WHERE LoanID = @LoanID;

  IF @OverdueDays < 0
    SET @OverdueDays = 0;

  RETURN @OverdueDays;
END;

-- View to display details of overdue loans
CREATE VIEW OverdueLoans AS
SELECT Books.Title, Members.Name, CalculateOverdueDays(Loans.LoanID) AS OverdueDays
FROM Loans
JOIN Books ON Loans.BookID = Books.BookID
JOIN Members ON Loans.MemberID = Members.MemberID
WHERE Loans.ReturnDate < GETDATE();

-- Trigger to prevent a member from borrowing more than three books
CREATE TRIGGER PreventBorrowingMoreThanThreeBooks
BEFORE INSERT ON Loans
FOR EACH ROW
BEGIN
  DECLARE @MemberID VARCHAR(10);
  SET @MemberID = NEW.MemberID;

  DECLARE @TotalLoans INT;
  SELECT @TotalLoans = COUNT(*) FROM Loans WHERE MemberID = @MemberID;

  IF @TotalLoans >= 3 THEN
    RAISERROR ('Member is already borrowing three books.', 16, 1);
    ROLLBACK TRANSACTION;
  END IF;
END;
