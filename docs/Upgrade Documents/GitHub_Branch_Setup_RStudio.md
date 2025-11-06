# GitHub Branch Setup in RStudio - Phase 2 Guide

## Overview

This guide walks you through setting up a GitHub branch for Phase 2 using RStudio's built-in Git integration. Even if you're new to Git, follow these steps carefully and you'll be set up in 15-20 minutes.

---

## Prerequisites

Before starting, you need:
- [ ] RStudio installed (you have this ✅)
- [ x] Git installed on your computer
- [ x] GitHub account created
- [ x] Your project connected to Git/GitHub

Let's check each one...

---

## Part 1: Check If Git Is Installed

### Step 1: Check Git Installation

In RStudio, go to **Tools → Terminal → New Terminal** and type:

```bash
git --version
```

**Expected result:**
```
git version 2.x.x
```

### If Git is NOT installed:

**Windows:**
1. Download Git from: https://git-scm.com/download/win
2. Run installer with default settings
3. Restart RStudio
4. Try `git --version` again

**Important:** During installation, select "Use Git from the Windows Command Prompt"

---

## Part 2: Check If Your Project Is Already a Git Repository

### Step 1: Look for Git Tab in RStudio

In RStudio, look at the top-right pane. Do you see a **Git** tab?

```
┌─────────────────────────┐
│ Environment History Git │  ← Look for this tab
└─────────────────────────┘
```

### If YES - Git Tab Exists ✅
Your project is already set up with Git. **Skip to Part 3.**

### If NO - No Git Tab ❌
Your project needs to be initialized with Git. **Continue to Step 2.**

---

### Step 2: Initialize Git Repository

**Method 1: Using RStudio (Easiest)**

1. Go to **Tools → Project Options → Git/SVN**
2. Change "Version control system" from **(None)** to **Git**
3. Click **Yes** when asked "Confirm New Git Repository"
4. Click **Yes** when asked to restart RStudio
5. After restart, you should see the **Git** tab

**Method 2: Using Terminal**

In RStudio Terminal:
```bash
cd E:/ExecutiveSearchYaml
git init
```

Then restart RStudio.

---

### Step 3: Create .gitignore File

Before making your first commit, create a `.gitignore` file to exclude unnecessary files.

**In RStudio:**
1. File → New File → Text File
2. Paste this content:

```
# R specific
.Rproj.user/
.Rhistory
.RData
.Ruserdata

# Output files (large CSV files)
output/*.csv
!output/baseline_before_phase2.csv  # Keep baseline

# Temporary files
*.tmp
*.bak
*~

# OS files
.DS_Store
Thumbs.db

# Backups
backups/

# Large data files (if any)
*.rds
```

3. Save as `.gitignore` in your project root (E:/ExecutiveSearchYaml/)
4. Note: On Windows, you may need to save as `gitignore.txt` first, then rename to `.gitignore` in File Explorer

---

### Step 4: Make Your First Commit

**In the Git tab:**

1. Click the **checkbox** next to each file you want to track (start with main files):
   - ✅ pattern_based_scraper.R
   - ✅ enhanced_hospitals.yaml
   - ✅ .gitignore
   - ✅ Any other key files

2. Click **Commit** button

3. In the commit window:
   - Top section shows files being committed
   - Bottom section is for your commit message
   
4. Type commit message:
   ```
   Initial commit - Baseline before Phase 2
   
   - Added pattern_based_scraper.R with 18 pattern functions
   - Added enhanced_hospitals.yaml with 119 hospitals
   - Created .gitignore for R project
   ```

5. Click **Commit** button

6. You should see: "Your branch is ahead of 'origin/main' by 1 commit" or similar

**✅ Your local Git repository is now set up!**

---

## Part 3: Connect to GitHub (If Not Already Connected)

### Check GitHub Connection

In RStudio Terminal, type:
```bash
git remote -v
```

