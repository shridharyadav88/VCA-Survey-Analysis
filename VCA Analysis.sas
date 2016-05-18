libname LCA "F:\UTD material\Fall 2015\Marketing analytics using SAS\MKT project\vca group project";run;

/*Removing all the 0 values and adding one it*/

data lca_cluster;
  set LCA.survey_data;
FAIR_PRICES = FAIR_PRICES +1;
PAYMENT_OPTIONS =PAYMENT_OPTIONS +1;
CHECKOUT_PROCESS = CHECKOUT_PROCESS +1;
VET_KNOWLEDGE = VET_KNOWLEDGE +1;
KEPT_INFORMED = KEPT_INFORMED + 1;

LIKELY_RECOMMEND  = LIKELY_RECOMMEND  + 1;
LIKELY_RETURN = LIKELY_RETURN + 1;
HOSPITAL_ATMOSPHERE = HOSPITAL_ATMOSPHERE +1;
STAFF_FRIENDLY = STAFF_FRIENDLY +1;
STAFF_PREPARED =STAFF_PREPARED +1;
PET_CARE = PET_CARE +1;
CARING_AT_HOME =CARING_AT_HOME +1;
COST_NEXT_VISIT =COST_NEXT_VISIT +1;
PET_NEXT_VISIT = COST_NEXT_VISIT +1;
run;

proc sort data=lca_cluster nodupkey by OID_CLIENT_DIM ; run;

proc univariate data = lca_cluster;
run;

/*Latent Class Anaysis segmentation LCA*/


PROC LCA DATA=lca_cluster outparam=LCA.outputLCA;
    NCLASS 5;
    ITEMS FAIR_PRICES PAYMENT_OPTIONS CHECKOUT_PROCESS  VET_KNOWLEDGE 
KEPT_INFORMED LIKELY_RECOMMEND LIKELY_RETURN
HOSPITAL_ATMOSPHERE STAFF_FRIENDLY ;
RHO PRIOR = 1;
CATEGORIES 8 8 8 8 8 11 8 8 8;
    SEED 1000;
RUN;

data lca_cluster_hospital;
  set LCA.hospital_stats;
Bedroom_community	=	Bedroom_community	+1	;
Military_community	=	Military_community	+1	;
Retirement_community	=	Retirement_community	+1	;
Rural_area	=	Rural_area	+1	;
Urban_area	=	Urban_area	+1	;
run;

PROC LCA DATA=lca_cluster_hospital outparam=LCA.outputLCAHOSP;
    NCLASS 5;
    ITEMS Bedroom_community Military_community Retirement_community  Rural_area Urban_area;
/*RHO PRIOR = 1;*/
CATEGORIES 2 2 2 2 2;
    SEED 1000;
RUN;

/* Market Basket Analysis*/
libname LCA "F:\UTD material\Fall 2015\Marketing analytics using SAS\MKT project\vca group project";run;
/* Adding revenue for 2 yrs*/
proc SQl;
create table LCA.CLUSTERREVENUE as
select OID_CLIENT_DIM ,avg_days_between,
year1_tot_net_rev+year2_tot_net_rev as total_rev,
year1_tot_units+year2_tot_units as total_units,
year1_boarding_net_rev+year2_boarding_net_rev AS tot_boarding_rev ,
year1_Dental_net_rev+year2_Dental_net_rev as tot_dent_rev,
year1_Exam_net_rev+year2_Exam_net_rev as tot_exam_rev,
year1_Food_net_rev+year2_Food_net_rev as tot_food_rev,
year1_Grooming_net_rev+year2_Grooming_net_rev as tot_groming_rev,
year1_Hospitalized_net_rev+year2_Hospitalized_net_rev as tot_hootspital_rev,
year1_Laboratory_net_rev+year2_Laboratory_net_rev as tot_lab_rev,
year1_Retail_net_rev+year2_Retail_net_rev as tot_retail_rev,
year1_Other_net_rev+year2_Other_net_rev as tot_other_rev,
year1_Parasite_net_rev+year2_Parasite_net_rev as tot_parasite_rev,
year1_Radiology_net_rev+year2_Radiology_net_rev as tot_radiology_rev,
year1_Prescription_net_rev+year2_Prescription_net_rev as tot_prescription_rev,
year1_Surgery_net_rev+year2_Surgery_net_rev as tot_surgery_rev,
year1_Vaccination_net_rev+year2_Vaccination_net_rev as tot_vacci_rev as tot_vac_rev 
from LCA.trans_data;
quit;

