function PVset_LSTM_train(input,path)
%% LOAD DATA
traindays=7;
%% devide data (train,vaild)
predata = input(end-96*traindays+1:end,:);
mu = mean(predata);
sig = std(predata); %sig= 표준편차
dataTrainStandardized = (predata - mu) ./ sig;
predictorscol=[5 7:12];
predictors=dataTrainStandardized(:,predictorscol);
targetdata=dataTrainStandardized(:,13);

XTrain=transpose(predictors);
YTrain= transpose(targetdata);
%% train lstm
numFeatures = 6;
numResponses = 1;
numHiddenUnits = 200;

layers = [ ...
    sequenceInputLayer(numFeatures)
    lstmLayer(numHiddenUnits)
    fullyConnectedLayer(numResponses)
    regressionLayer];

options = trainingOptions('adam', ...
    'MaxEpochs',250, ...
    'GradientThreshold',1.2, ...
    'InitialLearnRate',0.005, ...
    'LearnRateSchedule','piecewise', ...
    'LearnRateDropPeriod',125, ...
    'LearnRateDropFactor',0.2, ...
    'Verbose',0);
net = trainNetwork(XTrain,YTrain,layers,options);
    %% save result mat file
    clearvars input;
    clearvars shortTermPastData dataTrainStandardized 
    building_num = num2str(predata(2,1));
    save_name = '\PV_LSTM_';
    save_name = strcat(path,save_name,building_num,'.mat');
    clearvars path;
    save(save_name);

end

