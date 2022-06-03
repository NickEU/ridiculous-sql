create or replace function createTimeRecord(
    target_stat_type integer,
    interval_val text
) RETURNS "void" 
language plpgsql
as $$
declare 
	time_record record;
begin
	select * into time_record from public."TokenCandleModel" 
			where time = date_trunc(interval_val, NEW.time) and stat_type = target_stat_type and token_code = NEW.token_code;
		
	IF (time_record.id is not null) THEN
		-- if time record already exists we conditionally update the columns with new data
		update public."TokenCandleModel"
		set high = GREATEST(NEW.high, time_record.high),
			low = LEAST(NEW.low, time_record.low),
			close = NEW.close,
			volume = time_record.volume + NEW.volume
		where id = time_record.id;		
	ELSE
		-- we create a new record for the new time period		
		INSERT INTO public."TokenCandleModel"(token_code, time, open, high, low, close, volume, stat_type)
		VALUES(NEW.token_code, 
			   date_trunc(interval_val, NEW.time),
			   NEW.open,
			   NEW.high,
			   NEW.low,
			   NEW.close,
			   NEW.volume,
			   target_stat_type);
	END IF;	
end; $$ 