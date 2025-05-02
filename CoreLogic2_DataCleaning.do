
clear all
set more off
global root "E:\CoreLogic"
global dta "E:\CoreLogic\dta"

/*
foreach State in CA NC NY {
	use "$dta\CoreLogic_Merged_CA_NY_NC.dta",clear
	keep if SITUSSTATE=="`State'"
	save ,replace
}
*/

*Check DocumentTypeCode with CoreLogic

*********************************
*         Data Cleaning         *
*********************************
global CATE "AIRCONDITIONINGTYPECODE HEATINGTYPECODE BUILDINGTYPECODE BUILDINGIMPROVEMENTCONDITIONCODE CONSTRUCTIONTYPECODE EXTERIORWALLTYPECODE FOUNDATIONTYPECODE GARAGETYPECODE TOTALNUMBEROFPARKINGSPACES PARKINGTYPECODE POOLINDICATOR POOLTYPECODE BUILDINGQUALITYCODE ROOFTYPECODE BUILDINGSTYLETYPECODE  FUELTYPECODE ELECTRICITYWIRINGTYPECODE SEWERTYPECODE UTILITIESTYPECODE WATERTYPECODE"
*Use locational info from assessment data here, as those from ownertransfer contain more missing values
global GeoUnit "SITUSSTREETADDRESS SITUSSTREETNAME SITUSCITY SITUSSTATE SITUSZIPCODE SITUSCOUNTY SITUSCARRIERROUTE MUNICIPALITYNAME TOWNCODE TAXAREACODE SCHOOLDISTRICTNAME NEIGHBORHOODDESCRIPTION SITUSCOREBASEDSTATISTICALAREACBS "


global X0 "LivingSQFT TotalBathroomNum TotalBedroomNum TotalRoomNum NoofFirePlace NoofBuildings NoofStories NoofUnits"


