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
-- 국가별, 도시별 매출액
-- 북미 vs 비북미 매출액 비교
-- 매출 Top5 국가 및 매출
-- 재구매율 Retention Rate. 국가별로 구매에 대한 연간 리텐션을 구하라.
-- Best Seller. 미국시장에서 역대 누적 판매액이 가장 높은 모델 Top5를 구하라.


# Churn Rate
-- Churn과 Non-Churn의 수를 구하라.
-- Churn Rate를 구하라
