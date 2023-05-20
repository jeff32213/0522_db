CREATE or ALTER FUNCTION [dbo].[slope_trend]
(
	@company varchar(10),
	@interval_size int, 
	@StatementType NVARCHAR(20) = ''
)
RETURNS @Result_Table TABLE
(
	start_date date,
	start_day_price real,
	end_date date,
	end_day_price real,
	slop real,
	trend NVARCHAR (20)
)
AS
BEGIN
	DECLARE @date_select Table(
		date date Not Null,
		close_price real Not null
	)
	IF @StatementType = 'Extremum_MAX'
		BEGIN
			INSERT @date_select (date, close_price)
			SELECT date, close_price
			FROM dbo.find_max_min(@company)
			WHERE max_min=1
			order by date desc
		END
	ELSE IF @StatementType = 'Extremum_MIN'
		BEGIN
			INSERT @date_select (date, close_price)
			SELECT date, close_price
			FROM dbo.find_max_min(@company)
			WHERE max_min = 0
			order by date desc
		END
	ELSE IF @StatementType = 'Interval'
		Begin
			INSERT @date_select(date, close_price)
			SELECT T1.date, T1.c FROM(
				SELECT ROW_NUMBER() OVER (ORDER BY date DESC) AS ROW, date,c
				FROM [dbo].[stock_data_2021_2022]
				WHERE stock_code = @company
			)T1
			WHERE (T1.ROW % @interval_size)=1
		END

	INSERT INTO @Result_Table(start_date, start_day_price, end_date, end_day_price)
	SELECT T2.date, T2.close_price, T1.date, T1.close_price FROM @date_select AS T1
	CROSS APPLY (
		SELECT TOP 1 * FROM @date_select
		where date < T1.date
		order by date DESC	
	) T2
	
	UPDATE @Result_Table
	SET slop = [dbo].[slope_calculate](@company, start_date, end_date)
	UPDATE @Result_Table SET trend =(
		Case
			WHEN T1.slop > T2.slop and T1.slop >0 and T2.slop>0 THEN '價格加速上漲'
			WHEN T1.slop < T2.slop and T1.slop >0 and T2.slop>0 THEN '上漲速度趨緩'
			WHEN T1.slop >0 and T2.slop<0 THEN '轉為上漲'
			WHEN T1.slop > T2.slop and T1.slop < 0 and T2.slop<0 THEN '下跌速度趨緩'
			WHEN T1.slop < T2.slop and T1.slop <0 and T2.slop<0 THEN '價格加速下跌'
			WHEN T1.slop <0 and T2.slop>0 THEN '轉為下跌'
			ELSE '狀況不變'
		END
	)
	FROM @Result_Table AS T1
	CROSS APPLY(
		SELECT TOP 1 * FROM  @Result_Table
		where start_date < T1.start_date
		order by start_date DESC	
		)T2
	return
END;
