function target = PVset_LSTM_Forecast(input,path)
% PV prediction: LSTM Model Forecast algorithm
% 2019/10/15 Updated gyeong gak (kakkyoung2@gmail.com)
%% load .mat file
Forecastdata = input;
building_num = num2str(Forecastdata(2,1));
load_name = '\PV_LSTM_';
load_name = strcat(path,load_name,building_num,'.mat');
load(load_name,'-mat');
%% forecast
data=Forecastdata(:,predictorscol);
predictors =(data - meandata(predictorscol))./sigdata(predictorscol);

XTest=transpose(predictors);
net = predictAndUpdateState(net,XTrain);
[net,YPred(:,1:96)] = predictAndUpdateState(net,XTrain(:,end-96+1:end));
numTimeStepsTest = size(XTest,2);
for i = 1:numTimeStepsTest
    [net,YPred(:,i+96)] = predictAndUpdateState(net,XTest(:,i),'ExecutionEnvironment','auto');
end
YPred = sigdata(13).*YPred(96+1:end) + meandata(13);
target=transpose(YPred);