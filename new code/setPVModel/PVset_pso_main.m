% y_ture: True load [MW]
% y_predict: predicted load [MW]
function PVset_pso_main(y_predict, y_true, path)
    start_pso_main = tic;   
    
    %% Calculate optimal weight for each algorithm --------------------------
    % Algorithms;
    % 1. Nenural Network (NN)
    % 2. k-means
    % 3. LSTM
    % 4. Optical flow
    % ----------------------------------------------------------------------------
    % 3 methods additive model; NN, k-means, LSTM
    numOfMethds = 3; 
    coeff = getWeight(numOfMethds, y_predict, y_true);
    % 4 (all) methods additive model; NN, k-means, LSTM, Optical flow
    numOfMethds = size(y_predict, 2); % Select all algorithms
    coeff4 = getWeight(numOfMethds, y_predict, y_true);
        
    %% save file
    save_name='\PV_pso_coeff_';
    building_num = num2str(y_true(1,1)); % Get building index
    save_name = strcat(path,save_name,building_num,'.mat');
    save(save_name,'coeff','coeff4')
    end_pso_main = toc(start_pso_main)
end

function weight = getWeight(methods, y_predict, y_true)
    % Initialization
    days = size(y_predict(1).data,2);
    hours=size(y_true, 1)/days/2;
    % Restructure the predicted data
    for j = 1:methods % the number of prediction methods (k-means and fitnet)
        for hour = 1:hours
            yPredict(hour).data(:,j) = reshape(y_predict(j).data(1+(hour-1)*2:hour*2,:), [],1); % this global variable is utilized in 'objective_func'
        end
    end   
   % Restructure the target data
   for day = 1:days
       initial = 1+(day-1)*48;
       for hour = 1:hours    
           yTarget(hour).data(1+(day-1)*2:2*day,1) = reshape(y_true(initial+(hour-1)*2:initial-1+hour*2,2), [],1); 
       end
   end
    % Essential paramerters for PSO performance
    for hour = 1:hours
        rng default  % For reproducibility
        lb = zeros(1,methods);
        ub = ones(1,methods);
        options = optimoptions('particleswarm', 'MaxIterations',2000,'FunctionTolerance', 1e-25, 'MaxStallIterations', 1500,'Display', 'none');
        objFunc = @(weight) objectiveFunc(weight, yPredict(hour).data, yTarget(hour).data);
        [weight(hour, :),~,~,~] = particleswarm(objFunc,methods,lb,ub, options);   
    end
end

function total_err = objectiveFunc(weight, forecast, target) % objective function
    ensembleForecasted = sum(forecast.*weight, 2);  % add all methods
    err1 = sum(abs(target - ensembleForecasted));
    err2 = abs(1-sum(weight));
    total_err = err1+100*err2;
end