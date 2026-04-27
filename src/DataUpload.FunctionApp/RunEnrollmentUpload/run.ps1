using namespace System.Net

param($Request, $TriggerMetadata)

function ConvertTo-SqlLiteral {
    param(
        [AllowNull()]
        [string]$Value
    )

    if ($null -eq $Value) {
        return ""
    }

    return $Value.Replace("'", "''")
}

try {
    $connectionString = $env:SqlConnectionString

    if ([string]::IsNullOrWhiteSpace($connectionString)) {
        throw "Function app setting 'SqlConnectionString' is required."
    }

    Import-Module SqlServer -ErrorAction Stop

    $studentsCsvPath = Join-Path $PSScriptRoot "..\Data\Students.csv"
    $enrollmentsCsvPath = Join-Path $PSScriptRoot "..\Data\Enrollments.csv"

    $requestBody = $null
    if ($Request.Body) {
        if ($Request.Body -is [string]) {
            $requestBody = $Request.Body | ConvertFrom-Json -ErrorAction Stop
        }
        else {
            $requestBody = $Request.Body
        }
    }

    if ($requestBody) {
        if ($requestBody.studentsCsvPath) {
            $studentsCsvPath = $requestBody.studentsCsvPath
        }

        if ($requestBody.enrollmentsCsvPath) {
            $enrollmentsCsvPath = $requestBody.enrollmentsCsvPath
        }
    }

    if (!(Test-Path -Path $studentsCsvPath)) {
        throw "Students CSV not found at '$studentsCsvPath'."
    }

    if (!(Test-Path -Path $enrollmentsCsvPath)) {
        throw "Enrollments CSV not found at '$enrollmentsCsvPath'."
    }

    Write-Host "*** INSERT STUDENTS ***"
    $students = Import-Csv -Path $studentsCsvPath

    if ($students.Count -eq 0) {
        throw "No student rows found in '$studentsCsvPath'."
    }

    Write-Host "Building student insert query"
    $studentValues = @()

    foreach ($student in $students) {
        $firstName = ConvertTo-SqlLiteral -Value $student.FirstMidName
        $lastName = ConvertTo-SqlLiteral -Value $student.LastName
        $enrollmentDate = ConvertTo-SqlLiteral -Value $student.EnrollmentDate

        $studentValues = "('$firstName','$lastName','$enrollmentDate')"
    }

    $insertStudentsQuery = @"
DECLARE @expected_inserts int;
DECLARE @actual_inserts int;
SET XACT_ABORT ON;
SET @expected_inserts = $($students.Count);
BEGIN TRANSACTION;
INSERT INTO [dbo].[Students] (FirstMidName, LastName, EnrollmentDate)
VALUES $($studentValues -join ',');
SET @actual_inserts = @@ROWCOUNT;
IF @actual_inserts = @expected_inserts
BEGIN
    COMMIT TRANSACTION;
    SELECT @expected_inserts AS ExpectedInserts, @actual_inserts AS ActualInserts;
END
ELSE
BEGIN
    ROLLBACK TRANSACTION;
    THROW 51000, 'Student insert row-count mismatch. Transaction rolled back.', 1;
END
"@

    $studentInsertResult = Invoke-Sqlcmd -ConnectionString $connectionString -Query $insertStudentsQuery -Verbose -ErrorAction Stop
    if ($studentInsertResult) {
        Write-Host "Student upload completed: expected=$($studentInsertResult[0].ExpectedInserts), actual=$($studentInsertResult[0].ActualInserts)"
    }
    Write-Host "*** INSERT STUDENTS FINISHED ***"

    Write-Host "*** INSERT ENROLLMENTS ***"
    $enrollments = Import-Csv -Path $enrollmentsCsvPath

    if ($enrollments.Count -eq 0) {
        throw "No enrollment rows found in '$enrollmentsCsvPath'."
    }

    $processedEnrollments = 0

    foreach ($enrollment in $enrollments) {
        $studentFirstName = ConvertTo-SqlLiteral -Value $enrollment.FirstMidName
        $studentLastName = ConvertTo-SqlLiteral -Value $enrollment.LastName

        [int]$courseId = 0
        if (-not [int]::TryParse($enrollment.CourseId, [ref]$courseId)) {
            Write-Warning "Skipping enrollment for '$studentFirstName $studentLastName' due to invalid CourseId '$($enrollment.CourseId)'."
            continue
        }

        $getStudentIdQuery = "SELECT Id FROM [dbo].[Students] WHERE FirstMidName = '$studentFirstName' AND LastName = '$studentLastName'"
        $studentResult = Invoke-Sqlcmd -ConnectionString $connectionString -Query $getStudentIdQuery

        if ($studentResult) {
            $studentId = [int]$studentResult[0].Id

            $insertEnrollmentQuery = @"
SET XACT_ABORT ON;
BEGIN TRANSACTION;
INSERT INTO [dbo].[Enrollments] (CourseId, StudentId)
VALUES (
    (SELECT CourseID FROM [dbo].[Courses] WHERE CourseId = $courseId),
    (SELECT Id FROM [dbo].[Students] WHERE Id = $studentId)
);
COMMIT TRANSACTION;
"@

            Invoke-Sqlcmd -ConnectionString $connectionString -Query $insertEnrollmentQuery -Verbose | Out-Null
            $processedEnrollments++
        }
        else {
            Write-Warning "Student '$studentFirstName $studentLastName' was not found. Enrollment row was skipped."
        }
    }

    Write-Host "*** INSERT ENROLLMENTS FINISHED ***"

    $result = [ordered]@{
        message = "Data upload finished successfully."
        studentsInserted = $students.Count
        enrollmentsProcessed = $processedEnrollments
        studentsCsvPath = $studentsCsvPath
        enrollmentsCsvPath = $enrollmentsCsvPath
        timestampUtc = [DateTime]::UtcNow.ToString("o")
    }

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = $result
    })
}
catch {
    if ($_.Exception.Message -like '*row-count mismatch*') {
        Write-Warning 'Student upload transaction rolled back due to row-count mismatch. Enrollment upload was not started.'
    }

    Write-Error $_

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = [ordered]@{
            message = "Data upload failed."
            error = $_.Exception.Message
            timestampUtc = [DateTime]::UtcNow.ToString("o")
        }
    })
}
