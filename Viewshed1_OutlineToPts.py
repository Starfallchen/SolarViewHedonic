# Replication code for solar site viewshed analysis in 
# PNAS article "Impact of Large-scale Solar on Property Values in the US: Diverse Effects and Causal Mechanisms"
# Created by Zhenshan Chen on May 2nd, 2025

# Turn solar site polygon outline into perimeter points

#import system modules
import arcpy
from arcpy import env
from arcpy.sa import *
import os
import time
import sys

#Specify directories, inputs, and outputs
fc_in = r"...\uspvdb_v1_0_20231108.shp"
fc_out = r"...\ViewPoints"
fld_in = "eia_id"
interval = 500 # specify intervals (unit as meters in this case) here

arcpy.management.Delete(fc_out,"")
#Determine the input spatial reference
sr = arcpy.Describe(fc_in).spatialReference

#Create the point feature class (empty)
fc_ws, fc_name = os.path.split(fc_out)
arcpy.CreateFeatureclass_management(fc_ws, fc_name, "POINT", spatial_reference=sr)

#Add fields to the empty feature class
fld = arcpy.ListFields(fc_in, wild_card=fld_in)[0]
arcpy.AddField_management(fc_out, fld_in, fld.type, fld.precision, fld.scale, fld.length)

#Insert points from site polygon outline to the empty output feature class
with arcpy.da.InsertCursor(fc_out, ("SHAPE@", fld_in)) as curs_out:
    with arcpy.da.SearchCursor(fc_in, ("SHAPE@", fld_in)) as curs_in:
        for row_in in curs_in:
            polygon = row_in[0]
            outline = polygon.boundary()
            value = row_in[1]
            d = 0
            while d < outline.length:
                pnt = outline.positionAlongLine(d, False)
                curs_out.insertRow((pnt, value, ))
                d += interval

