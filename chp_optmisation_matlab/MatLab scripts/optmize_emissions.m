% optimize_GT.m
clc;
clear;

% Initial guess
x0  = [15, 0.8468, 0.8786, 914.28, 1492.63];

% Variable bounds (vlb/vub)
lb  = [10,   0.5, 0.5,  800, 1300];
ub  = [20,  0.89, 0.91, 1200, 1550];

% Define nonlinear constraint function
nonlcon = @(x) deal([], exam25_emissions(x)); 

% Objective function
objfun = @(x) exam25_emissions(x); 

% Optimization options
options = optimoptions('fmincon', ...
    'Display', 'iter', ...
    'Algorithm', 'sqp', ...
    'MaxFunctionEvaluations', 5000, ...
    'OptimalityTolerance', 1e-6);

% Run optimization
[x_opt, fval, exitflag, output] = fmincon(@(x) objfun(x), x0, ...
    [], [], [], [], lb, ub, nonlcon, options);

% Now get the individual cost terms at x_opt
[~, ~, R] = exam25_emissions(x_opt);
fprintf('  Emission penalty NOx:  %.2f USD/yr\n', R.C_NOx);
fprintf('  Emission penalty CO :  %.2f USD/yr\n', R.C_CO);

% Display optimal values
fprintf('\nOptimal Design Variables:\n');
fprintf('Beta (pressure ratio):       %.2f\n', x_opt(1));
fprintf('Compressor efficiency:       %.2f\n', x_opt(2));
fprintf('Turbine efficiency:          %.2f\n', x_opt(3));
fprintf('Preheat temp T2 [K]:         %.2f\n', x_opt(4));
fprintf('Turbine inlet temp T3 [K]:   %.2f\n', x_opt(5));
fprintf('Minimum Annual Cost:         %.2f USD/year\n', fval);

% Print the individual cost contributions
fprintf('\nCost breakdown at optimum (USD):\n');
fprintf('  C1 (compressor):      %.3f\n', R.C1);
fprintf('  C2 (combustor):      %.3f\n', R.C2);
fprintf('  C3 (turbine):        %.3f\n', R.C3);
fprintf('  C_stack (exhaust):   %.3f\n', R.C_stack);
fprintf('  C_fuel:              %.3f\n', R.C_fuel);
