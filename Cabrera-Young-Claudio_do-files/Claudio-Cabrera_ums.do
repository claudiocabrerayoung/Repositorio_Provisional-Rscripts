**Scrip 04**



log using "Claudio-Cabrera_ums.log"

**********************************
*******Variables Estructurales****
**********************************

*Crear Area
recode estrato (1/5=1) (6/8=2), gen (area)
label var area "Area de residencia"
label define area 1 "Area Urbana" 2 "Area Rural"
label value area area

*Crear Region Natural
recode dominio (1 2 3 8=1)(4/6=2)(7=3), generate(RNatural)
lab var RNatural "Region Natural"
label define RNatural 1 "Costa" 2 "Sierra" 3 "Selva"
label value RNatural RNatural

*Crear Departamento
gen str2 dpto=substr(ubigeo,1,2)
destring dpto, replace
label var dpto "Departamento"
label define dptos  1 "AMAZONAS" 2 "ANCASH" 3 "APURIMAC" 4 "AREQUIPA" 5 "AYACUCHO" 6 "CAJAMARCA" 7 "CALLAO" ///
8 "CUSCO" 9 "HUANCAVELICA" 10 "HUANUCO" 11 "ICA"	12 "JUNIN" 13 "LA LIBERTAD" 14 "LAMBAYEQUE" 15 "LIMA" 16 "LORETO"  ///
17 "MADRE DE DIOS" 18 "MOQUEGUA" 19 "PASCO" 20 "PIURA" 21 "PUNO" 22 "SAN MARTIN" 23 "TACNA" 24 "TUMBES" 25 "UCAYALI"
label value dpto dptos

*Crear Dominio Geografico
gen Dominio=1 if area==1 & RNatural==1
replace Dominio=2 if area==2 & RNatural==1
replace Dominio=3 if area==1 & RNatural==2
replace Dominio=4 if area==2 & RNatural==2
replace Dominio=5 if area==1 & RNatural==3
replace Dominio=6 if area==2 & RNatural==3 
replace Dominio=7 if dominio==8
lab var Dominio "Dominio GeogrÃ¡ficos"
lab def Dominio 1"Costa Urbana" 2"Costa Rural" 3"Sierra Urbana" 4"Sierra Rural" 5"Selva Urbana" 6"Selva Rural" 7"Lima Metro"
lab val Dominio Dominio

* Crear trimestre
gen mes_1=mes
destring mes_1, replace 
recode mes_1 (1/3=1)(4/6=2)(7/9=3)(10/12=4), generate(trimestre)
lab var trimestre "Trimestral"
label define trimestre 1 "1-trimestre" 2 "2-trimestre" 3 "3-trimestre" 4 "4-trimestre"
label value trimestre trimestre

*Calcular el ingreso y gasto real percapital mensual

gen grpm=gashog2d/(12*ld*mieperho)
gen irpm=inghog1d/(12*ld*mieperho)
gen facpob=factor07*mieperho



describe Pobre p208a irpm p209 mieperho p301a

 tab Pobre [iw=facpob]
 tab Pobre  p207 [iw=facpob]
 tab Pobre  p207 [iw=facpob], nofreq row
 tab p301a Pobre [iw=facpob], nofreq row

 tabstat irpm  [w=facpob], s(mean cv min max iqr) by(Pobre) 

 *Matriz de correlacion 
 
 cor Pobre p208a irpm p209 mieperho p301a [w facpob]
 pwcorr Pobre p208a irpm p209 mieperho p301a [w=facpob], star(0.05)

 logit Pobre irpm p208a mieperho p209 p301a
 
 estat class
 
 *Estimar la probabilidad
predict prob, pr
sort Pobre prob
browse Pobre prob
 
lsens
estat class, cutoff (0.25)

logit Pobre irpm p208a mieperho p209 p301a, or
margins



*+++++++++++++++++++++++++++++++++++

*Intervalos de confianza
ci  means irpm grpm 
ci  means irpm grpm [w=facpob]

*Diferenciado por area
ci  irpm grpm [w=facpob] if area==1
ci  irpm grpm [w=facpob] if area==2
*Diferenciado por pobreza
ci irpm grpm [w=facpob] if pobreza==1
ci irpm grpm [w=facpob] if pobreza==2
ci irpm grpm [w=facpob] if pobreza==3
*Medias de pobre no extremo de area rural
ci irpm grpm [w=facpob] if pobreza==2 & area==2

svyset [pweight = facpob], psu(conglome)strata(estrato)