**If you see:**
```
origin  https://github.com/yourusername/yourrepo.git (fetch)
origin  https://github.com/yourusername/yourrepo.git (push)
```
✅ **Already connected to GitHub! Skip to Part 4.**

**If you see:**
```
(nothing)
```
❌ **Need to connect to GitHub. Continue below.**

---

### Step 1: Create GitHub Repository

1. Go to https://github.com
2. Log in to your account
3. Click the **+** icon (top right) → **New repository**
4. Repository name: `ontario-hospital-scraper` (or your choice)
5. Description: "Executive scraper for Ontario hospitals"
6. Choose **Private** (recommended for work projects)
7. **DO NOT** check "Initialize with README" (you already have files)
8. Click **Create repository**

**GitHub will show you setup commands - ignore these, use RStudio method below**

---

### Step 2: Connect RStudio to GitHub

**In RStudio Terminal:**

```bash
# Replace with YOUR GitHub username and repository name
git remote add origin https://github.com/YOUR-USERNAME/ontario-hospital-scraper.git

# Verify connection
git remote -v
```

You should see:
```
origin  https://github.com/YOUR-USERNAME/ontario-hospital-scraper.git (fetch)
origin  https://github.com/YOUR-USERNAME/ontario-hospital-scraper.git (push)
```

---

### Step 3: Set Up GitHub Authentication

**Modern GitHub requires authentication. Two options:**

#### Option A: Personal Access Token (Recommended)

