
clear all
set more off
cap log close
set seed 123456789

*Specify directories
global root ""
global dta0 ""

global AgSolar ""
global dta "$AgSolar\data"
global results "$AgSolar\results"

global GIS  "$AgSolar\GIS"
global House_X "TotalRooms TotalBedrooms TotalCalculatedBathCount BuildingAge"

global CATE1 "Aircondition Heated BuildingCondition BuildingType Garage Pool FuelType SewerType WaterType"

*Here we use below 5 acre data processing as an example (b5)
************************************************************************************************
*               Merge distance-measured sales data with solar site data                        * 
************************************************************************************************
use "$dta0\CoreLogicProp_All_Analysis_Bulk.dta",clear
merge m:1 COMPOSITEPROPERTYLINKAGEKEY using"$dta0\Distances_b5_all_new.dta"
drop if _merge==1 | _merge==2
drop _merge

foreach n of numlist 1(1)5 {
ren near_fid`n' fid
merge m:1 fid using"$dta\solar_sites.dta",keepusing(p_area p_year p_cap_ac)
drop if _merge==2
drop _merge
ren p_area p_area_`n'
ren p_year p_year_`n'
ren p_cap_ac p_cap_ac_`n'
ren fid near_fid`n'
}	
save "$dta\data_preanalysis_b5_new.dta",replace

*Can process in multiple bulks if computer capacity is limited

********************************************************************************************************
*       trim data based on distance (drop sales that are too far away to keep t-c balance)             *
********************************************************************************************************
use "$dta\data_preanalysis_b5_new.dta",clear
//drop obs with no sale price info
drop if SalesPrice==.
ren SALE_Year e_Year
*Already keep NoOfBuildings == 1, 98.55% of all obs 

sum near_dist_solar1,d
*Solar sites are everywhere, in this data - 90% of transactions are within 18 miles of any solar site, 95% are within 23 miles of any solar site
*59.4% within 8 mi; 69% within 10 mi.
drop if  near_dist_solar1 >= 20  
/*properties outside 20 mile buffer dropped */

* create buffers for Treatment and Control group
gen solar1T=0
replace solar1T=1 if near_dist_solar1<=2

gen solar2T=0
replace solar2T=1 if near_dist_solar2<=2

gen solar3T=0
replace solar3T=1 if near_dist_solar3<=2

gen solar4T=0
replace solar4T=1 if near_dist_solar4<=2

gen solar5T=0
replace solar5T=1 if near_dist_solar5<=2

gen post=0
replace post=1 if e_Year>p_year_1
*what if the same year, double check here
count if e_Year == p_year_1

*interaction term
gen post_solar1T=post*solar1T
save "$dta\data_Ag_Solar_b5_new.dta",replace

******************************************************
*  Generate viewshed property file & Clean Variables *
******************************************************
*As distance decay study shows the negative effect over distance becomes zero beyond 3.5 miles (with 5.5-6mile property as controls), we create a file involving properties within 6 miles and calculate their viewshed.
use "$dta\data_Ag_Solar_b5_new.dta",clear

ren TotalBathroomNum TotalCalculatedBathCount
tab TotalCalculatedBathCount
drop if TotalCalculatedBathCount>5.5 & TotalCalculatedBathCount!=.

ren TotalBedroomNum TotalBedrooms
drop if TotalBedrooms > 14 & TotalBedrooms!=.

*TotalRooms is not as well populated as TotalBedrooms
foreach v in TotalBedrooms TotalCalculatedBathCount {
	sum `v'
	replace `v'=r(mean) if `v'==.
}

ren ACRES LotSizeAcres 
drop if LotSizeAcres>5

*get some important parcel attr back  - state city
merge m:1 COMPOSITEPROPERTYLINKAGEKEY using"$dta0\CoreLogic_CurAss.dta", keepusing(SITUSCITY SITUSSTATE)
drop if _merge==2
drop _merge

ren SITUSCOUNTY county
ren SITUSSTATE state
egen cty = group(county state)
gen logSalesPrice=log(SalesPrice)

