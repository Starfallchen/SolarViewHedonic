*This do file produces Table 1, Figure 3, Figure 4, and Figure S7

clear all
set more off
cap log close
set seed 123456789

* Set up directories here
 global AgSolar "..."
// global AgSolar "C:\Users\huchenyang\OneDrive - Virginia Tech\Documents\AgSolar"
global dta "$AgSolar\..."
global results "$AgSolar\..."
global GIS  "$AgSolar\..."
global figures "$AgSolar\..."

global House_X "c.logDistRoad#i.post  c.logDistMetro#i.post  c.TotalBedrooms#i.post  c.TotalCalculatedBathCount#i.post  c.BuildingAge#i.post "

* stcolor_alt  lean2 uncluttered plottig s1rcolor economist
set scheme plotplain


******************************************************************
***      Treatment Effect DID Proximity and View   Table 1     ***
******************************************************************
use "$dta\data_b5_foranalysis_final_new.dta",clear  /* Change dataset name here */
drop if near_dist_solar1>6
*replace post = 1 if e_Year>=p_year_1

*near_fid1 
egen locale=group(Tract)

global control=6
global treat=3
drop if (near_dist_solar1<$treat+2) & (near_dist_solar1>$treat)
drop if (near_dist_solar1>$treat+3)

*treatment term
replace solar1T=0
replace solar1T=1 if near_dist_solar1<=$treat
*View 
gen ViewT=0
replace ViewT=1 if solarview==1

*Main - Separate
*
reghdfe logSalesPrice 1.solar1T 1.post 1.solar1T#1.post logDistLine post_logDistLine $House_X ,  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto DID_ResiHome


*Main - effect estimate
reghdfe logSalesPrice 1.solar1T#0.ViewT 1.post 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine $House_X,  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto DIDVintP_ResiHome

