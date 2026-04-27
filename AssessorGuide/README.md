# Assessor Guide

**⚠️ IMPORTANT: Remove this folder before sharing with candidates**

This folder contains:
- `SOLUTIONS.md` - Complete solutions and scoring rubric
- `INTERVIEWER_SETUP.md` - Pre-interview setup instructions (browser-only candidate model)
- `ASSESSMENT_SUMMARY.md` - Quick reference guide

Assessment expectation summary:
- Candidates work in browser tools (`vscode.dev`, GitHub, Azure Portal)
- Validation is against deployed Azure resources (not local runtime)
- Question 3 execution uses an Azure PowerShell Function trigger path

## To Prepare Candidate Repository

```powershell
# Delete this folder before forking/sharing
Remove-Item -Recurse -Force AssessorGuide
```

Or add to `.gitignore` if maintaining separate branches:
```
AssessorGuide/
```
