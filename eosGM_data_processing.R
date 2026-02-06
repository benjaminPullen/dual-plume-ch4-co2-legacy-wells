##### eosGM Processing Script #####
#Written by Eosense, February 2022
#updated in April 2025 for use with AC-O chamber


#Install libraries 
library(data.table)
library(zoo)
library(grDevices)
library(gridExtra)

##VARIABLES##

wd="~" #set working directory for input and output files
path_in="~" #file path for input data
path_out="eosGM_summary.csv" #file path summary table
collar_height=0 #in m, vertical distance between soil surface and the bottom lip of the chamber
offset=8 #Pump offset, for gas travel time, in s


##############

#Import data
setwd(wd)
f_data=fread(file=path_in,  
           header = T, skip=1, na.strings = "NaN")
f_data=f_data[-c(1,2)]

#Offset status for gas travel time
f_data$AC_Status_Shifted=shift(f_data$AC_Status,n=offset)

#format data
f_data$TIMESTAMP=as.POSIXct(f_data$TIMESTAMP)
f_data$CO2=as.numeric(f_data$CO2)
f_data$LZ_CH4Conc_Avg=as.numeric(f_data$LZ_CH4Conc_Avg)

#tidy ch4 values
f_data$LZ_CH4Conc_Avg <- ifelse(f_data$LZ_CH4Conc_Avg < 1, NA, f_data$LZ_CH4Conc_Avg) 
f_data$LZ_CH4Conc_Avg <- na.approx(f_data$LZ_CH4Conc_Avg,na.rm = F) #interpolate NAs

#Section and index measurements
f_split=subset(f_data,f_data$AC_Status_Shifted==1)#Subset when chamber is closed
f_split$gap=c(0, diff(f_split$TIMESTAMP) > 60) #Flag different measurements 
f_split$group <- cumsum(f_split$gap) + 1  #Index measurements
uniquegroups=unique(f_split$group) #Count measurements

#Create summary table
summary_table=data.frame(Index=integer(),
                         Start_Time=as.POSIXct(character()),
                         CO2_Flux=double(),
                         CO2_RSquared=double(),
                         CH4_Flux=double(),
                         CH4_RSquared=double(),
                         Temp=double(),
                         Pressure=double(),
                         stringsAsFactors=FALSE
                         )

#initialize plot lists and folder
co2list=list()
ch4list=list()
dir.create("plots")
setwd("plots")

#constants for flux calculations
S=0.032#Soil facing surface area of AC in m2 
V=0.005531+collar_height*S #Total system volume in m3: Tubing to chamber vol + eosGM vol + Chamber vol + Collar vol

#Fit for fluxes for each close
for (i in seq_along(uniquegroups)){
  #select and format data
  fluxdata=subset(f_split,group==i)
  fluxdata=na.omit(fluxdata)
  
  fluxdata$seconds=as.numeric(fluxdata$TIMESTAMP)
  pressure=as.numeric(fluxdata$AC_Pressure[1])
  temp=as.numeric(fluxdata$AC_Temp[1])
  
  #co2 flux rate
  co2_flux=lm(formula = seconds~CO2,data = fluxdata)#linear fit x/y
  co2_f=1/as.numeric(co2_flux$coefficients[2])#flip fit to be y/x
  co2_fl=co2_f*V/S #Volume correction
  co2_fc=co2_fl*pressure*1000/(8.3145*(temp+273)) #Ideal gas law correction
  
  #plot co2 with fit
  jpeg(paste0("co2_",i,".jpg"), width = 350, height = 350)
  plot(fluxdata$TIMESTAMP,fluxdata$CO2,main=paste("CO2 - ",i))
  curve((x/co2_flux$coefficients[2]-co2_flux$coefficients[1]/co2_flux$coefficients[2]),add=TRUE)
  co2list[[i]]=recordPlot()
  dev.off()
  
  #ch4 flux rate
  ch4_flux=lm(formula = seconds~LZ_CH4Conc_Avg,data = fluxdata)#linear fit
  ch4_f=1/as.numeric(ch4_flux$coefficients[2])
  ch4_fl=ch4_f*V/S #volume correction
  ch4_fc=ch4_fl*pressure*1000/(8.3145*(temp+273)) #Ideal gas law correction
  
  #plot ch4 with fit
  jpeg(paste0("ch4_",i,".jpg"), width = 350, height = 350)
  plot(fluxdata$TIMESTAMP,fluxdata$LZ_CH4Conc_Avg,main=paste("CH4 - ",i))
  curve((x/ch4_flux$coefficients[2]-ch4_flux$coefficients[1]/ch4_flux$coefficients[2]),add=TRUE)
  ch4list[[i]]=recordPlot()
  dev.off()
  
  #add to table
  summary_table[i,]=c(i,as.character(fluxdata$TIMESTAMP[1]),co2_fc,summary(co2_flux)$r.squared,ch4_fc,summary(ch4_flux)$r.squared,temp,pressure)

}

#output summary csv
setwd(wd)
write.csv(summary_table, file=path_out)





# AC Chamber Status
# '+----------------------------------+
# '|  Status Values                   |
# '|	0	=	Opened Sucessfully          |
# '|	1	=	Closed Sucessfully          |
# '|	2	=	Opening                     |
# '|	3	=	Closing                     |
# '|	4	=	Timeout while Opening       |
# '|	5	=	Timeout while Closing       |
# '|	6	=	Unknown position            |
# '|	7	=	Startup unknown pos.        |
# '|	8	=	Not opened                  |
# '|	9	=	Not closed                  |
# '|	10	=	Not opened, fell closed   |
# '+----------------------------------+


