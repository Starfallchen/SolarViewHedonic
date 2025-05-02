********************************************************************************
* Land DID, placebo, event study, 
clear all
set more off
cap log close
set seed 123456789
set scheme plotplain, permanently

*Specify directories here
global AgSolar "..."
global dta "$AgSolar\data"
global results "$AgSolar\results"
global figures "$AgSolar\figures"

global House_X "c.logDistRoad#i.post  c.logDistMetro#i.post  c.TotalBedrooms#i.post  c.TotalCalculatedBathCount#i.post  c.BuildingAge#i.post "
global Lot_X "c.logDistRoad#i.post  c.logDistMetro#i.post  "







************************************************************************
*                       Ag & Vacant Land no home                        *
************************************************************************



***************************************************************************
*regression on Ag & Vacant Land  - distance decay 2 miles each - Figure 5 *
***************************************************************************
use "$dta\data_a5Land_foranalysis_final_new.dta", clear
drop if near_dist_solar1>22
drop if SFR==1
cap drop locale
egen locale = group(near_fid1 county state)

cap drop ring
gen ring=0
	replace ring=0 if near_dist_solar1<=2
	
	count if near_dist_solar1<=2 &post==1
	di r(N)
foreach d of numlist 200(200)1600 {
	*treatment term
	replace ring=(`d')/100 if near_dist_solar1>((`d')/100) & near_dist_solar1<=(`d'+200)/100
	count if near_dist_solar1>((`d')/100) & near_dist_solar1<=(`d'+200)/100 &post==1
	di r(N)
	*interaction term
}
replace ring=18 if near_dist_solar1>18
drop if near_dist_solar1>20
*replace ring=20 if near_dist_solar1>20

*replace ring=1 if near_dist_solar1>0 & near_dist_solar1<=1 
*c.logDistRoad#i.post c.logDistMetro#i.post 
reghdfe logPperAcre ib18.ring 1.post ib18.ring#1.post logDistLine post_logDistLine $Lot_X if (LotSizeAcres>=5) ,   a(i.locale#i.e_Year) cluster(locale e_Year)

label variable logDistLine "log of (Distance to Nearest Power Line (miles))"
label variable post_logDistLine "post $\times$ log of (Distance to Nearest Power Line (miles))"
label variable logDistRoad "log of (Distance to Nearest Road (miles))"
label variable logDistMetro "log of (Distance to Nearest Metro Area (miles))"
est sto distdecay_study_Agland
esttab using "$results\distdecay_study_Agland.csv", se replace 


/*Control - land price between 12-20 mile*/
mat list e(b)
mat list e(V)

parmest, saving(distdecay_study_Agland_results, replace)

use distdecay_study_Agland_results, clear
keep in 12/20

* Generate a numeric variable for the ring categories
gen ring = .
replace ring = 0 in 1
replace ring = 2 in 2
replace ring = 4 in 3
replace ring = 6 in 4
replace ring = 8 in 5
replace ring = 10 in 6
replace ring = 12 in 7
replace ring = 14 in 8
replace ring = 16 in 9
*replace ring = 18 in 10
* Create variables for the confidence intervals
gen ci_low = min95
gen ci_high = max95

* List the data to verify
// list

twoway (connected estimate ring, lcolor(blue)) ///
       (rarea ci_low ci_high ring, lcolor(blue%1) color(blue%10)), ///
    xlabel(0 "[0,2)" 2 "[2,4)" 4 "[4,6)" 6 "[6,8)" 8 "[8,10)" 10 "[10,12)" 12 "[12,14)" 14 "[14,16)" 16 "[16,18)", angle(45)) ///
    legend(label(1 "Point Estimate") label(2 "95% CI") position(2) ring(0)) ///
 	ylabel(-.1  0  .1  .2  .3) ///
    ytitle("Effect on Log of Ag&Vac Land Price") ///
	xtitle("Distance (in miles)") ///
    yline(0, lw(thin) lcolor(red)) saving($results\AgLandG5_distdecaystudy2mi_ring.gph, replace) 
//    title("Distance Decay Results of Ag and Vacant Land") ///
graph export "$results\AgLandG5_distdecaystudy2mi_ring.pdf",as(pdf) replace
graph export "$results\AgLandG5_distdecaystudy2mi_ring.tif",as(tif) replace


*****************************************************************
*        Event Study      on AG & VACANT land - Figure S5       *
*****************************************************************
use "$dta\data_a5Land_foranalysis_final_new.dta", clear
*0.ring is the treatment 
gen T=(0.ring==1)
drop if SFR==1
cap drop locale
egen locale = group(near_fid1 county state)
*drop if ring>=2 & ring<=16
drop if near_dist_solar1>20

tab Year_relative, sum(PperAcre)  /*good data go back to 25 years ahead*/
*Generate Event Study years
gen Year_event=Year_relative+5
drop if Year_event<0

*regression on pure Ag land with 0 building: base is prioryr1
reghdfe logPperAcre 1.T ib4.Year_event ib4.Year_event#1.T i.ring logDistLine post_logDistLine $Lot_X if LotSizeAcres>=5 & Year_event>=0 & Year_event<=12,  a(i.cty#i.e_Year) cluster(cty e_Year)

eststo event_study_Agland


mat list e(b)
mat list e(V)

parmest, saving(event_study_Agland_results, replace)

use event_study_Agland_results, clear
keep in 15/26

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

twoway (rarea ci_low ci_high year, lcolor(green%1) color(green%10)) ///
       (connected estimate year, mcolor(blue)), ///
       xlabel(1 "prior year 5" 2 "prior year 4" 3 "prior year 3" 4 "prior year 2" 5 " prior year 1" 6 "year 0" 7 "year 1" 8 "year 2" 9 "year 3" 10 "year 4" 11 "year 5" 12 "year 6",angle(45)) ///
    legend(label(1 "95% CI Event study") label(2 "Estimate")  position(2) ring(0)) ///
 	ylabel(-.5 "-0.5" 0 "0" .5 "0.5" 1 "1" ) ///
    ytitle("Effect on Natural Log of Ag&Vacant Land Price") ///
	xline(5, lw(vthin) lc(red)) ///
    yline(0, lw(thin) lcolor(grey))
	
	//	xtitle("Year") ///
//    title("Event Study Ag and Vacant Land") ///

graph export "$results\Event_AgLand_p1.pdf",as(pdf) replace
graph export "$results\Event_AgLand_p1.tif",as(tif) replace




********************************************************************
*      Heterogeneity analysis  on AG & VACANT land - Figure S6     *
********************************************************************

use "$dta\data_a5Land_foranalysis_final_new.dta", clear
ren state State
merge m:1 FIPS using "$dta\presidential_election2016.dta", keepusing(FIPS perc_republican perc_democrat DEM)
drop if _merge==2
drop _merge
merge m:1 FIPS using "$dta\household_income_ACSST5Y2020.dta", keepusing(FIPS income high_income)
drop if _merge==2
drop _merge
gen DEMstate=0
replace DEMstate=1 if State=="ME"|State=="VT"|State=="NH"|State=="MA"|State=="CT"|State=="RI"|State=="NJ"|State=="DE"|State=="NJ"|State=="DE"|State=="MD"|State=="DC"|State=="NY"|State=="VA"|State=="IL"|State=="MN"|State=="CO"|State=="NM"|State=="WA"|State=="OR"|State=="NV"|State=="CA"

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

forv n = 1(1)5 {
	cap drop IDclose_`n'
	gen IDclose_`n'=(near_dist_solar`n'<=6)
}
cap drop p_area_total
gen p_area_total=IDclose_1*p_area_1+IDclose_2*p_area_2+IDclose_3*p_area_3+IDclose_4*p_area_4+IDclose_5*p_area_5

cap drop bigUSS
sum p_area_total,d
gen bigUSS=0
replace bigUSS=1 if p_area_total >  82179 /* about 20.3 acres*/

* 3 from Lawrence Berkeley National Laboratory
gen public_involvement=1
replace public_involvement=0 if State=="AK"|State=="ID"|State=="MT"|State=="UT"|State=="NV"|State=="CO"|State=="KS"|State=="MO"|State=="IN"|State=="LA"|State=="PA"|State=="NJ"|State=="DE"|State=="AL"|State=="GA"|State=="TX"|State=="PR"

gen public_guidance=1
replace public_guidance=0 if State=="VT"|State=="NH"|State=="ID"|State=="MT"|State=="SD"|State=="IL"|State=="PA"|State=="CO"|State=="WV"|State=="DE"|State=="NM"|State=="KS"|State=="AR"|State=="SC"|State=="NC"|State=="OK"|State=="LA"|State=="MS"|State=="AL"|State=="GA"|State=="TX"|State=="PR"

gen model_ordinance=1
replace model_ordinance=0 if State=="AK"|State=="VT"|State=="WA"|State=="ID"|State=="MT"|State=="ND"|State=="WY"|State=="SD"|State=="NV"|State=="CO"|State=="MO"|State=="WV"|State=="MD"|State=="DE"|State=="AZ"|State=="NM"|State=="KS"|State=="AR"|State=="SC"|State=="OK"|State=="MS"|State=="AL"|State=="HI"|State=="PR"

*heterogeneity
***************************************************
*regression on Ag & Vacant Land  - rural vs urban
***************************************************

// *1. separate regression
reghdfe logPperAcre ib18.ring 1.post ib18.ring#1.post logDistLine post_logDistLine $Lot_X if LotSizeAcres>5 & rural==1,  a(i.locale#i.e_Year) cluster(locale e_Year)
// eststo hetero_Agland_rural

// Extract the coefficient and S.E. for ring=0 & post=1 
scalar coef_rural = _b[0.ring#1.post]
scalar se_rural = _se[0.ring#1.post]

// Calculate the 95% CI bounds
scalar lb_rural = coef_rural - 1.96 * se_rural
scalar ub_rural = coef_rural + 1.96 * se_rural

// *2. separate regression
reghdfe logPperAcre ib18.ring 1.post ib18.ring#1.post logDistLine post_logDistLine $Lot_X if LotSizeAcres>5 & rural==0,  a(i.locale#i.e_Year) cluster(locale e_Year)
eststo hetero_Agland_urban

// Extract the coefficient and S.E. for ring=0 & post=1
scalar coef_urban = _b[0.ring#1.post]
scalar se_urban = _se[0.ring#1.post]

// Calculate the 95% CI bounds
scalar lb_urban = coef_urban - 1.96 * se_urban
scalar ub_urban = coef_urban + 1.96 * se_urban


***************************************************
*regression on Ag & Vacant Land  - small / big lot
***************************************************
// *1. separate regression
reghdfe logPperAcre ib18.ring 1.post ib18.ring#1.post logDistLine post_logDistLine $Lot_X if LotSizeAcres>5 & biglot==1, a(i.locale#i.e_Year) cluster(locale e_Year)
// eststo hetero_Agland_blot

// Extract the coefficient and S.E. for ring=0 & post=1 
scalar coef_biglot = _b[0.ring#1.post]
scalar se_biglot = _se[0.ring#1.post]

// Calculate the 95% CI bounds
scalar lb_biglot = coef_biglot - 1.96 * se_biglot
scalar ub_biglot = coef_biglot + 1.96 * se_biglot


// *2. separate regression
reghdfe logPperAcre ib18.ring 1.post ib18.ring#1.post logDistLine post_logDistLine $Lot_X if LotSizeAcres>5 & biglot==0,  a(i.locale#i.e_Year) cluster(locale e_Year)
// eststo hetero_Agland_slot

// Extract the coefficient and S.E. for ring=0 & post=1 
scalar coef_smalllot = _b[0.ring#1.post]
scalar se_smalllot = _se[0.ring#1.post]

// Calculate the 95% CI bounds
scalar lb_smalllot = coef_smalllot - 1.96 * se_smalllot
scalar ub_smalllot = coef_smalllot + 1.96 * se_smalllot


***************************************************
*regression on Ag & Vacant Land  - NE / S  / W / MW
***************************************************

// *1. separate regression
reghdfe logPperAcre ib18.ring 1.post ib18.ring#1.post logDistLine post_logDistLine $Lot_X if LotSizeAcres>5 & NE==1, a(i.locale#i.e_Year) cluster(locale e_Year)
// eststo hetero_Agland_NE

// Extract the coefficient and S.E. for ring=0 & post=1 
scalar coef_NE = _b[0.ring#1.post]
scalar se_NE = _se[0.ring#1.post]

// Calculate the 95% CI bounds
scalar lb_NE = coef_NE - 1.96 * se_NE
scalar ub_NE = coef_NE + 1.96 * se_NE


// *2. separate regression
reghdfe logPperAcre ib18.ring 1.post ib18.ring#1.post logDistLine post_logDistLine $Lot_X if LotSizeAcres>5 & S==1, a(i.locale#i.e_Year) cluster(locale e_Year)
// eststo hetero_Agland_SE

// Extract the coefficient and S.E. for ring=0 & post=1 
scalar coef_S = _b[0.ring#1.post]
scalar se_S = _se[0.ring#1.post]

// Calculate the 95% CI bounds
scalar lb_S = coef_S - 1.96 * se_S
scalar ub_S = coef_S + 1.96 * se_S

// *3. separate regression

reghdfe logPperAcre ib18.ring 1.post ib18.ring#1.post logDistLine post_logDistLine $Lot_X if LotSizeAcres>5 & W==1,  a(i.locale#i.e_Year) cluster(locale e_Year)
// eststo hetero_Agland_SE

// Extract the coefficient and S.E. for ring=0 & post=1 
scalar coef_W = _b[0.ring#1.post]
scalar se_W = _se[0.ring#1.post]

// Calculate the 95% CI bounds
scalar lb_W = coef_W - 1.96 * se_W
scalar ub_W = coef_W + 1.96 * se_W


// *4. separate regression
reghdfe logPperAcre ib18.ring 1.post ib18.ring#1.post logDistLine post_logDistLine $Lot_X if LotSizeAcres>5 & MW==1, a(i.locale#i.e_Year) cluster(locale e_Year)
// eststo hetero_Agland_LA

// Extract the coefficient and S.E. for ring=0 & post=1 
scalar coef_MW = _b[0.ring#1.post]
scalar se_MW = _se[0.ring#1.post]

// Calculate the 95% CI bounds
scalar lb_MW = coef_MW - 1.96 * se_MW
scalar ub_MW = coef_MW + 1.96 * se_MW

***************************************************
*regression on Ag & Vacant Land  - political leaning
***************************************************

// *1. separate regression
reghdfe logPperAcre ib18.ring 1.post ib18.ring#1.post logDistLine post_logDistLine $Lot_X if LotSizeAcres>5 & DEM==1, a(i.locale#i.e_Year) cluster(locale e_Year)
// eststo hetero_Agland_blue

// Extract the coefficient and S.E. for ring=0 & post=1 
scalar coef_blue = _b[0.ring#1.post]
scalar se_blue = _se[0.ring#1.post]

// Calculate the 95% CI bounds
scalar lb_blue = coef_blue - 1.96 * se_blue
scalar ub_blue = coef_blue + 1.96 * se_blue


// *2. separate regression
reghdfe logPperAcre ib18.ring 1.post ib18.ring#1.post logDistLine post_logDistLine $Lot_X if LotSizeAcres>5 & DEM==0, a(i.locale#i.e_Year) cluster(locale e_Year)
// eststo hetero_Agland_red

// Extract the coefficient and S.E. for ring=0 & post=1 
scalar coef_red = _b[0.ring#1.post]
scalar se_red = _se[0.ring#1.post]

// Calculate the 95% CI bounds
scalar lb_red = coef_red - 1.96 * se_red
scalar ub_red = coef_red + 1.96 * se_red



***************************************************
*regression on Ag & Vacant Land  - big USS
***************************************************

// *1. separate regression
reghdfe logPperAcre ib18.ring 1.post ib18.ring#1.post logDistLine post_logDistLine $Lot_X if LotSizeAcres>5 & bigUSS==1,a(i.locale#i.e_Year) cluster(locale e_Year)
// eststo hetero_Agland_bigS

// Extract the coefficient and S.E. for ring=0 & post=1 
scalar coef_bigUSS = _b[0.ring#1.post]
scalar se_bigUSS = _se[0.ring#1.post]

// Calculate the 95% CI bounds
scalar lb_bigUSS = coef_bigUSS - 1.96 * se_bigUSS
scalar ub_bigUSS = coef_bigUSS + 1.96 * se_bigUSS

// *2. separate regression
reghdfe logPperAcre ib18.ring 1.post ib18.ring#1.post logDistLine post_logDistLine $Lot_X if LotSizeAcres>5 & bigUSS==0, a(i.locale#i.e_Year) cluster(locale e_Year)
// eststo hetero_Agland_smallS

// Extract the coefficient and S.E. for ring=0 & post=1 
scalar coef_smallUSS = _b[0.ring#1.post]
scalar se_smallUSS = _se[0.ring#1.post]

// Calculate the 95% CI bounds
scalar lb_smallUSS = coef_smallUSS - 1.96 * se_smallUSS
scalar ub_smallUSS = coef_smallUSS + 1.96 * se_smallUSS


***************************************************
*regression on Ag & Vacant Land  - income
***************************************************

// *1. separate regression
reghdfe logPperAcre ib18.ring 1.post ib18.ring#1.post logDistLine post_logDistLine $Lot_X if LotSizeAcres>5 & high_income==1, a(i.locale#i.e_Year) cluster(locale e_Year)
// eststo hetero_Agland_high_income

// Extract the coefficient and S.E. for ring=0 & post=1 
scalar coef_highincome = _b[0.ring#1.post]
scalar se_highincome = _se[0.ring#1.post]

// Calculate the 95% CI bounds
scalar lb_highincome = coef_highincome - 1.96 * se_highincome
scalar ub_highincome = coef_highincome + 1.96 * se_highincome

// *2. separate regression
reghdfe logPperAcre ib18.ring 1.post ib18.ring#1.post logDistLine post_logDistLine $Lot_X if LotSizeAcres>5 & high_income==0, a(i.locale#i.e_Year) cluster(locale e_Year)
// eststo hetero_Agland_low_income
// Extract the coefficient and S.E. for ring=0 & post=1 
scalar coef_lowincome = _b[0.ring#1.post]
scalar se_lowincome = _se[0.ring#1.post]

// Calculate the 95% CI bounds
scalar lb_lowincome = coef_lowincome - 1.96 * se_lowincome
scalar ub_lowincome = coef_lowincome + 1.96 * se_lowincome


**********************************************************
*  regression on Ag & Vacant Land  - public_involvement  *  
**********************************************************

// *1. separate regression
reghdfe logPperAcre ib18.ring 1.post ib18.ring#1.post logDistLine post_logDistLine $Lot_X if LotSizeAcres>5 & public_involvement==1, a(i.locale#i.e_Year) cluster(locale e_Year)
// eststo hetero_Agland_involve

// Extract the coefficient and S.E. for ring=0 & post=1 
scalar coef_pub_involve = _b[0.ring#1.post]
scalar se_pub_involve = _se[0.ring#1.post]

// Calculate the 95% CI bounds
scalar lb_pub_involve = coef_pub_involve - 1.96 * se_pub_involve
scalar ub_pub_involve = coef_pub_involve + 1.96 * se_pub_involve


// *2. separate regression
reghdfe logPperAcre ib18.ring 1.post ib18.ring#1.post logDistLine post_logDistLine $Lot_X if LotSizeAcres>5 & public_involvement==0, a(i.locale#i.e_Year) cluster(locale e_Year)
// eststo hetero_Agland_involve0

// Extract the coefficient and S.E. for ring=0 & post=1 
scalar coef_no_involve = _b[0.ring#1.post]
scalar se_no_involve = _se[0.ring#1.post]

// Calculate the 95% CI bounds
scalar lb_no_involve = coef_no_involve - 1.96 * se_no_involve
scalar ub_no_involve = coef_no_involve + 1.96 * se_no_involve

*******************Aggregate Results
// Combine the coefficients and CIs into a single matrix
matrix hetero_combined = (coef_rural, lb_rural, ub_rural) \ (coef_urban, lb_urban, ub_urban) \ ///
                       (coef_biglot, lb_biglot, ub_biglot) \ (coef_smalllot, lb_smalllot, ub_smalllot) \ ///
					   (coef_NE, lb_NE, ub_NE) \ (coef_S, lb_S, ub_S) \ ///
					   (coef_W, lb_W, ub_W) \ (coef_MW, lb_MW, ub_MW) \ ///
					   (coef_blue, lb_blue, ub_blue) \ (coef_red, lb_red, ub_red) \ ///
					   (coef_bigUSS, lb_bigUSS, ub_bigUSS) \ (coef_smallUSS, lb_smallUSS, ub_smallUSS) \ ///
					   (coef_highincome, lb_highincome, ub_highincome) \ (coef_lowincome, lb_lowincome, ub_lowincome) \ ///
					   (coef_pub_involve, lb_pub_involve, ub_pub_involve) \ (coef_no_involve, lb_no_involve, ub_no_involve) 
					   


matrix rownames hetero_combined = "Rural" "Urban" "Big Lot" "Small Lot" "US Northeast" "US South" "US West" "US Midwest" ///
                                  "Dem-leaning" "Non-Dem" "Big USS" "Small USS" "High Income" "Low Income" "Public Involvement" "No Involvement"
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

// Assign value labels to the numerical variable
gen cat_num = _n
label define category 1 "Rural" 2 "Urban" 3 "Big Lot" 4 "Small Lot" 5 "US Northeast" 6 "US South" 7 "US West" 8 "US Midwest" 9 "Dem-leaning" 10 "Non-Dem" 11 "Big USS" 12 "Small USS" 13 "High Income" 14 "Low Income" 15 "Public Involvement" 16 "No Public Involvement"
label values cat_num category

// Create the plot with specific colors for each pair of categories
twoway (scatter Coefficient cat_num if cat_num==1 | cat_num==2, msymbol(diamond) msize(medium) mcolor(red)) ///
       (scatter Coefficient cat_num if cat_num==3 | cat_num==4, msymbol(diamond) msize(medium) mcolor(green)) ///
       (scatter Coefficient cat_num if cat_num==5 | cat_num==6, msymbol(diamond) msize(medium) mcolor(blue)) ///
       (scatter Coefficient cat_num if cat_num==7 | cat_num==8, msymbol(diamond) msize(medium) mcolor(blue)) ///
       (scatter Coefficient cat_num if cat_num==9 | cat_num==10, msymbol(diamond) msize(medium) mcolor(pink)) ///
       (scatter Coefficient cat_num if cat_num==11 | cat_num==12, msymbol(diamond) msize(medium) mcolor(black)) ///
       (scatter Coefficient cat_num if cat_num==13 | cat_num==14, msymbol(diamond) msize(medium) mcolor(brown)) ///
       (scatter Coefficient cat_num if cat_num==15 | cat_num==16, msymbol(diamond) msize(medium) mcolor(orange)) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==1 | cat_num==2, lcolor(red)) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==3 | cat_num==4, lcolor(green)) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==5 | cat_num==6, lcolor(blue)) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==7 | cat_num==8, lcolor(blue)) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==9 | cat_num==10, lcolor(pink)) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==11 | cat_num==12, lcolor(black)) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==13 | cat_num==14, lcolor(brown)) ///
       (rcap CI_Lower_Bound CI_Upper_Bound cat_num if cat_num==15 | cat_num==16, lcolor(orange)) ///
       , yline(0, lstyle(dash) lwidth(medium)) ///
       xlabel(1 "Rural" 2 "Urban" 3 "Big Lot" 4 "Small Lot" 5 "US Northeast" 6 "US South" 7 "US West" 8 "US Midwest" 9 "Dem-leaning" 10 "Non-Dem" 11 "Big USS" 12 "Small USS" 13 "High Income" 14 "Low Income" 15 "Public Involvement" 16 "No Public Involvement", angle(45)) ///
       ytitle("Change in Agricultural & Vacant Land Value") ///
       xtitle("") ///
       ylabel(-1 -.5 0 .5  1) ///
       legend(off)
graph export "$results\SI_land_heterogeneity16.pdf",as(pdf) replace	   
graph export "$results\SI_land_heterogeneity16.tif",as(tif) replace	   
	   
*Conduct z-test
mat Z=J(1,2,.)
scalar dif_mean = abs(coef_bigUSS - coef_smallUSS)
scalar dif_se = sqrt(se_bigUSS^2+se_smallUSS^2)
scalar z_stat = dif_mean/dif_se
di z_stat
scalar p_ztest = 2*(1-normal(z_stat))
di "z_stat is: " z_stat "  p_value is: " p_ztest
mat Z=(Z\ z_stat, p_ztest)

scalar dif_mean = abs(coef_pub_involve - coef_no_involve)
scalar dif_se = sqrt(se_pub_involve^2+se_no_involve^2)
scalar z_stat = dif_mean/dif_se
di z_stat
scalar p_ztest = 2*(1-normal(z_stat))
di "z_stat is: " z_stat "  p_value is: " p_ztest
mat Z=(Z\ z_stat, p_ztest)

scalar dif_mean = abs(coef_highincome - coef_lowincome)
scalar dif_se = sqrt(se_highincome^2+se_lowincome^2)
scalar z_stat = dif_mean/dif_se
di z_stat
scalar p_ztest = 2*(1-normal(z_stat))
di "z_stat is: " z_stat "  p_value is: " p_ztest
mat Z=(Z\ z_stat, p_ztest)

mat list Z

clear
svmat Z
drop if Z1==.
gen var=""
replace var="bigUSS_small" in 1
replace var="PublicinvolvePolicy_no" in 2
replace var="highincome_low" in 3

ren Z1 zstat
ren Z2 pvalue
order var zstat pvalue
save "$results\AgLandHeterogeneityTests.dta",replace
export delimited using "$results\AgLandHeterogeneityTests.csv", replace

/* Conclusion */
* limited sample size lead to sizable variations and estimation errors in effect estimates, and heterogeneities are hard to detect. 









************************************************************************
*                       Ag land with one home                          *
************************************************************************

*******************************************************************
*regression on Ag Home  - distance decay 2 miles each    Figure 5*
*******************************************************************
use "$dta\data_a5AgHome_foranalysis_final_new.dta", clear
*use "$dta\data_above5_AgHome_foranalysis_final.dta", clear
drop if near_dist_solar1>22
drop if Ag==1
cap drop locale
egen locale = group(near_fid1 county state)

cap drop ring
gen ring=0
	replace ring=0 if near_dist_solar1<=2
	
	count if near_dist_solar1<=2 &post==1
	di r(N)
foreach d of numlist 200(200)1600 {
	*treatment term
	replace ring=(`d')/100 if near_dist_solar1>((`d')/100) & near_dist_solar1<=(`d'+200)/100
	count if near_dist_solar1>((`d')/100) & near_dist_solar1<=(`d'+200)/100 &post==1
	di r(N)
	*interaction term
}
replace ring=18 if near_dist_solar1>18
drop if near_dist_solar1>20
*replace ring=20 if near_dist_solar1>20

reghdfe logSalesPrice ib18.ring 1.post ib18.ring#1.post logDistLine post_logDistLine $House_X if LotSizeAcres>5,  a(i.locale#i.e_Year) cluster(locale e_Year)
label variable logDistLine "log of (Distance to Nearest Power Line (miles))"
label variable post_logDistLine "post $\times$ log of (Distance to Nearest Power Line (miles))"
label variable logDistRoad "log of (Distance to Nearest Road (miles))"
label variable logDistMetro "log of (Distance to Nearest Metro Area (miles))"
label variable TotalRooms "Total Number of Rooms"
label variable TotalBedrooms "Total Number of Bedrooms"
label variable TotalCalculatedBathCount "Total Number of Bathrooms"
label variable BuildingAge "Building Age (years)"
est sto distdecay_study_Aghome
esttab using "$results\distdecay_study_Aghome.csv", se replace 
esttab using "$results\distdecay_study_Aghome.tex", se replace label ///
nonum  fragment
	
/*Control - land price between 12-20 mile*/
mat list e(b)
mat list e(V)

parmest, saving($results\distdecay_study_Aghome_results.dta, replace)

use $results\distdecay_study_Aghome_results.dta, clear
keep in 12/20

* Generate a numeric variable for the ring categories
gen ring = .
replace ring = 0 in 1
replace ring = 2 in 2
replace ring = 4 in 3
replace ring = 6 in 4
replace ring = 8 in 5
replace ring = 10 in 6
replace ring = 12 in 7
replace ring = 14 in 8
replace ring = 16 in 9
* Create variables for the confidence intervals
gen ci_low = min95
gen ci_high = max95

* List the data to verify
// list

twoway (connected estimate ring, lcolor(blue)) ///
       (rarea ci_low ci_high ring, lcolor(blue%1) color(blue%10)), ///
    xlabel(0 "[0,2)" 2 "[2,4)" 4 "[4,6)" 6 "[6,8)" 8 "[8,10)" 10 "[10,12)" 12 "[12,14)" 14 "[14,16)" 16 "[16,18)", angle(45)) ///
    legend(label(1 "Point Estimate") label(2 "95% CI") position(2) ring(0)) ///
 	ylabel(-.1 0 .1 .2 .3) ///
    ytitle("Effect on Log of Ag Home Price") ///
	xtitle("Distance (in miles)") ///
    yline(0, lw(thin) lcolor(red)) saving($results\AgHomeG5_distdecaystudy2mi_ring.gph, replace) 
//    title("Distance Decay Results of Ag and Vacant Land") ///
graph export "$results\AgHomeG5_distdecaystudy2mi_ring.pdf",as(pdf) replace
graph export "$results\AgHomeG5_distdecaystudy2mi_ring.tif",as(tif) replace

gr combine $results\AglandG5_distdecaystudy2mi_ring.gph $results\AgHomeG5_distdecaystudy2mi_ring.gph, cols(1) iscale(*0.95) imargin(vtiny)
graph export "$results\AgG5_combined_distdecaystudy2mi_ring.pdf",as(pdf) replace
graph export "$results\AgG5_combined_distdecaystudy2mi_ring.tif",as(tif) replace

* Little effect detected for ag homes. 
