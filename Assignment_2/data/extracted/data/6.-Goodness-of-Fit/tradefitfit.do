clear all
set more off
set mem 240m
set matsize 800

cd "C:/Users/oporteous/Documents/Data/"

use tradefit4c
merge 1:1 countryid using tradefitg4c
gen correct = 0
replace correct = 1 if netex<0 & netexg<0
replace correct = 1 if netex>0 & netexg>0
replace correct = 1 if netex==0 & netexg==0
sum correct
sort netex
corr netex netexg
drop if abs(netex)<100
drop if abs(netexg)<100
sum correct

clear
use tradefit5c
merge 1:1 countrycrop using tradefitg5c
replace netex = 0 if netex==.
replace netexg = 0 if netexg==.
gen correct = 0
replace correct = 1 if netex<0 & netexg<0
replace correct = 1 if netex>0 & netexg>0
replace correct = 1 if netex==0 & netexg==0
sum correct
sort netex
corr netex netexg
drop if abs(netex)<100
drop if abs(netexg)<100
sum correct

clear
use tradefit6c
merge 1:1 countryyear using tradefitg6c
replace netex = 0 if netex==.
replace netexg = 0 if netexg==.
gen correct = 0
replace correct = 1 if netex<0 & netexg<0
replace correct = 1 if netex>0 & netexg>0
replace correct = 1 if netex==0 & netexg==0
sum correct
sort netex
corr netex netexg
drop if abs(netex)<10
drop if abs(netexg)<10
sum correct


clear
use tradefit7c
merge 1:1 countryyearcrop using tradefitg7c
replace netex = 0 if netex==.
replace netexg = 0 if netexg==.
gen correct = 0
replace correct = 1 if netex<0 & netexg<0
replace correct = 1 if netex>0 & netexg>0
replace correct = 1 if netex==0 & netexg==0
sum correct
sort netex
corr netex netexg
drop if abs(netex)<10
drop if abs(netexg)<10
sum correct

