% ---------------------------------------------------------------------------
% PV forecast: Prediction Model development algorithm 
% Contact: daisuke.kodaira03@gmail.com
% 
% function flag =setPVModel(LongTermPastData)
%         flag =1 ; if operation is completed successfully
%         flag = -1; if operation fails.
% ----------------------------------------------------------------------------

function setPVModel(LongTermPastData)
    tic;
    warning('off','all');   % Warning is not shown
    
    %% Get file path
    path = fileparts(LongTermPastData);     
    
    %% Load data
    if strcmp(LongTermPastData, 'NULL') == 0    % if the filename is not null
        TableAllPastData = readtable(LongTermPastData);
    else  % if the fine name is null
        flag = -1;  % return error
        return
    end 
     
    %% Data preprocessing
    %     TableAllPastData = preprocess(T);
    
    %% Devide the data into training and validation
    % Parameter
    ValidDays = 3; % it must be above 1 day. 3days might provide the best performance
    nValidData = 22*ValidDays; % 22 time frame in a day.valid_data = longPast(end-n_valid_data+1:end, :); 
    colPredictors = {'PV_ID', 'PV_ID_original', 'Season', 'Year', 'Month', ...
                               'Day', 'Time', 'Tempreature', 'Precipitation', 'Weather'};
        
    %% Data restructure
    % Arrange the structure to be sotred for all data
    allData.Predictor = TableAllPastData(:, colPredictors);
    allData.Target = table2array(TableAllPastData(:, {'Observed'})); % trarget Data for validation (targets only)
    allData.OpticalFlow = table2array(TableAllPastData(:, {'ForecastOpticalFlow'})); % Forecasted result by optical flow
    
    % Divide all past data into training and validation
    trainData = TableAllPastData(1:end-nValidData, :);     % training Data (predictors + target)
    validData.Predictor = TableAllPastData(end-nValidData+1:end, colPredictors);    % validation Data (predictors only)
    validData.Target = table2array(TableAllPastData(end-nValidData+1:end, {'Observed'})); % trarget Data for validation (targets only)
    validData.OpticalFlow = table2array(TableAllPastData(end-nValidData+1:end, {'ForecastOpticalFlow'}));
    
    %% Train each model using past load data
    kmeansPV_Training(trainData, colPredictors, path);
    neuralNetPV_Training(trainData, colPredictors, path);
    %     LSTMEV_Training();    % add LSTM here later
    
    %% Validate the performance of each model
    % Note: return shouldn't be located inside of structure. It should be sotred as matrix.
    %           This is because it makes problem after .m files is converted into java files 
    % 1. k-means
    % 2. Neural net
    % 3. Optical flow
    [validData.Pred(:,1)]  = kmeansPV_Forecast(validData.Predictor, path);
    [validData.Pred(:,2)] = neuralNetPV_Forecast(validData.Predictor, path); 
    [validData.Pred(:,3)] = table2array(TableAllPastData(end-nValidData+1:end, {'ForecastOpticalFlow'}));  % Get optical flow result
    %     [validData.Pred(:,4)] = LSTMPV_Forecast(validData.Predictor, path); % add LSTM here later
    
    %% Optimize the coefficients (weights) for the ensembled forecasting model
    weight.ML = getWeight(validData.Predictor, validData.Pred(:,1:2), validData.Target); % only Machine learning
    weight.All = getWeight(validData.Predictor, validData.Pred, validData.Target);  % Machine learining + optical flow
        
    %% Get error distribution for validation data 
    %     % Calculate error from validation data
    %      [validData.errDistML, validData.errML] = getErrorDist(validData, weight.ML);
    %      [validData.errDistAll, validData.errAll] = getErrorDist(validData, weight.All);
                       
    %% Get error distribution for all past data (training+validation data)
    % Get forecasted result from each method
    [allData.Pred(:,1)]  = kmeansPV_Forecast(allData.Predictor, path);
    [allData.Pred(:,2)] = neuralNetPV_Forecast(allData.Predictor, path);   
    [allData.Pred(:,3)] =  allData.OpticalFlow;
    [allData.errDist, allData.ensembledPred]= getErrorDist(allData, weight.ML);
    [allData.errDist, allData.ensembledPred]= getErrorDist(allData, weight.All);

    % Get neural network for PI 
    % this part is under configuration 2021/4/15 --------------------------
    %     getPINeuralnet(allData);
    % ----------------------------------------------------------------
    
    
    %% Save .mat files
    filename = {'EV_trainingData_', 'EV_weight_'};
    Bnumber = num2str(TableAllPastData.BuildingIndex(1)); % Get building index to add to fine name
    varX = {'allData', 'weight'};
    for i = 1:size(varX,2)
        name = strcat(filename(i), Bnumber, '.mat');
        matname = fullfile(path, name);
        save(char(matname), char(varX(i)));
    end
    
%     % for debugging --------------------------------------------------------
%     % Under construction 2020 June 16th
%         display_result(1:size(nValidData,1), ensembledPredEnergy, validData.Target, [], 'EnergyTrans'); % EnergyTrans
%         display_result(1:size(nValidData,1), ensembledPredSOC, validData.TargetSOC, [], 'SOC'); % SOC 
%     % for debugging --------------------------------------------------------------------- 
    
    toc;
end
