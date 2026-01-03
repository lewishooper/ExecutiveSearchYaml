# READ SUMMARY REPORT

#
library(tidyverse)
Source<-"E:/ExecutiveSearchYaml/output/all_hospitals_20251024_120624.csv"
Output<-"E:/ExecutiveSearchYaml/output/"

df<-read.csv2(Source,header=TRUE,sep=",")
Hospitals<-df %>%
  filter(!is.na(executive_name))%>%
  group_by(FAC) %>%
  mutate(Execs=n()) %>%
  select(FAC,hospital_name) %>%
  unique()
# 83 hospitals with information 5 where work needs done

saveRDS(df,file.path(Output,"AsofOctober242025.r"))


#
library(tidyverse)
Source<-"E:/ExecutiveSearchYaml/output/all_hospitals_20251024_130202.csv"
Output<-"E:/ExecutiveSearchYaml/output/"

df<-read.csv2(Source,header=TRUE,sep=",")
Hospitals<-df %>%
  filter(!is.na(executive_name))%>%
  group_by(FAC) %>%
  mutate(Execs=n()) %>%
  select(FAC,hospital_name) %>%
  unique()
# 83 hospitals with information 5 where work needs done

saveRDS(df,file.path(Output,"AsofOctober242025v2.r"))


OldWay<-readRDS(file.path(Output,"AsofOctober242025.r"))
NewWay<-readRDS(file.path(Output,"AsofOctober242025v2.r"))
diff<-anti_join(NewWay,OldWay)
