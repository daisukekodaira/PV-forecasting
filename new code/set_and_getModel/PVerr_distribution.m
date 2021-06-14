    %% Integrate individual forecasting algorithms
    function PVerr_distribution(valid_data,train_data,valid_day,range,err_file_name,path)
        start_err_distribution = tic;    
        Train_data = train_data;
        for day = 1:valid_day
            for forecast_time = 1:range
                forecast_data = valid_data(22*(day-1)+forecast_time,1:end-2);
                target_data = valid_data(22*(day-1)+forecast_time,end-1:end);
            %% Train each model using past load data    
                PVANN_Train(Train_data, path);     
                PVLSTM_train(Train_data, path);
            %% Validate the performance of each model 
                if forecast_time == 1 && day == 1
                    last_day = Train_data(end-range*2+forecast_time,1:end-2);
                    target_last_data = Train_data(end-range*2+forecast_time,end-1:end);        
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
                result_forecast = horzcat(forecast_data(1,4),y_ValidEstIndv(1).data(1),y_ValidEstIndv(2).data(1),y_ValidEstIndv(3).data(1),save_data,target_data(1));
                if forecast_time==1
                    forecast_1day = result_forecast;
                else
                    forecast_1day = vertcat(forecast_1day,result_forecast);
                end
                Train_data = vertcat(train_data,valid_data(1:22*(day-1)+forecast_time,:));
            end
            if day==1
                forecast_all_day_2 = forecast_1day(:,5);
                forecast_all_day_3 = forecast_1day(:,6);
                real_all_day = forecast_1day(:,end);
            else
                forecast_all_day_2 = horzcat(forecast_all_day_2,forecast_1day(:,5));
                forecast_all_day_3 = horzcat(forecast_all_day_3,forecast_1day(:,6));
                real_all_day = horzcat(real_all_day,forecast_1day(:,end));
            end
            clearvars forecast_1day;
        end
        %% three method   
        % error from validation data[%] error[%] 
        err_2 = forecast_all_day_2 - real_all_day; 
        %% four method
        % error from validation data[%] error[%], hours, Quaters    
        err_3 = forecast_all_day_3 - real_all_day;
       %% save file
        save_name = strcat(err_file_name);
        save(save_name,'err_2','err_3')
        end_err_distribution = toc(start_err_distribution)
    end