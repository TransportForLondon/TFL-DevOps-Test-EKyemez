# Assessment Summary

## Overview
This repository contains a complete **1-hour technical skills assessment** for DevOps/Software Engineering candidates. It evaluates cloud-first diagnostic skills, C# code analysis, and PowerShell scripting in a browser-only workflow.

## Files Created/Updated

### For Candidates
- **`README.md`** - Main assessment document with all three questions, instructions, and success criteria

### For Interviewers (in `AssessorGuide/` folder)
- **`SOLUTIONS.md`** - Complete solutions guide with scoring rubric
- **`INTERVIEWER_SETUP.md`** - Pre-interview setup checklist and troubleshooting
- **`ASSESSMENT_SUMMARY.md`** (this file) - Quick reference
- **`README.md`** - Instructions for removing this folder before sharing

**⚠️ IMPORTANT:** Delete the `AssessorGuide/` folder before forking or sharing with candidates.

## The Three Questions

### Question 1: Diagnose API Failure Using Application Insights (20 min)
**Skill:** Logging/telemetry investigation, root-cause analysis, configuration troubleshooting

**Bug Location:** `Api/appsettings.json` line 10  
**Bug:** Database name has typo: `sqldb-tfls-d4a635oijzpb` (missing 'c' at end)  
**Impact:** API fails to connect to database

**Solution:** Either:
1. Fix the typo in `appsettings.json`, OR
2. Modify `Program.cs` to use `GetConnectionString("TflSchoolApiContext")` which has correct value in `appsettings.Development.json`

**Verification:** Candidate uses Application Insights and deployed API behavior to confirm `/api/Students` is healthy (HTTP 200, error trend resolved)

---

### Question 2: Fix C# Logic Error (20 min)
**Skill:** Defect interpretation, code reading, C# fundamentals

**Bug Location:** `Models/Models/Student.cs` line 19  
**Bug:** Loop uses assignment (`=`) instead of accumulation (`+=`)  
**Impact:** Total credits shows only last enrollment's credits (3) instead of sum (9)

**Solution:**
```csharp
// Change from:
totalCredits = (int)enrollment.Course.Credits;

// To:
totalCredits += enrollment?.Course?.Credits ?? 0;
```

**Verification:** Candidate commits directly from `vscode.dev`, deployment completes, and deployed Student Portal shows "Carson Alexander" with 9 total credits

---

### Question 3: Fix Function App Data Upload Failure (20 min)
**Skill:** PowerShell scripting, SQL safety, loop logic, cloud execution validation

**Bug Location:** `src/DataUpload.FunctionApp/RunEnrollmentUpload/run.ps1` (student insert value accumulation)  
**Bug:** Student value construction is overwritten each loop iteration instead of accumulated  
**Impact:** 0 students are uploaded and execution fails with a transaction rolled back error due to row-count mismatch

**Solution:**
```powershell
# Initialize before loop:
$values = ""

# Inside loop, change from:
$value = "(...)"

# To:
$values += "(...)"  # Use += and $values (plural)

# After loop, use $values instead of $value
```

**Verification:** Candidate deploys function changes with workflow "Build and Deploy Data Upload Function", then runs workflow "Upload Data Files and Run Data Upload Function" and confirms rows are inserted with no rollback error

---

## Quick Start for Interviewers

1. **Verify bugs exist:**
   ```powershell
   # Bug 1 - Database name typo
   cat Api/appsettings.json | Select-String "DatabaseName"
   # Should show: "sqldb-tfls-d4a635oijzpb" (missing 'c')

   # Bug 2 - Assignment instead of accumulation
   cat Models/Models/Student.cs | Select-String "totalCredits ="
   # Should show: totalCredits = (int)...

   # Bug 3 - Overwriting instead of accumulating in function app code
   cat src/DataUpload.FunctionApp/RunEnrollmentUpload/run.ps1 | Select-String '$studentValues ='
   # Should show assignment in loop where accumulation should be used
   ```

