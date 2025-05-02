# Replication code for solar site viewshed analysis in 
# PNAS article "Impact of Large-scale Solar on Property Values in the US: Diverse Effects and Causal Mechanisms"
# Created by Zhenshan Chen on May 2nd, 2025

# Calculate viewshed of each solar site on surrounding areas


#import system modules
import arcpy
from arcpy import env
from arcpy.sa import *
import os
import time
import sys

#Check SA extension license
arcpy.CheckOutExtension("Spatial")

#Set up directories
env.workspace = "\\...\\SolarSite.gdb"
outputroot="...\\Viewshed_site\\"
temp1="\\...\\temp"

#Specify site view points (site perimeter points in this case):
Viewshed_pt=env.workspace+"\\ViewPoints"

#Specify elevation surface 
DEM = env.workspace+"\\..."

#Define project and map (optional)
#c_project=arcpy.mp.ArcGISProject(r"...\\SolarSite_View.aprx")
#c_map=c_project.listMaps()[0]

# Make a layer from the feature class of view points
arcpy.management.Delete("lyr0", "")
lyr=arcpy.management.MakeFeatureLayer(Viewshed_pt,"lyr0")[0]

StartTime0=time.process_time()
 
for n in range(1,28829):
        arcpy.env.extent = "MAXOF"
        #
        VSras_n_tif = outputroot+"Vshed_"+str(n)+".tif"
        StartTime1 = time.process_time()
        arcpy.management.Delete(VSras_n_tif,"")
        arcpy.management.Delete("Site_P_"+str(n),"")
        arcpy.management.Delete("SiteP_buffer_"+str(n),"")
        arcpy.management.Delete("Obs_buffer_"+str(n),"")
        arcpy.management.Delete("LiDAR_bufferclip_"+str(n),"")
        arcpy.management.Delete("LiDAR_obsclip_"+str(n),"")

        # Select one feature
        #arcpy.management.SelectLayerByAttribute("lyr0", "New_SELECTION", '"OBJECTID" = '+str(n))
        lyr.setSelectionSet([n],"NEW")
        
        # Process: Feature To Point
        #arcpy.management.FeatureToPoint("lyr0", "Site_P_"+str(n), "CENTROID") 
        
        # Process: Buffer-mimic the entire region within 10 mile 
        arcpy.analysis.Buffer(lyr, "SiteP_buffer_"+str(n), "10 Miles", "FULL", "ROUND", "NONE", "", "GEODESIC")

        # Process: Buffer-creat an observer-a 300 ft radius (about 90m) pillar-actually one cell of the raster 
        arcpy.analysis.Buffer(lyr, "Obs_buffer_"+str(n), "300 feet", "FULL", "ROUND", "NONE", "", "GEODESIC")

        try:
                # Process: Clip - DEM around the specific site
                arcpy.management.Clip(DEM, "", "LiDAR_bufferclip_"+str(n), "SiteP_buffer_"+str(n), "-3.402823e+038", "ClippingGeometry", "NO_MAINTAIN_EXTENT")
        except:
                arcpy.management.Delete("Site_P_"+str(n),"")
                arcpy.management.Delete("SiteP_buffer_"+str(n),"")
                arcpy.management.Delete("Obs_buffer_"+str(n),"")
                print('Error happened operating feature'+str(n)+', likely due the view point is outside of raster scope')
                pass
        else:
                

                # Process: Clip - the observer clip of surface
                arcpy.management.Clip(DEM, "", "LiDAR_obsclip_"+str(n), "Obs_buffer_"+str(n), "-3.402823e+038", "ClippingGeometry", "NO_MAINTAIN_EXTENT")

                # Process: Raster Calculator raise pillar by 2 meters (mimicing the view from a person standing)
                OutRas = Raster("LiDAR_obsclip_"+str(n))+2
                
                # Process: Raster Calculator replace
                OutRas1 = Con(IsNull(OutRas),"LiDAR_bufferclip_"+str(n),OutRas)


                # Process: Viewshed
                outViewshed = Viewshed(OutRas1,lyr,"1", "FLAT_EARTH", ".13")
                outViewshed.save(VSras_n_tif)

                #Delete temp files
                arcpy.management.Delete("Site_P_"+str(n),"")
                arcpy.management.Delete("SiteP_buffer_"+str(n),"")
                arcpy.management.Delete("Obs_buffer_"+str(n),"")
                arcpy.management.Delete("LiDAR_bufferclip_"+str(n),"")
                arcpy.management.Delete("LiDAR_obsclip_"+str(n),"")


                StopTime0 = time.process_time()
                elapsedTime0=(StopTime0-StartTime1)
                print ('Time for operating feature '+str(n)+' is: '+ str(round(elapsedTime0, 1))+ ' seconds')

 
