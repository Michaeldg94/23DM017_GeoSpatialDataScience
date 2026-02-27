$title welfare
$offupper
$onuellist

*Full set of 232 markets including 3 world markets:
Set m markets /Luanda, Cotonou, Malanville, Natitingou, Parakou, Gaborone, BoboDioulasso, Dedougou, FadaNgourma, Ouagadougou, Bujumbura, Gitega, Muyinga, Bamenda, Douala, Garoua, Yaounde, Bambari, Bangassou, Bangui, Abeche, Moundou, Ndjamena, Sarh, Brazzaville, Impfondo, PointeNoire, Abengourou, Abidjan, Bouake, Daloa, Man, Odienne, Bandundu, Bukavu, Bunia, Butembo, Gbadolite, Goma, Isiro, Kalemie, Kamina, Kananga, Kikwit, Kindu, Kinshasa, Kisangani, Kolwezi, Lubumbashi, Matadi, Mbandaka, MbujiMayi, Tshikapa, Uvira, Zongo, Djibouti, Asmara, Massawa, AddisAbaba, Awasa, BahirDar, Dessie, DireDawa, Gambela, Gode, Gondar, Jijiga, Jimma, Mekele, Nekemte, Yabelo, Libreville, Banjul, Accra, Bolgatanga, Ho, Kumasi, SekondiTakoradi, Tamale, Wa, Conakry, Kankan, Labe, Nzerekore, Bissau, Eldoret, Garissa, Kisumu, Lodwar, Mandera, Mombasa, Moyale, Nairobi, Nakuru, Wajir, Maseru, Gbarnga, Monrovia, Blantyre, Karonga, Lilongwe, Mangochi, Mzuzu, Bamako, Gao, Kayes, Mopti, Segou, Sikasso, AdelBagrou, Nouakchott, Tintane, Beira, Chimoio, Cuamba, Lichinga, Maputo, Maxixe, Milange, Nacala, Nampula, Pemba, Quelimane, Tete, XaiXai, KatimaMulilo, Oshakati, Swakopmund, Windhoek, Agadez, Arlit, Diffa, Maradi, Niamey, Tahoua, Zinder, Abuja, Akure, BeninCity, Calabar, Enugu, Gombe, Ibadan, Ilorin, Jos, Kaduna, Kano, Katsina, Lagos, Lokoja, Maiduguri, Makurdi, PortHarcourt, Sokoto, Yola, Butare, Gisenyi, Kigali, Dakar, Kaolack, SaintLouis, Tambacounda, Touba, Ziguinchor, Bo, Freetown, Kabala, Baidoa, Beledweyne, Bosaso, Galkayo, Garoowe, Hargeisa, Kismayo, Mogadishu, Bor, Juba, Malakal, Rumbek, Wau, AdDamazin, AlFashir, AlQadarif, ElGeneina, ElObeid, Kadugli, Kassala, Khartoum, Kosti, Nyala, PortSudan, Mbabane, Arusha, Bukoba, DaresSalaam, Dodoma, Iringa, Kigoma, Mbeya, Mtwara, Musoma, Mwanza, Singida, Songea, Sumbawanga, Tabora, Tanga, Kara, Lome, Arua, Gulu, Jinja, Kampala, Lira, Masindi, Mbarara, Chipata, Kabwe, Kasama, Kitwe, Livingstone, Lusaka, Mongu, Solwezi, Bulawayo, Harare, Hwange, Masvingo, Mutare, Johannesburg, Bangkok, Gulf/;
alias(n,m);

Set c crops /Maize, Millet, Sorghum, Rice, Teff, Wheat/;
alias(d,c);

Set t months /5*136/
    tfirst(t) first period
    tint(t) /17*136/;
tfirst(t) = yes$(ord(t) eq 1);

Parameter s(m,c,t) storage;
Parameter q(m,c,t) consumption;
Parameter p(m,c,t) price;
Parameter tr(m,n,c,t) trade;

