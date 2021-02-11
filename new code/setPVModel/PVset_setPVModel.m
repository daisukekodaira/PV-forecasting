% PV prediction: Model development algorithm 
function flag = PVset_setPVModel(LongTermPastData)
    start_all = tic;    
    %% Get file path
    path = fileparts(LongTermPastData);
    %% parameters
    test_days = 30; % it must be above 1 day. 3days might provide the best performance
    first_ID=15;
    %% Load data
    if strcmp(LongTermPastData,'NULL') == 0    % if the filename is not null
        longPastdata = readmatrix(LongTermPastData);
    else  % if the fine name is null
        flag = -1; 
        return
    end
    %% Devide the data into training and validation
    [row_L,~]=size(longPastdata);
    for i=1:row_L
        if longPastdata(i,10) == 0 || longPastdata(i,10) == 1 || longPastdata(i,10) == 2 
            longPastdata(i,10) = 0; %% sunny
        elseif longPastdata(i,10) == 4 || longPastdata(i,10) == 5
            longPastdata(i,10) = 1; %% Sunny, sometimes cloudy
        elseif longPastdata(i,10) > 5
            longPastdata(i,10) = 3; %% cloudy or rain
        end
    end
    sin_data(:,1) = sin(longPastdata(:,5)/12*pi);
    cos_data(:,1) = cos(longPastdata(:,5)/12*pi);
    longPastdata=horzcat(longPastdata(:,1:6),sin_data,cos_data,longPastdata(:,9:14)); % remove mois and wind
    for PV_ID=first_ID:27
        m=1;
        for n=1:row_L
            if longPastdata(n,1)==PV_ID
               longPast(m,:)=longPastdata(n,:);
               m=m+1;
            end
        end             
        long_test_data = longPast(1:48*test_days,:);
        train_data = longPast(48*test_days+1:end,:);
    %% Train each model using past load data
        PVset_kmeans_Train(train_data, path);   
        PVset_ANN_Train(train_data, path);     
        PVset_LSTM_train(train_data, path);
    %% Validate the performance of each model (test)
        start_Forecast = tic;
        for day = 1:test_days 
            short_test_data = long_test_data(48*day-47:48*day,:);
            y_ValidEstIndv(1).data(:,day) = PVset_kmeans_Forecast(short_test_data,  path);
            y_ValidEstIndv(2).data(:,day) = PVset_ANN_Forecast(short_test_data,  path);
            y_ValidEstIndv(3).data(:,day) = PVset_LSTM_Forecast(short_test_data, path);
            y_ValidEstIndv(4).data(:,day) = short_test_data(:,end);
        end
        end_Forecast = toc(start_Forecast)
    %% Optimize the coefficients for the additive model
        PVset_pso_main(y_ValidEstIndv, long_test_data(:,[1 end-1]),path); 
    %% Integrate individual forecasting algorithms
        PVset_err_distribution(y_ValidEstIndv,long_test_data(:,1:end-1),train_data,path);
        flag = 1;    % Return 1 when the operation properly works
        clearvars longPast;
        clearvars long_test_data;
        clearvars train_data;
        clearvars short_test_data;
    end
    end_all = toc(start_all)
end