1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Note: "RStudio Git Access"
4. Expiration: 90 days (or your choice)
5. Scopes: Check **repo** (full control of private repositories)
6. Click "Generate token"
7. **COPY THE TOKEN** (you won't see it again!)

**Store token in RStudio:**

In RStudio Console:
```r
# Install credentials package if needed
install.packages("credentials")

# Store your token
credentials::set_github_pat()
```

When prompted, paste your token.

#### Option B: GitHub CLI (Alternative)

```bash
# In Terminal
gh auth login
# Follow prompts
```

---

### Step 4: Push to GitHub

**In RStudio Terminal:**

```bash
# Set default branch name to main (if not already)
git branch -M main

# Push to GitHub
git push -u origin main
```

**If asked for credentials:** Enter your GitHub username and the Personal Access Token (not your password).

**Expected output:**
```
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
...
To https://github.com/YOUR-USERNAME/ontario-hospital-scraper.git
 * [new branch]      main -> main
Branch 'main' set up to track remote branch 'main' from 'origin'.
```

**✅ Your project is now on GitHub!**

Visit `https://github.com/YOUR-USERNAME/ontario-hospital-scraper` to see your files.

---

## Part 4: Create Phase 2 Branch (THE MAIN EVENT!)

Now that Git and GitHub are set up, creating a branch is easy!

### Method 1: Using RStudio GUI (Easiest)

1. **Look at the Git tab** in RStudio
2. **Click the branch dropdown** (it currently says "main")
   ```
   ┌──────────────┐
   │ main ▼      │  ← Click this dropdown
   └──────────────┘
   ```
3. **Click "New Branch"**
4. **Branch name:** `phase2-yaml-recognition`
5. **Sync with remote:** Leave checked ✅
6. **Click "Create"**

**Done!** You're now on the phase2 branch. The dropdown should now show:
```
┌──────────────────────────────┐
│ phase2-yaml-recognition ▼   │
└──────────────────────────────┘
```

### Method 2: Using Terminal (Alternative)

In RStudio Terminal:
```bash
# Create and switch to new branch
git checkout -b phase2-yaml-recognition

# Push branch to GitHub
git push -u origin phase2-yaml-recognition
```

---

## Part 5: Verify Your Branch Setup

### Check 1: Current Branch

**In Git tab**, verify the dropdown shows: `phase2-yaml-recognition`

**Or in Terminal:**
```bash
git branch
```

Should show:
```
  main
* phase2-yaml-recognition  ← asterisk means current branch
```

### Check 2: GitHub Shows Branch

1. Go to your GitHub repository
2. Click the **branch dropdown** (says "main")
3. You should see: `phase2-yaml-recognition` in the list

**✅ Success!** You're ready to start Phase 2 work.

---

## Part 6: Working with Your Branch (Daily Workflow)

### Making Changes and Committing

1. **Edit files** in RStudio (pattern_based_scraper.R, enhanced_hospitals.yaml, etc.)

2. **Stage changes** in Git tab:
   - Click checkboxes next to modified files
   - Review changes by clicking on file name

3. **Commit changes:**
   - Click "Commit" button
   - Write descriptive message:
     ```
     Phase 2: Added recognition_config section to YAML
     
     - Added title_keywords (primary, secondary, medical)
     - Added name_exclusions patterns
     - Added title_exclusions patterns
     ```
   - Click "Commit"

4. **Push to GitHub:**
   - Click the green "Push" arrow ↑ in Git tab
   - Or in Terminal: `git push`

**Tip:** Commit frequently with clear messages. Good practice is to commit after each logical change.

---

## Part 7: Switching Between Branches

### Switch to Main Branch (to see original code)

**In Git tab:**
1. Click branch dropdown
2. Select "main"
3. Your files will change to the main branch version

**Or in Terminal:**
```bash
git checkout main
```

### Switch Back to Phase 2 Branch

**In Git tab:**
1. Click branch dropdown
2. Select "phase2-yaml-recognition"

**Or in Terminal:**
```bash
git checkout phase2-yaml-recognition
```

**Important:** Always commit or stash changes before switching branches!

---

## Part 8: After Phase 2 is Complete

### Option 1: Merge Branch into Main (Recommended)

When Phase 2 is tested and ready:

**In RStudio Terminal:**
```bash
# Switch to main branch
git checkout main

# Merge phase2 branch into main
git merge phase2-yaml-recognition

# Push updated main to GitHub
git push
```

**Or use GitHub Pull Request (better for review):**
1. Go to your GitHub repository
2. Click "Pull requests" tab
3. Click "New pull request"
4. Base: main, Compare: phase2-yaml-recognition
5. Click "Create pull request"
6. Add description, review changes
7. Click "Merge pull request"
8. In RStudio: `git checkout main` then `git pull`

### Option 2: Keep Both Branches

If you want to keep Phase 2 separate:
- Just document which branch is "production"
- Continue working on phase2 branch
- Create new branches for future phases (phase3, phase4, etc.)

---

## Troubleshooting

### Problem: "Git is not installed"

**Solution:**
1. Download from https://git-scm.com
2. Install with default options
3. Restart RStudio
4. Try again

---

### Problem: "Authentication failed"

**Solution:**
- Use Personal Access Token, not password
- Token must have "repo" scope
- Store with `credentials::set_github_pat()`

---

### Problem: "Branch already exists"

**Solution:**
```bash
# Delete local branch
git branch -d phase2-yaml-recognition

# Delete remote branch
git push origin --delete phase2-yaml-recognition

# Create fresh branch
git checkout -b phase2-yaml-recognition
```

---

### Problem: "Your branch is ahead/behind origin"

**Solution - Behind (need to pull):**
```bash
git pull
```

**Solution - Ahead (need to push):**
```bash
git push
```

**Solution - Diverged:**
```bash
# If you want to keep local changes
git pull --rebase

# If you want to discard local changes
git reset --hard origin/phase2-yaml-recognition
```

---

### Problem: "Uncommitted changes prevent branch switch"

**Solution - Commit them:**
```bash
git add .
git commit -m "WIP: saving progress"
```

**Solution - Stash them temporarily:**
```bash
# Save changes
git stash

# Switch branch
git checkout main

# Return and restore changes
git checkout phase2-yaml-recognition
git stash pop
```

---

### Problem: Can't see Git tab in RStudio

**Solution:**
1. Tools → Project Options
2. Git/SVN
3. Version control system: Git
4. Restart RStudio

---

## Quick Reference Card

### Daily Git Workflow
```bash
# 1. Start work (make sure on phase2 branch)
git status

# 2. Make changes to files in RStudio
# (edit pattern_based_scraper.R, etc.)

# 3. Check what changed
git status
git diff

# 4. Stage and commit
git add pattern_based_scraper.R enhanced_hospitals.yaml
git commit -m "Phase 2: Updated validation functions"

# 5. Push to GitHub
git push
```

### Common Commands
```bash
# Check current branch
git branch

# Switch branches
git checkout main
git checkout phase2-yaml-recognition

# See what changed
git status
git log --oneline

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo all local changes (dangerous!)
git reset --hard HEAD
```

---

## RStudio Git Tab Guide

```
┌─────────────────────────────────────────┐
│ Git Tab Layout:                         │
├─────────────────────────────────────────┤
│ [Diff] [Commit] [Pull ↓] [Push ↑]     │  ← Buttons
│                                         │
│ [main ▼] ← Branch dropdown              │
│                                         │
│ Staged  □ Unstaged Files                │  ← Checkboxes to stage
│   ☑ pattern_based_scraper.R             │
│   ☑ enhanced_hospitals.yaml             │
│   □ test_file.R                         │
│                                         │
│ Changes preview shown here →            │
└─────────────────────────────────────────┘
```

**Key Buttons:**
- **Diff:** See changes in selected file
- **Commit:** Open commit dialog
- **Pull ↓:** Download changes from GitHub
- **Push ↑:** Upload your commits to GitHub
- **Branch dropdown:** Switch branches or create new ones

---

## Best Practices for Phase 2

### Commit Messages
Good:
```
Phase 2: Added recognition_config section

- Added title_keywords with 3 categories
- Added exclusion patterns
- Tested YAML loading
```

Bad:
```
updates
fixed stuff
wip
```

### When to Commit
- ✅ After adding YAML section
- ✅ After updating a function
- ✅ After testing passes
- ✅ Before switching branches
- ✅ End of each work session

### When to Push
- ✅ After completing a logical unit of work
- ✅ End of day
- ✅ Before asking for help/review
- ✅ After successful testing

---

## Learning Resources

### RStudio + Git Tutorials
- RStudio Git Guide: https://support.rstudio.com/hc/en-us/articles/200532077
- Happy Git with R: https://happygitwithr.com/
- Git Basics: https://git-scm.com/book/en/v2/Getting-Started-Git-Basics

### Quick Video Tutorials
- "Git and GitHub in RStudio" (YouTube, ~10 min)
- "RStudio Git Integration" (Posit videos)

---

## Summary Checklist

Before starting Phase 2, ensure:

- [ ] Git is installed (`git --version` works)
- [ ] RStudio shows Git tab
- [ ] Project has initial commit
- [ ] Connected to GitHub (can push/pull)
- [ ] Created `phase2-yaml-recognition` branch
- [ ] Currently on phase2 branch (check dropdown)
- [ ] Can commit and push changes
- [ ] Understand basic workflow (edit → stage → commit → push)

**If all checked, you're ready for Phase 2! 🚀**

---

## Next Steps

Once your branch is set up:

1. **Create code2/ folder** as discussed
2. **Copy files to code2/**
3. **Follow Phase2_Quick_Start_Guide.md**
4. **Commit changes frequently**
5. **Push to GitHub regularly**

---

## Getting Help

### If Stuck on Git Setup:
1. Check the Troubleshooting section above
2. Review RStudio Git documentation
3. Happy Git with R book (free online)

### If Git is Too Complex:
The folder + backup approach still works! Git is better but not required.

---

**Good luck with Git setup! The learning curve is worth it. 💪**

---

*Guide Version: 1.0*
*Last Updated: November 6, 2025*
*For: Phase 2 - Ontario Hospital Scraper Project*
