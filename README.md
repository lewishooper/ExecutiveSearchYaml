The purpose of the project is to extact the members of the Hospital executive leadership team from Ontario Hosptials (about 140)
This data will be used to monitor turnover in the executive teams over time. The data set wil also be linke to the Ontario Salary survey data in the future
The focus is on being as acurate as possible. 
the project is using webscrapping tools only and will generate patterns that can be used as guides to extract specific hospitals

Phase 1: Generic approach for ~80% of hospitals
  phase 1a,  get 30 hospitals configured and make a go no go on methods.
Phase 2: Configure the ~20% problematic hospitals individually
Phase 3: Handle edge cases as they come up
Phase 4: data cleanup and  setting this program up to maintain and update a database of Hospital executives in ontario hospitals
 
We are currently in phase 4 of the project, and today we are contining to identify and correct errors in the output
These fall into two general types.
1) a complete failure to identify anyone 
In those cases I find where there is an error that is intended to be pickedup or cleaned up in post processing I have marked the yamal status as ok-PP
2) those edge cases where 1-2 executives listed on the web page are missing in the data. 

