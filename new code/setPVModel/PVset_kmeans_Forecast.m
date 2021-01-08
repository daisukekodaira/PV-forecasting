function predictedPVGen = PVset_kmeans_Forecast(forecastData, ~, path)
%% load .mat file
building_num = num2str(forecastData(2,1));
load_name = '\PV_Model_';
load_name = strcat(path,load_name,building_num,'.mat');
load(load_name,'-mat');
%% normalize
% Data such as time, irradiation, etc. have high variance. so i normalize
ForecastData=forecastData(:,[1:4 7:13]);
dataForecastnormalize = (ForecastData(:,7:11) - min_value(1:5)) ./ (max_value(1:5) - min_value(1:5));
dataForecastnormalize = horzcat(ForecastData(:,1:6),dataForecastnormalize);
%% Forecast solarlrradiance
% There is no solar irradiance data so i predict solar data using k-means
TempArray = dataForecastnormalize(~any(isnan(dataForecastnormalize),2),:);
predictorArray = horzcat(TempArray(:,[3 5 6]),TempArray(:,predictor_sun));        % Set feature column
predict_label_nb_sunlight = nb_sunlight.predict(predictorArray);     % Find solar's idex using Bayesian
result_nb_sunlight = c_sunlight(predict_label_nb_sunlight,:);        % Find solar irradiance using solar's idex
dataForecastnormalize = horzcat(dataForecastnormalize,result_nb_sunlight); % Make a new forecast data
ForecastData(:,12)=(max_value(6) - min_value(6)).*result_nb_sunlight + min_value(6);       % Return normalize data back to real value.
%% Patterning ForecastData
% In PV forecast, it is much better to use patterned data
% Count day number -> (0~23: 1 day), (8~7: 2 days)
[m_ForecastData, ~]= size(dataForecastnormalize);
j = 1;k=1;
% Patterning data. (if there is two day's data in forecast data, Separate data in two rows)
for i = 1:m_ForecastData
    patterned_Forecastdata(j,1)=dataForecastnormalize(2,1);
    patterned_Forecastdata(j,3)=max(dataForecastnormalize(i,7));
    patterned_Forecastdata(j,4)=mean(dataForecastnormalize(k:i,8));
    patterned_Forecastdata(j,5)=max(dataForecastnormalize(i,9));
    patterned_Forecastdata(j,6:8)=mean(dataForecastnormalize(k:i,10:12));
    mon=(dataForecastnormalize(i,3) + round(dataForecastnormalize(i,4)/30));
    if mon >= 12 || mon < 3  %Winter
        patterned_Forecastdata(j,2) = 1;
    elseif mon >= 6 && mon<9
        patterned_Forecastdata(j,2) = 3;
    else
        patterned_Forecastdata(j,2) = 2;
    end
    if i ~= m_ForecastData && (dataForecastnormalize(i,4) - dataForecastnormalize((i+1),4)) ~= 0
        j = j + 1;
        k=i;
    end
end
%% Use k-means, bayesian for predict
[Forecastday, ~] = size(patterned_Forecastdata);
Result_idx = zeros(Forecastday,1);
Result_value = zeros(Forecastday,48);
%The k-means algorithm repeats three times because the result may vary from execution to execution.
for i_loop = 1:3
    nb_pv = nb_pv_loop{i_loop};
    c_PastData = c_PastData_pv_loop{i_loop};
    for day = 1:Forecastday
        Result_idx(day,1) = nb_pv.predict(patterned_Forecastdata(day,Feature)); % Find generation's idex using Bayesian
        Result_value(day,:) = c_PastData(Result_idx(day,:),:);                  % Find generation using generation's idex
    end
    Result_cluster{i_loop} = Result_value;
end
% Average the results and derive the final result
Result_cluster_mean = Result_cluster{1}+Result_cluster{2}+Result_cluster{3};
Result_cluster_final = (Result_cluster_mean/3)';
new_version_ResultingData = horzcat(ForecastData(:,1:12),Result_cluster_final);
predictedPVGen = new_version_ResultingData(1:m_ForecastData,13);
end