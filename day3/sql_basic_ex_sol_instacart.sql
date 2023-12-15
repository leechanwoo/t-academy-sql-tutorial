USE instacart;

# 데이터
SELECT * FROM aisles LIMIT 100;
SELECT * FROM departments LIMIT 100;
SELECT * FROM order_products__prior LIMIT 100;
SELECT * FROM orders LIMIT 100;
SELECT * FROM products LIMIT 100;

# 지표 추출
## 전체 주문 건수
SELECT count(order_id) AS '전체 주문 건수'
FROM orders;

/*
데이터의 정합성을 고려해서 데이터베이스를 create했다면 id가 중복될 일이 없겠지만
csv형태로 데이터를 건네받다보면 데이터의 중복이 발생하는 경우도 있다.
이런 사태를 미연에 방지하기 위해 중복유무를 distinct로 체크해주는건 좋은 습관이다.
*/
SELECT count(order_id), count(distinct order_id)
FROM orders;

## 구매자 수
SELECT COUNT(DISTINCT user_id) as BU
FROM orders;

## 상품별 주문 건수
SELECT P.product_name, COUNT(DISTINCT OP.order_id) AS ORDERS_CNT
FROM order_products__prior OP
LEFT JOIN products AS P
ON OP.product_id = P.product_id
GROUP BY 1;


## 카트에 가장 먼저 넣는 상품 10개
SELECT *
FROM (
    SELECT *, ROW_NUMBER() OVER(ORDER BY N_ADD_TO_CART_ORDER DESC) AS RNK
    FROM (
        SELECT product_id, SUM(CASE WHEN add_to_cart_order = 1 THEN 1 ELSE 0 END) AS N_ADD_TO_CART_ORDER
        FROM order_products__prior
        GROUP BY 1) AS A
    ) AS AA
WHERE RNK <= 10;

-- LIMIT 사용
SELECT product_id, SUM(CASE WHEN add_to_cart_order = 1 THEN 1 ELSE 0 END) AS N_ADD_TO_CART_ORDER
FROM order_products__prior
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;


## 시간별 주문 건수
SELECT order_hour_of_day, COUNT(DISTINCT order_id) AS N_ORDER_ID
FROM orders
GROUP BY 1
ORDER BY 1;


## 첫 구매 후 다음 구매까지 걸린 평균 일수
SELECT AVG(days_since_prior_order) AS '첫 구매 후 다음 구매까지 걸린 평균 일수'
FROM orders
WHERE order_number = 2;

## 주문 건당 평균 구매 상품 수(UPT, Unit Per Transaction)
SELECT COUNT(product_id) / COUNT(DISTINCT order_id) AS UPT
FROM order_products__prior;

## 인당 평균 주문 건수
SELECT COUNT(DISTINCT order_id) / COUNT(DISTINCT user_id) AS 'AVG_N_ORDER_BY_USER'
FROM orders;

## 재구매율이 가장 낮은 상품 3위까지
SELECT *
FROM (
    SELECT *, DENSE_RANK() OVER(ORDER BY REORDER_RATIO) AS RNK
    FROM (
        SELECT PRODUCT_ID, SUM(CASE WHEN reordered = 1 THEN 1 ELSE 0 END)/COUNT(1) AS REORDER_RATIO
        FROM order_products__prior
        GROUP BY 1) AS A
    WHERE REORDER_RATIO <> 0
    ) AS AA
WHERE RNK <= 3;


## Department별 재구매 수가 가장 많은 상품
WITH tmp AS (
    SELECT D.department_id, D.department, P.product_id, P.product_name, SUM(reordered) AS N_REORDERED,
        DENSE_RANK() OVER(PARTITION BY department_id ORDER BY SUM(reordered) DESC) AS RNK
    FROM order_products__prior as OP
    LEFT JOIN products as P
    ON OP.product_id = P.product_id
    LEFT JOIN departments as D
    ON P.department_id = D.department_id
    GROUP BY 1,2,3,4
)
SELECT *
FROM tmp
WHERE RNK = 1;


# 구매자 분석
## 유저별 10분위 구하기
SELECT *,
        CASE WHEN RNK BETWEEN 1    AND 316  THEN 'Quantile_1'
             WHEN RNK BETWEEN 317  AND 632  THEN 'Quantile_2'
             WHEN RNK BETWEEN 633  AND 948  THEN 'Quantile_3'
             WHEN RNK BETWEEN 949  AND 1264 THEN 'Quantile_4'
             WHEN RNK BETWEEN 1265 AND 1580 THEN 'Quantile_5'
             WHEN RNK BETWEEN 1581 AND 1895 THEN 'Quantile_6'
             WHEN RNK BETWEEN 1896 AND 2211 THEN 'Quantile_7'
             WHEN RNK BETWEEN 2212 AND 2527 THEN 'Quantile_8'
             WHEN RNK BETWEEN 2528 AND 2843 THEN 'Quantile_9'
             WHEN RNK BETWEEN 2844 AND 3159 THEN 'Quantile_10'
             END AS quantile
FROM (
    SELECT *, ROW_NUMBER() OVER (ORDER BY N_ORDERS DESC) AS RNK
    FROM (
        SELECT user_id, COUNT(DISTINCT ORDER_ID) AS N_ORDERS
        FROM orders
        GROUP BY 1
        ) AS A 
    ) AS AA
