function PVLSTM_train(input,path)
start_LSTM_train = tic;
% PV prediction: LSTM Model Forecast algorithm
%% devide data (train,vaild)
predata = input(:,1:end-1);
meandata = mean(predata);
sigdata = std(predata); 
if sigdata(6)==0 % in case of rain, its valus is usually 0. so it make NAN value
    sigdata(6)=1;
end
dataTrainStandardized = (predata - meandata) ./ sigdata;
%% train lstm (generation)
predictorscol2=[4 5 6 7];
XTrain2=(dataTrainStandardized(:,predictorscol2))';
YTrain2=(dataTrainStandardized(:,end))';
%lstm
numFeatures = size(predictorscol2,2);
numResponses = 1;
numHiddenUnits1 = 100;
numHiddenUnits2 = 50;
numHiddenUnits3 = 25;
layers = [ ...
    sequenceInputLayer(numFeatures)
    reluLayer
    lstmLayer(numHiddenUnits1)
    reluLayer
    lstmLayer(numHiddenUnits2)
    reluLayer
    lstmLayer(numHiddenUnits3)    
    reluLayer
    fullyConnectedLayer(numResponses)
    regressionLayer];
options = trainingOptions('adam', ...
    'MaxEpochs',250, ...
    'GradientThreshold',1.2, ...
    'InitialLearnRate',0.01, ...
    'LearnRateSchedule','piecewise', ...
    'LearnRateDropPeriod',125, ...
    'LearnRateDropFactor',0.2, ...
    'Verbose',0);
pv_net = trainNetwork(XTrain2,YTrain2,layers,options);
    %% save result mat file
    clearvars input;
    clearvars shortTermPastData dataTrainnormalize
    building_num = num2str(predata(2,1));
    save_name = '\PV_LSTM_';
    save_name = strcat(path,save_name,building_num,'.mat');
    clearvars path;
    save(save_name);
    end_LSTM_train = toc(start_LSTM_train)
end