2. **Ensure database has sample data:**
   - Student "Carson Alexander" with 3 enrollments totaling 9 credits

3. **Confirm browser-only candidate flow is ready:**
   - Candidate can access repository in `vscode.dev`
   - Candidate can access Azure Portal (Application Insights + deployed apps)
   - Candidate can execute Question 3 via Azure PowerShell Function trigger (no local execution)

4. **Share repository with candidate**

5. **Start 60-minute timer**

---

## Assessment Objectives

### What This Tests
✅ Ability to read and understand error messages  
✅ Using logs and diagnostics tools (Application Insights, Azure monitoring)  
✅ Code comprehension (reading unfamiliar codebase)  
✅ Debugging logic errors  
✅ Cloud-based testing and verification without local runtime  
✅ Time management  
✅ C# fundamentals (loops, null-safety)  
✅ PowerShell scripting (loops, string manipulation)  
✅ SQL awareness (injection prevention)  

### What This Doesn't Test
❌ Advanced algorithm design  
❌ System architecture  
❌ Deep Azure knowledge  
❌ Writing code from scratch  
❌ Local IDE setup or local runtime execution  

---

## Scoring Quick Reference

### Excellent Candidate (3/3 questions complete)
- Uses diagnostic tools effectively
- Starts Question 1 with logs/telemetry before editing code
- Minimal, targeted fixes
- Validates all changes in deployed Azure environment
- Considers edge cases (nulls, SQL injection)
- Completes in < 60 minutes

### Good Candidate (2-3 questions complete)
- Finds and fixes bugs
- Verifies solutions in deployed environment
- May miss some edge cases
- Completes most questions in time

### Needs Improvement (< 2 questions complete)
- Guesses at solutions without diagnosing
- Doesn't validate changes in cloud environment
- Makes excessive changes
- Poor time management

---

## Time Benchmarks

- **0-20 min:** Working on Question 1, should have it diagnosed
- **20-40 min:** Working on Question 2, Q1 complete
- **40-60 min:** Working on Question 3, Q2 complete
- **60 min:** All questions complete (ideal)

---

## Common Issues

### "Database connection still fails after fix"
- Check they validated the deployed app (not a stale local assumption)
- Verify they targeted the correct configuration value and committed to the branch being deployed
- Confirm App Service configuration and database credentials are still valid

### "Student total still shows wrong value"
- Did deployment complete successfully after commit?
- Did they validate in the deployed Student Portal URL?
- Did they fix both the loop AND add null safety?

### "PowerShell script fails with SQL error"
- Did the Azure PowerShell Function run with valid configuration and credentials?
- Did they escape single quotes in names?
- Did they fix the accumulation AND the trailing comma?

---

## Files Structure

```
TFL-DevOps-Test/
├── README.md                         # Candidate-facing assessment
├── AssessorGuide/                    # ⚠️ DELETE BEFORE SHARING
│   ├── README.md                     # Removal instructions
│   ├── SOLUTIONS.md                  # Complete solutions
│   ├── INTERVIEWER_SETUP.md          # Setup guide
│   └── ASSESSMENT_SUMMARY.md         # This file
├── Api/
│   ├── Program.cs                   # Q1 related
│   ├── appsettings.json             # Q1: typo here
│   └── appsettings.Development.json
├── Models/Models/
│   └── Student.cs                   # Q2: line 19
├── src/DataUpload.FunctionApp/
│   └── RunEnrollmentUpload/run.ps1  # Q3: accumulation bug location
└── src/DataUpload/Enrollment2024/
   ├── Students.csv                 # Q3 upload input
   └── Enrollments.csv              # Q3 upload input
```

---

## Next Steps

1. Review `INTERVIEWER_SETUP.md` for detailed setup
2. Review `SOLUTIONS.md` for scoring rubric
3. Test all three bugs work in your environment
4. Prepare database with sample data
5. Schedule your interview!

---

## Contact

For questions about this assessment, contact [your team/email].

**Version:** 1.0  
**Last Updated:** November 2025
