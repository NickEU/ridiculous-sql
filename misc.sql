select * into stuck_transactions
from pg_stat_activity
where (state = 'idle in transaction')
    and xact_start is not null;
	
raise notice stuck_transactions;


/*

BEGIN TRANSACTION;
SELECT id, token_code, "time", open, high, low, close, volume, stat_type
	FROM public."TokenCandleModel"
	ORDER BY id DESC LIMIT 100;

-- COMMIT TRANSACTION;
ROLLBACK TRANSACTION;

*/

select * from "TokenCandleModel"
where stat_type = 2
order by id asc limit 10000;


delete from "TokenCandleModel"
where (stat_type = 2 or stat_type = 3) 
	and time < '2022-06-05 01:00:00'
	and (open is null or high is null or low is null or close is null or volume is null);


