/* 
Aleksandar Dimitrievski
2024-08-23
*/

1. Deployable scripts are available in the folder "Scripts"
2. The database restore file is available in the folder "db"


Comments:

- Unzip the db/billups_test.zip file
- Restore the database using the option Source/Device

- After having db online you can run the stored procedure dbo.sp_search() 
-- Within the stored procedure there are prepared different variants for running the stored procedure to check the validity of the task

- The output format is not GeoJSON since the polygon-related task was not done.
