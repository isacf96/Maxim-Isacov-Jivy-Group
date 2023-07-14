declare @time_diff int = 20000		-- time difference allowed between 

;with trades as(
SELECT  
	def.ASSET_ID,
	ASSET_NAME,
	TRADER_ID, 
	TRADING_TIME, 
	CLOSE_TIME,
	MONEY_INVESTMENT,
	ta.TRADE_TYPE,
	DATEDIFF(MILLISECOND, TRADING_TIME, LAG(TRADING_TIME) OVER (PARTITION BY def.ASSET_ID ORDER BY TRADING_TIME)) date_diff,
	DATEDIFF(MILLISECOND, CLOSE_TIME, LAG(CLOSE_TIME) OVER (PARTITION BY def.ASSET_ID ORDER BY TRADING_TIME)) close_date_diff,
	(LAG(TRADE_TYPE) OVER (PARTITION BY def.ASSET_ID ORDER BY TRADING_TIME)) next_trade_type
from TFC_TRADE_ACTIONS ta
join TFC_OPTION_INSTANCES ins on ins.OPTION_INSTANCE_ID = ta.OPTION_INSTANCE_ID
join TFC_OPTION_DEFINITION def on def.OPTION_DEF_ID = ins.OPTION_DEF_ID
join tfc_assets ast on ast.asset_id = def.ASSET_ID
WHERE TRADING_TIME BETWEEN '2023-01-04 22:00' AND '2023-01-06 22:00'
and trader_id in (1418961, 1418972, 1419010
)
), 

group_gen AS(
SELECT  *,
	case when next_trade_type%5 = TRADE_TYPE%5 AND date_diff between -@time_diff and @time_diff and close_date_diff between -@time_diff and @time_diff 
			then 0 
			else 1 
		end group_generator
FROM trades
),

group_num AS( 
SELECT *,
SUM(group_generator) OVER (ORDER BY TRADING_TIME ROWS UNBOUNDED PRECEDING) AS group_number
FROM group_gen
)

SELECT group_number, ASSET_NAME, MIN(TRADING_TIME) min_trade_time, MAX(TRADING_TIME) max_trade_time, 
	MIN(CLOSE_TIME) min_close_time, MAX(CLOSE_TIME) max_close_time, COUNT(DISTINCT TRADER_ID) traders, COUNT(*) ta
	--(select distinct ', ' + cast(trader_id as varchar(20)) from group_num where group_number = gn.group_number for xml path (''))
FROM group_num gn
GROUP BY group_number, ASSET_NAME
HAVING COUNT(DISTINCT TRADER_ID) > 1
