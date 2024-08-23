use billups_test
go

if (OBJECT_ID('sp_search') is not null)
	drop procedure sp_search
go


create procedure dbo.sp_search(@p_json nvarchar(max)) as
declare 
@v_sql nvarchar(max),
@v_category_name nvarchar(max),
@v_poi_name nvarchar(max),
@v_city nvarchar(max),
@v_region nvarchar(max),
@v_country nvarchar(max),
@v_latitude nvarchar(max),
@v_longitude nvarchar(max),
@v_latitude_max nvarchar(max),
@v_longitude_max nvarchar(max),
@v_radius decimal(18, 8);
begin

/* USAGE:


DECLARE	@return_value int

EXEC	@return_value = [dbo].[sp_search]
		--@p_json = N'{"poi_category":"Building Finishing Contractors",  "poi_name":"StoneCrafters", "city":"Phoenix", "country":"US", "region":"AZ"}'
		--@p_json = N'{"poi_category":"Agencies, Brokerages, and Other Insurance Related Activities",  "city":"Phoenix", "country":"US", "region":"AZ", "latitude":"33.670450", "longitude":"-112.100600", "radius":"10"}'
		--@p_json = N'{"city":"Phoenix", "country":"US", "latitude":"32.000000", "longitude":"-112.000000", "radius":"3"}'
		--@p_json = N'{"city":"Phoenix", "country":"US", "latitude":"39.52596000", "longitude":"-76.55285000", "radius":"0"}'
		--@p_json = N'{"poi_category":"Elementary and Secondary Schools",  "country":"US", "latitude":"39.52596000", "longitude":"-76.55285000", "radius":"10"}'
		--@p_json = N'{"city":"Phoenix", "country":"US"}'
		
		@p_json = N'{}'

SELECT	'Return Value' = @return_value

GO

*/


	select @v_category_name = v.poi_category, @v_poi_name = v.poi_name, @v_city = v.city, @v_region = v.region, @v_country = v.country
		, @v_latitude = v.latitude, @v_longitude = v.longitude, @v_radius = v.radius, @v_latitude_max = v.latitude + @v_radius, @v_longitude_max = v.longitude + @v_radius 
	from (
		SELECT poi_category, poi_name, city, region, country, latitude, longitude, radius
		FROM OPENJSON(@p_json) WITH (
			poi_category nvarchar(max) '$.poi_category',
			poi_name nvarchar(max) '$.poi_name',
			city nvarchar(max) '$.city',
			region nvarchar(max) '$.region',
			country nvarchar(max) '$.country',
			latitude decimal(18, 8) '$.latitude',
			longitude decimal(18, 8) '$.longitude',
			radius decimal(18, 8) '$.radius')
		) v;

	-- default values - start

	-- If no search criteria is supplied, return all POIs within 200 meters of the current location. You can use any dummy location in Phoenix as the current one.

	if @p_json = '{}'
		begin
			set @v_radius = 2; -- radius = 2 == 200 meters; just assumption
			set @v_latitude = '39.00000000';
			set @v_longitude = '-74.00000000';
			set @v_latitude_max = @v_latitude + @v_radius;
			set @v_longitude_max = @v_longitude + @v_radius;
		end

	-- default values - end

	set @v_sql = 'select p.id as Id, p.parent_id as ''Parent Id'', co.country_code as ''Country code'', r.region_code as ''Region Code'', ci.city_name as ''City Name''
	, concat(p.latitude, '', '', p.longitude) as ''Location coordinates'', c.category_name as Category, c.sub_category_name as ''Sub category'', p.polygon_wkt as ''WKT polygon''
	, p.location_name as''Location Name'', p.postal_code as ''Postal code'', p.operation_hours as ''Operation Hours''
	from dbo.poi_details p
		left join [dbo].[category] c on c.category_id = p.category_id
		join [dbo].[country] co on co.country_id = p.country_id
		join [dbo].[city] ci on ci.city_id = p.city_id
		join [dbo].[region] r on r.region_id = p.region_id
	where 1 = 1 ';

	if @v_category_name is not null
		set @v_sql = @v_sql + 'and c.category_name = ''' + @v_category_name + '''';

	if @v_poi_name is not null
		set @v_sql = @v_sql + ' and p.location_name = ''' + @v_poi_name + '''';

	if @v_city is not null
		set @v_sql = @v_sql + ' and ci.city_name = ''' + @v_city + '''';

	if @v_region is not null
		set @v_sql = @v_sql + ' and r.region_code = ''' + @v_region + '''';

	if @v_country is not null
		set @v_sql = @v_sql + ' and co.country_code = ''' + @v_country + '''';

	if @v_latitude is not null and @v_longitude is not null
		set @v_sql = @v_sql + ' and p.latitude >= ' + @v_latitude + ' and p.latitude <= ' + @v_latitude_max + '' + ' and p.longitude >= ' + @v_longitude + ' and p.longitude <= ' + @v_longitude_max + '';

	set @v_sql = @v_sql + ' for json path ';

	--print(@v_sql);

	exec (@v_sql);

	--print(@v_category_name);
	--print(@v_poi_name);
	--print(@v_city);
	--print(@v_region);
	--print(@v_country);
	--print(@v_latitude);
	--print(@v_longitude);
	--print(@v_latitude_max);
	--print(@v_longitude_max);
	--print(@v_radius);

end
go
