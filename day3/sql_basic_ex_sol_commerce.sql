use commerce;

# 데이터
SELECT * FROM commerce;

# 국가별, 상품별 구매자 수 및 매출액
-- 매출액은 반올림해서 나타낼것
-- country의 오름차순, 구매자수의 내림차순, 매출액의 내림차순으로 정렬
SELECT country, stockcode, COUNT(DISTINCT customerID) AS BU, ROUND(SUM(quantity*unitprice)) AS SALES
FROM commerce
GROUP BY 1, 2
ORDER BY 1, 3 DESC, 4 DESC
;

# 특정 상품 구매자가 많이 구매한 상품은?
## 가장 많이 판매된 상품
WITH tmp AS (
    SELECT *, ROW_NUMBER() OVER(ORDER BY QTY DESC) AS RNK
    FROM (
        SELECT stockcode, SUM(quantity) AS QTY
        FROM commerce
        GROUP BY 1) AS A
)
SELECT * FROM tmp
WHERE RNK <= 1;

## 가장 많이 판매된 상품이 포함된 주문내역(invoice)
WITH tmp AS (
    SELECT *, ROW_NUMBER() OVER(ORDER BY QTY DESC) AS RNK
    FROM (
        SELECT stockcode, SUM(quantity) AS QTY
        FROM commerce
        GROUP BY 1) AS A
)
SELECT distinct InvoiceNo 
FROM commerce
WHERE stockcode = (SELECT stockcode FROM tmp WHERE RNK <= 1)
;

## 가장 많이 판매된 상품과 함께 판매된 다른 상품
WITH tmp AS (
    SELECT *, ROW_NUMBER() OVER(ORDER BY QTY DESC) AS RNK
    FROM (
        SELECT stockcode, SUM(quantity) AS QTY
        FROM commerce
        GROUP BY 1) AS A
)
SELECT stockcode, sum(quantity)
FROM commerce
WHERE invoiceno IN (
    SELECT distinct InvoiceNo 
    FROM commerce
    WHERE stockcode = (SELECT stockcode FROM tmp WHERE RNK <= 1)
    )
GROUP BY 1
ORDER BY 2 DESC
;

# 국가별 재구매율(리텐션)
SELECT A.country, substr(A.invoicedate, 1, 4 ) AS YY, 
        COUNT(distinct B.customerID)/COUNT(DISTINCT A.customerID) AS RETENTION_RATE
FROM (
    SELECT DISTINCT country, invoicedate, customerid
    FROM commerce
    ) AS A
LEFT JOIN (
    SELECT DISTINCT country, invoicedate, customerid
    FROM commerce
    ) AS B
ON SUBSTR(A.invoicedate, 1, 4) = SUBSTR(B.invoicedate, 1, 4) - 1
    AND A.country = B.country
    AND A.customerid = B.customerid
WHERE SUBSTR(A.invoicedate, 1, 4)  = 2010
GROUP BY 1, 2
ORDER BY 1, 2
;

# 코호트 분석
## 고객별 첫 구매일 구하기
SELECT customerid, MIN(invoicedate) AS FIRST_PURCHASE_DATE
FROM commerce
GROUP BY 1
ORDER BY 2, 1 
;
## 고객id, 구매일, 판매액
SELECT customerid, invoicedate, unitprice*quantity AS SALES
FROM commerce;

## 코호트 분석을 위한 테이블 생성하기
SELECT *
FROM (
    SELECT customerid, MIN(invoicedate) AS FIRST_PURCHASE_DATE
    FROM commerce
    GROUP BY 1
    ORDER BY 2, 1 
) AS A
LEFT JOIN (
    SELECT customerid, invoicedate, unitprice*quantity AS SALES
    FROM commerce
) AS B
ON A.customerid = B.customerid
;
## 월단위 코호트 분석하기
SELECT SUBSTR(FIRST_PURCHASE_DATE, 1, 7) AS YYYYMM,
    TIMESTAMPDIFF(MONTH, FIRST_PURCHASE_DATE, invoicedate) AS MONTH_DIFF,
    COUNT(DISTINCT A.customerid) AS BU,
    ROUND(SUM(sales)) AS SALES
FROM (
    SELECT customerid, MIN(invoicedate) AS FIRST_PURCHASE_DATE
    FROM commerce
    GROUP BY 1
    ORDER BY 2, 1 
) AS A
LEFT JOIN (
    SELECT customerid, invoicedate, unitprice*quantity AS SALES
    FROM commerce
) AS B
ON A.customerid = B.customerid
GROUP BY 1, 2;

