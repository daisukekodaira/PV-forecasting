function target = PVset_LSTM_Forecast(input,path)
%% load .mat file
Forecastdata = input;
building_num = num2str(Forecastdata(2,1));
load_name = '\PV_LSTM_';
load_name = strcat(path,load_name,building_num,'.mat');
load(load_name,'-mat');

%% forecast
predictors =(Forecastdata(:,predictorscol)- mu(predictorscol)) ./ sig(predictorscol);

XTest=transpose(predictors);
net = predictAndUpdateState(net,XTrain);
[net,YPred(:,1:96)] = predictAndUpdateState(net,XTrain(:,end-96+1:end));
numTimeStepsTest = size(XTest,2);
for i = 1:numTimeStepsTest
    [net,YPred(:,i+96)] = predictAndUpdateState(net,XTest(:,i),'ExecutionEnvironment','auto');
end
YPred = sig(13).*YPred(96+1:end) + mu(13);
target=transpose(YPred);