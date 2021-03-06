#Week 6: Final Project Sigma
#Dataset used: Walmart.csv

#####installing and loading required packages#####
install.packages('ggplot2')
install.packages("onehot")
install.packages('glmnet')
install.packages('cluster')
install.packages("DataExplorer")
library(ggplot2)
library(glmnet)
library(onehot)
library(cluster)
library(DataExplorer)


#####Loading the dataset Walmart.csv#####
#Choosing file with treating Columns for "", " ", "?", "NA" values in file as NA
Walmart_input <- read.csv(file = file.choose(), header = TRUE,na.strings = c("", " ", "?", "NA", NA))                 
                                            
#####Cleaning the Walmart dataset#####
Walmart_clean <- Walmart_input    #Initiating the process of cleaning the dataset
Walmart_clean   #Displyaing the Unclean walmart dataset
str(Walmart_clean)          #Displaying the structure of the dataset

#Data cleaning for Fat content
fats <- Walmart_clean$Fat_Content    #Selecting the 'Fat_Content' column
unique(fats)  #Displaying the names of unique values in 'Fat_Content' column
Walmart_clean$Fat_Content[fats == "LF"] <- "Low Fat" #Replacing 'LF' with 'Low Fat' in 'Item_Fat_Content' column
Walmart_clean$Fat_Content[fats == "low fat"] <- "Low Fat"  #Replacing 'low fat' with 'Low Fat' in 'Item_Fat_Content' column
Walmart_clean$Fat_Content[fats == "reg"] <- "Regular"      #Replacing 'reg' with 'Regular' in 'Item_Fat_Content' column
Walmart_clean$Fat_Content <- droplevels(Walmart_clean$Fat_Content)      #Removing the unused levels for 'LF', 'low fat', 'reg'
unique(Walmart_clean$Fat_Content)   #Displaying the names of unique values in 'Item_Fat_Content' column

#Data cleaning for weight column 
weight <- Walmart_clean$Weight      #Selecting the 'Weight' column
summary(weight)   #Displaying statistical summary for 'Weight' to show count of missing values and mean
Count_Weight <- is.na(weight)#Condition checking count of missing values in 'Weight' column
Count_Weight # Displyaing the count of missing values in weight column
weight_mean <- mean(weight[!Count_Weight])  #Computing the weight of available values in 'Weight' column
weight_mean #displaying the mean weight without na values
Walmart_clean$Weight[Count_Weight] <- weight_mean     #Replacing missing values with computed 'mean'
Walmart_clean #Dsiplayng the clean walmart data

# Changing the name of the clean data set 
walmart <- Walmart_clean #New variable assigned to clean dataset
View(walmart) #To view the cleaned data

#####Explorartory Data Analysis#####

#Creating Bar graph for fat content
ggplot(walmart,aes(x=walmart$Fat_Content,fill=walmart$Fat_Content))+geom_bar()+ xlab("Fat Content")+ylab('Frequency')+ labs(title="Number of items sold as per fat content")

#Creating Bar graph for fat outletsize
ggplot(walmart,aes(x=walmart$Outlet_Size,fill=walmart$Outlet_Size))+geom_bar() + xlab("Outlet size")+ylab('Frequency') + labs(title="Number of items sold for each outlet size")

##Creating Bar graph for location type 
ggplot(walmart,aes(x=walmart$Outlet_Location_Type,fill=walmart$Outlet_Location_Type))+geom_bar() + xlab("Location Type")+ylab('Frequency') + labs(title="Number of items sold for each location")

#Creating the correlation between various fields of Walmart dataset
walmart_cr <- walmart[c(2,4,6,8,12)]

#plotting the correlation matrix
plot_correlation(walmart_cr)


##### Hypothesis Testing #####
hype_test<-var.test(walmart$Outlet_Sales[walmart$Fat_Content=="Low Fat"],walmart$Outlet_Sales[walmart$Fat_Content=="Regular"]) #Calculating F test statistics for sale of Low fat vs sale of Regular items
hype_test #Displaying the test results


#####LASSO Regularization#####
#Supressing warning for removed columns and generating one hot encoder for linear regression
options(warn = -1)  #To ignore the warnings
encoder <- onehot(walmart, max_levels = 11) #For one hot encoder
options(warn = 0) #To store warnings till the top level functions returns

data <- data.frame(predict(encoder, walmart))#Converting categorical coloumns to one hot encoded columns using fitted encoder

walmart_sales <- data[, 27] #Response variable :Sales
walmart_sales #Display the sales
walmart_predictors <- data[, -27] #Predictors
walmart_predictors #Display all the predictors : Weight,visibility,MRP,outlet type and identifier etc.
View(walmart_predictors)

cross_val <- cv.glmnet(as.matrix(walmart_predictors), #Performing cross-validation linear regression
                       walmart_sales, #Specifying response variable :Sales
                       nlambda = 500) #Number of lambda values to be used


#Building linear regression model
lmd_1se_cv <- glmnet(as.matrix(walmart_predictors), #Using greater lambda value within one standard error from the minimum value
                     walmart_sales, #Specifying response variable
                     nlambda = cross_val$lambda.1se)#Specifying lambda value

plot(lmd_1se_cv,  #Plotting curve for coefficients for Lasso regularization
     xvar = "norm", #Specifying 'norm'
     label = TRUE,#Displaying labels for each coefficient curve
     main = "Lasso Regularization  - Coefficients")#Specifying title of plot

#####Clustering - k means algorithm#####

walmart_short_clust<-walmart[c(6,12)] #looking for only MRP and Outlet Sales field from the whole data set to derive insights based on the cluster (as these are numeric)
walmart_short_clust #viewing the dataset which has only two variables for study (Gross and Budget)
walmart_clust<-data.matrix(walmart_short_clust) #making the data matrix for the new dataset which has only two variables

wss <- (nrow(walmart_clust)-1)*sum(apply(walmart_clust,2,var)) #performing within sum of squares to understand how many clusters to choose for better results
#iterating for a max of 10 clusters to understand at what point there is no significant differences observed within the clusters
options(warn=-1) #suppressing the warning
for(i in 2:10) wss[i]<-sum(kmeans(walmart_clust,centers=i)$withinss)
#plotting the results of within sum of squares to understand where the value is getting saturated which implies there is no useful information gained when we group data beyond that point
plot(1:10, wss, type ="b", xlab="Number of Clusters", ylab="Within groups sum of squares", col = 'blue')

kc<-kmeans(walmart_clust,5) # K-means clustering with 3 clusters as per the above scree plot result (Elbow method)
plot(walmart_clust,col = (kc$cluster), main = "k means clustering", pch=1, cex=1) #visualizaing a scatterplot of the three groups clustered
points(kc$centers, col='white', pch=8, cex=3) #inserting a point based on the clusters centroids



