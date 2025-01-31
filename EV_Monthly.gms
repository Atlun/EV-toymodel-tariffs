$setglobal path "C:\Users\thelun\Documents\GAMS\EV charging"
$setglobal Output_path "C:\Users\thelun\Documents\GAMS\EV charging"


$setglobal Year "2050"
$setglobal Casename "test_months_%Year%"


Sets
timestep
/h0001*h8785/

month
/ m1*m12 /


trsp /
$include ./trsp_426.inc 
/;

alias(month, month2);

parameter dayspermonth(month) / m1 31, m2 28, m3 31, m4 30, m5 31, m6 30, m7 31, m8 31, m9 30, m10 31, m11 30, m12 31 /;
parameter lasthourinmonth(month);
parameter firsthourinmonth(month);
lasthourinmonth(month) = sum(month2 $ (ord(month2) <= ord(month)), 24*dayspermonth(month2));
firsthourinmonth(month) = lasthourinmonth(month-1) + 1;
firsthourinmonth('m1') = 1;

set maphour2month(timestep, month);
maphour2month(timestep, month) = yes $ (ord(timestep) >= firsthourinmonth(month) and ord(timestep) <= lasthourinmonth(month));



Table EV_home(timestep,trsp)  notes if car is home or not [1 if home and able to charge - otherwise 0]
$include "fleetava_home_YDP426.inc"
;
Table EV_demand(timestep,trsp)  electricity demand per car in each daily driving profile [kWh per hour]
$include "demand_bil_YDP426.inc"
;
*€/MWh

Parameter eprice(timestep) /
$include ./h_eprice_%year%.inc
/;
*€/MWh

Parameter residential_demand(timestep) /
$include ./h_AVG_residential_demand.inc
/;

Scalar
El_cost
Beff_EV
Batterysize
Price_fastcharge
Charge_Power
Fuse_cost
;

Beff_EV=0.95;
El_cost=1;
Batterysize=60;
Price_fastcharge=10000;
Charge_Power=6.9;
Fuse_cost=10000;


Variable
   vtotcost
   ;
   

Positive variables
V_PEVcharging_slow (timestep,trsp) charging of the vehicle battery [kWh per hour]
*V_PEVdischarge_net (timestep,trsp) Discharging of the vehicle battery back to the electricity grid [kWh per hour]
V_PEV_storage (timestep,trsp) Storage level of the vehicle battery [kWh per hour]
V_PEV_need (timestep,trsp) vehicle kilometers not met by charging [kWh per hour]
V_fuse(trsp)
V_power_monthly(month, trsp) Peak power in month
;


Equations
EQU_EVstoragelevel(timestep,trsp)
EQU_totcost
EQU_fuse_need(timestep,trsp)
EQU_month_p_need(timestep,trsp)

;

V_PEV_storage.up(timestep,trsp)=Batterysize;
V_PEVcharging_slow.up(timestep,trsp)=Charge_Power;

*Equation
EQU_EVstoragelevel(timestep,trsp)..
    V_PEV_storage(timestep++1,trsp)
=E=
    V_PEV_storage(timestep,trsp)
    + V_PEVcharging_slow(timestep,trsp)*Beff_EV*EV_home(timestep,trsp)
    -EV_demand(timestep,trsp)
    +V_PEV_need (timestep,trsp)*Beff_EV;
*    - V_PEVdischarge_net(timestep,trsp)
*    - round(demand_EV_perhour(timestep,trsp),2);


EQU_totcost..
vtotcost =E= sum(trsp, sum(timestep, (V_PEVcharging_slow(timestep,trsp)*eprice(timestep)+V_PEV_need(timestep,trsp)*Price_fastcharge))+(V_fuse(trsp)+sum(month, V_power_monthly(month, trsp)))*Fuse_cost);

EQU_fuse_need(timestep,trsp)..
V_PEVcharging_slow(timestep,trsp)+residential_demand(timestep)/1000 =L= V_fuse(trsp);

EQU_month_p_need(timestep, trsp)..
V_PEVcharging_slow(timestep, trsp) + residential_demand(timestep)/1000 =L= sum(month $ maphour2month(timestep, month), V_power_monthly(month, trsp));




Model EV_charge /
*Add missing equation names here to be part of model
              All
             /;

EV_charge.iterlim=400000;
EV_charge.optfile = 1;
Option Reslim=1000000;
EV_charge.holdfixed=1;
Solve EV_charge using lp minimizing vtotcost;



Execute_unload '%Casename%.gdx';
execute "gdxxrw %Casename%.gdx o=%Casename%.xlsx squeeze=0 var=V_PEV_need rng=Fast_charging!a1";
execute "gdxxrw %Casename%.gdx o=%Casename%.xlsx squeeze=0 var=V_PEVcharging_slow rng=Slow_charging!a1";
