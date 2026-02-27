clear all
set more off
set mem 240m
set matsize 800

cd "C:/Users/oporteous/Documents/Data/"

use AfrGrAll.dta

replace q = q/1000

sort hs6
by hs6: egen hs6tot = total(q)

gen crop = 0
replace crop = 1 if hs6==100510
replace crop = 1 if hs6==100590
replace crop = 2 if hs6==100820
replace crop = 3 if hs6==100610
replace crop = 3 if hs6==100620
replace crop = 3 if hs6==100630
replace crop = 3 if hs6==100640
replace crop = 4 if hs6==100700
replace crop = 6 if hs6==100110
replace crop = 6 if hs6==100190
drop if crop==0

gen oid = 99
replace oid = 1 if i==24
replace oid = 5 if i==108
replace oid = 6 if i==120
replace oid = 7 if i==140
replace oid = 8 if i==148
replace oid = 9 if i==178
replace oid = 11 if i==180
replace oid = 2 if i==204
replace oid = 14 if i==231
replace oid = 13 if i==232
replace oid = 12 if i==262
replace oid = 15 if i==266
replace oid = 16 if i==270
replace oid = 17 if i==288
replace oid = 18 if i==324
replace oid = 10 if i==384
replace oid = 20 if i==404
replace oid = 22 if i==430
replace oid = 23 if i==454
replace oid = 24 if i==466
replace oid = 25 if i==478
replace oid = 26 if i==508
replace oid = 28 if i==562
replace oid = 29 if i==566
replace oid = 19 if i==624
replace oid = 30 if i==646
replace oid = 31 if i==686
replace oid = 32 if i==694
replace oid = 33 if i==706
replace oid = 42 if i==711
replace oid = 41 if i==716
replace oid = 35 if i==736
replace oid = 38 if i==768
replace oid = 39 if i==800
replace oid = 37 if i==834
replace oid = 4 if i==854
replace oid = 40 if i==894
*Remaining 99 are world

gen did = 99
replace did = 1 if j==24
replace did = 5 if j==108
replace did = 6 if j==120
replace did = 7 if j==140
replace did = 8 if j==148
replace did = 9 if j==178
replace did = 11 if j==180
replace did = 2 if j==204
replace did = 14 if j==231
replace did = 13 if j==232
replace did = 12 if j==262
replace did = 15 if j==266
replace did = 16 if j==270
replace did = 17 if j==288
replace did = 18 if j==324
replace did = 10 if j==384
replace did = 20 if j==404
replace did = 22 if j==430
replace did = 23 if j==454
replace did = 24 if j==466
replace did = 25 if j==478
replace did = 26 if j==508
replace did = 28 if j==562
replace did = 29 if j==566
replace did = 19 if j==624
replace did = 30 if j==646
replace did = 31 if j==686
replace did = 32 if j==694
replace did = 33 if j==706
replace did = 42 if j==711
replace did = 41 if j==716
replace did = 35 if j==736
replace did = 38 if j==768
replace did = 39 if j==800
replace did = 37 if j==834
replace did = 4 if j==854
replace did = 40 if j==894
*Remaining 99 are world

