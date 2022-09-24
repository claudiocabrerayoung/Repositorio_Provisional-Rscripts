*********************** ACTIVIDADES EN ECONOMÍA 2 ******************************
********************************************************************************

`'

****************************** ASIGNACIÓN 3 ************************************

clear all
global main C:\Users\c3368\OneDrive\Documentos\pruebas\stata\do_files\trabajo_final\consolidado"
global inputs "$main/Base"
global works "$main/Trabajada"
global plots "$main/Graficos"
global map   "$main/Mapas"
global results "$main/Resultados"

* Creación de la base de datos

use "$inputs/enaho01a-2020-300.dta", clear
keep a?o conglome vivienda hogar codperso ubigeo dominio estrato p300a p301a ///
p301d factor07 p301b p301c p302 
save "$works/modulo_educacion.dta", replace 

use "$inputs/enaho01a-2020-500.dta", clear
keep a?o conglome vivienda hogar codperso ubigeo dominio estrato ocu500 p209 ///
p507 p510 p512a i524a1 d529t i530a d536 p506r4 p505r4 p208a p207 p203 fac500a p513t p513a1 d544t i538a1 d540t i541a d543 i520  

merge 1:1 conglome vivienda hogar codperso using "$works/modulo_educacion.dta"

save "$works/base.dta", replace 


keep if _merge==3

drop if p300a== 6
drop if p300a== 7
drop if p300a== 8
drop if p300a== 9
drop if ocu500== .

********************************************************************************
* Crear la variable de ingresos totales
recode p300a ///
(1/3=1 "Originario") ///
(10/15=1 "Originario") ///
(4=2 "Español"), gen(idioma)
label var idioma "Idioma"

* BASE DE AREA
label list estrato
recode estrato ///
(1/5=0 "Urbano") ///
(6/8=1 "Rural"), gen(area)
label var area "Área"

* Pea ocupada
recode ocu500 ///
(1= 0 "PEA Ocupada") ///
(2/3= 1 "PEA desocupada") ///
(4= 3 "Inactivos"), gen(pea)
label var pea "Empleado"

*sexo 
recode p207 (1= 0 "Hombre") (2= 1 "Mujer") , gen(sexo)
label var area "Sexo"

*edad
sort p208a
recode p208a ///
(14/24= 0 "14-24") ///
(25/44= 1 "25-44") ///
(45/64= 2 "45-64") ///
(65/98= 3 "65 a más"), gen(rango_de_edad)
label var rango_de_edad "Rango de edad"

* Edad
rename p208 age
label variable age "Edad"

*lengua materna
label list p300a
recode p300a  ///
(1=2 "Quechua") ///
(2=3 "Aymara") ///
(3=10 "Otra lengua nativa") ///
(4=1 "Castellano") ///
(10=4 "Ashaninka") ///
(11=5 "Awajun") ///
(12=6 "Shipibo") ///
(13=7 "Shawi") ///
(14=8 "Matsigenka") ///
(15=9 "Achuar"), gen(lengua_materna)
label var lengua_materna "Lengua materna"

*nivel educativo
label list p301a
recode p301a ///
(1= 0 "Sin nivel") ///
(2= 1 "Inicial") ///
(3/4= 2 "primaria") ///
( 5/6= 3 "Secundaria") ///
(7/8= 4 "Superior No Universitaria") ///
(9/10= 5 "Superior Universitaria") ///
(11= 6 "Maestria") ///
(12= 7 "Basica Especial"), gen(nivel_educativo)
label var nivel_educativo "Nivel educativo"

*estado civil
recode p209 ///
(1/2=1 "Casado o conviviente") ///
(3/6=3 "Otro"), gen(estado_civil)
label var estado_civil "Estado civil"

label list p209
recode p209 (1/2=1 "Casado_conviviente") (3=3 "Viudo")  (4/5= 2 "Separado_divorciado") (6=0 "Soltero"), gen("estado_civil_general")

*Posición en el hogar
label list p203
recode p203 ///
(0=2 "No jefe de hogar") ///
(1=1 "Jefe de hogar") ///
(2/11= 2 "No jefe de hogar"), gen(posic_hogar)
label var posic_hogar "Posición hogar"

*Categoria ocupacional
label list p507
label var p507 "Categoria ocup"

*Generamos la variable ingreso anual por ocupaciÛn principal
egen ing_ocu_pri=rowtotal(i524a1 d529t i530a d536)

*Generamos la variable ingreso anual por ocupaciÛn secundaria
egen ing_ocu_sec=rowtotal(i538a1 d540t i541a d543)

* Generamos el ingreso laboral anual a partir del ingreso de la ocupaciÛn principal y secundaria
egen ing_lab=rowtotal(ing_ocu_pri ing_ocu_sec)  

/* Generamos la serie de ingresos extraordinarios (gratificaciones, bonos, CTS, etc)
d544t  Ingreso extraordinario (Deflactado)
*/
rename d544t ing_extra

* Generamos la serie de ingreso total mensual 
egen ing_totalA = rowtotal(ing_lab ing_extra) 
gen ing_totalM = ing_totalA/12
br ing_totalA ing_totalM

* Colocamos valores missing si el ingreso laboral es cero o es missing (puede darse un missing en ingreso laboral y un pago de CTS)
replace ing_totalM =. 	if ing_lab==0 | ing_lab==.

* Generamos las horas trabajadas al año a partir de las horas reportadas a la semana
*g horas_m=i520*52
gen horas_m = i520*4

* GENERAMOS EL INGRESO POR HORA
gen ingreso_T = ing_totalM/horas_m
gen ingreso_t = ing_totalM

*replace ingreso_t = 0 if missing(ingreso_t)
label var ingreso_T "Ingreso total por hora"

* Aplicamos logaritmos			
gen ln_ing	= ln(ingreso_t) 										
label var ln_ing "Logaritmo del ingreso total por hora"

*Grupos ocupacionales
recode p510 ///
(1=1 "Fuerzas Armadas, Policía Nacional del Perú") ///
(2=2 "Administración pública") ///
(3=3 "Empresa pública") ///
(5=4 "Empresas especiales de servicios (SERVICE)") ///
(6=5 "Empresa o patrono privado"), gen(grupos_ocupacionales)
label var grupos_ocupacionales "Grupos ocupacionales"

*Actividad economica
gen cod=p506r4
order cod, a(p506r4)
recode p506r4 ///
		(0111/0322= 1 "Agricultura, ganadería, silvicultura y pesca") ///
		(0510/0990= 2 "Explotación de minas y canteras") ///
		(1010/3320= 3 "Industrias manufactureras") ///
		(3510/3530= 4 "Suministro de electricidad, gas, vapor y aire acondicionado") ///
		(3600/3900= 5 " Suministro de agua; evacuación de aguas residuales, gestión de desechos y descontaminación") ///
		(4100/4390= 6 "Construcción") ///
		(4510/4799= 7 "Comercio al por mayor y al por menor; reparación de vehículos automotores y motocicletas") ///
		(4911/5320= 8 "Transporte y almacenamiento") ///
		(5510/5630= 9 "Actividades de alojamiento y de servicio de comidas") ///
		(5811/6399= 10 "Información y comunicaciones") ///
		(6411/6630= 11 "Actividades financieras y de seguros") ///
		(6810/6820= 12 "Actividades inmobiliarias") ///
		(6910/7500= 13 "Actividades profesionales, científicas y técnicas") ///
		(7710/8299= 14 "Actividades de servicios administrativos y de apoyo") ///
		(8411/8430= 15 "Administración pública y defensa; planes de seguridad social de afiliación obligatoria") ///
		(8510/8550= 16 "Enseñanza") ///
		(8610/8890= 17 "Actividades de atención de la salud humana y de asistencia social") ///
		(9000/9329= 18 "Actividades artísticas, de entretenimiento y recreativas") ///
		(9411/9609= 19 "Otras actividades de servicios") ///
		(9700/9820= 20 "Actividades de los hogares como empleadores; actividades no diferenciadas de los hogares como productores de bienes y servicios para uso propio") ///
		(9900= 21 "Actividades de organizaciones y órganos extraterritoriales"), gen(actividad_economica)
label var actividad_economica "Actividad economica"

*Tamaño de empresa
recode p512a ///
(1=1 "1-20 trabajadores") ///
(2=2 "21-50 trabajadores") ///
(3=3 "51-100 trabajadores") ///
(4=4 "101-500 trabajadores") ///
(5=5 "más de 500 trabajadores"), gen(tamaño_de_empresa)
label var tamaño_de_empresa "Tamaño de empresa"

* Crear el indice de los ingresos para Ingreso mujer e Ingreso idioma nativo
egen ing_muj = mean(ing_totalM) if sexo==1
gen ingresos1 = ing_totalM/10.45019 

egen ing_nativo = mean(ing_totalM) if idioma==1
gen ingresos2 = ing_totalM/7.752269

* ingresos para Ingreso varon e Ingreso idioma español
egen ing_varon = mean(ing_totalM) if sexo==0
egen ing_español = mean(ing_totalM) if idioma==2

sum ing_muj ing_nativo ing_varon ing_español

save "$works/base_de_datos.dta", replace
******************** ESTADISTICOS DESCRIPTIVOS GENERALES ***********************

*indicadores PET
tab area pea  [iw=fac500a], row 

*sexo
tab area sexo [iw=fac500a], row 

*Rango de edades
tab area rango_de_edad [iw=fac500a], row

*lengua materna, no idioma materno
tab area lengua_materna [iw=fac500a], row

*Nivel educativo
tab area nivel_educativo  [iw=fac500a], row

*Estado civil
tab area estado_civil_general  [iw=fac500a], row 
 
 
*************** ESTADISTICOS DESCRIPTIVOS POR SEXO Y LENGUA de la PEA OCUPADA ********************
*seleccionamos los datos de la PEA OCUPADA
keep if pea==0
save "$works/pea_Ocupada.dta", replace
use "$works/pea_Ocupada.dta"
* CUADRO 2A: Fila 1 Y 2

table idioma p207 [iw=fac500a], contents(mean ingresos1)
table p207 idioma [iw=fac500a], contents(mean ingresos2)

* CUADRO 2A: Fila 3
table area idioma [iw=fac500a], contents(mean ingresos1)
table area p207 [iw=fac500a], contents(mean ingresos2)

* CUADRO 2A: Fila 4
table rango_de_edad idioma [iw=fac500a], contents(mean ingresos1)
table rango_de_edad p207 [iw=fac500a], contents(mean ingresos2)

* CUADRO 2A: Fila 5
table nivel_educativo idioma [iw=fac500a], contents(mean ingresos1)
table nivel_educativo p207 [iw=fac500a], contents(mean ingresos2)

* CUADRO 2A: Fila 6
* No tenemos una variable propiamente de privado o público

* CUADRO 2A: Fila 7
table estado_civil idioma [iw=fac500a], contents(mean ingresos1)
table estado_civil p207 [iw=fac500a], contents(mean ingresos2)

* CUADRO 2A: Fila 8
table posic_hogar idioma [iw=fac500a], contents(mean ingresos1)
table posic_hogar p207 [iw=fac500a], contents(mean ingresos2)

* CUADRO 2A: Fila 9
table p507 idioma  [iw=fac500a], contents(mean ingresos1)
table p507 p207  [iw=fac500a], contents(mean ingresos2)

*******************************CUADRO 2B*****************************

* CUADRO 2B: Fila 1
table tamaño_de_empresa idioma [iw=fac500a], contents(mean ingresos1)
table tamaño_de_empresa p207 [iw=fac500a], contents(mean ingresos2)

* CUADRO 2B: Fila 2
table actividad_economica idioma [iw=fac500a], contents(mean ingresos1)
table actividad_economica p207 [iw=fac500a], contents(mean ingresos2)

* CUADRO 2B: Fila 3
table grupos_ocupacionales idioma [iw=fac500a], contents(mean ingresos1)
table grupos_ocupacionales p207 [iw=fac500a], contents(mean ingresos2)

*****************************ANALISIS ECONOMETRICO******************************
********************************************************************************

*Ingreso por hora

sum ingreso_t p207 area idioma

************************************3A*****************************************
*Fila 1
sum ingreso_t if sexo==0
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0
sum ingreso_t if sexo==1
display "t de medias entre hombre y mujer "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 2

sum ingreso_t if sexo==0 & idioma==1
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & idioma==1
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & idioma==1
sum ingreso_t if sexo==1 & idioma==1
display "t de medias entre hombre y mujer si hablan idioma originario "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 3

sum ingreso_t if sexo==0 & idioma==2
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & idioma==2
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & idioma==2
sum ingreso_t if sexo==1 & idioma==2
display "t de medias entre hombre y mujer si hablan idioma español "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 4

sum ingreso_t if sexo==0 & area==0
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & area==0
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & area==0
sum ingreso_t if sexo==1 & area==0
display "t de medias entre hombre y mujer en el area urbana "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 5

sum ingreso_t if sexo==0 & area==1
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & area==1
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & area==1
sum ingreso_t if sexo==1 & area==1
display "t de medias entre hombre y mujer en el area rural "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 6

sum ingreso_t if sexo==0 & rango_de_edad==0
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & rango_de_edad==0
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & rango_de_edad==0
sum ingreso_t if sexo==1 & rango_de_edad==0
display "t de medias entre hombre y mujer de 14 a 24 años: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 7

sum ingreso_t if sexo==0 & rango_de_edad==1
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & rango_de_edad==1
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & rango_de_edad==1
sum ingreso_t if sexo==1 & rango_de_edad==1
display "t de medias entre hombre y mujer de 25 a 44 años: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 8

sum ingreso_t if sexo==0 & rango_de_edad==2
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & rango_de_edad==2
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & rango_de_edad==2
sum ingreso_t if sexo==1 & rango_de_edad==2
display "t de medias entre hombre y mujer de 45 a 64 años: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 9

sum ingreso_t if sexo==0 & rango_de_edad==3
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & rango_de_edad==3
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & rango_de_edad==3
sum ingreso_t if sexo==1 & rango_de_edad==3
display "t de medias entre hombre y mujer de 65 años a mas: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 10

sum ingreso_t if sexo==0 & nivel_educativo==0
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & nivel_educativo==0
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & nivel_educativo==0
sum ingreso_t if sexo==1 & nivel_educativo==0
display "t de medias entre hombre y mujer sin nivel educativo: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 11

sum ingreso_t if sexo==0 & nivel_educativo==1
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & nivel_educativo==1
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & nivel_educativo==1
sum ingreso_t if sexo==1 & nivel_educativo==1
display "t de medias entre hombre y mujer con nivel educativo inicial: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 12

sum ingreso_t if sexo==0 & nivel_educativo==2
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & nivel_educativo==2
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & nivel_educativo==2
sum ingreso_t if sexo==1 & nivel_educativo==2
display "t de medias entre hombre y mujer con nivel educativo primaria: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 13

sum ingreso_t if sexo==0 & nivel_educativo==3
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & nivel_educativo==3
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & nivel_educativo==3
sum ingreso_t if sexo==1 & nivel_educativo==3
display "t de medias entre hombre y mujer con nivel educativo secundaria: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 14

sum ingreso_t if sexo==0 & nivel_educativo==4
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & nivel_educativo==4
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & nivel_educativo==4
sum ingreso_t if sexo==1 & nivel_educativo==4
display "t de medias entre hombre y mujer con nivel educativo superior no univ: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 15

sum ingreso_t if sexo==0 & nivel_educativo==5
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & nivel_educativo==5
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & nivel_educativo==5
sum ingreso_t if sexo==1 & nivel_educativo==5
display "t de medias entre hombre y mujer con nivel educativo superior univ: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 16

sum ingreso_t if sexo==0 & nivel_educativo==6
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & nivel_educativo==6
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & nivel_educativo==6
sum ingreso_t if sexo==1 & nivel_educativo==6
display "t de medias entre hombre y mujer con nivel educativo superior maestria: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 17 no se considera

sum ingreso_t if sexo==0 & nivel_educativo==7
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & nivel_educativo==7
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & nivel_educativo==7
sum ingreso_t if sexo==1 & nivel_educativo==7
display "t de medias entre hombre y mujer con nivel educativo basico especial: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 18 no tenemos variable para publico y privado
* Fila 19 no tenemos variable para publico y privado

* Fila 17

sum ingreso_t if sexo==0 & estado_civil==1
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & estado_civil==1
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & estado_civil==1
sum ingreso_t if sexo==1 & estado_civil==1
display "t de medias entre hombre y mujer casado y conviviente: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 22

sum ingreso_t if sexo==0 & estado_civil==3
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & estado_civil==3
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & estado_civil==3
sum ingreso_t if sexo==1 & estado_civil==3
display "t de medias entre hombre y mujer con otro estado civil: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 23

sum ingreso_t if sexo==0 & posic_hogar==1
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & posic_hogar==1
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & posic_hogar==1
sum ingreso_t if sexo==1 & posic_hogar==1
display "t de medias entre hombre y mujer cuando son jefes de hogar: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 24

sum ingreso_t if sexo==0 & posic_hogar==2
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & posic_hogar==2
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & posic_hogar==2
sum ingreso_t if sexo==1 & posic_hogar==2
display "t de medias entre hombre y mujer cuando no son jefes de hogar: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 25

sum ingreso_t if sexo==0 & p507==1
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & p507==1
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & p507==1
sum ingreso_t if sexo==1 & p507==1
display "t de medias entre hombre y mujer cuando son empleadores: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 26

sum ingreso_t if sexo==0 & p507==2
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & p507==2
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & p507==2
sum ingreso_t if sexo==1 & p507==2
display "t de medias entre hombre y mujer cuando son trabajadores: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 27

sum ingreso_t if sexo==0 & p507==3
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & p507==3
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & p507==3
sum ingreso_t if sexo==1 & p507==3
display "t de medias entre hombre y mujer cuando son empleados: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 28

sum ingreso_t if sexo==0 & p507==4
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & p507==4
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & p507==4
sum ingreso_t if sexo==1 & p507==4
display "t de medias entre hombre y mujer cuando son obreros: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 29

sum ingreso_t if sexo==0 & p507==5
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & p507==5
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & p507==5
sum ingreso_t if sexo==1 & p507==5
display "t de medias entre hombre y mujer cuando son trabajador familiar no remunerado: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 30

sum ingreso_t if sexo==0 & p507==6
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & p507==6
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & p507==6
sum ingreso_t if sexo==1 & p507==6
display "t de medias entre hombre y mujer cuando son trabajadores del hogar: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 31

sum ingreso_t if sexo==0 & p507==7
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & p507==7
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & p507==7
sum ingreso_t if sexo==1 & p507==7
display "t de medias entre hombre y mujer cuando son otro: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

*********************************** 3B *****************************************	

* Fila 2

sum ingreso_t if sexo==0 & tamaño_de_empresa==1
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & tamaño_de_empresa==1
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & tamaño_de_empresa==1
sum ingreso_t if sexo==1 & tamaño_de_empresa==1
display "t de medias entre hombre y mujer cuando trabajan con menos de 20 trabajadores: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 3

sum ingreso_t if sexo==0 & tamaño_de_empresa==2
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & tamaño_de_empresa==2
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & tamaño_de_empresa==2
sum ingreso_t if sexo==1 & tamaño_de_empresa==2
display "t de medias entre hombre y mujer cuando trabajan con entre 21 a 50 trabajadores: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 4

sum ingreso_t if sexo==0 & tamaño_de_empresa==3
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & tamaño_de_empresa==3
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & tamaño_de_empresa==3
sum ingreso_t if sexo==1 & tamaño_de_empresa==3
display "t de medias entre hombre y mujer cuando trabajan con entre 51 a 100 trabajadores: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 4

sum ingreso_t if sexo==0 & tamaño_de_empresa==4
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & tamaño_de_empresa==4
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & tamaño_de_empresa==4
sum ingreso_t if sexo==1 & tamaño_de_empresa==4
display "t de medias entre hombre y mujer cuando trabajan con entre 101 a 500 trabajadores: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 5

sum ingreso_t if sexo==0 & tamaño_de_empresa==5
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & tamaño_de_empresa==5
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & tamaño_de_empresa==5
sum ingreso_t if sexo==1 & tamaño_de_empresa==5
display "t de medias entre hombre y mujer cuando trabajan más 500 trabajadores: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 7

sum ingreso_t if sexo==0 & actividad_economica==1
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & actividad_economica==1
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & actividad_economica==1
sum ingreso_t if sexo==1 & actividad_economica==1
display "t de medias entre hombre y mujer en agricultura: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 8

sum ingreso_t if sexo==0 & actividad_economica==2
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & actividad_economica==2
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & actividad_economica==2
sum ingreso_t if sexo==1 & actividad_economica==2
display "t de medias entre hombre y mujer en minas: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 9

sum ingreso_t if sexo==0 & actividad_economica==3
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & actividad_economica==3
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & actividad_economica==3
sum ingreso_t if sexo==1 & actividad_economica==3
display "t de medias entre hombre y mujer en manufactura: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 10

sum ingreso_t if sexo==0 & actividad_economica==4
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & actividad_economica==4
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & actividad_economica==4
sum ingreso_t if sexo==1 & actividad_economica==4
display "t de medias entre hombre y mujer en electricidad: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 11

sum ingreso_t if sexo==0 & actividad_economica==5
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & actividad_economica==5
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & actividad_economica==5
sum ingreso_t if sexo==1 & actividad_economica==5
display "t de medias entre hombre y mujer en agua: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 12

sum ingreso_t if sexo==0 & actividad_economica==6
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & actividad_economica==6
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & actividad_economica==6
sum ingreso_t if sexo==1 & actividad_economica==6
display "t de medias entre hombre y mujer en construccion: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 13

sum ingreso_t if sexo==0 & actividad_economica==7
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & actividad_economica==7
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & actividad_economica==7
sum ingreso_t if sexo==1 & actividad_economica==7
display "t de medias entre hombre y mujer en comercio: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 14

sum ingreso_t if sexo==0 & actividad_economica==8
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & actividad_economica==8
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & actividad_economica==8
sum ingreso_t if sexo==1 & actividad_economica==8
display "t de medias entre hombre y mujer en transporte: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 15

sum ingreso_t if sexo==0 & actividad_economica==9
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & actividad_economica==9
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & actividad_economica==9
sum ingreso_t if sexo==1 & actividad_economica==9
display "t de medias entre hombre y mujer en alojamiento: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 16

sum ingreso_t if sexo==0 & actividad_economica==10
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & actividad_economica==10
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & actividad_economica==10
sum ingreso_t if sexo==1 & actividad_economica==10
display "t de medias entre hombre y mujer en comunicaciones: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 17

sum ingreso_t if sexo==0 & actividad_economica==11
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & actividad_economica==11
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & actividad_economica==11
sum ingreso_t if sexo==1 & actividad_economica==11
display "t de medias entre hombre y mujer en finanzas: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 18

sum ingreso_t if sexo==0 & actividad_economica==12
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & actividad_economica==12
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & actividad_economica==12
sum ingreso_t if sexo==1 & actividad_economica==12
display "t de medias entre hombre y mujer en inmobiliarias: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 19

sum ingreso_t if sexo==0 & actividad_economica==13
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & actividad_economica==13
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & actividad_economica==13
sum ingreso_t if sexo==1 & actividad_economica==13
display "t de medias entre hombre y mujer en actividades profesionales: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 20

sum ingreso_t if sexo==0 & actividad_economica==14
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & actividad_economica==14
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & actividad_economica==14
sum ingreso_t if sexo==1 & actividad_economica==14
display "t de medias entre hombre y mujer en actividades profesionales: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 21

sum ingreso_t if sexo==0 & actividad_economica==15
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & actividad_economica==15
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & actividad_economica==15
sum ingreso_t if sexo==1 & actividad_economica==15
display "t de medias entre hombre y mujer en actividades adm publica: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 22

sum ingreso_t if sexo==0 & actividad_economica==16
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & actividad_economica==16
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & actividad_economica==16
sum ingreso_t if sexo==1 & actividad_economica==16
display "t de medias entre hombre y mujer en actividades enseñanza: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 23

sum ingreso_t if sexo==0 & actividad_economica==17
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & actividad_economica==17
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & actividad_economica==17
sum ingreso_t if sexo==1 & actividad_economica==17
display "t de medias entre hombre y mujer en actividades enseñanza: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 24

sum ingreso_t if sexo==0 & actividad_economica==18
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & actividad_economica==18
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & actividad_economica==18
sum ingreso_t if sexo==1 & actividad_economica==18
display "t de medias entre hombre y mujer en actividades artisticas: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 25

sum ingreso_t if sexo==0 & actividad_economica==19
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & actividad_economica==19
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & actividad_economica==19
sum ingreso_t if sexo==1 & actividad_economica==19
display "t de medias entre hombre y mujer en otras actividades de servicios: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 26

sum ingreso_t if sexo==0 & actividad_economica==20
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & actividad_economica==20
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & actividad_economica==20
sum ingreso_t if sexo==1 & actividad_economica==20
display "t de medias entre hombre y mujer en autoempleo: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 27

sum ingreso_t if sexo==0 & actividad_economica==21
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & actividad_economica==21
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & actividad_economica==21
sum ingreso_t if sexo==1 & actividad_economica==21
display "t de medias entre hombre y mujer en actividades de organizaciones: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 28

sum ingreso_t if sexo==0 & grupos_ocupacionales==1
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & grupos_ocupacionales==1
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & grupos_ocupacionales==1
sum ingreso_t if sexo==1 & grupos_ocupacionales==1
display "t de medias entre hombre y mujer en FFAA: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 29

sum ingreso_t if sexo==0 & grupos_ocupacionales==2
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & grupos_ocupacionales==2
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & grupos_ocupacionales==2
sum ingreso_t if sexo==1 & grupos_ocupacionales==2
display "t de medias entre hombre y mujer en adm publica: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 30

sum ingreso_t if sexo==0 & grupos_ocupacionales==3
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & grupos_ocupacionales==3
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & grupos_ocupacionales==3
sum ingreso_t if sexo==1 & grupos_ocupacionales==3
display "t de medias entre hombre y mujer en empresa publica: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 31

sum ingreso_t if sexo==0 & grupos_ocupacionales==4
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & grupos_ocupacionales==4
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & grupos_ocupacionales==4
sum ingreso_t if sexo==1 & grupos_ocupacionales==4
display "t de medias entre hombre y mujer en SERVICE: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 32

sum ingreso_t if sexo==0 & grupos_ocupacionales==5
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if sexo==1 & grupos_ocupacionales==5
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if sexo==0 & grupos_ocupacionales==5
sum ingreso_t if sexo==1 & grupos_ocupacionales==5
display "t de medias entre hombre y mujer en empresa o patrono privado: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

******************************** Cuadro 4A *************************************

*Fila 1
sum ingreso_t if idioma==1
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1
sum ingreso_t if idioma==2
display "t de medias entre ingresos de idiomas de español y originario "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 2

sum ingreso_t if idioma==1 & sexo==0
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & sexo==0
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & sexo==0
sum ingreso_t if idioma==2 & sexo==0
display "t de medias entre los que hablan español y originario si son varones "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 3

sum ingreso_t if idioma==1 & sexo==1
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & sexo==1
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & sexo==1
sum ingreso_t if idioma==2 & sexo==1
display "t de medias entre los que hablan español y originario si son mujeres "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 4

sum ingreso_t if idioma==1 & area==0
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & area==0
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & area==0
sum ingreso_t if idioma==2 & area==0
display "t de medias entre los que hablan español y originario en el area urbana "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 5

sum ingreso_t if idioma==1 & area==1
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & area==1
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & area==1
sum ingreso_t if idioma==2 & area==1
display "t de medias entre los que hablan español y originario en el area rural "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 6

sum ingreso_t if idioma==1 & rango_de_edad==0
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & rango_de_edad==0
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & rango_de_edad==0
sum ingreso_t if idioma==2 & rango_de_edad==0
display "t de medias entre español y originario de 14 a 24 años: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 7

sum ingreso_t if idioma==1 & rango_de_edad==1
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & rango_de_edad==1
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & rango_de_edad==1
sum ingreso_t if idioma==2 & rango_de_edad==1
display "t de medias entre español y originario de 25 a 44 años: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 8

sum ingreso_t if idioma==1 & rango_de_edad==2
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & rango_de_edad==2
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & rango_de_edad==2
sum ingreso_t if idioma==2 & rango_de_edad==2
display "t de medias entre español y originario de 45 a 64 años: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 9

sum ingreso_t if idioma==1 & rango_de_edad==3
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & rango_de_edad==3
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & rango_de_edad==3
sum ingreso_t if idioma==2 & rango_de_edad==3
display "t de medias entre español y originario de 65 años a mas: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 11

sum ingreso_t if idioma==1 & nivel_educativo==0
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & nivel_educativo==0
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & nivel_educativo==0
sum ingreso_t if idioma==2 & nivel_educativo==0
display "t de medias entre español y originario sin nivel educativo: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 12

sum ingreso_t if idioma==1 & nivel_educativo==1
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & nivel_educativo==1
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & nivel_educativo==1
sum ingreso_t if idioma==2 & nivel_educativo==1
display "t de medias entre español y originario con nivel educativo inicial: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 13

sum ingreso_t if idioma==1 & nivel_educativo==2
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & nivel_educativo==2
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & nivel_educativo==2
sum ingreso_t if idioma==2 & nivel_educativo==2
display "t de medias entre español y originario con nivel educativo primaria: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 14

sum ingreso_t if idioma==1 & nivel_educativo==3
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & nivel_educativo==3
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & nivel_educativo==3
sum ingreso_t if idioma==2 & nivel_educativo==3
display "t de medias entre español y originario con nivel educativo secundaria: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 15

sum ingreso_t if idioma==1 & nivel_educativo==4
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & nivel_educativo==4
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & nivel_educativo==4
sum ingreso_t if idioma==2 & nivel_educativo==4
display "t de medias entre español y originario con nivel educativo superior no univ: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 16

sum ingreso_t if idioma==1 & nivel_educativo==5
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & nivel_educativo==5
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & nivel_educativo==5
sum ingreso_t if idioma==2 & nivel_educativo==5
display "t de medias entre español y originario con nivel educativo superior univ: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 17

sum ingreso_t if idioma==1 & nivel_educativo==6
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & nivel_educativo==6
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & nivel_educativo==6
sum ingreso_t if idioma==2 & nivel_educativo==6
display "t de medias entre español y originario con nivel educativo superior maestria: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 18

sum ingreso_t if idioma==1 & nivel_educativo==7
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & nivel_educativo==7
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & nivel_educativo==7
sum ingreso_t if idioma==2 & nivel_educativo==7
display "t de medias entre español y originario con nivel educativo basico especial: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 19 no tenemos variable para publico y privado
* Fila 20 no tenemos variable para publico y privado

* Fila 21

sum ingreso_t if idioma==1 & estado_civil==1
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & estado_civil==1
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & estado_civil==1
sum ingreso_t if idioma==2 & estado_civil==1
display "t de medias entre español y originario casado y conviviente: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 22

sum ingreso_t if idioma==1 & estado_civil==3
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & estado_civil==3
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & estado_civil==3
sum ingreso_t if idioma==2 & estado_civil==3
display "t de medias entre español y originario con otro estado civil: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 23

sum ingreso_t if idioma==1 & posic_hogar==1
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & posic_hogar==1
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & posic_hogar==1
sum ingreso_t if idioma==2 & posic_hogar==1
display "t de medias entre español y originario cuando son jefes de hogar: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 24

sum ingreso_t if idioma==1 & posic_hogar==2
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & posic_hogar==2
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & posic_hogar==2
sum ingreso_t if idioma==2 & posic_hogar==2
display "t de medias entre español y originario cuando no son jefes de hogar: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 25

sum ingreso_t if idioma==1 & p507==1
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & p507==1
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & p507==1
sum ingreso_t if idioma==2 & p507==1
display "t de medias entre español y originario cuando son empleadores: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 26

sum ingreso_t if idioma==1 & p507==2
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & p507==2
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & p507==2
sum ingreso_t if idioma==2 & p507==2
display "t de medias entre español y originario cuando son trabajadores: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 27

sum ingreso_t if idioma==1 & p507==3
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & p507==3
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & p507==3
sum ingreso_t if idioma==2 & p507==3
display "t de medias entre español y originario cuando son empleados: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 28

sum ingreso_t if idioma==1 & p507==4
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & p507==4
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & p507==4
sum ingreso_t if idioma==2 & p507==4
display "t de medias entre español y originario cuando son obreros: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 29

sum ingreso_t if idioma==1 & p507==5
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & p507==5
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & p507==5
sum ingreso_t if idioma==2 & p507==5
display "t de medias entre español y originario cuando son trabajador familiar no remunerado: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 30

sum ingreso_t if idioma==1 & p507==6
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & p507==6
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & p507==6
sum ingreso_t if idioma==2 & p507==6
display "t de medias entre español y originario cuando son trabajadores del hogar: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 31

sum ingreso_t if idioma==1 & p507==7
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & p507==7
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & p507==7
sum ingreso_t if idioma==2 & p507==7
display "t de medias entre español y originario cuando son otro: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

*********************************** 4B *****************************************	

* Fila 2

sum ingreso_t if idioma==1 & tamaño_de_empresa==1
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & tamaño_de_empresa==1
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & tamaño_de_empresa==1
sum ingreso_t if idioma==2 & tamaño_de_empresa==1
display "t de medias entre español y originario cuando trabajan con menos de 20 trabajadores: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 3

sum ingreso_t if idioma==1 & tamaño_de_empresa==2
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & tamaño_de_empresa==2
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & tamaño_de_empresa==2
sum ingreso_t if idioma==2 & tamaño_de_empresa==2
display "t de medias entre español y originario cuando trabajan con entre 21 a 50 trabajadores: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 4

sum ingreso_t if idioma==1 & tamaño_de_empresa==3
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & tamaño_de_empresa==3
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & tamaño_de_empresa==3
sum ingreso_t if idioma==2 & tamaño_de_empresa==3
display "t de medias entre español y originario cuando trabajan con entre 51 a 100 trabajadores: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 4

sum ingreso_t if idioma==1 & tamaño_de_empresa==4
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & tamaño_de_empresa==4
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & tamaño_de_empresa==4
sum ingreso_t if idioma==2 & tamaño_de_empresa==4
display "t de medias entre español y originario cuando trabajan con entre 101 a 500 trabajadores: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 5

sum ingreso_t if idioma==1 & tamaño_de_empresa==5
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & tamaño_de_empresa==5
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & tamaño_de_empresa==5
sum ingreso_t if idioma==2 & tamaño_de_empresa==5
display "t de medias entre español y originario cuando trabajan más 500 trabajadores: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 7

sum ingreso_t if idioma==1 & actividad_economica==1
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & actividad_economica==1
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & actividad_economica==1
sum ingreso_t if idioma==2 & actividad_economica==1
display "t de medias entre español y originario en agricultura: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 8

sum ingreso_t if idioma==1 & actividad_economica==2
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & actividad_economica==2
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & actividad_economica==2
sum ingreso_t if idioma==2 & actividad_economica==2
display "t de medias entre español y originario en minas: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 9

sum ingreso_t if idioma==1 & actividad_economica==3
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & actividad_economica==3
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & actividad_economica==3
sum ingreso_t if idioma==2 & actividad_economica==3
display "t de medias entre español y originario en manufactura: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 10

sum ingreso_t if idioma==1 & actividad_economica==4
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & actividad_economica==4
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & actividad_economica==4
sum ingreso_t if idioma==2 & actividad_economica==4
display "t de medias entre español y originario en electricidad: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 11

sum ingreso_t if idioma==1 & actividad_economica==5
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & actividad_economica==5
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & actividad_economica==5
sum ingreso_t if idioma==2 & actividad_economica==5
display "t de medias entre español y originario en agua: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 12

sum ingreso_t if idioma==1 & actividad_economica==6
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & actividad_economica==6
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & actividad_economica==6
sum ingreso_t if idioma==2 & actividad_economica==6
display "t de medias entre español y originario en construccion: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 13

sum ingreso_t if idioma==1 & actividad_economica==7
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & actividad_economica==7
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & actividad_economica==7
sum ingreso_t if idioma==2 & actividad_economica==7
display "t de medias entre español y originario en comercio: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 14

sum ingreso_t if idioma==1 & actividad_economica==8
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & actividad_economica==8
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & actividad_economica==8
sum ingreso_t if idioma==2 & actividad_economica==8
display "t de medias entre español y originario en transporte: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 15

sum ingreso_t if idioma==1 & actividad_economica==9
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & actividad_economica==9
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & actividad_economica==9
sum ingreso_t if idioma==2 & actividad_economica==9
display "t de medias entre español y originario en alojamiento: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 16

sum ingreso_t if idioma==1 & actividad_economica==10
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & actividad_economica==10
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & actividad_economica==10
sum ingreso_t if idioma==2 & actividad_economica==10
display "t de medias entre español y originario en comunicaciones: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 17

sum ingreso_t if idioma==1 & actividad_economica==11
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & actividad_economica==11
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & actividad_economica==11
sum ingreso_t if idioma==2 & actividad_economica==11
display "t de medias entre español y originario en finanzas: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 18

sum ingreso_t if idioma==1 & actividad_economica==12
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & actividad_economica==12
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & actividad_economica==12
sum ingreso_t if idioma==2 & actividad_economica==12
display "t de medias entre español y originario en inmobiliarias: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 19

sum ingreso_t if idioma==1 & actividad_economica==13
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & actividad_economica==13
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & actividad_economica==13
sum ingreso_t if idioma==2 & actividad_economica==13
display "t de medias entre español y originario en actividades profesionales: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 20

sum ingreso_t if idioma==1 & actividad_economica==14
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & actividad_economica==14
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & actividad_economica==14
sum ingreso_t if idioma==2 & actividad_economica==14
display "t de medias entre español y originario en actividades profesionales: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 21

sum ingreso_t if idioma==1 & actividad_economica==15
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & actividad_economica==15
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & actividad_economica==15
sum ingreso_t if idioma==2 & actividad_economica==15
display "t de medias entre español y originario en actividades adm publica: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 22

sum ingreso_t if idioma==1 & actividad_economica==16
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & actividad_economica==16
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & actividad_economica==16
sum ingreso_t if idioma==2 & actividad_economica==16
display "t de medias entre español y originario en actividades enseñanza: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 23

sum ingreso_t if idioma==1 & actividad_economica==17
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & actividad_economica==17
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & actividad_economica==17
sum ingreso_t if idioma==2 & actividad_economica==17
display "t de medias entre español y originario en actividades enseñanza: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 24

sum ingreso_t if idioma==1 & actividad_economica==18
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & actividad_economica==18
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & actividad_economica==18
sum ingreso_t if idioma==2 & actividad_economica==18
display "t de medias entre español y originario en actividades artisticas: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 25

sum ingreso_t if idioma==1 & actividad_economica==19
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & actividad_economica==19
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & actividad_economica==19
sum ingreso_t if idioma==2 & actividad_economica==19
display "t de medias entre español y originario en otras actividades de servicios: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 26

sum ingreso_t if idioma==1 & actividad_economica==20
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & actividad_economica==20
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & actividad_economica==20
sum ingreso_t if idioma==2 & actividad_economica==20
display "t de medias entre español y originario en autoempleo: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 27

sum ingreso_t if idioma==1 & actividad_economica==21
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & actividad_economica==21
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & actividad_economica==21
sum ingreso_t if idioma==2 & actividad_economica==21
display "t de medias entre español y originario en actividades de organizaciones: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 28

sum ingreso_t if idioma==1 & grupos_ocupacionales==1
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & grupos_ocupacionales==1
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & grupos_ocupacionales==1
sum ingreso_t if idioma==2 & grupos_ocupacionales==1
display "t de medias entre español y originario en FFAA: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 29

sum ingreso_t if idioma==1 & grupos_ocupacionales==2
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & grupos_ocupacionales==2
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & grupos_ocupacionales==2
sum ingreso_t if idioma==2 & grupos_ocupacionales==2
display "t de medias entre español y originario en adm publica: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 30

sum ingreso_t if idioma==1 & grupos_ocupacionales==3
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & grupos_ocupacionales==3
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & grupos_ocupacionales==3
sum ingreso_t if idioma==2 & grupos_ocupacionales==3
display "t de medias entre español y originario en empresa publica: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 31

sum ingreso_t if idioma==1 & grupos_ocupacionales==4
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & grupos_ocupacionales==4
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & grupos_ocupacionales==4
sum ingreso_t if idioma==2 & grupos_ocupacionales==4
display "t de medias entre español y originario en SERVICE: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

* Fila 32

sum ingreso_t if idioma==1 & grupos_ocupacionales==5
return list
gen XA = r(mean)
gen NA = r(N)
gen SDA = r(sd)	

sum ingreso_t if idioma==2 & grupos_ocupacionales==5
return list
gen XB = r(mean)
gen NB = r(N)
gen SDB = r(sd)	

gen A = ((NA-1)*(SDA^2) + (NB-1)*(SDB^2))/(NA+NB-2)
gen B = ((1/NA)+(1/NB))

gen difSD = (A*B)^(1/2) 
gen tmedias = (XA-XB)/difSD

sum ingreso_t if idioma==1 & grupos_ocupacionales==5
sum ingreso_t if idioma==2 & grupos_ocupacionales==5
display "t de medias entre español y originario en empresa o patrono privado: "tmedias

drop XA NA SDA XB NB SDB A B difSD tmedias

********************************************************************************
*******************************Modelo de Heckman********************************
********************************************************************************

*Sector de actividad economica
recode p506r4 ///
(0111/0990=1 "Sector primario") ///
(1010/9900=0 "Secor secundario y terciario"), gen(sector)
label var sector "Sector"

*Tamaño de empresa
recode p512a ///
(1=1 "Microempresa") ///
(2/5=0 "Empresa pequeña, mediana y grande"), gen(empresa) 
label var empresa "Tamaño de empresa"

*estado civil
recode p209 ///
(1/2=1 "Casado o conviviente") ///
(3/6=0 "Otro"), gen(estad_civil)
label var estad_civil "Estado civil"

*Posición en el hogar
recode p203 ///
(0=0 "No jefe de hogar") ///
(1=1 "Jefe de hogar") ///
(2/11=0 "No jefe de hogar"), gen(p_hogar)
label var p_hogar "Posición hogar"

* Escolaridad (años) / años de educación
gen sch=.
replace sch=0  if p301a==1 | p301a==2 					                                                            // Sin nivel, nivel inicial
replace sch=0  if p301a==3 & (p301b==0 & p301c==0)																    // Sin nivel :799
replace sch=1  if (p301a==3 & p301b==1) | (p301a==3 & p301c==1) | (p301a==4 & p301b==1) | (p301a==4 & p301c==1)     // 1 año  
replace sch=2  if (p301a==3 & p301b==2) | (p301a==3 & p301c==2) | (p301a==4 & p301b==2) | (p301a==4 & p301c==2)     // 2 años
replace sch=3  if (p301a==3 & p301b==3) | (p301a==3 & p301c==3) | (p301a==4 & p301b==3) | (p301a==4 & p301c==3)     // 3 años
replace sch=4  if (p301a==3 & p301b==4) | (p301a==3 & p301c==4) | (p301a==4 & p301b==4) | (p301a==4 & p301c==4)     // 4 años
replace sch=5  if (p301a==3 & p301b==5) | (p301a==3 & p301c==5) | (p301a==4 & p301b==5) | (p301a==4 & p301c==5)     // 5 años
replace sch=6  if (p301a==3 & p301b==6) | (p301a==3 & p301c==6) | (p301a==4 & p301b==6) | (p301a==4 & p301c==6)     // 6 años
replace sch=7  if (p301a==5 & p301b==1) | (p301a==6 & p301b==1)                                                     // 7 años
replace sch=8  if (p301a==5 & p301b==2) | (p301a==6 & p301b==2)   											        // 8 años
replace sch=9  if (p301a==5 & p301b==3) | (p301a==6 & p301b==3)   												    // 9 años
replace sch=10 if (p301a==5 & p301b==4) | (p301a==6 & p301b==4)   												    // 10 años
replace sch=11 if (p301a==5 & p301b==5) | (p301a==6 & p301b==5)   												    // 11 años
replace sch=12 if (p301a==6 & p301b==6) 																			// Secundaria
replace sch=12 if (p301a==7 & p301b==1) | (p301a==8 & p301b==1) | (p301a==9 & p301b==1) | (p301a==10 & p301b==1)   // 12 años
replace sch=13 if (p301a==7 & p301b==2) | (p301a==8 & p301b==2) | (p301a==9 & p301b==2) | (p301a==10 & p301b==2)   // 13 años
replace sch=14 if (p301a==7 & p301b==3) | (p301a==8 & p301b==3) | (p301a==9 & p301b==3) | (p301a==10 & p301b==3)   // 14 años
replace sch=15 if (p301a==7 & p301b==4) | (p301a==8 & p301b==4) | (p301a==9 & p301b==4) | (p301a==10 & p301b==4)   // 15 años
replace sch=16 if (p301a==7 & p301b==5) | (p301a==8 & p301b==5) | (p301a==9 & p301b==5) | (p301a==10 & p301b==5)   // 16 años
replace sch=17 if (p301a==9 & p301b==6) | (p301a==10 & p301b==6) | (p301a==11 & p301b==1)
replace sch=18 if (p301a==9 & p301b==7) | (p301a==10 & p301b==7) | (p301a==11 & p301b==2)
label variable sch "Años de educación"

* Experiencia laboral
gen exper = age - sch - 6 
label var exper "Potential Experience =  age - sch - 6"

* Experiencia laboral al cuadrado
gen exper_sq=(exper)^2
label var exper_sq "Potential Experience (Square)"

* Modelo de Heckman
heckman ln_ing sexo idioma sch exper exper_sq empresa sector area, select(sexo idioma age estad_civil p_hogar area) cformat(%6.4fc) level(95) 
outreg2 using "$results/regresiones.xls", title(Modelo de Heckman) noparen excel 

* Modelo de Heckman separando la muestra por género
gen ln_ing_v  = ln_ing if sexo==0
gen ln_ing_m  = ln_ing if sexo==1

* Modelo de Heckman para varones
heckman ln_ing_v idioma sch exper exper_sq empresa sector area, select(idioma age estad_civil p_hogar area) cformat(%6.4fc) level(95) 

* Modelo de Heckman para mujeres
heckman ln_ing_m idioma sch exper exper_sq empresa sector area, select(idioma age estad_civil p_hogar area) cformat(%6.4fc) level(95) 

* Modelo de Heckman separando la muestra por lengua materna
gen ln_ing_o  = ln_ing if idioma==1
gen ln_ing_e  = ln_ing if idioma==2

* Modelo de Heckman para lengua originaria
heckman ln_ing_o sexo sch exper exper_sq empresa sector area, select(sexo age estad_civil p_hogar area) cformat(%6.4fc) level(95) 

* Modelo de Heckman para español
heckman ln_ing_e sexo sch exper exper_sq empresa sector area, select(sexo age estad_civil p_hogar area) cformat(%6.4fc) level(95) 

***********************CORRELACIONES ENTRE VARIABLES****************************

Graficamos correlaciones
graph twoway (scatter ing_totalM p207), ///
xlabel(1(1)2, nogrid) graphregion(color(white)) xtitle("Sexo") ytitle("Ingreso_Laboral")
graph export "$plots/scatter_1.png", as(png) replace

graph twoway (scatter ing_totalM idioma), ///
xlabel(1(1)2, nogrid) graphregion(color(white)) xtitle("Lengua_Materna") ytitle("Ingreso_Laboral")
graph export "$plots/scatter_2.png", as(png) replace

graph matrix ing_totalM area nivel_educativo idioma p207 grupos_ocupacionales, diagonal(,bfcolor(eggshell)) graphregion(color(white))



