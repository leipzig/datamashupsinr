library(XML)
library(PBSmapping)
library(maptools)
library(ROAuth)

cKey<-'put your consumer key here'
cSecret<-'put your consumer secret here'
reqURL<-"http://yboss.yahooapis.com/geo/placefinder"

#input:html filename
#returns:dataframe of geocoded addresses that can be plotted by PBSmapping
getAddressesFromHTML<-function(myHTMLDoc){
  myStreets<-vector(mode="character",0)
  stNum<-"^[0-9]{2,5}(\\-[0-9]+)?"
  stName<-"([NSEW]\\. )?([0-9A-Z ]+)"
  stSuf<-"(St|Ave|Place|Blvd|Drive|Lane|Ln|Rd)(\\.?)$"
  badStrings<-"(\\r| a\\/?[kd]\\/?a.+$| - Premise.+$| assessed as.+$|, Unit.+|<font size=\"[0-9]\">|Apt\\..+| #.+$|[,\"]|\\s+$)"
  myStPat<-paste(stNum,stName,stSuf,sep=" ")
  for(line in readLines(myHTMLDoc)){
      line<-gsub(badStrings,'',line,perl=TRUE)
      matches<-grep(myStPat,line,perl=TRUE,value=FALSE,ignore.case = TRUE)
      if(length(matches)>0){
        myStreets<-append(myStreets,line)
      }
    }
  myStreets
}

#input:vector of streets
#output:data frame containing lat/longs in PBSmapping-acceptable format
#this revised function uses the newer Yahoo BOSS API
geocodeAddresses<-function(myStreets){
  myGeoTable<-data.frame(address=character(),lat=numeric(),long=numeric(),EID=numeric())
  for(myStreet in myStreets){
     requestParams<-c(q=paste(URLencode(myStreet),"+Philadelphia,+PA",sep=""))
     cat("geocoding:",myStreet,"\n")
     tryCatch({
       getResult<-ROAuth:::oauthGET(url=reqURL,consumerKey=cKey,consumerSecret=cSecret,oauthKey=NULL,oauthSecret=NULL,params=requestParams)
       xmlResult<-xmlTreeParse(getResult,isURL=FALSE,addAttributeNamespaces=TRUE)
       geoResult<-xmlResult$doc$children$bossresponse$children$placefinder$children$results$children$result
        if(xmlValue(geoResult[['quality']]) >= 87){
          lat<-xmlValue(geoResult[['latitude']])
          long<-xmlValue(geoResult[['longitude']])
          myGeoTable<-rbind(myGeoTable,data.frame(address = myStreet, Y = lat, X = long,EID=NA))
        }
        }, error=function(err) {
        cat("xml parsing or http error:", conditionMessage(err), "\n")
        })
     Sys.sleep(0.5)
   }

    #let's use the built-in numbering as the event id that PBSmapping wants   
    myGeoTable$EID<-as.numeric(rownames(myGeoTable))
    myGeoTable
}

#Save as html:
#http://www.phillysheriff.com/properties.html
streets<-getAddressesFromHTML("properties.html")
geoTable<-geocodeAddresses(streets)

#Download and unzip
#http://www.temple.edu/ssdl/shpfiles/phila_tracts_2000.zip
myShapeFile<-importShapefile("tracts2000",readDBF=TRUE)
myPolyData<-attr(myShapeFile,"PolyData")

geoTable$X<-as.numeric(levels(geoTable$X))[geoTable$X]
geoTable$Y<-as.numeric(levels(geoTable$Y))[geoTable$Y]

addressEvents<-as.EventData(geoTable)

plotPolys(myShapeFile,axes=FALSE,bg="beige",main="Philadelphia County\July 2009 Foreclosures",xlab="",ylab="")

addressEvents<-as.EventData(geoTable,projection=NA)

addPoints(addressEvents,col="red",cex=.5)

addressPolys<-findPolys(addressEvents,myShapeFile)

myTrtFC<-table(factor(addressPolys$PID,levels=levels(as.factor(myShapeFile$PID))))

mapColors<-heat.colors(max(myTrtFC)+1,alpha=.6)[max(myTrtFC)-myTrtFC+1]

plotPolys(myShapeFile,axes=FALSE,bg="beige",main="Philadelphia County\July 2009 Foreclosure Heat Map",xlab="",ylab="",col=mapColors)
legend("bottomright",legend=max(myTrtFC):0,fill=heat.colors(max(myTrtFC)+1,alpha=.6),title="Foreclosures")

censusTable<-read.table("dc_dec_2000_sf3_u_data1.txt",sep="|",header=TRUE)

censusTable<-merge(x=censusTable,y=myPolyData,by.x='GEO_ID2',by.y='STFID')

myTrtFC<-as.data.frame(myTrtFC)
names(myTrtFC)<-c("PID","FCs")

censusTable<-merge(x=censusTable,y=myTrtFC,by.x="PID",by.y="PID")


