library(RTextTools)
library(beepr)

coded <- c(116, 303, 352, 368, 421, 494, 603, 636, 711, 834, 864, 1141, 1239, 1292, 1361, 1650, 1772)

for (i in 1:length(coded)) {
  dat <- read.csv(paste0("Training/",coded[i],".csv"))
  if (i==1) data <- dat else data <- rbind(data, dat)
}

matrix <- create_matrix(cbind(data["text"]), language="spanish",
                        removeNumbers=TRUE, stemWords=FALSE, weighting=tm::weightTfIdf)
container1 <- create_container(matrix, data$protest, trainSize=1:450, testSize=451:594, virgin=FALSE)
models1 <- train_models(container1, algorithms=c("SVM","GLMNET","MAXENT", "SLDA","BOOSTING","BAGGING","RF","TREE")) #Also NNET
#models1 <- train_models(container1, algorithms=c("SVM","GLMNET","MAXENT"))
results1 <- classify_models(container1, models1)
analytics1 <- create_analytics(container1, results1)

summary(analytics1)
beep()


# algos <- c("SVM","GLMNET","MAXENT", "SLDA","BOOSTING","BAGGING","RF","TREE")
# cross.val <- list()
# for (i in seq(length(algos))) {
#   cross.val[i] <- cross_validate(container1, 3, algos[i])
# }
