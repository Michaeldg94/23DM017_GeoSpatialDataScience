clear all
set more off
set mem 240m
set matsize 800

cd "C:/Users/oporteous/Documents/Data/"

use tradesecondINTLtauwKO.dta
drop if price==.
drop if quantitylag==9999

gen ccode = 0
replace ccode=1 if country == "Angola" 
replace ccode=2 if country == "Benin" 
replace ccode=3 if country == "Botswana" 
replace ccode=4 if country == "Burkina" 
replace ccode=5 if country == "Burundi" 
replace ccode=6 if country == "Cameroon" 
replace ccode=7 if country == "CAR" 
replace ccode=8 if country == "Chad" 
replace ccode=9 if country == "Congo" 
replace ccode=10 if country == "CdI" 
replace ccode=11 if country == "DRC" 
replace ccode=12 if country == "Djibouti" 
replace ccode=13 if country == "Eritrea" 
replace ccode=14 if country == "Ethiopia" 
replace ccode=15 if country == "Gabon" 
replace ccode=16 if country == "Gambia" 
replace ccode=17 if country == "Ghana" 
replace ccode=18 if country == "Guinea" 
replace ccode=19 if country == "GB" 
replace ccode=20 if country == "Kenya" 
replace ccode=21 if country == "Lesotho" 
replace ccode=22 if country == "Liberia" 
replace ccode=23 if country == "Malawi" 
replace ccode=24 if country == "Mali" 
replace ccode=25 if country == "Mauritania" 
replace ccode=26 if country == "Mozambique" 
replace ccode=27 if country == "Namibia" 
replace ccode=28 if country == "Niger" 
replace ccode=29 if country == "Nigeria" 
replace ccode=30 if country == "Rwanda" 
replace ccode=31 if country == "Senegal" 
replace ccode=32 if country == "SL" 
replace ccode=33 if country == "Somalia" 
*replace country = "" if ccode==34
replace ccode=35 if country == "Sudan" 
replace ccode=36 if country == "Swaziland" 
replace ccode=37 if country == "Tanzania" 
replace ccode=38 if country == "Togo" 
replace ccode=39 if country =="Uganda" 
replace ccode=40 if country == "Zambia" 
replace ccode=41 if country == "Zimbabwe"

*getting rid of 1 Mozambique outlier
drop if quantitylag<0

*adjusting for special trade data (Botswana, Angola, Namibia, Lesotho, Swazi)
gen keep2012 = 0
replace keep2012 = 1 if ccode==1
replace keep2012 = 1 if ccode==27
replace keep2012 = 1 if ccode==21
drop if keep2012==0 & y==2012
drop if ccode==21 & y<2012
drop if ccode==36 & y>=2006

*getting rid of unbalanced crops
drop if ccode==10 & y<=2004
drop if ccode==14 & y<=2004
drop if ccode==24 & y<=2004
drop if ccode==31 & y<=2005
drop if ccode==35 & y<=2006
drop if ccode==39 & y<=2009
*Sudan missing wheat imports (KO addition)
drop if ccode==35 & y>=2011

gen expen = quantitylag*price
gen cycode = ccode*10000 + y
sort cycode
by cycode: egen expenT = total(expen)

by cycode: egen countcheck = count(expen)
sort country
by country: egen countcheck2 = max(countcheck)
gen countcheck3 = 0
replace countcheck3 = 1 if countcheck2>countcheck
drop if countcheck3 == 1

gen exshare = expen/expenT

gen gcode = 0
replace gcode = 1 if c == "Maize"
replace gcode = 2 if c == "Millet"
replace gcode = 3 if c == "Rice"
replace gcode = 4 if c == "Sorghum"
replace gcode = 5 if c == "Teff"
replace gcode = 6 if c == "Wheat"

tabulate gcode, gen(g)

gen rcode = 0
replace rcode = 1 if ccode == 1
replace rcode = 1 if ccode == 3
replace rcode = 1 if ccode == 27

replace rcode = 2 if ccode == 9
replace rcode = 2 if ccode == 15

replace rcode = 3 if ccode==7
replace rcode = 3 if ccode==11

replace rcode = 4 if ccode==18
replace rcode = 4 if ccode==22
replace rcode = 4 if ccode==32

replace rcode = 5 if ccode==16
replace rcode = 5 if ccode==19
replace rcode = 5 if ccode==31

replace rcode = 6 if ccode==21
replace rcode = 6 if ccode==36
replace rcode = 6 if ccode==41
replace rcode = 6 if ccode==40
replace rcode = 18 if ccode==23

replace rcode = 7 if ccode==30
replace rcode = 28 if ccode==39
replace rcode = 7 if ccode==5

replace rcode = 27 if ccode==14
replace rcode = 8 if ccode==13

replace rcode = 9 if ccode==2
replace rcode = 26 if ccode==38

replace rcode = 10 if ccode==4
replace rcode = 11 if ccode==28

replace rcode = 12 if ccode==6
replace rcode = 13 if ccode==10

replace rcode = 14 if ccode==17
replace rcode = 15 if ccode==29

replace rcode = 16 if ccode==26
replace rcode = 17 if ccode==37

replace rcode = 19 if ccode==8
replace rcode = 20 if ccode==12
replace rcode = 21 if ccode==20
replace rcode = 22 if ccode==24
replace rcode = 23 if ccode==25
replace rcode = 24 if ccode==33
replace rcode = 25 if ccode==35


**********try sigma
gen lnsh = ln(exshare)
gen lnp = ln(price)
gen rgcode = gcode*100+rcode
gen cgcode = gcode*100+ccode

*drop if only 1 crop (just simplifies)
drop if ccode ==1
drop if ccode ==3
drop if ccode ==9
drop if ccode ==12
drop if ccode ==13
drop if ccode ==15
drop if ccode ==18
drop if ccode ==20
drop if ccode ==21
drop if ccode ==22
drop if ccode ==23
drop if ccode ==27
drop if ccode ==32
drop if ccode ==36
drop if ccode ==40
drop if ccode ==41
 
tabulate rgcode, gen(rg)
tabulate cycode, gen(cy)
gen rycode = rcode*10000 + y
tabulate rycode, gen(ry)
tabulate cgcode, gen(cg)

*next line is baseline OLS (no IV)
reg lnsh lnp rg1-rg55 cy1-cy166, noconstant cluster(cgcode)

*drop millet and teff
drop if priceintl>100

*IV
gen lnpint = ln(priceintl)
*first stage:
reg lnp lnpint rg1-rg55 cy1-cy166, noconstant
reg lnp lnpint rg1-rg55 cy1-cy166, noconstant cluster(cgcode)
*full iv:
ivregress 2sls lnsh rg1-rg55 cy1-cy166 (lnp = lnpint), noconstant
estat firststage
ivregress 2sls lnsh rg1-rg55 cy1-cy166 (lnp = lnpint), noconstant cluster(cgcode)
estat firststage
