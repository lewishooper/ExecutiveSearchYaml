# Claude Working Preferences - ExecutiveSearchYaml Project

## Project Structure

**Project Root:** `E:\ExecutiveSearchYaml`

### Folder Organization
- **`E:\ExecutiveSearchYaml\code`** - All R scripts and YAML files
- **`E:\ExecutiveSearchYaml\Docs`** - Project documentation
- **`E:\ExecutiveSearchYaml\output`** - Temporary outputs (transitory, not pushed to GitHub, can be regenerated)
- **`E:\ExecutiveSearchYaml\processed`** - Monthly reports from process_hospital_data.R (permanent storage)
- **`E:\ExecutiveSearchYaml\ArchiveCode`** - Archived/deprecated code
- **`E:\ExecutiveSearchYaml\tracking`** - Issue tracking files

### Version Control
- Backups maintained on separate server with versioning system
- Output folder not pushed to GitHub (transitory/regenerable)

## Working Methodology

### Debugging Approach
- **User debugs in own R/RStudio environment**
- Claude provides code snippets and guidance, not full execution
- User executes code and reports results
- User outlines issues with data and code samples when appropriate
- This approach gives user better insight into troubleshooting logic

### Code Output Standards

#### YAML Formatting
When outputting YAML for hospital cards:
- **Add 2 spaces at the beginning of each row**
- This fits R/RStudio formatting styles
- Example:
  ```yaml
    - FAC: '980'
      name: 'TORONTO UNITY HEALTH TORONTO'
      pattern: div_classes
  ```

#### R Code Preferences
- Provide snippets for user to run in their environment
- Focus on problem isolation and correction
- Allow user to execute and verify results

### Documentation
- **Do not write additional documentation without asking first**
- User prefers to control documentation scope and timing
- Exception: When explicitly requested

## Communication Style

### Problem-Solving Flow
1. User describes issue with context
2. User provides relevant data/code samples
3. Claude suggests diagnostic approach
4. User executes in their R environment
5. User reports results
6. Iterate until resolved

### Code Delivery
- Provide code as snippets for user integration
- Explain reasoning behind approach
- Let user decide on implementation

## Project-Specific Context

### Key Files
- **enhanced_hospitals.yaml** - Master hospital configuration (in `code/`)
- **pattern_based_scraper.R** - Core scraping engine (in `code/`)
- **process_hospital_data.R** -creates monthly data files (in 'code/)
- Helper scripts and testing utilities (in `code/`)

### Workflow
- Monthly scraping cycle
- Pre-scrape YAML updates for manually entered executives
- Post-processing and report generation
- Results stored in `processed/` folder with monthly organization

## Session Startup

Quick reminders for new sessions:
- "Debug in my R environment"
- "YAML needs 2-space indent"
- Reference this document for full context

---

*Last Updated: November 2024*
*This document should be uploaded to the Project Knowledge for persistent reference*
