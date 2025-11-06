# Git in RStudio - Quick Reference Card

## One-Page Guide for Phase 2

---

## Initial Setup (One Time Only)

### 1. Install Git
- Download: https://git-scm.com
- Install with defaults
- Restart RStudio
- Test: `git --version` in Terminal

### 2. Enable Git in RStudio
- Tools → Project Options → Git/SVN
- Version control: **Git**
- Restart RStudio
- Look for **Git tab** (top-right pane)

### 3. First Commit
```bash
# In Terminal
git init
git add .
git commit -m "Initial commit before Phase 2"
```

### 4. Connect to GitHub
```bash
# Create repo on GitHub first, then:
git remote add origin https://github.com/USERNAME/REPO.git
git push -u origin main
```

### 5. Create Phase 2 Branch
**In Git tab:** Click branch dropdown → New Branch → `phase2-yaml-recognition`

**Or in Terminal:**
```bash
git checkout -b phase2-yaml-recognition
git push -u origin phase2-yaml-recognition
```

---

## Daily Workflow

### The Simple 4-Step Process

```
┌─────────────────────────────────────────────┐
│ 1. EDIT FILES                               │
│    Make changes in RStudio                  │
└─────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────┐
│ 2. STAGE CHANGES                            │
│    Git tab: Check boxes next to files       │
└─────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────┐
│ 3. COMMIT                                   │
│    Git tab: Commit button → Write message   │
└─────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────┐
│ 4. PUSH TO GITHUB                           │
│    Git tab: Push ↑ button                   │
└─────────────────────────────────────────────┘
```

---

## RStudio Git Tab Layout

```
┌──────────────────────────────────────────────────┐
│  [Diff] [Commit] [Pull ↓] [Push ↑] [History]   │
│                                                  │
│  Branch: [phase2-yaml-recognition ▼]            │
│                                                  │
│  Staged        Unstaged Files                   │
│  □ M pattern_based_scraper.R                    │
│  □ M enhanced_hospitals.yaml                    │
│  □ ?? test_phase2.R                             │
│                                                  │
│  (Changes preview)                              │
└──────────────────────────────────────────────────┘

Status Codes:
M  = Modified
A  = Added  
D  = Deleted
?? = Untracked (new file)
```

---

## Essential Commands

### Check Status
```bash
git status                    # What changed?
git branch                    # Which branch am I on?
git log --oneline -5         # Recent commits
```

### Switch Branches
```bash
git checkout main                      # Go to main
git checkout phase2-yaml-recognition   # Go to phase2
```

### Commit & Push
```bash
# Stage specific files
git add pattern_based_scraper.R enhanced_hospitals.yaml

# Or stage all changes
git add .

# Commit with message
git commit -m "Phase 2: Updated validation functions"

# Push to GitHub
git push
```

### Sync with GitHub
```bash
git pull      # Download changes from GitHub
git push      # Upload your changes to GitHub
```

### Undo Mistakes
```bash
# Undo last commit (keep changes)
git reset --soft HEAD~1

# Discard all local changes (CAREFUL!)
git reset --hard HEAD

# Undo changes to one file
git checkout -- filename.R
```

---

## Good Commit Messages

### Format
```
Phase 2: Brief summary (50 chars or less)

- Detailed point 1
- Detailed point 2
- Why you made this change
```

### Examples

**Good:**
```
Phase 2: Added recognition_config to YAML

- Added title_keywords (primary/secondary/medical)
- Added exclusion patterns for names and titles
- Tested YAML loading with validate_yaml.R
```

**Bad:**
```
updates
fixed stuff
changes
```

---

## Common Workflows

### Starting Work Session
```bash
git status                        # Check current state
git pull                          # Get latest changes
# Make your changes
```

### Ending Work Session
```bash
git status                        # Review changes
git add .                         # Stage all changes
git commit -m "Description"       # Commit
git push                          # Push to GitHub
```

### Creating Test Branch (for experiments)
```bash
git checkout -b test-new-feature
# Try things out
# If good: merge back
# If bad: delete branch
```

---

## Troubleshooting

### "Your branch is behind"
```bash
git pull
```

### "Your branch is ahead"
```bash
git push
```

