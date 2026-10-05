function [f, g, results] = exam25_emissions(x)


%% Decision variables
beta  = x(1);    % Compressor pressure ratio
eta_c = x(2);    % Compressor isentropic efficiency
eta_t = x(3);    % Turbine   isentropic efficiency
T2    = x(4);    % Preheater outlet temp [K]
T3    = x(5);    % Turbine inlet  temp [K]

%% Fixed data
T0   = 298.15;   % Ambient temp [K]
P0   = 1;        % Ambient pressure [bar]
LHV  = 50000;    % Lower heating value CH4 [kJ/kg]
W_el = 50e3;     % Electric power output [kW]

% Economic parameters
c11 = 39.5;  c12 = 0.9;      % compressor cost
c21 = 25.6;  c22 = 0.995;    % combustor cost
c23 = 0.018; c24 = 26.4;
c31 = 266.3; c32 = 0.92;     % turbine cost
c33 = 0.036; c34 = 54.4;

CRF = 0.18;    % capital recovery factor
phi = 1.10;    % maintenance factor
N   = 7500;    % operating hours per year
tau = 3600;    % seconds per hour
cf  = 9e-6;    % base fuel cost [USD/kJ]

%% ---- Thermodynamics ----
% 1) Compressor outlet temp (isentropic, γ=1.4)
T2 = T0 * (1 + (beta^0.286 - 1)/eta_c);

% Pressures
P2 = P0 * beta;
rb = 0.95;           % burner pressure loss
P3 = rb * P2;
P4 = P0;

% Turbine outlet temp
T4 = T3 * (1 - eta_t * (1 - (P3/P4)^((1-1.4)/1.4)));

% Fuel‐to‐air ratio
FAR = (1.17*(T3-T0) - 1.004*(T2-T0)) / (LHV - 1.17*(T3-T0));

% Mass flows
G_air     = W_el / (1.17*(1+FAR)*(T3-T4) - 1.004*(T2-T0));  % kg/s
G_fuel    = FAR * G_air;
G_exhaust = G_air + G_fuel;

% Work terms
W_c = 1.004 * G_air     * (T2 - T0);
W_t = 1.17  * G_exhaust * (T3 - T4);

%% ---- Capital cost terms (USD) ----
C1       = c11 * G_air     / (c12 - eta_c) * beta * log(beta);
C2       = (c21/(c22 - rb)) * G_air * (1 + exp(c23*T3 - c24));
rT       = P3/P4;
C3       = (c31/(c32 - eta_t)) * G_exhaust * log(rT) * (1 + exp(c33*T3 - c34));

% Other fixed and stack costs
C_fixed = 165480;
C_stack = 658 * G_exhaust^1.2;

% Fuel cost [USD/year]
C_fuel = cf * G_fuel * LHV * N * tau;

%% ---- Emission penalties (USD/year) ----
% Emission factors
EF_NOx = 51e-3;   % kg NOx per GJ fuel
EF_CO  = 26e-3;   % kg CO  per GJ fuel

% Fuel energy flow [GJ/s]
E_dot_GJ   = G_fuel * LHV / 1e6;

% Total operating seconds per year
sec_year   = N * tau;

% Annual emission masses [kg/yr]
m_NOx = EF_NOx * E_dot_GJ * sec_year;
m_CO  = EF_CO  * E_dot_GJ * sec_year;

% Penalty factors & unit costs
fp_NOx = 1.1;  c_NOx = 5;  % $/kg
fp_CO  = 7.0;  c_CO  = 3;  % $/kg

% Annual penalty costs
C_NOx = fp_NOx * c_NOx * m_NOx;
C_CO  = fp_CO  * c_CO  * m_CO;

%% ---- Assemble objective & constraint ----
% Total annualized cost (USD/year)
f = CRF*phi*(C1 + C2 + C3 + C_fixed + C_stack) ...
    + C_fuel + C_NOx + C_CO;

% Inequality constraint: g ≤ 0
g(1) = T2 - T3;

%% ---- Pack results ----
results.C1      = C1;
results.C2      = C2;
results.C3      = C3;
results.C_stack = C_stack;
results.C_fuel  = C_fuel;
results.C_NOx   = C_NOx;
results.C_CO    = C_CO;

end