Parameter imp_vars(m,c,t), imp_varq(m,c,t), imp_varp(m,c,t), imp_vartr(m,n,c,t);

$call gdxxrw i=resultsALL.xlsx o=imp_vars.gdx par=imp_vars rng="s!a1:ed512" cdim=1 rdim=2
$gdxin imp_vars.gdx
$load imp_vars
s(m,c,t) = imp_vars(m,c,t);

$call gdxxrw i=resultsALL.xlsx o=imp_varq.gdx par=imp_varq rng="q!a1:ed512" cdim=1 rdim=2
$gdxin imp_varq.gdx
$load imp_varq
q(m,c,t) = imp_varq(m,c,t);

$call gdxxrw i=resultsALL.xlsx o=imp_varp.gdx par=imp_varp rng="p!a1:ed512" cdim=1 rdim=2
$gdxin imp_varp.gdx
$load imp_varp
p(m,c,t) = imp_varp(m,c,t);

$call gdxxrw i=resultsALL.xlsx o=imp_vartr.gdx par=imp_vartr rng="tr!a1:ee2000" cdim=1 rdim=3
$gdxin imp_vartr.gdx
$load imp_vartr
tr(m,n,c,t) = imp_vartr(m,n,c,t);

Parameter h(m,c,t) harvest;
Parameter imp_varh(m,c,t);

$call gdxxrw i=realCNH.xlsx o=imp_varh.gdx par=imp_varh rng="H!a1:ed1375" cdim=1 rdim=2
$gdxin imp_varh.gdx
$load imp_varh
h(m,c,t) = imp_varh(m,c,t);

Parameter y(m,t) income;
Parameter imp_vary(m,t);

$call gdxxrw i=YdeMatlab.xlsx o=imp_vary.gdx par=imp_vary rng="Y!a1:ec230" cdim=1 rdim=1
$gdxin imp_vary.gdx
$load imp_vary
y(m,t) = imp_vary(m,t);

Parameter r(m) monthly interest rate;
Parameter k(m) monthly unit storage cost;
Parameter A(m) demand shifter;
Parameter alpha(m,c) demand share for crop c;

set varm / r, k, A /;
set varmc /alpha/;

Parameter imp_varm(m,varm), imp_varmc(m,c);

$call gdxxrw i=in_mkt.xlsx o=imp_varm.gdx par=imp_varm rng="sheet1!b1:e233" cdim=1 rdim=1
$gdxin imp_varm.gdx
$load imp_varm
r(m) = imp_varm(m,"r");
k(m) = imp_varm(m,"k");
A(m) = imp_varm(m,"A");

$call gdxxrw i=in_alpha.xlsx o=imp_varmc.gdx par=imp_varmc rng="sheet1!b1:h233" cdim=1 rdim=1
$gdxin imp_varmc.gdx
$load imp_varmc
alpha(m,c) = imp_varmc(m,c);

Parameter Pop(m,t) population;
Parameter imp_varn(m,t);

$call gdxxrw i=realCNH.xlsx o=imp_varn.gdx par=imp_varn rng="N!a1:ec230" cdim=1 rdim=1
$gdxin imp_varn.gdx
$load imp_varn
Pop(m,t) = imp_varn(m,t);

Parameter tau(m,n) bilateral trade costs;
set varmn / tau /;
Parameter imp_varmn(m,n);

$call gdxxrw i=in_tau2.xlsx o=imp_varmn.gdx par=imp_varmn rng="fromMatlab!b2:hz234" cdim=1 rdim=1
$gdxin imp_varmn.gdx
$load imp_varmn
tau(m,n) = imp_varmn(m,n);

Parameter cr indicator for crop presence in all markets;
cr(m,c)$(alpha(m,c) > 0) = 1;
Parameter afri indicator for a non-world market;
afri(m)$(sum(c,alpha(m,c)) < 2) = 1;
Parameter l all links;
l(m,n,c)$((tau(m,n) < 1000)$((tau(m,n) > 0)$((cr(m,c) = 1)$(cr(n,c)=1)))) = 1;

