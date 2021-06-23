function [pred] = neuralNetPV_Forecast(forecastData, path)

    %     % Display for user
    %     disp('Validating the Neural Network model....');


    %% Read Input data
    % get building number
    pvID = num2str(forecastData.PV_ID(1));
    % load a '.mat' file
    load_name = '\PV_trainedNeuralNet_';
    load_name = strcat(path,load_name,pvID,'.mat');
    load(load_name,'-mat');

    %% Forecast 
    % use ANN 3 times for reduce ANN's error
    forecastData = table2array(forecastData);
    pred = getAverageOfMultipleForecast(trainedNet, forecastData);
    %     % Display for user    
    %     disp('Validating the Neural Network model.... Done!');

end

function forecastResultAverage = getAverageOfMultipleForecast(trainedNetAll, forecastData)
    % get the number of records in forecastData
    [time_steps, ~]= size(forecastData);
    % get how many multiple results will be taken average
    maxLoop = size(trainedNetAll,2);
    % Perform the multiple forecasting with trained network
    for i_loop = 1:maxLoop
        trainedNetInd = trainedNetAll{i_loop};
        for i = 1:time_steps
                forecastResultIndvidual(i,:) = trainedNetInd(transpose(forecastData(i, :)));
        end
        forecastResultAll(:,i_loop) = forecastResultIndvidual;
    end
    % Take average and erase the minus value
    forecastResultAverage = max( sum(forecastResultAll, 2)./maxLoop, 0);
    
    %% Error correction
    % To be implemented ------------------------------------------------------------------------------------------------
    %     [result1,result2] = error_correction_sun(predictors, result_PV_ANN_mean, shortTermPastData, path);
    % -------------------------------------------------------------------------------------------------------------
end