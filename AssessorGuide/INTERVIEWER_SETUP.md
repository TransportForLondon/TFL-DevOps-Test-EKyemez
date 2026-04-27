# Interviewer Setup Guide

This guide helps you prepare the Azure-deployed technical assessment environment before the interview.

**Important:** This assessment runs entirely in Azure with automated CI/CD pipelines. Candidates will diagnose and fix issues in the deployed environment, then verify fixes via the pipelines.

## Prerequisites

### Required Access
- [ ] Active Azure subscription with Contributor access
- [ ] GitHub repository (forked or cloned) with Actions enabled
- [ ] Azure CLI (`az`) installed locally for setup
- [ ] Git installed locally

### Candidate Requirements
- [ ] GitHub account (to access candidate fork)
- [ ] Web browser (for GitHub, `vscode.dev`, Azure Portal, and deployed apps)
- [ ] Basic familiarity with GitHub web workflow (edit, commit, push, and actions history)

---

## Pre-Interview Setup

**Estimated Time:** 45-60 minutes (first-time setup)

**Overview:** You'll create Azure infrastructure, configure GitHub Actions, deploy the application with intentional bugs, and verify the pipelines work. Candidates will then fix bugs and redeploy via the same pipelines.

**Candidate Working Model:** Candidates work in a browser-only environment. They should not need local Visual Studio, local VS Code, or local runtime execution.

### 1. Fork Repository for Candidate

```powershell
# Clone the assessor repository
git clone <assessor-repository-url>
cd TFL-DevOps-Test

# Remove the AssessorGuide folder
Remove-Item -Recurse -Force AssessorGuide

# Create candidate repository (via GitHub UI or CLI)
# Push to new repository
git remote set-url origin <candidate-repository-url>
git push -u origin main
```

**Or use GitHub's fork feature and then delete the `AssessorGuide/` folder.**

---

## Azure Infrastructure Setup

### 2. Create Azure Resource Group

```powershell
# Login to Azure
az login

# Set your subscription (if you have multiple)
az account set --subscription "<your-subscription-id>"

# Create resource group
az group create `
  --name "rg-tfl-school-dev" `
  --location "uksouth"
```

**Note:** Update the resource group name in `.github/workflows/Infrastructure.yml` if using a different name.

### 3. Create User-Assigned Managed Identity

```powershell
# Create the managed identity
az identity create `
  --name "id-tfl-school-github" `
  --resource-group "rg-tfl-school-dev" `
  --location "uksouth"

# Get the Client ID (Application ID)
$clientId = az identity show `
  --name "id-tfl-school-github" `
  --resource-group "rg-tfl-school-dev" `
  --query clientId -o tsv

# Get the Principal ID
$principalId = az identity show `
  --name "id-tfl-school-github" `
  --resource-group "rg-tfl-school-dev" `
  --query principalId -o tsv

Write-Host "Client ID: $clientId"
Write-Host "Principal ID: $principalId"
```

### 4. Assign Permissions to Managed Identity

```powershell
# Get your subscription ID
$subscriptionId = az account show --query id -o tsv

# Assign Contributor role at Resource Group level
az role assignment create `
  --assignee $principalId `
  --role "Contributor" `
  --scope "/subscriptions/$subscriptionId/resourceGroups/rg-tfl-school-dev"

# If deploying across subscription, use subscription scope instead:
# --scope "/subscriptions/$subscriptionId"
```

### 5. Configure Federated Credentials for GitHub Actions

```powershell
# For main branch deployments
az identity federated-credential create `
  --name "github-main-branch" `
  --identity-name "id-tfl-school-github" `
  --resource-group "rg-tfl-school-dev" `
  --issuer "https://token.actions.githubusercontent.com" `
  --subject "repo:<GitHubOrg>/<RepoName>:ref:refs/heads/main" `
  --audiences "api://AzureADTokenExchange"

# For pull request deployments (optional)
az identity federated-credential create `
  --name "github-pull-requests" `
  --identity-name "id-tfl-school-github" `
  --resource-group "rg-tfl-school-dev" `
  --issuer "https://token.actions.githubusercontent.com" `
  --subject "repo:<GitHubOrg>/<RepoName>:pull_request" `
  --audiences "api://AzureADTokenExchange"
```

