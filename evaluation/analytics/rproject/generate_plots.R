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
qxts <- xts(df, order.by=df$date)

# Calculate means
# function for computing mean, DS, max and min values
min.mean.sd.max <- function(x) {
  r <- c(min(x), mean(x) - sd(x), mean(x), mean(x) + sd(x), max(x))
  names(r) <- c("ymin", "lower", "middle", "upper", "ymax")
  r
}

min.max.mean <- function(x) c(min = min(x), med = median(x), mean = mean(x), max = max(x))

sapply(d, mode)

keeps <- c("runtime","complete_runtime","size")
DF[keeps]

