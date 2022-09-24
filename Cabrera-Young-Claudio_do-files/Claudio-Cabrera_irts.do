/*STATA INTERMEDIO
FECHA 14112020*/

cd "C:\Users\c3368\OneDrive\Documentos\pruebas\stata\do_files"
pwd

log using "Claudio-Cabrera_irts.log"

use enaho_2018_100_604_combustible.dta , clear

describe
count 
tabstat Gasolina_604, s(mean)
tab result 

*Variables estructurales
*Area de residencia (estrato)
recode estrato (1/4 5=1) (6/8=2), gen(Area)
label var  Area "Area de residencia"
label def Area 1"Area Urbana" 2"Area Rural"
label value Area Area

*Regiones Naturales (dominio)
recode dominio (1/3 8=1) (4/6=2)(7=3), gen(RN)
label var  RN "Región Natural"
label def RN 1"Costa" 2"Sierra" 3"Selva"
label value RN RN

*Dominio geograficos (Regiones Naturales con Area)
gen DG=1 if Area==1 & RN ==1
replace DG=2 if Area==2 & RN ==1
replace DG=3 if Area==1 & RN ==2
replace DG=4 if Area==2 & RN ==2
replace DG=5 if Area==1 & RN ==3
replace DG=6 if Area==2 & RN ==3
replace DG=7 if dominio==8
label var DG "Dominio Geografico"
label def DG 1"Costa Urbana" 2"Costa Rural" 3"Sierra Urbana" 4"Sierra Rural" 5"Selva Urbana" 6"Selva Rural" 7"Lima Metropolitana"
label value DG DG

*Crear Departamento
gen str2 dpto=substr(ubigeo,1,2)
destring dpto, replace
label var dpto "Departamento"
label define dpto  1 "AMAZONAS" 2 "ANCASH" 3 "APURIMAC" 4 "AREQUIPA" 5 "AYACUCHO" 6 "CAJAMARCA" 7 "CALLAO" ///
8 "CUSCO" 9 "HUANCAVELICA" 10 "HUANUCO" 11 "ICA"	12 "JUNIN" 13 "LA LIBERTAD" 14 "LAMBAYEQUE" 15 "LIMA" 16 "LORETO"  ///
17 "MADRE DE DIOS" 18 "MOQUEGUA" 19 "PASCO" 20 "PIURA" 21 "PUNO" 22 "SAN MARTIN" 23 "TACNA" 24 "TUMBES" 25 "UCAYALI"
label value dpto dpto

*Crear trimestre

gen mes_1=mes
destring mes_1,replace
recode mes_1 (1/3=1)(4/6=2)(7/9=3)(10/12=4),gen(trimestre)
label var trimestre "Trimestral"
label define trimestre 1"1-Trimestre" 2"2-Trimestre" 3"3-Trimestre" 4"4-Trimestre"
label value trimestre trimestre


use enaho_2018_100_604_combustible.dta , clear

list p1172_09 p1173_09 p1174_09 in 1/10
*p1171_09 y p1175_09 son variables cualitativas
bro hogar p1172_09 p1173_09 p1174_09
drop gas_petroleo_t
egen gas_petroleo_t=rowtotal (p1172_09 p1173_09 p1174_09)
tabstat gas_petroleo_t [aw=factor07], s(mean) by (dpto)

save enaho_2018_100_604_combustible.dta, replace

*La base en transportes y comunicaciones

use enaho01-2018-604.dta, clear
count
sort conglome vivienda hogar
tab p604n
label list p604n
keep if p604n==2
sort conglome vivienda hogar
count
save enaho_604_petroleo_2018.dta, replace

list p604b p604c2 p604c3 p604c4 p604c5 p604c6 p604c7 in 30/50

bro p604n p604b p604c2 p604c3 p604c4 p604c5 p604c6 p604c7

egen suma_p604_petroleo=rowtotal(p604b p604c2 p604c3 p604c4 p604c5 p604c6 p604c7)
list p604b p604c2 p604c3 p604c4 p604c5 p604c6 p604c7 suma_p604_petroleo in 100/150