Scalar epsi price elasticity of demand for calories;
Scalar sigma elasticity of substitution;
set scalarset /eps, sig/;
set scalarhelp /hel/;
Parameter scalarpar(scalarhelp, scalarset);
$call gdxxrw i=in_scalar.xlsx o=scalarpar.gdx par=scalarpar rng="sheet1!a1:c2" cdim=1 rdim=1
$gdxin scalarpar.gdx
$load scalarpar
epsi = scalarpar("hel","eps");
sigma = scalarpar("hel","sig");

**********now manipulate inputted data to get parameters of interest

Parameter tcost(m,t) expenditure on trade costs;
tcost(m,t)$(afri(m)) = sum(n,sum(c,0.5*tau(m,n)*(tr(m,n,c,t)+tr(n,m,c,t))));

Parameter scost(m,t) expenditure on storage costs;
scost(m,t)$(afri(m)) = sum(c,r(m)*s(m,c,t-1)$(not tfirst(t))*(p(m,c,t-1)$(not tfirst(t))+k(m))) + sum(c,k(m)*s(m,c,t));

Parameter agrev(m,t) ag revenue net of storage and trade costs;
agrev(m,t)$(afri(m)) = sum(c,p(m,c,t)*(s(m,c,t-1)$(not tfirst(t)) + h(m,c,t) - s(m,c,t))) - sum(c,r(m)*s(m,c,t-1)$(not tfirst(t))*(p(m,c,t-1)$(not tfirst(t))+k(m))) - sum(c,k(m)*s(m,c,t));

Parameter nprod(m,t) production of numeraire good FINAL;
nprod(m,t)$(afri(m)) = y(m,t) - sum(c,p(m,c,t)*q(m,c,t)) - sum(n,sum(c,p(m,c,t)*(tr(m,n,c,t)-tr(n,m,c,t)))) - sum(n,sum(c,0.5*tau(m,n)*(tr(m,n,c,t)+tr(n,m,c,t))));
Parameter nprod2(m,t) production of numeraire good TOTAL (includes intermediates for storage and trade costs);
nprod2(m,t)$(afri(m)) = y(m,t) - agrev(m,t);

Parameter agcons(m,t) expenditure on grains;
agcons(m,t)$(afri(m)) = sum(c,p(m,c,t)*q(m,c,t));

Parameter agquan(m,t) quantity of grains consumed;
agquan(m,t)$(afri(m)) = sum(c,q(m,c,t));

Parameter qindex(m,t) quantity index of grains;
qindex(m,t)$(afri(m)) = prod(c$cr(m,c),((q(m,c,t)/alpha(m,c)$cr(m,c))**alpha(m,c)$cr(m,c)));

Parameter ncons(m,t) consumption of numeraire good;
ncons(m,t)$(afri(m)) = y(m,t) - agcons(m,t);

Parameter nexp(m,t) net exports of numeraire good;
nexp(m,t)$(afri(m)) = - sum(n,sum(c,p(m,c,t)*(tr(m,n,c,t)-tr(n,m,c,t)))) - sum(n,sum(c,0.5*tau(m,n)*(tr(m,n,c,t)+tr(n,m,c,t))));

Parameter agtrdom(m,t) quantity of grains traded internally;
agtrdom(m,t)$(afri(m)) = sum(n,sum(c,0.5*(tr(m,n,c,t)$(afri(n))+tr(n,m,c,t)$(afri(n)))));

Parameter agtrintl(m,t) quantity of grains traded with world;
agtrintl(m,t)$(afri(m)) = sum(n,sum(c,(tr(m,n,c,t)$(not afri(n))+tr(n,m,c,t)$(not afri(n)))));

Parameter agtrtot(m,t) total quantity of grains traded;
agtrtot(m,t)$(afri(m)) = agtrdom(m,t) + agtrintl(m,t);

