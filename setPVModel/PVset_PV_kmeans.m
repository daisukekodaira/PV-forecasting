function y = PVset_PV_kmeans(flag,input,shortTermPastData,path)
% tic;
% disp('Matlab demand call function')
feature = 2:7;
if flag == 1
   PastDataExcelFile = input; % matrix
   new_format_PastData = PastDataExcelFile(1:(end-96*7),:); % PastData load
   [m_new_format_PastData, ~]= size(new_format_PastData);% PastData size
       % if there is no 1 day past data
    if m_new_format_PastData < 96

        new_format_PastData(1:96,1) = new_format_PastData(1,1); % building ID
        new_format_PastData(1:96,2) = new_format_PastData(1,2);
        new_format_PastData(1:96,3) = new_format_PastData(1,3);
        new_format_PastData(1:96,4) = new_format_PastData(1,4);

        new_format_PastData(1:96,5) = transpose([0 0 0 1 1 1 1 2 2 2 2 3 3 3 3 4 4 4 4 5 5 5 5 6 6 6 6 7 7 7 7 8 8 8 8 9 9 9 9 10 10 10 10 ...
            11 11 11 11 12 12 12 12 13 13 13 13 14 14 14 14 15 15 15 15 16 16 16 16 17 17 17 17 18 18 18 18 ...
            19 19 19 19 20 20 20 20 21 21 21 21 22 22 22 22 23 23 23 23 0]);

        new_format_PastData(1:96,6) = transpose([1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 ...
            1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0]);

        new_format_PastData(1:96,7) = new_format_PastData(1,7);
        new_format_PastData(1:96,8) = new_format_PastData(1,8);
        new_format_PastData(1:96,9) = new_format_PastData(1,9);
        new_format_PastData(1:96,10) = new_format_PastData(1,10);

        new_format_PastData(1:96,11) = mean(new_format_PastData(1:m_new_format_PastData,11)); % demand
    end
 %% Format change        
    % format_change_1 : new -> old
    old_format_PastData = PVset_format_change_1(new_format_PastData);
%% Train model    
[m_old_format_PastData, ~] = size(old_format_PastData);
if m_old_format_PastData <= 30
      k_pv = 2;
     [idx_PastData,c_PastData_pv] = kmeans(old_format_PastData(:,7:102),k_pv);       % k-means past data index
     train_feature = old_format_PastData(1:end,feature);                                 % feature
     train_label = idx_PastData(1:end,1);                                     % class index
     nb_pv = fitcnb(train_feature,train_label,'Distribution','kernel');     % train model
end
for i_loop = 1:1:3
        %% choose k
        if (m_old_format_PastData) >= 31
            if abs(var(old_format_PastData(:,8:103))) < 10
                if var(abs(var(old_format_PastData(:,8:103)))) < 0.5
                    kkk_start = abs(round(var(old_format_PastData(:,8:103))));
                    kkk_stop = abs(round(var(old_format_PastData(:,8:103)))); + 1;
                else
                    kkk_start = 5;
                    kkk_stop = 10;
                end
            else
                if var(abs(log10(var(old_format_PastData(:,8:103))))) < 0.5
                    kkk_start = abs(round(mean(log10(var(old_format_PastData(:,8:103)))))) - 1;
                    kkk_stop = abs(round(mean(log10(var(old_format_PastData(:,8:103)))))) + 1;
                else
                    kkk_start = 5;
                    kkk_stop = 10;
                end
            end
            
            result_MAPE = zeros(kkk_stop,1);
            for kkk = kkk_start:1:kkk_stop
            %% Divide data train, valid
                % 100% : total
            raw_100_PastData = old_format_PastData;
            [m_raw_100_PastData, ~] = size(raw_100_PastData);
            m_raw_70_PastData = round(m_raw_100_PastData * 0.7);
            m_raw_30_PastData = m_raw_100_PastData - m_raw_70_PastData;
            % 70% : train, 30% : validate
            raw_70_PastData = raw_100_PastData(1:m_raw_70_PastData,:);
            raw_30_PastData = raw_100_PastData(m_raw_70_PastData+1:end,:);
            % check again the size of raw_PastData because of delete
            [m_pv_check, ~] = size(raw_70_PastData);
            
            %% k-means past train data 
            [idx_PastData,c_PastData] = kmeans(raw_70_PastData(:,8:103),kkk);
            idx_PastData_pv_array{kkk} = idx_PastData;
            c_PastData_pv_array{kkk} = c_PastData;
            train_feature = raw_70_PastData(1:end,feature);                                               % feature
            train_label = idx_PastData(1:end,1);                                                   % class index
            nb_pv_array{kkk} = fitcnb(train_feature,train_label,'Distribution','kernel');        %# train model
       %% Test(to make err data)
           % ForecastData
            raw_ForecastData = raw_30_PastData;
            [m_raw_ForecastData, ~] = size(raw_30_PastData);
            % Clustering
            % for test
            result_cluster_idx = zeros(m_raw_ForecastData,1);
            result_cluster_1D_day = zeros(m_raw_ForecastData,96);
            
            for i = 1:1:m_raw_ForecastData
               test_1D_day_feature(i,:) = raw_ForecastData(i,feature); % feature
                %# prediction
               result_cluster_idx(i,1) = nb_pv_array{kkk}.predict(test_1D_day_feature(i,:));
               result_cluster_1D_day(i,:) = c_PastData(result_cluster_idx(i,:),:);
            end
       %% Result err data
             result_cluster_1D_day_array{kkk} = result_cluster_1D_day;
            result_err_data_array{kkk} =  raw_30_PastData(:,8:103) - result_cluster_1D_day_array{kkk}; % real - forecast
            err_rate_kkk = result_err_data_array{kkk} ./ raw_30_PastData(:,8:103);
            abs_err_rate_kkk = abs(err_rate_kkk);  
            result_MAPE(kkk,1) = sum(mean(abs_err_rate_kkk))/96;
            end
            result_MAPE(~any(result_MAPE(:,1),2),1) = 100;
            min_MAPE = min(result_MAPE);
            [i_min_MAPE,~] = find(result_MAPE==min_MAPE);
            [m_i_min_MAPE,~] = size(i_min_MAPE);
            if m_i_min_MAPE > 1
                kkk = max(i_min_MAPE);
            else
                kkk = i_min_MAPE;
            end   
        %%  Train again (to update optimal kkk model)
