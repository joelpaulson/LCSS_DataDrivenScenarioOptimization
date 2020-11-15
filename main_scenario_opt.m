
% Description: 
% Loads the closed-loop data (generated with "main_closed_loop_data") and
% runs the discrete scenario optimization method

% Written by: Joel Paulson
% Date: 11/10/20

clear

% load data file with tuning parameters
load('cbo_results.mat')

% load the scenarios
icount = [];
ScenarioData = {};
for i = 1:Nrepeat
    % local filename for ith set of tuning parameters
    filename = ['./scenario_data/scenario_param' num2str(i) '_v2']';
    
    % try to load file
    try
        load(filename, 'Data')
        icount = [icount ; i];
        ScenarioData{end+1} = Data;
    catch
        continue
    end
end

% keep only the values for which we have data
N = length(ScenarioData{1});
Ntheta = length(icount);
x_opt = x_opt(icount,:);

% construct matrices
F = zeros(Ntheta,N);
G = zeros(Ntheta,N);
Gmax = zeros(Ntheta,1);
for i = 1:Ntheta
    for j = 1:N
        F(i,j) = -ScenarioData{i}{j}.Objective(end-1);     % minus (-) for fact that we are max moles (need to convert to min)    
        G(i,j) = max([ScenarioData{i}{j}.States(2:end,5) - 326 ; 322 - ScenarioData{i}{j}.States(2:end,5)]);
    end
    Gmax(i) = max(G(i,:));
end

% calculate objective and find minimum index
rho = 10^6;
obj = rho*max(Gmax,0) + mean(F,2);
[objopt,indopt] = min(obj);

% calculate indices of support subsample
Lsupport = [];
Ls = 1:N;
Ldelete = [];
for i = 1:N
    Lcurr = Ls;
    Lcurr(i) = -1;
    if ~isempty(Ldelete)
        Lcurr(Ldelete) = -1;
    end
    
    indDelete = find(Lcurr == -1);
    Lcurr(indDelete) = [];
    
    Fcurr = F(:,Lcurr);
    Gcurr = G(:,Lcurr);
    Gmaxcurr = max(Gcurr,[],2);
    objcurr = rho*max(Gmaxcurr,0) + mean(Fcurr,2);
    [objoptcurr,indoptcurr] = min(objcurr);    
    
    if indopt == indoptcurr
        Ldelete = [Ldelete, i];
    else
        Lsupport = [Lsupport, i];
    end
end
nsupport = length(Lsupport);

% calculate probability of satisfaction
beta = 1e-6;
epsilon = 1 - (beta/(N*nchoosek(N,nsupport)))^(1/(N-nsupport))

% find tuning parameter that leads to worst-case constraint satisfaction
[objwc,indwc] = max(Gmax);

% generate plots
Data_opt = ScenarioData{indopt};
Data_wc = ScenarioData{indwc};
tempData_opt = zeros(N,size(Data_opt{1}.States,1));
tempData_wc = zeros(N,size(Data_wc{1}.States,1));
for i = 1:N
    tempData_opt(i,:) = Data_opt{i}.States(:,5);
    tempData_wc(i,:) = Data_wc{i}.States(:,5);
end
figure; hold on;
curve1 = min(tempData_wc);
curve2 = max(tempData_wc);
fill([Data_wc{1}.Time', fliplr(Data_wc{1}.Time')], [curve1, fliplr(curve2)],'r','linestyle','none')
curve1 = min(tempData_opt);
curve2 = max(tempData_opt);
fill([Data_opt{1}.Time', fliplr(Data_opt{1}.Time')], [curve1, fliplr(curve2)],'b','linestyle','none')
alpha(0.3)
plot(Data_wc{1}.Time, mean(tempData_wc), '-.r', 'linewidth', 4);
plot(Data_opt{1}.Time, mean(tempData_opt), '-b', 'linewidth', 4);
plot([Data_opt{1}.Time(1), Data_opt{1}.Time(end)], [322, 322], '--k', 'linewidth', 2)
plot([Data_opt{1}.Time(1), Data_opt{1}.Time(end)], [326, 326], '--k', 'linewidth', 2)
set(gcf,'color','w');
set(gca,'FontSize',20)
xlabel('time (sec)')
ylabel('temperature (K)')
axis([Data_opt{1}.Time(1), Data_opt{1}.Time(end), 321, 327])