Parameter agtrnet(m,t) net quantity of grains traded (net exports);
agtrnet(m,t)$(afri(m)) = sum(n,sum(c,tr(m,n,c,t)-tr(n,m,c,t)));

Parameter pindex(m,t) price index of grains;
pindex(m,t)$(afri(m)) = prod(c,p(m,c,t)**alpha(m,c));

Parameter util(m,t) indirect utility;
util(m,t) = y(m,t)$(afri(m)) - (1/(epsi+1))*A(m)*Pop(m,t)*(pindex(m,t)**(epsi+1));

**********sum (or avg) parameters across time periods and export

Set varname /tcostT, scostT, agrevT, nprodT, agconsT, agquanT, qindexAVG, nconsT, nexpT, agtrdomT, agtrintlT, agtrtotT, agtrnetT, pindexAVG, utilT/;

Parameter tcostTin(m,varname);
tcostTin(m,"tcostT") = sum(t$tint(t),tcost(m,t));

Parameter scostTin(m,varname);
scostTin(m,"scostT") = sum(t$tint(t),scost(m,t));

Parameter agrevTin(m,varname);
agrevTin(m,"agrevT") = sum(t$tint(t),agrev(m,t));

Parameter nprodTin(m,varname);
nprodTin(m,"nprodT") = sum(t$tint(t),nprod(m,t));

Parameter agconsTin(m,varname);
agconsTin(m,"agconsT") = sum(t$tint(t),agcons(m,t));

Parameter agquanTin(m,varname);
agquanTin(m,"agquanT") = sum(t$tint(t),agquan(m,t));

Parameter qindexAVGin(m,varname);
qindexAVGin(m,"qindexAVG") = sum(t$tint(t),qindex(m,t))/120;

Parameter nconsTin(m,varname);
nconsTin(m,"nconsT") = sum(t$tint(t),ncons(m,t));

Parameter nexpTin(m,varname);
nexpTin(m,"nexpT") = sum(t$tint(t),nexp(m,t));

Parameter agtrdomTin(m,varname);
agtrdomTin(m,"agtrdomT") = sum(t$tint(t),agtrdom(m,t));

Parameter agtrintlTin(m,varname);
agtrintlTin(m,"agtrintlT") = sum(t$tint(t),agtrintl(m,t));

Parameter agtrtotTin(m,varname);
agtrtotTin(m,"agtrtotT") = sum(t$tint(t),agtrtot(m,t));

Parameter agtrnetTin(m,varname);
agtrnetTin(m,"agtrnetT") = sum(t$tint(t),agtrnet(m,t));

Parameter pindexAVGin(m,varname);
pindexAVGin(m,"pindexAVG") = sum(t$tint(t),pindex(m,t))/120;

Parameter utilTin(m,varname);
utilTin(m,"utilT") = sum(t$tint(t),util(m,t));

**********help for zeros
Parameter zerotcost(m,varname);
zerotcost(m,"tcostT")$(not tcostTin(m,"tcostT")) = 1;
tcostTin(m,"tcostT")$(zerotcost(m,"tcostT")$(afri(m))) = 0.001;
Parameter zeroscost(m,varname);
zeroscost(m,"scostT")$(not scostTin(m,"scostT")) = 1;
scostTin(m,"scostT")$(zeroscost(m,"scostT")$(afri(m))) = 0.001;
Parameter zeroagrev(m,varname);
zeroagrev(m,"agrevT")$(not agrevTin(m,"agrevT")) = 1;
agrevTin(m,"agrevT")$(zeroagrev(m,"agrevT")$(afri(m))) = 0.001;
Parameter zeronexp(m,varname);
zeronexp(m,"nexpT")$(not nexpTin(m,"nexpT")) = 1;
nexpTin(m,"nexpT")$(zeronexp(m,"nexpT")$(afri(m))) = 0.001;
Parameter zeroagtr1(m,varname);
zeroagtr1(m,"agtrdomT")$(not agtrdomTin(m,"agtrdomT")) = 1;
agtrdomTin(m,"agtrdomT")$(zeroagtr1(m,"agtrdomT")$(afri(m))) = 0.001;
Parameter zeroagtr2(m,varname);
zeroagtr2(m,"agtrintlT")$(not agtrintlTin(m,"agtrintlT")) = 1;
agtrintlTin(m,"agtrintlT")$(zeroagtr2(m,"agtrintlT")$(afri(m))) = 0.001;
Parameter zeroagtr3(m,varname);
zeroagtr3(m,"agtrtotT")$(not agtrtotTin(m,"agtrtotT")) = 1;
agtrtotTin(m,"agtrtotT")$(zeroagtr3(m,"agtrtotT")$(afri(m))) = 0.001;
Parameter zeroagtr4(m,varname);
zeroagtr4(m,"agtrnetT")$(not agtrnetTin(m,"agtrnetT")) = 1;
agtrnetTin(m,"agtrnetT")$(zeroagtr4(m,"agtrnetT")$(afri(m))) = 0.001;

