function predictedPVGen = PVset_kmeans_Forecast(forecastData, shortTermPastData, path)  
       
    %% Format error check (to be modified)
    % Check if the number of columns is the 10
    % !!!! It would be flexible. we have to accept any number of columns later.
    % "-1" if there is an error in the forecast_sunlight's data form, or "1"
    [~,number_of_columns3] = size(forecastData);
    if number_of_columns3 == 10
        Alg_State3 = 1;
    else
        Alg_State3 = -1;
    end

    %% Read inpudata
    building_num = num2str(shortTermPastData(2,1)); % distribute with building number 
    % Load mat files
    load_name = '\PV_Model_';
    load_name = strcat(path,load_name,building_num,'.mat');
    load(load_name,'-mat');       

    %% Arrange the arry for prediction
    TempArray = forecastData(~any(isnan(forecastData),2),:);         % Remove NaN from input dataset
    predictorArray = horzcat(TempArray(:,2:6),TempArray(:,9:10));         % Combine the columns (???)
    % Arrange the array for forecast (need to be modified. why predictorArray is not utilized???)
    predict_label_nb_sunlight = nb_sunlight.predict(predictorArray);  % Arrange sun radiation data????
    result_nb_sunlight = c_sunlight(predict_label_nb_sunlight,:); % ???
    Forecastdata_PV = horzcat(forecastData,result_nb_sunlight); % ???
    predict_feature_PV = horzcat(Forecastdata_PV(:,5), Forecastdata_PV(:,9:10)); %???

    %% Prediction
    predict_label_nb_PV = nb_PV.predict(predict_feature_PV);
    predictedPVGen = c_PV(predict_label_nb_PV,:);

end
