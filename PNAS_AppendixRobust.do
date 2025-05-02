
clear all
set more off
cap log close
set seed 123456789

*Specify directories here
global AgSolar "..."
global dta "$AgSolar\data"
global results "$AgSolar\results"
global GIS  "$AgSolar\GIS"
global figures "$AgSolar\figures"

global House_X "c.logDistRoad#i.post  c.logDistMetro#i.post  c.TotalBedrooms#i.post  c.TotalCalculatedBathCount#i.post  c.BuildingAge#i.post "
*global House_X "TotalRooms TotalBedrooms TotalCalculatedBathCount BuildingAge"
global Lot_X "c.logDistRoad#i.post  c.logDistMetro#i.post  "
* stcolor_alt  lean2 uncluttered plottig s1rcolor economist
set scheme plotplain



********************************************************************************************************************************
**************************************************************************************************************************************                               Robustness check - Res Home  Control group  Table S6                                 ******
********************************************************************************************************************************
********************************************************************************************************************************

*********************************************************************
*   Robustness check - use observations in 5-5.5 mile as controls   *
*********************************************************************
use "$dta\data_b5_foranalysis_final_new.dta",clear
drop if near_dist_solar1>6
*replace post = 1 if e_Year>=p_year_1

*near_fid1 
egen locale=group(Tract)

global control=6
global treat=3

drop if (near_dist_solar1<$treat+2) & (near_dist_solar1>$treat)
drop if (near_dist_solar1>$treat+2.5)

*treatment term
replace solar1T=0
replace solar1T=1 if near_dist_solar1<=$treat

*View 
gen ViewT=0
replace ViewT=1 if solarview==1

reghdfe logSalesPrice 1.solar1T 1.post 1.solar1T#1.post logDistLine post_logDistLine $House_X ,  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto DID_ResiHome_Rob1

*reghdfe logSalesPrice 1.ViewT 1.post 1.ViewT#1.post logDistLine post_logDistLine $House_X ,  a(i.locale#i.e_Year) cluster(locale e_Year)
*est sto DID_view_ResiHome_Rob1

*Main - effect estimate
reghdfe logSalesPrice 1.solar1T#0.ViewT 1.post 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine $House_X,  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto DIDVintP_ResiHome_Rob1

*Main - effect estimate drop confounding treatment i.e., invisible within 3 mi
reghdfe logSalesPrice 1.post 1.solar1T#1.ViewT 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine $House_X if (solar1T==1&ViewT==1) | (solar1T!=1),  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto DIDVintP_ResiHome_drop_Rob1