svy:mean grpm irpm , over(area)
svy:mean grpm irpm , over(RNatural)
svy:mean grpm irpm , over(Dominio)

svy: regress grpm irpm
svy: regress grpm irpm if area==1
svy: regress grpm irpm if area==2

svy: regress grpm irpm if pobreza==1
svy: regress grpm irpm if pobreza==2
svy: regress grpm irpm if pobreza==3

*Una regresion del departamento de Cajamarca, area rural, condicion de pobre extremo
gen str2 dpto_1=substr(ubigeo,1,2)

svy: regress grpm irpm if pobreza==1 & area==2 & dpto_1=="06"
svy: regress grpm irpm if pobreza==1 & area==2 & dpto_1=="21"
svy: regress grpm irpm if pobreza==1 & area==2 & dpto_1=="10"
*Nota: pocos casos de pobreza extrema

*Pobreza monetaria
* Pobre : Pobre extremo, pobre no extremo
* No Pobre: No pobre

recode pobreza (1 2=1)(3=0), generate(Pobre)
lab var Pobre "Pobreza Monetaria"
label define Pobre_1 1 "Pobre" 0 "No Pobre"
label value Pobre Pobre_1
sort conglome vivienda hogar
save "Hogar_pobre_nopobre_2018.dta",replace


/*Medicion de la pobreza

Pobreza - Pobreza monetaria
				Necesidades basicas insatisfechas
				Integrada

*/

********************************************************
***Cálculo de Necesidades Básicas Insatisfechas(NBIs)***
******************************************************** 
clear

********************************************
***********Cálculo de la NBI1***************
***Hogares en viviendas con caracteristicas*
***fisicas inadecuadas**********************
********************************************

use "enaho01-2018-100.dta"
keep if (result==1 | result==2)
tab result
gen XNBI1=((p101 == 6 | p102 == 8 | ((p102 == 5 | p102 == 6 | p102 == 7 | p102 == 9) & p103 == 6)))
replace XNBI1=. if p101==.
tab XNBI1
sort conglome vivienda
collapse (max)XNBI1,by(conglome vivienda)
browse
tab XNBI1
save XNBI1.dta, replace
dir*dta

********************************************
***********Cálculo de la NBI2***************
***Hogares con vivienda hacinada************
********************************************

use "enaho01-2018-100.dta", clear
keep if (result==1 | result==2)
tab result
tab p104
gen tothab=p104
sort conglome vivienda
collapse (sum)tothab,by(conglome vivienda)
browse
save Tothab.dta,replace

*******Total de miembros de la vivienda**********

use "enaho01-2018-200.dta", clear
gen mieperviv =(p204== 1 & p203 ~= 8 & p203 ~= 9)
sort conglome vivienda  
collapse (sum)mieperviv,by(conglome vivienda)
save Mieperviv.dta,replace

*******Total de miembros del hogar***************

use "enaho01-2018-200.dta", clear
gen mieperho =(p204== 1 & p203 ~= 8 & p203 ~= 9)
sort conglome vivienda hogar 
collapse (sum)mieperho,by(conglome vivienda hogar )
save Mieperho,replace

*************Generando NBI2**********************

use "Tothab.dta",clear
merge 1:1 conglome vivienda using Mieperviv
tab _merge
gen XNBI2=((mieperviv/tothab) > 3.4)
sort conglome vivienda
collapse (max)XNBI2, by(conglome vivienda)
save XNBI2.dta, replace
*Este indicador esta calculado a nivel de vivienda

***************************************************
***********Cálculo de la NBI3**********************
***Hogares en viviendas sin desagüe de ningun tipo*
***************************************************

use "enaho01-2018-100.dta", clear
keep if (result==1 | result==2)
tab1 result p111,nola
gen XNBI3= (p111==6 | p111==8)
sort conglome vivienda hogar
collapse (max)XNBI3, by(conglome vivienda hogar)
save XNBI3.dta, replace
*Este indicador esta a nivel de hogar

*************************************************
***********Cálculo de la NBI4********************
***Hogares con niños que no asisten a la escuela*
*************************************************

use "enaho01a-2018-300.dta", clear

gen XNBI4 =((p208a  >= 6 & p208a <= 12) & (p203 == 1 | p203 == 3 | p203 == 5 | p203 == 7) & p303==2) if (mes >="01" & mes <="03")
replace XNBI4 = p208a >= 6 & p208a <= 12 & (p203 == 1 | p203 == 3 | p203 == 5 | p203 == 7) & (p306 == 2 | (p306 == 1 & p307 == 2)) if (mes >="04" & mes <="12")
sort conglome vivienda hogar 
collapse (max)XNBI4, by(conglome vivienda hogar)
save XNBI4.dta, replace
*Este archivo esta a nivel de hogar


