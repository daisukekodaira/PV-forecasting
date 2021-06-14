function result = PVLSTM_Forecast(input,path)
% PV prediction: LSTM Model Forecast algorithm
%% load .mat file
Forecastdata = input;
building_num = num2str(Forecastdata(1,1));
load_name = '\PV_LSTM_';
load_name = strcat(path,load_name,building_num,'.mat');
load(load_name,'-mat');
%% forecast pv
data2=Forecastdata(:,predictorscol2);
XTest2 =((data2 - meandata(predictorscol2))./sigdata(predictorscol2))';
pv_net = predictAndUpdateState(pv_net,XTrain2);
[pv_net,YPred(:,1:48)] = predictAndUpdateState(pv_net,XTrain2(:,end-48+1:end));
numTimeStepsTest = size(XTest2,2);
for i = 1:numTimeStepsTest
    [pv_net,YPred(:,i+48)] = predictAndUpdateState(pv_net,XTest2(:,i),'ExecutionEnvironment','auto');
end
result_LSTM = (sigdata(end).*YPred(48+1:end) + meandata(end))'; 
for i=1:size(result_LSTM,1)
    if result_LSTM(i)<0
        result_LSTM(i)=0;
    end
end
result = result_LSTM;