*Removing non-covered crops
gen keepcco = 0
gen keepccd = 0
replace keepcco = 1 if oid==1  & crop==1
replace keepcco = 1 if oid==2  & crop==1
replace keepcco = 1 if oid==2  & crop==3
replace keepcco = 1 if oid==2  & crop==4
replace keepcco = 1 if oid==4  & crop==2
replace keepcco = 1 if oid==4  & crop==4
replace keepcco = 1 if oid==5  & crop==1
replace keepcco = 1 if oid==5  & crop==4
replace keepcco = 1 if oid==6  & crop==1
replace keepcco = 1 if oid==6  & crop==3
replace keepcco = 1 if oid==7  & crop==1
replace keepcco = 1 if oid==7  & crop==3
replace keepcco = 1 if oid==8  & crop==1
replace keepcco = 1 if oid==8  & crop==2
replace keepcco = 1 if oid==8  & crop==3
replace keepcco = 1 if oid==8  & crop==4
replace keepcco = 1 if oid==9  & crop==3
replace keepcco = 1 if oid==10 & crop==1
replace keepcco = 1 if oid==10 & crop==3
replace keepcco = 1 if oid==11 & crop==1
replace keepcco = 1 if oid==11 & crop==3
replace keepcco = 1 if oid==12 & crop==3
replace keepcco = 1 if oid==13 & crop==4
replace keepcco = 1 if oid==14 & crop==1
replace keepcco = 1 if oid==14 & crop==4
replace keepcco = 1 if oid==14 & crop==6
replace keepcco = 1 if oid==15 & crop==3
replace keepcco = 1 if oid==16 & crop==1
replace keepcco = 1 if oid==16 & crop==2
replace keepcco = 1 if oid==16 & crop==3
replace keepcco = 1 if oid==16 & crop==4
replace keepcco = 1 if oid==17 & crop==1
replace keepcco = 1 if oid==17 & crop==2
replace keepcco = 1 if oid==17 & crop==3
replace keepcco = 1 if oid==17 & crop==4
replace keepcco = 1 if oid==18 & crop==3
replace keepcco = 1 if oid==19 & crop==1
replace keepcco = 1 if oid==19 & crop==2
replace keepcco = 1 if oid==19 & crop==3
replace keepcco = 1 if oid==19 & crop==4
replace keepcco = 1 if oid==20 & crop==1
replace keepcco = 1 if oid==21 & crop==1
replace keepcco = 1 if oid==22 & crop==3
replace keepcco = 1 if oid==23 & crop==1
replace keepcco = 1 if oid==24 & crop==2
replace keepcco = 1 if oid==24 & crop==3
replace keepcco = 1 if oid==24 & crop==4
replace keepcco = 1 if oid==25 & crop==3
replace keepcco = 1 if oid==25 & crop==4
replace keepcco = 1 if oid==26 & crop==1
replace keepcco = 1 if oid==26 & crop==3
replace keepcco = 1 if oid==27 & crop==1
replace keepcco = 1 if oid==28 & crop==2
replace keepcco = 1 if oid==28 & crop==4
replace keepcco = 1 if oid==29 & crop==1
replace keepcco = 1 if oid==29 & crop==2
replace keepcco = 1 if oid==29 & crop==3
replace keepcco = 1 if oid==29 & crop==4
replace keepcco = 1 if oid==30 & crop==1
replace keepcco = 1 if oid==30 & crop==4
replace keepcco = 1 if oid==31 & crop==1
replace keepcco = 1 if oid==31 & crop==2
replace keepcco = 1 if oid==31 & crop==3
replace keepcco = 1 if oid==31 & crop==4
replace keepcco = 1 if oid==32 & crop==3
replace keepcco = 1 if oid==33 & crop==1
replace keepcco = 1 if oid==33 & crop==4
replace keepcco = 1 if oid==35 & crop==1
replace keepcco = 1 if oid==35 & crop==2
replace keepcco = 1 if oid==35 & crop==4
replace keepcco = 1 if oid==35 & crop==6
replace keepcco = 1 if oid==36 & crop==1
replace keepcco = 1 if oid==37 & crop==1
replace keepcco = 1 if oid==37 & crop==3
replace keepcco = 1 if oid==38 & crop==1
replace keepcco = 1 if oid==38 & crop==3
replace keepcco = 1 if oid==38 & crop==4
replace keepcco = 1 if oid==39 & crop==1
replace keepcco = 1 if oid==39 & crop==4
replace keepcco = 1 if oid==40 & crop==1
replace keepcco = 1 if oid==41 & crop==1
replace keepcco = 1 if oid==42 & crop==1
replace keepcco = 1 if oid==99 & crop==1
replace keepcco = 1 if oid==99 & crop==3
replace keepcco = 1 if oid==99 & crop==4
replace keepcco = 1 if oid==99 & crop==6
replace keepccd = 1 if did==1  & crop==1
replace keepccd = 1 if did==2  & crop==1
replace keepccd = 1 if did==2  & crop==3
replace keepccd = 1 if did==2  & crop==4
replace keepccd = 1 if did==4  & crop==2
replace keepccd = 1 if did==4  & crop==4
replace keepccd = 1 if did==5  & crop==1
replace keepccd = 1 if did==5  & crop==4
replace keepccd = 1 if did==6  & crop==1
replace keepccd = 1 if did==6  & crop==3
replace keepccd = 1 if did==7  & crop==1
replace keepccd = 1 if did==7  & crop==3
replace keepccd = 1 if did==8  & crop==1
replace keepccd = 1 if did==8  & crop==2
replace keepccd = 1 if did==8  & crop==3
replace keepccd = 1 if did==8  & crop==4
replace keepccd = 1 if did==9  & crop==3
replace keepccd = 1 if did==10 & crop==1
replace keepccd = 1 if did==10 & crop==3
replace keepccd = 1 if did==11 & crop==1
replace keepccd = 1 if did==11 & crop==3
replace keepccd = 1 if did==12 & crop==3
replace keepccd = 1 if did==13 & crop==4
replace keepccd = 1 if did==14 & crop==1
replace keepccd = 1 if did==14 & crop==4
replace keepccd = 1 if did==14 & crop==6
replace keepccd = 1 if did==15 & crop==3
replace keepccd = 1 if did==16 & crop==1
replace keepccd = 1 if did==16 & crop==2
replace keepccd = 1 if did==16 & crop==3
replace keepccd = 1 if did==16 & crop==4
replace keepccd = 1 if did==17 & crop==1
replace keepccd = 1 if did==17 & crop==2
replace keepccd = 1 if did==17 & crop==3
replace keepccd = 1 if did==17 & crop==4
replace keepccd = 1 if did==18 & crop==3
replace keepccd = 1 if did==19 & crop==1
replace keepccd = 1 if did==19 & crop==2
replace keepccd = 1 if did==19 & crop==3
replace keepccd = 1 if did==19 & crop==4
replace keepccd = 1 if did==20 & crop==1
replace keepccd = 1 if did==21 & crop==1
replace keepccd = 1 if did==22 & crop==3
replace keepccd = 1 if did==23 & crop==1
replace keepccd = 1 if did==24 & crop==2
replace keepccd = 1 if did==24 & crop==3
replace keepccd = 1 if did==24 & crop==4
replace keepccd = 1 if did==25 & crop==3
replace keepccd = 1 if did==25 & crop==4
replace keepccd = 1 if did==26 & crop==1
replace keepccd = 1 if did==26 & crop==3
replace keepccd = 1 if did==27 & crop==1
replace keepccd = 1 if did==28 & crop==2
replace keepccd = 1 if did==28 & crop==4
replace keepccd = 1 if did==29 & crop==1
replace keepccd = 1 if did==29 & crop==2
replace keepccd = 1 if did==29 & crop==3
replace keepccd = 1 if did==29 & crop==4
replace keepccd = 1 if did==30 & crop==1
replace keepccd = 1 if did==30 & crop==4
replace keepccd = 1 if did==31 & crop==1
replace keepccd = 1 if did==31 & crop==2
replace keepccd = 1 if did==31 & crop==3
replace keepccd = 1 if did==31 & crop==4
replace keepccd = 1 if did==32 & crop==3
replace keepccd = 1 if did==33 & crop==1
replace keepccd = 1 if did==33 & crop==4
replace keepccd = 1 if did==35 & crop==1
replace keepccd = 1 if did==35 & crop==2
replace keepccd = 1 if did==35 & crop==4
replace keepccd = 1 if did==35 & crop==6
replace keepccd = 1 if did==36 & crop==1
replace keepccd = 1 if did==37 & crop==1
replace keepccd = 1 if did==37 & crop==3
replace keepccd = 1 if did==38 & crop==1
replace keepccd = 1 if did==38 & crop==3
replace keepccd = 1 if did==38 & crop==4
replace keepccd = 1 if did==39 & crop==1
replace keepccd = 1 if did==39 & crop==4
replace keepccd = 1 if did==40 & crop==1
replace keepccd = 1 if did==41 & crop==1
replace keepcco = 1 if did==42 & crop==1
replace keepcco = 1 if did==99 & crop==1
replace keepcco = 1 if did==99 & crop==3
replace keepcco = 1 if did==99 & crop==4
replace keepcco = 1 if did==99 & crop==6
gen keepcc = keepcco+keepccd
drop if keepcc == 0
drop if keepcco == 0
drop if keepccd == 0

