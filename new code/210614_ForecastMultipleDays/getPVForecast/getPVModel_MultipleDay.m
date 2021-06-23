% ---------------------------------------------------------------------------
% PV Foecasting algorithm 
% Contact: daisuke.kodaira03@gmail.com
%
% function flag = demandForecast(shortTermPastData, ForecastData, ResultData)
%     flag =1 ; if operation is completed successfully
%     flag = -1; if operation fails.
%     This function depends on '.mat' files. If these files are not found return -1.
%     The output of the function is "resultEVData.csv"
% ----------------------------------------------------------------------------

function [PICoverRate, MAPE, RMSE, PIWidth, outTable] = getPVModel_MultipleDay(shortTermTable, predictorTable, targetTable)  
    % parameters
    pvID = shortTermTable.PV_ID(1);
    ci_percentage = 0.05; % 0.05 = 95% it must be between 0 to 1
    
    %% Error recognition: Check mat files exist
    name1 = [pwd, '\', 'PV_trainedKmeans_', num2str(pvID), '.mat'];
    name2 = [pwd, '\', 'PV_trainedNeuralNet_', num2str(pvID), '.mat'];
    name3 = [pwd, '\', 'PV_trainingData_', num2str(pvID), '.mat'];
    name4 = [pwd, '\', 'PV_weight_', num2str(pvID), '.mat'];
    if exist(name1) == 0 || exist(name2) == 0 || exist(name3) == 0 || exist(name4) == 0 
        flag = -1;
        disp('There are missing .mat files from setPV');
        return
    end
    
    %% Load mat files
    s(1).fname = 'PV_trainedKmeans_';
    s(2).fname = 'PV_trainedNeuralNet_';
    s(3).fname = 'PV_trainingData_';
    s(4).fname = 'PV_weight_';
    s(5).fname = num2str(pvID);    
    extention='.mat';
    for i = 1:size(s,2)-1
        name(i).string = strcat(s(i).fname, s(end).fname);
        matname = fullfile(pwd, [name(i).string extention]);
        load(matname);
    end
    
    %% Get individual prediction for test data
    % Two methods are combined
    %   1. k-menas
    %   2. Neural network
    [predData.Ind(:,1)]  = kmeansPV_Forecast(predictorTable, pwd);
    [predData.Ind(:,2)] = neuralNetPV_Forecast(predictorTable, pwd);  
    
    %% Get combined prediction result with weight for each algorithm
    % Prepare the tables to store the deterministic forecasted result (ensemble forecasted result)
    % Note: the forecasted results are stored in an hourly basis
    predData.Ensemble = NaN(size(predictorTable, 1), 1);                
    records = size(predData.Ind, 1);
    % generate ensemble forecasted result
    for i = 1:records
        hour =predictorTable.Hour(i)+1;   % transpose Hour from 0~23 to 1~24
        predData.EnsembleML(i) = sum(weight.ML(hour,:).*predData.Ind(i, :));
        predData.EnsembleAll(i) = sum(weight.All(hour,:).*predData.Ind(i, :));
    end
    % Get Prediction Interval
    % 1. Confidence interval basis method
    % Note: Method1 utilizes the error distribution derived from one month
    %            validation data which is not concained in the training process
    [predData.MLPImean, predData.MLPImin, predData.MLPImax] = getPI(predictorTable, predData.EnsembleML, allData.errDistML);
    [predData.AllPIBootmin, predData.AllPIBootmax] = getPIBootstrap(predictorTable, predData.EnsembleAll, allData.errDistAll);
    %     % 2. Neural Network basis method
    %     % Note: Method2 utilized the error distribution deriveved from all past
    %     %           data which is utilized for trining process in ensemble forecastin model 
    %     [predData.EnergyPImean, predData.EnergyPImin, predData.EnergyPImax] = getPINeuralNet(predictorTable, predData.EnsembleEnergy,  allData.errDistEnergy);
    
    %% Write  down the forecasted result in csv file
    outTable = [predictorTable, struct2table(predData), targetTable];

    %% Get forecast performance summary
    MLPI =  [predData.MLPImin, predData.MLPImax];
    AllPI =  [predData.AllPImin, predData.AllPImax];

    % Energy demand (ensembled)
    [PICoverRate.ensembleML, MAPE.ensembleML, RMSE.ensembleML, PIWidth.ensembleML] = getDailyPerformance(MLPI, predData.EnsembleML, targetTable.Observed);
    [PICoverRate.ensembleAll, MAPE.ensembleAll, RMSE.ensembleAll, PIWidth.ensembleAll] = getDailyPerformance(AllPI, predData.EnsembleAll, targetTable.Observed);

    % Energy emand (k-means)
    [~, MAPE.kmeans, RMSE.kmeans, ~] = getDailyPerformance([], predData.Ind(:,1), targetTable.Observed);
    % Energy demand (Neural Network)
    [~, MAPE.neuralNet, RMSE.neuralNet, ~] = getDailyPerformance([], predData.Ind(:,2), targetTable.Observed);
    % SOC   
    %     [PICoverRate.ensemble, MAPE.ensemble] = getDailyPerformance(socPI, predData.EnsembleEnergy, targetTable.EnergyDemand, ci_percentage);
    
end