*variables imputadas
egen suma_i604_petroleo=rowtotal(i604b i604c2 i604c3 i604c4 i604c5 i604c6 i604c7)
list i604b i604c2 i604c3 i604c4 i604c5 i604c6 i604c7 suma_i604_petroleo in 100/150

gen petroleo_604=suma_i604_petroleo+suma_i604_petroleo
list petroleo_604 suma_i604_petroleo suma_i604_petroleo in 100/150

sort conglome vivienda hogar 
collapse (sum)petroleo_604, by (conglome vivienda hogar)
save enaho_604_petroleo_2018.dta, replace

*Fusionar con la base del enaho_2018_100_604_combustible

use enaho_2018_100_604_combustible.dta , clear
sort conglome vivienda hogar
merge 1:1 conglome vivienda hogar using enaho_604_petroleo_2018.dta
drop _merge

egen petroleo_total=rowtotal(petroleo_604 gas_petroleo_t)

tabstat petroleo_total, s(mean) by(dpto)
tabstat petroleo_total [aw=factor07], s(mean) by(dpto)

*Sumar los gastos de gasolina y petroleo
drop Gas_Combustible
gen Gas_Combustible=gasolina_total+petroleo_total

tabstat Gas_Combustible, s(mean) by (dpto)

bro gas_gasolina_t Gasolina_604 gasolina_total gas_petroleo_t petroleo_604 petroleo_total Gas_Combustible

tabstat Gas_Combustible, s(mean) by(dpto)
tabstat Gas_Combustible [aw=factor07], s(mean) by (dpto)

save enaho_2018_100_604_combustible.dta , replace

*Ahora vamos a agregarle la sumaria
use sumaria-2018.dta, clear
sort conglome vivienda hogar
save sumaria-2018.dta, replace

use enaho_2018_100_604_combustible.dta , clear
sort conglome vivienda hogar
merge 1:1 conglome vivienda hogar using sumaria-2018.dta
drop _merge

*Calcular el gasto e ingreso real percapital mensual 

drop grpm irpm
gen grpm=gashog2d/(12*ld*mieperho)
gen irpm=inghog1d/(12*ld*mieperho)
drop facpob
gen facpob=factor07*mieperho

tabstat grpm [aw=facpob], s(mean) by(RN)

*Deciles
xtile deciles_grpm=grpm[aw=facpob], nq(10)
tabstat grpm [aw=facpob], s(mean) by (deciles)

/*Pruebas de normalidad: veamos como se comporta nuestra base de combustible: variaciones deben ser iguales, las variaciones constantes, errores no correlacionados*/

sum grpm, detail 

*Pruebas de normalidad para grpm
sktest grpm
* p value es menos que el 0.5. rechazamos la hipotesis nula
swilk grpm
sfrancia grpm
* no se cumplen las pruebas de normalidad
sktest grpm
histogram grpm, normal 
kdensity grpm, normal 

*Pruebas de normalida para gasto de combustible 
sktest Gas_Combustible
swilk Gas_Combustible
sfrancia Gas_Combustible
sktest Gas_Combustible
histogram Gas_Combustible, normal 
kdensity Gas_Combustible, normal

*Graficos de disperción del grpm e irpm
scatter grpm irpm
two scatter grpm irpm || lfit grpm irpm 

regress grpm irpm 
predict rstu, rstu 

histogram rstu, normal 
swilk rstu

predict grpm_2 
*al cuadrado 
scatter rstu grpm_2

save enaho_2018_100_604_combustible.dta, replace
*******************************************


*Linealizar las variables grpm e irpm
gen l_grpm=log(grpm)
gen l_irpm=log(irpm)

sktest l_grpm l_irpm
histogram l_grpm, normal
two scatter l_grpm l_irpm || lfit l_grpm l_irpm 

regress l_grpm l_irpm
predict rstu, rstu
histogram rstu, normal 
swilk rstu
save enaho_2018_100_604_combustible.dta, replace

* rstu es la estandarización de los errores 
* Y observada - Y estimada

*Fusionar la base de cap 200 y 300 del jefe del hogar y sumaria

log close