%       idx_PastData_pv = idx_PastData_pv_array{kkk};
        c_PastData_pv_save = c_PastData_pv_array{1,kkk};
        nb_pv_save = nb_pv_array{kkk};
        % make err using 30% past data to train ECF
        for i = 1:m_raw_30_PastData
            for j = 1:96
                new_result_err_data(j+(i-1)*96,1) = result_err_data_array{kkk}(i,j);
                raw_30_ForecastData(j+(i-1)*96,1) = result_cluster_1D_day_array{kkk}(i,j);
            end
        end
        err_PastData(:,1:11) = new_format_PastData(end-size(new_result_err_data,1)+1:end,1:11);
        err_PastData(:,12) = new_result_err_data;
        % save name
        building_num = num2str(PastDataExcelFile(2,1));
        Name = 'err_correction_kmeans_bayesian_';
        Name = strcat(Name,building_num,'.mat');
        PVset_err_correction_ANN(1,err_PastData,Name,path);    
        % PastData , Train work space data will save like .mat file
        % loop
        nb_pv_loop{i_loop} = nb_pv_save;
        c_PastData_pv_loop{i_loop} = c_PastData_pv_save;
        err_PastData_loop{i_loop} = err_PastData;
%         clearvars nb_week nb_pv_array nb_pv_save
%         clearvars c_PastData_pv c_PastData_pv_array c_PastData_pv_save
%         clearvars err_PastData
        end
end
    if (m_old_format_PastData) < 31
        clearvars input;
        clearvars shortTermPastData;
        building_num = num2str(PastDataExcelFile(2,1));
        save_name = '\PV_Model_';
        save_name = strcat(path,save_name,building_num,'.mat');
        save(save_name,'nb_pv','c_PastData_pv'...
            ,'feature','err_PastData','raw_30_ForecastData');
    else
        clearvars input;
        clearvars shortTermPastData;
        building_num = num2str(PastDataExcelFile(2,1));
        save_name = '\PV_Model_';
        save_name = strcat(path,save_name,building_num,'.mat');
        save(save_name,'raw_30_ForecastData','nb_pv_loop','c_PastData_pv_loop'...
        ,'feature','err_PastData_loop');
    end
