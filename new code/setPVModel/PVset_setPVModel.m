% PV prediction: Model development algorithm 
function flag = PVset_setPVModel(LongTermPastData)
    start_all = tic;    
    %% Get file path
    path = fileparts(LongTermPastData);
    %% parameters
    ValidDays = 30; % it must be above 1 day. 3days might provide the best performance
    n_valid_data = 48*ValidDays; % 24*2*day
    %% Load data
    if strcmp(LongTermPastData,'NULL') == 0    % if the filename is not null
        longPastdata = readmatrix(LongTermPastData);
        longPastdata = longPastdata(1:end,:);
    else  % if the fine name is null
        flag = -1; 
        return
    end
    %% Devide the data into training and validation
    [row,~]=size(longPastdata);
    for PV_ID=5:27
        m=1;
        for n=1:row
            if longPastdata(n,1)==PV_ID
               longPast(m,:)=longPastdata(n,:);
               m=m+1;
            end
        end       
        valid_data = longPast(end-n_valid_data+1:end, 1:13); 
        train_data = longPast(1:end-n_valid_data, 1:13); 
        valid_predictors = longPast(end-n_valid_data+1:end, 1:end-2);
        valid_data_opticalflow = longPast(end-n_valid_data+1:end, [1:12,14]);
    %% Train each model using past load data
        PVset_kmeans_Train(longPast, path);   
        PVset_ANN_Train(longPast, path);     
        PVset_LSTM_train(longPast, path);
    %% Validate the performance of each model
        start_Forecast = tic;
        g=waitbar(0,'PVset Forecasting(forLoop)','Name','PVset Forecasting(forLoop)');   
        for day = 1:ValidDays 
            waitbar(day/ValidDays,g,'PVset Forecasting(forLoop)');
            TimeIndex = size(train_data,1)+1+48*(day-1);  % Indicator of the time instance for validation data in past_load, 
            short_past_load = longPast(TimeIndex-48*7+1:TimeIndex, 1:13); % size of short_past_load is always "672*11" for one week data set
            short_past_load_opticalflow = longPast(TimeIndex-48*7+1:TimeIndex, [1:12,14]);
            valid_predictor = valid_predictors(1+(day-1)*48:day*48, 1:end);  % predictor for 1 day (96 data instances)
            valid_predictor_opticalflow = valid_data_opticalflow(1+(day-1)*48:day*48, :);
            y_ValidEstIndv(1).data(:,day) = PVset_kmeans_Forecast(valid_predictor, short_past_load, path);
            y_ValidEstIndv(2).data(:,day) = PVset_ANN_Forecast(valid_predictor, short_past_load, path);
            y_ValidEstIndv(3).data(:,day) = PVset_LSTM_Forecast(valid_predictor,short_past_load, path);
            y_ValidEstIndv(4).data(:,day) = PVset_opticalflow_Forecast(valid_predictor_opticalflow,short_past_load_opticalflow, path);
        end
        close(g)  
        end_Forecast = toc(start_Forecast)
    %% Optimize the coefficients for the additive model
        PVset_pso_main(y_ValidEstIndv, valid_data(:,[1 end]),path); 
    %% Integrate individual forecasting algorithms
        PVset_err_distribution(y_ValidEstIndv,valid_data,valid_predictors,ValidDays,path);
        flag = 1;    % Return 1 when the operation properly works
        clearvars longPast;
        clearvars valid_data;
        clearvars train_data;
        clearvars valid_predictors;
    end
    end_all = toc(start_all)
end