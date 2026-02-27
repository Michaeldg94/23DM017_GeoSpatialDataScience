program doublebsNEW, eclass
version 11

preserve

bsample, strata(r2code)

matrix balpha = J(28,6,0)
forvalues i = 1(1)28{
forvalues j = 1(1)6{
mean share`j' if r2code==`i'
matrix mean = e(b)
matrix balpha[`i',`j'] = mean[1,1]
}
}

forvalues j = 1(1)6{
gen pweight`j' = 1
}

forvalues j = 1(1)6{
gen qweight`j' = 1
}

forvalues i = 1(1)28{
forvalues j = 1(1)6{
replace pweight`j' = pr`j'^balpha[`i',`j'] if pr`j'!=. & r2code==`i'
replace qweight`j' = (qu`j'/balpha[`i',`j'])^balpha[`i',`j'] if qu`j'!=. & r2code==`i'
}
}

gen pcomp = pweight1*pweight2*pweight3*pweight4*pweight5*pweight6
gen qcomp = qweight1*qweight2*qweight3*qweight4*qweight5*qweight6

gen Acalc = qcomp/(popn*pcomp^-0.066)
 
matrix bA = J(28,1,0)
forvalues i = 1(1)28{
mean Acalc if rcode==`i'
matrix mean = e(b)
matrix bA[`i',1] = mean[1,1]
}

matrix balphaA = J(28,7,0)
matrix balphaA[1,1] = balpha[1..28,1..6]
matrix balphaA[1,7] = bA

forvalues i = 1(1)28{
ereturn scalar A`i' = balphaA[`i',7]
}

forvalues i = 1(1)28{
forvalues j = 1(1)6{
ereturn scalar F`i'`j' = balpha[`i',`j']
}
}


restore

end
