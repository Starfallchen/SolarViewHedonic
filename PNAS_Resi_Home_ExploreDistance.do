
clear all
set more off
cap log close
set seed 123456789

*Specify directories here
global AgSolar "..."
global dta "$AgSolar\data"
global results "$AgSolar\results"
global GIS  "$AgSolar\GIS"


global House_X "c.logDistRoad#i.post  c.logDistMetro#i.post  c.TotalBedrooms#i.post  c.TotalCalculatedBathCount#i.post  c.BuildingAge#i.post "
** stcolor_alt  lean2 uncluttered plottig s1rcolor economist
set scheme plotplain


*****************************************************************************************
*       Resi Home - compare view interact distance vs. distance decay    - Figure 2     *  
*****************************************************************************************
use "$dta\data_b5_foranalysis_final_new.dta",clear
drop if near_dist_solar1>6

*View as treatment - specifically, solar site view within 6miles
gen ViewT=0
replace ViewT=1 if solarview==1
gen post_ViewT=0
replace post_ViewT=post*ViewT

global control=6
egen State=group(state)
egen locale=group(Tract)

est clear

*Generate distance decay measures - segregate into rings
cap drop ring

gen ring=0
	replace ring=0 if near_dist_solar1<=1
	
	count if near_dist_solar1<=1 &post==1
	di r(N)

mat CNT=J(1,3,.)
foreach d of numlist 0(50)550 {
	*treatment term
	replace ring=(`d')/10 if near_dist_solar1>((`d')/100) & near_dist_solar1<=(`d'+50)/100
	count if near_dist_solar1>((`d')/100) & near_dist_solar1<=(`d'+50)/100 &post==1
	di r(N)  " in (`d')/100 to (`d'+50)/100"
	mat CNT=(CNT\r(N),`d'/100,(`d'+50)/100)
	*interaction term
}
replace ring=60 if near_dist_solar1>5
count if near_dist_solar1>5.5 &post==1
*di r(N) 
mat list CNT

/* control group 5-6mi*/

*Distance Decay
est clear
*
reghdfe logSalesPrice 1.post ib60.ring#0.ViewT ib60.ring#1.ViewT ib60.ring#1.post#0.ViewT ib60.ring#1.post#1.ViewT ib60.ring#1.ViewT logDistLine post_logDistLine $House_X if near_dist_solar1<=6&LotSizeAcres<5,  a(i.locale#i.e_Year) cluster(locale e_Year)
est sto distdecay_byview_study
esttab using "$results\distdecay_byview_study_ResiHome_b5.csv", replace 

mat list e(b)
*mat list e(V)

mat A=J(1,4,.)
mat B=J(1,4,.)
forv n=24(2)45  {
	local m = `n'+1
	
	di e(b)[1,`n']
	di sqrt(e(V)[`n',`n'])
	
	scalar lb1=e(b)[1,`n']-1.96*sqrt(e(V)[`n',`n'])
	scalar ub1=e(b)[1,`n']+1.96*sqrt(e(V)[`n',`n'])
	
	di e(b)[1,`m']
	di sqrt(e(V)[`m',`m'])
	
	scalar lb2=e(b)[1,`m']-1.96*sqrt(e(V)[`m',`m'])
	scalar ub2=e(b)[1,`m']+1.96*sqrt(e(V)[`m',`m'])
	
	mat A=(A\e(b)[1,`n'],sqrt(e(V)[`n',`n']),lb1,ub1)
	mat B=(B\e(b)[1,`m'],sqrt(e(V)[`m',`m']),lb2,ub2)
}
mat list A
mat list B

clear
svmat A
svmat B

ren A1 mean_View0
ren B1 mean_View1
drop if A2==.
gen ring=(_n-1)/2
drop if ring>4.5

twoway ///
    (connected mean_View0 ring, lp(solid) lcolor(blue) lwidth(medium)) ///
	(rarea A3 A4 ring, lcolor(blue%1) color(blue%15)) ///
    (connected mean_View1 ring, lp(solid) lcolor(red) lwidth(medium)) ///
	(rarea B3 B4 ring, lcolor(red%1) color(red%15)), /// 
    legend( label(1 "Estimate View=0") label(2 "95% CI View=0") label(3 "Estimate View=1") label(4 "95% CI View=1") position(5) ring(0) c(1) r(4)) ///
    xtitle("Distance (in miles)") xlabel(0 "[0,0.5)" 0.5 "[0.5,1)" 1 "[1,1.5)" 1.5 "[1.5,2)" 2 "[2,2.5)" 2.5 "[2.5,3)" 3 "[3,3.5)" 3.5 "[3.5,4)" 4 "[4,4.5)" 4.5 "[4.5,5)" ) ///
    ytitle("Effect on Natural Logarithm of Home Price") ysc(range(-0.12 0.05)) ylabel(-0.1 -0.05 0 0.05)

graph export "$results\DistanceDecayByview.tif", as(tif) replace
graph export "$results\DistanceDecayByview.pdf", as(pdf) replace

