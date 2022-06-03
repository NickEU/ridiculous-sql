CREATE OR REPLACE FUNCTION update_or_create_composites()
  RETURNS TRIGGER 
  AS
$$
DECLARE
	hour_record record;
BEGIN
	IF (NEW.stat_type != 1) THEN
		RETURN NULL;
	END IF;	
	select * into hour_record from public."TokenCandleModel" 
		where time = date_trunc('hour', NEW.time) and stat_type = 2 and token_code = NEW.token_code;
		
	IF (hour_record.id is not null) THEN
		-- if hour record already exists we conditionally update the columns with new data
		update public."TokenCandleModel"
		set high = GREATEST(NEW.high, hour_record.high),
			low = LEAST(NEW.low, hour_record.low),
			close = NEW.close,
			volume = hour_record.volume + NEW.volume
		where id = hour_record.id;		
	ELSE
		-- we create a new record for the new hour		
		INSERT INTO public."TokenCandleModel"(token_code, time, open, high, low, close, volume, stat_type)
		VALUES(NEW.token_code, 
			   date_trunc('hour', NEW.time),
			   NEW.open,
			   NEW.high,
			   NEW.low,
			   NEW.close,
			   NEW.volume,
			   2);
	END IF;	
	RETURN NULL;
END;
$$
LANGUAGE 'plpgsql';

CREATE TRIGGER candle_insert_trigger
AFTER INSERT ON public."TokenCandleModel"
FOR EACH ROW
EXECUTE PROCEDURE update_or_create_composites();