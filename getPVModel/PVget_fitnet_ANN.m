function target = PVget_fitnet_ANN(flag,input,shortTermPastData,path)
% tic;
%% set feature
% P1(hour), P2(temp), P3(cloud), P4(solar)
    sub_feature1 = 5;
    sub_feature2 = 9:10;
    feature = horzcat(sub_feature1,sub_feature2);
     %% PastData
if flag == 1
    PastDataExcelFile_ANN = input;
    PastDataExcelFile_ANN(:,5) = PastDataExcelFile_ANN(:,5)+0.25*PastDataExcelFile_ANN(:,6); 
    PastData_ANN = PastDataExcelFile_ANN(1:(end-96*7),:);    % PastData load
    PastData_ANN(~any(PastData_ANN(:,12),2),:) = [];         % if there is 0 value in generation column -> delete
    [m_PastData_ANN, ~] = size(PastData_ANN);
   %% Train model
    for i_loop = 1:1:3
        trainDay_ANN =m_PastData_ANN;
        x_PV_ANN = transpose(PastData_ANN(1:trainDay_ANN,feature)); % input(feature)
        t_PV_ANN = transpose(PastData_ANN(1:trainDay_ANN,12)); % target
        % Create and display the network
        net_ANN = fitnet([20,20,20,20,5],'trainscg');
        net_ANN.trainParam.showWindow = false;
        net_ANN = train(net_ANN,x_PV_ANN,t_PV_ANN); % Train the network using the data in x and t
        net_ANN_loop{i_loop} = net_ANN;             % save result 
    end
    %% save result mat file
    clearvars input;
    clearvars shortTermPastData;
    building_num = num2str(PastDataExcelFile_ANN(2,1));
    save_name = '\PV_fitnet_ANN_';
    save_name = strcat(path,save_name,building_num,'.mat');
    clearvars path;
    save(save_name);
else
    % file does not exist so use already created .mat
   %% load .mat file
    ForecastExcelFile = input;
    building_num = num2str(ForecastExcelFile(2,1));
    load_name = '\PV_fitnet_ANN_';
    load_name = strcat(path,load_name,building_num,'.mat');
    load(load_name,'-mat');
    %% ForecastData
    ForecastData_ANN = ForecastExcelFile; % ForecastData load
    ForecastData_ANN( ~any(ForecastData_ANN,2), : ) = []; 
    [m_ForecastData_ANN, ~]= size(ForecastData_ANN);
    %% Test using forecast data
        % use ANN 3 times for reduce ANN's error
    for i_loop = 1:1:3
        net_ANN = net_ANN_loop{i_loop};
        result_ForecastData_ANN_loop = zeros(m_ForecastData_ANN,1);
        for i = 1:1:m_ForecastData_ANN
                x2_ANN = transpose(ForecastData_ANN(i,feature));
                result_ForecastData_ANN_loop(i,:) = net_ANN(x2_ANN);
        end
        result_ForecastData_ANN{i_loop} = result_ForecastData_ANN_loop;
    end
    result_ForecastData_ANN_premean = result_ForecastData_ANN{1}+result_ForecastData_ANN{2}+result_ForecastData_ANN{3};
    result_ForecastData_ANN_mean = result_ForecastData_ANN_premean/3;
    result_ForecastData_ANN_final = PVget_error_correction_1(ForecastData_ANN,result_ForecastData_ANN_mean,shortTermPastData);
    %% ResultingData File
    ResultingData_ANN(:,1:10) = ForecastData_ANN(:,1:10);
    [m_ForecastData_ANN, ~]= size(ForecastData_ANN);
    ResultingData_ANN(:,12) = result_ForecastData_ANN_final;
    target = ResultingData_ANN(1:m_ForecastData_ANN,12);
end
end