else
      %% load .mat file
      %#function ClassificationNaiveBayes
    ForecastExcelFile = input;
    building_num = num2str(ForecastExcelFile(2,1));
    load_name = '\PV_Model_';
    load_name = strcat(path,load_name,building_num,'.mat');
    load(load_name,'-mat');
    %% ForecastData
    % ForecastData load
    new_version_ForecastData = ForecastExcelFile;
    % ForecastData size
    [m_new_veresion_ForecastData, ~]= size(new_version_ForecastData);
    % Feature data
    j = 1;
    % using day type we can find period of forecast
    Forecast_day = 1;
    for day = 1:1:m_new_veresion_ForecastData
        if m_new_veresion_ForecastData == (m_new_veresion_ForecastData - 1)
            if abs(new_version_ForecastData((day+1),7) - new_version_ForecastData(day,7)) > 0
                Forecast_day = Forecast_day + 1;
            else
            end  
        break
        end
    end
    old_format_condition_forecast = zeros(Forecast_day,6);
    for i = 1:1:m_new_veresion_ForecastData
        if i == m_new_veresion_ForecastData
            old_format_condition_forecast(j,3:7) = new_version_ForecastData(i,7:11);
            old_format_condition_forecast(j,2) = new_version_ForecastData(i,2)*10000 + new_version_ForecastData(i,3)*100 + new_version_ForecastData(i,4);
        else
            old_format_condition_forecast(j,3:7) = new_version_ForecastData(i,7:11);
            old_format_condition_forecast(j,2) = new_version_ForecastData(i,2)*10000 + new_version_ForecastData(i,3)*100 + new_version_ForecastData(i,4);

            if (new_version_ForecastData(i,4) - new_version_ForecastData((i+1),4)) == 0
            else
                j = j + 1;
            end
        end
    end
 raw_ForecastData = old_format_condition_forecast;

    [m_raw_ForecastData, ~] = size(old_format_condition_forecast);

    %% k-means, bayesian Test

    % Clustering
    % for test
    result_cluster_idx = zeros(m_raw_ForecastData,1);
    result_cluster_1D_day_loop = zeros(m_raw_ForecastData,96);
    for i_loop = 1:1:3
        nb_pv = nb_pv_loop{i_loop};
        c_PastData = c_PastData_pv_loop{i_loop};
        err_PastData = err_PastData_loop{i_loop};
        for i_forecast = 1:1:m_raw_ForecastData
            test_1D_day_feature(i_forecast,:) = raw_ForecastData(i_forecast,feature); % feature
            %# prediction
            result_cluster_idx(i_forecast,1) = nb_pv.predict(test_1D_day_feature(i_forecast,:));
            result_cluster_1D_day_loop(i_forecast,:) = c_PastData(result_cluster_idx(i_forecast,:),:);                
        end
    result_cluster_1D_day{i_loop} = result_cluster_1D_day_loop;        
    end
    result_cluster_1D_day_mean = result_cluster_1D_day{1}+result_cluster_1D_day{2}+result_cluster_1D_day{3};
    result_cluster_1D_day_final = result_cluster_1D_day_mean/3;
     %% ResultingData File
    % 3. Create demand result excel file with the given file name
    % same period at ForecastData
    new_version_ResultingData(:,1:11) = new_version_ForecastData(:,1:11);
    % forecast Demand
    [m_new_veresion_ForecastData, ~]= size(new_version_ForecastData);
    j = 1;
    for i = 1:1:m_new_veresion_ForecastData
        if new_version_ForecastData(i,5) == 0 & new_version_ForecastData(i,6) == 0
            new_version_ResultingData(i,12) = result_cluster_1D_day_final(j,96);
        else
            new_version_ResultingData(i,12) = result_cluster_1D_day_final(j,(new_version_ForecastData(i,5)*4 + new_version_ForecastData(i,6)));
        end
        if i == m_new_veresion_ForecastData
        else
            if (new_version_ForecastData(i,4) - new_version_ForecastData((i+1),4)) == 0
            else
                j = j + 1;
            end
        end
    end
 %% err correction
    % variance error correction
    building_num = num2str(ForecastExcelFile(2,1));
    Name = 'err_correction_kmeans_bayesian_';
    Name = strcat(Name,building_num,'.mat');
    y_err = PVset_err_correction_ANN(2,ForecastExcelFile,Name,path);
    [m_y_err,~] = size(y_err);
    y_err_2 = zeros(m_y_err,1);
    for i = 1:2:(m_y_err-1)
        y_err_2(i,1) = mean(y_err(i:i+1,1));
        y_err_2(i+1,1) = mean(y_err(i:i+1,1));
    end
    y_pv = new_version_ResultingData(1:m_new_veresion_ForecastData,11);
%     y_demand_with_1 = y_demand + y_err;
    y_pv_with_2 = y_pv + y_err_2;
    % bias error correction
    % err correction t_1 (short)
    % forecast err rate
     if exist('shortTermPastData','var')
        y_err_rate = PVset_err_correction_t_1(shortTermPastData,path);
        [m_new_veresion_ForecastData, ~]= size(new_version_ForecastData);
        j = 1;
        y_err_rate_result = zeros(m_new_veresion_ForecastData,1);
        count_1 = 1; % to count abs err rate bigger than 1    
    for i = 1:1:m_new_veresion_ForecastData
        if new_version_ForecastData(i,5)*4 == 0 & new_version_ForecastData(i,6) == 0
            y_err_rate_result(i,1) = y_err_rate(1,96);
        else
            y_err_rate_result(i,1) = y_err_rate(1,(new_version_ForecastData(i,5)*4 + new_version_ForecastData(i,6)));
        end

        if abs(y_err_rate_result(i,1)) > 1
            count_1 = count_1 + 1;
        else
        end
        
        if i == m_new_veresion_ForecastData
        else
            if (new_version_ForecastData(i,4) - new_version_ForecastData((i+1),4)) == 0
            else
                j = j + 1;
            end
        end
    end
     y_pv_with_3 = y_pv ./ (1 - y_err_rate_result);
     if count_1 > 4
         y = y_pv_with_2;
     else
        y = y_pv_with_3;
     end
     else
         y = y_pv_with_2;
     end 
end
% toc
end
