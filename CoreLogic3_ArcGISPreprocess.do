
clear all
set more off

*Specify directories

global root ""
global dta ""
global AgSolar ""
global GIS  "$AgSolar\GIS"

******************************************************
*      Clean Variables for GIS Analyses       *
******************************************************

********************Bulk****************************
foreach n of numlist 1(1)10 {
use "$dta\CoreLogic_Cleaned_Bulk_`n'.dta",clear
global CATE1 "Aircondition Heated BuildingCondition BuildingType Garage Pool FuelType SewerType WaterType"
global X1 "BuildingAge_e BuildingAge_sq LivingSQFT TotalBathroomNum TotalBedroomNum NoofFirePlace NoofStories ACRES"
global GeoUnit "SITUSSTREETADDRESS SITUSSTREETNAME SITUSCITY FIPSCODE SITUSSTATE SITUSZIPCODE SITUSCOUNTY SITUSCARRIERROUTE MUNICIPALITYNAME TOWNCODE TAXAREACODE SCHOOLDISTRICTNAME NEIGHBORHOODDESCRIPTION SITUSCOREBASEDSTATISTICALAREACBS "

keep MORTGAGEPURCHASEINDICATOR $CATE1 $X1 $GeoUnit FIPSCODE ZONINGCODESTATIC LANDUSECODESTATIC STATEUSEDESCRIPTIONSTATIC SalesPrice SALE_Year SALE_Date ADDLEVELLONGITUDE PARCELLEVELLONGITUDE ADDLEVELLATITUDE PARCELLEVELLATITUDE COMPOSITEPROPERTYLINKAGEKEY Ag SFR PRIMARYCATEGORYCODE DEEDCATEGORYTYPECODE SALETYPECODE SALE_Date

*drop more non-arm's length affect about 1%-4%
keep if PRIMARYCATEGORYCODE=="A"
keep if DEEDCATEGORYTYPECODE=="G"
drop if SALETYPECODE!="F" & SALETYPECODE!=""

count if PARCELLEVELLONGITUDE==.
count if ADDLEVELLONGITUDE==.

gen zip5= substr(SITUSZIPCODE,1,5)
*tab zip5, gen(Zip_)
drop if zip5==""

gen Ln_Price=ln(SalesPrice)
drop if Ln_Price==0 | abs(SalesPrice)<0.0001

*          Check Repeated Sales             *
egen PID = group(SITUSCOUNTY SITUSCITY zip5 SITUSSTREETADDRESS)
drop if PID==.

keep PID SalesPrice Ln_Price $X1 $CATE1 zip5 SITUSSTREETADDRESS SITUSCITY SITUSCOUNTY FIPSCODE SITUSSTATE SALE_Year PARCELLEVELLONGITUDE PARCELLEVELLATITUDE SITUSCOUNTY SITUSCITY zip5 SALE_Year COMPOSITEPROPERTYLINKAGEKEY Ag SFR PRIMARYCATEGORYCODE DEEDCATEGORYTYPECODE SALETYPECODE SALE_Date

sort *

order PID Ln_Price SalesPrice $X1 $CATE1 zip5 SITUSSTREETADDRESS SITUSCITY SITUSCOUNTY FIPSCODE SITUSSTATE SALE_Year PARCELLEVELLONGITUDE PARCELLEVELLATITUDE SITUSCOUNTY SITUSCITY zip5 SALE_Year COMPOSITEPROPERTYLINKAGEKEY Ag SFR PRIMARYCATEGORYCODE DEEDCATEGORYTYPECODE SALETYPECODE SALE_Date

gen ID=_n
save "$dta\CoreLogicProp_Analysis_Bulk_`n'.dta",replace
}

use "$dta\CoreLogicProp_Analysis_Bulk_1.dta",clear
foreach n of numlist 2(1)10 {
append using "$dta\CoreLogicProp_Analysis_Bulk_`n'.dta"
}
save "$dta\CoreLogicProp_All_Analysis_Bulk.dta",replace