/* Converting interval revenue data to binary revenue data for logit regression*/
data logit_total_rev;
set LCA.CLUSTERREVENUE;
logit_dent_rev = 0;
logit_exam_rev = 0;
logit_food_rev = 0;
logit_groming_rev = 0;
logit_hospital_rev = 0;
logit_lab_rev = 0;
logit_retail_rev = 0;
logit_other_rev = 0;
logit_parasite_rev = 0;
logit_radiology_rev = 0;
logit_surgery_rev = 0;
logit_vac_rev = 0;
if tot_dent_rev > 0 then logit_dent_rev = 1;
if tot_exam_rev > 0 then logit_exam_rev = 1;
if tot_food_rev > 0 then logit_food_rev = 1;
if tot_groming_rev > 0 then logit_groming_rev = 1;
if tot_lab_rev > 0 then logit_lab_rev = 1;
if tot_retail_rev > 0 then logit_retail_rev = 1;
if tot_other_rev > 0 then logit_other_rev = 1;
if tot_parasite_rev > 0 then logit_parasite_rev = 1;
if tot_radiology_rev > 0 then logit_radiology_rev = 1;
if tot_prescription_rev > 0 then logit_prescription_rev = 1;
if tot_surgery_rev > 0 then logit_surgery_rev = 1;
if tot_vac_rev > 0 then  logit_vac_rev = 1;
run;

/*Having dental test increases the chances of having surgery by 96.750 time with confidence intervals 68.413 136.655 */
/*Result = Dental bundled with surgery*/
proc logistic descending data = logit_total_rev;
model logit_dent_rev = logit_exam_rev logit_food_rev  logit_groming_rev  logit_lab_rev  
logit_retail_rev  logit_other_rev  logit_parasite_rev  logit_radiology_rev logit_prescription_rev
logit_surgery_rev  logit_vac_rev;
run;

/*Having other products or radiology increases the probabilty of having exam by 3.5 times  */
/*Result = Bundle Exam Radiology and other revenue*/
proc logistic descending data = logit_total_rev;
model logit_exam_rev = logit_dent_rev logit_food_rev  logit_groming_rev  logit_lab_rev  
logit_retail_rev  logit_other_rev  logit_parasite_rev  logit_radiology_rev logit_prescription_rev
logit_surgery_rev  logit_vac_rev;
run;

/*Goin to lag increases the chances of having food by 1.26 times*/
/*Result = Bundle Food and lab*/
proc logistic descending data = logit_total_rev;
model  logit_food_rev = logit_exam_rev logit_dent_rev  logit_groming_rev  logit_lab_rev  
logit_retail_rev  logit_other_rev  logit_parasite_rev  logit_radiology_rev logit_prescription_rev
logit_surgery_rev  logit_vac_rev;
run;

/*Having vaccination increases the probality of grooming by 1.3 times */
/*Rsult - Bundle Grooming and vaccination*/
proc logistic descending data = logit_total_rev;
model logit_groming_rev  = logit_exam_rev logit_dent_rev logit_food_rev  logit_lab_rev  
logit_retail_rev  logit_other_rev  logit_parasite_rev  logit_radiology_rev logit_prescription_rev
logit_surgery_rev  logit_vac_rev;
run;

