# compare  two different summaries from test_all_configured_hospitals.R
# over two different runs (days, etc)
source<-"E:/ExecutiveSearchYaml/output"
OlderVersion<-"all_hospitals_20251028_105948.csv"
NewVersion<-"all_hospitals_20251028_105948.csv"

NewDF<-read.csv2(file.path(source,NewVersion))
OldDF<-read.csv2(file.path(source,OlderVersion))
diff<-anti_join(NewDF,OldDF)                
