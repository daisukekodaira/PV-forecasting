% ---------------------------------------------------------------------------
% PV prediction: Foecasting algorithm 
% 2019/02/22 Updated by Daisuke Kodaira 
% email: daisuke.kodaira03@gmail.com
%
% function flag = demandForecast(shortTermPastData, ForecastData, ResultData)
%     flag =1 ; if operation is completed successfully
%     flag = -1; if operation fails.
%     This function depends on demandModel.mat. If these files are not found return -1.
%     The output of the function is "ResultData.csv"
% ----------------------------------------------------------------------------

function flag = getPVModel(shortTermPastData, ForecastData, ResultData)
    tic;
    
    %% parameters
    op_flag = 2; % 2: forecast mode(validation)
    ci_percentage = 0.05; % 0.05 = 95% it must be between 0 to 1

    %% Load data
    if strcmp(shortTermPastData, 'NULL') == 0 || strcmp(ForecastData, 'NULL') == 0 || strcmp(ResultData, 'NULL') == 0
        short_past_load = csvread(shortTermPastData,1,0);
        predictors = csvread(ForecastData,1,0);
        Resultfile = ResultData;
    else
        flag = -1;
        errMessage =  'ERROR: one of the input csv files is missing';
        disp(errMessage)
        return
    end       

    %% Load .mat files from give path of "shortTermPastData"
    filepath = fileparts(shortTermPastData);
    buildingIndex = short_past_load(1,1);
    %% Error recognition: Check mat files exist
    name1 = [filepath, '\', 'PV_Model_', num2str(buildingIndex), '.mat'];
    name2 = [filepath, '\', 'PV_err_distribution_', num2str(buildingIndex), '.mat'];
    name3 = [filepath, '\', 'PV_pso_coeff_', num2str(buildingIndex), '.mat'];
    if exist(name1) == 0 || exist(name2) == 0 || exist(name3)== 0
        flag = -1;
        errMessage = 'ERROR: .mat files is not found (or the building index is not consistent in "demandModelDev" and "demandForecst" phase)';
        disp(errMessage)
        return
    end    
    
    %% Load mat files
    s1 = 'PV_pso_coeff_';
    s2 = 'PV_err_distribution_';
    s3 = num2str(buildingIndex);    
    name(1).string = strcat(s1,s3);
    name(2).string = strcat(s2,s3);
    varX(1).value = 'coeff';
    varX(2).value = 'err_distribution';
    extention='.mat';
    for i = 1:size(varX,2)
        matname = fullfile(filepath, [name(i).string extention]);
        load(matname);
    end
    %% Prediction for test data
    predicted_PV(1).data = PVget_kmeans(op_flag, predictors, short_past_load, filepath);
%     predicted_PV(2).data = PV_fitnet_ANN(op_flag, predictors, short_past_load, filepath);   
    %% Prediction result
    for hour = 1:24
        for i = 1:size(predicted_PV.data,2) % the number of prediction methods(k-means and fitnet)
            if i == 1
                yDetermPred(1+(hour-1)*4:hour*4,:) = coeff(hour).data(i)*predicted_PV(i).data(1+(hour-1)*4:hour*4);
            else
                yDetermPred(1+(hour-1)*4:hour*4,:) = yDetermPred(1+(hour-1)*4:hour*4,:) + coeff(hour).data(i)*predicted_PV(i).data(1+(hour-1)*4:hour*4);  
            end
        end
    end    
    %% Generate Result file    
    % Headers for output file
    hedder = {'BuildingIndex', 'Year', 'Month', 'Day', 'Hour', 'Quarter', 'DemandMean', 'CIMin', 'CIMax', 'CILevel', 'pmfStartIndx', 'pmfStep', ...
                      'DemandpmfData1', 'DemandpmfData2', 'DemandpmfData3', 'DemandpmfData4', 'DemandpmfData5', 'DemandpmfData6' ...
                      'DemandpmfData7', 'DemandpmfData8', 'DemandpmfData9', 'DemandpmfData10'};
    fid = fopen(Resultfile,'wt');
    fprintf(fid,'%s,',hedder{:});
    fprintf(fid,'\n');

    % Make distribution of prediction
    for i = 1:size(yDetermPred,1)
        prob_prediction(:,i) = yDetermPred(i) + err_distribution(predictors(i,5)+1, predictors(i,6)+1).data;
        prob_prediction(:,i) = max(prob_prediction(:,i), 0);    % all elements must be bigger than zero
        % %         for debugging --------------------------------------------------------------------------
        %                 h = histogram(prob_prediction(:,i), 'Normalization','probability');
        %                 h.NumBins = 10;
        % %         for debugging -------------------------------------------------------------------------------------
        [demandpmfData(i,:), edges(i,:)] = histcounts(prob_prediction(:,i), 10, 'Normalization', 'probability');
        pmfStart(i,:) = edges(i,1);
        pmfStart(i,:) = max(pmfStart(i,:), 0);
        pmfStep(i,:) =  abs(edges(i,1) - edges(i,2));
    end
    % When the validation date is for only one day
    if size(prob_prediction, 1) == 1    
        prob_prediction = [prob_prediction; prob_prediction];
    end
    % Get mean value of Probabilistic load prediction
    y_mean = mean(prob_prediction)';
    % Get Confidence Interval
    [L_boundary, U_boundary] = PVget_getCI(prob_prediction, ci_percentage);
    % Make matrix to be written in "ResultData.csv"
    result = [predictors(:,1:6) y_mean L_boundary U_boundary 100*(1-ci_percentage)*ones(size(yDetermPred,1),1) pmfStart pmfStep demandpmfData];
    fprintf(fid,['%d,', '%4d,', '%02d,', '%02d,', '%02d,', '%d,', '%f,', '%f,', '%f,', '%02d,', '%f,', '%f,', repmat('%f,',1,10) '\n'], result');
    fclose(fid);
   %% Display graph
    % make x timestep
    timestep=csvread(ForecastData,1,4,[1,4,96,5]);
    xtime=timestep(:,1)+0.25*timestep(:,2);
    for i=1:size(xtime,1)
        if xtime(i) < xtime(1)
           xtime(i)=xtime(i)+24;
        end
    end
%       % for debugging --------------------------------------------------------
%         observed = csvread('Target.csv');
%         boundaries =  [L_boundary, U_boundary];
%         % display graph
%         graph_desc(xtime, yDetermPred, observed, boundaries, 'Combined for forecast data', ci_percentage); % Combined
%         graph_desc(xtime, predicted_PV(1).data, observed, [], 'k-means for forecast data', ci_percentage); % k-means
%         graph_desc(xtime, predicted_PV(2).data, observed, [], 'ANN for forecast data', ci_percentage); % k-means
%         % Cover Rate of PI
%         count = 0;
%         for i = 1:(size(observed,1))
%             if (L_boundary(i)<=observed(i)) && (observed(i)<=U_boundary(i))
%                 count = count+1;
%             end
%         end
%         PICoverRate = 100*count/size(observed,1);
%         MAE(1) = mean(abs(yDetermPred - observed)./observed); % combined   % MAE: mean average error
%         MAE(2) = mean(abs(predicted_PV(1).data - observed)./observed);
%         MAE(3) = mean(abs(predicted_PV(2).data - observed)./observed);% k-means
%         disp(['PI cover rate is ',num2str(PICoverRate), '[%]/', num2str(100*(1-ci_percentage)), '[%]'])
%         disp(['MAPE of combine model: ', num2str(MAE(1))])
%         disp(['MAPE of kmeans: ', num2str(MAE(2))])
%         disp(['MAPE of ANN: ', num2str(MAE(3))])
%        % for debugging --------------------------------------------------------------------- 
    
    flag = 1;
    toc;
end
