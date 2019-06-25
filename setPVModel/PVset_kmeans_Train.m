function PVset_kmeans_Train(LongTermpastData, path)
% PV prediction: Model development algorithm
% 2019/06/25 Updated gyeong gak (kakkyoung2@gmail.com)
%% Load data
Past_Load_dataData = LongTermpastData(1:(end-96*7),:); % PastData load
[m_new_format_PastData, ~]= size(Past_Load_dataData);
%% Kmeans clustering for forecast sunlight data
past_feature_sunlight = horzcat(Past_Load_dataData(:,2:4), Past_Load_dataData(:,9:10)); % combine 1~5 columns & 9,10 columns
past_load_sunlight = Past_Load_dataData(:,11);
% Set K for sunlight. 10 is experimentally chosen by gyeong gak
k_sunlight = 10;
[idx_sunlight,c_sunlight] = kmeans(past_load_sunlight,k_sunlight);
nb_sunlight = fitcnb(past_feature_sunlight, idx_sunlight,'Distribution','kernel');
%% If there is no 1 day past data, Make clone data
if m_new_format_PastData < 96
    Past_Load_dataData(1:96,[1,3,4]) = Past_Load_dataData(1,[1,3,4]); % building ID
    Past_Load_dataData(1:96,5) = transpose([0 0 0 1 1 1 1 2 2 2 2 3 3 3 3 4 4 4 4 5 5 5 5 6 6 6 6 7 7 7 7 8 8 8 8 9 9 9 9 10 10 10 10 ...
        11 11 11 11 12 12 12 12 13 13 13 13 14 14 14 14 15 15 15 15 16 16 16 16 17 17 17 17 18 18 18 18 ...
        19 19 19 19 20 20 20 20 21 21 21 21 22 22 22 22 23 23 23 23 0]);
    Past_Load_dataData(1:96,6) = transpose([1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 ...
        1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0]);
    Past_Load_dataData(1:96,7:10) = Past_Load_dataData(1,7:10);
    Past_Load_dataData(1:96,11) = mean(Past_Load_dataData(1:m_new_format_PastData,11)); % demand
end
%% Patterning data
% 1:Building index , 2:Date, 3:Day of Week,  4:Holiday,  5:Temparature,
%  6:Cloud, 7:SolarIrradiance,  8~102:Generation
Patterned_PastData = PVset_Format_Change(Past_Load_dataData);
%% Train model
feature = 3:7;
[days, ~] = size(Patterned_PastData);
if days <= 30
    k_pv = 2;
    [idx_PastData,c_PastData_pv] = kmeans(Patterned_PastData(:,8:103),k_pv);       % k-means past data index
    train_feature = Patterned_PastData(1:end,feature);                                 % feature
    train_label = idx_PastData(1:end,1);                                     % class index
    nb_pv = fitcnb(train_feature,train_label,'Distribution','kernel');     % train model
end
for i_loop = 1:3
    %% validation for selecting otimal k
    k_min = 5;
    k_max = 25;
    for k = k_min:1:k_max
        %% Divide data train, valid
        % 100% : total
        raw_100_PastData = Patterned_PastData;
        [m_raw_100_PastData, ~] = size(raw_100_PastData);
        m_raw_70_PastData = round(m_raw_100_PastData * 0.7);
        % 70% : train, 30% : validate
        raw_70_PastData = raw_100_PastData(1:m_raw_70_PastData,:);
        raw_30_PastData = raw_100_PastData(m_raw_70_PastData+1:end,:);
        %% k-means past train data
        [idx_PastData,c_PastData] = kmeans(raw_70_PastData(:,8:103),k);
        idx_PastData_pv_array{k} = idx_PastData;
        c_PastData_pv_array{k} = c_PastData;
        train_feature = raw_70_PastData(1:end,feature);                                               % feature
        train_label = idx_PastData(1:end,1);                                                   % class index
        nb_pv_array{k} = fitcnb(train_feature,train_label,'Distribution','kernel');        %# train model
        %% vaild (to make err data)
        [m_raw_ForecastData, ~] = size(raw_30_PastData);
        result_idx = zeros(m_raw_ForecastData,1);
        result_cluster = zeros(m_raw_ForecastData,96);
        for i = 1:m_raw_ForecastData
            test_input(i,:) = raw_30_PastData(i,feature); % feature
            %# prediction
            result_idx(i,1) = nb_pv_array{k}.predict(test_input(i,:));
            result_cluster(i,:) = c_PastData(result_idx(i,:),:);
        end
        %% Calculate err data for selet optimal K
        result_cluster_array{k} = result_cluster;
        result_err_data_array{k} =  raw_30_PastData(:,8:103) - result_cluster_array{k}; % real - forecast
        abs_err_rate_k{k} = abs(result_err_data_array{k});
        total_err(k)=sum(mean(abs_err_rate_k{k}));
    end
    Optimal_k=find(total_err==min(total_err(k_min:k_max)));
    %%  Train again (using optimal k model)
    nb_pv_loop{i_loop} =nb_pv_array{Optimal_k};
    c_PastData_pv_loop{i_loop} = c_PastData_pv_array{1,Optimal_k};
    idx_PastData_loop{i_loop}=idx_PastData_pv_array{Optimal_k};
end
%% Save .mat file
clearvars input;
building_num = num2str(LongTermpastData(2,1));
save_name = '\PV_Model_';
save_name = strcat(path,save_name,building_num,'.mat');
if (days) < 31
    save(save_name,'nb_pv','c_PastData_pv','idx_PastData','feature','nb_sunlight','c_sunlight','idx_sunlight');
else
    save(save_name,'nb_pv_loop','c_PastData_pv_loop','idx_PastData_loop','feature','nb_sunlight','c_sunlight','idx_sunlight');
end
end