gen year = t-2000
gen ODyearcrop = oid*100000 + did*1000 + year*10 + crop
sort ODyearcrop
by ODyearcrop: egen totTR = total(q)
contract oid did crop t totTR ODyearcrop year
sort ODyearcrop
save tradefit.dta, replace
drop _freq

gen ODcrop = oid*1000 + did*10 + crop
sort ODcrop
by ODcrop: egen totTR2 = total(totTR)
contract oid did crop totTR2 ODcrop
sort ODcrop
save tradefit2.dta, replace
drop _freq

clear
use tradefit2.dta
drop _freq
gen OD = oid*100 + did
sort OD
by OD: egen totTR3 = total(totTR2)
contract oid did totTR3 OD
sort OD
save tradefit3.dta, replace
drop _freq

clear
use tradefit3.dta
drop _freq
sort oid
by oid: egen totTRoid = total(totTR3)
sort did
by did: egen totTRdid = total(totTR3)
save tradefit4a.dta, replace
contract oid totTRoid
gen countryid = oid
save tradefit4b.dta, replace
clear
use tradefit4a.dta
contract did totTRdid
gen countryid = did
merge 1:1 countryid using tradefit4b.dta
drop did _freq oid _merge
replace totTRdid = 0 if totTRdid ==.
replace totTRoid = 0 if totTRoid ==.
gen netex = totTRoid - totTRdid
save tradefit4c.dta, replace

