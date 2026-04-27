# Technical Assessment Solutions Guide

**For Interviewers Only** - Do not share with candidates

---

## Question 1: API Configuration Issue

### The Bug
The API fails to start or connect to the database due to a configuration mismatch.

**Root Cause:**
- `Api/appsettings.json` contains `DatabaseConnection:DatabaseName` = `sqldb-tfls-d4a635oijzpb` (typo, missing 'c')
- `Api/Program.cs` builds the connection string using this incorrect database name
- The correct database name is `sqldb-tfls-d4a635oijzpbc`
- Meanwhile, `appsettings.Development.json` has a correct connection string under `ConnectionStrings:TflSchoolApiContext`, but it's not being used

### Solution 1 (Best Practice)
Modify `Api/Program.cs` to prefer `ConnectionStrings` configuration:

```csharp
// Replace the connection string building code with:
var connection = builder.Configuration.GetConnectionString("TflSchoolApiContext");

if (string.IsNullOrEmpty(connection))
{
    var dbName = builder.Configuration["DatabaseConnection:DatabaseName"];
    var userName = builder.Configuration["DatabaseConnection:UserName"];
    var password = builder.Configuration["DatabaseConnection:Password"];
    
    connection = $"Server=tcp:sql-tfls-d4a635oijzpbc.database.windows.net,1433;Initial Catalog={dbName};Persist Security Info=False;User ID={userName};Password={password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;";
}

builder.Services.AddDbContext<TflDbContext>(opt =>
    opt.UseSqlServer(connection, sqlOptions => sqlOptions.EnableRetryOnFailure())
);
```

### Solution 2 (Quick Fix)
Fix the typo in `Api/appsettings.json`:

```json
"DatabaseConnection": {
  "DatabaseName": "sqldb-tfls-d4a635oijzpbc",  // Added 'c' at the end
  "UserName": "appUser",
  "Password": ""
}
```

### Verification
Verify using cloud signals rather than local runtime:

- Check Application Insights to confirm the prior 500 failures are no longer occurring.
- Confirm deployed API endpoint `/api/Students` now responds with HTTP 200.
- Ensure the candidate can explain how telemetry evidence led to the root cause.

### Scoring Criteria
- **Excellent:** Uses Azure logging/telemetry to diagnose first, implements Solution 1 (proper fallback)
- **Good:** Identifies the typo, fixes it, validates successfully in deployed environment
- **Needs Improvement:** Guesses at the solution without using diagnostic tools

---

## Question 2: C# Logic Error

### The Bug
The `Student.TotalCredits` property returns only the last enrollment's credits instead of the sum.

**Root Cause:**  
In `Models/Models/Student.cs`, line 17:
```csharp
totalCredits = (int)enrollment.Course.Credits;  // Assignment, not accumulation!
```

This **assigns** the value on each iteration instead of **adding** to it.

### Solution
Change line 17 from assignment to addition:

```csharp
public int TotalCredits
{
    get
    {
        var totalCredits = 0;
        
        if (Enrollments != null)
        {
            foreach(var enrollment in Enrollments)
            {
                totalCredits += enrollment?.Course?.Credits ?? 0;  // Use += and null-safe
            }
        }
        
        return totalCredits;
    }
}
```

### Key Changes
1. `=` changed to `+=` (accumulation)
2. Added null check for `Enrollments` collection
3. Added null-safe navigation with `??` operator

### Verification
Verification should be done from the deployed portal after redeploy:

- Candidate commits and pushes the change directly from `vscode.dev`.
- Deployment pipeline completes for API/portal.
- In deployed Student Portal, searching for "Carson Alexander" changes from 3 to 9 credits.

### Scoring Criteria
- **Excellent:** Fixes accumulation bug AND adds null safety
- **Good:** Fixes the `=` to `+=` bug, verifies successfully in deployed app
- **Needs Improvement:** Fixes bug but doesn't validate deployed behavior or consider edge cases

---

## Question 3: Function App Data Upload Failure

