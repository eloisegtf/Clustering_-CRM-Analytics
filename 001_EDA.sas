/*************************************/
/*1) IMPORTATION DES BASES DE DONNEES*/ 
/*************************************/

/***A) Base de données clients***/
proc import datafile="C:\Users\evage\Desktop\CRM\Projet\Donnees\clients.csv" 
    out=projet.clients (rename=(VAR3=date_creation_compte))  /* Nom de la table en sortie */
    dbms=csv                /* Le type de données à importer */
    replace;               /* A utiliser pour remplacer la table de sortie*/
    delimiter=';';           /* Le séparateur utilisé */
    getnames=yes;           /* Prendre la première ligne comme nom de colonnes */
run; 

/***B) Base de données commandes***/ 
proc import datafile="C:\Users\evage\Desktop\CRM\Projet\Donnees\commandes.csv" 
    out=projet.commandes  
	dbms=csv                
    replace;               
    delimiter=';';          
    getnames=yes;           
run; 


/**********************************/
/*2) REGARD DES DEUX TABLES BRUTES*/ 
/**********************************/

/***A) Base de données clients***/
proc contents data=projet.clients; 
run; 
/*Composée de 5096 observations et 7 variables*/ 
/*3 variables de type caractère, 2 dates, 2 variables numériques qui sont des indicatrices*/ 

/***B) Base de données commandes***/
proc contents data=projet.commandes; 
run; 
/*Composée de 11242 observations et 8 variables*/ 
/*1 date en format caractère, 
6 numériques dont le numéro de commande qui est en réalité du caractère
1 variable caractère qui est le numéro de client*/ 

/*************************************/
/*3) CHANGEMENT DU TYPE DES VARIABLES*/ 
/*************************************/

/*Dans cette partie, nous changeons le type du numéro de commande et de la date (dans commandes)*/ 
data projet.commandes;
set projet.commandes;

/*numéro de commande de numérique à caractère*/
numero_commande_2 = put(numero_commande, 6.);
DROP numero_commande; 
RENAME numero_commande_2=numero_commande; 

/*date de char à date*/ 
length NEW_DATE $10.;
   SUB = '-';
   NEW_DATE = transtrn(date,SUB,trimn(''));
   JAN = 'janv';
   NEW_DATE_1 = transtrn(NEW_DATE,JAN,trimn('JAN'));
   FEB = 'févr';
   NEW_DATE_2 = transtrn(NEW_DATE_1,FEB,trimn('FEB'));
   MAR = 'mars';
   NEW_DATE_3 = transtrn(NEW_DATE_2,MAR,trimn('MAR'));
   APR = 'avr';
   NEW_DATE_4 = transtrn(NEW_DATE_3,APR,trimn('APR'));
   MAY = 'mai';
   NEW_DATE_5 = transtrn(NEW_DATE_4,MAY,trimn('MAY'));
   JUN = 'juin';
   NEW_DATE_6 = transtrn(NEW_DATE_5,JUN,trimn('JUN'));
   JUL = 'juil';
   NEW_DATE_7 = transtrn(NEW_DATE_6,JUL,trimn('JUL'));
   AUG = 'aout';
   NEW_DATE_8 = transtrn(NEW_DATE_7,AUG,trimn('AUG'));
   SEP = 'sept';
   NEW_DATE_9 = transtrn(NEW_DATE_8,SEP,trimn('SEP'));
   OCT = 'oct';
   NEW_DATE_10 = transtrn(NEW_DATE_9,OCT,trimn('OCT'));
   NOV = 'nov';
   NEW_DATE_11 = transtrn(NEW_DATE_10,NOV,trimn('NOV'));
   DEC = 'déc';
   NEW_DATE_12 = transtrn(NEW_DATE_11,DEC,trimn('DEC'));

