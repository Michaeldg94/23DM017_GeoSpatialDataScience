clear all
set more off
set mem 240m
set matsize 800

cd "C:/Users/oporteous/Documents/Data"

use tradefitgams.dta

gen crop = 0
replace crop = 1 if c == "Maize"
replace crop = 2 if c == "Millet"
replace crop = 3 if c == "Rice"
replace crop = 4 if c == "Sorghum"
replace crop = 6 if c == "Wheat"

gen oid = 0
replace oid=1 if ctrym == "Angola" 
replace oid=2 if ctrym == "Benin" 
replace oid=3 if ctrym == "Botswana" 
replace oid=4 if ctrym == "Burkina" 
replace oid=5 if ctrym == "Burundi" 
replace oid=6 if ctrym == "Cameroon" 
replace oid=7 if ctrym == "CAR" 
replace oid=8 if ctrym == "Chad" 
replace oid=9 if ctrym == "Congo" 
replace oid=10 if ctrym == "CdI" 
replace oid=11 if ctrym == "DRC" 
replace oid=12 if ctrym == "Djibouti" 
replace oid=13 if ctrym == "Eritrea" 
replace oid=14 if ctrym == "Ethiopia" 
replace oid=15 if ctrym == "Gabon" 
replace oid=16 if ctrym == "Gambia" 
replace oid=17 if ctrym == "Ghana" 
replace oid=18 if ctrym == "Guinea" 
replace oid=19 if ctrym == "GB" 
replace oid=20 if ctrym == "Kenya" 
replace oid=21 if ctrym == "Lesotho" 
replace oid=22 if ctrym == "Liberia" 
replace oid=23 if ctrym == "Malawi" 
replace oid=24 if ctrym == "Mali" 
replace oid=25 if ctrym == "Mauritania" 
replace oid=26 if ctrym == "Mozambique" 
replace oid=27 if ctrym == "Namibia" 
replace oid=28 if ctrym == "Niger" 
replace oid=29 if ctrym == "Nigeria" 
replace oid=30 if ctrym == "Rwanda" 
replace oid=31 if ctrym == "Senegal" 
replace oid=32 if ctrym == "SL" 
replace oid=33 if ctrym == "Somalia" 
replace oid=35 if ctrym == "Sudan" 
replace oid=36 if ctrym == "Swaziland" 
replace oid=37 if ctrym == "Tanzania" 
replace oid=38 if ctrym == "Togo" 
replace oid=39 if ctrym == "Uganda" 
replace oid=40 if ctrym == "Zambia" 
replace oid=41 if ctrym == "Zimbabwe"
replace oid=42 if ctrym == "SA" 
replace oid=99 if ctrym == "World"

gen did = 0
replace did=1 if ctryn == "Angola" 
replace did=2 if ctryn == "Benin" 
replace did=3 if ctryn == "Botswana" 
replace did=4 if ctryn == "Burkina" 
replace did=5 if ctryn == "Burundi" 
replace did=6 if ctryn == "Cameroon" 
replace did=7 if ctryn == "CAR" 
replace did=8 if ctryn == "Chad" 
replace did=9 if ctryn == "Congo" 
replace did=10 if ctryn == "CdI" 
replace did=11 if ctryn == "DRC" 
replace did=12 if ctryn == "Djibouti" 
replace did=13 if ctryn == "Eritrea" 
replace did=14 if ctryn == "Ethiopia" 
replace did=15 if ctryn == "Gabon" 
replace did=16 if ctryn == "Gambia" 
replace did=17 if ctryn == "Ghana" 
replace did=18 if ctryn == "Guinea" 
replace did=19 if ctryn == "GB" 
replace did=20 if ctryn == "Kenya" 
replace did=21 if ctryn == "Lesotho" 
replace did=22 if ctryn == "Liberia" 
replace did=23 if ctryn == "Malawi" 
replace did=24 if ctryn == "Mali" 
replace did=25 if ctryn == "Mauritania" 
replace did=26 if ctryn == "Mozambique" 
replace did=27 if ctryn == "Namibia" 
replace did=28 if ctryn == "Niger" 
replace did=29 if ctryn == "Nigeria" 
replace did=30 if ctryn == "Rwanda" 
replace did=31 if ctryn == "Senegal" 
replace did=32 if ctryn == "SL" 
replace did=33 if ctryn == "Somalia" 
replace did=35 if ctryn == "Sudan" 
replace did=36 if ctryn == "Swaziland" 
replace did=37 if ctryn == "Tanzania" 
replace did=38 if ctryn == "Togo" 
replace did=39 if ctryn =="Uganda" 
replace did=40 if ctryn == "Zambia" 
replace did=41 if ctryn == "Zimbabwe"
replace did=42 if ctryn == "SA" 
replace did=99 if ctryn == "World"

