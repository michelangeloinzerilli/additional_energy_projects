Set t /t1*t24/;

Parameter rawPrice(t), price(t);

* Define your working path
$setGlobal myPath "C:/Users/michelangeloinze/Desktop/Energy_Policy/GAMS_assignment/model"

* Step 1: Use gdxxrw to convert Excel sheet to GDX
$call gdxxrw.exe input="%myPath%/Day_Ahed_Electricity_Prices.xlsx" output="%myPath%/in.gdx" par=rawPrice rng=MGP-PUNPUN!B2:C25 rdim=1 cdim=0

* Step 2: Load from GDX into GAMS
$gdxin %myPath%/in.gdx
$load rawPrice
$gdxin

* Convert €/MWh → €/kWh
price(t) = rawPrice(t) / 1000;

Set
    a  appliances    /fridge, dishwasher, washer, HVAC, ev/;

* Power usage of appliances [kWh per hour]
Parameter
    power(a) /
        fridge     0.8,
        dishwasher 1.8,
        washer     1.0,
        HVAC       2.0,
        ev         7.2
    /;

* Required runtime per appliance during the day [hours]
Parameter
    runtime(a) /
        fridge     24,
        dishwasher 2,
        washer     1,
        HVAC       3,
        ev         4
    /;

* Time window matrix (1 if appliance 'a' is allowed to run in time 't')
Parameter timewindow(a,t);

* Default all to 0
timewindow(a,t) = 0;

* Appliance time windows using $ conditional
timewindow("fridge",t)     = 1;
timewindow("dishwasher",t)$(ord(t) >= 8 and ord(t) <= 22) = 1;
timewindow("washer",t)    $(ord(t) >= 7 and ord(t) <= 21) = 1;
timewindow("HVAC",t)    $(ord(t) >= 6 and ord(t) <= 23) = 1;
timewindow("ev",t)        $(ord(t) <= 7 or ord(t) >= 22) = 1;

* Binary decision variable: x(a,t) = 1 if appliance a runs at time t
Binary Variable x(a,t);

* Objective variable: total electricity cost
Variable totalCost;

Equation
    obj                   "Objective function"
    applianceRuntime(a)   "Ensure each appliance runs for required hours"
    timeWindowLimit(a,t)  "Only allow appliances to run within allowed time slots";

* Objective function: Minimize total cost
obj..
    totalCost =e= sum((a,t), x(a,t) * power(a) * price(t));

* Each appliance must run for exactly its required runtime
applianceRuntime(a)..
    sum(t, x(a,t)) =e= runtime(a);

* Respect allowed time windows
timeWindowLimit(a,t)..
    x(a,t) =l= timewindow(a,t);

Model HomeEnergy /all/;

Solve HomeEnergy using mip minimizing totalCost;

* Display results
Display x.l, totalCost.l;
