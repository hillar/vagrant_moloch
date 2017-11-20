#!/usr/bin/r -i
# see http://dirk.eddelbuettel.com/code/littler.html

#install.packages("moments")

samples <- as.integer(readLines())

cat("min",min(samples),"\n")
cat("max",max(samples),"\n")
cat("mean",mean(samples),"\n")
cat("sd",sd(samples),"\n")
cat("variance",var(samples),"\n")
library(moments)
cat("kurtosis",kurtosis(samples),"\n")
cat("skewness",skewness(samples),"\n")
