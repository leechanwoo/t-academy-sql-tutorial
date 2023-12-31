USE instacart;

# 지표 추출
## 전체 주문 건수
## 구매자 수
## 상품별 주문 건수
## 카트에 가장 먼저 넣는 상품 10개
## 시간별 주문 건수
## 첫 구매 후 다음 구매까지 걸린 평균 일수
## 주문 건당 평균 구매 상품 수(UPT, Unit Per Transaction)
## 인당 평균 주문 건수
## 재구매율이 가장 낮은 상품 3위까지
## Department별 재구매 수가 가장 많은 상품 (WITH, DENSE_RANK, OVER, PARTITION 활용 문제, )

# 구매자 분석
## 유저별 10분위 구하기 (ROW_NUMBER, OVER, )
## 각 분위수의 주문 건수 ( ROW_NUMBER )
## VIP 구매 비중

# 상품 분석
## 재구매 비중이 높은 순서대로 상품을 정렬하라. 단, 주문 건수가 10건 이하인 제품은 제외한다.
## 아래 주어진 시간대별로 segmentation 한 뒤,시간대별로 가장 많은 주문이 발생한 제품 TOP 5를 구하여라.
/*
    - 6~8시: 1_BREAKFAST
    - 11~13시: 2_LAUNCH
    - 18~20시: 3_DINNER
    - 나머지 시간대: 4_OTHER_TIME
*/
        

