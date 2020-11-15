
% Description: 
% Loads the BO results (generated with "main_bo") and then generates the
% closed-loop objective and constraint data for each tuning parameter
% stored in x_opt. The results are saved under the "scenario_data" folder,
% so make sure a unique name is used to avoid overwriting results. 

% Written by: Joel Paulson
% Date: 11/10/20

% clear all variables
clear

% load data file
load('cbo_results.mat')

% number of scenarios
N = 750;

% run scenario test for all parameter values
endTimeList = zeros(Nrepeat,1);
for i = 1:Nrepeat
    % print statement
    startTime_i = tic;
    fprintf('running scenarios for tuning parameter %g of %g...', i, Nrepeat)
    
    % create local filename for ith set of tuning parameters
    filename = ['./scenario_data/scenario_param' num2str(i)]';
    
    % call function to evaluate closed-loop simulation (fixed random seed)
    semibatch_mpc(x_opt(i,:), T, N, 0, filename, 1234);
    
    % print end statement
    endTimeList(i) = toc(startTime_i);
    fprintf('took %g seconds \n', endTimeList(i))        
end
