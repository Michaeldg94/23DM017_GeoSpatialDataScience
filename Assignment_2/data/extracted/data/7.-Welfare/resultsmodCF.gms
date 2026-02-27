$title resultsmodCF
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

$call gdxxrw i=resultsALLcf.xlsx o=imp_vars.gdx par=imp_vars rng="s!a1:ed512" cdim=1 rdim=2
$gdxin imp_vars.gdx
$load imp_vars
s(m,c,t) = imp_vars(m,c,t);

$call gdxxrw i=resultsALLcf.xlsx o=imp_varq.gdx par=imp_varq rng="q!a1:ed512" cdim=1 rdim=2
$gdxin imp_varq.gdx
$load imp_varq
q(m,c,t) = imp_varq(m,c,t);

$call gdxxrw i=resultsALLcf.xlsx o=imp_varp.gdx par=imp_varp rng="p!a1:ed512" cdim=1 rdim=2
$gdxin imp_varp.gdx
$load imp_varp
p(m,c,t) = imp_varp(m,c,t);

$call gdxxrw i=resultsALLcf.xlsx o=imp_vartr.gdx par=imp_vartr rng="tr!a1:ee2000" cdim=1 rdim=3
$gdxin imp_vartr.gdx
$load imp_vartr
tr(m,n,c,t) = imp_vartr(m,n,c,t);

Parameter h(m,c,t) harvest;
Parameter imp_varh(m,c,t);

$call gdxxrw i=realCNH.xlsx o=imp_varh.gdx par=imp_varh rng="H!a1:ed1375" cdim=1 rdim=2
$gdxin imp_varh.gdx
$load imp_varh
h(m,c,t) = imp_varh(m,c,t);

Parameter cr indicator for crop presence;
cr(m,c,t)$(q(m,c,t) > 0) = 1;

Parameter flag zero price flag;
flag(m,c,t)$(cr(m,c,t)$(not p(m,c,t))) = 1;
Parameter flag2 zero price AND trade;
flag2(m,c,t)$(flag(m,c,t)$(sum(n,tr(m,n,c,t))>0)) = 1;
flag2(m,c,t)$(flag(m,c,t)$(sum(n,tr(n,m,c,t))>0)) = 1;
p(m,c,t)$(flag(m,c,t)) = 0.000001;
q(m,c,t)$(flag(m,c,t)) = s(m,c,t-1) + h(m,c,t) - s(m,c,t) - sum(n,tr(m,n,c,t)) + sum(n,tr(n,m,c,t));

execute_unload "resultsmod" p q flag flag2;
execute 'gdxxrw.exe resultsmod.gdx o=resultsALLcf.xlsx par=p rng="p!a1:ed512" cdim=1 rdim=2'
execute 'gdxxrw.exe resultsmod.gdx o=resultsALLcf.xlsx par=q rng="q!a1:ed512" cdim=1 rdim=2'
execute 'gdxxrw.exe resultsmod.gdx o=resultsALLcf.xlsx par=flag rng=flag!a1 cdim=1 rdim=2'
execute 'gdxxrw.exe resultsmod.gdx o=resultsALLcf.xlsx par=flag2 rng=flag2!a1 cdim=1 rdim=2'
