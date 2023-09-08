CREATE USER uservest;
CREATE DATABASE vest;
GRANT ALL PRIVILEGES ON DATABASE vest TO uservest;
ALTER USER postgres with PASSWORD 'postgres';
ALTER USER uservest with PASSWORD 'postgres';

\connect vest
-- public.orders definition

CREATE TABLE public.orders (
	id varchar NOT NULL,
	id_user varchar NOT NULL,
	transaction_type varchar NOT NULL,
	stock_symbol varchar NOT NULL,
	stock_units integer NOT NULL,
	stock_price REAL NOT NULL,
	date_transaction timestamp NOT NULL,
	CONSTRAINT orders_pk PRIMARY KEY (id)
);

CREATE OR REPLACE FUNCTION public.f_create_registro(p_id character varying, p_id_user character varying, p_transaction_type character varying, p_stock_symbol character varying, p_stock_units integer, p_stock_price real, p_date_transaction timestamp without time zone)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
	declare
		v_error varchar := '';
		v_stocks int;
		my_result json;
	begin
		begin
			
			if(p_transaction_type = 'SL') then
			
				select coalesce(sum(stock_units),0) into v_stocks from orders where stock_symbol = p_stock_symbol and id_user = p_id_user;
				
				if(v_stocks <= (p_stock_units*-1)) then
					v_error := 'Dont enought stocks to sell'; 
				end if;
			
			end if;
			
			if(v_error = '') then
				INSERT INTO public.orders
				(id, id_user, transaction_type, stock_symbol, stock_units, stock_price, date_transaction)
				VALUES(p_id, p_id_user, p_transaction_type, p_stock_symbol, p_stock_units, p_stock_price, p_date_transaction);
			end if;
		exception 
			   when others then
			      v_error := sqlerrm;		     
		end;
		
		SELECT
		    json_build_object(
		        'error', (v_error)
		    ) into my_result;
	
		return my_result;
	END;
$function$
;

