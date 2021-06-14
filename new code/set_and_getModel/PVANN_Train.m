function target = PVANN_Train(LongTermpastData,path)
start_ANN_Train = tic;
%% PastData
PastData_ANN = LongTermpastData(:,1:end-1); % PastData load
[m_PastData_ANN, ~] = size(PastData_ANN);  
%% set featur
feature2 =[4 5 6 7];
%% Train PV model
for i_loop = 1:3
    trainDay_ANN =m_PastData_ANN;
    x_PV_ANN = transpose(PastData_ANN(1:trainDay_ANN,feature2)); % input(feature)
    t_PV_ANN = transpose(PastData_ANN(1:trainDay_ANN,end)); % target
    % Create and display the network
    net_PV_ANN = fitnet([30,20,20,20,15],'trainscg');
    net_PV_ANN.trainParam.showWindow = false;
    net_PV_ANN = train(net_PV_ANN,x_PV_ANN,t_PV_ANN); % Train the network using the data in x and t
    net_PV_ANN_loop{i_loop} = net_PV_ANN;             % save result
end
%% save result mat file
clearvars input;
clearvars shortTermPastData;
building_num = num2str(LongTermpastData(2,1));
save_name = '\PV_fitnet_ANN_';
save_name = strcat(path,save_name,building_num,'.mat');
clearvars path;
save(save_name,'net_PV_ANN_loop','feature2');
end__ANN_Train = toc(start_ANN_Train)
end