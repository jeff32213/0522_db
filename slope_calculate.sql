CREATE or ALTER FUNCTION [dbo].[slope_calculate]
(	
	@company varchar(10),
	@begin_date date,
	@end_date date
)
RETURNS real
AS
BEGIN

	-- @days:兩日之間的開市天數
	DECLARE @days int = (
		SELECT COUNT(*) FROM [dbo].[calendar] 
		WHERE [date] > @begin_date AND [day_of_stock] != -1 AND [date] <= @end_date
	)

	DECLARE @begin_price real = (SELECT c FROM stock_data_2021_2022 WHERE stock_code = @company AND date = @begin_date)
	DECLARE @end_price real = (SELECT c FROM stock_data_2021_2022 WHERE stock_code = @company AND date = @end_date)

	DECLARE @result real = (@end_price - @begin_price) / @days
	return @result
END;
