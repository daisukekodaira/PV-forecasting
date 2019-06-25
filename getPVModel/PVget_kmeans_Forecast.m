function predictedPVGen = PVget_kmeans_Forecast(ForecastData, shortTermPastData, path)
% PV prediction: Model development algorithm
% 2019/06/25 Updated gyeong gak (kakkyoung2@gmail.com)
%% load .mat file
building_num = num2str(ForecastData(2,1));
load_name = '\PV_Model_';
load_name = strcat(path,load_name,building_num,'.mat');
load(load_name,'-mat');
%% Forecast Solar Irradiance
TempArray = ForecastData(~any(isnan(ForecastData),2),:);
predictorArray = horzcat(TempArray(:,2:4),TempArray(:,9:10));
predict_label_nb_sunlight = nb_sunlight.predict(predictorArray);
result_nb_sunlight = c_sunlight(predict_label_nb_sunlight,:);
ForecastData = horzcat(ForecastData,result_nb_sunlight);
%% Patterning ForecastData
% Count day number -> (0~23: 1 day), (8~7: 2 days)
[m_ForecastData, ~]= size(ForecastData);
j = 1;
for i = 1:m_ForecastData
    patterned_Forecastdata(j,1)=ForecastData(2,1);
    patterned_Forecastdata(j,3:7) = ForecastData(i,7:11);
    patterned_Forecastdata(j,2) = ForecastData(i,2)*10000 + ForecastData(i,3)*100 + ForecastData(i,4);
    if i ~= m_ForecastData && (ForecastData(i,4) - ForecastData((i+1),4)) ~= 0
        j = j + 1;
    end
end
%% Use k-means, bayesian for predict
[Forecastday, ~] = size(patterned_Forecastdata);
Result_idx = zeros(Forecastday,1);
Result_value = zeros(Forecastday,96);
for i_loop = 1:3
    nb_pv = nb_pv_loop{i_loop};
    c_PastData = c_PastData_pv_loop{i_loop};
    for day = 1:Forecastday
        % I want use feature value using .mat ,but it makes error.
        % so i write 3:7.
        Result_idx(day,1) = nb_pv.predict(patterned_Forecastdata(day,3:7));
        Result_value(day,:) = c_PastData(Result_idx(day,:),:);
    end
    Result_cluster{i_loop} = Result_value;
end
Result_cluster_mean = Result_cluster{1}+Result_cluster{2}+Result_cluster{3};
Result_cluster_final = Result_cluster_mean/3;
%% Make a prediction result
new_version_ResultingData(:,1:11) = ForecastData(:,1:11);
[m_ForecastData, ~]= size(ForecastData);
j = 1;
for i = 1:m_ForecastData
    if ForecastData(i,5) == 0 && ForecastData(i,6) == 0
        new_version_ResultingData(i,12) = Result_cluster_final(j,96);
    else
        new_version_ResultingData(i,12) = Result_cluster_final(j,(ForecastData(i,5)*4 + ForecastData(i,6)));
    end
    if i ~= m_ForecastData && (ForecastData(i,4) - ForecastData((i+1),4)) ~= 0
        j = j + 1;
    end
end
y_pv = new_version_ResultingData(1:m_ForecastData,12);
predictedPVGen=y_pv;
end

