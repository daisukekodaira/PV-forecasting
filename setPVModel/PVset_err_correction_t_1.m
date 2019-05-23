function y = PVset_err_correction_t_1(shortTermPastData,path)
% tic;
% feature
% P1(day), P2(holiday), P3(highest Temp), P4(weather)
feature = 2:7;

% kmeans_bayesian
   %% load .mat file
      %#function ClassificationNaiveBayes
    [m_Short,n_Short] = size(shortTermPastData);
    
    if m_Short < 96*3
        ShortExcelFile = shortTermPastData(:,:);
    else
%         ShortExcelFile = shortTermPastData((end-96*3+1):end,:);
%         ShortExcelFile = shortTermPastData((end-96*1+1):end,:);
        ShortExcelFile = shortTermPastData(:,:);
    end
    
    building_num = num2str(ShortExcelFile(2,1));

    load_name = '\PV_Model_';
    load_name = strcat(path,load_name,building_num,'.mat');
    
    load(load_name,'-mat');


    %% ForecastData

    % ForecastData load
    ShortData = ShortExcelFile;

    old_format_ShortData = PVset_format_change_1(ShortData);

    % ForecastData
    raw_ShortData = old_format_ShortData;

    [m_raw_ShortData, ~] = size(old_format_ShortData);

    %% k-means, bayesian Test
    % Clustering
    % for test

    result_cluster_idx = zeros(m_raw_ShortData,1);

    result_cluster_1D_day_loop = zeros(m_raw_ShortData,96);

    for i_loop = 1:1:3
        nb_pv = nb_pv_loop{i_loop};
        c_PastData_pv = c_PastData_pv_loop{i_loop};
        for i_forecast = 1:1:m_raw_ShortData

            test_1D_day_feature(i_forecast,:) = raw_ShortData(i_forecast,feature); % feature
            %# prediction
                result_cluster_idx(i_forecast,1) = nb_pv.predict(test_1D_day_feature(i_forecast,:));
            % idx -> kW
                result_cluster_1D_day_loop(i_forecast,:) = c_PastData_pv(result_cluster_idx(i_forecast,:),:);                
        end
    
    result_cluster_1D_day{i_loop} = result_cluster_1D_day_loop; 
    end
    result_cluster_1D_day_sum = result_cluster_1D_day{1}+result_cluster_1D_day{2}+result_cluster_1D_day{3};
    result_cluster_1D_day_mean = result_cluster_1D_day_sum/3;
    real_demand = old_format_ShortData(:,8:103);
    % delete 0 value
    
    for i_s = 1:1:m_raw_ShortData
        for j_s = 1:1:96
%             if real_demand(i_s,j_s) ~= 0
                err_ShortData(i_s,j_s) = real_demand(i_s,j_s) - result_cluster_1D_day_mean(i_s,j_s);
%             end
        end
    end  
%     err_ShortData = real_demand - result_cluster_1D_day_mean; % real - forecast
    err_ShortData_rate = err_ShortData./real_demand; % (real - forecast) / real
    if m_Short < 96*3
        % row 3, d-1
        if (ShortData(end,5)*4 + ShortData(end,6)) ~= 0
            err_ShortData_rate(m_raw_ShortData,(ShortData(end,5)*4 + ShortData(end,6)):end) = 0;
        end
    else
        % row 1, 1st day (or d-3)
        if (ShortData(1,5)*4 + ShortData(1,6)) ~= 1
            err_ShortData_rate(1,1:(ShortData(1,5)*4 + ShortData(1,6))) = 0;
        end
        % row 3, d-1
        if (ShortData(end,5)*4 + ShortData(end,6)) ~= 0
            err_ShortData_rate(m_raw_ShortData,(ShortData(end,5)*4 + ShortData(end,6)):end) = 0;
        end
    end
    for i=1:96
     err_ShortData_rate(isnan(err_ShortData_rate(1:end,i)),i)= 0;
     err_ShortData_rate(isinf(err_ShortData_rate(1:end,i)),i)= 0;
    end
    % bias detection
    bias_detection = zeros(1,24);
    if (ShortData(end,5)*4 + ShortData(end,6)) < 24
        if m_Short < 96*3
             bias_detection(1,1:(ShortData(end,5)*4 + ShortData(end,6))) = err_ShortData_rate(end,1:(ShortData(end,5)*4 + ShortData(end,6))); % d-1
        else
            bias_detection(1,(ShortData(end,5)*4 + ShortData(end,6))+1:24) = err_ShortData_rate(end-1,(ShortData(end,5)*4 + ShortData(end,6))+1:24); % d-2
            bias_detection(1,1:(ShortData(end,5)*4 + ShortData(end,6))) = err_ShortData_rate(end,1:(ShortData(end,5)*4 + ShortData(end,6))); % d-1
        end
    else
        bias_detection(1,1:24) = err_ShortData_rate(end,(ShortData(end,5)*4 + ShortData(end,6))-23:(ShortData(end,5)*4 + ShortData(end,6))); % d-1
    end
    bias_detection = bias_detection + 0.000001;
    bias_detection_sign = 1;
    for i = 1:1:24
        bias_detection_sign = bias_detection_sign * bias_detection(1,i);
    end
    for delete_detection_i = 1:1:24
        bias_detection(isnan(bias_detection(1,delete_detection_i)),:) = [];
    end
    % detect
    if bias_detection_sign > 0
        bias_err_rate_mean(1,1:96) = sum(bias_detection) / (24 - sum(bias_detection == 0));
    end
    % delete NaN value
    for delete_i = 1:1:96
        err_ShortData_rate(isnan(err_ShortData_rate(:,delete_i)),:) = [];
    end
    m_raw_ShortData_0 = sum(err_ShortData_rate == 0);
    [m_raw_ShortData,~] = size(err_ShortData_rate);
    m_raw_ShortData = m_raw_ShortData - m_raw_ShortData_0;
    err_ShortData_rate_sum = sum(err_ShortData_rate(:,:),1);
    n_zero = find(err_ShortData_rate_sum(1,:) == 0);
    [~,M_n_zero] = size(n_zero);
    for i_n_zero = 1:1:M_n_zero
        err_ShortData_rate_sum(1,n_zero(1,i_n_zero)) = mean(err_ShortData_rate_sum);
        m_raw_ShortData(1,n_zero(1,i_n_zero)) = 1;
    end
    avg_err_rate_mean = err_ShortData_rate_sum ./ m_raw_ShortData;
    % err compare
    if bias_detection_sign > 0
        err_trend_mean = mean(bias_err_rate_mean) - mean(avg_err_rate_mean);
        
        if sign(mean(bias_err_rate_mean)) == sign(err_trend_mean)
            y = bias_err_rate_mean;
        else
            y = avg_err_rate_mean;
        end
    else
        y = avg_err_rate_mean;
    end
    

end