/*Goin to dental exam increases the probability of goin to lab by 3.66 time to go to lab*/
/*Bundle lab and */
proc logistic descending data = logit_total_rev;
model logit_lab_rev  = logit_exam_rev logit_dent_rev logit_food_rev logit_groming_rev   
logit_retail_rev  logit_other_rev  logit_parasite_rev  logit_radiology_rev logit_prescription_rev
logit_surgery_rev  logit_vac_rev;
run;

/*Vaccination increases the chances of Parasite by 4.2 times*/
/*Vaccin and parasite*/
proc logistic descending data = logit_total_rev;
model logit_parasite_rev   = logit_exam_rev logit_dent_rev logit_food_rev logit_groming_rev logit_lab_rev logit_retail_rev logit_other_rev
      logit_radiology_rev logit_prescription_rev
logit_surgery_rev  logit_vac_rev;
run;

/*Having dental exam increases the chance of doin a radiology by 3.18 times*/
/*Bundle Radiology and dental*/
proc logistic descending data = logit_total_rev;
model  logit_radiology_rev  = logit_exam_rev logit_dent_rev logit_food_rev logit_groming_rev logit_lab_rev 
logit_retail_rev logit_other_rev logit_parasite_rev logit_prescription_rev logit_surgery_rev  logit_vac_rev;
run;

/*Price Elasticity*/

data LCA.elasticity_transaction_yr1 ;
set LCA.trans_nodupe;
if year1_Dental_units = . then delete;
if year1_Dental_net_rev <=0 then delete;
if year1_Dental_units <= 0 then delete;
year = 1;
year1_dental_price = year1_Dental_net_rev/year1_Dental_units;
lnDentalP = log(year1_dental_price); 
lnDentalQ = log(year1_Dental_units);
run;

data LCA.elasticity_transaction_yr2 ;
set LCA.trans_nodupe;
if year2_Dental_units = . then delete;
if year2_Dental_net_rev <=0 then delete;
if year2_Dental_units <=0 then delete;
year = 2;
year2_dental_price = year2_Dental_net_rev/year2_Dental_units;
lnDentalP = log(year2_dental_price); 
lnDentalQ = log(year2_Dental_units);
run;

proc append base=LCA.elasticity_transaction_yr1 data=LCA.elasticity_transaction_yr2 force;
run;

data LCA.elasticity_transaction_yr1;
   set LCA.elasticity_transaction_yr1 (keep=year lnDentalQ lnDentalP);
run;

proc autoreg data=LCA.elasticity_transaction_yr1 ;
      model lnDentalQ = lnDentalP / nlag=(1 2) method=ml;
	      output out=out1 r=resid1 ;
   title "OLS Estimates";
run ;

proc autoreg data=LCA.elasticity_transaction_yr1 ;
      model lnDentalQ = lnDentalP;
	      output out=out1 r=resid1 ;
   title "OLS Estimates";
run ;

	proc gplot data=plot2 ;
        title 'OLS Model Residual Plot' ;
        axis1 label=(angle=90 'Residuals') ;
        axis2 label=('Date') ;
        symbol1 c=blue i=needle v=none ;
        plot resid1*date / cframe=ligr haxis=axis2 vaxis=axis1 ;
    run ;
/*Survival analysis*/

data liferercluster;
set LCA.cc2;
if sum_discounts > 100 then delete;
lndiscount = log(sum_discounts);
run;

proc lifereg data = liferercluster;
model avg_days_between*censored(0) =
total_current_patients avg_patients_age sum_discounts

/dist = gamma;
output out = output p=median std = s; 
run;

proc means data = liferercluster;
var avg_days_between sum_revenue;run;

proc means data = liferercluster;
var sum_revenue;run;

proc lifereg data = LCA.cc2;
model avg_days_between*censored(0) =
total_current_patients avg_patients_age sum_discounts

/dist = exponential;
output out = output p=median std = s; 
run;

proc lifereg data = LCA.cc3;
model avg_days_between*censored(0) =
total_current_patients avg_patients_age sum_discounts

/dist = exponential;
output out = output p=median std = s; 
run;
