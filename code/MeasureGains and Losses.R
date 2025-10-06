## check agaisnt baseline


library(readxl)



baseline<-read.csv("E:/ExecutiveSearchYaml/output/BaseLineOct51pm.csv")
NewFile<-read.csv("E:/ExecutiveSearchYaml/output/test_10_hospitals_20251005_192738.csv")
diff<-anti_join(NewFile,baseline)
Gains<-anti_join(baseline,NewFile)