DROP date NEW_DATE NEW_DATE_1 NEW_DATE_2 NEW_DATE_3 NEW_DATE_4 
NEW_DATE_5 NEW_DATE_6 NEW_DATE_7 NEW_DATE_8 NEW_DATE_9 NEW_DATE_10 NEW_DATE_11
SUB JAN OCT NOV DEC AUG SEP MAR JUN JUL FEB APR MAY;
date_2 = input(NEW_DATE_12,date8.);
format date_2 ddmmyy8.;
RENAME date_2=date; 
DROP NEW_DATE_12; 
run;

/**************************/
/*4) AUDIT SUR LES DONNEES*/ 
/**************************/

/***A) Base de données clients***/ 
proc sql;
create table audit_client
as select

/*Nombre de clients distincts*/
count(distinct(num_client)) as nb_num_clients, /*5096, un client pour une observation*/ 

/*Nombre de valeurs manquantes*/
sum(num_client="") as nb_NR_num_client, /*0 valeur manquante*/
sum(actif=.) as nb_NR_actif, /*0 valeur manquante*/
sum(date_creation_compte=.) as nb_NR_date_creation, /*0 valeur manquante*/
sum(A_ete_parraine="") as nb_NR_A_ete_parraine, /*106 valeurs manquantes*/
sum(Genre="") as nb_NR_civilite_client, /*0 valeur manquante*/
sum(date_naissance=.) as nb_NR_date_naissance, /*62 valeurs manquantes*/
sum(inscrit_NL=.) as nb_NR_inscrit_NL, /*0 valeur manquante*/

/*Analyse des dates*/ 
max(date_creation_compte) as max_date_inscription format ddmmyy8., 
min(date_creation_compte) as min_date_inscrition format ddmmyy8.,
	/*La dernière date de création est en 2021 et la première en 2013, ce qui semble correct*/ 
max(date_naissance) as max_date_naissance format ddmmyy8.,
min(date_naissance) as min_date_naissance format ddmmyy8.,
	/*La personne la plus jeune est née en 2014. Si on se situe par rapport à 2021, 
	elle aurait effectué sa première commande à 7 ans ce qui semble tout de même aberrant.
	La personne la plus agée a 91 ans, ce qui semble correct*/

/*Analyse des variables catégorielles*/ 
count(distinct(Genre)) as nb_D_civilite_client, /*2 modalités*/
count(distinct(A_ete_parraine)) as nb_D_A_ete_parraine, /*3 modalités, nous analyserons cette variable dans la partie 5)A)*/
count(distinct(actif)) as nb_D_actif, /*2 modalités*/ 
count(distinct(inscrit_NL)) as nb_D_inscrit_NL  /*2 modalités*/
from projet.clients;
quit;


/***B) Base de données commandes***/ 
proc sql;
create table audit_commandes
as select
/*Nombre de clients et commandes distincts*/
count(distinct(num_client)) as nb_num_clients, /*4201 clients ont fait une commande*/ 
count(distinct(numero_commande)) as nb_num_commandes, /*11242, une commande pour une observation*/ 

/*Nombre de valeurs manquantes*/
sum(num_client="") as nb_NR_num_client, /*0 valeur manquante*/
sum(numero_commande="") as nb_NR_num_commandes, /*0 valeur manquante*/
sum(montant_des_produits=.) as nb_NR_montant, /*135 valeurs manquantes*/
sum(date=.) as nb_NR_date, /*0 valeur manquante*/
sum(remise_sur_produits=.) as nb_NR_remise, /* 9694 valeurs manquantes qui signifie pas de remise*/
sum(montant_livraison=.) as nb_NR_liv, /*132 valeurs manquantes*/
sum(remise_sur_livraison=.) as nb_NR_remise_liv, /*10282 NA ce qui signifie pas de remise*/
sum(montant_total_paye=.) as nb_NR_total, /*117 valeurs manquantes*/

/*Montants*/
min(montant_des_produits) as min_mtn_prod, /*3.5*/
max(montant_des_produits) as max_mtn_prod, /*3631*/
mean(montant_des_produits) as mean_mtn_prod,  /*Environ 99*/ 
/*L'écart entre le plus petit montant et le plus grand montant est très important. 
Cependant, les très grands montants sont rares car la moyenne est d'environ 99*/ 

