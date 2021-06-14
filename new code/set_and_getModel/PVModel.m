% PV prediction: Model development algorithm 
function flag = PVModel(LongTermPastData)
    start_all = tic;   
    %% Parameters
    train_day = 30; 
    valid_day = 30;
    ci_percentage = 0.05;
    first_ID = 1;
    season = 'summer'; % select season (spring  , summer , fall , winter )
    region =  'few' ; % select region (kanto  , chubu , kansai ,few )
    %% Load data
    load_name = strcat(region,'_',season,'.csv');
    LongPastdata = readmatrix(load_name);
    %% Get file path
    path = fileparts(LongTermPastData);
    %% Devide the data into training and validation
    [row_L,~]=size(LongPastdata);
    for i=1:row_L
        if LongPastdata(i,9) == 0 || LongPastdata(i,9) == 1 || LongPastdata(i,9) == 2 
            LongPastdata(i,9) = 0; %% sunny
        elseif LongPastdata(i,9) == 4 || LongPastdata(i,9) == 5
            LongPastdata(i,9) = 1; %% Sunny, sometimes cloudy
        elseif LongPastdata(i,9) > 5
            LongPastdata(i,9) = 2; %% cloudy or rain
        end     
    end
    longPastdata=horzcat(LongPastdata(:,[1 4:end])); 
    for PV_ID=first_ID:longPastdata(end,1)
        Number=num2str(PV_ID);
        m=1;
        for n=1:size(longPastdata)
            if longPastdata(n,1)==PV_ID                   
               longPast(m,:)=longPastdata(n,:);
               m=m+1;
            end
        end
        range = longPast(end,4)*2 - longPast(1,4)*2+1;
        % get err
        err_file_name = strcat('PV_err_',region,'_',season,'_',Number,'.mat');
        if isfile(err_file_name) == 0
            valid_data = longPast(end-range-train_day*range+1:end-range,1:end);
            train_data = longPast(end-range-(train_day+valid_day)*range+1:end-range-train_day*range,:);
            PVerr_distribution(valid_data,train_data,valid_day,range,err_file_name,path);
        end
        for forecast_time = 1:range
            forecast_data = longPast(end-range+forecast_time,1:end-2);
            target_data = longPast(end-range+forecast_time,end-1:end);
            train_data = longPast(end-range+forecast_time-train_day*range+1:end-range+forecast_time-1,:);
        %% Train each model using past load data    
            PVANN_Train(train_data, path);     
            PVLSTM_train(train_data, path);
        %% Validate the performance of each model 
            if forecast_time == 1
                last_day = longPast(end-range+forecast_time-1,1:end-2);
                target_last_data = longPast(end-range+forecast_time-1,end-1:end);        
                y_ValidEstIndv(1).data(:,1) = PVANN_Forecast(last_day,  path);
                y_ValidEstIndv(2).data(:,1) = PVLSTM_Forecast(last_day, path);
                y_ValidEstIndv(3).data(:,1) = target_last_data(2);
                last_day_data = horzcat(y_ValidEstIndv(1).data(1),y_ValidEstIndv(2).data(1),y_ValidEstIndv(3).data(1),target_last_data(1));
            end
            y_ValidEstIndv(1).data(:,1) = PVANN_Forecast(forecast_data,  path);
            y_ValidEstIndv(2).data(:,1) = PVLSTM_Forecast(forecast_data, path);
            y_ValidEstIndv(3).data(:,1) = target_data(2);            
            if forecast_time == 1
                save_data = PV_combine(last_day_data(1:3), last_day_data(end),y_ValidEstIndv); 
            else
                save_data = PV_combine(forecast_1day(end,2:4), forecast_1day(end,end),y_ValidEstIndv); 
            end           
            result_forecast = horzcat(forecast_data(1,4),y_ValidEstIndv(1).data(1)/1000,y_ValidEstIndv(2).data(1)/1000,y_ValidEstIndv(3).data(1)/1000,save_data/1000,target_data(1)/1000);
            if forecast_time==1
                forecast_1day = result_forecast;
            else
                forecast_1day = vertcat(forecast_1day,result_forecast);
            end
            %% Load err
            load(err_file_name);
            %% Make distribution of ensemble forecasting (two method)
            prob_prediction(1,:) = forecast_1day(forecast_time,5)+ err_2(forecast_time,:)/1000; 
            % Get Confidence Interval
            [L_boundary_2, U_boundary_2] = PV_ci(prob_prediction, ci_percentage); 
            %% Make distribution of ensemble forecasting (three method)
            prob_prediction(1,:) = forecast_1day(forecast_time,6)+ err_3(forecast_time,:)/1000;
            % Get Confidence Interval
            [L_boundary_3, U_boundary_3] = PV_ci(prob_prediction, ci_percentage);    
            boundaries_2(forecast_time,:) =  [L_boundary_2, U_boundary_2];  
            boundaries_3(forecast_time,:) =  [L_boundary_3, U_boundary_3];  
            %% Make graph
            if forecast_time==range
                error_data = PV_graph_eva(PV_ID,forecast_1day,boundaries_2,boundaries_3,range);
                if PV_ID == first_ID
                    evalution_data = error_data;
                else
                    evalution_data = vertcat(evalution_data,error_data);
                end
            end
            flag = 1;    % Return 1 when the operation properly works
            clearvars train_data;
            clearvars forecast_data;
            clearvars target_data;
            clearvars save_data;
            clearvars result_forecast;
        end
        if PV_ID == longPastdata(end,1)
            save_name = strcat(region,'_',season,'_','RMSE');
            save(all_eva_data,save_name)
        end
        clearvars longPast;  
    end
    end_all = toc(start_all)
end