# SolarViewHedonic
The replication package for PNAS article "Impact of Large-scale Solar on Property Values in the US: Diverse Effects and Causal Mechanisms" by Chenyang Hu, Zhenshan Chen, Pengfei Liu, Wei Zhang, Xi He, and Darrell Bosch.

This package include the following items:
1. Data/solar_sites_visibility_PNAS.dta: The LSSPV visibility data for large-scale solar sites in US Large Scale Solar Photovoltaic Database (based on the 2023 version, most recent version is available in https://eerscmap.usgs.gov/uspvdb).
2. Data/solar_sites_visibility_description.dta: A brief introduction of the LSSPV visibility data.
3. Data/presidential_election2016.dta: Presidential election data to check the potential heterogeneity associated with political leaning.
4. Data/household_income_ACSST5Y2020.dta: County median income data to check the potential heterogeneity associated with income level. 
5. Stata do file: CoreLogic1_RawDataProcess_MergeTransNProp.do - Data process from raw CoreLogic dataset
6. Stata do file: CoreLogic2_DataCleaning.do - Data cleaning process for the merged transaction and property dataset
7. Stata do file: CoreLogic3_ArcGISPreprocess.do - Prepare data for ArcGIS analysis and merge ArcGIS results back
8. Stata do file: CoreLogic4_GenerateDataforAnalysis.do - Final coreLogic property data processing to generate data for analysis
9. Stata do file: PNAS_Resi_Home_ExploreDistance.do - Home (below 5 acres) analysis to explore treatment distance specification, including Fig 2
10. Stata do file: PNAS_Home_Analysis.do - Home (below 5 acres) analysis, including Table 1, Fig 3, Fig 4, Fig S7
11. Stata do file: PNAS_Land_Analysis.do - Land (above 5 acres) analysis, including Fig 5, Fig S5, Fig S6 
12. Stata do file: PNAS_AppendixRobust.do - Robustness check, including Table S6, Table S7, Table S8, Table S9,
13. Stata do file: PNAS_PlaceboTest.do - Placebo test, including Table S5
14. Python file: Viewshed1_OutlineToPts.py - Start the viewshed analysis, breaking polygon into view points
15. Python file: Viewshed2_ViewofSolarSitePts.py - Calculate the viewshed of solar site view points
16. Python file: Viewshed3_CombineAllViewRas.py - Combine viewsheds from all solar site view points nationwide
17. Python file: Viewshed4_IntersectPropwithViewshed.py - Intersect the the combined viewshed with property points

## Property Data Sharing Limit
Our property transaction data are acquired from CoreLogic Solutions, LLC (https://www.corelogic.com/360-property-data). Restricted by contract with CoreLogic, data derived from raw CoreLogic data cannot be shared. To replicate our study, we recommend acquiring CoreLogic property data with transactions from 1993 to 2020 and applying the data processing code in this replication package.

## Elevation Data
The Digital elevation models (DEMs) data used for viewshed analysis is acquired from the Shuttle Radar Topographic Mission (SRTM) produced by NASA. Data are available at https://srtm.csi.cgiar.org/.

## Contact
Please contact Zhenshan Chen (zhenshanchen@vt.edu) for any questions regarding the code or data files. Please check the article and SI appendix for more information on the codes and data.

## Citation of the PNAS article (TBA):

## Reference
Fujita, K.S., Ancona, Z.H., Kramer, L.A., Straka, M., Gautreau, T.E., Garrity, C.P., Robson, D., Diffendorfer, J.E., and Hoen, B., 2023, United States Large-Scale Solar Photovoltaic Database (v2.0, August, 2024): U.S. Geological Survey and Lawrence Berkeley National Laboratory data release, https://doi.org/10.5066/P9IA3TUS.  \
MIT Election Data and Science Lab, U.S. President 1976–2020. Harvard Dataverse. https://doi.org/10.7910/DVN/42MVDX. \
A. Jarvis, H. Reuter, A. Nelson, E. Guevara, Hole-filled seamless SRTM data V4. International Centre for Tropical Agriculture (CIAT). https://srtm.csi.cgiar.org/. 
