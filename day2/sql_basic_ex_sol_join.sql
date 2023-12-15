/*
JOIN 관련 질의
*/

-- 이제까지 했던 조인은 INNER JOIN(EQUAL JOIN이라고도 한다)
-- CROSS JOIN(Cartesian Product)은 join조건을 기술하지 않은 경우 발생

-- SELF JOIN: 동일한 TABLE을 JOIN하는 경우
-- hr테이블의 EMP에는 직원 정보가 저장되어있다. 
-- BLAKE가 관리하는(Blake가 매니저인) 직원의 이름과 직급을 출력하시오
;
USE hr;
SELECT * FROM EMP
;
SELECT EMP.* FROM EMP
;

SELECT STAFF.*, MANAGER.EMPNO, MANAGER.ENAME
FROM
    EMP AS STAFF,
    EMP AS MANAGER
WHERE STAFF.MGR = MANAGER.EMPNO
    AND MANAGER.ENAME ='BLAKE'
;    
SELECT STAFF.ENAME, STAFF.JOB, MANAGER.ENAME
FROM
    EMP AS STAFF,
    EMP AS MANAGER
WHERE STAFF.MGR = MANAGER.EMPNO
    AND MANAGER.ENAME ='BLAKE'
;    



;
USE madang;
;
-- LEFT OUTER JOIN, RIGHT OUTER JOIN
-- 고객의 이름과 고객이 주문한 도서의 판매가격을 구하시오
SELECT C.name, O.saleprice
FROM Orders as O, Customer as C
WHERE
    O.custid = C.custid;
-- 도서를 구매하지 않은 고객을 포함하여 고객의 이름과 고객이 주문한 도서의 판매가격을 구하시오
# LEFT OUTER JOIN으로 풀기
# RIGHT OUTER JOIN으로 풀기
;
SELECT * FROM Customer;
SELECT * FROM Orders;
SELECT COUNT(DISTINCT custid) FROM Orders;
;
SELECT *
FROM Customer
LEFT JOIN Orders
    ON Customer.custid = Orders.custid
;
#Alias도 활용 가능
SELECT C.name, O.saleprice
FROM Customer as C
LEFT JOIN Orders as O
    ON C.custid = O.custid
;
-- 고객별로 책 구매에 얼마를 지출하였는지를 구하시오. 쿼리결과에 구매내역없는 고객도 포함되어야 함.
-- 첫번째열 고객아이디, 두번째열 이름, 세번째열 책구매에 지출한 금액
SELECT C.custid, C.name, SUM(saleprice)
FROM Customer as C
LEFT JOIN Orders as O
    ON C.custid = O.custid
GROUP BY C.custid, C.name
;

;
select *
from Orders
order by bookid
;

-- FULL OUTER JOIN
-- 누가 어떤 책을 샀는지를 보여주세요. 첫번째 열에는 고객의 이름, 두번째열에는 책의 이름이 나와야 합니다.
-- 구매하지 않은 고객도 표시되어야하며 판매되지 않은 책도 표시되어야 합니다.
-- MYSQL은 FULL JOIN이라는 문법을 지원하지 않습니다.
-- 대신 UNION을 써서 FULL JOIN을 합니다.

SELECT 
    C.name, (SELECT B.bookname 
            FROM Book as B 
            WHERE O.bookid = B.bookid)
FROM 
    Orders as O
RIGHT JOIN 
    Customer as C
ON
    O.custid = C.custid
UNION ALL
SELECT
    (SELECT C.name 
    FROM Customer as C 
    WHERE O.custid = C.custid), B.bookname
FROM 
    Orders as O
RIGHT JOIN 
    Book as B
ON 
    O.bookid = B.bookid
;

-- UNION (합집합 개념)
/*
대한민국에 거주하는 고객 또는 도서를 주문한 고객의 이름을 보이시오
(=대한민국에 거주하는 고객의 이름과 도서를 주문한 고객의 이름을 보이시오) OR
(!=대한민국에 거주하 도서를 주문한 고객의 이름을 보이시오)
*/
SELECT name
FROM Customer
WHERE address LIKE '%대한민국%'
;
SELECT distinct name
FROM Orders as O, Customer as C
WHERE O.custid = C.custid
;


;
# UNION 사용해서 풀어보세요
SELECT name
FROM Customer
WHERE address LIKE '%대한민국%'
UNION
SELECT distinct name
FROM Orders as O, Customer as C
WHERE O.custid = C.custid
;
-- UNION ALL (UNION과 동일하지만 중복을 포함함)
SELECT name
FROM Customer
WHERE address LIKE '%대한민국%'
UNION ALL
SELECT distinct name
FROM Orders as O, Customer as C
WHERE O.custid = C.custid