gen logDistSolar1=log(near_dist_solar1)
drop if logDistSolar1==.  /* Land holding solar sites - dropped*/

gen logDistLine=log(near_dist_line)

gen post_logDistLine=post*logDistLine

gen Year_relative = e_Year-p_year_1
tab Year_relative, sum(SalesPrice)  /*good data go back to 34 years ahead*/
drop if Year_relative<-34 | Year_relative>=30

keep if near_dist_solar1<=6  /*8 million dropped */
*Some states, e.g., IA, have most properties (~90%) outside the 6 mile radius of any solar sites
sort *
save "$dta\data_b5_foranalysis_new0.dta",replace


/*Link sites with site outline points
capture import delimited "$GIS\Site_OutlinePoints.txt", delimiter(",") clear
rename ïeia_id eia_id
gen PointID=_n
egen rank = rank(PointID), by(eia_id)
reshape wide PointID, i(eia_id) j(rank)

egen PIDlist=concat(PointID*), punct(,)
gen PID_list=subinstr(PIDlist,".,","",.)
replace PID_list=subinstr(PID_list, ",.","",.)
keep eia_id PID_list
save "$dta\solar_sites_outlinepts.dta",replace
*/

use "$dta\data_b5_foranalysis_new0.dta",clear
gen OID=_n
foreach n of numlist 1(1)5 {
ren near_fid`n' fid
merge m:1 fid using"$dta\solar_sites.dta",keepusing(eia_id)
drop if _merge==2
drop _merge
ren fid near_fid`n'
merge m:1 eia_id using"$dta\solar_sites_outlinepts.dta"
drop if _merge==2
drop _merge
ren eia_id eia_id_`n'
ren PID_list PIDlist_`n'
}

foreach n of numlist 1(1)5 {
	replace PIDlist_`n'="" if near_dist_solar`n'>6
}
sort OID
save "$dta\data_b5_foranalysis_new_1.dta",replace
keep OID PARCELLEVELLONGITUDE PARCELLEVELLATITUDE SITUSSTREETADDRESS SITUSCITY eia_id_* PIDlist_* near_dist_solar*
export delimited using "$GIS\data_b5_foranalysis_new.csv", replace
*This is the property feature "b5_viewanalysis_new"

***************Preprocess census tract************************
capture import delimited "$GIS\b5_proptract_new.txt", delimiter(",") clear
keep oid_1 fid_censustracts tractce
ren oid_1 OID
ren fid_censustracts fidtract

duplicates tag OID, gen(dup)
sort OID *
duplicates drop OID,force
save "$dta\b5_proptract_new.dta",replace


*************Preprocess viewshed analysis results - get visibility index**************
capture import delimited "$GIS\b5_solarview_new.txt", delimiter(",") clear
keep oid_ gridcode
ren oid_ OID
ren gridcode solarview
tab solarview
*21.8 percent with solar view
duplicates tag OID, gen(dup)
gen negsolarview=-solarview
sort OID negsolarview *
duplicates drop OID,force
tab solarview if dup==1
drop dup negsolarview
save "$dta\b5_solarview_new.dta",replace


*************merge viewshed analysis results back to main dataset***************
use "$dta\data_b5_foranalysis_new0.dta",clear
gen OID=_n
merge 1:1 OID using"$dta\b5_solarview_new.dta",keepusing(solarview)
drop if _merge==2
drop _merge
replace solarview=0 if solarview==.
ren solarview solarview_index
gen solarview=(solarview_index>0)
*Now solarview is binary
*use "$dta\data_b5_foranalysis_final.dta",clear

merge 1:1 OID using"$dta\b5_proptract_new.dta",keepusing(fidtract tractce)
drop if _merge==2
drop _merge

egen Tract=group(fidtract)
drop if fidtract==.

ren BuildingAge_e BuildingAge
ren SITUSSTREETADDRESS address

tab Year_relative
drop if Year_relative<-15

gen logDistRoad=log(near_dist_road)
gen logDistMetro=log(near_dist_metro)
replace logDistMetro=0 if logDistMetro==.

