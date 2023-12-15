USE exercise;

# 데이터
SELECT *
FROM review;
# Division별 평점 분포 계산
-- 칼럼명에 공백이나 한글이 들어갈경우 `기호(숫자 1 왼쪽)로 감싸줍니다.
SELECT `Clothing ID`, `Review Text`, `Division Name`
FROM review
LIMIT 10;

## Division Name별 평균 평점
SELECT `Division Name`, AVG(Rating) AS AVG_RATE
FROM review
GROUP BY 1
ORDER BY 2 DESC;

## Department별 평균 평점 
SELECT `Department Name`, AVG(Rating) AS AVG_RATE
FROM review
GROUP BY 1
ORDER BY 2 DESC;

## Trend 리뷰중 3점 이하 리뷰
### Department가 Trend인 리뷰중 3점 이하 리뷰를 구하세요.
SELECT *
FROM review
WHERE `Department Name` = 'Trend'
    AND rating <= 3;
    
### (CASE WHEN 구문 활용) 먼저 고객의 나이를 아래 구간대로 그룹핑해주세요.     
SELECT id, AGE, 
    CASE WHEN AGE BETWEEN 0 AND 9 THEN '0009'
            WHEN AGE BETWEEN 10 AND 19 THEN '10'
            WHEN AGE BETWEEN 20 AND 29 THEN '20'
            WHEN AGE BETWEEN 30 AND 39 THEN '30'
            WHEN AGE BETWEEN 40 AND 49 THEN '40'
            WHEN AGE BETWEEN 50 AND 59 THEN '50'
            WHEN AGE BETWEEN 60 AND 69 THEN '60'
            WHEN AGE BETWEEN 70 AND 79 THEN '70'
            WHEN AGE BETWEEN 80 AND 89 THEN '80'
            WHEN AGE BETWEEN 90 AND 99 THEN '90'
            ELSE 'over100' END AS AGEBAND
FROM review;

### (FLOOR 함수 활용) 고객의 나이를 10살단위로 그룹핑해주세요.
SELECT id, AGE, FLOOR(AGE/10)*10 AS AGEBAND
FROM review;
;

### Department가 Trend인 리뷰 중 평점 3점 이하 리뷰의 연령 분포를 구하세요.
SELECT FLOOR(AGE/10)*10 AS AGEBAND, COUNT(1) AS under_3_CNT
FROM review
WHERE `Department Name` = 'Trend' AND rating <= 3
GROUP BY 1
ORDER BY 1
;


### Department가 Trend인 리뷰에서, 연령대별로 '리뷰수', '평점 3점 이하 리뷰수', '평점 3점 이하 리뷰 비중'을 구하세요. (NULL값의 경우 0으로 표시하세요.)
-- with문 사용
WITH total AS (
        SELECT FLOOR(AGE/10)*10 AS AGEBAND, COUNT(1) AS CNT
        FROM review
        WHERE `Department Name` = 'Trend'
        GROUP BY 1
        ORDER BY 1),
    under_3 AS (
        SELECT FLOOR(AGE/10)*10 AS AGEBAND, COUNT(1) AS under_3_CNT
        FROM review
        WHERE `Department Name` = 'Trend' AND rating <= 3
        GROUP BY 1
        ORDER BY 1)
SELECT total.AGEBAND, CNT AS '전체 리뷰 수', IFNULL(under_3_CNT, 0) AS '3점 이하 리뷰 수', IFNULL(under_3_CNT/CNT, 0) AS '3점 이하 리뷰 비중'
FROM total
LEFT JOIN under_3
ON total.AGEBAND = under_3.AGEBAND;

-- WITH문 사용 X
SELECT FLOOR(AGE/10)*10 AS AGEBAND,
    COUNT(1) AS CNT,
    COUNT(CASE WHEN rating <= 3 THEN 1 ELSE NULL END) AS under_3_CNT
FROM review
WHERE `Department Name` = 'Trend'
GROUP BY 1
ORDER BY 1;

### Department가 Trend인 리뷰에서 30대 40대가 3점 이하 평점을 준 리뷰의 내용을 확인하세요.
SELECT AGE, FLOOR(AGE/10)*10 AS AGEBAND, TITLE, `Review Text`
FROM review
WHERE `Department Name` = 'Trend'
    AND FLOOR(AGE/10)*10 IN (30, 40)
    AND rating <= 3
;    
# 평점이 낮은 상품의 주요 Complain
## Department별로 평균 평점이 가장 낮은 상품을 3개씩 조회해주세요.
WITH tmp AS (
    SELECT *, ROW_NUMBER() OVER(PARTITION BY `Department Name` ORDER BY AVG_RATE) AS RNK
    FROM (
        SELECT `Department Name`, `Clothing ID`, AVG(rating) AS AVG_RATE
        FROM review
        GROUP BY 1, 2
        ) AS A   
    )
SELECT *
FROM tmp
WHERE RNK <= 3
;

## 위에서 Department별로 평균 평점이 가장 낮은 상품 3개의 Clothing ID를 구했습니다.
## 이를 활용해 Department별로 평균 평점이 가장 낮은 상품 3개의 Review Text를 조회해주세요.
WITH tmp AS (
    SELECT *, ROW_NUMBER() OVER(PARTITION BY `Department Name` ORDER BY AVG_RATE) AS RNK
    FROM (
        SELECT `Department Name`, `Clothing ID`, AVG(rating) AS AVG_RATE
        FROM review
        GROUP BY 1, 2
        ) AS A   
    )
SELECT R.`Clothing ID`, R.rating, R.Title, R.`Review Text`
FROM tmp as T
LEFT JOIN review as R
ON T.`Clothing ID` = R.`Clothing ID`
WHERE RNK <= 3
;   
-- 서브쿼리사용
WITH tmp AS (
    SELECT *, ROW_NUMBER() OVER(PARTITION BY `Department Name` ORDER BY AVG_RATE) AS RNK
    FROM (
        SELECT `Department Name`, `Clothing ID`, AVG(rating) AS AVG_RATE
        FROM review
        GROUP BY 1, 2
        ) AS A   
    )
SELECT `Clothing ID`, Rating, Title, `Review Text`
FROM review
WHERE `Clothing ID` IN (SELECT `Clothing ID` FROM tmp WHERE RNK <= 3)    
;

# 연령별 Worst Department
## Trend를 제외한 Department중에서, 연령대별로 평균 평점이 가장 낮은 Department를 구하시오. 
WITH tmp_table AS (
    SELECT *, ROW_NUMBER() OVER(PARTITION BY AGEBAND ORDER BY AVG_RATING) AS RNK
    FROM (
        SELECT FLOOR(AGE/10)*10 AS AGEBAND, `Department Name`, AVG(RATING) AS AVG_RATING
        FROM review
        WHERE `Department Name` <> 'Trend'
        GROUP BY 1,2
        ) AS AA
)
SELECT *
FROM tmp_table
WHERE RNK = 1;

# 리뷰 조작
## 평균평점 4.2미만인 Department Name의 평균 평점을 4.2로 만들기 위해서 Department Name별로 몇 개의 5점 평점이 필요한지를 구하세요. 
WITH tmp AS (
    select `Department Name`, count(1) AS n_rating, AVG(Rating) AS avg_rating, 4.2 AS target_rating
    from review
    GROUP BY 1
    HAVING AVG(Rating) < 4.2
)
SELECT `Department Name`,
        n_rating AS '현재 평점 수',
        avg_rating AS '현재 평균 평점',
        target_rating AS '목표 평균 평점',
        (target_rating*n_rating -  avg_rating*n_rating) / (5 - target_rating) AS '필요한 5점 평점 수',
        CEILING((target_rating*n_rating -  avg_rating*n_rating) / (5 - target_rating)) AS '가짜리뷰업체에 요청할 5점 평점 수'
FROM tmp
;

# 사이즈 컴플레인
## review text에 size라는 단어 언급 유무를 size_yn이라는 칼럼을 통해 나타내시오.
SELECT `review text`,
        CASE WHEN `review text` LIKE '%size%' THEN 1 ELSE 0 END AS size_yn
FROM review

;
## 전체 리뷰 수와 전체 리뷰중 size라는 단어가 언급된 리뷰가 몇 건인지를 구하시오.
SELECT count(1) AS N_TOTAL,
    -- SUM(CASE WHEN `review text` LIKE '%size%' THEN 1 ELSE 0 END) AS N_SIZE,
    COUNT(CASE WHEN `review text` LIKE '%size%' THEN 1 ELSE NULL END) AS N_SIZE
FROM review
;

## 좀 더 쪼개서 확인해보고자 합니다. size란 단어 말고도 large, loose, small, tight란 단어에 대해서도 숫자를 확인해주세요.
SELECT count(1) AS N_TOTAL,
    SUM(CASE WHEN `review text` LIKE '%size%' THEN 1 ELSE 0 END) AS N_SIZE,
    SUM(CASE WHEN `review text` LIKE '%large%' THEN 1 ELSE 0 END) AS N_LARGE,
    SUM(CASE WHEN `review text` LIKE '%loose%' THEN 1 ELSE 0 END) AS N_LOOSE,
    SUM(CASE WHEN `review text` LIKE '%small%' THEN 1 ELSE 0 END) AS N_SMALL,
    SUM(CASE WHEN `review text` LIKE '%tight%' THEN 1 ELSE 0 END) AS N_TIGHT
FROM review
;

## 위 결과를 연령대별, Department별로 쪼개서 구해주세요.
SELECT
    FLOOR(AGE/10)*10 AS AGEBAND,
    `Department Name`,
    count(1) AS N_TOTAL,
    SUM(CASE WHEN `review text` LIKE '%size%' THEN 1 ELSE 0 END) AS N_SIZE,
    SUM(CASE WHEN `review text` LIKE '%large%' THEN 1 ELSE 0 END) AS N_LARGE,
    SUM(CASE WHEN `review text` LIKE '%loose%' THEN 1 ELSE 0 END) AS N_LOOSE,
    SUM(CASE WHEN `review text` LIKE '%small%' THEN 1 ELSE 0 END) AS N_SMALL,
    SUM(CASE WHEN `review text` LIKE '%tight%' THEN 1 ELSE 0 END) AS N_TIGHT
FROM review
GROUP BY 1, 2
ORDER BY 1, 2
;

## 위 결과를 개수가 아닌 비율로 구해주세요.
SELECT
    FLOOR(AGE/10)*10 AS AGEBAND,
    `Department Name`,
    SUM(CASE WHEN `review text` LIKE '%size%' THEN 1 ELSE 0 END)/count(1) AS N_SIZE_PCT,
    SUM(CASE WHEN `review text` LIKE '%large%' THEN 1 ELSE 0 END)/count(1) AS N_LARGE_PCT,
    SUM(CASE WHEN `review text` LIKE '%loose%' THEN 1 ELSE 0 END)/count(1) AS N_LOOSE_PCT,
    SUM(CASE WHEN `review text` LIKE '%small%' THEN 1 ELSE 0 END)/count(1) AS N_SMALL_PCT,
    SUM(CASE WHEN `review text` LIKE '%tight%' THEN 1 ELSE 0 END)/count(1) AS N_TIGHT_PCT
FROM review
GROUP BY 1, 2
ORDER BY 1, 2
;


# SIZE관련 얘기가 가장 많은 제품
## 리뷰가 10건 이상 달린 제품들의 리뷰 텍스트에서 'size, large, loose, small, tight' 단어 포함 비중을 구하라. 리뷰내 'size' 포함 비율이 높은 순서로 정렬하라.
SELECT
    `Clothing ID`,
    count(1) AS N_TOTAL,
    SUM(CASE WHEN `review text` LIKE '%size%' THEN 1 ELSE 0 END)/count(1) AS N_SIZE_PCT,
    SUM(CASE WHEN `review text` LIKE '%large%' THEN 1 ELSE 0 END)/count(1) AS N_LARGE_PCT,
    SUM(CASE WHEN `review text` LIKE '%loose%' THEN 1 ELSE 0 END)/count(1) AS N_LOOSE_PCT,
    SUM(CASE WHEN `review text` LIKE '%small%' THEN 1 ELSE 0 END)/count(1) AS N_SMALL_PCT,
    SUM(CASE WHEN `review text` LIKE '%tight%' THEN 1 ELSE 0 END)/count(1) AS N_TIGHT_PCT
FROM review
GROUP BY 1
HAVING count(1) >= 10
ORDER BY 3 DESC
;