gen year = t-2000
*drop for intra-national trade
drop if oid==did
*drop for countries missing trade data (Botsana, Lesotho, Namibia, Swaziland)
drop if oid==3
drop if oid==21
drop if oid==27
drop if oid==36
drop if did==3
drop if did==21
drop if did==27
drop if did==36

gen ODyearcrop = oid*100000 + did*1000 + year*10 + crop
sort ODyearcrop
by ODyearcrop: egen totTR = total(q)
contract oid did crop t totTR ODyearcrop year
sort ODyearcrop
save tradefitg.dta, replace
drop _freq

gen ODcrop = oid*1000 + did*10 + crop
sort ODcrop
by ODcrop: egen totTR2 = total(totTR)
contract oid did crop totTR2 ODcrop
sort ODcrop
save tradefitg2.dta, replace
drop _freq

clear
use tradefitg2.dta
drop _freq
gen OD = oid*100 + did
sort OD
by OD: egen totTR3 = total(totTR2)
contract oid did totTR3 OD
sort OD
save tradefitg3.dta, replace
drop _freq

clear
use tradefitg3.dta
drop _freq
sort oid
by oid: egen totTRoid = total(totTR3)
sort did
by did: egen totTRdid = total(totTR3)
save tradefitg4a.dta, replace
contract oid totTRoid
gen countryid = oid
save tradefitg4b.dta, replace
clear
use tradefitg4a.dta
contract did totTRdid
gen countryid = did
merge 1:1 countryid using tradefitg4b.dta
drop did _freq oid _merge
replace totTRdid = 0 if totTRdid ==.
replace totTRoid = 0 if totTRoid ==.
gen netexg = totTRoid - totTRdid
save tradefitg4c.dta, replace

clear
use tradefitg2.dta
drop _freq
gen ocrop = oid*10+crop
gen dcrop = did*10+crop
save tradefitg5a.dta, replace
sort ocrop
by ocrop: egen totTRocrop = total(totTR2)
contract ocrop totTRocrop
gen countrycrop = ocrop
save tradefitg5b.dta, replace
clear
use tradefitg5a.dta
sort dcrop 
by dcrop: egen totTRdcrop = total(totTR2)
contract dcrop totTRdcrop
gen countrycrop = dcrop
merge 1:1 countrycrop using tradefitg5b.dta
drop _freq _merge
replace totTRdcrop = 0 if totTRdcrop ==.
replace totTRocrop = 0 if totTRocrop ==.
gen netexg = totTRocrop - totTRdcrop
save tradefitg5c.dta, replace

clear
use tradefitg.dta
drop _freq
gen oyear = oid*100+year
gen dyear = did*100+year
save tradefitg6a.dta, replace
sort oyear
by oyear: egen totTRoyear = total(totTR)
contract oyear totTRoyear
gen countryyear = oyear
save tradefitg6b.dta, replace
clear
use tradefitg6a.dta
sort dyear
by dyear: egen totTRdyear = total(totTR)
contract dyear totTRdyear
gen countryyear = dyear
merge 1:1 countryyear using tradefitg6b.dta
drop _freq _merge
replace totTRdyear = 0 if totTRdyear==.
replace totTRoyear = 0 if totTRoyear==.
gen netexg = totTRoyear - totTRdyear
save tradefitg6c.dta, replace

clear
use tradefitg.dta
drop _freq
gen oyearcrop = oid*1000+year*10+crop
gen dyearcrop = did*1000+year*10+crop
save tradefitg7a.dta, replace
sort oyearcrop
by oyearcrop: egen totTRoyearcrop = total(totTR)
contract oyearcrop totTRoyearcrop
gen countryyearcrop = oyearcrop
save tradefitg7b.dta, replace
clear
use tradefitg7a.dta
sort dyearcrop
by dyearcrop: egen totTRdyearcrop = total(totTR)
contract dyearcrop totTRdyearcrop
gen countryyearcrop = dyearcrop
merge 1:1 countryyearcrop using tradefitg7b.dta
drop _freq _merge
replace totTRdyearcrop = 0 if totTRdyearcrop==.
replace totTRoyearcrop = 0 if totTRoyearcrop==.
gen netexg = totTRoyearcrop - totTRdyearcrop
save tradefitg7c.dta, replace

