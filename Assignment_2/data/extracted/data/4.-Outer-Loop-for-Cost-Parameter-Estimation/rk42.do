clear all
set more off
set mem 240m
set matsize 800

cd "C:/Users/oporteous/Documents/Data/"

insheet using rknewdematlab.csv
rename v1 mcode
rename v2 gcode
rename v3 y
rename v4 pmin
rename v5 pmax
rename v6 mu

*deletes missing observations
drop if pmin==999
*just in case (should be none)
drop if pmax==999
drop if pmin==pmax
drop if pmin>pmax

gen ccode = 0
replace ccode = 1 if mcode==200
replace ccode = 2 if mcode>=401 & mcode<=404
replace ccode = 3 if mcode==110
replace ccode = 4 if mcode>=405 & mcode<=408
replace ccode = 5 if mcode>=201 & mcode<=203
replace ccode = 6 if mcode>=410 & mcode<=413
replace ccode = 7 if mcode>=210 & mcode<=212
replace ccode = 8 if mcode>=414 & mcode<=417
replace ccode = 9 if mcode>=213 & mcode<=215
replace ccode = 10 if mcode>=420 & mcode<=425
replace ccode = 11 if mcode>=220 & mcode<=237
replace ccode = 11 if mcode>=121 & mcode<=124
replace ccode = 12 if mcode==301
replace ccode = 13 if mcode>=302 & mcode<=303
replace ccode = 14 if mcode>=310 & mcode<=320
replace ccode = 14 if mcode>=240 & mcode<=242
replace ccode = 15 if mcode==426
replace ccode = 16 if mcode==427
replace ccode = 17 if mcode>=428 & mcode<=434
replace ccode = 18 if mcode>=435 & mcode<=439
replace ccode = 19 if mcode==440
replace ccode = 20 if mcode>=243 & mcode<=252
replace ccode = 21 if mcode==130
replace ccode = 22 if mcode>=441 & mcode<=442
replace ccode = 23 if mcode>=140 & mcode<=144
replace ccode = 24 if mcode>=443 & mcode<=448
replace ccode = 25 if mcode>=449 & mcode<=451
replace ccode = 26 if mcode>=145 & mcode<=157
replace ccode = 27 if mcode>=160 & mcode<=163
replace ccode = 28 if mcode>=452 & mcode<=458
replace ccode = 29 if mcode>=460 & mcode<=478
replace ccode = 30 if mcode>=260 & mcode<=262
replace ccode = 31 if mcode>=480 & mcode<=485
replace ccode = 32 if mcode>=490 & mcode<=492
replace ccode = 33 if mcode>=270 & mcode<=278
replace ccode = 34 if mcode==279
replace ccode = 34 if mcode>=331 & mcode<=334
replace ccode = 35 if mcode>=340 & mcode<=350
replace ccode = 36 if mcode==165
replace ccode = 37 if mcode>=280 & mcode<=289
replace ccode = 37 if mcode>=170 & mcode<=174
replace ccode = 38 if mcode>=493 & mcode<=494
replace ccode = 39 if mcode>=290 & mcode<=296
replace ccode = 40 if mcode>=180 & mcode<=187
replace ccode = 41 if mcode>=190 & mcode<=194
tab ccode

gen rgroup=0
replace rgroup = 1 if ccode==3
replace rgroup = 1 if ccode==21
replace rgroup = 1 if ccode==27
replace rgroup = 1 if ccode==36
replace rgroup = 1 if ccode==41
replace rgroup = 1 if ccode==23
replace rgroup = 1 if ccode==26
replace rgroup = 1 if ccode==40
replace rgroup = 2 if ccode==1
replace rgroup = 2 if ccode==11
replace rgroup = 2 if ccode==9
replace rgroup = 2 if ccode==7
replace rgroup = 2 if ccode==34
replace rgroup = 3 if ccode==6
replace rgroup = 3 if ccode==15
replace rgroup = 3 if ccode==29
replace rgroup = 3 if ccode==2
replace rgroup = 3 if ccode==38
replace rgroup = 3 if ccode==17
replace rgroup = 3 if ccode==10
replace rgroup = 3 if ccode==18
replace rgroup = 3 if ccode==22
replace rgroup = 3 if ccode==32
replace rgroup = 4 if ccode==8
replace rgroup = 4 if ccode==28
replace rgroup = 4 if ccode==16
replace rgroup = 4 if ccode==19
replace rgroup = 4 if ccode==31
replace rgroup = 4 if ccode==25
replace rgroup = 4 if ccode==24
replace rgroup = 4 if ccode==4
replace rgroup = 4 if ccode==35
replace rgroup = 5 if ccode==12
replace rgroup = 5 if ccode==13
replace rgroup = 5 if ccode==14
replace rgroup = 5 if ccode==33
replace rgroup = 5 if ccode==20
replace rgroup = 5 if ccode==39
replace rgroup = 5 if ccode==30
replace rgroup = 5 if ccode==5
replace rgroup = 5 if ccode==37

tab rgroup

gen mu11 = 0
replace mu11 = 1 if mu>=11
gen mu10 = 0
replace mu10 = 1 if mu>=10
gen mu9 = 0
replace mu9 = 1 if mu>=9
gen mu8 = 0
replace mu8 = 1 if mu>=8
gen mu7 = 0
replace mu7 = 1 if mu>=7
gen mu6 = 0
replace mu6 = 1 if mu>=6
gen mu5 = 0
replace mu5 = 1 if mu>=5
gen mu4 = 0
replace mu4 = 1 if mu>=4
gen mu3 = 0
replace mu3 = 1 if mu>=3
gen mu2 = 0
replace mu2 = 1 if mu>=2

matrix rkCo = J(5,4,0)
forvalues i = 1(1)5{
preserve
gen keepme = 0
replace keepme = 1 if rgroup==`i'
drop if keepme == 0
nl (pmax = (1+{r})^mu*pmin + ((1+{r})^11*mu11 + (1+{r})^10*mu10 + (1+{r})^9*mu9 + (1+{r})^8*mu8 + (1+{r})^7*mu7 + (1+{r})^6*mu6 + (1+{r})^5*mu5 + (1+{r})^4*mu4 + (1+{r})^3*mu3 + (1+{r})^2*mu2 + (1+{r}))*({k})), vce(bootstrap, reps(10000) seed(4926522) cluster(mcode)) 
matrix bet = e(b)
matrix vet = e(V)
matrix rkCo[`i',1] = bet[1,1]
matrix rkCo[`i',3] = bet[1,2]
matrix rkCo[`i',2] = vet[1,1]^0.5
matrix rkCo[`i',4] = vet[2,2]^0.5
restore
}

clear

matrix colnames rkCo = rmean rSE kmean kSE
svmat rkCo, names(col)
save rkBS10000, replace

outsheet rmean kmean using RK4Matlab.csv, comma nonames replace
