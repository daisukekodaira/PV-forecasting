% y_ture: True load [MW]
% y_predict: predicted load [MW]
function coeff = PVset_pso_main(y_predict, y_true)
    start_pso_main = tic;
    % Declare the global variables
    global g_y_true;
    global g_y_predict;    
    % Initialization
    methods = size(y_predict, 2);
    days = size(y_predict(1).data,2);   
    % Restructure the predicted data
    for j = 1:methods % the number of prediction methods (k-means and fitnet)
        for hour = 1:24
            yPredict(hour).data(:,j) = reshape(y_predict(j).data(1+(hour-1)*4:hour*4,:), [],1); % this global variable is utilized in 'objective_func'
        end
    end   
   % Restructure the target data
   for day = 1:days
       initial = 1+(day-1)*96;
       for hour = 1:24    
           yTarget(hour).data(1+(day-1)*4:4*day,1) = reshape(y_true(initial+(hour-1)*4:initial-1+hour*4,:), [],1); 
       end
   end
                % Essential paramerters for PSO performance
    for hour = 1:24
        g_y_predict = yPredict(hour).data;
        g_y_true = yTarget(hour).data;
        objFunc = @(weight) objectiveFunc(weight, g_y_predict, g_y_true);
        rng default  % For reproducibility
        nvars = 3;
        lb = [0, 0, 0];
        ub = [1, 1, 1];
        options = optimoptions('particleswarm', 'MaxIterations',2000,'FunctionTolerance', 1e-25, 'MaxStallIterations', 1500,'Display', 'none');
        [coeff(hour, :),~,~,~] = particleswarm(objFunc,nvars,lb,ub, options);    
    end
    function err = objectiveFunc(weight, forecast, target)
    % objective function
    ensembleForecasted = sum(forecast.*weight, 2);  % add two methods
    err = sum(abs(target - ensembleForecasted));
    % err = max(abs(target - ensembleForecasted));
    end
    end_pso_main = toc(start_pso_main)
end