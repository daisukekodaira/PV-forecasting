% y_ture: True load [MW]
% y_predict: predicted load [MW]
function PVset_pso_main(y_predict, y_true, path)
    start_pso_main = tic;   
    % Initialization
    methods = size(y_predict, 2);
    days = size(y_predict(1).data,2);
    hours=size(y_true, 1)/days/2;
    %% three method
    % Restructure the predicted data
    for j = 1:methods-1 % the number of prediction methods (k-means and fitnet)
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
        g_y_predict = yPredict(hour).data;
        g_y_true = yTarget(hour).data;
        rng default  % For reproducibility
        nvars = methods-1;
        lb = [0,0,0];
        ub = [1,1,1];
        options = optimoptions('particleswarm', 'MaxIterations',2000,'FunctionTolerance', 1e-25, 'MaxStallIterations', 1500,'Display', 'none');
        objFunc = @(weight) objectiveFunc(weight, g_y_predict, g_y_true);
        [coeff(hour, :),~,~,~] = particleswarm(objFunc,nvars,lb,ub, options);   
    end
    %% four method
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
        g_y_predict = yPredict(hour).data;
        g_y_true = yTarget(hour).data;
        rng default  % For reproducibility
        nvars = methods;
        lb = [0,0,0,0];
        ub = [1,1,1,1];
        options = optimoptions('particleswarm', 'MaxIterations',2000,'FunctionTolerance', 1e-25, 'MaxStallIterations', 1500,'Display', 'none');
        objFunc = @(weight) objectiveFunc(weight, g_y_predict, g_y_true);
        [coeff4(hour, :),~,~,~] = particleswarm(objFunc,nvars,lb,ub, options);   
    end
    
    function total_err = objectiveFunc(weight, forecast, target) % objective function
        ensembleForecasted = sum(forecast.*weight, 2);  % add two methods
        err1 = sum(abs(target - ensembleForecasted));
        err2 = abs(1-sum(weight));
        total_err = err1+100*err2;
    end
%% save file
    s1 = 'PV_pso_coeff_';
    s2 = 'PV_pso_coeff4_';
    s3 = num2str(y_true(1,1)); % Get building index
    name(1).string = strcat(s1,s3);
    name(2).string = strcat(s2,s3);
    varX(1).value = 'coeff';
    varX(2).value = 'coeff4';
    for i = 1:size(varX,2)
        matname = fullfile(path,[name(i).string '.mat']);
        save(matname, varX(i).value);
    end
    end_pso_main = toc(start_pso_main)
end