****************************************************
*				  in Bulks                         *
****************************************************
*
foreach n of numlist 1(1)10 {
	use "$dta\CoreLogic_Merged_SFR_AG_Bulk_`n'.dta",clear
	drop if MANUFACTUREDHOMEINDICATOR=="Y"
	drop if FORECLOSURESTAGECODE!=""

	*Elementary and Highschool district not complete - SCHOOLDISTRICTNAME is much more populated
	*Unpopulated variables are dropped
	drop  EFFECTIVEYEARBUILTSTATIC SELLER2FULLNAME RECORDACTIONINDICATOR FIREDISTRICTCOUNTYNAME ELEMENTARYSCHOOLDISTRICTCOUNTYDE HIGHSCHOOLDISTRICTCOUNTYDESCRIPT COUNTYLANDUSEDESCRIPTION MANUFACTUREDHOMEINDICATOR ZONINGCODE ZONINGCODEDESCRIPTION PROPERTYINDICATORCODE NUMBEROFBUILDINGS FORECLOSURESTAGECODE LASTFORECLOSURETRANSACTIONDATE TAXRATEAREACODE MARKETLANDVALUE MARKETIMPROVEMENTVALUE APPRAISEDTOTALVALUE APPRAISEDLANDVALUE APPRAISEDIMPROVEMENTVALUE TAXABLEIMPROVEMENTVALUE TAXABLELANDVALUE NETTAXAMOUNT DISABLEDEXEMPTINDICATOR VETERANEXEMPTINDICATOR WIDOWEXEMPTINDICATOR TOTALTAXEXEMPTIONAMOUNT CALCULATEDTOTALTAXEXEMPTIONAMOUN FRONTFOOTAGE DEPTHFOOTAGE EASEMENTTYPECODE EFFECTIVEYEARBUILT CLIP PREVIOUSCLIP TAXROLLEDITIONNUMBER

	ren TOTALNUMBEROFACRES ACRES
	**********************************ren or clean***********************************
	ren BLOCKLEVELLATITUDE ADDLEVELLATITUDE
	ren BLOCKLEVELLONGITUDE ADDLEVELLONGITUDE
	ren SALEDERIVEDDATE SALE_Date
	ren SALEAMOUNT SalesPrice
	*Many Mailing Addresses are inconsistent with Parcel Address  -  could study Second Home with this data
	count if SITUSSTREETADDRESS!= MAILINGSTREETADDRESS   /*1.13 mi out of 4.14 mi */

	*Yearbuilt in the assessment file is more populated than in the ownertransfer file - and they are inconcistent for a large share
	gen BuildingAge_e = SALE_Year - ACTUALYEARBUILTSTATIC 
	replace BuildingAge_e = SALE_Year-YEARBUILT if BuildingAge<=0 | BuildingAge==.
	drop if BuildingAge_e>300
	drop if BuildingAge_e<0  /* negative building age means the house attributes are inaccurate for the transaction*/

	*drop obs with missing coordinates - none
	drop if ADDLEVELLATITUDE==. & PARCELLEVELLATITUDE==. 
	*drop obs with missing sales date - none
	drop if SALE_Date==.

	********Dropping non-arms length sales or other types that may not represent fair market value********
	*Some sales that may not represent fair market value already dropped in the earlier data process, based on variables from CoreLogic 
	*Already dropped when processing transactions
	/*
	drop if SHORTSALEINDICATOR==1
	drop if FORECLOSUREREOINDICATOR==1
	drop if FORECLOSUREREOSALEINDICATOR==1
	drop if NEWCONSTRUCTIONINDICATOR==1
	drop if INVESTORPURCHASEINDICATOR==1 
	drop if INTERFAMILYRELATEDINDICATOR==1

	drop if PENDINGRECORDINDICATOR=="Y"
	*Could not be matched with tax roll
	*/

	*drop obs with missing transaction prices - about 1.5 percent
	drop if SalesPrice==.

	gen Mul_sale=(DEEDSITUSHOUSENUMBER2STATIC!=""|BUYERMAILINGHOUSENUMBER2!="")
	drop if Mul_sale==1 /*restriction: 20,937 observations deleted*/

	drop if SalesPrice<1000
	/*restriction: 10,415 observations deleted*/

	*drop price outlier - potential change make the outliers determined in each year
	sum SalesPrice, detail
	drop if SalesPrice<=r(p1)|SalesPrice>=r(p99)
	/*restriction: 69,806 observations deleted*/
	*3.35 mi sales left

	tab SALE_Year
	drop if SALE_Year<=1984 
	/*restriction: 11,904 observations deleted; obviously, many counties do not report sales before 1985 - discontinuous change in sales numbers; dropping to maintain representativeness*/
	drop if RESALEINDICATOR==0
	*drop new construction sales - restriction: 564 dropped */

	tab CASHPURCHASEINDICATOR MORTGAGEPURCHASEINDICATOR
	*Certain sales are not decided on whether it is with a mortgage loan or not

	*Now check property characteristics to clean variables and filter unusable observations
	global X1 "BuildingAge_e LivingSQFT TotalBathroomNum TotalBedroomNum TotalRoomNum NoofFirePlace NoofBuildings NoofStories NoofUnits TOTALNUMBEROFPARKINGSPACES "
	foreach v in SalesPrice $X1 {
		di "`v'"
		count if `v'==.
	}
	gen BuildingAge_sq = BuildingAge_e*BuildingAge_e

	tab NoofBuildings
	drop if NoofBuildings!=1 /*restriction: 7,319 observations deleted*/
	drop if NoofUnits>1 & NoofUnits!=.

	drop if NoofFirePlace>10 & NoofFirePlace!=. /*restriction: 24 observations deleted*/
	replace NoofFirePlace=0 if NoofFirePlace==.

	foreach v in TotalBathroomNum TotalBedroomNum NoofStories {
		sum `v'
		replace `v'=r(mean) if `v'==.
	}

	*Using TotalBathroomNum and TotalBedroomNum, TotalRoomNum is largely not populated (more than 60%)
	global X1 "BuildingAge_e BuildingAge_sq LivingSQFT TotalBathroomNum TotalBedroomNum NoofFirePlace NoofStories"
	foreach v in SalesPrice $X1 {
		di "`v'"
		count if `v'==.
	}

	global CATE "AIRCONDITIONINGTYPECODE HEATINGTYPECODE BUILDINGTYPECODE BUILDINGIMPROVEMENTCONDITIONCODE CONSTRUCTIONTYPECODE EXTERIORWALLTYPECODE FOUNDATIONTYPECODE GARAGETYPECODE PARKINGTYPECODE POOLINDICATOR POOLTYPECODE BUILDINGQUALITYCODE ROOFTYPECODE BUILDINGSTYLETYPECODE FUELTYPECODE ELECTRICITYWIRINGTYPECODE SEWERTYPECODE WATERTYPECODE"
	foreach v in $CATE {
		di "`v'"
		count if `v'==""
	}

	tab AIRCONDITIONINGTYPECODE
	gen Aircondition=(AIRCONDITIONINGTYPECODE!="")

	tab HEATINGTYPECODE
	gen Heated=(HEATINGTYPECODE!="")

	tab BUILDINGIMPROVEMENTCONDITIONCODE
	drop if BUILDINGIMPROVEMENTCONDITIONCODE=="001"
	replace BUILDINGIMPROVEMENTCONDITIONCODE="NA" if BUILDINGIMPROVEMENTCONDITIONCODE==""
	egen BuildingCondition=group(BUILDINGIMPROVEMENTCONDITIONCODE)
	tab BuildingCondition BUILDINGIMPROVEMENTCONDITIONCODE

	tab ELECTRICITYWIRINGTYPECODE
	tab EXTERIORWALLTYPECODE

	tab GARAGETYPECODE
	gen Garage=(GARAGETYPECODE!="")
	tab Garage

	tab POOLINDICATOR
	gen Pool=(POOLINDICATOR!="")

	tab BUILDINGSTYLETYPECODE /*The primary building type (e.g., Bowling Alley, Supermarket)*/
	replace BUILDINGSTYLETYPECODE="NA" if BUILDINGSTYLETYPECODE==""
	egen BuildingType=group(BUILDINGSTYLETYPECODE)

	tab FUELTYPECODE
	replace FUELTYPECODE="NA" if FUELTYPECODE==""
	gen FUELTYPE_e = "GAS" if FUELTYPECODE=="FGA"|FUELTYPECODE=="FGP"|FUELTYPECODE=="00G"
	replace FUELTYPE_e = "SOLAR" if FUELTYPECODE=="FGS"|FUELTYPECODE=="FOS"|FUELTYPECODE=="FSO"|FUELTYPECODE=="00S"|FUELTYPECODE=="00Z"
	replace FUELTYPE_e = "OIL" if FUELTYPECODE=="FOI"|FUELTYPECODE=="00O"|FUELTYPECODE=="00Y"
	replace FUELTYPE_e = "ELEC" if FUELTYPECODE=="FEL"|FUELTYPECODE=="00R"|FUELTYPECODE=="00T"
	replace FUELTYPE_e = "Other" if FUELTYPE_e==""
	egen FuelType=group(FUELTYPE_e)
	tab FuelType FUELTYPE_e

	tab SEWERTYPECODE
	replace SEWERTYPECODE="NA" if SEWERTYPECODE==""
	gen SEWER_e="PUB" if SEWERTYPECODE=="SPU"
	replace SEWER_e="PRIVATE" if SEWERTYPECODE=="SPR"|SEWERTYPECODE=="SSE"|SEWERTYPECODE=="STR"|SEWERTYPECODE=="SCE"
	replace SEWER_e="COMMERCIAL" if SEWERTYPECODE=="SCO"
	replace SEWER_e="Other" if SEWER_e==""
	egen SewerType=group(SEWER_e)

	tab WATERTYPECODE
	replace WATERTYPECODE="NA" if WATERTYPECODE==""
	egen WaterType=group(WATERTYPECODE)

	global CATE1 "Aircondition Heated BuildingCondition BuildingType Garage Pool FuelType SewerType WaterType"
	foreach v in $CATE1 {
		di "`v'"
		count if `v'==.
	}
	global CATE1_FE "i.Aircondition i.Heated i.BuildingCondition i.BuildingType i.Garage i.Pool i.FuelType i.SewerType i.WaterType"
	save "$dta\CoreLogic_Cleaned_Bulk_`n'.dta",replace
}


