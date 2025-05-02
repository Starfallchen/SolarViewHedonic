# SolarViewHedonic
The replication package for PNAS article "Impact of Large-scale Solar on Property Values in the US: Diverse Effects and Causal Mechanisms"

This package include the following items:
1. The LSSPV visibility data for large-scale solar sites in US Large Scale Solar Photovoltaic Database (based on the 2023 version, most recent version is available in https://eerscmap.usgs.gov/uspvdb).
2. A brief introduction of the LSSPV visibility data.
3. Stata do file: CoreLogic1_RawDataProcess_MergeTransNProp - Data process from raw CoreLogic dataset
4. Stata do file: CoreLogic2_DataCleaning - Data cleaning process for the merged transaction and property dataset
5. Stata do file: CoreLogic3_ArcGISPreprocess - Prepare data for ArcGIS analysis and merge ArcGIS results back
6. Stata do file: CoreLogic4_GenerateDataforAnalysis.do - Final coreLogic property data processing to generate data for analysis
7. Stata do file: PNAS_Resi_Home_ExploreDistance.do - Home (below 5 acres) analysis to explore treatment distance specification, including Fig 2
8. Stata do file: PNAS_Home_Analysis.do - Home (below 5 acres) analysis, including Table 1, Fig 3, Fig 4, Fig S7
9. Stata do file: PNAS_Land_Analysis.do - Land (above 5 acres) analysis, including Fig 5, Fig S5, Fig S6 
10. Stata do file: PNAS_AppendixRobust.do - Robustness check, including Table S6, Table S7, Table S8, Table S9,
11. Stata do file: PNAS_PlaceboTest.do - Placebo test, including Table S5
12. Python file: Viewshed1_OutlineToPts.py
13. Python file: Viewshed2_ViewofSolarSitePts.py
14. Python file: Viewshed3_CombineAllViewRas.py
15. Python file: Viewshed4_IntersectPropwithViewshed.py