**Replace:** `<GitHubOrg>/<RepoName>` with your actual GitHub organization and repository (e.g., `TransportForLondon/TFL-DevOps-Test`)

### 6. Add GitHub Secrets

Navigate to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**

#### Required Secrets:
```powershell
# AZURE_CREDENTIALS (JSON format for service principal)
{
  "clientId": "<client-id-from-step-3>",
  "clientSecret": "",
  "subscriptionId": "<your-subscription-id>",
  "tenantId": "<your-tenant-id>",
  "resourceManagerEndpointUrl": "https://management.azure.com/"
}

# SQL_ADMIN_PASSWORD
# Generate a strong password for SQL Server admin
# Example: 'P@ssw0rd123!' (use something more secure)

# APP_USER_PASSWORD  
# Generate a strong password for the application database user
# Example: 'AppU$er456!' (use something more secure)
```

**To get your Tenant ID:**
```powershell
az account show --query tenantId -o tsv
```

#### Required Variables (not secrets):
- `APP_INSIGHTS_CONN_STRING` - (will be created after infrastructure deployment)
- `API_NAME` - Name of the API app service (from infrastructure output)
- `STUDENTPORTAL_NAME` - Name of the portal app service (from infrastructure output)

### 7. Deploy Infrastructure

```powershell
cd src/Infrastructure

# Review and update main.parameters.json if needed
# Then deploy using Azure CLI

az deployment group create `
  --resource-group "rg-tfl-school-dev" `
  --template-file main.bicep `
  --parameters main.parameters.json `
  --parameters environmentName=dev `
              sqlAdminPassword='<your-sql-admin-password>' `
              appUserPassword='<your-app-user-password>'
```

**Or trigger via GitHub Actions:**
- Push changes to `src/Infrastructure/**` on main branch
- Or manually trigger the "Deploy Infrastructure" workflow

### 8. Get Infrastructure Outputs and Update Configuration

After infrastructure deployment, retrieve the outputs:

```powershell
# Get the deployment outputs
az deployment group show `
  --resource-group "rg-tfl-school-dev" `
  --name "school-infra-deployment" `
  --query properties.outputs

