% PV prediction: Model development algorithm 
function flag = PVset_setPVModel(LongTermPastData)
    start_all = tic;    
    %% Get file path
    path = fileparts(LongTermPastData);
    %% parameters
    Params = PVset_getParameters;
    ValidDays = Params.validDays; % it must be more than 1 day
    n_valid_data = 48*ValidDays; % total records = 24[hours]*2[record/hour]*days
    %% Load data
    if strcmp(LongTermPastData,'NULL') == 0    % if the filename is not null
        longPastdata = readmatrix(LongTermPastData);
        longPastdata = longPastdata(1:end,:);
    else  % if the fine name is null
        flag = -1; 
        return
    end
    %% Devide the data into training and validation
    % Transform the date into sin and cos form
    [row,~]=size(longPastdata);
    sin_data(:,1) = sin(longPastdata(:,5)/12*pi);
    cos_data(:,1) = cos(longPastdata(:,5)/12*pi);
    longPastdata=horzcat(longPastdata(:,1:6),sin_data,cos_data,longPastdata(:,7:14));
    
%     for PV_ID=15:27
    for PV_ID=1:1
        m=1;
        for n=1:row
            if longPastdata(n,1)==PV_ID
               longPast(m,:)=longPastdata(n,:);
               m=m+1;
            end
        end
        valid_data = longPast(end-n_valid_data+1:end, 1:15); 
        train_data = longPast(1:end-n_valid_data, 1:15); 
        valid_predictors = longPast(end-n_valid_data+1:end, 1:end-2);
        valid_data_opticalflow = longPast(end-n_valid_data+1:end, [1:14,16]);
    %% Train each model using past load data
        PVset_kmeans_Train(longPast, path);   
        PVset_ANN_Train(longPast, path);     
        PVset_LSTM_train(longPast, path);
    %% Validate the performance of each model
        start_Forecast = tic;
        for day = 1:ValidDays 
            TimeIndex = size(train_data,1)+1+48*(day-1);  % Indicator of the time instance for validation data in past_load, 
            short_past_load = longPast(TimeIndex-48*7+1:TimeIndex, 1:15); % size of short_past_load is always "672*11" for one week data set
            short_past_load_opticalflow = longPast(TimeIndex-48*7+1:TimeIndex, [1:14,16]);
            valid_predictor = valid_predictors(1+(day-1)*48:day*48, 1:end);  % predictor for 1 day (96 data instances)
            valid_predictor_opticalflow = valid_data_opticalflow(1+(day-1)*48:day*48, :);
            y_ValidEstIndv(1).data(:,day) = PVset_kmeans_Forecast(valid_predictor, short_past_load, path);
            y_ValidEstIndv(2).data(:,day) = PVset_ANN_Forecast(valid_predictor, short_past_load, path);
            y_ValidEstIndv(3).data(:,day) = PVset_LSTM_Forecast(valid_predictor,short_past_load, path);
            y_ValidEstIndv(4).data(:,day) = PVset_opticalflow_Forecast(valid_predictor_opticalflow,short_past_load_opticalflow, path);
        end
        end_Forecast = toc(start_Forecast)
    %% Optimize the coefficients for the additive model
        PVset_pso(y_ValidEstIndv, valid_data(:,[1 end]),path); 
    %% Integrate individual forecasting algorithms
        PVset_err_distribution(y_ValidEstIndv,valid_data,train_data,path);
        flag = 1;    % Return 1 when the operation properly works
        clearvars longPast;
        clearvars valid_data;
        clearvars train_data;
        clearvars valid_predictors;
    end
    end_all = toc(start_all)
end