***********export summed parameters

execute_unload "welfare" tcostTin scostTin agrevTin nprodTin agconsTin agquanTin qindexAVGin nconsTin nexpTin agtrdomTin agtrintlTin agtrtotTin agtrnetTin pindexAVGin utilTin;
execute 'gdxxrw.exe welfare.gdx o=welfare.xlsx par=utilTin rng=ac!o1:p230 cdim=1 rdim=1'
execute 'gdxxrw.exe welfare.gdx o=welfare.xlsx par=pindexAVGin rng=ac!n1:o230 cdim=1 rdim=1'
execute 'gdxxrw.exe welfare.gdx o=welfare.xlsx par=agtrnetTin rng=ac!m1:n230 cdim=1 rdim=1'
execute 'gdxxrw.exe welfare.gdx o=welfare.xlsx par=agtrtotTin rng=ac!l1:m230 cdim=1 rdim=1'
execute 'gdxxrw.exe welfare.gdx o=welfare.xlsx par=agtrintlTin rng=ac!k1:l230 cdim=1 rdim=1'
execute 'gdxxrw.exe welfare.gdx o=welfare.xlsx par=agtrdomTin rng=ac!j1:k230 cdim=1 rdim=1'
execute 'gdxxrw.exe welfare.gdx o=welfare.xlsx par=nexpTin rng=ac!i1:j230 cdim=1 rdim=1'
execute 'gdxxrw.exe welfare.gdx o=welfare.xlsx par=nconsTin rng=ac!h1:i230 cdim=1 rdim=1'
execute 'gdxxrw.exe welfare.gdx o=welfare.xlsx par=qindexAVGin rng=ac!g1:h230 cdim=1 rdim=1'
execute 'gdxxrw.exe welfare.gdx o=welfare.xlsx par=agquanTin rng=ac!f1:g230 cdim=1 rdim=1'
execute 'gdxxrw.exe welfare.gdx o=welfare.xlsx par=agconsTin rng=ac!e1:f230 cdim=1 rdim=1'
execute 'gdxxrw.exe welfare.gdx o=welfare.xlsx par=nprodTin rng=ac!d1:e230 cdim=1 rdim=1'
execute 'gdxxrw.exe welfare.gdx o=welfare.xlsx par=agrevTin rng=ac!c1:d230 cdim=1 rdim=1'
execute 'gdxxrw.exe welfare.gdx o=welfare.xlsx par=scostTin rng=ac!b1:c230 cdim=1 rdim=1'
execute 'gdxxrw.exe welfare.gdx o=welfare.xlsx par=tcostTin rng=ac!a1:b230 cdim=1 rdim=1'

***********export nprod for use with counterfactual
execute_unload "nprod" nprod2
execute 'gdxxrw.exe nprod.gdx o=in_nprod.xlsx par=nprod2 rng=Sheet1!a1 cdim=1 rdim=1'
$exit
