function [pred] = kmeansPV_Forecast(forecastData, path)  
       
    %% Format error check (to be modified)
%     % Check if the number of columns is the 10
%     % !!!! It would be flexible. we have to accept any number of columns later.
%     % "-1" if there is an error in the forecast_sunlight's data form, or "1"
%     [~,number_of_columns3] = size(forecastData);
%     if number_of_columns3 == 10
%         Alg_State3 = 1;
%     else
%         Alg_State3 = -1;
%     end

    %     % Display for user
    %     disp('Validating the k-menas & Baysian model....');
    
    %% Read inpudata
    pvID = num2str(forecastData.PV_ID(1)); % distribute with building number 
    % Load mat files
    load_name = '\PV_trainedKmeans_';
    load_name = strcat(path,load_name, pvID,'.mat');
    load(load_name,'-mat');    

    %% Prediction based on the Naive Bayes classification model
    forecastData = table2array(forecastData);   % change table to array
    label = NaiveBayesModel.predict(forecastData);  % Distribute class label using attribute "predict".
    pred = centroid(label,:);    % Extract centroid as a predicted targe
    
    %     % Display for user    
    %     disp('Validating the k-menas & Baysian model.... Done!');
end
