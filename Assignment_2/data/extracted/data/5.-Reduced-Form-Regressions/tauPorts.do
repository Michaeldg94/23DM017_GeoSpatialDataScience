clear all
set more off
set mem 240m
set matsize 800

cd "C:/Users/oporteous/Documents/Data/"

use tauKOports.dta

gen ccode = 0
replace ccode = 1 if mincode==200
replace ccode = 2 if mincode>=401 & mincode<=404
replace ccode = 3 if mincode==110
replace ccode = 4 if mincode>=405 & mincode<=408
replace ccode = 5 if mincode>=201 & mincode<=203
replace ccode = 6 if mincode>=410 & mincode<=413
replace ccode = 7 if mincode>=210 & mincode<=212
replace ccode = 8 if mincode>=414 & mincode<=417
replace ccode = 9 if mincode>=213 & mincode<=215
replace ccode = 10 if mincode>=420 & mincode<=425
replace ccode = 11 if mincode>=220 & mincode<=237
replace ccode = 11 if mincode>=121 & mincode<=124
replace ccode = 12 if mincode==301
replace ccode = 13 if mincode>=302 & mincode<=303
replace ccode = 14 if mincode>=310 & mincode<=320
replace ccode = 14 if mincode>=240 & mincode<=242
replace ccode = 15 if mincode==426
replace ccode = 16 if mincode==427
replace ccode = 17 if mincode>=428 & mincode<=434
replace ccode = 18 if mincode>=435 & mincode<=439
replace ccode = 19 if mincode==440
replace ccode = 20 if mincode>=243 & mincode<=252
replace ccode = 21 if mincode==130
replace ccode = 22 if mincode>=441 & mincode<=442
replace ccode = 23 if mincode>=140 & mincode<=144
replace ccode = 24 if mincode>=443 & mincode<=448
replace ccode = 25 if mincode>=449 & mincode<=451
replace ccode = 26 if mincode>=145 & mincode<=157
replace ccode = 27 if mincode>=160 & mincode<=163
replace ccode = 28 if mincode>=452 & mincode<=458
replace ccode = 29 if mincode>=460 & mincode<=478
replace ccode = 30 if mincode>=260 & mincode<=262
replace ccode = 31 if mincode>=480 & mincode<=485
replace ccode = 32 if mincode>=490 & mincode<=492
replace ccode = 33 if mincode>=270 & mincode<=278
replace ccode = 34 if mincode==279
replace ccode = 34 if mincode>=331 & mincode<=334
replace ccode = 35 if mincode>=340 & mincode<=350
replace ccode = 36 if mincode==165
replace ccode = 37 if mincode>=280 & mincode<=289
replace ccode = 37 if mincode>=170 & mincode<=174
replace ccode = 38 if mincode>=493 & mincode<=494
replace ccode = 39 if mincode>=290 & mincode<=296
replace ccode = 40 if mincode>=180 & mincode<=187
replace ccode = 41 if mincode>=190 & mincode<=194
tab ccode

sort ccode
merge m:1 ccode using "countryvars4merge.dta"
drop if mncode==.
drop _merge

gen sub500=0
replace sub500=1 if popn1>2

gen usa = 0
replace usa = 1 if maxcode==920
gen thai = 0
replace thai = 1 if maxcode==940
gen trainsusa = 0
replace trainsusa = trains if usa==1
gen trainsthai = 0 
replace trainsthai = trains if thai==1
gen trainsadjusted = trains
replace trainsadjusted = trains*0.5 if usa==1

reg taubar sub500 hivol corrupt2013 gdppercap2010 lpicustoms2014, cluster(ccode)
reg taubar sub500 hivol corrupt2013 gdppercap2010 lpicustoms2014 trains, cluster(ccode)
