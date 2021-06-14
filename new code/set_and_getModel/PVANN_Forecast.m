function target = PVANN_Forecast(predictor,path)    
    %% load .mat file   
    building_num = num2str(predictor(1,1));
    load_name = '\PV_fitnet_ANN_';
    load_name = strcat(path,load_name,building_num,'.mat');
    load(load_name,'-mat');
    %% ForecastData
    predictors=predictor;
    [time_steps, ~]= size(predictors);
  %% Forecast PV using ANN
    % use ANN 3 times for reduce ANN's error
    for i_loop = 1:3
        net_PV_ANN = net_PV_ANN_loop{i_loop};
        result_PV_ANN_loop = zeros(time_steps,1);
        for i = 1:time_steps
                x2_ANN = transpose(predictors(i,feature2));
                result_PV_ANN_loop(i,:) = net_PV_ANN(x2_ANN);
        end
        result_PV_ANN{i_loop} = result_PV_ANN_loop;
    end
    result_PV_ANN_premean = result_PV_ANN{1}+result_PV_ANN{2}+result_PV_ANN{3};
    result_PV_ANN_mean = max(result_PV_ANN_premean/3,0);   
    %% ResultingData File
    ResultingData_ANN = predictors(:,1:end);
    ResultingData_ANN(:,end+1) = result_PV_ANN_mean;
    target = ResultingData_ANN(1:time_steps,end);
end