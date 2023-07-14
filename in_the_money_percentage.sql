declare @date date = '2022-09-07';

declare @fromdate datetime = dateadd(hour, -170, convert(datetime, @date, 120));
declare @todate datetime = dateadd(hour, 22, convert(datetime, @date, 120));

declare @trader_id int = 718757;

with trades as (
	SELECT TRADER_ID
			,SUM((TRADER_INCOME - MONEY_INVESTMENT) * ISNULL(c.EXCH_RATE, 1)) AS TRADER_PROFIT_USD
			,SUM(MONEY_INVESTMENT * ISNULL(c.EXCH_RATE, 1)) AS TRADER_VOLUME_USD
			,SUM((TRADER_INCOME - MONEY_INVESTMENT) * ISNULL(c.EXCH_RATE, 1))/
				SUM(MONEY_INVESTMENT * ISNULL(c.EXCH_RATE, 1)) AS TRADER_MARGIN
			,cast(COUNT(
			case	
				when TRADER_INCOME > MONEY_INVESTMENT then TRADER_INCOME
			end) as float) /
			COUNT(TRADER_INCOME) in_the_money_percentage
			,MIN(TRADING_TIME) AS FIRST_TRADE
	FROM TFC_TRADE_ACTIONS ta with (index(IX_TFC_TRADE_ACTIONS_CLOSE_TIME))
	LEFT JOIN T_CURRENCY_EXCH_RATE c ON ta.CURRENCY_ID = c.SRC_CODE AND DEST_CODE = '840'
	WHERE ta.CLOSE_TIME > @fromdate AND ta.CLOSE_TIME < @todate
	AND TRADER_ID = @trader_id
	GROUP BY TRADER_ID
	HAVING SUM((TRADER_INCOME - MONEY_INVESTMENT) * ISNULL(c.EXCH_RATE, 1)) > 1000 OR SUM((TRADER_INCOME - MONEY_INVESTMENT) * ISNULL(c.EXCH_RATE, 1)) < -1000
	--ORDER BY TRADER_PROFIT_USD DESC
	),

transactions AS (
	SELECT SUM(
		case 
			when trans_type in (1, 51) then amount 
		end
		) * ISNULL (c.EXCH_RATE, 1) as deposit_with_canceled,
		SUM(
		case 
			when trans_type in (2, 52) then amount 
		end
		) * ISNULL (c.EXCH_RATE, 1) as wd_with_canceled
	,player_id
	,MAX(trans_id) AS max_trans_id
	--,max(real_money_balance) over (order by trans_id) balance
	FROM TT_REAL_TRANSACTIONS tt
	LEFT JOIN T_CURRENCY_EXCH_RATE c ON tt.CURRENCY_ID = c.SRC_CODE AND DEST_CODE = '840'
	WHERE trans_type IN (1,2,51,52) 
	AND trans_date < dateadd(minute, -1, getdate())
	AND operator_id = 1
	GROUP BY player_id, c.EXCH_RATE
	),

balance AS (
	SELECT real_money_balance, tt.player_id
	FROM TT_REAL_TRANSACTIONS AS tt
	JOIN transactions ON max_trans_id = trans_id
	)


SELECT TRADER_ID
	, TRADER_PROFIT_USD
	, TRADER_VOLUME_USD
	, TRADER_MARGIN
	, in_the_money_percentage
	, deposit_with_canceled
	, wd_with_canceled
	, FIRST_TRADE
	, b.real_money_balance
FROM trades ta
JOIN transactions tt ON ta.TRADER_ID = tt.player_id
JOIN balance b ON tt.player_id = b.player_id