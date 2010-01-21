# File-Name:       naive_model_9.R                 
# Date:            2010-01-19                                
# Author:          Drew Conway                                       
# Purpose:         Use a SAR model specification to predict from 2010 data with ind vars
#                   for violent and non-violent crimes
# Data Used:       homicides
# Packages Used:   spdep
# Output File:     
# Data Output:     
# Machine:         Drew Conway's MacBook

# Load shapefile of Philadelphia zips
prj<-CRS("+proj=utm +zone=30 +units=km")
shape.data<-readShapeSpatial("shape_files/phila_zipcodes_shp/zipcodes.shp", ID="ZIPCODE", proj4string = prj)

# Load homicde data from this year, plus violent crimes
eb.data<-master.datasets[["everyblock_crimes"]]

# Create data with three columns indexed by zip: number of homicides, number of non-homicide violent crimes, 
# and number of crimes that fit into neither of the other categories
zips<-levels(zipcodes)
homicide.2010<-subset(eb.data,eb.data$crime_type=="Homicide")
homicides<-cbind(sapply(zips,function(x) nrow(subset(homicide.2010,homicide.2010$zip==x))))
colnames(homicides)<-"Homicides"
data.2010<-as.data.frame(homicides)

# Get the non-homicide violent crimes without double counting observations
violent.2010<-subset(eb.data,eb.data$is_violent>0)
violent.all<-cbind(sapply(zips,function(x) nrow(subset(violent.2010,violent.2010$zip==x))))
violent.crimes<-violent.all-homicides

# Get non-violent crimes
other.2010<-subset(eb.data,eb.data$is_violent<1)
other<-cbind(sapply(zips,function(x) nrow(subset(other.2010,other.2010$zip==x))))

# Add dummies for zip codes that contain a water border
deleware<-as.character(c(14,36,35,37,34,25,23,06,47,48,12,53)) # E. Philly border on DE River
schuykill.w<-as.character(c(53,43,04,31)) # West side of Schuykill River
schuykill.e<-as.character(c(12,45,46,03,30,21,32,29,27,28)) # East side
river.list<-list(deleware,schuykill.e,schuykill.w)
river.zips<-lapply(river.list,function(x) paste("191",x,sep=""))

de.dummy<-rep(0,length(zips))
se.dummy<-rep(0,length(zips))
sw.dummy<-rep(0,length(zips))

de.dummy[match(river.zips[[1]],zips)]<-1
se.dummy[match(river.zips[[2]],zips)]<-1
sw.dummy[match(river.zips[[3]],zips)]<-1

# Now add all the data
data.2010<-transform(data.2010,Violent=violent.crimes,Non.Violent=other,DE.Dummy=de.dummy,SE.Dummy=se.dummy,SW.Dummy=sw.dummy)

# Bind variables to shape data
shape.data<-spCbind(shape.data,data.2010)

# Get spatial weights among zip codes
phi.nb<-tri2nb(coordinates(shape.data),row.names=row.names(shape.data)) # Create neighbor object
phi.lw<-nb2listw(phi.nb,style="B")    # Create list of weight

# Create a lagged-SAR using spatial weights, and predict homicides
lag.sar<-lagsarlm(Homicides ~ Violent + Non.Violent, shape.data,phi.lw)
summary(lag.sar)
lag.pred<-predict.sarlm(lag.sar)
pred.lag<-cbind(lag.pred[names(lag.pred)])
if(min(pred.lag)<0) pred.lag<-pred.lag+abs(min(pred.lag)) 

# Create a error-SAR using spatial weights, and predict homicides,
# Inlcude new model with dummies for water borders (er.ar.r)
err.sar.r<-errorsarlm(Homicides ~ Violent + Non.Violent + DE.Dummy + SE.Dummy + SW.Dummy, shape.data,phi.lw)
err.sar<-errorsarlm(Homicides ~ Violent + Non.Violent, shape.data,phi.lw)
# summary(err.sar)
# summary(err.sar.r)
err.pred<-predict.sarlm(err.sar)
pred.err<-cbind(err.pred[names(err.pred)])
if(min(pred.err)<0) pred.err<-pred.err+abs(min(pred.err)) 

# Create a mixed-SAR using spatial weights, and predict homicides
mix.sar<-lagsarlm(Homicides ~ Violent + Non.Violent, shape.data,phi.lw,type="mixed")
summary(mix.sar)
mix.pred<-predict.sarlm(mix.sar)
pred.mix<-cbind(mix.pred[names(mix.pred)])
if(min(pred.mix)<0) pred.mix<-pred.mix+abs(min(pred.mix)) 

# NOTE: Due to current small N on homicides, the models are actually predicting
# negaitive numbers for several zip codes.  I use a simple affine transformation whereby
# all predicted values have the minimum prdicted value added to them. This is a BAD fix, 
# but so far all I could think of.  I welcome other ideas.

# Chose error-sar based on reference that noted it has the best predicitve power for
# models with positive spatial auto-corr

# Build Predictions
predicted.homicides<-cbind(as.character(shape.data$ZIPCODE),as.numeric(2009),as.numeric(pred.err/sum(pred.err)))
colnames(predicted.homicides)<-c("Zipcode","Year","Probability")
rownames(predicted.homicides)<-1:length(shape.data$ZIPCODE)

# Output the data
write.data(predicted.homicides, 'naive_model_9')


pred.all<-cbind(pred.lag,pred.err,pred.mix)
colnames(pred.all)<-c("LAG","ERR","MIX")
