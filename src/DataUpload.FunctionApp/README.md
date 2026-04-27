# Data Upload Function App

This Azure Function App runs the enrollment upload process in Azure using PowerShell.

## Trigger

- Function name: `RunEnrollmentUpload`
- Trigger type: HTTP
- Route: `POST /api/data-upload/run`
- Auth level: `function`

## Required App Settings

Set these in Azure Function App configuration:

- `FUNCTIONS_WORKER_RUNTIME` = `powershell`
- `SqlConnectionString` = SQL connection string for the target Azure SQL Database

Example connection string format:

`Server=tcp:<server>.database.windows.net,1433;Initial Catalog=<database>;Persist Security Info=False;User ID=<user>;Password=<password>;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;`

## Data Inputs

By default, the function reads:

- `Data/Students.csv`
- `Data/Enrollments.csv`

You can optionally override paths by posting JSON:

```json
{
  "studentsCsvPath": "D:\\home\\site\\wwwroot\\Data\\Students.csv",
  "enrollmentsCsvPath": "D:\\home\\site\\wwwroot\\Data\\Enrollments.csv"
}
```

## Execution

Invoke the function via Azure Portal, Postman, or curl using the function key.

## Automated CSV Upload + Trigger Workflow

Repository workflow: `.github/workflows/dataupload-csv-and-run.yml`

What it does:
- Uploads `src/DataUpload/Enrollment2024/Students.csv` and `src/DataUpload/Enrollment2024/Enrollments.csv` into `wwwroot/Data` in the deployed Function App.
- Invokes `POST /api/data-upload/run` using the function key.
- Fails the job if the function returns an error status.

Required GitHub variables:
- `DATAUPLOAD_FUNCTIONAPP_NAME`
- `RESOURCE_GROUP_NAME`

## Notes

- Student names are escaped before SQL query generation to reduce SQL injection risk.
- The student insert step verifies expected row count in a transaction.
- If student insert row count does not match expected count, the transaction is rolled back and the function throws an error immediately.
- Enrollment upload is not executed after a student transaction rollback.
- Enrollment rows with invalid `CourseId` values are skipped and logged.
