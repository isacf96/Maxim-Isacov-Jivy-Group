/****** Script for SelectTopNRows command from SSMS  ******/


SELECT TOP 10
	  CONVERT(VARCHAR(7),DATEADD(hour, 2, CLOSE_TIME),120) trading_date
	  ,ast.ASSET_ID
	  ,ast.ASSET_NAME
	  ,def.EXPIRATION_TYPE
	  --,min(ins.OPEN_TIME) open_time
	  ,ISNULL(CONVERT(VARCHAR(8), def.FIXED_DURATION_VALUE, 120),
			CASE
				WHEN dur.DURATION_VALUE = 15
				THEN '15_min'
				WHEN dur.DURATION_VALUE = 60
				THEN '60_min'
				ELSE 'daily'
			END
	  )duration
	  ,ta.RETURN_RATE
	  ,SUM(MONEY_INVESTMENT) volume
      ,SUM(MONEY_INVESTMENT - TRADER_INCOME) site_PnL
	  ,(CASE
			when CONVERT(VARCHAR(7),DATEADD(hour, 2, ta.CLOSE_TIME),120) > '2022-05' THEN 1
			ELSE 0
		END) change

FROM [MarketsPulse].[dbo].[TFC_TRADE_ACTIONS] ta
JOIN TP_PLAYERS pl ON pl.player_id = ta.TRADER_ID
join TFC_OPTION_INSTANCES ins on ins.OPTION_INSTANCE_ID = ta.OPTION_INSTANCE_ID
join TFC_OPTION_DEFINITION def on def.OPTION_DEF_ID = ins.OPTION_DEF_ID
join TFC_DURATIONS dur on def.DURATION_ID  = dur.DURATION_ID
join tfc_assets ast on ast.asset_id = def.ASSET_ID
  
WHERE ta.OPERATOR_ID <> 2
AND pl.account_type <> 1
AND OPTION_TYPE_ID = 1
--AND ast.ASSET_ID = 1
AND ta.CLOSE_TIME > '2022-01-01'
AND CONVERT(VARCHAR(10),DATEADD(hour, 2, ta.CLOSE_TIME),120) < '2022-10-01'
GROUP BY CONVERT(VARCHAR(7),DATEADD(hour, 2, CLOSE_TIME),120)
		,ast.ASSET_NAME
	    ,ast.ASSET_ID
	    ,def.EXPIRATION_TYPE
		,ISNULL(CONVERT(VARCHAR(8), def.FIXED_DURATION_VALUE, 120),
			CASE
				WHEN dur.DURATION_VALUE = 15
				THEN '15_min'
				WHEN dur.DURATION_VALUE = 60
				THEN '60_min'
				ELSE 'daily'
			END
		)
	    ,ta.RETURN_RATE
		
ORDER BY CONVERT(VARCHAR(7),DATEADD(hour, 2, CLOSE_TIME),120) DESC


 --SELECT TOP 10 *
 --FROM TFC_OPTION_DEFINITION