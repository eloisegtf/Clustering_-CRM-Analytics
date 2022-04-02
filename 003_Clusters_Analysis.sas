/***********************/
/*JOINTURES NECESSAIRES*/ 
/***********************/

/*Jointure des segments avec la base de données clients*/ 
proc sort data=PROJET.CLIENTS_MEF; by num_client; run; 
Data projet.df_seg_cli; 
Merge projet.segment_RFM (In=A)
projet.clients_MEF (in=B);
by num_client; 
if A then output; 
RUN;

/*Jointure des segments avec la base de données commandes*/ 
proc sql; 
create table projet.df_seg_com
as select *
from projet.commandes as t1
left join projet.segment_rfm as t2
on t1.num_client=t2.num_client; 
quit; 

/*Jointure  des segments avec la base de données commandes_MEF*/ 
proc sql; 
create table projet.df_seg_com_MEF
as select *
from projet.commandes_MEF as t1
left join projet.segment_rfm as t2
on t1.num_client=t2.num_client; 
quit; 

/***********/
/*SEGMENT E*/ 
/***********/
data projet.df_cli_E; 
set projet.df_seg_cli; 
where seg_RFM = "E"; 
run; 

/*ANALYSE SUR LA TABLE CLIENT*/
proc sql; 
create table count_cli_E
as select 
count(distinct(num_client)) as nb_cli,
mean(age) as age_moy, /*age moyen des clients*/ 
sum(montant) as mtn_sum, /*somme des montants*/
mean(montant) as mtn_moy, /*Montant moyen payé*/
mean(recence) as recence_moy, /*Recence moyenne pour ce segment*/ 
mean(frequence) as frequence_moy /*Fréquence moyenne pour ce segment*/ 
from projet.df_cli_E;  
quit; 

/*Exportation pour ce segment*/ 
PROC EXPORT DATA=count_cli_E
            OUTFILE="C:\Users\evage\Desktop\CRM\Resultats\COUNT_E.xlsx"
            DBMS=xlsx
            REPLACE;
			SHEET=PAR_CLIENT;
RUN;

ods excel file="C:\Users\evage\Desktop\CRM\Projet\Resultats\COUNT_CLI_E.xlsx"; 
title "FREQUENCE DES MODALITES SEGMENT E";
proc freq data=projet.df_cli_E; 
TABLE actif; /*Répartition actif/non actif*/ 
TABLE A_ete_parraine; /*Répartition de parrainage ou non*/ 
TABLE Genre;  /*Répartition par genre*/ 
TABLE inscrit_NL; /*Répartition inscrit à la new letter ou non*/ 
TABLE age_cat;  /*Répartition par catégorie d'age*/ 
TABLE anc_cat; /*Répartition par tranche d'ancienneté*/ 
TABLE an_date_creation; /*Répartition par mois de création de compte*/ 
run; 
ods excel close;

/*ANALYSE SUR LA TABLE COMMANDE POUR AVOIR LA DISCTINCTION PAR DATE*/
data projet.df_com_E; 
set projet.df_seg_com; 
where seg_RFM = "E"; 
year = year(date); 
run;

data projet.df_com_MEF_E; 
set projet.df_seg_com_MEF; 
where seg_RFM = "E"; 
run;

/*Nombre de commandes et CA*/ 
proc sql; 
create table count_com_E
as select year,
count(distinct(numero_commande)) as nb_com,
sum(montant_total_paye) as CA
from projet.df_com_E
group by year; 
quit; 

/*Nombre de commandes et CA par mois*/ 
proc sql; 
create table count_com_mois_E
as select an_date,
count(distinct(numero_commande)) as nb_com
from projet.df_com_MEF_E
group by an_date; 
quit; 

/*Exportation pour ce segment*/ 
PROC EXPORT DATA=count_com_E
            OUTFILE="C:\Users\evage\Desktop\CRM\Resultats\COUNT_E.xlsx"
            DBMS=xlsx
            REPLACE;
			SHEET=PAR_COMMANDE;
RUN;

PROC EXPORT DATA=count_com_mois_E
            OUTFILE="C:\Users\evage\Desktop\CRM\Resultats\COUNT_E.xlsx"
            DBMS=xlsx
            REPLACE;
			SHEET=PAR_COMMANDE_MOIS;
RUN;

/***********/
/*SEGMENT P*/ 
/***********/
data projet.df_cli_P; 
set projet.df_seg_cli; 
where seg_RFM = "P"; 
run; 

/*ANALYSE SUR LA TABLE CLIENT*/
proc sql; 
create table count_cli_P
as select 
count(distinct(num_client)) as nb_cli,
mean(age) as age_moy, /*age moyen des clients*/ 
sum(montant) as mtn_sum, /*somme des montants*/
mean(montant) as mtn_moy, /*Montant moyen*/
mean(recence) as recence_moy, /*Recence moyenne pour ce segment*/ 
mean(frequence) as frequence_moy /*Fréquence moyenne pour ce segment*/ 
from projet.df_cli_P;  
quit; 