**************************************************************************************************
*                              Get GIS variables and Merge back                                  *
**************************************************************************************************

*******Bulk 1 - all other states from CoreLogic*******
*export csv 
use "$dta\CoreLogicProp_All_Analysis_Bulk.dta",clear
keep if ACRES<5
tab Ag SFR

keep if SFR==1
drop if NoofBuildings!=1 /*restriction: only apply to home*/

cap drop ID
gen ID=_n
keep COMPOSITEPROPERTYLINKAGEKEY PARCELLEVELLONGITUDE PARCELLEVELLATITUDE
duplicates drop
sort *
save "$dta\CoreLogicProp_All_Analysis_b5.dta",replace
export delimited using "$GIS\CoreLogicProp1_location_b5.csv", replace
*export into ArcGIS to measure distances & other, the gdb feature class has the same name 

*above 5
use "$dta\CoreLogicProp_All_Analysis_Bulk.dta",clear
keep if ACRES>=5 & ACRES!=.
tab Ag SFR
drop if NoofBuildings!=1 & SFR==1 
drop if (NoofBuildings>=1 & NoofBuildings!=.) & Ag==1 

cap drop ID
gen ID=_n
keep COMPOSITEPROPERTYLINKAGEKEY PARCELLEVELLONGITUDE PARCELLEVELLATITUDE
duplicates drop
sort *
save "$dta\CoreLogicProp_All_Analysis_a5.dta",replace
export delimited using "$GIS\CoreLogicProp1_location_a5.csv", replace
*export into ArcGIS to measure distances & other, the gdb feature class has the same name 



******************************************************************************************************
*      read in property b5 distance measures, merge with property info, & merge with sales info      *
******************************************************************************************************
** 
** read in txt/csv files here
capture import delimited "$GIS\NearDist_Propb5_5solar_new.txt", delimiter(",") clear
drop objectid
ren near_dist near_dist_solar
label variable near_dist_solar "near_dist_solar"
replace near_dist_solar = near_dist_solar/1609.34
ren near_angle near_angle_solar
label variable near_angle_solar "near_angle_solar"

reshape wide near_dist_solar near_angle_solar near_fid, i(in_fid) j(near_rank)
global GIS  "E:\VT\Solar_AgValue\GIS"
save "$GIS\NearDist_b5_5solar_new.dta",replace

capture import delimited "$GIS\NearDist_Propb5_transmission_line_new.txt", delimiter(",") clear
drop objectid
ren near_dist near_dist_line
label variable near_dist_line "near_dist_line"
replace near_dist_line = near_dist_line/1609.34
save "$GIS\NearDist_b5_transmission_line_new.dta",replace

capture import delimited "$GIS\NearDist_Propb5_metropolitan_new.txt", delimiter(",") clear
drop objectid
ren near_dist near_dist_metro
label variable near_dist_metro "near_dist_metro"
replace near_dist_metro = near_dist_metro/1609.34
save "$GIS\NearDist_b5_metropolitan_new.dta",replace


capture import delimited "$GIS\NearDist_Propb5_primary_road_new.txt", delimiter(",") clear
drop objectid
ren near_dist near_dist_road
label variable near_dist_road "near_dist_road"
replace near_dist_road = near_dist_road/1609.34
save "$GIS\NearDist_b5_primary_road_new.dta",replace

* Getting property list from the feature class that's used to measure distances
use "$dta\CoreLogicProp_All_Analysis_b5.dta",clear
*import delimited "$GIS\CoreLogicProp_location_b5.csv",delimiter(",") clear
set type double
gen in_fid=_n
*save "$GIS\Prop_location_b5_new.dta",replace
*use "$GIS\Prop_location_b5_new.dta", clear

