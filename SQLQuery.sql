create database customeranalysis;
use customeranalysis;

--check the row counts
select count(*) as rows_2009_2010 from [dbo].[year 2009-2010];
select count(*) as rows_2010_2011 from [dbo].[year 2010-2011];

-- combine both tables and convert types safely
select
	Invoice,StockCode,Description,Quantity,
	coalesce(
		try_convert(datetime2,InvoiceDate,120),
		try_convert(datetime2,InvoiceDate,105)
	)As InvoiceDate,

	try_convert(decimal (10,2),price) AS price,
	Customer_ID,Country,'2009-2010' as sourcesheet
into dbo.retailcombined
from dbo.[year 2009-2010]

union all
select
	Invoice,StockCode,Description,Quantity,
	coalesce(
		try_convert(datetime2,InvoiceDate,120),
		try_convert(datetime2,InvoiceDate,105)
	)As InvoiceDate,

	try_convert(decimal (10,2),price) AS price,
	Customer_ID,Country,'2010-2011' as sourcesheet
from dbo.[year 2010-2011];

-- confirm the conversion worked cleanly
select COUNT(*) as total_rows from dbo.retailcombined;
select COUNT(*) as failed_dated from dbo.retailcombined where InvoiceDate is NULL;
select COUNT(*) as failed_price from dbo.retailcombined where price is NULL;

-- check missing customer id
select COUNT(*)  as missing_customer_id
from dbo.retailcombined where Customer_ID is null;

-- check negative or zero quantity
select COUNT(*) as negative_qty
from dbo.retailcombined where Quantity<=0;

-- check mising description
select COUNT(*) as missing_description
from dbo.retailcombined where Description is null;

-- check exact duplicate rows
select Invoice,StockCode,Description,Quantity,InvoiceDate,Price,Customer_ID,Country,
COUNT(*) as ExactDupVAlue
from dbo.retailcombined
group by Invoice,StockCode,Description,Quantity,InvoiceDate,Price,Customer_ID,Country
having COUNT(*) >1;


-- Duplicate and produce final cleaned table
with deduped as (
	select *,
	ROW_NUMBER() over(
		PARTITION BY Invoice,StockCode,Description,Quantity,InvoiceDate,Price,Customer_ID,Country
		order by (select NULL)
		) as row_num
		from dbo.retailcombined
	)
select Invoice,StockCode,Description,Quantity,InvoiceDate,Price,Customer_ID,Country,sourcesheet
into dbo.retailcleaned
from deduped
where row_num=1;  

select * from dbo.retailcleaned;
	