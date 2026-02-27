clear all
set more off
set mem 1g
set matsize 800

cd "C:/Users/oporteous/Documents/Data/"

use fitcorr.dta
*use fitcorrNOS.dta

drop if month==.

gen ccode = 0
replace ccode = 1 if crop == "Maize"
replace ccode = 2 if crop == "Millet"
replace ccode = 3 if crop == "Rice"
replace ccode = 4 if crop == "Sorghum"
replace ccode = 5 if crop == "Teff"
replace ccode = 6 if crop == "Wheat"

gen mcode = 0
replace mcode = 110 if market == "Gaborone"
replace mcode = 121 if market == "Kalemie"
replace mcode = 122 if market == "Kamina"
replace mcode = 123 if market == "Kolwezi"
replace mcode = 124 if market == "Lubumbashi"
replace mcode = 130 if market == "Maseru"
replace mcode = 140 if market == "Blantyre"
replace mcode = 141 if market == "Karonga"
replace mcode = 142 if market == "Lilongwe"
replace mcode = 143 if market == "Mangochi"
replace mcode = 144 if market == "Mzuzu"
replace mcode = 145 if market == "Beira"
replace mcode = 146 if market == "Chimoio"
replace mcode = 147 if market == "Cuamba"
replace mcode = 148 if market == "Lichinga"
replace mcode = 149 if market == "Maputo"
replace mcode = 150 if market == "Maxixe"
replace mcode = 151 if market == "Milange"
replace mcode = 152 if market == "Nacala"
replace mcode = 153 if market == "Nampula"
replace mcode = 154 if market == "Pemba"
replace mcode = 155 if market == "Quelimane"
replace mcode = 156 if market == "Tete"
replace mcode = 157 if market == "XaiXai"
replace mcode = 160 if market == "KatimaMulilo"
replace mcode = 161 if market == "Oshakati"
replace mcode = 162 if market == "Swakopmund"
replace mcode = 163 if market == "Windhoek"
replace mcode = 165 if market == "Mbabane"
replace mcode = 170 if market == "Iringa"
replace mcode = 171 if market == "Mbeya"
replace mcode = 172 if market == "Mtwara"
replace mcode = 173 if market == "Songea"
replace mcode = 174 if market == "Sumbawanga"
replace mcode = 180 if market == "Chipata"
replace mcode = 181 if market == "Kabwe"
replace mcode = 182 if market == "Kasama"
replace mcode = 183 if market == "Kitwe"
replace mcode = 184 if market == "Livingstone"
replace mcode = 185 if market == "Lusaka"
replace mcode = 186 if market == "Mongu"
replace mcode = 187 if market == "Solwezi"
replace mcode = 190 if market == "Bulawayo"
replace mcode = 191 if market == "Harare"
replace mcode = 192 if market == "Hwange"
replace mcode = 193 if market == "Masvingo"
replace mcode = 194 if market == "Mutare"
replace mcode = 200 if market == "Luanda"
replace mcode = 201 if market == "Bujumbura"
replace mcode = 202 if market == "Gitega"
replace mcode = 203 if market == "Muyinga"
replace mcode = 210 if market == "Bambari"
replace mcode = 211 if market == "Bangassou"
replace mcode = 212 if market == "Bangui"
replace mcode = 213 if market == "Brazzaville"
replace mcode = 214 if market == "Impfondo"
replace mcode = 215 if market == "PointeNoire"
replace mcode = 220 if market == "Bandundu"
replace mcode = 221 if market == "Bukavu"
replace mcode = 222 if market == "Bunia"
replace mcode = 223 if market == "Butembo"
replace mcode = 224 if market == "Gbadolite"
replace mcode = 225 if market == "Goma"
replace mcode = 226 if market == "Isiro"
replace mcode = 227 if market == "Kananga"
replace mcode = 228 if market == "Kikwit"
replace mcode = 229 if market == "Kindu"
replace mcode = 230 if market == "Kinshasa"
replace mcode = 231 if market == "Kisangani"
replace mcode = 232 if market == "Matadi"
replace mcode = 233 if market == "Mbandaka"
replace mcode = 234 if market == "MbujiMayi"
replace mcode = 235 if market == "Tshikapa"
replace mcode = 236 if market == "Uvira"
replace mcode = 237 if market == "Zongo"
replace mcode = 240 if market == "Gode"
replace mcode = 241 if market == "Jijiga"
replace mcode = 242 if market == "Yabelo"
replace mcode = 243 if market == "Eldoret"
replace mcode = 244 if market == "Garissa"
replace mcode = 245 if market == "Kisumu"
replace mcode = 246 if market == "Lodwar"
replace mcode = 247 if market == "Mandera"
replace mcode = 248 if market == "Mombasa"
replace mcode = 249 if market == "Moyale"
replace mcode = 250 if market == "Nairobi"
replace mcode = 251 if market == "Nakuru"
replace mcode = 252 if market == "Wajir"
replace mcode = 260 if market == "Butare"
replace mcode = 261 if market == "Gisenyi"
replace mcode = 262 if market == "Kigali"
replace mcode = 270 if market == "Baidoa"
replace mcode = 271 if market == "Beledweyne"
replace mcode = 273 if market == "Bosaso"
replace mcode = 274 if market == "Galkayo"
replace mcode = 275 if market == "Garoowe"
replace mcode = 276 if market == "Hargeisa"
replace mcode = 277 if market == "Kismayo"
replace mcode = 278 if market == "Mogadishu"
replace mcode = 279 if market == "Juba"
replace mcode = 280 if market == "Arusha"
replace mcode = 281 if market == "Bukoba"
replace mcode = 282 if market == "DaresSalaam"
replace mcode = 283 if market == "Dodoma"
replace mcode = 284 if market == "Kigoma"
replace mcode = 285 if market == "Musoma"
replace mcode = 286 if market == "Mwanza"
replace mcode = 287 if market == "Singida"
replace mcode = 288 if market == "Tabora"
replace mcode = 289 if market == "Tanga"
replace mcode = 290 if market == "Arua"
replace mcode = 291 if market == "Gulu"
replace mcode = 292 if market == "Jinja"
replace mcode = 293 if market == "Kampala"
replace mcode = 294 if market == "Lira"
replace mcode = 295 if market == "Masindi"
replace mcode = 296 if market == "Mbarara"
replace mcode = 301 if market == "Djibouti"
replace mcode = 302 if market == "Asmara"
replace mcode = 303 if market == "Massawa"
replace mcode = 310 if market == "AddisAbaba"
replace mcode = 312 if market == "Awasa"
replace mcode = 313 if market == "BahirDar"
replace mcode = 314 if market == "Dessie"
replace mcode = 315 if market == "DireDawa"
replace mcode = 316 if market == "Gambela"
replace mcode = 317 if market == "Gondar"
replace mcode = 318 if market == "Jimma"
replace mcode = 319 if market == "Mekele"
replace mcode = 320 if market == "Nekemte"
replace mcode = 331 if market == "Bor"
replace mcode = 332 if market == "Malakal"
replace mcode = 333 if market == "Rumbek"
replace mcode = 334 if market == "Wau"
replace mcode = 340 if market == "AdDamazin"
replace mcode = 341 if market == "AlFashir"
replace mcode = 342 if market == "AlQadarif"
replace mcode = 343 if market == "ElGeneina"
replace mcode = 344 if market == "ElObeid"
replace mcode = 345 if market == "Kadugli"
replace mcode = 346 if market == "Kassala"
replace mcode = 347 if market == "Khartoum"
replace mcode = 348 if market == "Kosti"
replace mcode = 349 if market == "Nyala"
replace mcode = 350 if market == "PortSudan"
replace mcode = 401 if market == "Cotonou"
replace mcode = 402 if market == "Malanville"
replace mcode = 403 if market == "Natitingou"
replace mcode = 404 if market == "Parakou"
replace mcode = 405 if market == "BoboDioulasso"
replace mcode = 406 if market == "Dedougou"
replace mcode = 407 if market == "FadaNgourma"
replace mcode = 408 if market == "Ouagadougou"
replace mcode = 410 if market == "Bamenda"
replace mcode = 411 if market == "Douala"
replace mcode = 412 if market == "Garoua"
replace mcode = 413 if market == "Yaounde"
replace mcode = 414 if market == "Abeche"
replace mcode = 415 if market == "Moundou"
replace mcode = 416 if market == "Ndjamena"
replace mcode = 417 if market == "Sarh"
replace mcode = 420 if market == "Abengourou"
replace mcode = 421 if market == "Abidjan"
replace mcode = 422 if market == "Bouake"
replace mcode = 423 if market == "Daloa"
replace mcode = 424 if market == "Man"
replace mcode = 425 if market == "Odienne"
replace mcode = 426 if market == "Libreville"
replace mcode = 427 if market == "Banjul"
replace mcode = 428 if market == "Accra"
replace mcode = 429 if market == "Bolgatanga"
replace mcode = 430 if market == "Ho"
replace mcode = 431 if market == "Kumasi"
replace mcode = 432 if market == "SekondiTakoradi"
replace mcode = 433 if market == "Tamale"
replace mcode = 434 if market == "Wa"
replace mcode = 435 if market == "Conakry"
replace mcode = 436 if market == "Kankan"
replace mcode = 438 if market == "Labe"
replace mcode = 439 if market == "Nzerekore"
replace mcode = 440 if market == "Bissau"
replace mcode = 441 if market == "Gbarnga"
replace mcode = 442 if market == "Monrovia"
replace mcode = 443 if market == "Bamako"
replace mcode = 444 if market == "Gao"
replace mcode = 445 if market == "Kayes"
replace mcode = 446 if market == "Mopti"
replace mcode = 447 if market == "Segou"
replace mcode = 448 if market == "Sikasso"
replace mcode = 449 if market == "AdelBagrou"
replace mcode = 450 if market == "Nouakchott"
replace mcode = 451 if market == "Tintane"
replace mcode = 452 if market == "Agadez"
replace mcode = 453 if market == "Arlit"
replace mcode = 454 if market == "Diffa"
replace mcode = 455 if market == "Maradi"
replace mcode = 456 if market == "Niamey"
replace mcode = 457 if market == "Tahoua"
replace mcode = 458 if market == "Zinder"
replace mcode = 460 if market == "Abuja"
replace mcode = 461 if market == "Akure"
replace mcode = 462 if market == "BeninCity"
replace mcode = 463 if market == "Calabar"
replace mcode = 464 if market == "Enugu"
replace mcode = 465 if market == "Gombe"
replace mcode = 466 if market == "Ibadan"
replace mcode = 467 if market == "Ilorin"
replace mcode = 468 if market == "Jos"
replace mcode = 469 if market == "Kaduna"
replace mcode = 470 if market == "Kano"
replace mcode = 471 if market == "Katsina"
replace mcode = 472 if market == "Lagos"
replace mcode = 473 if market == "Lokoja"
replace mcode = 474 if market == "Maiduguri"
replace mcode = 475 if market == "Makurdi"
replace mcode = 476 if market == "PortHarcourt"
replace mcode = 477 if market == "Sokoto"
replace mcode = 478 if market == "Yola"
replace mcode = 480 if market == "Dakar"
replace mcode = 481 if market == "Kaolack"
replace mcode = 482 if market == "SaintLouis"
replace mcode = 483 if market == "Tambacounda"
replace mcode = 484 if market == "Touba"
replace mcode = 485 if market == "Ziguinchor"
replace mcode = 490 if market == "Bo"
replace mcode = 491 if market == "Freetown"
replace mcode = 492 if market == "Kabala"
replace mcode = 493 if market == "Kara"
replace mcode = 494 if market == "Lome"

gen mccode = mcode*10+ccode
sort mccode
by mccode: egen obs = count(pdat>0)
sort obs

*within-series root mean squared deviation
gen dev2 = (pdat - psim)^2
gen dev3 = sqrt(dev2)
sort mccode
by mccode: egen mcdev3 = mean(dev3)
preserve
contract mccode mcdev3
sum(mcdev3), detail
restore

*dropping 10 market-crops w/ <10 obs => 501 remaining
drop if obs<10

tabulate mccode, gen(mc)

matrix correls = J(501,3,.)
forvalues i = 1(1)501{
preserve
gen keepme = 0
replace keepme = 1 if mc`i'==1
drop if keepme == 0
correlate pdat psim
matrix coco = r(C)
matrix correls[`i',2] = coco[2,1]
sum mccode
matrix correls[`i',1] = r(mean)
sum obs
matrix correls[`i',3] = r(mean)
restore
}

clear

matrix colnames correls = mccode corrcoeff observ

svmat correls, names(col)

save correls, replace

sort corrcoeff
sum(corrcoeff), detail