gen metro=0
replace metro=1 if near_dist_metro==0
sum near_dist_metro if near_dist_metro!=0,d
gen urban=0
replace urban=1 if near_dist_metro < r(p50)

global House_X "TotalBedrooms TotalCalculatedBathCount"
foreach v in $House_X logDistLine logDistRoad logDistMetro metro {
	sum `v'
	replace `v'=r(mean) if `v'==.
}

*use "$dta\data_b5_foranalysis_final.dta",clear
*drop possible house flipping events (drop sales of the same property within four months of each other)
duplicates tag address county state,gen(duptrans)
tab duptrans

*
ren SALE_Date RecordingDate
tostring RecordingDate, replace
gen SalesYear=substr(RecordingDate,1,4)
gen SalesMonth=substr(RecordingDate,5,2)
gen SalesDay=substr(RecordingDate,7,2)
destring SalesYear,replace
destring SalesMonth,replace
destring SalesDay,replace
gen SalesDate=mdy(SalesMonth,SalesDay,SalesYear)

sort state county address SalesDate * 
egen R_dup1=rank(_n), by(state county address)
tab R_dup1
*Check if the sales for same properties are within 120 days (four months) of each other
*format %td SalesDate 
gen SaleDateGap= SalesDate[_n+1]-SalesDate if address[_n+1]==address

gen MarkforFlip = 1 if R_dup1[_n+1]==R_dup1[_n]+1 & duptrans[_n+1]==duptrans[_n] & SaleDateGap<=120 
gen MarkforFlip_2nd=1 if MarkforFlip[_n-1]==1 & address[_n-1]==address

replace MarkforFlip=1 if MarkforFlip_2nd==1
drop if MarkforFlip==1 /*restriction 195,795 dup transactions within the same season drops, likely including house flipping events*/
capture drop duptrans neg_transprice
*

*Drop houses have more than 6 sale records - likely with some unobserved characteristics
duplicates tag state county address,gen(dupno_sale)
drop if dupno_sale>5
drop dupno_sale

duplicates report state county address
di r(unique_value)
* within 6 miles, 6.42 mi transactions (up to 15 years before site construction), 4.69 mi residential properties
drop MarkforFlip_2nd
drop MarkforFlip

*Merge solar site original land use -  greenfield or not
foreach n of numlist 1(1)5 {
ren near_fid`n' fid
merge m:1 fid using"$dta\solar_sites_withvisibility.dta",keepusing(greenfield TrackingSys p_tilt)
drop if _merge==2
drop _merge
ren fid near_fid`n'
ren greenfield greenfield`n'
ren TrackingSys TrackingSys`n'
ren p_tilt p_tilt`n'
}

gen greenfield_solar=1 if greenfield1==1|greenfield2==1|greenfield3==1|greenfield4==1|greenfield5==1
replace greenfield_solar=0 if greenfield_solar==.
drop greenfield1 greenfield2 greenfield3 greenfield4 greenfield5

foreach n of numlist 1(1)5 {
	replace p_tilt`n' = . if p_tilt`n'==-9999
}

gen TrackingSys=1 if (TrackingSys1==1&near_dist_solar1<=2.5)|(TrackingSys2==1&near_dist_solar2<=2.5)|(TrackingSys3==1&near_dist_solar3<=2.5)|(TrackingSys4==1&near_dist_solar4<=2.5)|(TrackingSys5==1&near_dist_solar5<=2.5)
replace TrackingSys=0 if TrackingSys==.
drop TrackingSys1 TrackingSys2 TrackingSys3 TrackingSys4 TrackingSys5

egen p_tilt=rowmean(p_tilt1 p_tilt2 p_tilt3 p_tilt4 p_tilt5) 
drop p_tilt1 p_tilt2 p_tilt3 p_tilt4 p_tilt5
*use "$dta\data_b5_foranalysis_final.dta",clear
*drop transactions during the recession period (2008-2010), to avoid prices from inequilibrium 
drop if e_Year==2008|e_Year==2009|e_Year==2010
*save "$dta\data_b5_foranalysis_final_new.dta",replace


