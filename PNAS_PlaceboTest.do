

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

global House_X "c.logDistRoad#i.ppost  c.logDistMetro#i.ppost  c.TotalBedrooms#i.ppost  c.TotalCalculatedBathCount#i.ppost  c.BuildingAge#i.ppost "
global Lot_X "c.logDistRoad#i.ppost  c.logDistMetro#i.ppost  "
* stcolor_alt  lean2 uncluttered plottig s1rcolor economist
set scheme plotplain
*Based on distance decay estimates, assign treatments: proximity <=2.5 mi, View



**************************************************************************************
***      Treatment Effect and Placebo Test  on Residential Homes b5 - Table S5     ***
**************************************************************************************
***************************************
***    <6 miles,  <5 acres         ***
***************************************
use "$dta\data_b5_foranalysis_final_new.dta",clear
drop if near_dist_solar1>6
*replace post = 1 if e_Year>=p_year_1

// sum LotSizeAcres, d 
// sum near_dist_solar1, d
egen locale=group(Tract)

*placebo test of the parallel trends
global control=6
global treat=3
drop if (near_dist_solar1<$treat+0.5) & (near_dist_solar1>$treat)
drop if (near_dist_solar1>$treat+3)

*treatment term
replace solar1T=0
replace solar1T=1 if near_dist_solar1<=$treat

gen T=solar1T
*Main
*Proximity only - placebo
*placebo test - regression on Resi Home - psydo treatment 5 years ahead
* 
gen ppost=0
replace ppost=1 if Year_relative>-6
gen ppost_logDistLine=logDistLine*ppost

reghdfe logSalesPrice 1.T 1.ppost 1.T#1.ppost logDistLine ppost_logDistLine $House_X if Year_relative<=-2 & Year_relative>=-12 ,  a(i.locale#i.e_Year) cluster(locale e_Year)

est sto ResiHome_plc

*View int Proximity - placebo
replace T=0
replace T=1 if solarview==1 & solar1T==1

gen T1=0
replace T1=1 if solarview==0 & solar1T==1

reghdfe logSalesPrice 1.T 1.T1 1.ppost 1.T#1.ppost 1.T1#1.ppost logDistLine ppost_logDistLine $House_X if Year_relative<=-2 & Year_relative>=-12,  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto ResiHome_plc_VintT


drop if solarview==0 & solar1T==1
reghdfe logSalesPrice 1.T 1.ppost 1.T#1.ppost logDistLine ppost_logDistLine $House_X if Year_relative<=-2 & Year_relative>=-12,  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto ResiHome_plc_VintT_drop

*********************************************************************
***      Treatment Effect and Placebo Test on AG & VACANT land    ***
*********************************************************************

***************************************
***    <20 miles,  >5 acres         ***
***************************************
use "$dta\data_a5Land_foranalysis_final_new.dta", clear
*0.ring is the treatment 
gen T=(0.ring==1)

*placebo test of the parallel trends
*first get an idea on how far ahead we can reach with the current data
tab Year_relative, sum(PperAcre)  /*good data go back to 25 years ahead*/

gen ppost=0
replace ppost=1 if e_Year>p_year_1-6
gen ppost_logDistLine=logDistLine*ppost
*placebo test - regression on pure Ag land with 0 building - psydo treatment 5 years ahead
reghdfe logPperAcre 1.T 1.ppost 1.T#1.ppost logDistLine ppost_logDistLine $Lot_X  if LotSizeAcres>=5 & post!=1 & Year_relative<-2 & Year_relative>=-12,  a(i.locale#i.e_Year) cluster(city e_Year)
est sto Agland_plc

esttab ResiHome_plc ResiHome_plc_VintT ResiHome_plc_VintT_drop Agland_plc using "$results/Placebotest_results.tex",replace se mti("plc-ProxyT" "plc ViewintProxyT" "plc Ag Land") keep(1.T 1.T#1.ppost) b(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
esttab ResiHome_plc ResiHome_plc_VintT ResiHome_plc_VintT_drop Agland_plc using "$results/Placebotest_results.csv",replace se mti("plc-ProxyT" "plc ViewintProxyT" "plc Ag Land") keep(1.T 1.T#1.ppost) b(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001)

