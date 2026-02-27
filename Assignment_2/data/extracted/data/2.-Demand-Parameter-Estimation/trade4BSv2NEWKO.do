clear all
set more off
set mem 240m
set matsize 800

cd "C:/Users/oporteous/Documents/Data/"

use trade4BSv2KO.dta

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

*getting rid of 1 Mozambique outlier (rice)
drop if qu1<0
drop if qu2<0
drop if qu3<0
drop if qu4<0
drop if qu5<0
drop if qu6<0

*adjusting for special trade data (Botswana, Angola, Namibia, Lesotho, Swazi)
gen keep2012 = 0
replace keep2012 = 1 if ccode==1
replace keep2012 = 1 if ccode==27
replace keep2012 = 1 if ccode==21
drop if keep2012==0 & y==2012
drop if ccode==21 & y<2012
drop if ccode==36 & y>=2006

replace qu1=. if qu1==999
replace qu2=. if qu2==999
replace qu3=. if qu3==999
replace qu4=. if qu4==999
replace qu5=. if qu5==999
replace qu6=. if qu6==999
replace pr1=. if pr1==999
replace pr2=. if pr2==999
replace pr3=. if pr3==999
replace pr4=. if pr4==999
replace pr5=. if pr5==999
replace pr6=. if pr6==999

drop if qu1==. & qu2==. & qu3==. & qu4==. & qu5==. & qu6==.
drop if pr1==. & pr2==. & pr3==. & pr4==. & pr5==. & pr6==.

*getting rid of unbalanced crops
drop if ccode==10 & y<=2004
drop if ccode==14 & y<=2004
drop if ccode==24 & y<=2004
drop if ccode==31 & y<=2005
drop if ccode==35 & y<=2006
drop if ccode==39 & y<=2009
*Sudan missing wheat imports 
drop if ccode==35 & y>=2011

gen exp1 = qu1*pr1
gen exp2 = qu2*pr2
gen exp3 = qu3*pr3
gen exp4 = qu4*pr4
gen exp5 = qu5*pr5
gen exp6 = qu6*pr6

replace exp1 = 0 if exp1==.
replace exp2 = 0 if exp2==.
replace exp3 = 0 if exp3==.
replace exp4 = 0 if exp4==.
replace exp5 = 0 if exp5==.
replace exp6 = 0 if exp6==.

gen exptotal = exp1 + exp2 + exp3 + exp4 + exp5 + exp6

gen share1 = exp1/exptotal
gen share2 = exp2/exptotal
gen share3 = exp3/exptotal
gen share4 = exp4/exptotal
gen share5 = exp5/exptotal
gen share6 = exp6/exptotal

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

gen r2code = rcode

*get means
meanbsNEW

*save means
preserve
clear
matrix AAlpha = J(28,7,0)
matrix AAlpha[1,1] = bA
matrix AAlpha[1,2] = balpha[1..28,1..6]
matrix colnames AAlpha = A Maize Millet Rice Sorghum Teff Wheat
svmat AAlpha, names(col)
save AAlpha, replace
restore

*run bootstrap
simulate A1=e(A1) A2=e(A2) A3=e(A3) A4=e(A4) A5=e(A5) A6=e(A6) A7=e(A7) A8=e(A8) A9=e(A9) A10=e(A10) A11=e(A11) A12=e(A12) A13=e(A13) A14=e(A14) A15=e(A15) A16=e(A16) A17=e(A17) A18=e(A18) A19=e(A19) A20=e(A20) A21=e(A21) A22=e(A22) A23=e(A23) A24=e(A24) A25=e(A25) A26=e(A26) A27=e(A27) A28=e(A28) F11=e(F11) F23=e(F23) F31=e(F31) F33=e(F33) F43=e(F43) F51=e(F51) F52=e(F52) F53=e(F53) F54=e(F54) F61=e(F61) F71=e(F71) F74=e(F74) F84=e(F84) F91=e(F91) F93=e(F93) F94=e(F94) F102=e(F102) F104=e(F104) F112=e(F112) F114=e(F114) F121=e(F121) F123=e(F123) F131=e(F131) F133=e(F133) F141=e(F141) F142=e(F142) F143=e(F143) F144=e(F144) F151=e(F151) F152=e(F152) F153=e(F153) F154=e(F154) F161=e(F161) F163=e(F163) F171=e(F171) F173=e(F173) F181=e(F181) F191=e(F191) F192=e(F192) F193=e(F193) F194=e(F194) F203=e(F203) F211=e(F211) F222=e(F222) F223=e(F223) F224=e(F224) F233=e(F233) F234=e(F234) F241=e(F241) F244=e(F244) F251=e(F251) F252=e(F252) F254=e(F254) F256=e(F256) F261=e(F261) F263=e(F263) F264=e(F264) F271=e(F271) F274=e(F274) F275=e(F275) F276=e(F276) F281=e(F281) F284=e(F284), reps(10000) seed(4926522): doublebsNEW

*get stats
bstat, stat(baseline)

*save results
matrix res1 = e(b)'
matrix res2 = e(se)'
matrix res3 = e(ci_normal)'
matrix resall = (res1, res2, res3)

matrix colnames resall = mean SE lb ub
matrix list resall

clear

svmat resall, names(col)
save BSresults10000NEWKO, replace

