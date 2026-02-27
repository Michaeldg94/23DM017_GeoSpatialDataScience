clear all
set more off
set mem 240m
set matsize 800

cd "C:/Users/oporteous/Documents/Data/"

use countryvars4merge.dta
drop if ccode == .
rename ccode ccodem
rename corrupt2013 corrupt2013m
rename lpicustoms2014 lpicustoms2014m
sort ccodem
save countryvars4mergem.dta, replace
clear

use countryvars4merge.dta
drop if ccode == .
rename ccode ccoden
rename corrupt2013 corrupt2013n
rename lpicustoms2014 lpicustoms2014n
sort ccoden
save countryvars4mergen.dta, replace
clear

use tauKOresults.dta

*drop 3 Ethiopian doubles
drop if mncode == 310920
drop if mncode == 314920
drop if mncode == 315920

gen ccodem = 0
replace ccodem = 1 if mincode==200
replace ccodem = 2 if mincode>=401 & mincode<=404
replace ccodem = 3 if mincode==110
replace ccodem = 4 if mincode>=405 & mincode<=408
replace ccodem = 5 if mincode>=201 & mincode<=203
replace ccodem = 6 if mincode>=410 & mincode<=413
replace ccodem = 7 if mincode>=210 & mincode<=212
replace ccodem = 8 if mincode>=414 & mincode<=417
replace ccodem = 9 if mincode>=213 & mincode<=215
replace ccodem = 10 if mincode>=420 & mincode<=425
replace ccodem = 11 if mincode>=220 & mincode<=237
replace ccodem = 11 if mincode>=121 & mincode<=124
replace ccodem = 12 if mincode==301
replace ccodem = 13 if mincode>=302 & mincode<=303
replace ccodem = 14 if mincode>=310 & mincode<=320
replace ccodem = 14 if mincode>=240 & mincode<=242
replace ccodem = 15 if mincode==426
replace ccodem = 16 if mincode==427
replace ccodem = 17 if mincode>=428 & mincode<=434
replace ccodem = 18 if mincode>=435 & mincode<=439
replace ccodem = 19 if mincode==440
replace ccodem = 20 if mincode>=243 & mincode<=252
replace ccodem = 21 if mincode==130
replace ccodem = 22 if mincode>=441 & mincode<=442
replace ccodem = 23 if mincode>=140 & mincode<=144
replace ccodem = 24 if mincode>=443 & mincode<=448
replace ccodem = 25 if mincode>=449 & mincode<=451
replace ccodem = 26 if mincode>=145 & mincode<=157
replace ccodem = 27 if mincode>=160 & mincode<=163
replace ccodem = 28 if mincode>=452 & mincode<=458
replace ccodem = 29 if mincode>=460 & mincode<=478
replace ccodem = 30 if mincode>=260 & mincode<=262
replace ccodem = 31 if mincode>=480 & mincode<=485
replace ccodem = 32 if mincode>=490 & mincode<=492
replace ccodem = 33 if mincode>=270 & mincode<=278
replace ccodem = 34 if mincode==279
replace ccodem = 34 if mincode>=331 & mincode<=334
replace ccodem = 35 if mincode>=340 & mincode<=350
replace ccodem = 36 if mincode==165
replace ccodem = 37 if mincode>=280 & mincode<=289
replace ccodem = 37 if mincode>=170 & mincode<=174
replace ccodem = 38 if mincode>=493 & mincode<=494
replace ccodem = 39 if mincode>=290 & mincode<=296
replace ccodem = 40 if mincode>=180 & mincode<=187
replace ccodem = 41 if mincode>=190 & mincode<=194
tab ccodem