scalar dif_mean = abs(_b[1.solar1T#0b.ViewT#1.post] - _b[1.solar1T#1.ViewT#1.post])
scalar cov = e(V)[5,4]
scalar dif_se = sqrt(_se[1.solar1T#0b.ViewT#1.post]^2+_se[1.solar1T#1.ViewT#1.post]^2-cov)
scalar z_stat = dif_mean/dif_se
di z_stat
scalar p_ztest = 2*(1-normal(z_stat))
di p_ztest
 
*Main - effect estimate drop confounding treatment i.e., invisible within 3 mi
reghdfe logSalesPrice 1.post 1.solar1T#1.ViewT 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine $House_X if (solar1T==1&ViewT==1) | (solar1T!=1),  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto DIDVintP_ResiHome_drop


*Combine Estimates
esttab DID_ResiHome DIDVintP_ResiHome DIDVintP_ResiHome_drop using "$results/Main_results.tex",replace b(a2) se mti("DID Proximity" "DID PintV") keep(1.solar1T 1.solar1T#1.post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post) star(+ 0.10 * 0.05 ** 0.01 *** 0.001)

esttab DID_ResiHome DIDVintP_ResiHome DIDVintP_ResiHome_drop using "$results/Main_results.csv",replace b(a2) se mti("DID Proximity" "DID PintV") keep(1.solar1T 1.solar1T#1.post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post) star(+ 0.10 * 0.05 ** 0.01 *** 0.001)



********************************************************************************
*           Event Study - Resi Home - Proximity as treatment   Figure 3        *
********************************************************************************
use "$dta\data_b5_foranalysis_final_new.dta",clear   /* Change dataset name here */
drop if near_dist_solar1>6

*Generate Event Study years
gen Year_event=Year_relative+10
drop if Year_relative>10
drop if Year_event<0

global control=6
global treat=3
	*treatment term
	replace solar1T=0
	replace solar1T=1 if near_dist_solar1<=$treat

*View as treatment - specifically, solar site view within 6miles
gen ViewT=0
replace ViewT=1 if solarview==1

egen locale=group(Tract)
est clear

*drop if ViewT==0 & solar1T==1

drop if (near_dist_solar1<$treat+2) & (near_dist_solar1>$treat)
drop if (near_dist_solar1>$treat+3)

global House_X0 "c.logDistRoad#i.post  c.logDistMetro#i.post  c.TotalBedrooms#i.post  c.TotalCalculatedBathCount#i.post "
*regression on  property less than 5 acres, prior3 as base

reghdfe logSalesPrice 1.solar1T ib7.Year_event ib7.Year_event#1.solar1T logDistLine post_logDistLine $House_X0 if Year_event>=0 , a(i.locale#i.e_Year) cluster(locale e_Year)

eststo event_study_Resi_p3
*mat list e(b)
*mat list e(V)
parmest, saving($results\event_study_Resi_results.dta, replace)

use $results\event_study_Resi_results.dta, clear
keep in 26/43

* Generate a numeric variable for the yearcategories
gen year = _n
*drop the base year
// drop if year==5
destring year, replace

* Create variables for the confidence intervals
gen ci_low = min95
gen ci_high = max95

* List the data to verify
// list
*
twoway (rarea ci_low ci_high year, lcolor(orange%1) color(orange%10) ysc(range(-0.12 0.05))) ///
       (connected estimate year, mcolor(blue) ysc(range(-0.12 0.05))), ///
       xlabel(1 " prior year 7" 2 "prior year 6" 3 "prior year 5" 4 "prior year 4" 5"prior year 3" 6"prior year 2" 7"prior year 1" 8"year 0" 9"year 1" 10"year 2" 11 "year 3" 12"year 4" 13 "year 5" 14 "year 6" 15 "year 7" 16 "year 8" 17 "year 9" 18 "year 10",angle(45)) ///
    legend(label(1 "95% CI Event study") label(2 "Point Estimates")  position(2) ring(0)) ///
    ytitle("Effect on Natural Logarithm of Home Price") xtitle(Year) ///
	xline(5, lw(vthin) lc(red)) ///
    yline(0, lw(thin) lcolor(grey)) ylabel(-0.15 -0.1 -0.05 0 0.05 0.1) ysc(range(-0.15 0.1))
	
	//	xtitle("Year") ///
/// 	title("Event Study - Effect of Visible Solar Site within 3 miles") ///
//	19 "year 9" 20 "year 10" 21 "year 11" ///
	
graph export "$results\ResHomeb5_eventstudy_Proxy.tif",as(tif) replace
graph export "$results\ResHomeb5_eventstudy_Proxy.pdf",as(pdf) replace



********************************************************************************
********************************************************************************
********************************************************************************
**     Heterogeneity analysis     on Resi Home   Proximity  Figure 4        ****
********************************************************************************
********************************************************************************
// 1. Rural/urban
// 2. Small/big ag lot
// 3. Region
// 4. political leaning
// 5. Small/big solar farm size
// 6. income
// 7. public involvement
// 8. Solar angle
// 9. Tracking System
// etc.

use "$dta\data_b5_foranalysis_final_new.dta",clear  /* Change dataset name here */
drop if near_dist_solar1>6

ren state State
tab State
*distinct State

global control=6
global treat=3
drop if (near_dist_solar1<$treat+2) & (near_dist_solar1>$treat)
drop if (near_dist_solar1>$treat+3)
*treatment term
replace solar1T=0
replace solar1T=1 if near_dist_solar1<=$treat

merge m:1 FIPS using "$dta\presidential_election2016.dta", keepusing(FIPS perc_republican perc_democrat DEM)
drop if _merge==2
drop _merge
merge m:1 FIPS using "$dta\household_income_ACSST5Y2020.dta", keepusing(FIPS income high_income)
drop if _merge==2
drop _merge

gen Dem= ( perc_democrat> 65 )

drop TrackingSys
*Merge solar site tracking system -  tracking or not
foreach n of numlist 1(1)5 {
ren near_fid`n' fid
merge m:1 fid using"$dta\solar_sites_withvisibility.dta",keepusing(TrackingSys)
drop if _merge==2
drop _merge
ren fid near_fid`n'
ren TrackingSys TrackingSys`n'
}

egen TrackingSys=rowmean(TrackingSys1 TrackingSys2 TrackingSys3 TrackingSys4 TrackingSys5)
replace TrackingSys=1 if TrackingSys>0.2 | TrackingSys1==1
replace TrackingSys=0 if TrackingSys!=1
drop TrackingSys1 TrackingSys2 TrackingSys3 TrackingSys4 TrackingSys5

* dummy for heterogeneity analysis
gen rural=0
replace rural=1 if near_dist_metro > 0

cap drop biglot
gen biglot=0
sum LotSizeAcres,d
replace biglot=1 if LotSizeAcres>r(p50) /* .2 acre*/
	
gen NE=0
replace NE=1 if State=="CT"|State=="ME"|State=="MA"|State=="NH"|State=="NJ"|State=="NY"|State=="PA"|State=="RI"|State=="VT"

gen S=0
replace S=1 if State=="MD"|State=="DE"|State=="FL"|State=="VA"|State=="NC"|State=="SC"|State=="GA"|State=="MS"|State=="AL"|State=="TX"|State=="OK"|State=="WV"|State=="KY"|State=="TN"|State=="AR"|State=="OK"

gen W=0
replace W=1 if State=="AZ"|State=="CA"|State=="NV"|State=="UT"|State=="NM"|State=="CO"|State=="OR"|State=="WA"

gen MW=0
replace MW=1 if State=="IL"|State=="IN"|State=="OH"|State=="MI"|State=="WI"|State=="IA"|State=="MN"|State=="MO"|State=="NE"|State=="SD"

* 3 from Lawrence Berkeley National Laboratory
gen public_involvement=1
replace public_involvement=0 if State=="AK"|State=="ID"|State=="MT"|State=="UT"|State=="NV"|State=="CO"|State=="KS"|State=="MO"|State=="IN"|State=="LA"|State=="PA"|State=="NJ"|State=="DE"|State=="AL"|State=="GA"|State=="TX"|State=="PR"

gen public_guidance=1
replace public_guidance=0 if State=="VT"|State=="NH"|State=="ID"|State=="MT"|State=="SD"|State=="IL"|State=="PA"|State=="CO"|State=="WV"|State=="DE"|State=="NM"|State=="KS"|State=="AR"|State=="SC"|State=="NC"|State=="OK"|State=="LA"|State=="MS"|State=="AL"|State=="GA"|State=="TX"|State=="PR"

gen model_ordinance=1
replace model_ordinance=0 if State=="AK"|State=="VT"|State=="WA"|State=="ID"|State=="MT"|State=="ND"|State=="WY"|State=="SD"|State=="NV"|State=="CO"|State=="MO"|State=="WV"|State=="MD"|State=="DE"|State=="AZ"|State=="NM"|State=="KS"|State=="AR"|State=="SC"|State=="OK"|State=="MS"|State=="AL"|State=="HI"|State=="PR"


forv n = 1(1)5 {
	cap drop IDclose_`n'
	gen IDclose_`n'=(near_dist_solar`n'<=6)
}
cap drop p_area_total
gen p_area_total=IDclose_1*p_area_1+IDclose_2*p_area_2+IDclose_3*p_area_3+IDclose_4*p_area_4+IDclose_5*p_area_5

cap drop bigUSS
sum p_area_total,d
gen bigUSS=0
replace bigUSS=1 if p_area_total >  r(p50) /* about 20.3 acres*/


gen solarangle=0
replace solarangle=0
replace solarangle=1 if near_angle_solar1>45 & near_angle_solar1<135 
// &near_dist_solar1<3

*View as treatment
gen ViewT=0
replace ViewT=1 if solarview==1  /*& near_dist_solar1<=$treat */

gen HighView=0
sum solarview_index if solarview_index>0,d
replace HighView=1 if solarview_index >  r(p50) /* 3*/


egen locale=group(Tract)
est clear
*regression on  property less than 5 acres, prior3 as base

***************************************************
*regression on Resi Home  - NE / S  / W / MW
***************************************************

*1. separate regression - NE
reghdfe logSalesPrice post 1.solar1T 1.solar1T#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if NE==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_NE = _b[1.solar1T#1.post]
scalar se_NE = _se[1.solar1T#1.post]

// Calculate the 95% CI bounds
scalar lb_NE = coef_NE - 1.96 * se_NE
scalar ub_NE = coef_NE + 1.96 * se_NE

*2. separate regression - S
reghdfe logSalesPrice post 1.solar1T 1.solar1T#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if S==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// vce(robust)
bysort locale e_Year: gen group_obs = _N if S==1
summarize group_obs

// Extract the coefficient and S.E. 
scalar coef_S = _b[1.solar1T#1.post]
scalar se_S = _se[1.solar1T#1.post]

// Calculate the 95% CI bounds
scalar lb_S = coef_S - 1.96 * se_S
scalar ub_S = coef_S + 1.96 * se_S

*3. separate regression - W
reghdfe logSalesPrice post 1.solar1T 1.solar1T#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if W==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_W = _b[1.solar1T#1.post]
scalar se_W = _se[1.solar1T#1.post]

// Calculate the 95% CI bounds
scalar lb_W = coef_W - 1.96 * se_W
scalar ub_W = coef_W + 1.96 * se_W


*4. separate regression
reghdfe logSalesPrice post 1.solar1T 1.solar1T#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if MW==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_MW = _b[1.solar1T#1.post]
scalar se_MW = _se[1.solar1T#1.post]

// Calculate the 95% CI bounds
scalar lb_MW = coef_MW - 1.96 * se_MW
scalar ub_MW = coef_MW + 1.96 * se_MW

***************************************************
*regression on Resi Home  - rural vs urban
***************************************************

*1. separate regression
reghdfe logSalesPrice post 1.solar1T 1.solar1T#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if rural==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_rural = _b[1.solar1T#1.post]
scalar se_rural = _se[1.solar1T#1.post]

// Calculate the 95% CI bounds
scalar lb_rural = coef_rural - 1.96 * se_rural
scalar ub_rural = coef_rural + 1.96 * se_rural


*2. separate regression
reghdfe logSalesPrice post 1.solar1T 1.solar1T#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if rural==0,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_urban = _b[1.solar1T#1.post]
scalar se_urban = _se[1.solar1T#1.post]

// Calculate the 95% CI bounds
scalar lb_urban = coef_urban - 1.96 * se_urban
scalar ub_urban = coef_urban + 1.96 * se_urban

*Conduct z-test
scalar dif_mean = abs(coef_rural - coef_urban)
scalar dif_se = sqrt(se_rural^2+se_urban^2)
scalar z_stat = dif_mean/dif_se
di z_stat
scalar p_ztest = 2*(1-normal(z_stat))
di "z_stat is: " z_stat "  p_value is: " p_ztest

mat Z=J(1,6,.)
mat Z=(Z\coef_rural,se_rural,coef_urban, se_urban, z_stat, p_ztest)

***************************************************
*regression on Resi Home  - small / big lot
***************************************************


*1. separate regression
reghdfe logSalesPrice post 1.solar1T 1.solar1T#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if biglot==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_biglot = _b[1.solar1T#1.post]
scalar se_biglot = _se[1.solar1T#1.post]

// Calculate the 95% CI bounds
scalar lb_biglot = coef_biglot - 1.96 * se_biglot
scalar ub_biglot = coef_biglot + 1.96 * se_biglot



*2. separate regression
reghdfe logSalesPrice post 1.solar1T 1.solar1T#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if biglot==0,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_smalllot = _b[1.solar1T#1.post]
scalar se_smalllot = _se[1.solar1T#1.post]

// Calculate the 95% CI bounds
scalar lb_smalllot = coef_smalllot - 1.96 * se_smalllot
scalar ub_smalllot = coef_smalllot + 1.96 * se_smalllot




***************************************************
*regression on Resi Home   - political leaning
***************************************************
*1. separate regression
*
reghdfe logSalesPrice post 1.solar1T 1.solar1T#1.post logDistLine post_logDistLine $House_X if Dem==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_blue = _b[1.solar1T#1.post]
scalar se_blue = _se[1.solar1T#1.post]

// Calculate the 95% CI bounds
scalar lb_blue = coef_blue - 1.96 * se_blue
scalar ub_blue = coef_blue + 1.96 * se_blue


*2. separate regression
*perc_republican>65
reghdfe logSalesPrice post 1.solar1T 1.solar1T#1.post logDistLine post_logDistLine $House_X if Dem==0,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E.
scalar coef_red = _b[1.solar1T#1.post]
scalar se_red = _se[1.solar1T#1.post]

// Calculate the 95% CI bounds
scalar lb_red = coef_red - 1.96 * se_red
scalar ub_red = coef_red + 1.96 * se_red



*Conduct z-test
scalar dif_mean = abs(coef_blue - coef_red)
scalar dif_se = sqrt(se_blue^2+se_red^2)
scalar z_stat = dif_mean/dif_se
di z_stat
scalar p_ztest = 2*(1-normal(z_stat))
di "z_stat is: " z_stat "  p_value is: " p_ztest

mat Z=(Z\coef_blue,se_blue,coef_red,se_red, z_stat, p_ztest)



***************************************************
*regression on Resi Home  - big USS
***************************************************

*1. separate regression
reghdfe logSalesPrice post 1.solar1T 1.solar1T#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if bigUSS==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_bigUSS = _b[1.solar1T#1.post]
scalar se_bigUSS = _se[1.solar1T#1.post]

// Calculate the 95% CI bounds
scalar lb_bigUSS = coef_bigUSS - 1.96 * se_bigUSS
scalar ub_bigUSS = coef_bigUSS + 1.96 * se_bigUSS

*2. separate regression
reghdfe logSalesPrice post 1.solar1T 1.solar1T#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if bigUSS==0,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E.
scalar coef_smallUSS = _b[1.solar1T#1.post]
scalar se_smallUSS = _se[1.solar1T#1.post]

// Calculate the 95% CI bounds
scalar lb_smallUSS = coef_smallUSS - 1.96 * se_smallUSS
scalar ub_smallUSS = coef_smallUSS + 1.96 * se_smallUSS

***************************************************
*regression on Resi Home  - income
***************************************************

*1. separate regression
reghdfe logSalesPrice post 1.solar1T 1.solar1T#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if high_income==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_highincome = _b[1.solar1T#1.post]
scalar se_highincome = _se[1.solar1T#1.post]

// Calculate the 95% CI bounds
scalar lb_highincome = coef_highincome - 1.96 * se_highincome
scalar ub_highincome = coef_highincome + 1.96 * se_highincome


*2. separate regression
reghdfe logSalesPrice post 1.solar1T 1.solar1T#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if high_income==0,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_lowincome = _b[1.solar1T#1.post]
scalar se_lowincome = _se[1.solar1T#1.post]

// Calculate the 95% CI bounds
scalar lb_lowincome = coef_lowincome - 1.96 * se_lowincome
scalar ub_lowincome = coef_lowincome + 1.96 * se_lowincome



***************************************************
*regression on Resi Home  - public_involvement----the result seems reasonable
***************************************************

*1. separate regression
reghdfe logSalesPrice post 1.solar1T 1.solar1T#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if public_involvement==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_pub_involve = _b[1.solar1T#1.post]
scalar se_pub_involve = _se[1.solar1T#1.post]

// Calculate the 95% CI bounds
scalar lb_pub_involve = coef_pub_involve - 1.96 * se_pub_involve
scalar ub_pub_involve = coef_pub_involve + 1.96 * se_pub_involve


*2. separate regression
reghdfe logSalesPrice post 1.solar1T 1.solar1T#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if public_involvement==0,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_no_involve = _b[1.solar1T#1.post]
scalar se_no_involve = _se[1.solar1T#1.post]

// Calculate the 95% CI bounds
scalar lb_no_involve = coef_no_involve - 1.96 * se_no_involve
scalar ub_no_involve = coef_no_involve + 1.96 * se_no_involve



*Conduct z-test
scalar dif_mean = abs(coef_pub_involve - coef_no_involve)
scalar dif_se = sqrt(se_pub_involve^2+se_no_involve^2)
scalar z_stat = dif_mean/dif_se
di z_stat
scalar p_ztest = 2*(1-normal(z_stat))
di "z_stat is: " z_stat "  p_value is: " p_ztest

mat Z=(Z\ coef_pub_involve,se_pub_involve,coef_no_involve, se_no_involve, z_stat, p_ztest)



***************************************************
*regression on Resi Home  - High View Index
***************************************************
*3. dummy interaction with treatment
reghdfe logSalesPrice post 1.solar1T 1.solar1T#1.HighView#1.post 1.solar1T#0.HighView#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X ,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_highview = _b[1.solar1T#1.HighView#1.post]
scalar se_highview = _se[1.solar1T#1.HighView#1.post]

// Calculate the 95% CI bounds
scalar lb_highview = coef_highview - 1.96 * se_highview
scalar ub_highview = coef_highview + 1.96 * se_highview


// Extract the coefficient and S.E. 
scalar coef_lowview = _b[1.solar1T#0.HighView#1.post]
scalar se_lowview = _se[1.solar1T#0.HighView#1.post]

// Calculate the 95% CI bounds
scalar lb_lowview = coef_lowview - 1.96 * se_lowview
scalar ub_lowview = coef_lowview + 1.96 * se_lowview

scalar cov = e(V)[4,3]

*Conduct z-test
scalar dif_mean = abs(coef_highview - coef_lowview)
scalar dif_se = sqrt(se_highview^2+se_lowview^2-cov)
scalar z_stat = dif_mean/dif_se
di z_stat
scalar p_ztest = 2*(1-normal(z_stat))
di "z_stat is: " z_stat "  p_value is: " p_ztest

mat Z=(Z\coef_highview,se_highview, coef_lowview, se_lowview, z_stat, p_ztest)

***************************************************
*regression on Resi Home  -  USS angle
***************************************************

*1. separate regression
reghdfe logSalesPrice post 1.solar1T 1.solar1T#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if LotSizeAcres<=5 & solarangle==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_angle = _b[1.solar1T#1.post]
scalar se_angle = _se[1.solar1T#1.post]

// Calculate the 95% CI bounds
scalar lb_angle = coef_angle - 1.96 * se_angle
scalar ub_angle = coef_angle + 1.96 * se_angle

*2. separate regression
reghdfe logSalesPrice post 1.solar1T 1.solar1T#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if LotSizeAcres<=5 & solarangle==0,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_no_angle = _b[1.solar1T#1.post]
scalar se_no_angle = _se[1.solar1T#1.post]

// Calculate the 95% CI bounds
scalar lb_no_angle = coef_no_angle - 1.96 * se_no_angle
scalar ub_no_angle = coef_no_angle + 1.96 * se_no_angle



***************************************************
*regression on Resi Home  -  Greenfield
***************************************************
reghdfe logSalesPrice post 1.solar1T 1.solar1T#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if greenfield_solar==1& 1.solar1T#0.ViewT==0,  a(i.locale#i.e_Year) cluster(locale e_Year)
// Extract the coefficient and S.E. 
scalar coef_Greenfield = _b[1.solar1T#1.post]
scalar se_Greenfield = _se[1.solar1T#1.post]

// Calculate the 95% CI bounds
scalar lb_Greenfield = coef_Greenfield - 1.96 * se_Greenfield
scalar ub_Greenfield = coef_Greenfield + 1.96 * se_Greenfield

*One way cluster - as two-way cluster will cause singular covariance matrix and no se can be estimated
reghdfe logSalesPrice post 1.solar1T 1.solar1T#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if greenfield_solar==0 & 1.solar1T#0.ViewT==0,  a(i.locale#i.e_Year) cluster(locale e_Year)
// Extract the coefficient and S.E. 
scalar coef_Brownfield = _b[1.solar1T#1.post]
scalar se_Brownfield = _se[1.solar1T#1.post]

// Calculate the 95% CI bounds
scalar lb_Brownfield = coef_Brownfield - 1.96 * se_Brownfield
scalar ub_Brownfield = coef_Brownfield + 1.96 * se_Brownfield

*Conduct z-test
scalar dif_mean = abs(coef_Greenfield - coef_Brownfield)
scalar dif_se = sqrt(se_Greenfield^2+se_Brownfield^2)
scalar z_stat = dif_mean/dif_se
di z_stat
scalar p_ztest = 2*(1-normal(z_stat))
di "z_stat is: " z_stat "  p_value is: " p_ztest

mat Z=(Z\coef_Greenfield,se_Greenfield,coef_Brownfield,se_Brownfield, z_stat, p_ztest)


***************************************************
*regression on Resi Home  -  TrackingSys
***************************************************
reghdfe logSalesPrice post 1.solar1T 1.solar1T#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if TrackingSys==1 ,  a(i.locale#i.e_Year) cluster(locale e_Year)
// Extract the coefficient and S.E. 
scalar coef_Tracking = _b[1.solar1T#1.post]
scalar se_Tracking = _se[1.solar1T#1.post]

// Calculate the 95% CI bounds
scalar lb_Tracking = coef_Tracking - 1.96 * se_Tracking
scalar ub_Tracking = coef_Tracking + 1.96 * se_Tracking


reghdfe logSalesPrice post 1.solar1T 1.solar1T#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if TrackingSys==0,  a(i.locale#i.e_Year) cluster(locale e_Year)
// Extract the coefficient and S.E. 
scalar coef_Fixed = _b[1.solar1T#1.post]
scalar se_Fixed = _se[1.solar1T#1.post]

// Calculate the 95% CI bounds
scalar lb_Fixed = coef_Fixed - 1.96 * se_Fixed
scalar ub_Fixed = coef_Fixed + 1.96 * se_Fixed

*Conduct z-test
scalar dif_mean = abs(coef_Tracking - coef_Fixed)
scalar dif_se = sqrt(se_Tracking^2+se_Fixed^2)
scalar z_stat = dif_mean/dif_se
di z_stat
scalar p_ztest = 2*(1-normal(z_stat))
di "z_stat is: " z_stat "  p_value is: " p_ztest

mat Z=(Z\coef_Tracking,se_Tracking, coef_Fixed, se_Fixed, z_stat, p_ztest)



*Proximity with View Effect 
// Combine the coefficients and CIs into a single matrix
matrix hetero_combined = (coef_rural, lb_rural, ub_rural) \ (coef_urban, lb_urban, ub_urban) \ ///
                       (coef_biglot, lb_biglot, ub_biglot) \ (coef_smalllot, lb_smalllot, ub_smalllot) \ ///
					   (coef_NE, lb_NE, ub_NE) \ (coef_S, lb_S, ub_S) \ ///
					   (coef_W, lb_W, ub_W) \ (coef_MW, lb_MW, ub_MW) \ ///
					   (coef_blue, lb_blue, ub_blue) \ (coef_red, lb_red, ub_red) \ ///
					   (coef_bigUSS, lb_bigUSS, ub_bigUSS) \ (coef_smallUSS, lb_smallUSS, ub_smallUSS) \ ///
					   (coef_highincome, lb_highincome, ub_highincome) \ (coef_lowincome, lb_lowincome, ub_lowincome) \ ///
					   (coef_pub_involve, lb_pub_involve, ub_pub_involve) \ (coef_no_involve, lb_no_involve, ub_no_involve) \ ///
					   (coef_highview, lb_highview, ub_highview) \ (coef_lowview, lb_lowview, ub_lowview) \ ///
					   (coef_angle, lb_angle, ub_angle) \ (coef_no_angle, lb_no_angle, ub_no_angle) \ ///
					   (coef_Greenfield, lb_Greenfield, ub_Greenfield) \ (coef_Brownfield, lb_Brownfield, ub_Brownfield) \ ///
					   (coef_Tracking, lb_Tracking, ub_Tracking) \ (coef_Fixed, lb_Fixed, ub_Fixed) 
// 	(coef_SW, lb_SW, ub_SW) 		
// "Southwestern US"		   

matrix rownames hetero_combined = "Rural" "Urban" "Big Lot" "Small Lot"  "US Northeast" "US South" "US West" "US Midwest" ///
                                  "Democrats" "Republicans" "Big USS" "Small USS" "High Income" "Low Income" "Public Involvement" "No Involvement" "High View" "Low View" "Facing" "Not Facing" "Greenfield" "Brownfield" "Tracking Sys." "Fixed Sys."
//matrix colnames hetero_combined = "Coefficient" "CI_Lower_Bound" "CI_Upper_Bound"

// Display the combined matrix
matrix list hetero_combined

// Convert the matrix to a dataset
clear
svmat hetero_combined, names(col)

// The svmat command creates variables named cq, c2, c3.
// Rename these variables to make them more meaningful
rename c1 Coefficient
rename c2 CI_Lower_Bound
rename c3 CI_Upper_Bound

// Convert the matrix to a dataset
// svmat hetero_combined, names(col)

// Add a variable for the categories (row names)
gen category = ""
replace category = "Rural" in 1
replace category = "Urban" in 2
replace category = "Big Lot" in 3
replace category = "Small Lot" in 4
replace category = "US Northeast" in 5
// replace category = "Northeastern US" in 5
replace category = "US South" in 6
replace category = "US West" in 7
replace category = "US Midwest" in 8
replace category = "Dem-leaning" in 9
replace category = "Non-Dem" in 10
replace category = "Big USS" in 11
replace category = "Small USS" in 12
replace category = "High Income" in 13
replace category = "Low Income" in 14
replace category = "Public Involvement" in 15
replace category = "No Public Involvement" in 16
replace category = "High View" in 17
replace category = "Low or no View" in 18
replace category = "Facing" in 19
replace category = "Not Facing" in 20
replace category = "Greenfield" in 21
replace category = "Brownfield" in 22
replace category = "Tracking Sys." in 23
replace category = "Fixed Sys." in 24

export delimited using "$results\Resib5Heterogeneity_Prox.csv", replace

// Assign value labels to the numerical variable
import delimited using "$results\Resib5Heterogeneity_Prox.csv",clear
gen cat_num = _n
label define category 1 "Rural" 2 "Urban" 3 "Big Lot" 4 "Small Lot" 5 "US Northeast" 6 "US South" 7 "US West" 8 "US Midwest" 9 "Dem-leaning" 10 "Non-Dem" 11 "Big USS" 12 "Small USS" 13 "High Income" 14 "Low Income" 15 "Public Involvement" 16 "No Public Involvement" 17 "High View" 18 "Low or no View" 19 "Facing" 20 "Not Facing" 21 "Greenfield" 22 "Brownfield" 23 "Tracking" 24 "Fixed"

label values cat_num category
ren coefficient Coefficient
ren ci_lower_bound CI_Lower_Bound 
ren ci_upper_bound CI_Upper_Bound

// Create the plot with specific colors for each pair of categories
twoway (scatter Coefficient cat_num if cat_num==1 | cat_num==2, msymbol(diamond) msize(small) mcolor(red)) ///
       (scatter Coefficient cat_num if cat_num==3 | cat_num==4, msymbol(diamond) msize(small) mcolor(green)) ///
       (scatter Coefficient cat_num if cat_num==5 | cat_num==6, msymbol(diamond) msize(small) mcolor(blue)) ///
       (scatter Coefficient cat_num if cat_num==7 | cat_num==8, msymbol(diamond) msize(small) mcolor(blue)) ///
       (scatter Coefficient cat_num if cat_num==9 | cat_num==10, msymbol(diamond) msize(small) mcolor(pink)) ///
       (scatter Coefficient cat_num if cat_num==11 | cat_num==12, msymbol(diamond) msize(small) mcolor(black)) ///
       (scatter Coefficient cat_num if cat_num==13 | cat_num==14, msymbol(diamond) msize(small) mcolor(brown)) ///
       (scatter Coefficient cat_num if cat_num==15 | cat_num==16, msymbol(diamond) msize(small) mcolor(orange)) ///
	   (scatter Coefficient cat_num if cat_num==17 | cat_num==18, msymbol(diamond) msize(small) mcolor(purple)) ///
	   (scatter Coefficient cat_num if cat_num==19 | cat_num==20, msymbol(diamond) msize(small) mcolor(teal)) ///
	   (scatter Coefficient cat_num if cat_num==21 | cat_num==22, msymbol(diamond) msize(small) mcolor( emerald )) ///
	   (scatter Coefficient cat_num if cat_num==23 | cat_num==24, msymbol(diamond) msize(small) mcolor( black )) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==1 | cat_num==2, lcolor(red)) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==3 | cat_num==4, lcolor(green)) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==5 | cat_num==6, lcolor(blue)) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==7 | cat_num==8, lcolor(blue)) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==9 | cat_num==10, lcolor(pink)) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==11 | cat_num==12, lcolor(black)) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==13 | cat_num==14, lcolor(brown)) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==15 | cat_num==16, lcolor(orange)) ///
	   (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==17 | cat_num==18, lcolor(purple)) ///
	   (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==19 | cat_num==20, lcolor(teal)) ///
   	   (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==21 | cat_num==22, lcolor( emerald )) ///
	   (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==23 | cat_num==24, lcolor( black )) ///
       , yline(0, lstyle(dash) lwidth(medium)) ///
       xlabel(1 "Rural" 2 "Urban" 3 "Big Lot" 4 "Small Lot" 5 "US Northeast" 6 "US South" 7 "US West" 8 "US Midwest" 9 "Dem-leaning" 10 "Non-Dem" 11 "Big USS" 12 "Small USS" 13 "High Income" 14 "Low Income" 15 "Public Involvement" 16 "No Public Involvement" 17 "High View" 18 "Low or no View" 19 "Facing" 20 "Not Facing" 21 "Greenfield" 22 "Brownfield" 23 "Tracking" 24 "Fixed", angle(45)) ///
       ytitle("Change in Residential Home Value") ///
       xtitle("") ///
       ylabel(,nogrid) legend(off)
graph export "$results\home_heterogeneity_Proxy.pdf",as(pdf) replace
graph export "$results\home_heterogeneity_Proxy.tif", as(tif) replace
*	   ylabel(-.06 "-6%" -.04 "-4%" -.02 "-2%" 0 "0" .02 "2%") ///


*Add tests 
*Conduct z-test
scalar dif_mean = abs(coef_angle - coef_no_angle)
scalar dif_se = sqrt(se_angle^2+se_no_angle^2)
scalar z_stat = dif_mean/dif_se
di z_stat
scalar p_ztest = 2*(1-normal(z_stat))
di "z_stat is: " z_stat "  p_value is: " p_ztest

mat Z=(Z\coef_angle, se_angle, coef_no_angle, se_no_angle, z_stat, p_ztest)


scalar dif_mean = abs(coef_highincome - coef_lowincome)
scalar dif_se = sqrt(se_highincome^2+se_lowincome^2)
scalar z_stat = dif_mean/dif_se
di z_stat
scalar p_ztest = 2*(1-normal(z_stat))
di "z_stat is: " z_stat "  p_value is: " p_ztest

mat Z=(Z\coef_highincome, se_highincome, coef_lowincome, se_lowincome, z_stat, p_ztest)


mat list Z
clear
svmat Z
drop if Z1==.
gen var=""
replace var="Urban_rural" in 1
replace var="Blue_red" in 2
replace var="PublicinvolvePolicy_no" in 3
replace var="High_low_view" in 4
replace var="Greenfield_Brownfield" in 5
replace var="Tracking_Fixed" in 6
replace var="South_North_RelativeAngel" in 7
replace var="High_low_income" in 8

ren Z1 coef1
ren Z2 se1
ren Z3 coef2
ren Z4 se2
ren Z5 zstat
ren Z6 pvalue
save "$results\HeterogeneityTests.dta",replace
export delimited using "$results\Resib5HeterogeneityTestsProxy.csv", replace










*****************************************************************************************
*****************************************************************************************
**      Heterogeneity analysis     on Resi Home Proximity with View Figure S7 (a)    ****
*****************************************************************************************
*****************************************************************************************


use "$dta\data_b5_foranalysis_final_new.dta",clear  /* Change dataset name here */
drop if near_dist_solar1>6

ren state State
tab State
*distinct State

global control=6
global treat=3
drop if (near_dist_solar1<$treat+2) & (near_dist_solar1>$treat)
drop if (near_dist_solar1>$treat+3)
*treatment term
replace solar1T=0
replace solar1T=1 if near_dist_solar1<=$treat

// collapse (mean) avg_sales_price=SalesPrice if State=="MN"|State=="WI"|State=="MI"|State=="IL"|State=="IN"|State=="OH", by(State e_Year)
// list State e_Year avg_sales_price, sepby(State)
// * Generate a line plot of average sales price over time by state
// twoway (line avg_sales_price e_Year, by(State) lcolor(blue)) ///
//     , title("Average Sales Price by State and Year") ///
//     ytitle("Average Sales Price") xtitle("Year") ///
//     legend(order(1 "Average Sales Price"))
	
merge m:1 FIPS using "$dta\presidential_election2016.dta", keepusing(FIPS perc_republican perc_democrat DEM)
drop if _merge==2
drop _merge
merge m:1 FIPS using "$dta\household_income_ACSST5Y2020.dta", keepusing(FIPS income high_income)
drop if _merge==2
drop _merge

gen Dem= ( perc_democrat> 65 )

drop TrackingSys
*Merge solar site tracking system -  tracking or not
foreach n of numlist 1(1)5 {
ren near_fid`n' fid
merge m:1 fid using"$dta\solar_sites_withvisibility.dta",keepusing(TrackingSys)
drop if _merge==2
drop _merge
ren fid near_fid`n'
ren TrackingSys TrackingSys`n'
}

egen TrackingSys=rowmean(TrackingSys1 TrackingSys2 TrackingSys3 TrackingSys4 TrackingSys5)
replace TrackingSys=1 if TrackingSys>0.2 | TrackingSys1==1
replace TrackingSys=0 if TrackingSys!=1
drop TrackingSys1 TrackingSys2 TrackingSys3 TrackingSys4 TrackingSys5

/*
gen DEMstate=0
replace DEMstate=1 if State=="ME"|State=="VT"|State=="NH"|State=="MA"|State=="CT"|State=="RI"|State=="NJ"|State=="DE"|State=="NJ"|State=="DE"|State=="MD"|State=="DC"|State=="NY"|State=="VA"|State=="IL"|State=="MN"|State=="CO"|State=="NM"|State=="WA"|State=="OR"|State=="NV"|State=="CA"
*/

* dummy for heterogeneity analysis
gen rural=0
replace rural=1 if near_dist_metro > 0

cap drop biglot
gen biglot=0
sum LotSizeAcres,d
replace biglot=1 if LotSizeAcres>r(p50) /* .2 acre*/
	
gen NE=0
replace NE=1 if State=="CT"|State=="ME"|State=="MA"|State=="NH"|State=="NJ"|State=="NY"|State=="PA"|State=="RI"|State=="VT"

gen S=0
replace S=1 if State=="MD"|State=="DE"|State=="FL"|State=="VA"|State=="NC"|State=="SC"|State=="GA"|State=="MS"|State=="AL"|State=="TX"|State=="OK"|State=="WV"|State=="KY"|State=="TN"|State=="AR"|State=="OK"

gen W=0
replace W=1 if State=="AZ"|State=="CA"|State=="NV"|State=="UT"|State=="NM"|State=="CO"|State=="OR"|State=="WA"

gen MW=0
replace MW=1 if State=="IL"|State=="IN"|State=="OH"|State=="MI"|State=="WI"|State=="IA"|State=="MN"|State=="MO"|State=="NE"|State=="SD"

* 3 from Lawrence Berkeley National Laboratory
gen public_involvement=1
replace public_involvement=0 if State=="AK"|State=="ID"|State=="MT"|State=="UT"|State=="NV"|State=="CO"|State=="KS"|State=="MO"|State=="IN"|State=="LA"|State=="PA"|State=="NJ"|State=="DE"|State=="AL"|State=="GA"|State=="TX"|State=="PR"

gen public_guidance=1
replace public_guidance=0 if State=="VT"|State=="NH"|State=="ID"|State=="MT"|State=="SD"|State=="IL"|State=="PA"|State=="CO"|State=="WV"|State=="DE"|State=="NM"|State=="KS"|State=="AR"|State=="SC"|State=="NC"|State=="OK"|State=="LA"|State=="MS"|State=="AL"|State=="GA"|State=="TX"|State=="PR"

gen model_ordinance=1
replace model_ordinance=0 if State=="AK"|State=="VT"|State=="WA"|State=="ID"|State=="MT"|State=="ND"|State=="WY"|State=="SD"|State=="NV"|State=="CO"|State=="MO"|State=="WV"|State=="MD"|State=="DE"|State=="AZ"|State=="NM"|State=="KS"|State=="AR"|State=="SC"|State=="OK"|State=="MS"|State=="AL"|State=="HI"|State=="PR"


forv n = 1(1)5 {
	cap drop IDclose_`n'
	gen IDclose_`n'=(near_dist_solar`n'<=6)
}
cap drop p_area_total
gen p_area_total=IDclose_1*p_area_1+IDclose_2*p_area_2+IDclose_3*p_area_3+IDclose_4*p_area_4+IDclose_5*p_area_5

cap drop bigUSS
sum p_area_total,d
gen bigUSS=0
replace bigUSS=1 if p_area_total >  r(p50) /* about 20.3 acres*/


gen solarangle=0
replace solarangle=0
replace solarangle=1 if near_angle_solar1>45 & near_angle_solar1<135 
// &near_dist_solar1<3

*View as treatment
gen ViewT=0
replace ViewT=1 if solarview==1  /*& near_dist_solar1<=$treat */

gen HighView=0
sum solarview_index if solarview_index>0,d
replace HighView=1 if solarview_index >  r(p50) /* 3*/


egen locale=group(Tract)
est clear
*regression on  property less than 5 acres, prior3 as base

*drop if ViewT==0 & solar1T==1
***************************************************
*regression on Resi Home  - NE / S  / W / MW
***************************************************

*1. separate regression - NE
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if NE==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_NE = _b[1.solar1T#1.ViewT#1.post]
scalar se_NE = _se[1.solar1T#1.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_NE = coef_NE - 1.96 * se_NE
scalar ub_NE = coef_NE + 1.96 * se_NE

*2. separate regression - S
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if S==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// vce(robust)
bysort locale e_Year: gen group_obs = _N if S==1
summarize group_obs

// Extract the coefficient and S.E. 
scalar coef_S = _b[1.solar1T#1.ViewT#1.post]
scalar se_S = _se[1.solar1T#1.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_S = coef_S - 1.96 * se_S
scalar ub_S = coef_S + 1.96 * se_S

*3. separate regression - W
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if W==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_W = _b[1.solar1T#1.ViewT#1.post]
scalar se_W = _se[1.solar1T#1.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_W = coef_W - 1.96 * se_W
scalar ub_W = coef_W + 1.96 * se_W


*4. separate regression
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if MW==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_MW = _b[1.solar1T#1.ViewT#1.post]
scalar se_MW = _se[1.solar1T#1.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_MW = coef_MW - 1.96 * se_MW
scalar ub_MW = coef_MW + 1.96 * se_MW

***************************************************
*regression on Resi Home  - rural vs urban
***************************************************

*1. separate regression
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if rural==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_rural = _b[1.solar1T#1.ViewT#1.post]
scalar se_rural = _se[1.solar1T#1.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_rural = coef_rural - 1.96 * se_rural
scalar ub_rural = coef_rural + 1.96 * se_rural


*2. separate regression
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if rural==0,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_urban = _b[1.solar1T#1.ViewT#1.post]
scalar se_urban = _se[1.solar1T#1.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_urban = coef_urban - 1.96 * se_urban
scalar ub_urban = coef_urban + 1.96 * se_urban

*Conduct z-test
scalar dif_mean = abs(coef_rural - coef_urban)
scalar dif_se = sqrt(se_rural^2+se_urban^2)
scalar z_stat = dif_mean/dif_se
di z_stat
scalar p_ztest = 2*(1-normal(z_stat))
di "z_stat is: " z_stat "  p_value is: " p_ztest

mat Z=J(1,6,.)
mat Z=(Z\coef_rural,se_rural,coef_urban, se_urban, z_stat, p_ztest)

***************************************************
*regression on Resi Home  - small / big lot
***************************************************


*1. separate regression
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if biglot==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_biglot = _b[1.solar1T#1.ViewT#1.post]
scalar se_biglot = _se[1.solar1T#1.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_biglot = coef_biglot - 1.96 * se_biglot
scalar ub_biglot = coef_biglot + 1.96 * se_biglot



*2. separate regression
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if biglot==0,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_smalllot = _b[1.solar1T#1.ViewT#1.post]
scalar se_smalllot = _se[1.solar1T#1.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_smalllot = coef_smalllot - 1.96 * se_smalllot
scalar ub_smalllot = coef_smalllot + 1.96 * se_smalllot




***************************************************
*regression on Resi Home   - political leaning
***************************************************
*1. separate regression
*
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine $House_X if Dem==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_blue = _b[1.solar1T#1.ViewT#1.post]
scalar se_blue = _se[1.solar1T#1.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_blue = coef_blue - 1.96 * se_blue
scalar ub_blue = coef_blue + 1.96 * se_blue


*2. separate regression
*perc_republican>65
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine $House_X if Dem==0,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E.
scalar coef_red = _b[1.solar1T#1.ViewT#1.post]
scalar se_red = _se[1.solar1T#1.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_red = coef_red - 1.96 * se_red
scalar ub_red = coef_red + 1.96 * se_red



*Conduct z-test
scalar dif_mean = abs(coef_blue - coef_red)
scalar dif_se = sqrt(se_blue^2+se_red^2)
scalar z_stat = dif_mean/dif_se
di z_stat
scalar p_ztest = 2*(1-normal(z_stat))
di "z_stat is: " z_stat "  p_value is: " p_ztest

mat Z=(Z\coef_blue,se_blue,coef_red,se_red, z_stat, p_ztest)



***************************************************
*regression on Resi Home  - big USS
***************************************************

*1. separate regression
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if bigUSS==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_bigUSS = _b[1.solar1T#1.ViewT#1.post]
scalar se_bigUSS = _se[1.solar1T#1.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_bigUSS = coef_bigUSS - 1.96 * se_bigUSS
scalar ub_bigUSS = coef_bigUSS + 1.96 * se_bigUSS

*2. separate regression
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if bigUSS==0,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E.
scalar coef_smallUSS = _b[1.solar1T#1.ViewT#1.post]
scalar se_smallUSS = _se[1.solar1T#1.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_smallUSS = coef_smallUSS - 1.96 * se_smallUSS
scalar ub_smallUSS = coef_smallUSS + 1.96 * se_smallUSS




***************************************************
*regression on Resi Home  - income
***************************************************

*1. separate regression
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if high_income==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_highincome = _b[1.solar1T#1.ViewT#1.post]
scalar se_highincome = _se[1.solar1T#1.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_highincome = coef_highincome - 1.96 * se_highincome
scalar ub_highincome = coef_highincome + 1.96 * se_highincome


*2. separate regression
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if high_income==0,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_lowincome = _b[1.solar1T#1.ViewT#1.post]
scalar se_lowincome = _se[1.solar1T#1.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_lowincome = coef_lowincome - 1.96 * se_lowincome
scalar ub_lowincome = coef_lowincome + 1.96 * se_lowincome



***************************************************
*regression on Resi Home  - public_involvement----the result seems reasonable
***************************************************

*1. separate regression
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if public_involvement==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_pub_involve = _b[1.solar1T#1.ViewT#1.post]
scalar se_pub_involve = _se[1.solar1T#1.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_pub_involve = coef_pub_involve - 1.96 * se_pub_involve
scalar ub_pub_involve = coef_pub_involve + 1.96 * se_pub_involve


*2. separate regression
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if public_involvement==0,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_no_involve = _b[1.solar1T#1.ViewT#1.post]
scalar se_no_involve = _se[1.solar1T#1.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_no_involve = coef_no_involve - 1.96 * se_no_involve
scalar ub_no_involve = coef_no_involve + 1.96 * se_no_involve



*Conduct z-test
scalar dif_mean = abs(coef_pub_involve - coef_no_involve)
scalar dif_se = sqrt(se_pub_involve^2+se_no_involve^2)
scalar z_stat = dif_mean/dif_se
di z_stat
scalar p_ztest = 2*(1-normal(z_stat))
di "z_stat is: " z_stat "  p_value is: " p_ztest

mat Z=(Z\ coef_pub_involve,se_pub_involve,coef_no_involve, se_no_involve, z_stat, p_ztest)



***************************************************
*regression on Resi Home  - High View Index
***************************************************
*3. dummy interaction with treatment
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.HighView#1.post 1.solar1T#0.HighView#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X ,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_highview = _b[1.solar1T#1.HighView#1.post]
scalar se_highview = _se[1.solar1T#1.HighView#1.post]

// Calculate the 95% CI bounds
scalar lb_highview = coef_highview - 1.96 * se_highview
scalar ub_highview = coef_highview + 1.96 * se_highview


// Extract the coefficient and S.E. 
scalar coef_lowview = _b[1.solar1T#0.HighView#1.post]
scalar se_lowview = _se[1.solar1T#0.HighView#1.post]

// Calculate the 95% CI bounds
scalar lb_lowview = coef_lowview - 1.96 * se_lowview
scalar ub_lowview = coef_lowview + 1.96 * se_lowview

*Conduct z-test
scalar dif_mean = abs(coef_highview - coef_lowview)
scalar dif_se = sqrt(se_highview^2+se_lowview^2)
scalar z_stat = dif_mean/dif_se
di z_stat
scalar p_ztest = 2*(1-normal(z_stat))
di "z_stat is: " z_stat "  p_value is: " p_ztest

mat Z=(Z\coef_highview,se_highview, coef_lowview, se_lowview, z_stat, p_ztest)

***************************************************
*regression on Resi Home  -  USS angle
***************************************************

*1. separate regression
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if LotSizeAcres<=5 & solarangle==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_angle = _b[1.solar1T#1.ViewT#1.post]
scalar se_angle = _se[1.solar1T#1.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_angle = coef_angle - 1.96 * se_angle
scalar ub_angle = coef_angle + 1.96 * se_angle

*2. separate regression
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if LotSizeAcres<=5 & solarangle==0,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_no_angle = _b[1.solar1T#1.ViewT#1.post]
scalar se_no_angle = _se[1.solar1T#1.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_no_angle = coef_no_angle - 1.96 * se_no_angle
scalar ub_no_angle = coef_no_angle + 1.96 * se_no_angle



***************************************************
*regression on Resi Home  -  Greenfield
***************************************************
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if greenfield_solar==1& 1.solar1T#0.ViewT==0,  a(i.locale#i.e_Year) cluster(locale e_Year)
// Extract the coefficient and S.E. 
scalar coef_Greenfield = _b[1.solar1T#1.ViewT#1.post]
scalar se_Greenfield = _se[1.solar1T#1.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_Greenfield = coef_Greenfield - 1.96 * se_Greenfield
scalar ub_Greenfield = coef_Greenfield + 1.96 * se_Greenfield

*One way cluster - as two-way cluster will cause singular covariance matrix and no se can be estimated
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if greenfield_solar==0 & 1.solar1T#0.ViewT==0,  a(i.locale#i.e_Year) cluster(locale e_Year)
// Extract the coefficient and S.E. 
scalar coef_Brownfield = _b[1.solar1T#1.ViewT#1.post]
scalar se_Brownfield = _se[1.solar1T#1.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_Brownfield = coef_Brownfield - 1.96 * se_Brownfield
scalar ub_Brownfield = coef_Brownfield + 1.96 * se_Brownfield

*Conduct z-test
scalar dif_mean = abs(coef_Greenfield - coef_Brownfield)
scalar dif_se = sqrt(se_Greenfield^2+se_Brownfield^2)
scalar z_stat = dif_mean/dif_se
di z_stat
scalar p_ztest = 2*(1-normal(z_stat))
di "z_stat is: " z_stat "  p_value is: " p_ztest

mat Z=(Z\coef_Greenfield,se_Greenfield,coef_Brownfield,se_Brownfield, z_stat, p_ztest)


***************************************************
*regression on Resi Home  -  TrackingSys
***************************************************
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if TrackingSys==1 ,  a(i.locale#i.e_Year) cluster(locale e_Year)
// Extract the coefficient and S.E. 
scalar coef_Tracking = _b[1.solar1T#1.ViewT#1.post]
scalar se_Tracking = _se[1.solar1T#1.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_Tracking = coef_Tracking - 1.96 * se_Tracking
scalar ub_Tracking = coef_Tracking + 1.96 * se_Tracking


reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if TrackingSys==0,  a(i.locale#i.e_Year) cluster(locale e_Year)
// Extract the coefficient and S.E. 
scalar coef_Fixed = _b[1.solar1T#1.ViewT#1.post]
scalar se_Fixed = _se[1.solar1T#1.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_Fixed = coef_Fixed - 1.96 * se_Fixed
scalar ub_Fixed = coef_Fixed + 1.96 * se_Fixed

*Conduct z-test
scalar dif_mean = abs(coef_Tracking - coef_Fixed)
scalar dif_se = sqrt(se_Tracking^2+se_Fixed^2)
scalar z_stat = dif_mean/dif_se
di z_stat
scalar p_ztest = 2*(1-normal(z_stat))
di "z_stat is: " z_stat "  p_value is: " p_ztest

mat Z=(Z\coef_Tracking,se_Tracking, coef_Fixed, se_Fixed, z_stat, p_ztest)



*Proximity with View Effect 
// Combine the coefficients and CIs into a single matrix
matrix hetero_combined = (coef_rural, lb_rural, ub_rural) \ (coef_urban, lb_urban, ub_urban) \ ///
                       (coef_biglot, lb_biglot, ub_biglot) \ (coef_smalllot, lb_smalllot, ub_smalllot) \ ///
					   (coef_NE, lb_NE, ub_NE) \ (coef_S, lb_S, ub_S) \ ///
					   (coef_W, lb_W, ub_W) \ (coef_MW, lb_MW, ub_MW) \ ///
					   (coef_blue, lb_blue, ub_blue) \ (coef_red, lb_red, ub_red) \ ///
					   (coef_bigUSS, lb_bigUSS, ub_bigUSS) \ (coef_smallUSS, lb_smallUSS, ub_smallUSS) \ ///
					   (coef_highincome, lb_highincome, ub_highincome) \ (coef_lowincome, lb_lowincome, ub_lowincome) \ ///
					   (coef_pub_involve, lb_pub_involve, ub_pub_involve) \ (coef_no_involve, lb_no_involve, ub_no_involve) \ ///
					   (coef_highview, lb_highview, ub_highview) \ (coef_lowview, lb_lowview, ub_lowview) \ ///
					   (coef_angle, lb_angle, ub_angle) \ (coef_no_angle, lb_no_angle, ub_no_angle) \ ///
					   (coef_Greenfield, lb_Greenfield, ub_Greenfield) \ (coef_Brownfield, lb_Brownfield, ub_Brownfield) \ ///
					   (coef_Tracking, lb_Tracking, ub_Tracking) \ (coef_Fixed, lb_Fixed, ub_Fixed) 
// 	(coef_SW, lb_SW, ub_SW) 		
// "Southwestern US"		   

matrix rownames hetero_combined = "Rural" "Urban" "Big Lot" "Small Lot"  "US Northeast" "US South" "US West" "US Midwest" ///
                                  "Democrats" "Republicans" "Big USS" "Small USS" "High Income" "Low Income" "Public Involvement" "No Involvement" "High View" "Low View" "Facing" "Not Facing" "Greenfield" "Brownfield" "Tracking Sys." "Fixed Sys."
//matrix colnames hetero_combined = "Coefficient" "CI_Lower_Bound" "CI_Upper_Bound"

// Display the combined matrix
matrix list hetero_combined

// Convert the matrix to a dataset
clear
svmat hetero_combined, names(col)

// The svmat command creates variables named cq, c2, c3.
// Rename these variables to make them more meaningful
rename c1 Coefficient
rename c2 CI_Lower_Bound
rename c3 CI_Upper_Bound

// Convert the matrix to a dataset
// svmat hetero_combined, names(col)

// Add a variable for the categories (row names)
gen category = ""
replace category = "Rural" in 1
replace category = "Urban" in 2
replace category = "Big Lot" in 3
replace category = "Small Lot" in 4
replace category = "US Northeast" in 5
// replace category = "Northeastern US" in 5
replace category = "US South" in 6
replace category = "US West" in 7
replace category = "US Midwest" in 8
replace category = "Dem-leaning" in 9
replace category = "Non-Dem" in 10
replace category = "Big USS" in 11
replace category = "Small USS" in 12
replace category = "High Income" in 13
replace category = "Low Income" in 14
replace category = "Public Involvement" in 15
replace category = "No Public Involvement" in 16
replace category = "High View" in 17
replace category = "Low View" in 18
replace category = "Facing" in 19
replace category = "Not Facing" in 20
replace category = "Greenfield" in 21
replace category = "Brownfield" in 22
replace category = "Tracking Sys." in 23
replace category = "Fixed Sys." in 24

export delimited using "$results\Resib5Heterogeneity_ProxAndView.csv", replace
// Assign value labels to the numerical variable
gen cat_num = _n
label define category 1 "Rural" 2 "Urban" 3 "Big Lot" 4 "Small Lot" 5 "US Northeast" 6 "US South" 7 "US West" 8 "US Midwest" 9 "Dem-leaning" 10 "Non-Dem" 11 "Big USS" 12 "Small USS" 13 "High Income" 14 "Low Income" 15 "Public Involvement" 16 "No Public Involvement" 17 "High View" 18 "Low View" 19 "Facing" 20 "Not Facing" 21 "Greenfield" 22 "Brownfield" 23 "Tracking" 24 "Fixed"

label values cat_num category

// Create the plot with specific colors for each pair of categories
twoway (scatter Coefficient cat_num if cat_num==1 | cat_num==2, msymbol(diamond) msize(small) mcolor(red)) ///
       (scatter Coefficient cat_num if cat_num==3 | cat_num==4, msymbol(diamond) msize(small) mcolor(green)) ///
       (scatter Coefficient cat_num if cat_num==5 | cat_num==6, msymbol(diamond) msize(small) mcolor(blue)) ///
       (scatter Coefficient cat_num if cat_num==7 | cat_num==8, msymbol(diamond) msize(small) mcolor(blue)) ///
       (scatter Coefficient cat_num if cat_num==9 | cat_num==10, msymbol(diamond) msize(small) mcolor(pink)) ///
       (scatter Coefficient cat_num if cat_num==11 | cat_num==12, msymbol(diamond) msize(small) mcolor(black)) ///
       (scatter Coefficient cat_num if cat_num==13 | cat_num==14, msymbol(diamond) msize(small) mcolor(brown)) ///
       (scatter Coefficient cat_num if cat_num==15 | cat_num==16, msymbol(diamond) msize(small) mcolor(orange)) ///
	   (scatter Coefficient cat_num if cat_num==17 | cat_num==18, msymbol(diamond) msize(small) mcolor(purple)) ///
	   (scatter Coefficient cat_num if cat_num==19 | cat_num==20, msymbol(diamond) msize(small) mcolor(teal)) ///
	   (scatter Coefficient cat_num if cat_num==21 | cat_num==22, msymbol(diamond) msize(small) mcolor( emerald )) ///
	   (scatter Coefficient cat_num if cat_num==23 | cat_num==24, msymbol(diamond) msize(small) mcolor( black )) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==1 | cat_num==2, lcolor(red)) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==3 | cat_num==4, lcolor(green)) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==5 | cat_num==6, lcolor(blue)) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==7 | cat_num==8, lcolor(blue)) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==9 | cat_num==10, lcolor(pink)) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==11 | cat_num==12, lcolor(black)) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==13 | cat_num==14, lcolor(brown)) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==15 | cat_num==16, lcolor(orange)) ///
	   (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==17 | cat_num==18, lcolor(purple)) ///
	   (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==19 | cat_num==20, lcolor(teal)) ///
   	   (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==21 | cat_num==22, lcolor( emerald )) ///
	   (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==23 | cat_num==24, lcolor( black )) ///
       , yline(0, lstyle(dash) lwidth(medium)) ///
       xlabel(1 "Rural" 2 "Urban" 3 "Big Lot" 4 "Small Lot" 5 "US Northeast" 6 "US South" 7 "US West" 8 "US Midwest" 9 "Dem-leaning" 10 "Non-Dem" 11 "Big USS" 12 "Small USS" 13 "High Income" 14 "Low Income" 15 "Public Involvement" 16 "No Public Involvement" 17 "High View" 18 "Low View" 19 "Facing" 20 "Not Facing" 21 "Greenfield" 22 "Brownfield" 23 "Tracking" 24 "Fixed", angle(45)) ///
       ytitle("Change in Residential Home Value") ///
       xtitle("") ///
       ylabel(,nogrid) legend(off)
graph export "$results\home_heterogeneity20_ProxTview.pdf",as(pdf) replace
graph export "$results\home_heterogeneity20_ProxTview.tif", as(tif) replace
*	   ylabel(-.06 "-6%" -.04 "-4%" -.02 "-2%" 0 "0" .02 "2%") ///


*Add tests 
*Conduct z-test
scalar dif_mean = abs(coef_angle - coef_no_angle)
scalar dif_se = sqrt(se_angle^2+se_no_angle^2)
scalar z_stat = dif_mean/dif_se
di z_stat
scalar p_ztest = 2*(1-normal(z_stat))
di "z_stat is: " z_stat "  p_value is: " p_ztest

mat Z=(Z\coef_angle, se_angle, coef_no_angle, se_no_angle, z_stat, p_ztest)


scalar dif_mean = abs(coef_highincome - coef_lowincome)
scalar dif_se = sqrt(se_highincome^2+se_lowincome^2)
scalar z_stat = dif_mean/dif_se
di z_stat
scalar p_ztest = 2*(1-normal(z_stat))
di "z_stat is: " z_stat "  p_value is: " p_ztest

mat Z=(Z\coef_highincome, se_highincome, coef_lowincome, se_lowincome, z_stat, p_ztest)


mat list Z
clear
svmat Z
drop if Z1==.
gen var=""
replace var="Urban_rural" in 1
replace var="Blue_red" in 2
replace var="PublicinvolvePolicy_no" in 3
replace var="High_low_view" in 4
replace var="Greenfield_Brownfield" in 5
replace var="Tracking_Fixed" in 6
replace var="South_North_RelativeAngel" in 7
replace var="High_low_income" in 8

ren Z1 coef1
ren Z2 se1
ren Z3 coef2
ren Z4 se2
ren Z5 zstat
ren Z6 pvalue
save "$results\HeterogeneityTests_ProxTview.dta",replace
export delimited using "$results\Resib5HeterogeneityTests_ProxTview.csv", replace







**********************************************************************************************
**********************************************************************************************
**       Heterogeneity analysis     on Resi Home    Proximity No view    Figure S7 (b)    ****
**********************************************************************************************
**********************************************************************************************
use "$dta\data_b5_foranalysis_final_new.dta",clear   /* Change dataset name here */
drop if near_dist_solar1>6

ren state State
tab State
*distinct State

global control=6
global treat=3
drop if (near_dist_solar1<$treat+2) & (near_dist_solar1>$treat)
drop if (near_dist_solar1>$treat+3)
*treatment term
replace solar1T=0
replace solar1T=1 if near_dist_solar1<=$treat

// collapse (mean) avg_sales_price=SalesPrice if State=="MN"|State=="WI"|State=="MI"|State=="IL"|State=="IN"|State=="OH", by(State e_Year)
// list State e_Year avg_sales_price, sepby(State)
// * Generate a line plot of average sales price over time by state
// twoway (line avg_sales_price e_Year, by(State) lcolor(blue)) ///
//     , title("Average Sales Price by State and Year") ///
//     ytitle("Average Sales Price") xtitle("Year") ///
//     legend(order(1 "Average Sales Price"))
	

merge m:1 FIPS using "$dta\presidential_election2016.dta", keepusing(FIPS perc_republican perc_democrat DEM)
drop if _merge==2
drop _merge
merge m:1 FIPS using "$dta\household_income_ACSST5Y2020.dta", keepusing(FIPS income high_income)
drop if _merge==2
drop _merge

gen Dem= ( perc_democrat> 65 )

/*
gen DEMstate=0
replace DEMstate=1 if State=="ME"|State=="VT"|State=="NH"|State=="MA"|State=="CT"|State=="RI"|State=="NJ"|State=="DE"|State=="NJ"|State=="DE"|State=="MD"|State=="DC"|State=="NY"|State=="VA"|State=="IL"|State=="MN"|State=="CO"|State=="NM"|State=="WA"|State=="OR"|State=="NV"|State=="CA"
*/
* dummy for heterogeneity analysis
gen rural=0
replace rural=1 if near_dist_metro > 0

cap drop biglot
gen biglot=0
sum LotSizeAcres,d
replace biglot=1 if LotSizeAcres>r(p50) /* .2 acre*/
	
gen NE=0
replace NE=1 if State=="CT"|State=="ME"|State=="MA"|State=="NH"|State=="NJ"|State=="NY"|State=="PA"|State=="RI"|State=="VT"

gen S=0
replace S=1 if State=="MD"|State=="DE"|State=="FL"|State=="VA"|State=="NC"|State=="SC"|State=="GA"|State=="MS"|State=="AL"|State=="TX"|State=="OK"|State=="WV"|State=="KY"|State=="TN"|State=="AR"|State=="OK"

gen W=0
replace W=1 if State=="AZ"|State=="CA"|State=="NV"|State=="UT"|State=="NM"|State=="CO"|State=="OR"|State=="WA"

gen MW=0
replace MW=1 if State=="IL"|State=="IN"|State=="OH"|State=="MI"|State=="WI"|State=="IA"|State=="MN"|State=="MO"|State=="NE"|State=="SD"

* 3 from Lawrence Berkeley National Laboratory
gen public_involvement=1
replace public_involvement=0 if State=="AK"|State=="ID"|State=="MT"|State=="UT"|State=="NV"|State=="CO"|State=="KS"|State=="MO"|State=="IN"|State=="LA"|State=="PA"|State=="NJ"|State=="DE"|State=="AL"|State=="GA"|State=="TX"|State=="PR"

gen public_guidance=1
replace public_guidance=0 if State=="VT"|State=="NH"|State=="ID"|State=="MT"|State=="SD"|State=="IL"|State=="PA"|State=="CO"|State=="WV"|State=="DE"|State=="NM"|State=="KS"|State=="AR"|State=="SC"|State=="NC"|State=="OK"|State=="LA"|State=="MS"|State=="AL"|State=="GA"|State=="TX"|State=="PR"

gen model_ordinance=1
replace model_ordinance=0 if State=="AK"|State=="VT"|State=="WA"|State=="ID"|State=="MT"|State=="ND"|State=="WY"|State=="SD"|State=="NV"|State=="CO"|State=="MO"|State=="WV"|State=="MD"|State=="DE"|State=="AZ"|State=="NM"|State=="KS"|State=="AR"|State=="SC"|State=="OK"|State=="MS"|State=="AL"|State=="HI"|State=="PR"


forv n = 1(1)5 {
	cap drop IDclose_`n'
	gen IDclose_`n'=(near_dist_solar`n'<=6)
}
cap drop p_area_total
gen p_area_total=IDclose_1*p_area_1+IDclose_2*p_area_2+IDclose_3*p_area_3+IDclose_4*p_area_4+IDclose_5*p_area_5

cap drop bigUSS
sum p_area_total,d
gen bigUSS=0
replace bigUSS=1 if p_area_total >  r(p50) /* about 20.3 acres*/


gen solarangle=0
replace solarangle=0
replace solarangle=1 if near_angle_solar1>45 & near_angle_solar1<135 
// &near_dist_solar1<3

*View as treatment
gen ViewT=0
replace ViewT=1 if solarview==1  /*& near_dist_solar1<=$treat */

gen HighView=0
sum solarview_index if solarview_index>0,d
replace HighView=1 if solarview_index >  r(p50) /* 3*/


egen locale=group(Tract)
est clear
*regression on  property less than 5 acres, prior3 as base

*drop if ViewT==1 & solar1T==1
*Overall
*reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X,  a(i.locale#i.e_Year) cluster(locale e_Year)

***************************************************
*regression on Resi Home  - NE / S  / W / MW
***************************************************

*1. separate regression - NE
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if NE==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_NE = _b[1.solar1T#0.ViewT#1.post]
scalar se_NE = _se[1.solar1T#0.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_NE = coef_NE - 1.96 * se_NE
scalar ub_NE = coef_NE + 1.96 * se_NE

*2. separate regression - S
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if S==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// vce(robust)
bysort locale e_Year: gen group_obs = _N if S==1
summarize group_obs

// Extract the coefficient and S.E. 
scalar coef_S = _b[1.solar1T#0.ViewT#1.post]
scalar se_S = _se[1.solar1T#0.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_S = coef_S - 1.96 * se_S
scalar ub_S = coef_S + 1.96 * se_S

*3. separate regression - W
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if W==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_W = _b[1.solar1T#0.ViewT#1.post]
scalar se_W = _se[1.solar1T#0.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_W = coef_W - 1.96 * se_W
scalar ub_W = coef_W + 1.96 * se_W


*4. separate regression
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if MW==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_MW = _b[1.solar1T#0.ViewT#1.post]
scalar se_MW = _se[1.solar1T#0.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_MW = coef_MW - 1.96 * se_MW
scalar ub_MW = coef_MW + 1.96 * se_MW

***************************************************
*regression on Resi Home  - rural vs urban
***************************************************

*1. separate regression
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if rural==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_rural = _b[1.solar1T#0.ViewT#1.post]
scalar se_rural = _se[1.solar1T#0.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_rural = coef_rural - 1.96 * se_rural
scalar ub_rural = coef_rural + 1.96 * se_rural


*2. separate regression
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if rural==0,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_urban = _b[1.solar1T#0.ViewT#1.post]
scalar se_urban = _se[1.solar1T#0.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_urban = coef_urban - 1.96 * se_urban
scalar ub_urban = coef_urban + 1.96 * se_urban

*Conduct z-test
scalar dif_mean = abs(coef_rural - coef_urban)
scalar dif_se = sqrt(se_rural^2+se_urban^2)
scalar z_stat = dif_mean/dif_se
di z_stat
scalar p_ztest = 2*(1-normal(z_stat))
di "z_stat is: " z_stat "  p_value is: " p_ztest

mat Z=J(1,2,.)
mat Z=(Z\ z_stat, p_ztest)

***************************************************
*regression on Resi Home  - small / big lot
***************************************************


*1. separate regression
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if biglot==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_biglot = _b[1.solar1T#0.ViewT#1.post]
scalar se_biglot = _se[1.solar1T#0.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_biglot = coef_biglot - 1.96 * se_biglot
scalar ub_biglot = coef_biglot + 1.96 * se_biglot



*2. separate regression
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if biglot==0,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_smalllot = _b[1.solar1T#0.ViewT#1.post]
scalar se_smalllot = _se[1.solar1T#0.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_smalllot = coef_smalllot - 1.96 * se_smalllot
scalar ub_smalllot = coef_smalllot + 1.96 * se_smalllot




***************************************************
*regression on Resi Home   - political leaning
***************************************************
*1. separate regression
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if Dem==1,  a(i.locale#i.e_Year)  cluster(locale e_Year)
*reghdfe logSalesPrice ViewT post post_ViewT logDistLine post_logDistLine logDistRoad logDistMetro $House_X if DEMstate==1,  a(i.locale#i.e_Year) cluster(locale e_Year)
// Extract the coefficient and S.E. 
scalar coef_blue = _b[1.solar1T#0.ViewT#1.post]
scalar se_blue = _se[1.solar1T#0.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_blue = coef_blue - 1.96 * se_blue
scalar ub_blue = coef_blue + 1.96 * se_blue


*2. separate regression
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if Dem==0,  a(i.locale#i.e_Year)  cluster(locale e_Year)
*reghdfe logSalesPrice ViewT post post_ViewT logDistLine post_logDistLine logDistRoad logDistMetro $House_X if DEMstate==0,  a(i.locale#i.e_Year) cluster(locale e_Year)
// Extract the coefficient and S.E.
scalar coef_red = _b[1.solar1T#0.ViewT#1.post]
scalar se_red = _se[1.solar1T#0.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_red = coef_red - 1.96 * se_red
scalar ub_red = coef_red + 1.96 * se_red



*Conduct z-test
scalar dif_mean = abs(coef_blue - coef_red)
scalar dif_se = sqrt(se_blue^2+se_red^2)
scalar z_stat = dif_mean/dif_se
di z_stat
scalar p_ztest = 2*(1-normal(z_stat))
di "z_stat is: " z_stat "  p_value is: " p_ztest

mat Z=(Z\ z_stat, p_ztest)



***************************************************
*regression on Resi Home  - big USS
***************************************************

*1. separate regression
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if bigUSS==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_bigUSS = _b[1.solar1T#0.ViewT#1.post]
scalar se_bigUSS = _se[1.solar1T#0.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_bigUSS = coef_bigUSS - 1.96 * se_bigUSS
scalar ub_bigUSS = coef_bigUSS + 1.96 * se_bigUSS

*2. separate regression
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if bigUSS==0,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E.
scalar coef_smallUSS = _b[1.solar1T#0.ViewT#1.post]
scalar se_smallUSS = _se[1.solar1T#0.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_smallUSS = coef_smallUSS - 1.96 * se_smallUSS
scalar ub_smallUSS = coef_smallUSS + 1.96 * se_smallUSS




***************************************************
*regression on Resi Home  - income
***************************************************

*1. separate regression
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if high_income==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_highincome = _b[1.solar1T#0.ViewT#1.post]
scalar se_highincome = _se[1.solar1T#0.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_highincome = coef_highincome - 1.96 * se_highincome
scalar ub_highincome = coef_highincome + 1.96 * se_highincome


*2. separate regression
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if high_income==0,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_lowincome = _b[1.solar1T#0.ViewT#1.post]
scalar se_lowincome = _se[1.solar1T#0.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_lowincome = coef_lowincome - 1.96 * se_lowincome
scalar ub_lowincome = coef_lowincome + 1.96 * se_lowincome



***************************************************
*regression on Resi Home  - public_involvement----the result seems reasonable
***************************************************

*1. separate regression
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if public_involvement==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_pub_involve = _b[1.solar1T#0.ViewT#1.post]
scalar se_pub_involve = _se[1.solar1T#0.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_pub_involve = coef_pub_involve - 1.96 * se_pub_involve
scalar ub_pub_involve = coef_pub_involve + 1.96 * se_pub_involve


*2. separate regression
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if public_involvement==0,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_no_involve = _b[1.solar1T#0.ViewT#1.post]
scalar se_no_involve = _se[1.solar1T#0.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_no_involve = coef_no_involve - 1.96 * se_no_involve
scalar ub_no_involve = coef_no_involve + 1.96 * se_no_involve



*Conduct z-test
scalar dif_mean = abs(coef_pub_involve - coef_no_involve)
scalar dif_se = sqrt(se_pub_involve^2+se_no_involve^2)
scalar z_stat = dif_mean/dif_se
di z_stat
scalar p_ztest = 2*(1-normal(z_stat))
di "z_stat is: " z_stat "  p_value is: " p_ztest

mat Z=(Z\ z_stat, p_ztest)



***************************************************
*regression on Resi Home  -  USS angle
***************************************************

*1. separate regression
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if LotSizeAcres<=5 & solarangle==1,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_angle = _b[1.solar1T#0.ViewT#1.post]
scalar se_angle = _se[1.solar1T#0.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_angle = coef_angle - 1.96 * se_angle
scalar ub_angle = coef_angle + 1.96 * se_angle

*2. separate regression
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if LotSizeAcres<=5 & solarangle==0,  a(i.locale#i.e_Year) cluster(locale e_Year)

// Extract the coefficient and S.E. 
scalar coef_no_angle = _b[1.solar1T#0.ViewT#1.post]
scalar se_no_angle = _se[1.solar1T#0.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_no_angle = coef_no_angle - 1.96 * se_no_angle
scalar ub_no_angle = coef_no_angle + 1.96 * se_no_angle



***************************************************
*regression on Resi Home  -  Greenfield
***************************************************
reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if greenfield_solar==1 & 1.solar1T#1.ViewT==0,  a(i.locale#i.e_Year) cluster(locale e_Year)
// Extract the coefficient and S.E. 
scalar coef_Greenfield = _b[1.solar1T#0.ViewT#1.post]
scalar se_Greenfield = _se[1.solar1T#0.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_Greenfield = coef_Greenfield - 1.96 * se_Greenfield
scalar ub_Greenfield = coef_Greenfield + 1.96 * se_Greenfield


reghdfe logSalesPrice post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine logDistRoad logDistMetro $House_X if greenfield_solar==0 & 1.solar1T#1.ViewT==0,  a(i.locale#i.e_Year) cluster(locale e_Year)
// Extract the coefficient and S.E. 
scalar coef_Brownfield = _b[1.solar1T#0.ViewT#1.post]
scalar se_Brownfield = _se[1.solar1T#0.ViewT#1.post]

// Calculate the 95% CI bounds
scalar lb_Brownfield = coef_Brownfield - 1.96 * se_Brownfield
scalar ub_Brownfield = coef_Brownfield + 1.96 * se_Brownfield

*Conduct z-test
scalar dif_mean = abs(coef_Greenfield - coef_Brownfield)
scalar dif_se = sqrt(se_Greenfield^2+se_Brownfield^2)
scalar z_stat = dif_mean/dif_se
di z_stat
scalar p_ztest = 2*(1-normal(z_stat))
di "z_stat is: " z_stat "  p_value is: " p_ztest

mat Z=(Z\ z_stat, p_ztest)



*Proximity with View Effect 
// Combine the coefficients and CIs into a single matrix
matrix hetero_combined = (coef_rural, lb_rural, ub_rural) \ (coef_urban, lb_urban, ub_urban) \ ///
                       (coef_biglot, lb_biglot, ub_biglot) \ (coef_smalllot, lb_smalllot, ub_smalllot) \ ///
					   (coef_NE, lb_NE, ub_NE) \ (coef_S, lb_S, ub_S) \ ///
					   (coef_W, lb_W, ub_W) \ (coef_MW, lb_MW, ub_MW) \ ///
					   (coef_blue, lb_blue, ub_blue) \ (coef_red, lb_red, ub_red) \ ///
					   (coef_bigUSS, lb_bigUSS, ub_bigUSS) \ (coef_smallUSS, lb_smallUSS, ub_smallUSS) \ ///
					   (coef_highincome, lb_highincome, ub_highincome) \ (coef_lowincome, lb_lowincome, ub_lowincome) \ ///
					   (coef_pub_involve, lb_pub_involve, ub_pub_involve) \ (coef_no_involve, lb_no_involve, ub_no_involve) \ ///
					   (coef_angle, lb_angle, ub_angle) \ (coef_no_angle, lb_no_angle, ub_no_angle) \ ///
					   (coef_Greenfield, lb_Greenfield, ub_Greenfield) \ (coef_Brownfield, lb_Brownfield, ub_Brownfield) 
// 	(coef_SW, lb_SW, ub_SW) 		
// "Southwestern US"		   

matrix rownames hetero_combined = "Rural" "Urban" "Big Lot" "Small Lot"  "US Northeast" "US South" "US West" "US Midwest" ///
                                  "Democrats" "Republicans" "Big USS" "Small USS" "Public Involvement" "No Involvement" "High View" "Low View" "Facing" "Not Facing" "Greenfield" "Brownfield"
//matrix colnames hetero_combined = "Coefficient" "CI_Lower_Bound" "CI_Upper_Bound"

// Display the combined matrix
matrix list hetero_combined

// Convert the matrix to a dataset
clear
svmat hetero_combined, names(col)

// The svmat command creates variables named cq, c2, c3.
// Rename these variables to make them more meaningful
rename c1 Coefficient
rename c2 CI_Lower_Bound
rename c3 CI_Upper_Bound

// Convert the matrix to a dataset
// svmat hetero_combined, names(col)

// Add a variable for the categories (row names)
gen category = ""
replace category = "Rural" in 1
replace category = "Urban" in 2
replace category = "Big Lot" in 3
replace category = "Small Lot" in 4
replace category = "US Northeast" in 5
// replace category = "Northeastern US" in 5
replace category = "US South" in 6
replace category = "US West" in 7
replace category = "US Midwest" in 8
replace category = "Dem-leaning" in 9
replace category = "Non-Dem" in 10
replace category = "Big USS" in 11
replace category = "Small USS" in 12
replace category = "High Income" in 13
replace category = "Low Income" in 14
replace category = "Public Involvement" in 15
replace category = "No Public Involvement" in 16
replace category = "Facing" in 17
replace category = "Not Facing" in 18
replace category = "Greenfield" in 19
replace category = "Brownfield" in 20

export delimited using "$results\Resib5Heterogeneity_ProxNoView.csv", replace
// Assign value labels to the numerical variable
gen cat_num = _n
label define category 1 "Rural" 2 "Urban" 3 "Big Lot" 4 "Small Lot" 5 "US Northeast" 6 "US South" 7 "US West" 8 "US Midwest" 9 "Dem-leaning" 10 "Non-Dem" 11 "Big USS" 12 "Small USS" 13 "High Income" 14 "Low Income" 15 "Public Involvement" 16 "No Public Involvement" 17 "Facing" 18 "Not Facing" 19 "Greenfield" 20 "Brownfield"

label values cat_num category

// Create the plot with specific colors for each pair of categories
twoway (scatter Coefficient cat_num if cat_num==1 | cat_num==2, msymbol(diamond) msize(small) mcolor(red)) ///
       (scatter Coefficient cat_num if cat_num==3 | cat_num==4, msymbol(diamond) msize(small) mcolor(green)) ///
       (scatter Coefficient cat_num if cat_num==5 | cat_num==6, msymbol(diamond) msize(small) mcolor(blue)) ///
       (scatter Coefficient cat_num if cat_num==7 | cat_num==8, msymbol(diamond) msize(small) mcolor(blue)) ///
       (scatter Coefficient cat_num if cat_num==9 | cat_num==10, msymbol(diamond) msize(small) mcolor(pink)) ///
       (scatter Coefficient cat_num if cat_num==11 | cat_num==12, msymbol(diamond) msize(small) mcolor(black)) ///
       (scatter Coefficient cat_num if cat_num==13 | cat_num==14, msymbol(diamond) msize(small) mcolor(brown)) ///
       (scatter Coefficient cat_num if cat_num==15 | cat_num==16, msymbol(diamond) msize(small) mcolor(orange)) ///
	   (scatter Coefficient cat_num if cat_num==17 | cat_num==18, msymbol(diamond) msize(small) mcolor(teal)) ///
	   (scatter Coefficient cat_num if cat_num==19 | cat_num==20, msymbol(diamond) msize(small) mcolor( emerald )) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==1 | cat_num==2, lcolor(red)) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==3 | cat_num==4, lcolor(green)) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==5 | cat_num==6, lcolor(blue)) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==7 | cat_num==8, lcolor(blue)) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==9 | cat_num==10, lcolor(pink)) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==11 | cat_num==12, lcolor(black)) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==13 | cat_num==14, lcolor(brown)) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==15 | cat_num==16, lcolor(orange)) ///
	   (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==17 | cat_num==18, lcolor(teal)) ///
   	   (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==19 | cat_num==20, lcolor( emerald )) ///
       , yline(0, lstyle(dash) lwidth(medium)) ///
       xlabel(1 "Rural" 2 "Urban" 3 "Big Lot" 4 "Small Lot" 5 "US Northeast" 6 "US South" 7 "US West" 8 "US Midwest" 9 "Dem-leaning" 10 "Non-Dem" 11 "Big USS" 12 "Small USS" 13 "High Income" 14 "Low Income" 15 "Public Involvement" 16 "No Public Involvement" 17 "Facing" 18 "Not Facing" 19 "Greenfield" 20 "Brownfield", angle(45)) ///
       ytitle("Change in Residential Home Value") ///
       xtitle("") ///
       ylabel(-.1 0 .1 .2,nogrid) legend(off) ylabel()
	   
graph export "$results\home_heterogeneity20_ProxTnoview.pdf",as(pdf) replace
graph export "$results\home_heterogeneity20_ProxTnoview.tif", as(tif) replace

