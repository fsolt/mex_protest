library(RTextTools)
library(dplyr)
library(beepr)

coded <- c(1, 116, 303, 352, 368, 421, 494, 603, 636, 711, 834, 864, 1141, 1239, 1292, 1361, 1650, 1772)

for (i in 1:length(coded)) {
  dat <- read.csv(paste0("Training/",coded[i],".csv"), stringsAsFactors=F)
  dat <- dat[, c("text", "protest")]
  dat$file <- coded[i]
  if (i==1) data <- dat else data <- rbind(data, dat)
}

meta <- read.csv("file_metadata.csv", stringsAsFactors=F)
data <- left_join(data, meta)

set.seed(324)
data <- data[sample(1:nrow(data), size=nrow(data), replace=FALSE), ]

ptm <- proc.time()
ptm
matrix <- create_matrix(cbind(data["text"], data["country"]), language="spanish",
                        removeNumbers=TRUE, stemWords=FALSE, weighting=tm::weightTfIdf)
#container <- create_container(matrix, data$protest, trainSize=1:round(.75*dim(data)[1]), testSize=(round(.75*dim(data)[1])+1):dim(data)[1], virgin=FALSE)
container <- create_container(matrix, data$protest, trainSize=1:dim(data)[1], virgin=FALSE) #train using all data (no reserved test set)
models <- train_models(container, algorithms=c("SVM","GLMNET","MAXENT", "SLDA","BOOSTING","BAGGING","RF","TREE")) #Also NNET
#models <- train_models(container, algorithms=c("SVM","GLMNET","MAXENT"))
results <- classify_models(container, models)
analytics <- create_analytics(container, results)

summary(analytics)
proc.time()
(proc.time() - ptm)/60
beep()

# write.csv(analytics@label_summary, "label_summary.csv")
# write.csv(analytics@algorithm_summary, "algorithm_summary.csv")
# write.csv(analytics@ensemble_summary, "ensemble_summary.csv")



# save(matrix,file="originalMatrix.Rd")
# save(models1,file="trainedModels.Rd")

# load("originalMatrix.Rd")
# load("trainedModels.Rd")

all.texts <- meta$file[meta$country!="Brasil"]
uncoded <- all.texts[!all.texts %in% coded]

ptm <- proc.time()
dir.create("../Classified", showWarnings = FALSE) # Make Classified directory, if it doesn't already exist

#for (i in 1:length(uncoded)) {
#  cat(i)
library(doParallel)
registerDoParallel(cores=8)

c.d <- foreach(i = 1:length(uncoded), .packages='RTextTools') %dopar% {
  d <- paste0("../Clean_Texts/", uncoded[i], ".txt") %>% 
    readLines %>% 
    data.frame(file = uncoded[i], text = ., stringsAsFactors=F)
  
  d <- left_join(d, meta)
  d["protest"] <- NA

  new_matrix <- create_matrix(cbind(d["text"], d["country"]), language="spanish",
                          removeNumbers=TRUE, stemWords=FALSE, weighting=tm::weightTfIdf, originalMatrix=matrix)
  
  new_container <- create_container(new_matrix, d$protest, testSize=seq(dim(d)[1]), virgin=T)
  
  new_results <- classify_models(new_container, models)
  
  label <- data.frame(sapply(select(new_results, contains("LABEL")), function(j) as.numeric(levels(j))[j]))
  prob <- select(new_results, contains("PROB"))
  new_results <- cbind(label, prob)
  new_results$sum <- rowSums(label)
  d["consensus"] <- as.numeric(new_results$sum>4)
  d$consensus_agree[new_results$sum>4] <- new_results$sum[new_results$sum>4]
  d$consensus_agree[new_results$sum<=4] <- 8-new_results$sum[new_results$sum<=4]
  d
}
(proc.time() - ptm)/60

for (i in 1:length(uncoded)) {
  write.csv(c.d[[i]], paste0("../Classified/", uncoded[i], ".csv"))
  if (i==1) class.data <- c.d[[i]] else class.data <- rbind(class.data, c.d[[i]])
}
class.data <- class.data[, c(1, 7:8, 2:6)]

class.data1 <- class.data
class.data1 %<>% group_by(file) %>% mutate(line = row_number(file))
class.data1$protest <- class.data1$consensus

for (i in 1:length(coded)) {
  dat <- read.csv(paste0("Training/",coded[i],".csv"), stringsAsFactors=F)
  dat <- dat[, c("text", "protest")]
  dat$file <- coded[i]
  if (i==1) data1 <- dat else data1 <- rbind(data1, dat)
} 
data1 %<>% group_by(file) %>% mutate(line = row_number(file))
data1 <- left_join(data1, meta)