# Key outputs you need:
# - sqlServerName: e.g., "sql-tfls-abc123xyz.database.windows.net"
# - databaseName: e.g., "sqldb-tfls-abc123xyz"
# - apiAppName: e.g., "app-api-tfls-abc123xyz"
# - portalAppName: e.g., "app-portal-tfls-abc123xyz"
# - appInsightsConnectionString
```

### 9. Update Application Configuration Files

**Update `src/Api/appsettings.json`:**
```json
{
  "DatabaseConnection": {
    "DatabaseName": "sqldb-tfls-<WRONG-NAME>",  // ⚠️ Keep this WRONG for Bug #1
    "UserName": "appUser",
    "Password": ""
  }
}
```

**Update `src/Api/appsettings.Development.json`:**
```json
{
  "ConnectionStrings": {
    "TflSchoolApiContext": "Server=tcp:<sql-server-name>.database.windows.net,1433;Initial Catalog=<database-name>;Persist Security Info=False;User ID=sqlAdmin;Password=<SQL_ADMIN_PASSWORD>;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  }
}
```

**Important for Assessment:**
- In `appsettings.json`, the `DatabaseName` should have a typo (e.g., missing last character)
- In `appsettings.Development.json`, the full connection string should be correct
- This creates Bug #1 for candidates to diagnose

### 10. Initialize Database Schema

```powershell
cd src/Api

# Run migrations to create database schema
dotnet ef database update --connection "<your-connection-string-from-appsettings.Development.json>"

# Or use Azure CLI
# The migrations will run automatically on first API deployment via GitHub Actions
```

### 11. Seed Sample Data

The database must have student "Carson Alexander" with 3 enrollments totaling 9 credits for Question 2.

```sql
-- Connect to your Azure SQL Database and run:

-- Insert sample data (adjust as needed)
INSERT INTO Students (FirstMidName, LastName, EnrollmentDate) 
VALUES ('Carson', 'Alexander', '2019-09-01');

-- Get the student ID
DECLARE @StudentId INT = SCOPE_IDENTITY();

-- Insert courses
INSERT INTO Courses (CourseId, Title, Credits, DepartmentId) VALUES 
(1050, 'Chemistry', 3, 1),
(4022, 'Microeconomics', 3, 2),
(4041, 'Macroeconomics', 3, 2);

-- Insert enrollments
INSERT INTO Enrollments (CourseId, StudentId, Grade) VALUES 
(1050, @StudentId, NULL),
(4022, @StudentId, NULL),
(4041, @StudentId, NULL);
```

**Verify:**
```sql
SELECT s.FirstMidName, s.LastName, c.Title, c.Credits
FROM Students s
JOIN Enrollments e ON s.Id = e.StudentId
JOIN Courses c ON e.CourseId = c.CourseId
WHERE s.FirstMidName = 'Carson' AND s.LastName = 'Alexander';

-- Should return 3 rows totaling 9 credits
```

### 12. Update GitHub Variables

Add these to **Settings** → **Secrets and variables** → **Actions** → **Variables**:

```
APP_INSIGHTS_CONN_STRING = <from infrastructure outputs>
API_NAME = <api-app-name from outputs>
STUDENTPORTAL_NAME = <portal-app-name from outputs>
```

### 13. Verify All Three Bugs Are Present

Before the interview, confirm the bugs are in place:

#### Bug 1 (API Configuration):
```powershell
# Check appsettings.json has typo in database name
cat src/Api/appsettings.json | Select-String "DatabaseName"
# Should show a database name with a typo (e.g., missing last character)
```

#### Bug 2 (C# Logic):
```powershell
# Check Student.cs has assignment instead of accumulation
cat src/Models/Models/Student.cs | Select-String "totalCredits ="
# Should show: totalCredits = (int)enrollment.Course.Credits;
# (using = instead of +=)
```

#### Bug 3 (Function App PowerShell):
```powershell
# Check function upload script overwrites student values instead of accumulating
cat src/DataUpload.FunctionApp/RunEnrollmentUpload/run.ps1 | Select-String '$studentValues ='
# Should show assignment in loop where accumulation should be used
```

### 14. Test Deployment Pipelines

Verify all GitHub Actions workflows complete successfully:

```powershell
# Push a small change to trigger pipelines
cd src/Api
# Make a trivial change (e.g., add a comment)
git add .
git commit -m "Test pipeline"
git push origin main
```

**Check GitHub Actions:**
- Navigate to **Actions** tab in GitHub
- Verify "Build and Deploy API" workflow runs successfully
- Verify "Build and Deploy StudentPortal" workflow runs successfully
- Check deployed URLs are accessible

### 14b. Configure Question 3 Azure Function Execution Path

Question 3 must be executable without local PowerShell. Provide a preconfigured Azure PowerShell Function that runs the script logic and can be triggered from Azure Portal.

This repository now includes a Function App project at `src/DataUpload.FunctionApp` and a deployment workflow at `.github/workflows/dataupload-function.yml`.

At minimum, ensure:
- A Function App exists and is running
- A PowerShell-triggered function for data upload is deployed
- Required SQL connection settings are configured in Function App settings (not in candidate-facing docs)
- Application Insights logging is enabled for the Function App
- Interviewer can demonstrate one successful manual trigger before the session

Required configuration for deployment and runtime:
- GitHub Actions variable `DATAUPLOAD_FUNCTIONAPP_NAME` is set to the Function App name
- Function App setting `SqlConnectionString` is set to the target Azure SQL connection string
- Function key is available for `RunEnrollmentUpload` if using authenticated HTTP invocation

Suggested verification flow:
1. Trigger workflow **Build and Deploy Data Upload Function**
2. Confirm deployment succeeds in GitHub Actions
3. Trigger workflow **Upload Data Files and Run Data Upload Function**
4. Confirm CSV files were uploaded and function invocation completed from workflow output
5. Validate execution logs in Function Monitor/Application Insights

Rollback behavior expectation:
- If student insert validation fails, the student transaction is rolled back.
- Function execution then fails fast with an error and enrollment processing does not continue.
- The upload-and-run workflow should fail in this case.

During the interview, candidates should only update repository code, commit/push, and run the approved Azure function trigger path.

### 15. Verify Deployed Applications

#### API Endpoint:
```
https://<api-app-name>.azurewebsites.net/api/Students
```

**Expected Behavior:**
- If Bug #1 NOT fixed: Returns 500 error (database connection fails)
- If Bug #1 fixed: Returns JSON array of students

#### Student Portal:
```
https://<portal-app-name>.azurewebsites.net
```

**Expected Behavior:**
- Site loads successfully
- Search for "Carson Alexander"
- If Bug #2 NOT fixed: Shows 3 credits
- If Bug #2 fixed: Shows 9 credits

### 16. Candidate Briefing Notes (Browser-Only)

Before starting the timer, tell candidates:

- Use GitHub + `vscode.dev` for code changes
- Use Azure Portal for diagnostics and verification
- Do not run services locally with `dotnet run`
- For Question 3, use the provided Azure PowerShell Function trigger path

This keeps candidate behavior aligned with the intended environment and scoring model.

### 17. Verify Application Insights

Navigate to Azure Portal → Application Insights resource

**Check:**
- [ ] Live metrics are showing (app is sending telemetry)
- [ ] Failures section shows errors if Bug #1 is present
- [ ] Logs contain connection errors for candidates to diagnose

### 18. Prepare PowerShell Upload Test Data

Ensure CSV files exist in `src/DataUpload/Enrollment2024/`:
- `Students.csv` - Should have 4+ student records
- `Enrollments.csv` - Enrollment data

**For Question 3 testing:**
Candidates should not run the PowerShell script from a local machine. They should trigger the approved Azure PowerShell Function path and validate execution through Azure-hosted logs.

---

## During the Interview

### Introduction (5 minutes)
1. Welcome the candidate
2. Explain the assessment format (3 questions, 60 minutes)
3. Provide the GitHub repository URL (candidate fork)
4. Provide the Azure Portal URL and read-only credentials
5. Provide deployed API and Student Portal URLs
6. Provide Function App name/URL and the approved Question 3 trigger method
7. Confirm they can access the resources
8. Start the timer

### Candidate Workflow
Candidates will:
1. **Diagnose** issues using Azure Portal, Application Insights, and deployed application
2. **Fix** bugs by editing code in the GitHub repository
3. **Commit and push** changes to trigger GitHub Actions pipelines
4. **Verify** fixes by checking the deployed application after pipeline completes

### Monitoring Progress
- **0-20 min:** Question 1 - Should be diagnosing API failure in Application Insights
- **20-40 min:** Question 2 - Should be fixing C# code and watching pipeline deploy
- **40-60 min:** Question 3 - Should be fixing PowerShell script and validating via Azure Function execution logs
- **Check pipelines:** Monitor their GitHub Actions runs for progress

### What to Observe
- [ ] Do they use Application Insights to diagnose Q1?
- [ ] Do they understand the pipeline logs and deployment process?
- [ ] Do they test changes by visiting the deployed URLs?
- [ ] Do they wait for pipelines to complete before verifying?
- [ ] How do they handle pipeline failures (if any)?

### What to Provide
**DO provide:**
- Azure Portal credentials (read-only viewer role)
- Deployed application URLs
- Question 3 Azure Function trigger instructions
- GitHub repository access

**DON'T provide:**
- Hints about where the bugs are
- Direct access to fix Azure resources
- Solutions or code snippets

### Common Issues

#### "The API is returning 500 errors"
- This is Question 1! They should use Application Insights to diagnose
- Point them to the Failures blade in App Insights if they're stuck

#### "My pipeline is failing"
- Check if they broke the build with syntax errors
- If it's a legitimate build break, that's part of their learning
- Only help if it's an infrastructure issue (secrets missing, etc.)

#### "How do I test my fix?"
- They should wait for the GitHub Actions pipeline to complete
- Then visit the deployed application URL
- For Q3, they should trigger the Azure PowerShell Function path and verify results in function logs

#### "Question 3 still says transaction rolled back"
- Confirm workflow **Build and Deploy Data Upload Function** ran after code changes
- Confirm workflow **Upload Data Files and Run Data Upload Function** ran after CSV/code updates
- Check function response/logs for row-count mismatch details
- If rollback occurs, expected behavior is no student rows inserted and enrollment step skipped

#### "I don't have PowerShell / SQL tools"
- Local tools are not required for this assessment model
- Direct them to the Azure Function trigger path and monitoring logs

---

## Post-Interview

### Scoring
Refer to `SOLUTIONS.md` for:
- Expected solutions
- Scoring criteria
- Red flags

### Debrief Questions
1. "Walk me through how you diagnosed Question 1"
2. "What was the bug in Question 2, and how did you find it?"
3. "What would you do differently with more time?"
4. "How would you prevent these bugs in production?"

---

## Troubleshooting

### The bugs have been fixed in the repo!
```powershell
# Reset to original buggy state
git checkout main
git reset --hard origin/main

# Or restore specific files
git checkout origin/main -- src/Api/appsettings.json
git checkout origin/main -- src/Models/Models/Student.cs
git checkout origin/main -- src/DataUpload.FunctionApp/RunEnrollmentUpload/run.ps1

# Force redeploy
git commit --allow-empty -m "Redeploy buggy version"
git push origin main
```

### Pipeline is failing unexpectedly
- Check GitHub Secrets are configured correctly
- Verify Azure credentials haven't expired
- Check resource group and resources still exist
- Review workflow logs in GitHub Actions

### Application Insights not showing data
- Check connection string is configured in GitHub Variables
- Verify the app is actually running (visit URL)
- Wait 2-5 minutes for data to appear
- Check the Application Insights resource exists in Azure

### Candidate finished too quickly (< 30 minutes)
- Verify all bugs are actually fixed by checking deployed apps
- Check their git commits show proper fixes
- Ask them to add monitoring/alerting improvements
- Discuss how they would prevent these bugs in production

### Candidate is stuck (> 45 minutes on one question)
- Give a hint: "Have you checked Application Insights?" or "What do the pipeline logs show?"
- Suggest they move to the next question and come back
- Consider extending time if infrastructure issues consumed time

---

## Alternative Formats

### Remote Interview (Recommended)
- Share screen while candidate drives
- Watch them navigate Azure Portal and Application Insights
- Observe their git workflow and pipeline monitoring
- Great for seeing real-time problem solving

### Take-Home Assessment
- Provide repository fork and Azure access for 24-48 hours
- Ask for PR with fixes and explanation
- Schedule follow-up to discuss approach and decisions
- Good for candidates in different time zones

### Pair Programming / Live
- Work through issues together in real-time
- Observe thought process as they diagnose
- Ask probing questions during investigation
- Best for evaluating collaboration skills

---

## Candidate Access Checklist

Before the interview, ensure candidate has:

- [ ] GitHub repository access (read/write to their fork)
- [ ] Azure Portal URL and credentials (read-only viewer access)
- [ ] Deployed API URL: `https://<api-name>.azurewebsites.net`
- [ ] Deployed Portal URL: `https://<portal-name>.azurewebsites.net`
- [ ] Application Insights resource name/URL
- [ ] Function App name and Azure Portal access path for Question 3 trigger
- [ ] Function execution log location (Application Insights or Monitor view)
- [ ] Function upload script location in repo: `src/DataUpload.FunctionApp/RunEnrollmentUpload/run.ps1`

---

## Post-Interview Cleanup

After the interview:

```powershell
# Optional: Delete candidate's fork (if using temporary repos)
# Or revoke their Azure access

# Optional: Tear down Azure resources if done with all candidates
az group delete --name "rg-tfl-school-dev" --yes --no-wait

# Or keep infrastructure and just reset the bugs for next candidate
```

---

## Questions?

If you have issues with this assessment setup, please contact [your team/email].

Good luck with the interviews!
