USE classicmodels;

# 구매지표 추출
-- 매출액(일자별, 월별, 연도별)
### 일별 매출액 조회
SELECT 
    O.orderdate, SUM(priceeach * quantityordered), COUNT(1)
FROM
    orders AS O
LEFT JOIN
    orderdetails AS OD ON O.ordernumber = OD.ordernumber
GROUP BY 1
LIMIT 500;

### 월별 매출액 조회 
SELECT 
    SUBSTR(O.orderdate, 1, 7) AS yyyymm,
    SUM(priceeach * quantityordered) AS sales
FROM
    orders AS O
LEFT JOIN
    orderdetails AS OD ON O.ordernumber = OD.ordernumber
GROUP BY 1
ORDER BY 1;
-- substr대신 date_format을 사용해도 된다.
SELECT 
    SUBSTR(orderdate, 1, 7), DATE_FORMAT(orderdate, '%Y-%m')
FROM
    orders;

### 연도별 매출액 조회
SELECT 
    SUBSTR(O.orderdate, 1, 4) yyyy,
    SUM(priceeach * quantityordered) AS sales
FROM
    orders AS O
LEFT JOIN
    orderdetails AS OD ON O.ordernumber = OD.ordernumber
GROUP BY 1
ORDER BY 1;
-- 또는 date_format(A.orderdate, '%Y')

## 구매자수, 구매 건수(일자별, 월별, 연도별)
### 일자별
SELECT 
    orderdate,
    COUNT(DISTINCT customernumber) AS n_purchaser,
    COUNT(ordernumber) AS n_orders
FROM
    orders
GROUP BY 1
ORDER BY 1;
### 월별
SELECT 
    SUBSTR(orderdate, 1, 7) AS yyyymm,
    COUNT(DISTINCT customernumber) AS n_purchaser,
    COUNT(ordernumber) AS n_orders
FROM
    orders
GROUP BY 1
ORDER BY 1;
### 연도별
SELECT 
    SUBSTR(orderdate, 1, 4) AS yyyy,
    COUNT(DISTINCT customernumber) AS n_purchaser,
    COUNT(ordernumber) AS n_orders
FROM
    orders
GROUP BY 1
ORDER BY 1;

## 인당매출액 AMV
### 연도별
SELECT 
    SUBSTR(O.orderdate, 1, 4) AS yyyy,
    COUNT(DISTINCT O.customernumber) AS n_purchaser,
    SUM(priceeach * quantityordered) AS sales,
    SUM(priceeach * quantityordered) / COUNT(DISTINCT O.customernumber) AS AMV
FROM
    orders AS O
LEFT JOIN
    orderdetails AS OD ON O.ordernumber = OD.ordernumber
GROUP BY 1
ORDER BY 1;

## 건당 구매 금액 ATV
### 연도별
SELECT 
    SUBSTR(O.orderdate, 1, 4) AS yyyy,
    COUNT(DISTINCT O.ordernumber) AS n_ordernumber,
    SUM(priceeach * quantityordered) AS sales,
    SUM(priceeach * quantityordered) / COUNT(DISTINCT O.ordernumber) AS ATV
FROM
    orders AS O
LEFT JOIN
    orderdetails AS OD ON O.ordernumber = OD.ordernumber
GROUP BY 1
ORDER BY 1;

# 그룹별 구매 지표 구하기
## 국가별, 도시별 매출액
SELECT 
    C.country, C.city, SUM(priceeach * quantityordered) AS sales
FROM
    orders AS O
LEFT JOIN
    orderdetails AS OD ON O.ordernumber = OD.ordernumber
LEFT JOIN
    customers AS C ON O.customernumber = C.customernumber
GROUP BY 1 , 2
ORDER BY 3 DESC;


SELECT 
    (SELECT country 
    FROM customers 
    WHERE O.customernumber = customernumber) country, 
    (SELECT city 
    FROM customers 
    WHERE O.customernumber = customernumber) city, 
    SUM(priceeach * quantityordered) AS sales
FROM
    orders AS O
LEFT JOIN
    orderdetails AS OD ON O.ordernumber = OD.ordernumber
GROUP BY 1 , 2
ORDER BY 3 DESC;

## 북미 vs 비북미 매출액 비교
SELECT 
    CASE
        WHEN country IN ('USA' , 'CANADA') THEN 'North America'
        ELSE 'Others'
    END AS COUNTRY_GROUP,
    SUM(priceeach * quantityordered) AS sales
FROM
    orders AS O
        LEFT JOIN
    orderdetails AS OD ON O.ordernumber = OD.ordernumber
        LEFT JOIN
    customers AS C ON O.customernumber = C.customernumber
GROUP BY 1
ORDER BY 2 DESC;

