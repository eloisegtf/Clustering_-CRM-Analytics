/*******************/
/*1) INDICATEUR RFM*/
/*******************/

/*PERIMETRE: Nombre de commandes entre 2020 et 2021
Nous n'appliquons pas de filtre car nos commandes sont d�j� comprises entre ces dates*/ 

proc sql; 
create table projet.indicateur_RFM
as select num_client, 
/*Recence: anciennet� de la derni�re commande en mois*/ 
min(intck("month",date,"31dec2021"d)) as recence, 
/*Fr�quence: Nombre de commandes r�alis�es sur les deux ann�es*/
count(distinct(numero_commande)) as frequence, 
/*Montant: montant moyen pay� par client*/
mean(montant_total_paye) as montant
from projet.commandes
group by num_client; 
quit; 

/************/
/*2) ANALYSE*/
/************/

/***A) RECENCE et FREQUENCE***/

/*Nous essayons de r�partir les recences et fr�quences en trois groupes compos�s 
du m�me nombre de clients*/ 
proc freq data=projet.indicateur_RFM; 
table recence / out = recence; 
/*Cela permet d'obtenir les individus ayant fait une commande r�cemment, 
ceux ayant effectu� leur derni�re commande dans un intervalle de temps moyen 
et ceux n'ayant pas effectu� de commande depuis un plus long moment*/ 
table frequence / out = frequence; 
/*Cela permet de quantifier le nombre de commandes par individu*/
run; 
	

/*Exportation de la table sas*/ 
PROC EXPORT DATA=recence
            OUTFILE="C:\Users\evage\Desktop\CRM\Resultats\ANALYSE_DECOUPAGE.xlsx"
            DBMS=xlsx
            REPLACE;
			SHEET=recence;
RUN;

/*Exportation de la table sas*/ 
PROC EXPORT DATA=frequence
            OUTFILE="C:\Users\evage\Desktop\CRM\Resultats\ANALYSE_DECOUPAGE.xlsx"
            DBMS=xlsx
            REPLACE;
			SHEET=frequence;
RUN;

/***B) MONTANT***/
/*S�paration des montants moyens pay�s en 10 groupes*/
proc rank data=projet.indicateur_RFM out=Rang_montant groups=10;
var montant; 
ranks rang; 
run; 

/*Minimum et maximum du montant moyen pour chaque groupe*/ 
proc summary data=Rang_montant; 
class rang; 
var montant; 
output out=montant_10_RANG
min=montant_min max=montant_max; 
run; 
/*Il s'agit de r�partir les individus selon le montant moyen pay� pour leurs commandes*/  

/*Exportation de la table sas*/ 
PROC EXPORT DATA=montant_10_RANG
            OUTFILE="C:\Users\evage\Desktop\CRM\Resultats\ANALYSE_DECOUPAGE.xlsx"
            DBMS=xlsx
            REPLACE;
			SHEET=Montant;
RUN;

/***********************/
/*3) REGLE DE DECOUPAGE*/
/***********************/
data application_seuil; 
set projet.indicateur_RFM; 
if 12<recence then seg_recence="R1"; /*Recence �lev�e*/ 
else if 6<recence<=12 then seg_recence="R2"; /*Recence moyenne*/ 
else if recence<=6 then seg_recence="R3";  /*Recence �lev�e*/ 
else seg_recence="?"; /*Recence non renseign�e*/ 
if frequence=1 then seg_frequence="F1"; /*Fr�quence faible*/ 
else if 2<=frequence<=3 then seg_frequence="F2"; /*Fr�quence moyenne*/
else if 3<frequence then seg_frequence="F3"; /*Fr�quence �lev�e*/ 
else seg_frequence="?"; /*Fr�quence non renseign�e*/ 
if montant<50 then seg_montant="M1"; /*Montant faible*/ 
else if 50<=montant<100 then seg_montant="M2"; /*Montant moyen*/ 
else if 100<=montant then seg_montant="M3"; /*Montant �lev�*/ 
else seg_montant="?"; /*Montant non renseign�*/ 
run; 