class.data2 <- bind_rows(class.data1, data1)
class.data2 <- arrange(class.data2, file, line)

cy.protests <- group_by(class.data2, country, year) %>% summarise(protests = sum(protest), lines = max(line))

write.csv(cy.protests, "cy_protests.csv")




### Brazil
coded <- c(125, 140)
for (i in 1:length(coded)) {
  dat <- read.csv(paste0("Training/",coded[i],".csv"), stringsAsFactors=F)
  dat <- dat[, c("text", "protest")]
  dat$file <- coded[i]
  if (i==1) data <- dat else data <- rbind(data, dat)
}

data <- left_join(data, meta)

set.seed(324)
data <- data[sample(1:nrow(data), size=nrow(data), replace=FALSE), ]

ptm <- proc.time()
ptm
b.matrix <- create_matrix(cbind(data["text"], data["country"]), language="portuguese",
                        removeNumbers=TRUE, stemWords=FALSE, weighting=tm::weightTfIdf)
b.container <- create_container(b.matrix, data$protest, trainSize=1:round(.75*dim(data)[1]), testSize=(round(.75*dim(data)[1])+1):dim(data)[1], virgin=FALSE)
b.models <- train_models(b.container, algorithms=c("SVM","GLMNET","MAXENT", "SLDA","BOOSTING","BAGGING","RF","TREE")) #Also NNET
#b.models <- train_models(b.container, algorithms=c("SVM","GLMNET","MAXENT"))
b.results <- classify_models(b.container, b.models)
b.analytics <- create_analytics(b.container, b.results)

summary(b.analytics)
proc.time()
(proc.time() - ptm)/60
beep()

write.csv(b.analytics@label_summary, "b.label_summary.csv")
write.csv(b.analytics@algorithm_summary, "b.algorithm_summary.csv")
write.csv(b.analytics@ensemble_summary, "b.ensemble_summary.csv")




# missing <- all.texts[!all.texts %in% paste0(class.data3$file, ".txt")]
# ptm <- proc.time()
# dir.create("../Classified", showWarnings = FALSE) # Make Classified directory, if it doesn't already exist
# for (i in 1:length(missing)) {
#   cat(i)
#   d <- paste0("../Clean_Texts/", missing[i]) %>% 
#     readLines %>% 
#     data.frame(file = as.numeric(gsub(".txt", "", missing[i])), text = ., stringsAsFactors=F)
#   
#   d <- left_join(d, meta)
#   d$protest <- NA
#   
#   new_matrix <- create_matrix(cbind(d["text"], d["country"]), language="spanish",
#                               removeNumbers=TRUE, stemWords=FALSE, weighting=tm::weightTfIdf, originalMatrix=matrix)
#   
#   new_container <- create_container(new_matrix, d$protest, testSize=seq(dim(d)[1]), virgin=F)
#   
#   new_results <- classify_models(new_container, models)
#   
#   label <- data.frame(sapply(select(new_results, contains("LABEL")), function(i) as.numeric(levels(i))[i]))
#   prob <- select(new_results, contains("PROB"))
#   new_results <- cbind(label, prob)
#   new_results$sum <- rowSums(label)
#   d$consensus <- as.numeric(new_results$sum>4)
#   d$consensus_agree[new_results$sum>4] <- new_results$sum[new_results$sum>4]
#   d$consensus_agree[new_results$sum<=4] <- 8-new_results$sum[new_results$sum<=4]
#   
#   write.csv(d, paste0("../Classified/", gsub("txt", "csv", missing[i])))
#   if (i==1) class.data <- d else class.data <- rbind(class.data, d)
# }
# class.data <- class.data[, c(1, 7:8, 2:6)]
# (proc.time() - ptm)/60
# class.data$protest <- class.data$consensus

# class.data <- class.data[, c(1, 7:8, 6, 2:5)]
# class.data$protest <- class.data$consensus
# dat <- class.data[class.data$file==1, ]
# dat$protest[dat$text==""] <- 0
# 
# dat[c(1:4, 40, 46, 65, 69, 71, 78:79, 84:87), "protest"] <- 0
# dat[c(75, 77), "protest"] <- 1
# 
# write.csv(dat, "Training/1.csv")

# stems <- c("SVM", "GLMNET", "MAXENTROPY", "SLDA", "LOGITBOOST", "BAGGING", "FORESTS", "TREE")
# #stems <- c("SVM", "GLMNET", "MAXENTROPY")
# prob1 <- prob
# for (j in seq(length(models))) {
#   prob1[label[, j]==0, j] <- 1 - prob1[label[, j]==0, j]
# }