# 매출 Top5 국가 및 매출
SELECT *
FROM (
    SELECT 
        country, sales, DENSE_RANK() OVER(ORDER BY sales DESC) AS RNK
    FROM (
        SELECT 
            C.country, SUM(priceeach*quantityordered) AS sales
        FROM 
            orders AS O
        LEFT JOIN 
            orderdetails AS OD
        ON 
            O.ordernumber = OD.ordernumber
        LEFT JOIN 
            customers AS C
        ON 
            O.customernumber = C.customernumber
        GROUP BY 1) as AA
) AS BB
WHERE RNK <= 5;


-- WITH 사용
WITH AA AS (
    SELECT 
        C.country, sum(priceeach*quantityordered) AS sales
    FROM 
        orders AS O
    LEFT JOIN 
        orderdetails AS OD
    ON 
        O.ordernumber = OD.ordernumber
    LEFT JOIN 
        customers AS C
    ON 
        O.customernumber = C.customernumber
    GROUP BY 1)
SELECT *
FROM
    (SELECT 
        country, sales, DENSE_RANK() OVER(ORDER BY sales DESC) AS RNK
    FROM 
        AA
    ) AS BB
WHERE 
    RNK <= 5;

## 재구매율 Retention Rate. 국가별로 구매에 대한 연간 리텐션을 구하라.
SELECT 
    C.country, SUBSTR(A.orderdate, 1, 4) yyyy,
    COUNT(DISTINCT A.customernumber) AS BU_1,
    COUNT(DISTINCT B.customernumber) AS BU_2,
    COUNT(DISTINCT B.customernumber) / COUNT(DISTINCT A.customernumber) AS 1_year_retention_rate
FROM 
    orders as A
LEFT JOIN 
    orders as B
ON 
    A.customernumber = B.customernumber 
    AND SUBSTR(A.orderdate, 1, 4) = SUBSTR(B.orderdate, 1, 4) - 1
LEFT JOIN 
    customers as C
ON 
    A.customernumber = C.customernumber
GROUP BY 1, 2
;

-- 오스트리아의 raw data를 한번 봐보자
SELECT C.country, O.orderNumber, O.customernumber, date_format(orderdate, '%Y')
FROM orders AS O
LEFT JOIN customers AS C 
ON O.customernumber = C.customernumber
WHERE C.country = 'Austria';

# Best Seller. 미국시장에서 역대 누적 판매액이 가장 높은 모델 Top5를 구하라.
WITH product_sales AS (
    SELECT P.productname, sum(quantityordered*priceeach) AS sales
    FROM orders AS O
    LEFT JOIN customers AS C
    ON O.customernumber = C.customernumber
    LEFT JOIN orderdetails AS OD
    ON O.ordernumber = OD.ordernumber
    LEFT JOIN products AS P
    ON OD.productcode = P.productCode
    WHERE C.country = 'USA'
    GROUP BY 1)
SELECT *
FROM (
    SELECT *, ROW_NUMBER() OVER(ORDER BY sales DESC) AS rnk
    FROM product_sales) AS AA
WHERE rnk <= 5;

# Churn Rate
## Churn과 Non-Churn의 수를 구하라.
SELECT 
    CASE
        WHEN diff >= 90 THEN 'CHURN'
        ELSE 'NON_CHURN'
    END CHURN_TYPE,
    COUNT(DISTINCT customernumber) AS n_customer
FROM
    (SELECT 
        Customernumber,
            MAX_ORDER_DATE,
            '2005-06-01' AS END_POINT,
            DATEDIFF('2005-06-01', MAX_ORDER_DATE) AS DIFF
    FROM
        (SELECT 
        customernumber, MAX(orderdate) AS MAX_ORDER_DATE
    FROM
        orders
    GROUP BY 1) AS A) AS AA
GROUP BY 1;

## Churn Rate를 구하라
WITH tmp_table AS (
    select case when diff >= 90 then 'CHURN' ELSE 'NON_CHURN' END CHURN_TYPE,
        count(distinct customernumber) AS n_customer
    FROM (
        SELECT Customernumber, MAX_ORDER_DATE, '2005-06-01' AS END_POINT,
            DATEDIFF('2005-06-01', MAX_ORDER_DATE) AS DIFF
        FROM
            (SELECT customernumber, MAX(orderdate) AS MAX_ORDER_DATE
             FROM orders
             GROUP BY 1) AS A
        ) AS AA
    GROUP BY 1)
SELECT SUM(CASE WHEN CHURN_TYPE = 'CHURN' THEN n_customer ELSE 0 END) AS n_CHURN,
    sum(n_customer) AS n_TOTAL,
    SUM(CASE WHEN CHURN_TYPE = 'CHURN' THEN n_customer ELSE 0 END) / sum(n_customer)  as CHURN_RATE
FROM tmp_table