;
## 각 분위수의 주문 건수
WITH tmp AS (
    SELECT *,
            CASE WHEN RNK BETWEEN 1    AND 316  THEN 'Quantile_1'
                 WHEN RNK BETWEEN 317  AND 632  THEN 'Quantile_2'
                 WHEN RNK BETWEEN 633  AND 948  THEN 'Quantile_3'
                 WHEN RNK BETWEEN 949  AND 1264 THEN 'Quantile_4'
                 WHEN RNK BETWEEN 1265 AND 1580 THEN 'Quantile_5'
                 WHEN RNK BETWEEN 1581 AND 1895 THEN 'Quantile_6'
                 WHEN RNK BETWEEN 1896 AND 2211 THEN 'Quantile_7'
                 WHEN RNK BETWEEN 2212 AND 2527 THEN 'Quantile_8'
                 WHEN RNK BETWEEN 2528 AND 2843 THEN 'Quantile_9'
                 WHEN RNK BETWEEN 2844 AND 3159 THEN 'Quantile_10'
                 END AS quantile
    FROM (
        SELECT *, ROW_NUMBER() OVER (ORDER BY N_ORDERS DESC) AS RNK
        FROM (
            SELECT user_id, COUNT(DISTINCT ORDER_ID) AS N_ORDERS
            FROM orders
            GROUP BY 1
            ) AS A 
        ) AS AA
)
SELECT quantile, SUM(N_ORDERS)
FROM tmp
GROUP BY 1;

## VIP 구매 비중
WITH tmp AS (
    SELECT *,
            CASE WHEN RNK BETWEEN 1    AND 316  THEN 'Quantile_1'
                 WHEN RNK BETWEEN 317  AND 632  THEN 'Quantile_2'
                 WHEN RNK BETWEEN 633  AND 948  THEN 'Quantile_3'
                 WHEN RNK BETWEEN 949  AND 1264 THEN 'Quantile_4'
                 WHEN RNK BETWEEN 1265 AND 1580 THEN 'Quantile_5'
                 WHEN RNK BETWEEN 1581 AND 1895 THEN 'Quantile_6'
                 WHEN RNK BETWEEN 1896 AND 2211 THEN 'Quantile_7'
                 WHEN RNK BETWEEN 2212 AND 2527 THEN 'Quantile_8'
                 WHEN RNK BETWEEN 2528 AND 2843 THEN 'Quantile_9'
                 WHEN RNK BETWEEN 2844 AND 3159 THEN 'Quantile_10'
                 END AS quantile
    FROM (
        SELECT *, ROW_NUMBER() OVER (ORDER BY N_ORDERS DESC) AS RNK
        FROM (
            SELECT user_id, COUNT(DISTINCT ORDER_ID) AS N_ORDERS
            FROM orders
            GROUP BY 1
            ) AS A 
        ) AS AA
)
SELECT SUM(N_ORDERS) AS TOTAL_ORDERS,
    SUM(CASE WHEN quantile = 'Quantile_1' THEN N_orders ELSE 0 END) AS VIP_ORDERS,
    SUM(CASE WHEN quantile = 'Quantile_1' THEN N_orders ELSE 0 END) / SUM(N_ORDERS) AS VIP_ORDERS_RATIO
FROM tmp
;


# 상품 분석
## 재구매 비중이 높은 순서대로 상품을 정렬하라. 단, 주문 건수가 10건 이하인 제품은 제외한다.
SELECT P.product_id, P.product_name, SUM(reordered)/SUM(1) AS REORDER_RATE, COUNT(DISTINCT order_id) AS N_ORDERS
FROM order_products__prior as OP
LEFT JOIN products as P
ON OP.product_id = P.product_id
GROUP BY P.product_id, P.product_name
HAVING COUNT(DISTINCT order_id) > 10
ORDER BY 3 DESC;

## 아래 주어진 시간대별로 segmentation 한 뒤,시간대별로 가장 많은 주문이 발생한 제품 TOP 5를 구하여라.
/*
    - 6~8시: 1_BREAKFAST
    - 11~13시: 2_LAUNCH
    - 18~20시: 3_DINNER
    - 나머지 시간대: 4_OTHER_TIME
*/
        
WITH tmp AS (
    SELECT 
        CASE WHEN O.order_hour_of_day BETWEEN 6 AND 8 THEN '1_BREAKFAST'
             WHEN O.order_hour_of_day BETWEEN 11 AND 13 THEN '2_LAUNCH'
             WHEN O.order_hour_of_day BETWEEN 18 AND 20 THEN '3_DINNER'
             ELSE '4_OTHER_TIME' END AS TIME_SEGMENTATION
        , P.product_id, P.product_name, COUNT(DISTINCT OP.order_id) as N_ORDERS
    FROM order_products__prior AS OP
    LEFT JOIN orders AS O
    ON OP.order_id = O.order_id
    LEFT JOIN products as P
    ON OP.product_id = P.product_id
    GROUP BY 1, 2, 3
    ORDER BY 1, 4 desc
)
SELECT *
FROM (
    SELECT *, ROW_NUMBER() OVER(PARTITION BY TIME_SEGMENTATION ORDER BY N_ORDERS DESC) AS RNK
    FROM tmp) AS A
WHERE RNK <= 5