**************************************************
***********Cálculo de la NBI5*********************
***Hogares con alta dependencia economica*********
**************************************************

use "enaho01a-2018-300.dta",clear
gen edujef = (((p301a == 1 | p301a == 2) | (p301a == 3 & (p301b == 0 | p301b == 1 | p301b == 2)) | (p301a == 3  /// 
& (p301c == 1 | p301c == 2 | p301c == 3))) & p203==1 ) 
sort conglome vivienda hogar
collapse (max)edujef, by(conglome vivienda hogar)
save edujef.dta, replace

*******Abrimos el cap-500****************************

use "enaho01a-2018-500.dta",clear
encode p500i, gen (p500inum) 
/*Convertimos la variable p500i a numérica: p500inum*/
format p500inum %8.0g
gen ocu= (p500inum>0 & ocu500 == 1 & p204 == 1  & p203 ~= 8 & p203 ~=9)
sort conglome vivienda hogar
collapse (sum)ocu, by(conglome vivienda hogar)
save ocu.dta, replace

use "enaho01-2018-100.dta", clear
keep if (result==1 | result==2)
merge 1:1 conglome vivienda hogar using ocu
drop _merge
merge 1:1 conglome vivienda hogar using edujef
drop _merge
merge 1:1 conglome vivienda  hogar using Mieperho
drop _merge
gen dep=mieperho if ocu==0
replace dep=(mieperho-ocu)/ocu if ocu > 0
gen XNBI5=(edujef == 1 & dep > 3)
sort conglome vivienda hogar
collapse (max)XNBI5, by(conglome vivienda hogar)
save XNBI5.dta, replace


*++++++ continura....

**********************************************************
********************PEGAR LOS NBIs************************
**********************************************************

use "enaho01-2018-100.dta", clear
keep if (result==1 | result==2)
merge m:1 conglome vivienda using XNBI1
drop _merge
merge m:1 conglome vivienda using XNBI2
drop _merge
merge 1:1 conglome vivienda hogar using XNBI3
drop _merge
merge 1:1 conglome vivienda hogar using XNBI4
drop _merge
merge 1:1 conglome vivienda hogar using XNBI5
drop _merge
label var XNBI1 "Hogares con Vivienda inadecuada"
label de XNBI1 1 "vivienda inadecuada" 0 "vivienda adecuada"
label values XNBI1 XNBI1
label var XNBI2 "Hogares con Viviendas Hacinadas"
label de XNBI2 1 "vivienda hacinada" 0 "vivienda no hacinada"
label values XNBI2 XNBI2
label var XNBI3 "Hogares con Vivienda sin servcicios higiénicos"
label de XNBI3 1 "vivienda sin servicios higiénicos" 0 "vivienda con servicios higiénicos"
label values XNBI3 XNBI3
label var XNBI4 "Hogares con niños que no asisten a la escuela"
label de XNBI4 1 "hogares con niños que no asisten a la escuela " 0 "hogares con niños que asisten a la escuela"
label values XNBI4 XNBI4
label var XNBI5 "Hogares con alta dependencia económica"
label de XNBI5 1 "hogares con alta dependencia económica" 0 "hogares sin alta dependencia económica"
label values XNBI5 XNBI5
gen N1=nbi1-XNBI1
gen N2=nbi2-XNBI2
gen N3=nbi3-XNBI3
gen N4=nbi4-XNBI4
gen N5=nbi5-XNBI5
tab1 N1 N2 N3 N4 N5
tab1 nbi1 XNBI1 nbi2 XNBI2 nbi3 XNBI3 nbi4 XNBI4 nbi5 XNBI5
/* Finalmente al ver las tabulaciones vemos que no existe diferencia 
entre las NBIs calculadas en Stata(Curso) y las que el INEI publica*/

 *** FALTA CREAR VARIABLE DE POBREZA NBI*******
 
 *******************************************
 *Pobreza monetaria
 *****************************************
 *la probre monetaria se trabaja del ingreso y gasto de al sumaria porque ahi esta la suam degastos de lso hogares de alimento sy servicios
 
*Abrimos la Sumaria 2018
use "sumaria-2017.dta", clear

*Describimos 3 variables importantes en el tema de pobreza
d linpe linea pobreza
*Verificar los datos publicados
sum linpe [iw=factor07]
 /* solo para ver el promedio*/
sum linea [iw=factor07] 
/* solo para ver el promedio*/

