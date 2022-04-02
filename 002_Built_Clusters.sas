/*******************/
/*1) INDICATEUR RFM*/
/*******************/

/*PERIMETRE: Nombre de commandes entre 2020 et 2021
Nous n'appliquons pas de filtre car nos commandes sont déjà comprises entre ces dates*/ 

proc sql; 
create table projet.indicateur_RFM
as select num_client, 
/*Recence: ancienneté de la dernière commande en mois*/ 
min(intck("month",date,"31dec2021"d)) as recence, 
/*Fréquence: Nombre de commandes réalisées sur les deux années*/
count(distinct(numero_commande)) as frequence, 
/*Montant: montant moyen payé par client*/
mean(montant_total_paye) as montant
from projet.commandes
group by num_client; 
quit; 

/************/
/*2) ANALYSE*/
/************/

/***A) RECENCE et FREQUENCE***/

/*Nous essayons de répartir les recences et fréquences en trois groupes composés 
du même nombre de clients*/ 
proc freq data=projet.indicateur_RFM; 
table recence / out = recence; 
/*Cela permet d'obtenir les individus ayant fait une commande récemment, 
ceux ayant effectué leur dernière commande dans un intervalle de temps moyen 
et ceux n'ayant pas effectué de commande depuis un plus long moment*/ 
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
/*Séparation des montants moyens payés en 10 groupes*/
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
/*Il s'agit de répartir les individus selon le montant moyen payé pour leurs commandes*/  

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
if 12<recence then seg_recence="R1"; /*Recence élevée*/ 
else if 6<recence<=12 then seg_recence="R2"; /*Recence moyenne*/ 
else if recence<=6 then seg_recence="R3";  /*Recence élevée*/ 
else seg_recence="?"; /*Recence non renseignée*/ 
if frequence=1 then seg_frequence="F1"; /*Fréquence faible*/ 
else if 2<=frequence<=3 then seg_frequence="F2"; /*Fréquence moyenne*/
else if 3<frequence then seg_frequence="F3"; /*Fréquence élevée*/ 
else seg_frequence="?"; /*Fréquence non renseignée*/ 
if montant<50 then seg_montant="M1"; /*Montant faible*/ 
else if 50<=montant<100 then seg_montant="M2"; /*Montant moyen*/ 
else if 100<=montant then seg_montant="M3"; /*Montant élevé*/ 
else seg_montant="?"; /*Montant non renseigné*/ 
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
Environ 38% des individus ont une recence de moins ou égale à 6 mois, 
environ 30% des individus ont une recence supérieure à 6 mois et inférieure ou égale à 12 mois 
et 32% ont une recence de plus d'un an 

Fréquence:
Environ 38% des individus ont passé une commande sur la période,
environ 35%  des individus ont passé entre 2 et 3 commandes et
environ 26% des individus sont fidèles ayant passsé plus de 3 commandes. Le dernier groupe est
moins représenté car si l'on place 3 commandes dans F3 alors F2 ne représenterait plus que 
21,5% de la clientèle 

Montant: 
Environ 36% des individus ont dépensé en moyenne moins de 50 euros, 
environs 31% des individus ont dépensé entre 50 et 100 euros et 
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

/*Environ 18% des individus ont une recence de plus d'un an et ont passé une commande. 
Environ 16% des individus ont une recence de moins de 6 mois et ont commandé plus de 3 fois.*/

/* EXPLICATION DES REGROUPEMENTS: 
- Nous choisissons de placer les individus ayant fait peu d'achat (maximum 3 achats) 
et ayant une recence de plus d'un an au sein d'un même segment car nous considérons que ce 
sont des clients non fidélisés (RF1). 
- Un deuxième segment concerne les individus ayant une recence de moins d'un an 
ayant passé plus de 3 commandes et ceux ayant une recence de moins de 6 mois et ayant passé 
2 ou 3 commandes car ils représente les clients les plus fidèles (RF3).
- Les autres individus sont placés dans un segment intermédiaire représentant les clients 
ayant le potentiel de clients fidèles (RF2).*/ 

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

/*Finalement, la répartition entre les segments est plutôt bien respectée 
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

/*Environ 12% des individus sont non fidèles et ont un montant de dépenses faible 
Environ 14% des individus sont fidèles et ont un montant de dépenses fort.*/

/* EXPLICATION DES REGROUPEMENTS:
- Nous choisissons de placer les individus non fidèles et avec des montants de dépenses inférieurs 
à 100 et potentiellement fidèle avec des dépenses inférieurs à 50 euros dans la catégorie 
ex (E) représentant les clients sur lesquels les actions marketing ne seront pas priorisées. 
- Un deuxième segment concerne les individus fidèles avec un montant de dépense supérieur à 100 
et ceux potentiellement fidèle avec des dépenses supérieures à 150 euros dans la catégories 
compagnons (C) car ce sont déjà des clients priorisés
- Les autres individus sont placés dans un segment intermédiaire noté prétendant (P) représentant 
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
/*Finalement, la répartition entre les segments est plutôt bien respectée 
environ 34% sont dans E, 29% dans P et 37% dans C.*/

/*Statistiques sur les segments*/ 
proc sql; 
create table analyse_rfm
as select seg_RFM,
mean(montant) as mtn_moy, /*Montants moyens des dépenses par segment*/ 
mean(recence) as recence_moy, /*Recences moyennes des dépenses par segment*/ 
mean(frequence) as frequence_moy /*Fréquences moyennes des dépenses par segment*/ 
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







