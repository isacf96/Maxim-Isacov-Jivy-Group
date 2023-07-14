/****** Script for SelectTopNRows command from SSMS  ******/

WITH count_trades AS
(
SELECT [TRADE_ACTION_ID]
      ,[TRADER_ID]
      ,[TRADING_TIME]
	  ,MONEY_INVESTMENT
	  ,pl.player_name
	  ,(SELECT VALUE
			FROM MarketsPulse..TFC_OPTION_DEF_PARAM_VALUES
			WHERE OPTION_DEF_ID = def.OPTION_DEF_ID and OPTION_TYPE_PARAM_ID in (1,20)) payout
	  ,CASE
			WHEN TRADE_TYPE = 1
			AND trading_strike > close_strike
			THEN 0
			WHEN TRADE_TYPE = 2
			AND trading_strike < close_strike
			THEN 0
			ELSE 1
		END site_trade_result
	  ,CASE
			WHEN DATEPART(SECOND, TRADING_TIME) = 0 OR DATEPART(SECOND, TRADING_TIME) = 59 THEN 1
			ELSE 0
		END round_number
  FROM [MarketsPulse].[dbo].[TFC_TRADE_ACTIONS] ta
  JOIN MarketsPulse..TFC_OPTION_INSTANCES ins ON ins.OPTION_INSTANCE_ID = ta.OPTION_INSTANCE_ID
  JOIN MarketsPulse..TFC_OPTION_DEFINITION def ON def.OPTION_DEF_ID = ins.OPTION_DEF_ID
  JOIN MarketsPulse..TP_PLAYERS pl ON ta.TRADER_ID = pl.TRADER_ID
  WHERE TRADING_TIME BETWEEN (DATEADD(HOUR,-24,GETDATE())) AND (GETDATE())
  )
,
ta_pnl AS
(
SELECT *
		,CASE 
			WHEN site_trade_result = 0 
			THEN (-MONEY_INVESTMENT)*payout/100
			ELSE MONEY_INVESTMENT
		END site_pnl
FROM count_trades
)
,
traders AS
(
SELECT TRADER_ID
	,SUM(round_number) cnt_round
	,COUNT(TRADE_ACTION_ID) cnt_ta
	,SUM(site_pnl)/130 site_pnl
FROM ta_pnl
GROUP BY TRADER_ID
)

SELECT TRADER_ID
	,cnt_round
	,cnt_ta
	,(CAST(cnt_round AS FLOAT))/(CAST(cnt_ta AS FLOAT)) round_proportion
	,site_pnl
FROM traders
WHERE cnt_round > 3
ORDER BY --round_proportion DESC
		site_pnl ASC
		,cnt_round DESC 

/*
SELECT TOP (1000) [TRADE_ACTION_ID]
      ,[TRADER_ID]
      ,[OPTION_INSTANCE_ID]
      ,[TRADING_TIME]
	  ,CASE
			WHEN DATEPART(SECOND, TRADING_TIME) = 0 OR DATEPART(SECOND, TRADING_TIME) = 59 THEN 1
			ELSE 0
		END round_number
  FROM [MarketsPulse].[dbo].[TFC_TRADE_ACTIONS]
  WHERE TRADING_TIME BETWEEN (DATEADD(HOUR,-24,GETDATE())) AND (GETDATE())
*/

/*
SELECT TRADER_ID
	,COUNT(TRADE_ACTION_ID) cnt_ta
FROM [MarketsPulse].[dbo].[TFC_TRADE_ACTIONS]
WHERE TRADING_TIME BETWEEN (DATEADD(HOUR,-24,GETDATE())) AND (GETDATE())
AND TRADER_ID = '735371'
GROUP BY TRADER_ID
ORDER BY cnt_ta DESC
*/