*Aggregate distance variables
capture drop _merge
merge 1:1 in_fid using"$GIS\NearDist_b5_5solar_new.dta"
drop if _merge==1
drop _merge
merge 1:1 in_fid using"$GIS\NearDist_b5_transmission_line_new.dta"
drop if _merge==1
drop _merge
merge 1:1 in_fid using"$GIS\NearDist_b5_primary_road_new.dta"
drop if _merge==1
drop _merge
merge 1:1 in_fid using"$GIS\NearDist_b5_metropolitan_new.dta"
drop if _merge==1
drop _merge 

ren SITUSSTREETADDRESS address
ren SITUSCITY city
compress address city
replace address=stritrim(strtrim(address))
replace address=strupper(address)

sort *

drop PID - SALE_Year
drop ID in_fid
duplicates drop
save "$dta\Distances_b5_all_new.dta",replace



******************************************************************************************************
*      read in property a5 distance measures, merge with property info, & merge with sales info      *
******************************************************************************************************
** 
** read in txt/csv files here
capture import delimited "$GIS\NearDist_Propa5_5solar_new.txt", delimiter(",") clear
drop objectid
ren near_dist near_dist_solar
label variable near_dist_solar "near_dist_solar"
replace near_dist_solar = near_dist_solar/1609.34
ren near_angle near_angle_solar
label variable near_angle_solar "near_angle_solar"

sort *
duplicates drop in_fid near_rank, force
reshape wide near_dist_solar near_angle_solar near_fid, i(in_fid) j(near_rank)
global GIS  "E:\VT\Solar_AgValue\GIS"
save "$GIS\NearDist_a5_5solar_new.dta",replace


*Note: May 24th, finished above this line
capture import delimited "$GIS\NearDist_Propa5_metropolitan_new.txt", delimiter(",") clear
drop objectid
ren near_dist near_dist_metro
label variable near_dist_metro "near_dist_metro"
replace near_dist_metro = near_dist_metro/1609.34
save "$GIS\NearDist_a5_metropolitan_new.dta",replace


capture import delimited "$GIS\NearDist_Propa5_primary_road_new.txt", delimiter(",") clear
drop objectid
ren near_dist near_dist_road
label variable near_dist_road "near_dist_road"
replace near_dist_road = near_dist_road/1609.34
save "$GIS\NearDist_a5_primary_road_new.dta",replace


capture import delimited "$GIS\NearDist_Propa5_transmission_line_new.txt", delimiter(",") clear
drop objectid
ren near_dist near_dist_line
label variable near_dist_line "near_dist_line"
replace near_dist_line = near_dist_line/1609.34
save "$GIS\NearDist_a5_transmission_line_new.dta",replace

* Getting property list from the feature class that's used to measure distances
use "$dta\CoreLogicProp_All_Analysis_a5.dta",clear
*import delimited "$GIS\CoreLogicProp_location_a5.csv",delimiter(",") clear
set type double
gen in_fid=_n
*save "$GIS\Prop_location_a5_new.dta",replace
*use "$GIS\Prop_location_a5_new.dta", clear

*Aggregate distance variables
capture drop _merge
merge 1:1 in_fid using"$GIS\NearDist_a5_5solar_new.dta"
drop if _merge==1
drop _merge
merge 1:1 in_fid using"$GIS\NearDist_a5_transmission_line_new.dta"
drop if _merge==1
drop _merge
merge 1:1 in_fid using"$GIS\NearDist_a5_primary_road_new.dta"
drop if _merge==1
drop _merge
merge 1:1 in_fid using"$GIS\NearDist_a5_metropolitan_new.dta"
drop if _merge==1
drop _merge 

ren SITUSSTREETADDRESS address
ren SITUSCITY city
compress address city
replace address=stritrim(strtrim(address))
replace address=strupper(address)

sort *
drop PID - SALE_Year
drop ID in_fid
duplicates drop
save "$dta\Distances_a5_all_new.dta",replace