*Si deseo los errores muestrales de estos indicadores
*los calculare en el modulo de encuestas de STATA
*svyset PSU [pweight=Variable Ponderacion], strata(Var. estratificacion)
svyset conglome [pw=factor07], strata(estrato)
list linpe linea pobreza in 1/20
svy: mean linpe linea
 
/*Tabulacion a nivel muestral*/
tab pobreza
/*Tabulacion expandida a nivel de hogares*/
tab pobreza [iw=factor07] 

gen facpob=factor07*mieperho

/*Pobreza a nivel de personas*/
tab pobreza [iw=facpob] 
/*Ponemos el factor de personas*/
svyset conglome [pw=facpob], strata(estrato) 
/*Calculamos la proporcion*/
svy: proportion pobreza 
label list pobreza
recode pobreza (1/2=1)(3=2), gen(pobrezat)
lab def pobre 1"Pobre" 2"No Pobre"
lab val pobrezat pobre
svy: proportion pobrezat
*Vamos asumir el calculo de la pobreza como un MAS
svyset [pw=facpob] 
svy: proportion pobrezat
*Vamos asumir el calculo de la pobreza como muestreo por conglomerados
svyset conglome [pw=facpob] 
svy: proportion pobrezat
*Vamos asumir el calculo de la pobreza como muestreo estratificado
svyset [pw=facpob], strata(estrato)
svy: proportion pobreza

*Hogares Pobres segun jefatura de hogar 2014
/*Abrimos el archivo de personas*/

use "enaho01-2017-200.dta",clear
collapse (first) p203 (first) p207, by(conglome vivienda hogar)
save jefes2017.dta,replace
use "sumaria-2017.dta", clear 
merge 1:1 conglome vivienda hogar using jefes2017
recode pobreza (1/2=1)(3=2), gen(pobrezat)
lab def pobre 1"Pobre" 2"No Pobre"
lab val pobrezat pobre
tab pobrezat p207 [iw=factor07], nofreq col
svyset conglome [pw=factor07], strata(estrato)
svy: tabulate pobrezat p207,col
*******************************
*Indicadores FGT
*******************************
gen gpcm=gashog2d/(12*mieperho)
gen facpob=factor07*mieperho
povdeco gpcm[w=facpob], varpl(linea)
*Calculo los FGT para Pobreza Extrema

povdeco gpcm[w=facpob], varpl(linpe) 
clear

*************************************
*Pobreza integrada
*************************************

use "enaho01-2017-100.dta", clear
keep if result==1|result==2
sort conglome vivienda hogar
save ENAHO_100_R_1_2.dta, replace

use "sumaria-2017.dta", clear
sort conglome vivienda hogar
merge 1:1 conglome vivienda hogar using ENAHO_100_R_1_2.dta


****Pobreza por NBI*******
egen SumaNBI=rowtotal(nbi1 nbi2 nbi3 nbi4 nbi5)
tab SumaNBI 
*Creamos la variable de pobreza
recode SumaNBI (0=0)(1=1)(2/5=2),gen(pobreNBI)
lab var pobreNBI "Pobreza - NBI"
lab define pobreNBI 0"No Pobre" 1"Pobre" 2"Pobre Extremo"
lab val pobreNBI pobreNBI

tab pobreNBI

gen pobre_nbi=pobreNBI
recode pobre_nbi (0=0)(1/2=1)
lab define pobre_nbi 0"No Pobre" 1"Pobre"
lab values pobre_nbi pobre_nbi
tab pobre_nbi


****Pobreza monetaria********

gen pob_mon=pobreza
recode pob_mon (1/2=1)(3=0)
lab var pob_mon "Pobreza Monetaria"
lab define monet 0 "NoPobre" 1 "Pobre"
lab values pob_mon monet
tab pob_mon


*Creamos el indicador de pobreza integrado

gen pob_integrado=4 if pob_mon==1 & pobre_nbi==1 /*Pobreza Cronica*/
replace pob_integrado=3 if pob_mon==1 & pobre_nbi==0 /*Pobreza Reciente*/
replace pob_integrado=2 if pob_mon==0 & pobre_nbi==1 /*Pobreza Inercial*/
replace pob_integrado=1 if pob_mon==0 & pobre_nbi==0 /*Integrado Socialmente*/
lab var pob_integrado "Pobreza por el Metodo Integrado"
lab define pob_integrado 1 "Integrado Socialmente" 2 "Pobreza Inercial" 3 "Pobreza Reciente" 4 "Pobreza Cronica"
lab values pob_integrado pob_integrado