/*Exportation pour ce segment*/ 
PROC EXPORT DATA=count_cli_P
            OUTFILE="C:\Users\evage\Desktop\CRM\Resultats\COUNT_P.xlsx"
            DBMS=xlsx
            REPLACE;
			SHEET=PAR_CLIENT;
RUN;

ods excel file="C:\Users\evage\Desktop\CRM\Projet\Resultats\COUNT_CLI_P.xlsx"; 
title "FREQUENCE DES MODALITES SEGMENT P";
proc freq data=projet.df_cli_P; 
TABLE actif; 
TABLE A_ete_parraine;
TABLE Genre; 
TABLE inscrit_NL;
TABLE age_cat;  
TABLE anc_cat; 
TABLE an_date_creation; 
run; 
ods excel close;

/*ANALYSE SUR LA TABLE COMMANDE POUR AVOIR LA DISCTINCTION PAR DATE*/
data projet.df_com_P; 
set projet.df_seg_com; 
where seg_RFM = "P"; 
year = year(date); 
run;

data projet.df_com_MEF_P; 
set projet.df_seg_com_MEF;
where seg_RFM = "P"; 
run;

/*Nombre de commandes et CA*/ 
proc sql; 
create table count_com_P
as select year,
count(distinct(numero_commande)) as nb_com,
sum(montant_total_paye) as CA
from projet.df_com_P
group by year; 
quit; 

/*Nombre de commandes et CA par mois*/ 
proc sql; 
create table count_com_mois_P
as select an_date,
count(distinct(numero_commande)) as nb_com
from projet.df_com_MEF_P
group by an_date; 
quit; 

PROC EXPORT DATA=count_com_P
            OUTFILE="C:\Users\evage\Desktop\CRM\Resultats\COUNT_P.xlsx"
            DBMS=xlsx
            REPLACE;
			SHEET=PAR_COMMANDE;
RUN;

PROC EXPORT DATA=count_com_mois_P
            OUTFILE="C:\Users\evage\Desktop\CRM\Resultats\COUNT_P.xlsx"
            DBMS=xlsx
            REPLACE;
			SHEET=PAR_COMMANDE_MOIS;
RUN;

/***********/
/*SEGMENT C*/ 
/***********/
data projet.df_cli_C; 
set projet.df_seg_cli; 
where seg_RFM = "C"; 
run; 

/*ANALYSE SUR LA TABLE CLIENT*/
proc sql; 
create table count_cli_C
as select 
count(distinct(num_client)) as nb_cli,
mean(age) as age_moy, /*age moyen des clients*/ 
sum(montant) as mtn_sum, /*somme des montants*/
mean(montant) as mtn_moy, /*Montant moyen*/
mean(recence) as recence_moy, /*Recence moyenne pour ce segment*/ 
mean(frequence) as frequence_moy /*Fréquence moyenne pour ce segment*/ 
from projet.df_cli_C;  
quit; 

PROC EXPORT DATA=count_cli_C
            OUTFILE="C:\Users\evage\Desktop\CRM\Resultats\COUNT_C.xlsx"
            DBMS=xlsx
            REPLACE;
			SHEET=PAR_CLIENT;
RUN;

ods excel file="C:\Users\evage\Desktop\CRM\Projet\Resultats\COUNT_CLI_C.xlsx"; 
title "FREQUENCE DES MODALITES SEGMENT C";
proc freq data=projet.df_cli_C; 
TABLE actif; 
TABLE A_ete_parraine;
TABLE Genre; 
TABLE inscrit_NL;
TABLE age_cat;  
TABLE anc_cat; 
TABLE an_date_creation; 
run; 
ods excel close;

/*ANALYSE SUR LA TABLE COMMANDE POUR AVOIR LA DISCTINCTION PAR DATE*/
data projet.df_com_C; 
set projet.df_seg_com; 
where seg_RFM = "C"; 
year = year(date); 
run;

data projet.df_com_MEF_C; 
set projet.df_seg_com_MEF; 
where seg_RFM = "C"; 
year = year(date); 
run;

/*Nombre de commandes et CA*/ 
proc sql; 
create table count_com_C
as select year,
count(distinct(numero_commande)) as nb_com,
sum(montant_total_paye) as CA
from projet.df_com_C
group by year; 
quit; 

/*Nombre de commandes et CA par mois*/ 
proc sql; 
create table count_com_mois_C
as select an_date,
count(distinct(numero_commande)) as nb_com
from projet.df_com_MEF_C
group by an_date; 
quit; 

PROC EXPORT DATA=count_com_C
            OUTFILE="C:\Users\evage\Desktop\CRM\Resultats\COUNT_C.xlsx"
            DBMS=xlsx
            REPLACE;
			SHEET=PAR_COMMANDE;
RUN;

PROC EXPORT DATA=count_com_mois_C
            OUTFILE="C:\Users\evage\Desktop\CRM\Resultats\COUNT_C.xlsx"
            DBMS=xlsx
            REPLACE;
			SHEET=PAR_COMMANDE_MOIS;
RUN;
