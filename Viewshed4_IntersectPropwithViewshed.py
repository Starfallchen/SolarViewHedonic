# Replication code for solar site viewshed analysis in 
# PNAS article "Impact of Large-scale Solar on Property Values in the US: Diverse Effects and Causal Mechanisms"
# Created by Zhenshan Chen on May 2nd, 2025

# Intersect all site viewshed with the property layer


#import system modules
import arcpy
from arcpy import env
from arcpy.sa import *
import os
import time
import sys

#setup parallel processing
arcpy.env.parallelProcessingFactor = "75%"  # Use 50% of available cores
#Set workspace
gdb = r"...\\SolarSite.gdb"
#Check SA extension license
arcpy.CheckOutExtension("Spatial")
env.workspace=gdb

#Specify property layer
Input_prop=gdb+"\\propb5_viewanalysis"
#Specify viewshed raster layer
Input_View = gdb+ "\\Merged_View_final"
#Specify output layers
VSpoly=gdb+"\\VSpoly"
SolarView=gdb+"\\b5_solarview_new"

# Process: Raster to Polygon
StartTime1=time.process_time()
arcpy.management.Delete(VSpoly,"")
arcpy.conversion.RasterToPolygon(Input_View, VSpoly, "NO_SIMPLIFY", "Value")
StopTime1=time.process_time()
elapsedTime1=(StopTime1-StartTime1)
print('Time for raster to polygon '+' is: '+ str(round(elapsedTime1, 1))+ ' seconds')


StartTime2=time.process_time()
# Process: Intersect property with positive view raster
arcpy.management.Delete(SolarView,"")
arcpy.analysis.Intersect(Input_prop+" #;"+VSpoly+" #", SolarView, "ALL", "", "INPUT")
StopTime2=time.process_time()
elapsedTime2=(StopTime2-StartTime2)
#Result: 1 or above-has view, 0-no view
print('Time for intersect properties with viewshed '+' is: '+ str(round(elapsedTime2, 1))+ ' seconds')

#Export gdb feature to txt - specify output table directory and name
arcpy.conversion.TableToTable(in_rows=SolarView, 
                              out_path=r"...\\GIS", 
                              out_name="b5_solarview_new.txt")
print("Table exported successfully to txt!")