gen ccoden = 0
replace ccoden = 1 if maxcode==200
replace ccoden = 2 if maxcode>=401 & maxcode<=404
replace ccoden = 3 if maxcode==110
replace ccoden = 4 if maxcode>=405 & maxcode<=408
replace ccoden = 5 if maxcode>=201 & maxcode<=203
replace ccoden = 6 if maxcode>=410 & maxcode<=413
replace ccoden = 7 if maxcode>=210 & maxcode<=212
replace ccoden = 8 if maxcode>=414 & maxcode<=417
replace ccoden = 9 if maxcode>=213 & maxcode<=215
replace ccoden = 10 if maxcode>=420 & maxcode<=425
replace ccoden = 11 if maxcode>=220 & maxcode<=237
replace ccoden = 11 if maxcode>=121 & maxcode<=124
replace ccoden = 12 if maxcode==301
replace ccoden = 13 if maxcode>=302 & maxcode<=303
replace ccoden = 14 if maxcode>=310 & maxcode<=320
replace ccoden = 14 if maxcode>=240 & maxcode<=242
replace ccoden = 15 if maxcode==426
replace ccoden = 16 if maxcode==427
replace ccoden = 17 if maxcode>=428 & maxcode<=434
replace ccoden = 18 if maxcode>=435 & maxcode<=439
replace ccoden = 19 if maxcode==440
replace ccoden = 20 if maxcode>=243 & maxcode<=252
replace ccoden = 21 if maxcode==130
replace ccoden = 22 if maxcode>=441 & maxcode<=442
replace ccoden = 23 if maxcode>=140 & maxcode<=144
replace ccoden = 24 if maxcode>=443 & maxcode<=448
replace ccoden = 25 if maxcode>=449 & maxcode<=451
replace ccoden = 26 if maxcode>=145 & maxcode<=157
replace ccoden = 27 if maxcode>=160 & maxcode<=163
replace ccoden = 28 if maxcode>=452 & maxcode<=458
replace ccoden = 29 if maxcode>=460 & maxcode<=478
replace ccoden = 30 if maxcode>=260 & maxcode<=262
replace ccoden = 31 if maxcode>=480 & maxcode<=485
replace ccoden = 32 if maxcode>=490 & maxcode<=492
replace ccoden = 33 if maxcode>=270 & maxcode<=278
replace ccoden = 34 if maxcode==279
replace ccoden = 34 if maxcode>=331 & maxcode<=334
replace ccoden = 35 if maxcode>=340 & maxcode<=350
replace ccoden = 36 if maxcode==165
replace ccoden = 37 if maxcode>=280 & maxcode<=289
replace ccoden = 37 if maxcode>=170 & maxcode<=174
replace ccoden = 38 if maxcode>=493 & maxcode<=494
replace ccoden = 39 if maxcode>=290 & maxcode<=296
replace ccoden = 40 if maxcode>=180 & maxcode<=187
replace ccoden = 41 if maxcode>=190 & maxcode<=194
replace ccoden = 42 if maxcode>=900 & maxcode<=900
tab ccoden

*drop ports
drop if ccoden==0

sort ccodem
merge m:1 ccodem using "countryvars4mergem.dta"
drop if mncode==.
drop _merge
sort ccoden
merge m:1 ccoden using "countryvars4mergen.dta"
drop if mncode==.
drop _merge

gen corruptmn = corrupt2013m + corrupt2013n
gen lpicustomsmn = lpicustoms2014m + lpicustoms2014n

*drop domestic
drop if internatl==0

*generate cluster variable
gen ccodemax = 0
replace ccodemax = ccodem if ccodem>ccoden
replace ccodemax = ccoden if ccoden>ccodem
gen ccodemin = 0
replace ccodemin = ccodem if ccodem<ccoden
replace ccodemin = ccoden if ccoden<ccodem
gen lcode = ccodemax*100+ccodemin
sort lcode

gen fta = 0
replace fta = 1 if nofta==0

reg taubar distance language, cluster(lcode)
reg taubar distance fta, cluster(lcode)
reg taubar distance corruptmn, cluster(lcode)
reg taubar distance lpicustomsmn, cluster(lcode)
reg taubar distance language fta corruptmn lpicustomsmn, cluster(lcode)




