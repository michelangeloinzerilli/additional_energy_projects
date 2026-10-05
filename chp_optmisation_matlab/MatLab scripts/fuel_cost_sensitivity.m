clc; clear;

% Base fuel cost [USD/kJ]
cf_base = 9e-6;

% Define the range of multipliers (0 → 2× base, i.e. –100% to +100%)
nPts = 21;
mult = linspace(0, 2, nPts)';   % column vector of factors
cf_vec = cf_base * mult;

% Preallocate storage for the 5 decision variables
Xopt = zeros(nPts, 5);

% common settings for fmincon
x0 = [8.5234, 0.8468, 0.8786, 914.28, 1492.63];
lb = [10, 0.5, 0.5, 800, 1300];
ub = [20, 0.89, 0.91, 1200, 1550];
options = optimoptions('fmincon', ...
    'Display','off','Algorithm','sqp','MaxFunctionEvaluations',5000,...
    'OptimalityTolerance',1e-6);

for i = 1:nPts
    cf_i = cf_vec(i);
    % objective for this cf
    obj_i = @(x) exam25_with_fuel_cost(x, cf_i);
    nonlcon_i = @(x) deal([], exam25_with_fuel_cost(x, cf_i)); 
    
    % optimize
    [x_opt, ~] = fmincon(obj_i, x0, [], [], [], [], lb, ub, nonlcon_i, options);
    
    Xopt(i,:) = x_opt;
    
    % use warm start
    x0 = x_opt;
end

% --- 3) Plot results ---
varNames = {'\beta','\eta_c','\eta_t','T_2 [K]','T_3 [K]'};
figure;
for j = 1:5
    subplot(3,2,j);
    plot(mult*100, Xopt(:,j), '-o','LineWidth',1.2);
    xlabel('Fuel cost change [% of base]');
    ylabel(varNames{j});
    grid on;
end
sgtitle('Optimal Design Variables vs. Fuel-Cost Variation');



