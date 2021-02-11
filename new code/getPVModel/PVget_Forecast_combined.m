function evaluation=PVget_Forecast_combined(predicted_PV,predictors,PV_ID,observed,forecastData)
    %% Load .mat files from given path of "forecastData"
        filepath = fileparts(forecastData);
        buildingIndex = predictors(1,1);     
    %% Load mat files
        s1 = '\PV_pso_coeff_';
        s2 = num2str(buildingIndex);
        load_name = fullfile(filepath, [strcat(s1,s2) '.mat']);
        load(load_name,'-mat');
    %% Get Deterministic prediction result  
    [~,numCols]=size(coeff(1,:));
    %% Make distribution of ensemble forecasting (three method)
    for hour = 1:24              
        for i = 1:numCols % the number of prediction methods(k-means, ANN and LSTM)
            if i == 1
               yDetermPred3(1+(hour-1)*2:hour*2,:) = coeff(hour,i).*predicted_PV(i).data(1+(hour-1)*2:hour*2);
            else
               yDetermPred3(1+(hour-1)*2:hour*2,:) = yDetermPred3(1+(hour-1)*2:hour*2,:) + coeff(hour,i).*predicted_PV(i).data(1+(hour-1)*2:hour*2);  
            end
        end
    end      
    % Get Interval
    [L_boundary_3, U_boundary_3] = PVget_PI(PV_ID,yDetermPred3,filepath);
    boundaries_3 =  [L_boundary_3, U_boundary_3];  
    %% Make distribution of ensemble forecasting (four method)
    for hour = 1:24
         if  hour==7 || hour==8 || hour==9 ||hour==10 || hour==11 || hour==12 || hour==13 || hour==14 || hour==15 || hour==16 || hour==17 || hour==18           
              for i = 1:numCols+1 
                   if i == 1
                       yDetermPred4(1+(hour-1)*2:hour*2,:) = coeff4(hour,i).*predicted_PV(i).data(1+(hour-1)*2:hour*2);
                   else
                       yDetermPred4(1+(hour-1)*2:hour*2,:) = yDetermPred4(1+(hour-1)*2:hour*2,:) + coeff4(hour,i).*predicted_PV(i).data(1+(hour-1)*2:hour*2);  
                   end
              end
         else
              for i = 1:numCols
                   if i == 1
                       yDetermPred4(1+(hour-1)*2:hour*2,:) = coeff(hour,i).*predicted_PV(i).data(1+(hour-1)*2:hour*2);
                   else
                       yDetermPred4(1+(hour-1)*2:hour*2,:) = yDetermPred4(1+(hour-1)*2:hour*2,:) + coeff(hour,i).*predicted_PV(i).data(1+(hour-1)*2:hour*2);  
                   end
              end
         end
    end    
    % Get Interval
    [L_boundary_4, U_boundary_4] = PVget_PI(PV_ID,yDetermPred4,filepath);
    boundaries_4 =  [L_boundary_4, U_boundary_4];  
    %% Display graph 
    Number=num2str(PV_ID);
    graphname_Combined_3=strcat('Combined the results without optical flow ',Number);
    graphname_Combined_4=strcat('Combined the results with optical flow',Number);
    graphname_Combined=strcat('Combined the results ',Number);
    PVget_graph_desc(predictors(:,5), yDetermPred3, [] ,observed, boundaries_3, [] ,graphname_Combined_3); % Combined 
    PVget_graph_desc(predictors(:,5), yDetermPred4, [] ,observed, boundaries_4, [] ,graphname_Combined_4); % Combined 
    PVget_graph_desc(predictors(:,5), yDetermPred3, yDetermPred4, observed,boundaries_3 ,boundaries_4, graphname_Combined);  
    %% Calculate PICoverRate
    count_3 = 0;
    count_4 = 0;
    count_0 = 0;
    for i = 1:(size(observed,1))
        if observed(i)==0
            count_0 =count_0+1;
        else
           if (L_boundary_3(i)<=observed(i)) && (observed(i)<=U_boundary_3(i))
               count_3 = count_3+1;
           end
           if (L_boundary_4(i)<=observed(i)) && (observed(i)<=U_boundary_4(i))
               count_4 = count_4+1;
           end
        end
    end
    PICoverRate_3 = 100*count_3/(size(observed,1)-count_0);  
    PICoverRate_4 = 100*count_4/(size(observed,1)-count_0);  
    %% Calculate RMSE
    data_num=size(yDetermPred4,1);
    count_0 =0;
    for i=1:data_num %SE=Square Error
         if observed(i)==0
             count_0 =count_0+1;
         else
             SE(i,1)= (yDetermPred3(i) - observed(i))^2;   
             SE(i,2)= (yDetermPred4(i) - observed(i))^2;          
         end
    end
    RMSE(1)=sqrt(sum(SE(:,1))/(48-count_0));     
    RMSE(2)=sqrt(sum(SE(:,2))/(48-count_0));     
    evaluation = horzcat(PICoverRate_3,PICoverRate_4,RMSE);
end