### "Uncommitted changes"
```bash
# Option 1: Commit them
git add .
git commit -m "Saving progress"

# Option 2: Stash temporarily
git stash
# (switch branches, do work)
git stash pop
```

### "Merge conflict"
```bash
# Open conflicted files in RStudio
# Look for <<<<<<< and >>>>>>>
# Edit to keep what you want
# Then:
git add conflicted_file.R
git commit -m "Resolved merge conflict"
```

### "Authentication failed"
```r
# In R Console
install.packages("credentials")
credentials::set_github_pat()
# Paste your GitHub Personal Access Token
```

---

## Branch Strategy for Phase 2

```
main branch (original)
  │
  ├─ phase2-yaml-recognition (your work)
  │    │
  │    ├─ commit: Added YAML sections
  │    ├─ commit: Updated functions  
  │    ├─ commit: Added tests
  │    └─ commit: Final validation
  │
  └─ (after Phase 2 complete)
       merge phase2 → main
```

---

## File Organization with Git

```
Your Project/
├── .git/                    # Git data (ignore this)
├── .gitignore              # Files to ignore
├── pattern_based_scraper.R # Tracked by Git
├── enhanced_hospitals.yaml # Tracked by Git
├── test_phase2.R           # Tracked by Git
├── output/
│   └── *.csv              # Ignored (too large)
└── backups/               # Ignored (in .gitignore)
```

---

## .gitignore Template

Create `.gitignore` file in project root:

```gitignore
# R files
.Rproj.user/
.Rhistory
.RData
.Ruserdata

# Output (large files)
output/*.csv
!output/baseline*.csv

# Temp files
*.tmp
*.bak
*~

# OS files  
.DS_Store
Thumbs.db

# Backups
backups/
```

---

## When to Commit

**Do commit after:**
- ✅ Completing a logical change
- ✅ Adding a new feature
- ✅ Fixing a bug
- ✅ Tests pass
- ✅ End of work session

**Don't commit:**
- ❌ Broken code
- ❌ Half-finished features
- ❌ Large binary files
- ❌ Passwords or secrets

---

## When to Push

**Push:**
- ✅ End of day
- ✅ After completing milestone
- ✅ Before asking for help
- ✅ After successful tests
- ✅ When code works

**Don't push:**
- ❌ Broken code
- ❌ Before testing
- ❌ Sensitive data

---

## Merging Phase 2 Back to Main

### When Phase 2 is Complete and Tested:

**Option 1: Direct Merge (Simple)**
```bash
git checkout main
git merge phase2-yaml-recognition
git push
```

**Option 2: Pull Request (Better for Review)**
1. Push phase2 branch to GitHub
2. On GitHub: Create Pull Request
3. Review changes
4. Merge on GitHub
5. Pull in RStudio: `git pull`

---

## Emergency: Undo Everything

**If you need to completely start over:**

```bash
# Discard all uncommitted changes
git reset --hard HEAD

# Go back to main branch
git checkout main

# Delete phase2 branch
git branch -D phase2-yaml-recognition

# Start fresh
git checkout -b phase2-yaml-recognition
```

---

## Resources

**Quick Help:**
- RStudio: Help → Version Control
- In Terminal: `git help <command>`

**Online:**
- Happy Git with R: https://happygitwithr.com
- Git Cheat Sheet: https://education.github.com/git-cheat-sheet-education.pdf

**In RStudio:**
- Tools → Version Control → View History
- Git tab → History button

---

## Remember

1. **Commit often** with clear messages
2. **Push daily** to backup work
3. **Pull before** starting new work
4. **Test before** pushing
5. **Branch** keeps main safe

---

## Phase 2 Specific Workflow

```bash
# Day 1: Setup
git checkout -b phase2-yaml-recognition
# Edit enhanced_hospitals.yaml (add recognition_config)
git add enhanced_hospitals.yaml
git commit -m "Phase 2: Added recognition_config section"
git push

# Day 2: Update functions
# Edit pattern_based_scraper.R
git add pattern_based_scraper.R
git commit -m "Phase 2: Updated validation functions"
git push

# Day 3-5: Continue...
# Regular commits as you work

# Final: Merge when done
git checkout main
git merge phase2-yaml-recognition
git push
```

---

**Print this page and keep it next to your computer! 📄**

*Quick Reference v1.0 - Phase 2 - Ontario Hospital Scraper*