esttab DID_ResiHome_Rob1 DIDVintP_ResiHome_Rob1 DIDVintP_ResiHome_drop_Rob1 using "$results/Main_Rob1.csv",replace b(a3) se mti("DID Proximity" "DID PintV") keep(1.solar1T 1.solar1T#1.post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post) star(+ 0.10 * 0.05 ** 0.01 *** 0.001)

************Robustness check - use observations in 5.25-5.75 mile as controls***********
use "$dta\data_b5_foranalysis_final_new.dta",clear
drop if near_dist_solar1>6

est clear
egen locale=group(Tract)

global control=6
global treat=3

drop if (near_dist_solar1<$treat+2.25) & (near_dist_solar1>$treat)
drop if (near_dist_solar1>$treat+2.75)
*treatment term
replace solar1T=0
replace solar1T=1 if near_dist_solar1<=$treat
*View 
gen ViewT=0
replace ViewT=1 if solarview==1

reghdfe logSalesPrice 1.solar1T 1.post 1.solar1T#1.post logDistLine post_logDistLine  $House_X ,  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto DID_ResiHome_Rob1

*reghdfe logSalesPrice 1.ViewT 1.post 1.ViewT#1.post logDistLine post_logDistLine $House_X ,  a(i.locale#i.e_Year) cluster(locale e_Year)
*est sto DID_view_ResiHome_Rob1


*Main - effect estimate
reghdfe logSalesPrice 1.solar1T#0.ViewT 1.post 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine $House_X,  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto DIDVintP_ResiHome_Rob1

*Main - effect estimate drop confounding treatment i.e., invisible within 3 mi
reghdfe logSalesPrice 1.post 1.solar1T#1.ViewT 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine $House_X if (solar1T==1&ViewT==1) | (solar1T!=1),  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto DIDVintP_ResiHome_drop_Rob1

esttab DID_ResiHome_Rob1 DIDVintP_ResiHome_Rob1 DIDVintP_ResiHome_drop_Rob1 using "$results/Main_Rob2.csv",replace b(a3) se mti("DID Proximity" "DID PintV") keep(1.solar1T 1.solar1T#1.post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post) star(+ 0.10 * 0.05 ** 0.01 *** 0.001)


************Robustness check - use observations in 4.75 - 5.75 mile as controls***********
use "$dta\data_b5_foranalysis_final_new.dta",clear
drop if near_dist_solar1>6

est clear
egen locale=group(Tract)

global control=6
global treat=3

drop if (near_dist_solar1<$treat+1.75) & (near_dist_solar1>$treat)
drop if (near_dist_solar1>$treat+2.75)
*treatment term
replace solar1T=0
replace solar1T=1 if near_dist_solar1<=$treat
*View 
gen ViewT=0
replace ViewT=1 if solarview==1

reghdfe logSalesPrice 1.solar1T 1.post 1.solar1T#1.post logDistLine post_logDistLine  $House_X ,  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto DID_ResiHome_Rob1

*reghdfe logSalesPrice 1.ViewT 1.post 1.ViewT#1.post logDistLine post_logDistLine $House_X ,  a(i.locale#i.e_Year) cluster(locale e_Year)
*est sto DID_view_ResiHome_Rob1


*Main - effect estimate
reghdfe logSalesPrice 1.solar1T#0.ViewT 1.post 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine $House_X,  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto DIDVintP_ResiHome_Rob1

*Main - effect estimate drop confounding treatment i.e., invisible within 3 mi
reghdfe logSalesPrice 1.post 1.solar1T#1.ViewT 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine $House_X if (solar1T==1&ViewT==1) | (solar1T!=1),  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto DIDVintP_ResiHome_drop_Rob1

esttab DID_ResiHome_Rob1 DIDVintP_ResiHome_Rob1 DIDVintP_ResiHome_drop_Rob1 using "$results/Main_Rob3.csv",replace b(a3) se mti("DID Proximity" "DID PintV") keep(1.solar1T 1.solar1T#1.post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post) star(+ 0.10 * 0.05 ** 0.01 *** 0.001)

************Robustness check - use observations in 4-5 mile as controls***********
use "$dta\data_b5_foranalysis_final_new.dta",clear
drop if near_dist_solar1>6

est clear
egen locale=group(Tract)

global control=6
global treat=3

drop if (near_dist_solar1<$treat+1) & (near_dist_solar1>$treat)
drop if (near_dist_solar1>$treat+2)
*treatment term
replace solar1T=0
replace solar1T=1 if near_dist_solar1<=$treat
*View 
gen ViewT=0
replace ViewT=1 if solarview==1

reghdfe logSalesPrice 1.solar1T 1.post 1.solar1T#1.post logDistLine post_logDistLine $House_X ,  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto DID_ResiHome_Rob1

*reghdfe logSalesPrice 1.ViewT 1.post 1.ViewT#1.post logDistLine post_logDistLine $House_X ,  a(i.locale#i.e_Year) cluster(locale e_Year)
*est sto DID_view_ResiHome_Rob1


*Main - effect estimate
reghdfe logSalesPrice 1.solar1T#0.ViewT 1.post 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine $House_X,  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto DIDVintP_ResiHome_Rob1

*Main - effect estimate drop confounding treatment i.e., invisible within 3 mi
reghdfe logSalesPrice 1.post 1.solar1T#1.ViewT 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine $House_X if (solar1T==1&ViewT==1) | (solar1T!=1),  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto DIDVintP_ResiHome_drop_Rob1

esttab DID_ResiHome_Rob1 DIDVintP_ResiHome_Rob1 DIDVintP_ResiHome_drop_Rob1 using "$results/Main_Rob4.csv",replace b(a3) se mti("DID Proximity" "DID PintV") keep(1.solar1T 1.solar1T#1.post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post) star(+ 0.10 * 0.05 ** 0.01 *** 0.001)


************Robustness check - use observations in 4-6 mile as controls***********
use "$dta\data_b5_foranalysis_final_new.dta",clear
drop if near_dist_solar1>6

est clear
egen locale=group(Tract)

global control=6
global treat=3

drop if (near_dist_solar1<$treat+1) & (near_dist_solar1>$treat)
drop if (near_dist_solar1>$treat+3)
*treatment term
replace solar1T=0
replace solar1T=1 if near_dist_solar1<=$treat
*View 
gen ViewT=0
replace ViewT=1 if solarview==1

reghdfe logSalesPrice 1.solar1T 1.post 1.solar1T#1.post logDistLine post_logDistLine $House_X ,  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto DID_ResiHome_Rob1

*reghdfe logSalesPrice 1.ViewT 1.post 1.ViewT#1.post logDistLine post_logDistLine $House_X ,  a(i.locale#i.e_Year) cluster(locale e_Year)
*est sto DID_view_ResiHome_Rob1


*Main - effect estimate
reghdfe logSalesPrice 1.solar1T#0.ViewT 1.post 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine $House_X,  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto DIDVintP_ResiHome_Rob1

*Main - effect estimate drop confounding treatment i.e., invisible within 3 mi
reghdfe logSalesPrice 1.post 1.solar1T#1.ViewT 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine $House_X if (solar1T==1&ViewT==1) | (solar1T!=1),  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto DIDVintP_ResiHome_drop_Rob1

esttab DID_ResiHome_Rob1 DIDVintP_ResiHome_Rob1 DIDVintP_ResiHome_drop_Rob1 using "$results/Main_Rob5.csv",replace b(a3) se mti("DID Proximity" "DID PintV") keep(1.solar1T 1.solar1T#1.post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post) star(+ 0.10 * 0.05 ** 0.01 *** 0.001)









*************************************************************************************************************************
*************************************************************************************************************************
          **                    Robustness check - Land   Control Group      Table S7                      **
*************************************************************************************************************************
*************************************************************************************************************************
global Lot_X "c.logDistRoad#i.post  c.logDistMetro#i.post  "

**********************************************************************
***      Robustness Check on AG & VACANT land Treatment Effect     ***
**********************************************************************
***    <20 miles,  >5 acres         ***
***************************************
use "$dta\data_a5Land_foranalysis_final_new.dta", clear
*0.ring is the treatment 
gen T=(0.ring==1)
drop if SFR==1
cap drop locale
egen locale = group(near_fid1 county state)
*drop if ring>=2 & ring<=16
drop if near_dist_solar1>19
replace ring=18 if near_dist_solar1>17

reghdfe logPperAcre 1.T 1.post 1.T#1.post i.ring#i.post logDistLine post_logDistLine c.logDistRoad  c.logDistMetro if (LotSizeAcres>=5),  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto DID_Agland_Rob1

use "$dta\data_a5Land_foranalysis_final_new.dta", clear
*0.ring is the treatment 
gen T=(0.ring==1)
drop if SFR==1
cap drop locale
egen locale = group(near_fid1 county state)
*drop if ring>=2 & ring<=16
drop if near_dist_solar1>20

reghdfe logPperAcre 1.T 1.post 1.T#1.post i.ring#i.post logDistLine post_logDistLine $Lot_X if (LotSizeAcres>=5),  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto DID_Agland_Mean

use "$dta\data_a5Land_foranalysis_final_new.dta", clear
*0.ring is the treatment 
gen T=(0.ring==1)
drop if SFR==1
cap drop locale
egen locale = group(near_fid1 county state)
*drop if ring>=2 & ring<=16
drop if near_dist_solar1>21

reghdfe logPperAcre 1.T 1.post 1.T#1.post i.ring#i.post logDistLine post_logDistLine $Lot_X if (LotSizeAcres>=5),  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto DID_Agland_Rob2


use "$dta\data_a5Land_foranalysis_final_new.dta", clear
*0.ring is the treatment 
gen T=(0.ring==1)
drop if SFR==1
cap drop locale
egen locale = group(near_fid1 county state)
*drop if ring>=2 & ring<=16
drop if near_dist_solar1>22

reghdfe logPperAcre 1.T 1.post 1.T#1.post i.ring#i.post logDistLine post_logDistLine $Lot_X if (LotSizeAcres>=5),  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto DID_Agland_Rob3

use "$dta\data_a5Land_foranalysis_final_new.dta", clear
*0.ring is the treatment 
gen T=(0.ring==1)
drop if SFR==1
cap drop locale
egen locale = group(near_fid1 county state)
*drop if ring>=2 & ring<=16
drop if near_dist_solar1>23

reghdfe logPperAcre 1.T 1.post 1.T#1.post i.ring#i.post logDistLine post_logDistLine $Lot_X if (LotSizeAcres>=5),  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto DID_Agland_Rob4

esttab DID_Agland_Rob1 DID_Agland_Mean DID_Agland_Rob2  DID_Agland_Rob3 DID_Agland_Rob4 using "$results/RobustnessCheck_Agland_results.csv",replace keep(1.T#1.post) se mti("DID_Agland_Rob1" "Main") b(a3) star(+ 0.10 * 0.05 ** 0.01 *** 0.001)










***************************************************************************************************************************
***************************************************************************************************************************
           **                              Robustness check - Res Home  Acreage Threshold  Table S8                        **
**************************************************************************************************************************
***************************************************************************************************************************

***************************************************************************************************
*   Robustness check - use different acreage threshold for residential analysis sample selection  *
***************************************************************************************************
use "$dta\data_b5_foranalysis_final_new.dta",clear
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

sum LotSizeAcres
est clear
foreach a of numlist 5(-.5)0.5 {
	*Main - effect estimate
reghdfe logSalesPrice 1.solar1T#0.ViewT 1.post 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine $House_X if LotSizeAcres<=`a',  a(i.locale#i.e_Year) cluster(locale e_Year)

local b = 10*`a'
est sto DIDVintP_ResiHome_Rob`b'

reghdfe logSalesPrice 1.solar1T 1.post 1.solar1T#1.post logDistLine post_logDistLine $House_X if LotSizeAcres<=`a',  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto DID_ResiHome_Rob`b'
}

reghdfe logSalesPrice 1.solar1T#0.ViewT 1.post 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine $House_X if LotSizeAcres<=0.3,  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto DIDVintP_ResiHome_Rob3

reghdfe logSalesPrice 1.solar1T 1.post 1.solar1T#1.post logDistLine post_logDistLine $House_X if LotSizeAcres<=0.3,  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto DID_ResiHome_Rob3

esttab DID_ResiHome_Rob* DIDVintP_ResiHome_Rob* using "$results/TableS8_AcreRob.csv",replace b(a3) se mti("AcreRob 5 main") keep(1.solar1T 1.solar1T#1.post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post) star(+ 0.10 * 0.05 ** 0.01 *** 0.001)


***************************************************************************************************
*   Robustness check - use different acreage threshold for ag land sample selection  *
***************************************************************************************************
use "$dta\data_a5Land_foranalysis_final_new.dta", clear
*0.ring is the treatment 
gen T=(0.ring==1)
drop if near_dist_solar1>22
drop if SFR==1
cap drop locale
egen locale = group(near_fid1 county state)
*drop if ring>=2 & ring<=16
drop if near_dist_solar1>20

sum LotSizeAcres
est clear
foreach a of numlist 5(0.5)10 {

reghdfe logPperAcre 1.T 1.post 1.T#1.post i.ring#i.post logDistLine post_logDistLine $Lot_X if (LotSizeAcres>=`a'),  a(i.locale#i.e_Year) cluster(locale e_Year)
local b = 10*`a'
est sto DID_Agland_Rob`b'
}

esttab DID_Agland_Rob* using "$results/TableS8_Land_AcreRob.csv",replace b(a3) se mti("AcreRob 5 main") keep(1.T#1.post) star(+ 0.10 * 0.05 ** 0.01 *** 0.001)


***************************************************************************************************
*   Robustness check - use different acreage threshold for ag home sample selection  *
***************************************************************************************************
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

gen T=(0.ring==1)
*replace ring=20 if near_dist_solar1>20
sum LotSizeAcres
est clear
foreach a of numlist 5.5(0.5)10 {
	
reghdfe logSalesPrice 1.T 1.post 1.T#1.post ib18.ring#i.post logDistLine post_logDistLine $House_X if (LotSizeAcres>=`a'),  a(i.locale#i.e_Year) cluster(locale e_Year)
local b = 10*`a'
est sto DID_Aghome_Rob`b'
}
esttab DID_Aghome_Rob* using "$results\TableS8_Aghome_AcreRob.csv", replace b(a3) se mti("AcreRob 5p5") keep(1.T#1.post) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) 





*************************************************************************************************************************
*************************************************************************************************************************
           **                       Robustness check - Transaction No. per Cluster Threshold  Table S9             **
*************************************************************************************************************************
*************************************************************************************************************************

***************************************************************************************************
*   Robustness check - use different obs per cluster threshold for residential analysis sample selection  *
***************************************************************************************************
use "$dta\data_b5_foranalysis_final_new.dta",clear
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

egen cluster = group(locale e_Year)
duplicates tag cluster, gen(dup_cluster)

sum dup_cluster,d
est clear
foreach a of numlist 0(5)20 {
	*Main - effect estimate
reghdfe logSalesPrice 1.solar1T#0.ViewT 1.post 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post logDistLine post_logDistLine $House_X if dup_cluster>=`a',  a(i.locale#i.e_Year) cluster(locale e_Year)

est sto DIDVintP_ResiHome_Rob`a'

reghdfe logSalesPrice 1.solar1T 1.post 1.solar1T#1.post logDistLine post_logDistLine $House_X if dup_cluster>=`a',  a(i.locale#i.e_Year) cluster(locale e_Year)

est sto DID_ResiHome_Rob`a'
}


esttab DID_ResiHome_Rob* DIDVintP_ResiHome_Rob* using "$results/TableS9_SaleNoCluster.csv",replace b(a3) se mti("SaleNoCluster main") keep(1.solar1T 1.solar1T#1.post 1.solar1T#0.ViewT 1.solar1T#1.ViewT 1.solar1T#0.ViewT#1.post 1.solar1T#1.ViewT#1.post) star(+ 0.10 * 0.05 ** 0.01 *** 0.001)


***************************************************************************************************
*   Robustness check - use different obs per cluster threshold for ag land sample selection  *
***************************************************************************************************
use "$dta\data_a5Land_foranalysis_final_new.dta", clear
*0.ring is the treatment 
gen T=(0.ring==1)
drop if SFR==1
cap drop locale
egen locale = group(near_fid1 county state)
*drop if ring>=2 & ring<=16
drop if near_dist_solar1>20


egen cluster = group(locale e_Year)
duplicates tag cluster, gen(dup_cluster)

sum dup_cluster,d
est clear
foreach a of numlist 0(5)50 {

reghdfe logPperAcre 1.T 1.post 1.T#1.post i.ring#i.post logDistLine post_logDistLine $Lot_X if dup_cluster>=`a',  a(i.locale#i.e_Year) cluster(locale e_Year)

est sto DID_Agland_Rob`a'
}

esttab DID_Agland_Rob* using "$results/TableS9_Land_SaleNoCluster.csv",replace b(a3) se mti("SaleNoCluster main") keep(1.T#1.post) star(+ 0.10 * 0.05 ** 0.01 *** 0.001)


***************************************************************************************************
*   Robustness check - use different obs per cluster threshold for ag home sample selection  *
***************************************************************************************************
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

gen T=(0.ring==1)
*replace ring=20 if near_dist_solar1>20
sum LotSizeAcres

egen cluster = group(locale e_Year)
duplicates tag cluster, gen(dup_cluster)

sum dup_cluster,d

est clear
foreach a of numlist 0(5)50 {
	
reghdfe logSalesPrice 1.T 1.post 1.T#1.post ib18.ring#i.post logDistLine post_logDistLine $House_X if dup_cluster>=`a',  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto DID_Aghome_Rob`a'
}
esttab DID_Aghome_Rob* using "$results\TableS9_Aghome_SaleNoCluster.csv", replace b(a3) se mti("SaleNoCluster main") keep(1.T#1.post) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

