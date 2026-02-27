program meanbsNEW, eclass
version 11

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
scalar A`i' = balphaA[`i',7]
}

forvalues i = 1(1)28{
forvalues j = 1(1)6{
scalar F`i'`j' = balpha[`i',`j']
}
}


matrix baseline = J(1,91,0)
forvalues i = 1(1)28{
matrix baseline[1,`i'] = A`i'
}
matrix baseline[1,29] = F11
matrix baseline[1,30] = F23
matrix baseline[1,31] = F31
matrix baseline[1,32] = F33
matrix baseline[1,33] = F43
matrix baseline[1,34] = F51
matrix baseline[1,35] = F52
matrix baseline[1,36] = F53
matrix baseline[1,37] = F54
matrix baseline[1,38] = F61
matrix baseline[1,39] = F71
matrix baseline[1,40] = F74
matrix baseline[1,41] = F84
matrix baseline[1,42] = F91
matrix baseline[1,43] = F93
matrix baseline[1,44] = F94
matrix baseline[1,45] = F102
matrix baseline[1,46] = F104
matrix baseline[1,47] = F112
matrix baseline[1,48] = F114
matrix baseline[1,49] = F121
matrix baseline[1,50] = F123
matrix baseline[1,51] = F131
matrix baseline[1,52] = F133
matrix baseline[1,53] = F141
matrix baseline[1,54] = F142
matrix baseline[1,55] = F143
matrix baseline[1,56] = F144
matrix baseline[1,57] = F151
matrix baseline[1,58] = F152
matrix baseline[1,59] = F153
matrix baseline[1,60] = F154
matrix baseline[1,61] = F161
matrix baseline[1,62] = F163
matrix baseline[1,63] = F171
matrix baseline[1,64] = F173
matrix baseline[1,65] = F181
matrix baseline[1,66] = F191
matrix baseline[1,67] = F192
matrix baseline[1,68] = F193
matrix baseline[1,69] = F194
matrix baseline[1,70] = F203
matrix baseline[1,71] = F211
matrix baseline[1,72] = F222
matrix baseline[1,73] = F223
matrix baseline[1,74] = F224
matrix baseline[1,75] = F233
matrix baseline[1,76] = F234
matrix baseline[1,77] = F241
matrix baseline[1,78] = F244
matrix baseline[1,79] = F251
matrix baseline[1,80] = F252
matrix baseline[1,81] = F254
matrix baseline[1,82] = F256
matrix baseline[1,83] = F261
matrix baseline[1,84] = F263
matrix baseline[1,85] = F264
matrix baseline[1,86] = F271
matrix baseline[1,87] = F274
matrix baseline[1,88] = F275
matrix baseline[1,89] = F276
matrix baseline[1,90] = F281
matrix baseline[1,91] = F284

drop pweight1-pweight6 qweight1-qweight6 pcomp qcomp Acalc

end
