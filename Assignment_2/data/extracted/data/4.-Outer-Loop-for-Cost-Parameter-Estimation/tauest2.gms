$title tauest2
$offupper
$onuellist

*Full set of 232 markets including 3 world markets:
Set m markets /Luanda, Cotonou, Malanville, Natitingou, Parakou, Gaborone, BoboDioulasso, Dedougou, FadaNgourma, Ouagadougou, Bujumbura, Gitega, Muyinga, Bamenda, Douala, Garoua, Yaounde, Bambari, Bangassou, Bangui, Abeche, Moundou, Ndjamena, Sarh, Brazzaville, Impfondo, PointeNoire, Abengourou, Abidjan, Bouake, Daloa, Man, Odienne, Bandundu, Bukavu, Bunia, Butembo, Gbadolite, Goma, Isiro, Kalemie, Kamina, Kananga, Kikwit, Kindu, Kinshasa, Kisangani, Kolwezi, Lubumbashi, Matadi, Mbandaka, MbujiMayi, Tshikapa, Uvira, Zongo, Djibouti, Asmara, Massawa, AddisAbaba, Awasa, BahirDar, Dessie, DireDawa, Gambela, Gode, Gondar, Jijiga, Jimma, Mekele, Nekemte, Yabelo, Libreville, Banjul, Accra, Bolgatanga, Ho, Kumasi, SekondiTakoradi, Tamale, Wa, Conakry, Kankan, Labe, Nzerekore, Bissau, Eldoret, Garissa, Kisumu, Lodwar, Mandera, Mombasa, Moyale, Nairobi, Nakuru, Wajir, Maseru, Gbarnga, Monrovia, Blantyre, Karonga, Lilongwe, Mangochi, Mzuzu, Bamako, Gao, Kayes, Mopti, Segou, Sikasso, AdelBagrou, Nouakchott, Tintane, Beira, Chimoio, Cuamba, Lichinga, Maputo, Maxixe, Milange, Nacala, Nampula, Pemba, Quelimane, Tete, XaiXai, KatimaMulilo, Oshakati, Swakopmund, Windhoek, Agadez, Arlit, Diffa, Maradi, Niamey, Tahoua, Zinder, Abuja, Akure, BeninCity, Calabar, Enugu, Gombe, Ibadan, Ilorin, Jos, Kaduna, Kano, Katsina, Lagos, Lokoja, Maiduguri, Makurdi, PortHarcourt, Sokoto, Yola, Butare, Gisenyi, Kigali, Dakar, Kaolack, SaintLouis, Tambacounda, Touba, Ziguinchor, Bo, Freetown, Kabala, Baidoa, Beledweyne, Bosaso, Galkayo, Garoowe, Hargeisa, Kismayo, Mogadishu, Bor, Juba, Malakal, Rumbek, Wau, AdDamazin, AlFashir, AlQadarif, ElGeneina, ElObeid, Kadugli, Kassala, Khartoum, Kosti, Nyala, PortSudan, Mbabane, Arusha, Bukoba, DaresSalaam, Dodoma, Iringa, Kigoma, Mbeya, Mtwara, Musoma, Mwanza, Singida, Songea, Sumbawanga, Tabora, Tanga, Kara, Lome, Arua, Gulu, Jinja, Kampala, Lira, Masindi, Mbarara, Chipata, Kabwe, Kasama, Kitwe, Livingstone, Lusaka, Mongu, Solwezi, Bulawayo, Harare, Hwange, Masvingo, Mutare, Johannesburg, Bangkok, Gulf/;
alias(n,m);

Set c crops /Maize, Millet, Sorghum, Rice, Teff, Wheat/;
alias(d,c);

Set t months /5*136/
    tfirst(t) first period;
tfirst(t) = yes$(ord(t) eq 1);

Parameter tr(m,n,c,t) trade;
Parameter Pdata(m,c,t) price data;

Parameter imp_vartr(m,n,c,t);
$call gdxxrw i=resultsALL.xlsx o=imp_vartr.gdx par=imp_vartr rng="tr!a1:ee1845" cdim=1 rdim=3
$gdxin imp_vartr.gdx
$load imp_vartr
tr(m,n,c,t) = imp_vartr(m,n,c,t);

Parameter imp_varpd(m,c,t);
$call gdxxrw i=PriceMaster4GAMS.xlsx o=imp_varpd.gdx par=imp_varpd rng="Sheet1!c1" cdim=1 rdim=2
$gdxin imp_varpd.gdx
$load imp_varpd
Pdata(m,c,t) = imp_varpd(m,c,t);

Parameter Pd price data excluding zeros;
Pd(m,c,t)$(Pdata(m,c,t)>0) = Pdata(m,c,t);

Parameter Pdm origin price;
Pdm(m,n,c,t) = Pd(m,c,t);

Parameter Pdn destination price;
Pdn(m,n,c,t) = Pd(n,c,t);

set varname /treq, pdatm, pdatn/;
parameter treqin(m,n,c,t,varname), pdatmin(m,n,c,t,varname), pdatnin(m,n,c,t,varname);
treqin(m,n,c,t,"treq") = tr(m,n,c,t);
pdatmin(m,n,c,t,"pdatm")$tr(m,n,c,t) = 999;
pdatmin(m,n,c,t,"pdatm")$(tr(m,n,c,t)$Pdm(m,n,c,t)) = Pdm(m,n,c,t);
pdatnin(m,n,c,t,"pdatn")$tr(m,n,c,t) = 999;
pdatnin(m,n,c,t,"pdatn")$(tr(m,n,c,t)$Pdn(m,n,c,t)) = Pdn(m,n,c,t);

execute_unload "tauest2" treqin pdatmin pdatnin;
execute 'gdxxrw.exe tauest2.gdx o=tauest2.xlsx par=treqin rng=Sheet1!a1 cdim=1 rdim=4'
execute 'gdxxrw.exe tauest2.gdx o=tauest2.xlsx par=pdatmin rng=Sheet1!f1 cdim=1 rdim=4'
execute 'gdxxrw.exe tauest2.gdx o=tauest2.xlsx par=pdatnin rng=Sheet1!k1 cdim=1 rdim=4'
$exit
