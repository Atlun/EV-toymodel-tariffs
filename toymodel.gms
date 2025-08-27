$setglobal path "C:\Users\thelun\Documents\GAMS\EV charging"
$setglobal Output_path "C:\Users\thelun\Documents\GAMS\EV charging"

$setglobal Year "2023"
$setglobal Temporal_Resolution "10_min"
*Set temporal resolution to either "hours" or "10_min"
$setglobal Annual_Power_Cost "no"          
$setglobal Monthly_Power_Cost "no"         
$setglobal Common_Power_Cost "no"           
$setglobal Fixed_Common_Power "no"         
$setglobal Casename "Toymodel_opt_%Temporal_Resolution%_%Year%"

$if %Annual_Power_Cost% == yes $setglobal Casename "%Casename%_annual"
$if %Monthly_Power_Cost% == yes $setglobal Casename "%Casename%_month"
$if %Common_Power_Cost% == yes $setglobal Casename "%Casename%_common"
$if %Fixed_Common_Power% == yes $setglobal Casename "%Casename%_fixedP"

Sets
priceareas
/SE1, SE2, SE3, SE4/
;



Scalar
TimestepsPerHour
DemandFactor;

$ifThen %Temporal_Resolution% ==10_min
TimestepsPerHour=6;
DemandFactor=1;

$elseIf %Temporal_Resolution% ==hours
TimestepsPerHour=1;
DemandFactor=-1;
*DemandFactor compensates for input data for demand being positive for the hourly resolution - update if changed input!

$endIf


Sets
month
/ m1*m12 /


$ifThen %Temporal_Resolution% ==10_min
timestep_all
/t00001*t52560/

timestep(timestep_all)
/t00001*t52560/

hours
/ h0001*h8760 /
   
trsp_all /
*$include ./logged_carnames.inc
$include ./names_logged.inc
    /
    
*trsp(trsp_all) / b100, b102, b103 /
*trsp(trsp_all) / b100, b102, b103 , b109,b10E, b10_1, b110, b113, b115, b117, b11B, b12_1, b13, b14_2, b15, b17_1, b18_1, b1B, b1C, b1D, b1F, b1_1, b20, b21, b22, b26, b29, b2B, b2E, b2F, b2_1, b30, b31, b32, b33, b35, b36, b37, b38, b3B, b3C, b3D, b3E, b3F, b3_1, b41, b43, b44, b47_2, b48, b4A, b4B_1, b4E, b4F, b4_1 / 
*trsp(trsp_all) / b100, b102, b103, b109, b10A, b10E, b10_1, b110, b113, b115, b117, b11B, b12_1, b13, b14_2, b15, b17_1, b18_1, b1B, b1C, b1D, b1F, b1_1, b20, b21, b22, b26, b29, b2B, b2E, b2F, b2_1, b30, b31, b32, b33, b35, b36, b37, b38, b3B, b3C, b3D, b3E, b3F, b3_1, b41, b43, b44, b47_2, b48, b4A, b4B_1, b4E, b4F, b4_1 /
*trsp(trsp_all) / b100, b102, b103, b109, b10A, b10E, b10_1, b110, b113, b115, b117, b11B, b12_1, b13, b14_2, b15, b17_1, b18_1, b1B, b1C, b1D, b1F, b1_1, b20, b21, b22, b26, b29, b2B, b2E, b2F, b2_1, b30, b31, b32, b33, b35, b36, b37, b38, b3B, b3C, b3D, b3E, b3F, b3_1, b41,  b43, b44, b47_2, b48, b4A, b4B_1, b4E, b4F, b4_1, b50, b52, b55, b58, b59, b5B, b5C, b5_1,b63, b64, b65, b66, b6A, b6B, b6C, b6E, b70, b74, b75, b77, b78, b79, b7B, b7C, b7D, b7E, b7_1  /
trsp(trsp_all) / b100, b102, b103, b109, b10D, b10E, b10_1, b110, b113, b115, b117, b11B, b12_1, b13, b14_2, b15, b17_1, b18_1, b1B, b1C, b1D, b1F, b1_1, b20, b21, b22, b26, b29, b2B, b2E, b2F, b2_1, b30, b31, b32, b33, b35, b36, b37, b38, b3B, b3C, b3D, b3E, b3F, b3_1, b41, b43, b44, b47_2, b48, b4A, b4B_1, b4E, b4F, b4_1, b50, b52, b55, b58, b59, b5B, b5C, b5_1, b63, b64, b65, b66, b6A, b6B, b6C, b6E, b70, b74, b75, b77, b78, b79, b7B, b7C, b7D, b7E, b7_1, b80, b87, b88, b8A, b8C, b8D, b8E, b90, b92, b95, b96, b97, b98, b99_1, b9A, b9C, b9D_1, b9E, b9F, b9_1, bA0, bA2, bA3, bA7, bA8, bAC, bAD, bAE, bA_1, bB3, bB4, bB5, bB6, bB7, bB8, bB9, bBB, bBD, bBF, bC0, bC2, bC5, bC8, bC9, bCA_1, bCD, bCF, bC_1, bD1, bD2, bD5, bD6, bD7, bD8, bD9, bDE, bDF, bE5, bE7, bE9, bEB, bF0, bF1, bF4, bF5, bF6, bF7, bF8, bF9, bFA, bFC  /
;


