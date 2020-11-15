
% Description: 
% Solves MPC tuning problem using constrained Bayesian optimization.
% User specifications are given at the beginning of the script. 
% You should save the results of this in a file to be used in the other
% scripts in this folder. 

% Written by: Joel Paulson
% Date: 11/10/20

% clear variables
clear

% fix random seed for repeatable results
rng(120,'twister')

% maximum number of objective calls
Nmax = 20;

% number of times to call bayesopt to get distribution of "optimal" points
Nrepeat = 1;

% number of simulation steps
T = 40;

 % number of Monte carlo samples
M = 3;

% define bayesian optimization variables
xbo1 = optimizableVariable('backoff1',[0 0.5],'Type','real');
xbo2 = optimizableVariable('backoff2',[0 0.5],'Type','real');
xbo3 = optimizableVariable('Npred',[5 20],'Type','integer');
xbo4 = optimizableVariable('discretization',{'ForwardEuler', 'RK4', 'Collocation', 'ImplicitEuler'},'Type','categorical');
xbo = [xbo1 ; xbo2 ; xbo3 ; xbo4];

% objective function and constraint handle
plot_on = 0; % turn plotting off
fun = @(x)semibatch_mpc(x, T, M, plot_on);

% loop over number of runs
saved_results = cell(Nrepeat,1);
for i = 1:Nrepeat
    
    % print statement
    startTime_i = tic;
    fprintf('\n****************************************************\n')
    fprintf('running closed-loop simulation %g of %g...\n', i, Nrepeat)
    fprintf('****************************************************\n\n')
    
    % load initial data
    load('InitialX_values.mat')
    
    % call Bayesian optimization solver
    results = bayesopt(fun,xbo,...
        'AcquisitionFunctionName', 'expected-improvement-plus',...
        'IsObjectiveDeterministic', 0,...
        'ExplorationRatio', 0.5,...
        'GPActiveSetSize', 300,...
        'UseParallel', false,...
        'MaxObjectiveEvaluations', Nmax,...
        'NumSeedPoints', 5,...
        'AreCoupledConstraintsDeterministic', [false, false],...
        'NumCoupledConstraints', 2, ...
        'PlotFcn', [], ...
        'InitialX', xinitial, ...
        'InitialObjective', finitial, ...
        'InitialConstraintViolations', cinitial);
    saved_results{i} = results;

    % create table or add to table
    if i == 1
        x_opt = results.XAtMinEstimatedObjective;
        f_opt = results.MinEstimatedObjective;
    else
        x_opt(end+1,:) = results.XAtMinEstimatedObjective;
        f_opt(end+1,:) = results.MinEstimatedObjective;
    end
    
    % print end statement
    endTime_i = toc(startTime_i);
    fprintf('\n TIME REPORT: simulation %g of %g took %g seconds \n\n', i, Nrepeat, endTime_i)    
end

% plot the average minimium function values and error bars
figure; hold on;
objMinTrace = zeros(Nrepeat,Nmax);
for i = 1:Nrepeat
    for j = 1:Nmax
        objMinTrace(i,j) = min(saved_results{i}.ObjectiveTrace(1:j));
    end
end
if Nrepeat > 1
    stairs(1:Nmax, mean(-objMinTrace), '-b', 'linewidth', 3);
    errorbar(1:Nmax, mean(-objMinTrace), min(-objMinTrace)-mean(-objMinTrace), max(-objMinTrace)-mean(-objMinTrace), '-b', 'CapSize', 10, 'LineStyle', 'none')
else
    stairs(1:Nmax, -objMinTrace, '-b', 'linewidth', 3);
end
set(gcf,'color','w')
set(gca,'FontSize',20)
xlabel('number of iterations')
ylabel('moles of product C')

% plot of spread in optimal values
figure; hold on;
Pbackoff = Polyhedron('V',[0, 0 ; 0, 0.5 ; 0.5, 0 ; 0.5, 0.5]);
Pbackoff.plot('wire',1,'color','k','linewidth',2)
scatter(x_opt.backoff1,x_opt.backoff2,75,'b','filled')
set(gcf,'color','w')
set(gca,'FontSize',20)
xlabel('backoff lower bound')
ylabel('backoff upper bound')

% run algorithm to get initial feasible value
% backoff1 = 0.5;
% backoff2 = 0.5;
% Npred = 5;
% discretization = categorical("ForwardEuler");
% xbo = table(backoff1, backoff2, Npred, discretization);
% [f, c] = semibatch_mpc(xbo, T, 10, 1);
% xinitial = xbo;
% finitial = f;
% cinitial = c';
% save('InitialX_values.mat','xinitial','finitial','cinitial')

% run a test and get a plot of results
% semibatch_mpc(x_opt(1,:), T, M, 1)
