clear all
set more off
set mem 1g
set matsize 800

cd "C:/Users/oporteous/Documents/Data/"

use fitindex.dta
*use fitindexNOS.dta

drop if month==.

gen zmd=0
replace zmd=10 if pdm<9999 & pdz<9999 & pdz>pdm
replace zmd=5 if pdm<9999 & pdz<9999 & pdz<pdm
gen zrd=0
replace zrd=10 if pdr<9999 & pdz<9999 & pdz>pdr
replace zrd=5 if pdr<9999 & pdz<9999 & pdz<pdr
gen zsd=0
replace zsd=10 if pds<9999 & pdz<9999 & pdz>pds
replace zsd=5 if pds<9999 & pdz<9999 & pdz<pds
gen ztd=0
replace ztd=10 if pdt<9999 & pdz<9999 & pdz>pdt
replace ztd=5 if pdt<9999 & pdz<9999 & pdz<pdt
gen zwd=0
replace zwd=10 if pdw<9999 & pdz<9999 & pdz>pdw
replace zwd=5 if pdw<9999 & pdz<9999 & pdz<pdw
gen mrd=0
replace mrd=10 if pdr<9999 & pdm<9999 & pdm>pdr
replace mrd=5 if pdr<9999 & pdm<9999 & pdm<pdr
gen msd=0
replace msd=10 if pds<9999 & pdm<9999 & pdm>pds
replace msd=5 if pds<9999 & pdm<9999 & pdm<pds
gen mwd=0
replace mwd=10 if pdw<9999 & pdm<9999 & pdm>pdw
replace mwd=5 if pdw<9999 & pdm<9999 & pdm<pdw
gen rsd=0
replace rsd=10 if pds<9999 & pdr<9999 & pdr>pds
replace rsd=5 if pds<9999 & pdr<9999 & pdr<pds
gen std=0
replace std=10 if pdt<9999 & pds<9999 & pds>pdt
replace std=5 if pdt<9999 & pds<9999 & pds<pdt
gen swd=0
replace swd=10 if pdw<9999 & pds<9999 & pds>pdw
replace swd=5 if pdw<9999 & pds<9999 & pds<pdw
gen twd=0
replace twd=10 if pdw<9999 & pdt<9999 & pdt>pdw
replace twd=5 if pdw<9999 & pdt<9999 & pdt<pdw

gen zms=0
replace zms=10 if psm<9999 & psz<9999 & psz>psm
replace zms=5 if psm<9999 & psz<9999 & psz<psm
gen zrs=0
replace zrs=10 if psr<9999 & psz<9999 & psz>psr
replace zrs=5 if psr<9999 & psz<9999 & psz<psr
gen zss=0
replace zss=10 if pss<9999 & psz<9999 & psz>pss
replace zss=5 if pss<9999 & psz<9999 & psz<pss
gen zts=0
replace zts=10 if pst<9999 & psz<9999 & psz>pst
replace zts=5 if pst<9999 & psz<9999 & psz<pst
gen zws=0
replace zws=10 if psw<9999 & psz<9999 & psz>psw
replace zws=5 if psw<9999 & psz<9999 & psz<psw
gen mrs=0
replace mrs=10 if psr<9999 & psm<9999 & psm>psr
replace mrs=5 if psr<9999 & psm<9999 & psm<psr
gen mss=0
replace mss=10 if pss<9999 & psm<9999 & psm>pss
replace mss=5 if pss<9999 & psm<9999 & psm<pss
gen mws=0
replace mws=10 if psw<9999 & psm<9999 & psm>psw
replace mws=5 if psw<9999 & psm<9999 & psm<psw
gen rss=0
replace rss=10 if pss<9999 & psr<9999 & psr>pss
replace rss=5 if pss<9999 & psr<9999 & psr<pss
gen sts=0
replace sts=10 if pst<9999 & pss<9999 & pss>pst
replace sts=5 if pst<9999 & pss<9999 & pss<pst
gen sws=0
replace sws=10 if psw<9999 & pss<9999 & pss>psw
replace sws=5 if psw<9999 & pss<9999 & pss<psw
gen tws=0
replace tws=10 if psw<9999 & pst<9999 & pst>psw
replace tws=5 if psw<9999 & pst<9999 & pst<psw

gen zmc=0
replace zmc = 1 if zmd==zms & zmd>0
replace zmc = -1 if zmd~=zms & zmd>0
gen zrc=0
replace zrc = 1 if zrd==zrs & zrd>0
replace zrc = -1 if zrd~=zrs & zrd>0
gen zsc=0
replace zsc = 1 if zsd==zss & zsd>0
replace zsc = -1 if zsd~=zss & zsd>0
gen ztc=0
replace ztc = 1 if ztd==zts & ztd>0
replace ztc = -1 if ztd~=zts & ztd>0
gen zwc=0
replace zwc = 1 if zwd==zws & zwd>0
replace zwc = -1 if zwd~=zws & zwd>0
gen mrc=0
replace mrc = 1 if mrd==mrs & mrd>0
replace mrc = -1 if mrd~=mrs & mrd>0
gen msc=0
replace msc = 1 if msd==mss & mwd>0
replace msc = -1 if msd~=mss & mwd>0
gen rsc=0
replace rsc = 1 if rsd==rss & rsd>0
replace rsc = -1 if rsd~=rss & rsd>0
gen stc=0
replace stc = 1 if std==sts & std>0
replace stc = -1 if std~=sts & std>0
gen swc=0
replace swc = 1 if swd==sws & swd>0
replace swc = -1 if swd~=sws & swd>0
gen mwc=0
replace mwc = 1 if mwd==mws & mwd>0
replace mwc = -1 if mwd~=mws & mwd>0
gen twc=0
replace twc = 1 if twd==zms & twd>0
replace twc = -1 if twd~=zms & twd>0

tab zmc
tab zrc
tab zsc
tab ztc
tab zwc
tab mrc
tab msc
tab mwc
tab rsc
tab stc
tab swc
tab twc
