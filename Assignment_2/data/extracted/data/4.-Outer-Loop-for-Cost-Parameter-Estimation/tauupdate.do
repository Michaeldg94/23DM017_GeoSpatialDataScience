clear all
set more off
set mem 500m
set matsize 800

cd "C:/Users/oporteous/Documents/Data/"

insheet using Tau4Matlab.csv
rename v1 mincode
rename v2 maxcode
rename v3 tauprevious

merge 1:1 mincode maxcode using tauBS10000

gen taunew = tauprevious
replace taunew = taubar if taubar > tauprevious
replace taunew = tauprevious if taunew==.
gen changed = 0
replace changed = 1 if taubar > tauprevious
replace changed = 0 if taubar==.
total(changed)

drop mncode _merge
save tauupdate, replace

outsheet mincode maxcode taunew using Tau4Matlab.csv, comma nonames replace