### The Bug
The function upload process fails during student insert and returns a transaction rollback error. No students are uploaded.

**Root Cause:**  
In `src/DataUpload.FunctionApp/RunEnrollmentUpload/run.ps1`, the loop overwrites the student values variable instead of accumulating each student row. This causes row-count validation to fail and the transaction to roll back.

Typical failing pattern:

```powershell
$studentValues = @()

foreach ($student in $students) {
    $studentValues = "('...')"  # Overwrites value each iteration
}
```

Only one value tuple is sent, expected row-count and actual row-count differ, and the student transaction is rolled back.

### Solution
Use accumulation and fail-fast rollback behavior:

```powershell
# Build values correctly
$studentValues = @()

foreach ($student in $students) {
    $firstName = $student.FirstMidName -replace "'", "''"
    $lastName = $student.LastName -replace "'", "''"
    $enrollmentDate = $student.EnrollmentDate -replace "'", "''"

    $studentValues += "('$firstName','$lastName','$enrollmentDate')"
}

# Query should THROW when expected and actual insert counts differ
# Enrollment section should only execute after successful student insert
```

### Key Changes
1. Build student insert values by accumulation (`+=`) instead of overwrite (`=`)
2. Preserve SQL literal escaping for student text fields
3. Keep explicit row-count validation and rollback logic
4. Ensure rollback path throws an error so processing stops before enrollment upload

### Verification
Verification should be done through Azure execution:

- Candidate commits/pushes function fix from `vscode.dev`.
- Workflow `Build and Deploy Data Upload Function` completes successfully.
- Workflow `Upload Data Files and Run Data Upload Function` completes successfully.
- Workflow logs and function logs show student insert succeeded without rollback and enrollment processing ran.

### Scoring Criteria
- **Excellent:** Fixes accumulation bug, preserves SQL safety, and validates both workflows plus successful function execution evidence
- **Good:** Fixes the accumulation bug and verifies successful function run with no rollback error
- **Needs Improvement:** Partial fix, rollback still occurs, or no verification via workflow/function logs

---

## Overall Assessment Rubric

### Time Management
- Completes all 3 questions in ~60 minutes
- Prioritizes getting working solutions over perfect solutions

### Diagnostic Approach
- Uses logs and error messages effectively
- Reads code to understand context before making changes
- Tests fixes to verify they work

### Code Quality
- Makes minimal, targeted changes
- Considers edge cases (nulls, empty collections, special characters)
- Follows existing code style

### Communication
- Can explain what was wrong
- Can explain how the fix works
- Asks clarifying questions if needed

### Red Flags
- Makes random changes without understanding the problem
- Doesn't test their fixes
- Over-engineers solutions
- Gives up without trying diagnostic tools

---

## Setup Notes for Interviewers

### Prerequisites
1. Ensure the database has sample data (students "Carson Alexander" with 3 enrollments)
2. Application Insights is enabled for deployed resources and visible to the candidate
3. Azure PowerShell Function execution path is available for Question 3
4. Candidate has browser access to GitHub, `vscode.dev`, and Azure Portal

### Timing Suggestions
- Start timer when candidate begins reading
- 20-minute checkpoint: Should be working on Question 2
- 40-minute checkpoint: Should be working on Question 3
- 10 minutes remaining: Suggest prioritizing working solutions

### Observation Points
- Do they read error messages carefully?
- Do they use Azure logging/diagnostic tools first?
- Do they validate fixes in deployed cloud environment?
- How do they handle uncertainty?

---

## Common Mistakes to Watch For

### Question 1
- Changing the wrong configuration file
- Ignoring Application Insights evidence before changing code
- Validating the wrong endpoint/environment

### Question 2
- Fixing the accumulation but breaking null safety
- Not validating after deployment completes
- Testing with the wrong student

### Question 3
- Not understanding loop accumulation behavior
- Forgetting to escape special characters
- Not verifying the actual insert count from Azure function execution logs

---

Good luck with your interviews!