/************************/
/*4)ANALYSE DU DECOUPAGE*/
/************************/

ods excel file="C:\Users\evage\Desktop\CRM\Projet\Resultats\REPARTITION_SEG.xlsx"; 
title "REPARTITION SEGMENT";
proc freq data=application_seuil; 
table seg_recence; 
table seg_frequence;
table seg_montant;
run; 
ods excel close;

/*EXPLICATION DES DECOUPAGES: 
Recence: 
Environ 38% des individus ont une recence de moins ou �gale � 6 mois, 
environ 30% des individus ont une recence sup�rieure � 6 mois et inf�rieure ou �gale � 12 mois 
et 32% ont une recence de plus d'un an 

Fr�quence:
Environ 38% des individus ont pass� une commande sur la p�riode,
environ 35%  des individus ont pass� entre 2 et 3 commandes et
environ 26% des individus sont fid�les ayant passs� plus de 3 commandes. Le dernier groupe est
moins repr�sent� car si l'on place 3 commandes dans F3 alors F2 ne repr�senterait plus que 
21,5% de la client�le 

Montant: 
Environ 36% des individus ont d�pens� en moyenne moins de 50 euros, 
environs 31% des individus ont d�pens� entre 50 et 100 euros et 
environ 33% plus de 100 euros.*/ 

/************************************/
/*5) CROISEMENT RECENCE et FREQUENCE*/
/************************************/
proc freq data=application_seuil; 
table seg_recence*seg_frequence/out=croisement_recence_frequence; 
run; 

/*Transposition de la table pour qu'elle soit lisible*/ 
proc transpose data=croisement_recence_frequence out=croisement_RF (drop=_name_ _label_);
   by seg_recence;
   var PERCENT;
   id seg_frequence;  
run;

/*Environ 18% des individus ont une recence de plus d'un an et ont pass� une commande. 
Environ 16% des individus ont une recence de moins de 6 mois et ont command� plus de 3 fois.*/

/* EXPLICATION DES REGROUPEMENTS: 
- Nous choisissons de placer les individus ayant fait peu d'achat (maximum 3 achats) 
et ayant une recence de plus d'un an au sein d'un m�me segment car nous consid�rons que ce 
sont des clients non fid�lis�s (RF1). 
- Un deuxi�me segment concerne les individus ayant une recence de moins d'un an 
ayant pass� plus de 3 commandes et ceux ayant une recence de moins de 6 mois et ayant pass� 
2 ou 3 commandes car ils repr�sente les clients les plus fid�les (RF3).
- Les autres individus sont plac�s dans un segment interm�diaire repr�sentant les clients 
ayant le potentiel de clients fid�les (RF2).*/ 

/***C) Segment SF*/
data application_seuil_RF; 
set application_seuil; 
if (seg_recence="R1" and seg_frequence="F1") or (seg_recence="R1" and seg_frequence="F2")
then seg_RF="RF1"; 
else if (seg_recence="R1" and seg_frequence="F3") or (seg_recence="R2" and seg_frequence="F1")
or (seg_recence="R2" and seg_frequence="F2") or (seg_recence="R3" and seg_frequence="F1")
then seg_RF="RF2"; 
else if (seg_recence="R2" and seg_frequence="F3") or (seg_recence="R3" and seg_frequence="F2")
or (seg_recence="R3" and seg_frequence="F3") 
then seg_RF="RF3"; 
else seg_RF="?"; 
run; 

proc freq data=application_seuil_RF; 
TABLE seg_RF /out=seg_RF; 
run; 

/*Finalement, la r�partition entre les segments est plut�t bien respect�e 
environ 29% sont dans RF1, 35% dans RF2 et 37% dans RF3.*/

/********************************************/
/*6)CROISEMENT RECENCE, FREQUENCE et MONTANT*/
/********************************************/
proc freq data=application_seuil_RF; 
table seg_RF*seg_montant/out=croisement_RF_montant; 
run; 

