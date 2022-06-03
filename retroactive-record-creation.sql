-- OK so I know this is really bad but I couldn't implement the proper solution with sets so I had to settle for anti-pattern with loops and stuff

-- runner for hourly
do $$
declare
	ts timestamp without time zone;								
begin
	for ts in select * from generate_series('2022-3-27 00:00'::timestamp,'2022-6-3 07:00', '1 hour') loop
		perform getTokenDataOfType('btcusd', 2, 500, ts, ts + interval '60min');	
		--raise notice 'date: %', ts;						
	end loop;
end; $$

-- runner for daily								
do $$
declare
	ts timestamp without time zone;								
begin
	for ts in select * from generate_series('2022-3-27 00:00'::timestamp,'2022-6-4 00:00', '1 day') loop
		perform getTokenDataOfType('ethusd', 3, 500, ts, ts + interval '1day');				
	end loop;
end; $$		

-- proc that inserts new records
create or replace function getTokenDataOfType(
    target_token_code text,
    target_stat_type integer,
    column_limit integer,
    date_from timestamp,
	date_to timestamp
) 
returns table (
		id integer,
		token_code text,
		"time" timestamp(3) without time zone,
		open numeric(22,10),
		high numeric(22,10),
		low numeric(22,10),
		close numeric(22,10),
		volume numeric(22,10),
		stat_type integer
	)
language plpgsql
as $$
declare 
	records public."TokenCandleModel";
begin

insert into public."TokenCandleModel"(token_code, time, open, high, low, close, volume, stat_type)
	select target_token_code, date_from, 
	(select "TokenCandleModel".open from public."TokenCandleModel" 
		where "TokenCandleModel".time = date_from and "TokenCandleModel".token_code = target_token_code and "TokenCandleModel".stat_type = 1 limit 1), 
	max("TokenCandleModel".high), min("TokenCandleModel".low), 
	(select "TokenCandleModel".close from public."TokenCandleModel" 
		where "TokenCandleModel".time = date_to and "TokenCandleModel".token_code = target_token_code and "TokenCandleModel".stat_type = 1 limit 1), 
	sum("TokenCandleModel".volume), target_stat_type 
	from public."TokenCandleModel" where "TokenCandleModel".token_code = target_token_code 
									and "TokenCandleModel".stat_type = 1
									and "TokenCandleModel".time BETWEEN date_from AND date_to;
									
	return query
		select * from public."TokenCandleModel"  
		where "TokenCandleModel".token_code = target_token_code 
			and "TokenCandleModel".stat_type = 1
			and "TokenCandleModel".time BETWEEN date_from AND date_to
		ORDER BY id DESC LIMIT column_limit;
end; $$ 