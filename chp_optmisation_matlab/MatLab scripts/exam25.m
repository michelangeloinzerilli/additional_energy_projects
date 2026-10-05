function [f, g, results] = exam25(x)

% Decision variables
beta = x(1);        % Compressor pressure ratio
eta_c = x(2);       % Compressor isentropic efficiency
eta_t = x(3);       % Turbine isentropic efficiency
T2 = x(4);          % Air preheating outlet temp [K]
T3 = x(5);          % Turbine inlet temp [K]

% Fixed values
T0 = 298.15;        % Ambient temp [K]
P0 = 1;         % Ambient pressure [bar]
LHV = 50000;        % Lower heating value of CH4 [kJ/kg]
W_el = 50e3;        % Electric power output [kW]


% ---- Thermodynamic calculations ----

% Compressor outlet temperature (isentropic relation for air, γ = 1.4)
T2 = T0 * (1 + ((beta^0.286 - 1) / eta_c));  

% Pressures throughout the system
P2 = P0 * beta;
rb = 0.95; % pressure losses in the combustion chamber
P3 = rb * P2;
P4 = P0;

% Gas turbine expansion ratio
rT = P3/P4;

% Turbine outlet temperature (isentropic relation)
T4 = T3 * (1 - eta_t * (1 - (P3 / P4) ^((1-1.4)/1.4)));

% Fuel-to-air mass ratio
FAR = (1.17 * (T3 - T0) - 1.004 * (T2 - T0)) / ...
      (LHV - 1.17 * (T3 - T0));

% Air mass flow rate
G_air = W_el / (1.17 * (1 + FAR) * (T3 - T4) - 1.004 * (T2 - T0));

% Fuel and exhaust mass flow rates
G_fuel = FAR * G_air;
G_exhaust = G_air + G_fuel;

% Work exchanged in compressor and turbine
W_c = 1.004 * G_air * (T2 - T0);
W_t = 1.17 * G_exhaust * (T3 - T4);

% ---- Cost calculations ----

% Economic parameters
c11 = 39.5;     % $ / (kg/s) // % Component 1 (e.g., Compressor)
c12 = 0.9;

c21 = 25.6;     % $ / (kg/s) // % Component 2 (e.g., Combustion chamber)
c22 = 0.995;
c23 = 0.018;    % K^-1
c24 = 26.4;

c31 = 266.3;    % $ / (kg/s) // % Component 3 (e.g., Turbine)
c32 = 0.92;
c33 = 0.036;    % K^-1
c34 = 54.4;

% Data taken from the providede table, using a case no. of 26
CRF = 0.18;
phi = 1.10; % maintenance factor
N = 7500; % [h/yr]
tau = 3600; % [s/h]
cf = 9e-6; % [USD/kJ]

% 1. AIR COMPRESSOR cost function. C is the Z of the instruction's file
C1 = c11 * G_air / (c12 - x(2)) * x(1) * log(x(1));

% 2. COMBUSTOR cost function. C is the Z of the instruction's file
C2 = (c21 / (c22 - rb)) * G_air * (1 + exp(c23 * x(5) - c24));

% 3. GAS TURBINE (expander) cost function. C is the Z of the instruction's file
C3 = (c31 / (c32 - x(3))) * G_exhaust * log(rT) * (1 + exp(c33 * x(5) - c34));

% 4. OTHER costs. C is the Z of the instruction's file
C_fixed     = 165480; % from the provided example of code's file
C_stack     = 658 * G_exhaust^1.2; % from the provided example of code's file
C_fuel      = cf * G_fuel * LHV * N * tau;

% Total cost per second
f = CRF * phi * (C1 + C2 + C3 + C_fixed + C_stack) + C_fuel;

% ---- Constraints (g ≤ 0) ----
g(1) = T2 - T3;  % ensures air can be heated

% Objective function
f = CRF * phi * (C1 + C2 + C3 + C_fixed + C_stack) + C_fuel;

% Pack results
results.C1      = C1;
results.C2      = C2;
results.C3      = C3;
results.C_stack = C_stack;
results.C_fuel  = C_fuel;


end