*map timesteps to hours
parameter lasttimestepinhour(hours);
parameter firsttimestepinhour(hours);
lasttimestepinhour(hours) = ord(hours) * TimestepsPerHour;
*sum(hours2 $ (ord(hours) <= ord(hours)), 24*TimestepsPerHour*dayspermonth(hours2));
firsttimestepinhour(hours) = lasttimestepinhour(hours-1) + 1;
firsttimestepinhour('h0001') = 1;

set maptimestep2hour(timestep, hours);
maptimestep2hour(timestep, hours) = yes $ (ord(timestep) >= firsttimestepinhour(hours) and ord(timestep) <= lasttimestepinhour(hours));


$elseIf %Temporal_Resolution% ==hours
timestep
/h0001*h8784/

trsp /
$include ./trsp_426.inc 
    /;

$endIf

*map timesteps to months
alias(month, month2);

parameter dayspermonth(month) / m1 31, m2 28, m3 31, m4 30, m5 31, m6 30, m7 31, m8 31, m9 30, m10 31, m11 30, m12 31 /;
parameter lasttimestepinmonth(month);
parameter firsttimestepinmonth(month);
lasttimestepinmonth(month) = sum(month2 $ (ord(month2) <= ord(month)), 24*TimestepsPerHour*dayspermonth(month2));
firsttimestepinmonth(month) = lasttimestepinmonth(month-1) + 1;
firsttimestepinmonth('m1') = 1;

set maptimestep2month(timestep, month);
maptimestep2month(timestep, month) = yes $ (ord(timestep) >= firsttimestepinmonth(month) and ord(timestep) <= lasttimestepinmonth(month));


$ifThen %Temporal_Resolution% ==10_min

Table EV_home(timestep_all,trsp_all)  notes if car is home or not [1 if home and able to charge - otherwise 0]
$include ./homeshare_10min.inc
;
Table EV_demand(timestep_all,trsp_all)  electricity demand per car in each daily driving profile [kWh per timestep]
$include ./tripenergy.inc
;

Table epriceh(hours,priceareas) 
$include ./eprice_priceareas_%year%.inc
* €/MWh (unit conversion  for energy demand in in cost eq as energy in normally in kWh)
;
Parameter residential_demand(timestep_all) /
$include ./HH_demand_10min.inc
/;

$elseIf %Temporal_Resolution% ==hours

Table EV_home(timestep,trsp)  notes if car is home or not [1 if home and able to charge - otherwise 0]
$include "fleetava_home_YDP426.inc"
;
Table EV_demand(timestep,trsp)  electricity demand per car in each daily driving profile [kWh per hour]
$include "demand_bil_YDP426.inc"
;

Table eprice(timestep,priceareas) 
$include ./eprice_priceareas_%year%.inc
* €/MWh (unit conversion  for energy demand in in cost eq as energy in normally in kWh)
;

Parameter residential_demand(timestep) /
$include ./h_AVG_residential_demand.inc
/;

$endIf


Scalar
El_cost
Beff_EV
Batterysize
Price_fastcharge
Charge_Power
Fuse_cost
kWhtokW
ktoM
;

Beff_EV=0.95;
El_cost=1;
Batterysize=100; 
Price_fastcharge=1;
*€/kWh
Charge_Power=6.9;
Fuse_cost=10;
*€/kW monthly
ktoM=1/1000;

$ifThen %Temporal_Resolution% ==10_min
    kWhtokW=6;

$elseIf %Temporal_Resolution% ==hours
    kWhtokW=1;
    
$endIf

Charge_Power=6.9/kWhtokW;


Variable
   vtotcost
   ;
   

