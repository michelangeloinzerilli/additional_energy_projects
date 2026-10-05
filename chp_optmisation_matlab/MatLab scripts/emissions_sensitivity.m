clc; clear;

% Fixed CH4 fuel cost
cf_base = 9e-6;       

% Base unit emission costs
cCO_base  = 3;    % $/kg
cNOx_base = 5;    % $/kg

% Range of multipliers from +20% to +100%
nPts    = 17;
mult    = linspace(1.2, 2.0, nPts)';  
cCO_vec  = cCO_base  * mult;
cNOx_vec = cNOx_base * mult;

% Preallocate storage
X_co   = zeros(nPts,5);
X_nox  = zeros(nPts,5);

% Common fmincon settings
x0      = [8.5234,0.8468,0.8786,914.28,1492.63];
lb      = [10,0.5,0.5,800,1300];
ub      = [20,0.89,0.91,1200,1550];
options = optimoptions('fmincon', ...
             'Display','off','Algorithm','sqp', ...
             'MaxFunctionEvaluations',5000, ...
             'OptimalityTolerance',1e-6);

%% 1) Sweep CO cost (keep NOx cost at base)
for i = 1:nPts
    cCO = cCO_vec(i);
    % objective closes over cf_base, cCO, cNOx_base
    obj = @(x) exam25_emiss_sensitivity(x, cf_base, cCO, cNOx_base);
    nonl = @(x) deal([], exam25_emiss_sensitivity(x, cf_base, cCO, cNOx_base));
    
    [xopt, ~] = fmincon(obj, x0, [],[],[],[], lb,ub, nonl, options);
    X_co(i,:) = xopt;
    x0 = xopt;  % warm start
end

%% 2) Sweep NOx cost (keep CO cost at base)
% reset initial guess
x0 = [8.5234,0.8468,0.8786,914.28,1492.63];
for i = 1:nPts
    cNOx = cNOx_vec(i);
    obj = @(x) exam25_emiss_sensitivity(x, cf_base, cCO_base, cNOx);
    nonl = @(x) deal([], exam25_emiss_sensitivity(x, cf_base, cCO_base, cNOx));
    
    [xopt, ~] = fmincon(obj, x0, [],[],[],[], lb,ub, nonl, options);
    X_nox(i,:) = xopt;
    x0 = xopt;
end

%% 3) Plotting
varNames = {'\beta','\eta_c','\eta_t','T_2 [K]','T_3 [K]'};

% a) CO cost sensitivity
figure;
for j = 1:5
  subplot(3,2,j);
  plot((mult-1)*100, X_co(:,j), '-o','LineWidth',1.2);
  xlabel('CO cost increase [%]');
  ylabel(varNames{j});
  grid on;
end
sgtitle('Optimum x vs. CO unit‐cost increase');

% b) NOx cost sensitivity
figure;
for j = 1:5
  subplot(3,2,j);
  plot((mult-1)*100, X_nox(:,j), '-o','LineWidth',1.2);
  xlabel('NO_x cost increase [%]');
  ylabel(varNames{j});
  grid on;
end
sgtitle('Optimum x vs. NO_x unit‐cost increase');
