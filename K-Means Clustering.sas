Libname UTD 'C:\Users\nxs144730\Desktop\SASdata\VCA';Run;


proc sql;
create table UTD.orders_aggreate as
select OID_CLIENT_DIM,sum(revenue)as sum_revenue,
  sum(exam) as Sum_exam,
sum(parasite) as Sum_parasite,
sum(vaccine) as Sum_vaccine,
sum(laboratory) as Sum_laboratory,
sum(radiology) as Sum_radiology,
sum(dental) as Sum_dental,
sum(hospitalized) as Sum_hospitalized,
sum(surgery) as Sum_surgery,
sum(grooming) as Sum_grooming,
sum(boarding) as Sum_boarding,
sum(discounts) as Sum_discounts,
sum(food) as Sum_food,
sum(other) as Sum_other,
sum(retail) as Sum_retail,
sum(prescription) as Sum_prescription,
sum(wellness_plan) as Sum_wellness_plan
from UTD.orders_past_2years
group by OID_CLIENT_DIM;
QUIT;


DATA WORK.CLUSTER;
MERGE UTD.Trans_data UTD.Survey_data; 
BY OID_CLIENT_DIM; RUN;

proc fastclus data = work.CLUSTER  maxclusters = 3 out = clus ;

var
FAIR_PRICES PAYMENT_OPTIONS CHECKOUT_PROCESS  VET_KNOWLEDGE 
KEPT_INFORMED OVERALL_SAT LIKELY_RECOMMEND LIKELY_RETURN
HOSPITAL_ATMOSPHERE STAFF_FRIENDLY  ;
run;

proc corr data =  work.CLUSTER;
 var  
FAIR_PRICES PAYMENT_OPTIONS CHECKOUT_PROCESS  VET_KNOWLEDGE 
KEPT_INFORMED OVERALL_SAT LIKELY_RECOMMEND LIKELY_RETURN
HOSPITAL_ATMOSPHERE STAFF_FRIENDLY STAFF_PREPARED ;
run;
; 

proc sort data = work.MERGE; by year1_tot_net_rev; run; 

proc discrim data= work.clus out=output scores = x method=normal anova;
   class cluster ;
   priors prop;
   id OID_CLIENT_DIM;
   var  
FAIR_PRICES PAYMENT_OPTIONS CHECKOUT_PROCESS VET_COMMUNICATE VET_KNOWLEDGE 
KEPT_INFORMED OVERALL_SAT LIKELY_RECOMMEND LIKELY_RETURN
HOSPITAL_ATMOSPHERE STAFF_FRIENDLY STAFF_PREPARED ;
run;
/* Check  for duplicates records*/

proc SQL;    
create table work.dop as
select OID_CLIENT_DIM, Count(*) from utd.trans_data group by OID_CLIENT_DIM having count(*)>1;
QUIT; 



proc SQL;
create table work.dop1 as
select  from utd.trans_data where OID_CLIENT_DIM = 6319924
QUIT; 
/* remove duplicates and create data set for trans_data */
 proc sort data=UTD.trans_data nodupkey out=UTD.trans_NODUPE; by OID_CLIENT_DIM ; run;   

/* Merge data sets */
 DATA WORK.CLUSTER;
MERGE UTD.Trans_data UTD.Survey_data; 
BY OID_CLIENT_DIM; RUN; 
/* remove duplicates and create data set for trans_data */

proc sort data=UTD.survey_data  nodupkey out=UTD.surveynodup; by OID_CLIENT_DIM ; run; 


/* Taking Avg   */

proc sql;
create table UTD.survey_avg as
select OID_CLIENT_DIM,
((OVERALL_SAT+LIKELY_RECOMMEND+LIKELY_RETURN+HOSPITAL_ATMOSPHERE+
STAFF_FRIENDLY+STAFF_PREPARED+KEPT_INFORMED+VET_KNOWLEDGE+VET_COMMUNICATE+
PET_CARE+CARING_AT_HOME+COST_NEXT_VISIT+PET_NEXT_VISIT+CHECKOUT_PROCESS+PAYMENT_OPTIONS+FAIR_PRICES)/16) as overall_rating
from UTD.surveynodup
QUIT; 

/* data merge orders and survey  */
 DATA UTD.Order_survey_merge;
MERGE UTD.orders_aggreate UTD.Survey_avg;
BY OID_CLIENT_DIM; RUN; 


/* data merge orders and survey  */

proc fastclus data = UTD.order_survey_merge  maxclusters = 5 out = CLUS ;

