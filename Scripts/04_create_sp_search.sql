use billups_test
go

if (OBJECT_ID('sp_search') is not null)
	drop procedure sp_search
go


create procedure [dbo].[sp_search](@p_json nvarchar(max)) as
declare 
@v_sql nvarchar(max),
@v_category_name nvarchar(max),
@v_poi_name nvarchar(max),
@v_city nvarchar(max),
@v_region nvarchar(max),
@v_country nvarchar(max),
@v_latitude decimal(18, 8),
@v_longitude decimal(18, 8),
@v_radius decimal(18, 8);
begin

/* USAGE:


DECLARE	@return_value int

EXEC	@return_value = [dbo].[sp_search]
		--@p_json = N'{"poi_category":"Building Finishing Contractors",  "poi_name":"StoneCrafters", "city":"Phoenix", "country":"US", "region":"AZ"}'
		--@p_json = N'{"poi_category":"Agencies, Brokerages, and Other Insurance Related Activities",  "city":"Phoenix", "country":"US", "region":"AZ", "latitude":"33.670450", "longitude":"-112.100600", "radius":"10"}'
		--@p_json = N'{"city":"Phoenix", "country":"US", "latitude":"39.525960", "longitude":"-76.552850", "radius":"0"}'
		--@p_json = N'{"poi_category":"Elementary and Secondary Schools",  "country":"US", "latitude":"39.525960", "longitude":"-76.552850", "radius":"100000"}'
		--@p_json = N'{"city":"Phoenix", "country":"US"}'
		
		@p_json = N'{}'

SELECT	'Return Value' = @return_value

GO

*/


	select @v_category_name = v.poi_category, @v_poi_name = v.poi_name, @v_city = v.city, @v_region = v.region, @v_country = v.country
		, @v_latitude = v.latitude, @v_longitude = v.longitude, @v_radius = v.radius
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

	if @v_latitude is not null and @v_latitude is not null
		set @v_sql = @v_sql + concat(' and geography::Point(', @v_latitude, ', ', @v_longitude, ', 4326).STDistance(geography::Point(p.latitude, p.longitude, 4326)) <= ', @v_radius);

	-- If no search criteria is supplied, return all POIs within 200 meters of the current location. You can use any dummy location in Phoenix as the current one.

	if @p_json = '{}'
		set @v_sql = @v_sql + ' and geography::Point(33.4484, -112.0740, 4326).STDistance(geography::Point(p.latitude, p.longitude, 4326)) <= 200';

	set @v_sql = @v_sql + ' for json path ';
	
	--print(@v_sql);

	exec (@v_sql);

end
go
