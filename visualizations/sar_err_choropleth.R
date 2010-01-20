# File-Name:       current_choropleth.R                
# Date:            2010-01-19                                
# Author:          Drew Conway                                       
# Purpose:         Create heat map of predicted probabilities 
# Data Used:       everyblock_crimes
# Packages Used:   
# Output File:     PNG heatmap
# Data Output:     
# Machine:         Drew Conway's MacBook                         
                                                                    
source('library/boot.R')
source('models/naive_model_9.R')

# Function taken from @leoniedu http://stackoverflow.com/questions/1260965/developing-geographic-thematic-maps-with-r
plot.heat <- function(counties.map,state.map,z,title=NULL,breaks=NULL,reverse=FALSE,cex.legend=1,bw=.2,col.vec=NULL,plot.legend=TRUE) {
  ##Break down the value variable
  if (is.null(breaks)) {
    breaks=
      seq(
          floor(min(counties.map@data[,z],na.rm=TRUE)*10)/10
          ,
          ceiling(max(counties.map@data[,z],na.rm=TRUE)*10)/10
          ,.1)
  }
  counties.map@data$zCat <- cut(counties.map@data[,z],breaks,include.lowest=TRUE)
  cutpoints <- levels(counties.map@data$zCat)
  if (is.null(col.vec)) col.vec <- heat.colors(length(levels(counties.map@data$zCat)))
  if (reverse) {
    cutpointsColors <- rev(col.vec)
  } else {
    cutpointsColors <- col.vec
  }
  levels(counties.map@data$zCat) <- cutpointsColors
  plot(counties.map,border=gray(.8), lwd=bw,axes = FALSE, las = 1,col=as.character(counties.map@data$zCat))
  if (!is.null(state.map)) {
    plot(state.map,add=TRUE,lwd=1)
  }
  ##with(counties.map.c,text(x,y,name,cex=0.75))
  if (plot.legend) legend("bottomleft", cutpoints, fill = cutpointsColors,bty="n",title=title,cex=cex.legend)
  ##title("Cartogram")
}

# Add probability data to shape data
shape.data@data$Probability<-as.numeric(predicted.homicides[,3])

# Create col.vec from blue to red, and save image
most.recent<-strsplit(max(eb.data$date)," ")[[1]][1]
png(paste("visualizations/",most.recent,"sar_err_heatmap.png",sep=""),width=800,height=800)
plot.heat(shape.data,shape.data,z="Probability",breaks=hist(shape.data$Probability,plot=FALSE)$breaks)
dev.off()