proc transpose data=croisement_RF_montant out=croisement_RF_MTN (drop=_name_ _label_);
   by seg_RF;
   var PERCENT;
   id seg_montant; 
run;

/*Environ 12% des individus sont non fid�les et ont un montant de d�penses faible 
Environ 14% des individus sont fid�les et ont un montant de d�penses fort.*/

/* EXPLICATION DES REGROUPEMENTS:
- Nous choisissons de placer les individus non fid�les et avec des montants de d�penses inf�rieurs 
� 100 et potentiellement fid�le avec des d�penses inf�rieurs � 50 euros dans la cat�gorie 
ex (E) repr�sentant les clients sur lesquels les actions marketing ne seront pas prioris�es. 
- Un deuxi�me segment concerne les individus fid�les avec un montant de d�pense sup�rieur � 100 
et ceux potentiellement fid�le avec des d�penses sup�rieures � 150 euros dans la cat�gories 
compagnons (C) car ce sont d�j� des clients prioris�s
- Les autres individus sont plac�s dans un segment interm�diaire not� pr�tendant (P) repr�sentant 
les clients ayant du potentiel sur lesquels nous appliquerons davantage d'action marketing.*/

/***E) Segment RFM***/
data projet.segment_RFM; 
set application_seuil_RF; 
if (seg_RF="RF1" and seg_montant="M1") or (seg_RF="RF1" and seg_montant="M2")
or (seg_RF="RF2" and seg_montant="M1")
then seg_RFM="E"; 
else if (seg_RF="RF1" and seg_montant="M3") or (seg_RF="RF2" and seg_montant="M2")
or (seg_RF="RF3" and seg_montant="M1") 
then seg_RFM="P"; 
else if (seg_RF="RF2" and seg_montant="M3") or (seg_RF="RF3" and seg_montant="M2")
or (seg_RF="RF3" and seg_montant="M3")
then seg_RFM="C"; 
else seg_RFM="?"; 
run; 

proc freq data=projet.segment_RFM; 
table seg_RFM / out=seg_RFM; 
run; 
/*Finalement, la r�partition entre les segments est plut�t bien respect�e 
environ 34% sont dans E, 29% dans P et 37% dans C.*/

/*Statistiques sur les segments*/ 
proc sql; 
create table analyse_rfm
as select seg_RFM,
mean(montant) as mtn_moy, /*Montants moyens des d�penses par segment*/ 
mean(recence) as recence_moy, /*Recences moyennes des d�penses par segment*/ 
mean(frequence) as frequence_moy /*Fr�quences moyennes des d�penses par segment*/ 
from projet.segment_RFM 
group by seg_RFM;
quit; 

/*Exportation des tables de la segmentation dans un excel*/ 
PROC EXPORT DATA=croisement_RF
            OUTFILE="C:\Users\evage\Desktop\CRM\Resultats\ANALYSE_SEGMENT.xlsx"
            DBMS=xlsx
            REPLACE;
			SHEET=croisement_RF;
RUN;

PROC EXPORT DATA=seg_RF
            OUTFILE="C:\Users\evage\Desktop\CRM\Resultats\ANALYSE_SEGMENT.xlsx"
            DBMS=xlsx
            REPLACE;
			SHEET=seg_RF;
RUN;

PROC EXPORT DATA=croisement_RF_MTN
            OUTFILE="C:\Users\evage\Desktop\CRM\Resultats\ANALYSE_SEGMENT.xlsx"
            DBMS=xlsx
            REPLACE;
			SHEET=croisement_RF_MTN;
RUN;

PROC EXPORT DATA=seg_RFM
            OUTFILE="C:\Users\evage\Desktop\CRM\Resultats\ANALYSE_SEGMENT.xlsx"
            DBMS=xlsx
            REPLACE;
			SHEET=seg_RFM;
RUN;

PROC EXPORT DATA=analyse_rfm
            OUTFILE="C:\Users\evage\Desktop\CRM\Resultats\ANALYSE_SEGMENT.xlsx"
            DBMS=xlsx
            REPLACE;
			SHEET=analyse_rfm;
RUN;







