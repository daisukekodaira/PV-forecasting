% Load prediction: Foecasting algorithm 
% function flag = demandForecast(shortTermPastData, ForecastData, ResultData)
%     flag =1 ; if operation is completed successfully
%     flag = -1; if operation fails.
%     This function depends on demandModel.mat. If these files are not found return -1.
%     The output of the function is "ResultData.csv"
function flag = PVget_getPVModel(forecastData)
    tic;    
    %% Load data
    if  strcmp(forecastData, 'NULL') == 0 
        predictors = csvread(forecastData,1,0);
    else
        flag = -1;
        return
    end     
    target = csvread('TargetData.csv',1,0);   
    [row_i,~]=size(predictors);
    [row_k,~]=size(target);
    for i=1:row_i
        if predictors(i,10) == 0 || predictors(i,10) == 1 || predictors(i,10) == 2 
            predictors(i,10) = 0; %% sunny
        elseif predictors(i,10) == 4 || predictors(i,10) == 5
            predictors(i,10) = 1; %% Sunny, sometimes cloudy
        elseif predictors(i,10) > 5
            predictors(i,10) = 3; %% cloudy or rain
        end
    end
    sin_data(:,1) = sin(predictors(:,5)/12*pi);
    cos_data(:,1) = cos(predictors(:,5)/12*pi);
    predictors=horzcat(predictors(:,1:6),sin_data,cos_data,predictors(:,9:end));
    first_ID = 15;
    for PV_ID=first_ID:27
        i=1;
        k=1;
        for n=1:row_i
            if predictors(n,1)==PV_ID
               ForecastData(i,:)=predictors(n,:);
               i=i+1;
            end
        end   
        for n=1:row_k
            if target(n,1)==PV_ID
               targetdata(k,:)=target(n,:);
               k=k+1;
            end
        end 
    %% Load .mat files from given path of "forecastData"
        filepath = fileparts(forecastData);    
    %% Prediction for test data   
        predicted_PV(1).data = PVget_kmeans_Forecast(ForecastData,  filepath);   
        predicted_PV(2).data = PVget_ANN_Forecast(ForecastData, filepath);   
        predicted_PV(3).data = PVget_LSTM_Forecast(ForecastData, filepath);   
        predicted_PV(4).data = targetdata(:,3);
    %% PV forecast 
        RMSE=PVget_Forecast(predicted_PV,PV_ID,targetdata(:,2),forecastData);  
    %% PV forecast (combined)  
        evaluation=PVget_Forecast_combined(predicted_PV,ForecastData,PV_ID,targetdata(:,2),forecastData); 
    %% correct error data
        error_data = horzcat(PV_ID,evaluation,RMSE);
        if PV_ID==first_ID
            data=error_data;
        else
            data=vertcat(data,error_data);
        end
        flag = 1;
        clearvars shortTermPastData;
        clearvars ForecastData;
        clearvars observed;
        clearvars targetdata;
        clearvars opticalflow_Forecast;
        clearvars yDetermPred3;
        clearvars yDetermPred4;
        clearvars prob_prediction;
    end
    data=array2table(data);
    data.Properties.VariableNames{'data1'} = 'ID';
    data.Properties.VariableNames{'data2'} = 'PICoverRate(machine)';
    data.Properties.VariableNames{'data3'} = 'PICoverRate(machine)';
    data.Properties.VariableNames{'data4'} = 'RMSE(machine)';
    data.Properties.VariableNames{'data5'} = 'RMSE(with optical flow)';
    data.Properties.VariableNames{'data6'} = 'RMSE(k)';
    data.Properties.VariableNames{'data7'} = 'RMSE(NN)';
    data.Properties.VariableNames{'data8'} = 'RMSE(LSTM)';
    data.Properties.VariableNames{'data9'} = 'RMSE(opt)';
    savename=strcat('errordata.csv');
    writetable(data,savename) 
    toc; 
end