clear all
set more off
set mem 240m
set matsize 800

cd "C:/Users/oporteous/Documents/Data/"

use tradethirdregionIVKO.dta

drop if qcomp==.

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

tabulate rcode, gen(region)
gen qpercap = qcomp/popn

*estimating epsilon
gen lnqpercap = ln(qpercap)
gen lnp = ln(pcomp)
*baseline OLS:
reg lnqpercap lnp region1-region28
reg lnqpercap lnp region1-region28, cluster(rcode)

*IV
gen lnpintltau = ln(pintltau)
*first stage:
reg lnp lnpintltau region1-region28, noconstant
reg lnp lnpintltau region1-region28, noconstant cluster(rcode)
*ivregress
ivregress 2sls lnqpercap region1-region28 (lnp = lnpintltau), noconstant
estat firststage
ivregress 2sls lnqpercap region1-region28 (lnp = lnpintltau), noconstant cluster(rcode)
estat firststage