# 고객 세그먼트
## RFM
SELECT customerid, datediff('2011-12-01', MAX_INVOICEDATE) AS Recency,
    Frequency, Monetary
FROM (
    SELECT customerid, MAX(invoicedate) AS MAX_INVOICEDATE,
            COUNT(distinct invoiceno) AS Frequency,
            ROUND(SUM(quantity*unitprice)) AS Monetary
    FROM commerce
    GROUP BY 1
) AS A
ORDER BY 1
;


## 재구매 segment
### 먼저 고객별, 제품별로 몇 개 년도에서 구매가 발생했는지를 구해주세요.
SELECT customerid, stockcode, COUNT(DISTINCT substr(invoicedate, 1, 4)) AS UNIQUE_YYYY
FROM commerce
GROUP BY 1, 2;

### 재구매 segment 나누기
SELECT customerid, MAX(UNIQUE_YYYY) - 1 AS repurcahse_segmentation
FROM (
    SELECT customerid, stockcode, COUNT(DISTINCT substr(invoicedate, 1, 4)) AS UNIQUE_YYYY
    FROM commerce
    GROUP BY 1, 2) AS A
GROUP BY customerid;
    
# 일자별 첫 구매수 
SELECT FIRST_PURCHASE_DATE, COUNT(DISTINCT customerid) AS FIRST_BU
FROM (
    SELECT customerid, MIN(invoicedate) AS FIRST_PURCHASE_DATE
    FROM commerce
    GROUP BY 1) AS A
GROUP BY 1;

# 상품별 첫 구매 수
SELECT stockcode, COUNT(DISTINCT customerid) AS FIRST_BU
FROM (
    SELECT *
    FROM (
        SELECT *, DENSE_RANK() OVER(PARTITION BY customerid ORDER BY FIRST_PURCHASE_DATE) AS RNK
        FROM (
            SELECT customerid, stockcode, MIN(invoicedate) AS FIRST_PURCHASE_DATE
            FROM commerce
            GROUP BY 1, 2
        ) AS A
    ) AS AA
    WHERE RNK = 1
) AS AAA
GROUP BY 1
ORDER BY 2 DESC;

# 첫 구매 후 이탈하는 고객 비중
## 이탈률
SELECT SUM(CASE WHEN N_ORDER_DATE = 1 THEN 1 ELSE 0 END) / SUM(1) AS BOUNCE_RATE
FROM (
    SELECT customerid, COUNT(distinct invoicedate) AS N_ORDER_DATE
    FROM commerce
    GROUP BY 1
) AS A;
## 국가별 이탈률
SELECT country, SUM(CASE WHEN N_ORDER_DATE = 1 THEN 1 ELSE 0 END) / SUM(1) AS BOUNCE_RATE
FROM (
    SELECT customerid, country, COUNT(distinct invoicedate) AS N_ORDER_DATE
    FROM commerce
    GROUP BY 1, 2
) AS A
GROUP BY 1
ORDER BY 1
;

# 판매량
SELECT T2011.stockcode, T2011.QTY AS QTY_2011, T2010.QTY AS QTY_2010, T2011.QTY/T2010.QTy -1 AS QTY_INCREASE_RATE
FROM (
    SELECT stockcode, SUM(QUANTITY) AS QTY
    FROM commerce
    WHERE SUBSTR(invoicedate, 1, 4) = '2011'
    GROUP BY 1
) AS T2011
LEFT JOIN (
    SELECT stockcode, SUM(quantity) AS QTY
    FROM commerce
    WHERE SUBSTR(invoicedate, 1, 4) = '2010'
    GROUP BY 1
) AS T2010
ON T2011.stockcode = T2010.stockcode;

## 판매량이 2010년 대비 2011년에 20%이상 증가한 상품 리스트
    WITH tmp AS (
    SELECT T2011.stockcode, T2011.QTY AS QTY_2011, T2010.QTY AS QTY_2010, T2011.QTY/T2010.QTy -1 AS QTY_INCREASE_RATE
    FROM (
        SELECT stockcode, SUM(QUANTITY) AS QTY
        FROM commerce
        WHERE SUBSTR(invoicedate, 1, 4) = '2011'
        GROUP BY 1
    ) AS T2011
    LEFT JOIN (
        SELECT stockcode, SUM(quantity) AS QTY
        FROM commerce
        WHERE SUBSTR(invoicedate, 1, 4) = '2010'
        GROUP BY 1
    ) AS T2010
    ON T2011.stockcode = T2010.stockcode
    ORDER BY 1
)
SELECT *
FROM tmp
WHERE QTY_INCREASE_RATE >= 0.2
ORDER BY 4, 2 DESC;

