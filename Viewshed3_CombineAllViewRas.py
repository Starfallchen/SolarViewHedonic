# Replication code for solar site viewshed analysis in 
# PNAS article "Impact of Large-scale Solar on Property Values in the US: Diverse Effects and Causal Mechanisms"
# Created by Zhenshan Chen on May 2nd, 2025

#Creating combined viewshed raster for all solar sites, cell values representing visibility index
#visibility index: the number of solar site perimeter points that the cell has view on

# Created on: 2024-06-17
# Description:
# ---------------------------------------------------------------------------
# Set the necessary product code
# import arcinfo

#import system modules

import arcpy
from arcpy import env
from arcpy.sa import *
import os
import time
import sys

#setup parallel processing
arcpy.env.parallelProcessingFactor = "75%"  # Use 50% of available cores
#Set up directories
gdb = r"...\\SolarSite.gdb"
#Check SA extension license
arcpy.CheckOutExtension("Spatial")
#Set work environment to the directory holding individual viewshed rasters
env.workspace=r"...\\Viewshed_site"


raster_list = arcpy.ListRasters()
print(raster_list)

output_location=gdb
output_name = "Merged_View"
pixel_type = "8_BIT_UNSIGNED"  # Define the pixel type
number_of_bands = 1          # Define the number of bands
mosaic_method = "SUM"       # Define the mosaic method (other options: "FIRST", "BLEND", etc.)
mosaic_colormap_mode = "MATCH"  # Define the colormap mode


#If you have a very large number of raster files,
# you might need to handle them in chunks to avoid memory issues. 

# Chunk size (number of rasters to process at a time)
chunk_size = 500  # Adjust based on your system's capability

# Function to merge raster files in chunks
def merge_rasters_in_chunks(raster_files, output_location, base_name, chunk_size):
    chunked_outputs = []

    for i in range(0, len(raster_files), chunk_size):
        chunk = raster_files[i:i + chunk_size]
        chunk_output_name = f"{base_name}_part{i // chunk_size}"

        arcpy.MosaicToNewRaster_management(
            input_rasters=chunk,
            output_location=gdb,
            raster_dataset_name_with_extension=chunk_output_name,
            coordinate_system_for_the_raster="",
            pixel_type=pixel_type,
            cellsize="",
            number_of_bands=number_of_bands,
            mosaic_method=mosaic_method,
            mosaic_colormap_mode=mosaic_colormap_mode
        )
        chunked_outputs.append(os.path.join(output_location, chunk_output_name))
        print("finished "+str(i)+" to "+str(i + chunk_size))

    # Merge all chunked outputs into a final raster
    final_output_name = f"{base_name}_final"
    arcpy.MosaicToNewRaster_management(
        input_rasters=chunked_outputs,
        output_location=gdb,
        raster_dataset_name_with_extension=final_output_name,
        coordinate_system_for_the_raster="",
        pixel_type=pixel_type,
        cellsize="",
        number_of_bands=number_of_bands,
        mosaic_method=mosaic_method,
        mosaic_colormap_mode=mosaic_colormap_mode
    )
    return final_output_name

# Call the function to merge rasters in chunks
merged_raster = merge_rasters_in_chunks(raster_list, output_location, output_name, chunk_size)
print(f"Merged raster created: {merged_raster}")