*use "$dta\data_b5_foranalysis_final_new.dta",clear
*get some important parcel attr back  - state city
merge m:1 COMPOSITEPROPERTYLINKAGEKEY using"$dta0\CoreLogic_CurAss_SFR_AG_CT.dta", keepusing(FIPSCODE)
drop if _merge==2
drop _merge
merge m:1 COMPOSITEPROPERTYLINKAGEKEY using"$dta0\CoreLogic_CurAss_SFR_AG_CO.dta", keepusing(FIPSCODE) update
drop if _merge==2
drop _merge
merge m:1 COMPOSITEPROPERTYLINKAGEKEY using"$dta0\CoreLogic_CurAss_SFR_AG_CA_NY_NC.dta", keepusing(FIPSCODE) update
drop if _merge==2
drop _merge

ren FIPSCODE FIPS

drop PID
drop Ln_Price 
drop BuildingAge_sq
ren NoofStories NoOfStories
ren zip5 PropertyZip 
ren SITUSCITY city
*drop if NoOfStories>3 & NoOfStories!=.

global House_X "TotalBedrooms TotalCalculatedBathCount  BuildingAge "
foreach v in $House_X {
	count if `v'==.
}


*Transfer Prices in 2017 dollar - done during the transaction process
*Inflation Rate is based on Bureau of Labor Statistics CPI
*The first sale is in 1985
replace SalesPrice=SalesPrice*2.28 if e_Year==1985
replace SalesPrice=SalesPrice*2.24 if e_Year==1986
replace SalesPrice=SalesPrice*2.16 if e_Year==1987
replace SalesPrice=SalesPrice*2.07 if e_Year==1988
replace SalesPrice=SalesPrice*1.98 if e_Year==1989
replace SalesPrice=SalesPrice*1.87 if e_Year==1990
replace SalesPrice=SalesPrice*1.80 if e_Year==1991
replace SalesPrice=SalesPrice*1.74 if e_Year==1992
replace SalesPrice=SalesPrice*1.69 if e_Year==1993
replace SalesPrice=SalesPrice*1.65 if e_Year==1994
replace SalesPrice=SalesPrice*1.61 if e_Year==1995
replace SalesPrice=SalesPrice*1.56 if e_Year==1996
replace SalesPrice=SalesPrice*1.53 if e_Year==1997
replace SalesPrice=SalesPrice*1.50 if e_Year==1998
replace SalesPrice=SalesPrice*1.47 if e_Year==1999
replace SalesPrice=SalesPrice*1.42 if e_Year==2000
replace SalesPrice=SalesPrice*1.38 if e_Year==2001
replace SalesPrice=SalesPrice*1.36 if e_Year==2002
replace SalesPrice=SalesPrice*1.33 if e_Year==2003
replace SalesPrice=SalesPrice*1.30 if e_Year==2004
replace SalesPrice=SalesPrice*1.25 if e_Year==2005
replace SalesPrice=SalesPrice*1.21 if e_Year==2006
replace SalesPrice=SalesPrice*1.18 if e_Year==2007
replace SalesPrice=SalesPrice*1.14 if e_Year==2008
replace SalesPrice=SalesPrice*1.14 if e_Year==2009
replace SalesPrice=SalesPrice*1.12 if e_Year==2010
replace SalesPrice=SalesPrice*1.09 if e_Year==2011
replace SalesPrice=SalesPrice*1.07 if e_Year==2012
replace SalesPrice=SalesPrice*1.05 if e_Year==2013
replace SalesPrice=SalesPrice*1.03 if e_Year==2014
replace SalesPrice=SalesPrice*1.03 if e_Year==2015
replace SalesPrice=SalesPrice*1.02 if e_Year==2016
replace SalesPrice=SalesPrice*0.98 if e_Year==2018
replace SalesPrice=SalesPrice*0.96 if e_Year==2019
replace SalesPrice=SalesPrice*0.94 if e_Year==2020
replace SalesPrice=SalesPrice*0.94 if e_Year==2021
replace logSalesPrice=log(SalesPrice)

sort *
drop if near_dist_solar1>6
save "$dta\data_b5_foranalysis_final_new.dta",replace