min(montant_livraison) as min_mtn_liv, /*0.09*/
max(montant_livraison) as max_mtn_liv, /*130*/
mean(montant_livraison) as mean_mtn_liv,/*Environ 12*/

min(montant_total_paye) as min_mtn_total, /*-3.99*/
max(montant_total_paye) as max_mtn_total, /*3716*/
mean(montant_total_paye) as mean_mtn_total,/*Environ 107*/ 
	/*Le montant total payé peut être négatif car des remboursements sont effectués
	Malgré des valeurs négatives, le montant total à payer est en moyenne plus élevé 
	que le montant, ce qui semble normal car les individus payent également la livraison*/ 

/*Remises*/
min(remise_sur_produits) as min_remise, /*-1396*/
max(remise_sur_produits) as max_remise, /*7.54*/
mean(remise_sur_produits) as mean_remise, /*Environ -24*/ 

min(remise_sur_livraison) as min_remise_liv, /*-130*/
max(remise_sur_livraison) as max_remise_liv, /*35*/
mean(remise_sur_livraison) as mean_remise_liv, /*Environ -15*/
	/*Les remises peuvent être positives comme négatives car il y a également 
	des remboursements*/ 

/*Date*/
max(date) as max_date format ddmmyy8., 
min(date) as min_date format ddmmyy8.
	/*La première commande est effectuée en 2020 et la dernière en 2021 on se situe 
	donc bien dans le périmètre d'analyse 2020 et 2021*/ 
from projet.commandes;
quit;

/***************************************/
/*5) CHANGMENT ET CREATION DE VARIABLES*/ 
/***************************************/

/***A) Base de données clients***/ 

/*Analyse détaillée de la variable "A_ete_parraine" car trois modalités présentes*/ 
proc freq data=projet.clients; TABLE A_ete_parraine; run; 
	/*3 modalités OUI, NON, ?: le ? est donc une valeur manquante
	Il y a donc (41 + 106) 147 valeurs manquantes que nous traitons ci-dessous*/ 

/*Nous avons la date de naissance mais pas l'âge des individus, également 
il est intéressant d'analyser l'ancienneté des individus. 
Nous créons une variable gardant les mois et années de création de comptes
pour une analyse graphique ultérieure*/ 
data projet.clients_MEF;
set projet.clients;
/*Gestion des NA dans la variable de parrainage*/
IF A_ete_parraine="" then A_ete_parraine="?"; else A_ete_parraine=A_ete_parraine; 
/*Détermination de l'âge*/ 
age=intck("year",date_naissance, "01jan2021"d);
/*Détermination de l'ancienneté*/
anciennete=intck("year",date_creation_compte, "01jan2021"d);
/*MOIS-ANNEE de création de comptes*/ 
if month(date_creation_compte)>9 then 
an_date_creation=compress(year(date_creation_compte)!!"-"!!month(date_creation_compte));
else an_date_creation=compress(year(date_creation_compte)!!"-0"!!month(date_creation_compte));
run;

/***B) Base de données commandes***/ 

/*Nous créons une variable pour savoir combien de commandes ont bénéficié d'une remise et 
 une variable gardant les mois et années de la commande pour une analyse graphique ultérieure*/ 

data projet.commandes_MEF; 
set projet.commandes; 
IF remise_sur_produits^=. AND remise_sur_produits<0 then remise="OUI"; else remise="NON"; 
/*MOIS-ANNEE de commande*/ 
if month(date)>9 then 
an_date=compress(year(date)!!"-"!!month(date));
else an_date=compress(year(date)!!"-0"!!month(date));
run; 

/************************/
/*6) ANALYSE DESCRIPTIVE*/
/************************/

/***A) Base de données clients***/

/*Création d'une variable catégorielle pour l'âge*/ 

/*Division de l'âge en 3 groupes avec un nombre de clients à peu près équitable*/ 
proc rank data=projet.clients_MEF  out=rank_age groups=3;
var age;  
ranks rang_age;
run; 

