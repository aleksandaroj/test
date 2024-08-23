use billups_test
go


if (object_id('phoenix') is not null)
	drop table phoenix
go

if (object_id('phoenix') is null)
	CREATE TABLE [dbo].[phoenix](
		[id] [varchar](50) NOT NULL,
		[parent_id] [varchar](50) NULL,
		[brand] [varchar](max) NULL,
		[brand_id] [varchar](max) NULL,
		[top_category] [varchar](100) NULL,
		[sub_category] [varchar](max) NULL,
		[category_tags] [varchar](max) NULL,
		[postal_code] [int] NOT NULL,
		[location_name] [varchar](max) NULL,
		[latitude] decimal(18, 8) NOT NULL,
		[longitude] decimal(18, 8) NOT NULL,
		[country_code] [varchar](50) NOT NULL,
		[city] [varchar](50) NOT NULL,
		[region] [varchar](50) NOT NULL,
		[operation_hours] [varchar](max) NULL, --json
		[geometry_type] [varchar](50) NOT NULL,
		[polygon_wkt] [varchar](max) NULL
	 CONSTRAINT [PK_phoenix] PRIMARY KEY CLUSTERED 
	([id] ASC)
	)
GO
