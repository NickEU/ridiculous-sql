CREATE OR REPLACE FUNCTION record_updater_creator()
  RETURNS TRIGGER 
AS $$
BEGIN
	IF (NEW.stat_type != 1) THEN
		RETURN NULL;
	END IF;
	PERFORM createTimeRecord(2, 'hour');
	PERFORM createTimeRecord(3, 'day');
	RETURN NULL;
END;
$$
LANGUAGE 'plpgsql';

CREATE TRIGGER candle_insert_trigger
AFTER INSERT ON public."TokenCandleModel"
FOR EACH ROW
EXECUTE PROCEDURE record_updater_creator();