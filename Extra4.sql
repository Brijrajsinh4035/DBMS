use MCA_123

CREATE TABLE STU_INFO (
    Rno INT PRIMARY KEY,
    Name VARCHAR(50) NOT NULL,
    Branch VARCHAR(10) NOT NULL
);
CREATE TABLE RESULT (
    Rno INT,
    SPI DECIMAL(3, 1) NOT NULL,
    CONSTRAINT FK_Result_StuInfo FOREIGN KEY (Rno) REFERENCES STU_INFO(Rno)
);
CREATE TABLE EMPLOYEE_MASTER (
    EmployeeNo VARCHAR(10) PRIMARY KEY,
    Name VARCHAR(50) NOT NULL,
    ManagerNo VARCHAR(10),
    CONSTRAINT FK_Employee_Manager FOREIGN KEY (ManagerNo) REFERENCES EMPLOYEE_MASTER(EmployeeNo)
);

INSERT INTO STU_INFO (Rno, Name, Branch) VALUES
(101, 'Raju', 'CE'),
(102, 'Amit', 'CE'),
(103, 'Sanjay', 'ME'),
(104, 'Neha', 'EC'),
(105, 'Meera', 'EE'),
(106, 'Mahesh', 'ME');
 
 INSERT INTO EMPLOYEE_MASTER (EmployeeNo, Name, ManagerNo) VALUES
('E01', 'Tarun', NULL),
('E02', 'Rohan', 'E02'),
('E03', 'Priya', 'E01'),
('E04', 'Milan', 'E03'),
('E05', 'Jay', 'E01'),
('E06', 'Anjana', 'E04');

INSERT INTO RESULT (Rno, SPI) VALUES
(101, 8.8),
(102, 9.2),
(103, 7.6),
(104, 8.2),
(105, 7.0);
-- (107, 8.9); -- Commented out to avoid Foreign Key error

--1
select * from STU_INFO,RESULT

--2
select * from STU_INFO inner join RESULT
on STU_INFO.Rno = RESULT.Rno

--3
select * from STU_INFO left join RESULT
on STU_INFO.Rno = RESULT.Rno

--4
select * from STU_INFO right join RESULT
on STU_INFO.Rno = RESULT.Rno

--5
select e.Name 'employee',m.Name'manager' 
from EMPLOYEE_MASTER m inner join EMPLOYEE_MASTER e
on m.EmployeeNo = e.ManagerNo
