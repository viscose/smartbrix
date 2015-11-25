library(ggplot2)

vulnerabilities <- read.csv("~/Documents/src/university/prototypes/smartbrix/evaluation/analytics/normalised_results/vulnerabilities_500.csv")
eval_run <- read.csv("~/Documents/src/university/prototypes/smartbrix/evaluation/analytics/performance_data/eval_run_500.csv")

# Clean up eval 
eval_run_cleaned <- eval_run[eval_run_500$container_name!="cadvisor",]

# Add pretty date
df <- eval_run_cleaned
options(digits.secs = 3)
df$date<-as.POSIXct(df$time/1000, origin="1970-01-01", tz="UTC")

# Convert to timerseries
as.xts(df)