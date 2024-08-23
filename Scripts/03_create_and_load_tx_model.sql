use billups_test
go

if (OBJECT_ID('country') is null)
	create table country (
		country_id int primary key not null identity(1,1),
		country_code char(2) not null
	)
go

if (OBJECT_ID('city') is null)
	create table city (
		city_id int primary key not null identity(1,1),
		city_name varchar(20) not null
	)
go

if (OBJECT_ID('region') is null)
	create table region (
		region_id int primary key not null identity(1,1),
		region_code char(2) not null
	)
go

if (OBJECT_ID('category') is null)
	create table category (
		category_id int primary key not null identity(1,1),
		category_name varchar(100) not null,
		sub_category_name varchar(100)
	)
go

if (OBJECT_ID('poi_details') is null)
	CREATE TABLE [dbo].[poi_details](
		[id] [varchar](50) NOT NULL,
		[parent_id] [varchar](50) NULL,
		[brand] [varchar](50) NULL,
		[brand_id] [varchar](250) NULL,
		[category_id] [int] NULL,
		[category_tags] [varchar](150) NULL,
		[postal_code] [int] NOT NULL,
		[location_name] [varchar](120) NULL,
		[latitude] [decimal](18, 8) NOT NULL,
		[longitude] [decimal](18, 8) NOT NULL,
		[country_id] [int] NOT NULL,
		[city_id] [int] NOT NULL,
		[region_id] [int] NOT NULL,
		[operation_hours] [varchar](360) NULL,
		[geometry_type] [varchar](50) NOT NULL,
		[polygon_wkt] [varchar](max) NULL
	)
GO

ALTER TABLE [dbo].[poi_details] ADD  CONSTRAINT [PK_poi_details] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)
go

CREATE NONCLUSTERED INDEX [ix_category_id] ON [dbo].[poi_details]
(
	[category_id] ASC
)
go

CREATE NONCLUSTERED INDEX [ix_city_id] ON [dbo].[poi_details]
(
	[city_id] ASC
)
go

CREATE NONCLUSTERED INDEX [ix_country_id] ON [dbo].[poi_details]
(
	[country_id] ASC
)
go

CREATE NONCLUSTERED INDEX [ix_region_id] ON [dbo].[poi_details]
(
	[region_id] ASC
)
go

ALTER TABLE dbo.poi_details
ADD CONSTRAINT FK_poi_details_region_id FOREIGN KEY (region_id)
REFERENCES dbo.region (region_id);

ALTER TABLE dbo.poi_details
ADD CONSTRAINT FK_poi_details_city_id FOREIGN KEY (city_id)
REFERENCES dbo.city (city_id);

ALTER TABLE dbo.poi_details
ADD CONSTRAINT FK_poi_details_country_id FOREIGN KEY (country_id)
REFERENCES dbo.country (country_id);

ALTER TABLE dbo.poi_details
ADD CONSTRAINT FK_poi_details_category_id FOREIGN KEY (category_id)
REFERENCES dbo.category (category_id);


-- drop procedure dbo.sp_load_tx

create procedure dbo.sp_load_tx as
begin

/* 
	for the sake of simplicity different loads are in the current stored procedure 
*/

	insert into dbo.country (country_code)
	select distinct p.country_code
	from dbo.phoenix p
		left join dbo.country c on c.country_code = p.country_code
	where c.country_id is null

	insert into dbo.city (city_name)
	select distinct p.city
	from dbo.phoenix p
		left join dbo.city c on c.city_name = p.city 
	where c.city_name is null

	insert into dbo.region (region_code)
	select distinct p.region
	from dbo.phoenix p
		left join dbo.region r on r.region_code = p.region
	where r.region_id is null

	insert into dbo.category (category_name, sub_category_name)
	select distinct p.top_category, case when p.sub_category != '' then p.sub_category else null end
	from dbo.phoenix p
		left join dbo.category c on c.category_name = p.top_category and coalesce(c.sub_category_name, 'x') = coalesce(case when p.sub_category != '' then p.sub_category else null end, 'x')
	where p.top_category != '' and c.category_id is null

	-- truncate table dbo.poi_details

	insert into dbo.poi_details ([id], [parent_id], [brand], [brand_id], [category_id], [category_tags], [postal_code], [location_name], [latitude], [longitude], [country_id]
	, [city_id], [region_id], [operation_hours], [geometry_type], [polygon_wkt])
	select p.id, p.parent_id, p.brand, p.brand_id, c.category_id, p.category_tags, p.postal_code, p.location_name, p.latitude, p.longitude
	, co.country_id, ci.city_id, r.region_id, p.operation_hours, p.geometry_type, p.polygon_wkt
	from dbo.phoenix p
		left join [dbo].[category] c on c.category_name = p.top_category and coalesce(c.sub_category_name, '-1') = coalesce(p.sub_category, '-1')
		join [dbo].[country] co on co.country_code = p.country_code
		join [dbo].[city] ci on ci.city_name = p.city
		join [dbo].[region] r on r.region_code = p.region


end
go