Positive variables
V_PEVcharging_slow (timestep,trsp,priceareas) charging of the vehicle battery [kWh per timestep]
V_PEV_storage (timestep,trsp,priceareas) Storage level of the vehicle battery [kWh per timestep]
V_PEV_need (timestep,trsp,priceareas) vehicle kilometers not met by charging [kWh per timestep]
V_fuse(trsp,priceareas) fuse size [kW per pricearea]
V_power_monthly(month,trsp,priceareas) monthly peak power consumption [kW per month]
V_common_power(priceareas) common power consumption [kW per pricearea]
;


Equations
EQU_totcost
EQU_EVstoragelevel(timestep,trsp,priceareas)
EQU_fuse_need(timestep,trsp,priceareas)
EQU_month_p_need(timestep,trsp,priceareas)
EQU_common_power(timestep,priceareas)

;

V_PEV_storage.up(timestep,trsp,priceareas)=Batterysize;
V_PEVcharging_slow.up(timestep,trsp,priceareas)=Charge_Power;

$if %Monthly_Power_Cost%==no V_power_monthly.fx(month,trsp,priceareas)=0;
$if %Annual_Power_Cost%==no V_fuse.fx(trsp,priceareas)=0;
$if %Common_Power_Cost%==no V_common_power.fx(priceareas)=0;


EQU_totcost..
vtotcost =E= 
    sum(priceareas, sum(trsp, 
        sum(timestep, V_PEV_need(timestep,trsp,priceareas)*Price_fastcharge)  
$if %Temporal_Resolution% == 10_min        + sum(hours, sum(timestep $ maptimestep2hour(timestep, hours), V_PEVcharging_slow(timestep,trsp,priceareas)) * ktoM  * epriceh(hours,priceareas))
$if %Temporal_Resolution% == hours        + sum(timestep, V_PEVcharging_slow(timestep,trsp,priceareas) * ktoM * eprice(timestep,priceareas))
        + (V_fuse(trsp,priceareas) * 12 + sum(month, V_power_monthly(month, trsp,priceareas))) * Fuse_cost)
        + V_common_power(priceareas) * Fuse_cost);

EQU_EVstoragelevel(timestep,trsp,priceareas)..
V_PEV_storage(timestep++1,trsp,priceareas) =E= V_PEV_storage(timestep,trsp,priceareas) + V_PEVcharging_slow(timestep,trsp,priceareas)*Beff_EV*EV_home(timestep,trsp) + EV_demand(timestep,trsp) * DemandFactor + V_PEV_need (timestep,trsp,priceareas)*Beff_EV*(1-EV_home(timestep,trsp));

EQU_fuse_need(timestep,trsp,priceareas)..
V_PEVcharging_slow(timestep,trsp,priceareas)*kWhtokW + residential_demand(timestep)*kWhtokW/1000 =L= V_fuse(trsp,priceareas);

EQU_month_p_need(timestep, trsp,priceareas)..
V_PEVcharging_slow(timestep, trsp,priceareas)*kWhtokW + residential_demand(timestep)*kWhtokW/1000 =L= sum(month $ maptimestep2month(timestep, month), V_power_monthly(month, trsp,priceareas));

EQU_common_power(timestep,priceareas)..
sum(trsp, V_PEVcharging_slow(timestep, trsp,priceareas)*kWhtokW) =L= V_common_power(priceareas)


Model EV_charge /
*Add missing equation names here to be part of model
EQU_totcost
EQU_EVstoragelevel
$if %Annual_Power_Cost%==yes EQU_fuse_need
$if %Monthly_Power_Cost%==yes EQU_month_p_need
$if %Common_Power_Cost%==yes EQU_common_power

             /;

EV_charge.iterlim=400000;
EV_charge.optfile = 1;
Option Reslim=1000000;
EV_charge.holdfixed=1;

option solver=gurobi
*option solver=osigurobi;

Solve EV_charge using lp minimizing vtotcost;



Execute_unload '%Casename%.gdx';
*execute "gdxxrw %Casename%.gdx o=%Casename%.xlsx squeeze=0 var=V_PEV_need rng=Fast_charging!a1";
executeTool 'csvwrite id=V_PEVcharging_slow file=%Casename%.csv';
executeTool 'csvwrite id=V_PEV_need file=%Casename%_fast_charging.csv';
executeTool 'csvwrite id=EV_demand file=%Casename%_demand.csv';

*execute "gdxxrw %Casename%.gdx o=%Casename%.csv symb=V_PEVcharging_slow format=csv";