/*Analyse des groupes d'age*/ 
proc summary data=rank_age ; 
VAR age; 
class rang_age; 
output out = age_cat min=mini max=maxi; 
run; 
/*Les personnes de moins de 16 ans sont placées la catégorie "?", car par exemple une personne de 
7 ans représentant le minimum ne peut passer de commandes sans l'intervention d'un adulte*/ 

/*Découpage*/ 
data projet.clients_MEF; 
set projet.clients_MEF; 
IF 16<=age<=49 then age_cat = "16_A_49"; 
ELSE IF age>=61 then age_cat="Plus_61"; 
ELSE IF 50<=age<=60 then age_cat = "50_A_60";
ELSE age_cat = "?"; 
run; 

/*Création d'une variable catégorielle pour l'anciennete*/ 

/*Division de l'ancienneté en 3 groupes avec un nombre de clients à peu près équitable*/ 
proc rank data=projet.clients_MEF  out=rank_anc groups=3;
var anciennete;  
ranks rang_anc;
run; 

/*Analyse des groupes d'anienneté*/ 
proc summary data=rank_anc; 
VAR anciennete; 
class rang_anc; 
output out = anc_cat min=mini max=maxi; 
run; 

/*Découpage*/ 
data projet.clients_MEF; 
set projet.clients_MEF; 
IF 0<=anciennete<=2 then anc_cat = "Nouvelle"; 
ELSE IF 3<=anciennete<=5 then anc_cat="Moyenne"; 
ELSE IF anciennete>=6 then anc_cat="Ancienne"; 
ELSE anc_cat = "?"; 
run; 

ods excel file="C:\Users\evage\Desktop\CRM\Projet\Resultats\ANALYSE_CLIENT.xlsx"; 
title "ANALYSE CLIENT";
/*Nombre de clients par modalités des variables catégorielles*/
proc freq data=projet.clients_MEF; 
TABLE age_cat / nocum nofreq norow; 
TABLE anc_cat / nocum nofreq norow; 
TABLE actif / nocum nofreq norow; 
TABLE Genre / nocum nofreq norow; 
TABLE inscrit_NL / nocum nofreq norow; 
TABLE A_ete_parraine / nocum nofreq norow; 
run; 
ods excel close;

/*Nombre de clients distincts par mois et année de création de compte*/ 
proc sql; 
CREATE TABLE date_clients_stat as select an_date_creation,
count(distinct(num_client)) as nb_num_clients 
from projet.clients_MEF 
group by an_date_creation; 
run;
/*Exportation de la table sas*/ 
PROC EXPORT DATA=date_clients_stat
            OUTFILE="C:\Users\evage\Desktop\CRM\Resultats\ANALYSE_DATE_CLI.xlsx"
            DBMS=xlsx
            REPLACE;
RUN;


/***B) Base de données commandes***/ 

ods excel file="C:\Users\evage\Desktop\CRM\Projet\Resultats\ANALYSE_REMISES.xlsx"; 
title "ANALYSE REMISES";
/*Nombre de commandes ayant recues une remise ou non*/ 
proc freq data=projet.commandes_MEF; 
TABLE remise / nocum nofreq norow; 
run; 
ods excel close;

proc sql; 
CREATE TABLE date_commandes_stat as select an_date,
count(distinct(num_client)) as nb_num_clients, 
	/*Nombre de clients distincts ayant passé au moins une commande par mois*/
count(distinct(numero_commande)) as nb_num_commande, /*Nombre de commandes distinctes par mois*/
sum(distinct(montant_total_paye)) as CA /*CA par mois*/
from projet.commandes_MEF 
group by an_date; 
run;
/*Exportation de la table sas*/ 
PROC EXPORT DATA=date_commandes_stat
            OUTFILE="C:\Users\evage\Desktop\CRM\Resultats\ANALYSE_COMMANDES.xlsx"
            DBMS=xlsx
            REPLACE;
RUN;