clear
use tradefit2.dta
drop _freq
gen ocrop = oid*10+crop
gen dcrop = did*10+crop
save tradefit5a.dta, replace
sort ocrop
by ocrop: egen totTRocrop = total(totTR2)
contract ocrop totTRocrop
gen countrycrop = ocrop
save tradefit5b.dta, replace
clear
use tradefit5a.dta
sort dcrop 
by dcrop: egen totTRdcrop = total(totTR2)
contract dcrop totTRdcrop
gen countrycrop = dcrop
merge 1:1 countrycrop using tradefit5b.dta
drop _freq _merge
replace totTRdcrop = 0 if totTRdcrop ==.
replace totTRocrop = 0 if totTRocrop ==.
gen netex = totTRocrop - totTRdcrop
save tradefit5c.dta, replace

clear
use tradefit.dta
drop _freq
gen oyear = oid*100+year
gen dyear = did*100+year
save tradefit6a.dta, replace
sort oyear
by oyear: egen totTRoyear = total(totTR)
contract oyear totTRoyear
gen countryyear = oyear
save tradefit6b.dta, replace
clear
use tradefit6a.dta
sort dyear
by dyear: egen totTRdyear = total(totTR)
contract dyear totTRdyear
gen countryyear = dyear
merge 1:1 countryyear using tradefit6b.dta
drop _freq _merge
replace totTRdyear = 0 if totTRdyear==.
replace totTRoyear = 0 if totTRoyear==.
gen netex = totTRoyear - totTRdyear
save tradefit6c.dta, replace

clear
use tradefit.dta
drop _freq
gen oyearcrop = oid*1000+year*10+crop
gen dyearcrop = did*1000+year*10+crop
save tradefit7a.dta, replace
sort oyearcrop
by oyearcrop: egen totTRoyearcrop = total(totTR)
contract oyearcrop totTRoyearcrop
gen countryyearcrop = oyearcrop
save tradefit7b.dta, replace
clear
use tradefit7a.dta
sort dyearcrop
by dyearcrop: egen totTRdyearcrop = total(totTR)
contract dyearcrop totTRdyearcrop
gen countryyearcrop = dyearcrop
merge 1:1 countryyearcrop using tradefit7b.dta
drop _freq _merge
replace totTRdyearcrop = 0 if totTRdyearcrop==.
replace totTRoyearcrop = 0 if totTRoyearcrop==.
gen netex = totTRoyearcrop - totTRdyearcrop
save tradefit7c.dta, replace