var
sum_revenue	Sum_exam	Sum_parasite	Sum_vaccine	Sum_laboratory	
Sum_radiology	Sum_dental	Sum_hospitalized Sum_surgery Sum_grooming	
Sum_boarding	Sum_discounts	Sum_food	Sum_other	Sum_retail	Sum_prescription	
Sum_wellness_plan	overall_rating;
run;
/* TABLE FOR   */
proc sql;
create table UTD.CLUSTER3 as
select OID_CLIENT_DIM,
((OVERALL_SAT+LIKELY_RECOMMEND+LIKELY_RETURN+HOSPITAL_ATMOSPHERE+
STAFF_FRIENDLY+STAFF_PREPARED+KEPT_INFORMED+VET_KNOWLEDGE+VET_COMMUNICATE+
PET_CARE+CARING_AT_HOME+COST_NEXT_VISIT+PET_NEXT_VISIT+CHECKOUT_PROCESS+PAYMENT_OPTIONS+FAIR_PRICES)/16) as overall_rating
from UTD.surveynodup
QUIT; 


proc fastclus data = UTD.order_survey_merge  maxclusters = 3 out = CLUS ;

var
	overall_rating;
run;

proc fastclus data = utd.SURVEYNODUP  maxclusters = 6 out = clus ;

var
FAIR_PRICES PAYMENT_OPTIONS CHECKOUT_PROCESS VET_COMMUNICATE VET_KNOWLEDGE 
KEPT_INFORMED OVERALL_SAT LIKELY_RECOMMEND LIKELY_RETURN
HOSPITAL_ATMOSPHERE STAFF_FRIENDLY STAFF_PREPARED ;
run; 

proc SQl;
create table UTD.CLUSTERREVENUE as
select OID_CLIENT_DIM ,avg_days_between,
year1_tot_net_rev+year2_tot_net_rev as total_rev,
year1_tot_units+year2_tot_units as total_units,
year1_boarding_net_rev+year2_boarding_net_rev AS tot_boarding_rev ,
year1_Dental_net_rev+year2_Dental_net_rev as tot_dental_revenue,
year1_Exam_net_rev+year2_Exam_net_rev as tot_exam_rev,
year1_Food_net_rev+year2_Food_net_rev as tot_food_rev,
year1_Grooming_net_rev+year2_Grooming_net_rev as tot_groming_rev,
year1_Hospitalized_net_rev+year2_Hospitalized_net_rev as tot_hospital_rev,
year1_Laboratory_net_rev+year2_Laboratory_net_rev as tot_lab_rev,
year1_Retail_net_rev+year2_Retail_net_rev as tot_retail_rev,
year1_Other_net_rev+year2_Other_net_rev as tot_other_rev,
year1_Parasite_net_rev+year2_Parasite_net_rev as tot_parasite_rev,
year1_Radiology_net_rev+year2_Radiology_net_rev as tot_radiology_rev,
year1_Prescription_net_rev+year2_Prescription_net_rev as tot_prescription_rev,
year1_Surgery_net_rev+year2_Surgery_net_rev as tot_surgery_rev,
year1_Vaccination_net_rev+year2_Vaccination_net_rev as tot_vacci_rev as tot_vac_rev 
from UTD.trans_nodupe;
quit;

Proc contents data = UTD.CLUSTERREVENUE; run;

proc reg data = UTD.surveynodup;
model LIKELY_RECOMMEND =  OVERALL_SAT LIKELY_RETURN	HOSPITAL_ATMOSPHERE	
STAFF_FRIENDLY	STAFF_PREPARED	KEPT_INFORMED	VET_KNOWLEDGE	
VET_COMMUNICATE	PET_CARE	CARING_AT_HOME	COST_NEXT_VISIT	PET_NEXT_VISIT	
CHECKOUT_PROCESS	PAYMENT_OPTIONS	FAIR_PRICES/VIF COLLIN ;
output out = resid p = PUNITS r = RUNITS student = student;
run;quit; 

proc standard data=UTD.CLUSTERREVENUE mean=0 std=1 out=UTD.standard;
var 
total_rev
total_units
avg_days_between
tot_boarding_rev
tot_dental_revenue
tot_exam_rev
tot_food_rev
tot_groming_rev
tot_hospital_rev
tot_lab_rev
tot_other_rev
tot_parasite_rev
tot_prescription_rev
tot_radiology_rev
tot_retail_rev
tot_surgery_rev
tot_vac_rev;
run;

proc fastclus data = UTD.standard  maxclusters = 3 out = clus ;
var
tot_dental_revenue
tot_exam_rev
tot_food_rev
tot_groming_rev
tot_hospital_rev
tot_lab_rev
tot_parasite_rev
tot_prescription_rev
tot_radiology_rev
tot_retail_rev
tot_vac_rev;
run; 

proc fastclus data = UTD.standard  maxclusters = 10 out = clus ;
var
total_units
total_rev;
run; 

DATA UTD.merge_trans_order;
MERGE UTD.orders_aggreate UTD.trans_nodupe;
BY OID_CLIENT_DIM; RUN;

proc sort; data=UTD.orders_aggreate  by OID_CLIENT_DIM ; run; 

Proc SQl;
create table cluster1 as 
select * 
