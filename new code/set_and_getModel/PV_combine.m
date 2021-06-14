% y_ture: True load [MW]
% y_predict: predicted load [MW]
function save_data = PV_combine(y_predict, y_true, y_ValidEstIndv)
    start_combine = tic;   
    % Initialization
    methods = size(y_predict, 2);
    %% two method
    % Essential paramerters for PSO performance
    g_y_predict = y_predict(1:2);
    g_y_true = y_true;
    rng default  % For reproducibility
    nvars = methods-1;
    lb = [0,0];
    ub = [1,1];
    options = optimoptions('particleswarm', 'MaxIterations',2000,'FunctionTolerance', 1e-25, 'MaxStallIterations', 1500,'Display', 'none');
    objFunc = @(weight) objectiveFunc(weight, g_y_predict, g_y_true);
    [coeff,~,~,~] = particleswarm(objFunc,nvars,lb,ub, options);   
    %% three method
   % Essential paramerters for PSO performance
    g_y_predict = y_predict;
    g_y_true = y_true;
    rng default  % For reproducibility
    nvars = methods;
    lb = [0,0,0];
    ub = [1,1,1];
    options = optimoptions('particleswarm', 'MaxIterations',2000,'FunctionTolerance', 1e-25, 'MaxStallIterations', 1500,'Display', 'none');
    objFunc = @(weight) objectiveFunc(weight, g_y_predict, g_y_true);
    [coeff3,~,~,~] = particleswarm(objFunc,nvars,lb,ub, options);   
    
    function total_err = objectiveFunc(weight, forecast, target) % objective function
        ensembleForecasted = sum(forecast.*weight, 2);  % add two methods
        err1 = sum(abs(target - ensembleForecasted));
        err2 = abs(1-sum(weight));
        total_err = err1+100*err2;
    end
    %% Combined and Prediction interval
    % machine learning
    for i=1:methods-1
        if i==1
            yDetermPred2 = coeff(i).*y_ValidEstIndv(i).data(1);
        else
            yDetermPred2 = yDetermPred2 + coeff(i).*y_ValidEstIndv(i).data(1);  
        end
    end 
    % machine learning and optcalflow
    for i=1:methods
        if i==1
            yDetermPred3 = coeff3(i).*y_ValidEstIndv(i).data(1);
        else
            yDetermPred3 = yDetermPred3 + coeff3(i).*y_ValidEstIndv(i).data(1);  
        end
    end      
    save_data = horzcat(yDetermPred2,yDetermPred3);
    end_combine = toc(start_combine)
end