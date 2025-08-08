$setglobal Year "2024"
$setglobal Casename "BabyTM_%Year%"

Sets
timestep
/t00001*t52560/

trsp_all /
*$include ./logged_carnames.inc
$include ./names_logged_short.inc
    /
trsp(trsp_all) / b100, b102, b103, b109, b10D, b10E, b10_1, b110, b113, b115, b117, b11B, b12_1, b13, b14_2, b15, b17_1, b18_1, b1B, b1C, b1D, b1F, b1_1, b20, b21, b22, b26, b29, b2B, b2E, b2F, b2_1, b30, b31, b32, b33, b35, b36, b37, b38, b3B, b3C, b3D, b3E, b3F, b3_1, b41, b43, b44, b47_2, b48, b4A, b4B_1, b4E, b4F, b4_1, b50, b52, b55, b58, b59, b5B, b5C, b5_1, b63, b64, b65, b66, b6A, b6B, b6C, b6E, b70, b74, b75, b77, b78, b79, b7B, b7C, b7D, b7E, b7_1, b80, b87, b88, b8A, b8C, b8D, b8E, b90, b92, b95, b96, b97, b98, b99_1, b9A, b9C, b9D_1, b9E, b9F, b9_1, bA0, bA2, bA3, bA7, bA8, bAC, bAD, bAE, bA_1, bB3, bB4, bB5, bB6, bB7, bB8, bB9, bBB, bBD, bBF, bC0, bC2, bC5, bC8, bC9, bCA_1, bCD, bCF, bC_1, bD1, bD2, bD5, bD6, bD7, bD8, bD9, bDE, bDF, bE5, bE7, bE9, bEB, bF0, bF1, bF4, bF5, bF6, bF7, bF8, bF9, bFA, bFC  /
;


Table EV_home(timestep,trsp_all)  notes if car is home or not [1 if home and able to charge - otherwise 0]
$include ./homeshare_10min_short.inc
;
Table EV_demand(timestep,trsp_all)  electricity demand per car in each daily driving profile [kWh per timestep]
$include ./tripenergy_10min_short.inc
;

Parameter residential_demand(timestep) /
$include ./HH_demand_10min.inc
/;

Parameter epriceh(timestep)/

$include ./eprice_10min_2024.inc
/;
* €/MWh (unit conversion  for energy demand in in cost eq as energy in normally in kWh)


Scalar
Beff_EV
Batterysize
Price_fastcharge
Charge_Power
kWhtokW
ktoM
;

Beff_EV=0.95;
Batterysize=100; 
Price_fastcharge=1;
*€/kWh
Charge_Power=6.9;
*€/kW monthly
ktoM=1/1000;
kWhtokW=6;
Charge_Power=6.9/kWhtokW;

Variable
vtotcost
;
   

Positive variables
V_PEVcharging_slow (timestep,trsp) charging of the vehicle battery [kWh per timestep]
V_PEV_storage (timestep,trsp) Storage level of the vehicle battery [kWh per timestep]
V_PEV_need (timestep,trsp) vehicle kilometers not met by charging [kWh per timestep]
;

Equations
EQU_totcost
EQU_EVstoragelevel(timestep,trsp)
;

V_PEV_storage.up(timestep,trsp)=Batterysize;
V_PEVcharging_slow.up(timestep,trsp)=Charge_Power;

EQU_totcost..
vtotcost =E= 
   sum(timestep, sum(trsp, V_PEV_need(timestep,trsp)*Price_fastcharge  + V_PEVcharging_slow(timestep,trsp) * ktoM  * epriceh(timestep)));

EQU_EVstoragelevel(timestep,trsp)..
V_PEV_storage(timestep++1,trsp) =E= V_PEV_storage(timestep,trsp) + V_PEVcharging_slow(timestep,trsp)*Beff_EV*EV_home(timestep,trsp) + EV_demand(timestep,trsp)
+ V_PEV_need (timestep,trsp)*Beff_EV*(1-EV_home(timestep,trsp));



Model EV_charge /
*Add missing equation names here to be part of model
all

             /;

EV_charge.iterlim=400000;
EV_charge.optfile = 1;
Option Reslim=1000000;
EV_charge.holdfixed=1;

option solver=gurobi
*option solver=osigurobi;

Solve EV_charge using lp minimizing vtotcost;

Execute_unload '%Casename%.gdx';
executeTool 'csvwrite id=V_PEVcharging_slow file=%Casename%.csv';
executeTool 'csvwrite id=V_PEV_need file=%Casename%_fast_charging.csv';