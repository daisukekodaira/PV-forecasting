function y = PVset_kmeans(flag,inputdata, shortTermPastData, path)

    if flag == 1    
        % Input data: longTermPastData
        PVset_kmeans_Training(inputdata, path); 
    else    
        % Input data: forecastData
        y = PVset_kmeans_Forecast(inputdata, shortTermPastData, path); 
        %         y = kmeansPV_error_correction(inputdata, shortTermPastData, path); % need to be developed
    end

end