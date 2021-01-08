% Load prediction: Foecasting algorithm 
% function flag = demandForecast(shortTermPastData, ForecastData, ResultData)
%     flag =1 ; if operation is completed successfully
%     flag = -1; if operation fails.
%     This function depends on demandModel.mat. If these files are not found return -1.
%     The output of the function is "ResultData.csv"
function flag = PVget_getPVModel(ShortTermPastData, forecastData)
    tic;    
    %% Load data
    if strcmp(ShortTermPastData, 'NULL') == 0 || strcmp(forecastData, 'NULL') == 0 || strcmp(resultdata, 'NULL') == 0
        short_past_load = csvread(ShortTermPastData,1,0);
        predictors = csvread(forecastData,1,0);
    else
        flag = -1;
        return
    end     
    target = csvread('TargetData.csv',1,0);   
    [row_i,~]=size(predictors);
    [row_k,~]=size(target);
    sin_data(:,1) = sin(predictors(:,5)/12*pi);
    cos_data(:,1) = cos(predictors(:,5)/12*pi);
    predictors=horzcat(predictors(:,1:6),sin_data,cos_data,predictors(:,7:11));
    [row_pre,~]=size(predictors);
    for n=1:row_pre/48
        predictors([48*n-47:48*n],5)=transpose([0 0 1 1 2 2 3 3 4 4 5 5 6 6 7 7 8 8 9 9 10 10 11 11 12 12 13 13 14 14 15 15 16 16 17 17 18 18 19 19 20 20 21 21 22 22 23 23]) ;
    end
    for PV_ID=15:27
        i=1;
        k=1;
        for n=1:row_i
            if predictors(n,1)==PV_ID
               longForecastData(i,:)=predictors(n,:);
               i=i+1;
            end
        end   
        for n=1:row_k
            if target(n,1)==PV_ID
               longtargetdata(k,:)=target(n,:);
               k=k+1;
            end
        end
        row_f=size(longForecastData,1)/48;
        for m=1:row_f
            ForecastData=longForecastData(48*m-47:48*m,:);
            targetdata=longtargetdata(48*m-47:48*m,:);
            observed=targetdata(:,2);
            opticalflow_Forecast=targetdata(:,3);
    %% Load .mat files from given path of "shortTermPastData"
            filepath = fileparts(ShortTermPastData);
            buildingIndex = targetdata(1,1);    
    %% Error recognition: Check if mat files exist
            name1 = [filepath, '\', 'PV_Model_', num2str(buildingIndex), '.mat'];
            name2 = [filepath, '\', 'PV_err_distribution_', num2str(buildingIndex), '.mat'];
            name3 = [filepath, '\', 'PV_pso_coeff_', num2str(buildingIndex), '.mat'];
            if exist(name1) == 0 || exist(name2) == 0 || exist(name3)== 0 
               flag = -1;
               return
            end        
    %% Load mat files
            buildingIndex = num2str(buildingIndex);
            load_name = '\PV_pso_coeff_';
            load_name = strcat(filepath,load_name,buildingIndex,'.mat');
            load(load_name,'-mat');
    %% Prediction for test data   
            predicted_PV(1).data = PVget_kmeans_Forecast(ForecastData,filepath);   
            predicted_PV(2).data = PVget_ANN_Forecast(ForecastData, filepath);   
            predicted_PV(3).data = PVget_LSTM_Forecast(ForecastData, filepath);   
            predicted_PV(4).data = PVget_opticalflow_Forecast(opticalflow_Forecast, filepath);     
%% three method
            %% Get Deterministic prediction result   
            [~,numCols]=size(coeff(1,:));
            for hour = 1:24              
                for i = 1:numCols % the number of prediction methods(k-means, ANN and LSTM)
                    if i == 1
                       yDetermPred3(1+(hour-1)*2:hour*2,:) = coeff(hour,i).*predicted_PV(i).data(1+(hour-1)*2:hour*2);
                    else
                       yDetermPred3(1+(hour-1)*2:hour*2,:) = yDetermPred3(1+(hour-1)*2:hour*2,:) + coeff(hour,i).*predicted_PV(i).data(1+(hour-1)*2:hour*2);  
                    end
                end
            end   
            %% Create PI
            [L_boundary_3, U_boundary_3] = PVget_PI(ForecastData,yDetermPred3,filepath);
           %% Display graph  
            % make x timestep
            timestep=csvread(forecastData,1,4,[1,4,48,5]);
            xtime=timestep(:,1);
            max_xtime=max(xtime);
            for i=1:size(xtime,1)
                if xtime(i) < xtime(1)
                   xtime(i)=xtime(i)+24;
                end
            end  
            boundaries_3 =  [L_boundary_3, U_boundary_3];           
            % Cover Rate of PI (three method)
            count = 0;
            for i = 15:37
                if (L_boundary_3(i)<=observed(i)) && (observed(i)<=U_boundary_3(i))
                   count = count+1;
                end
            end
            PICoverRate_3 = 100*count/(37-15+1);                 
            % for calculate MAPE  (Mean Absolute Percentage Error)
            a=0;
            maxreal=max(observed);
            for i=1:(size(yDetermPred3,1))
                if observed(i)~=0 && observed(i)>maxreal*0.05
                    if yDetermPred3(i) ~=0
                       MAE(i,1) = (abs(yDetermPred3(i) - observed(i))./observed(i)); % combined
                       a=a+1;
                    end
                end
            end               
            MAPE(1)=sum(MAE(:,1))/a *100;              
            % for calculate RMSE(Root Mean Square Error)
            data_num=size(yDetermPred3,1);
            for i=1:data_num %SE=Square Error
                SE(i,1)= (yDetermPred3(i) - observed(i))^2;             
            end               
            RMSE(1)=sqrt(sum(SE(:,1))/48);               
%% four method
      %% Get Deterministic prediction result                 
            [~,numCols]=size(coeff(1,:));
            for hour = 1:24
                if  hour==10 || hour==11 || hour==12 || hour==13 || hour==14 || hour==15 || hour==16 || hour==17           
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
        %% Create PI
        [L_boundary_4, U_boundary_4] = PVget_PI(ForecastData,yDetermPred4,filepath);
        %% Display graph  
        % make x timestep
            timestep=csvread(forecastData,1,4,[1,4,48,5]);
            xtime=timestep(:,1);
            max_xtime=max(xtime);
            for i=1:size(xtime,1)
                if xtime(i) < xtime(1)
                    xtime(i)=xtime(i)+24;
                end
            end  
            boundaries_4 =  [L_boundary_4, U_boundary_4];  
        % display graph
            Number=num2str(PV_ID);
            Month=num2str(ForecastData(1,3));
            day=num2str(ForecastData(1,4));
            graphname_Combined=strcat('Combined the results ',Number,'(',Month,'/',day,')');
            %PVget_graph_desc(xtime, yDetermPred4, observed ,boundaries_4, graphname_Combined, max_xtime);  
            PVget_graph_desc_all(xtime, yDetermPred3, yDetermPred4, observed,boundaries_3 ,boundaries_4, graphname_Combined, max_xtime);  
         % Cover Rate of PI (four method)
            count = 0;
            for i = 15:37
                if (L_boundary_4(i)<=observed(i)) && (observed(i)<=U_boundary_4(i))
                    count = count+1;
                end
            end
            PICoverRate_4 = 100*count/(37-15+1);                
        % for calculate MAPE  (Mean Absolute Percentage Error)
            f=0;
            maxreal=max(observed);
            for i=1:size(yDetermPred4,1)
                if observed(i)~=0 && observed(i)>maxreal*0.05                   
                   if yDetermPred4(i) ~=0
                       MAE(i,2) = (abs(yDetermPred4(i) - observed(i))./observed(i)); % combined
                       f=f+1;
                   end
                end
            end
            MAPE(2)=sum(MAE(:,2))/f *100;
        % for calculate RMSE(Root Mean Square Error)
            data_num=size(yDetermPred4,1);
            for i=1:data_num %SE=Square Error
                SE(i,2)= (yDetermPred4(i) - observed(i))^2;            
            end
            RMSE(2)=sqrt(sum(SE(:,2))/48);           
            Data=horzcat(PV_ID,ForecastData(1,4),PICoverRate_3,PICoverRate_4,RMSE(1),RMSE(2),MAPE(1),MAPE(2));
            if m==1 && PV_ID==15
                data=Data;
            else
                data=vertcat(data,Data);
            end
        end                   
        flag = 1;
        clearvars shortTermPastData;
        clearvars ForecastData;
        clearvars observed;
        clearvars targetdata;
        clearvars opticalflow_Forecast;
        clearvars yDetermPred3;
        clearvars yDetermPred4;
        clearvars prob_prediction;
    end
    data=array2table(data);
    data.Properties.VariableNames{'data1'} = 'ID';
    data.Properties.VariableNames{'data2'} = 'day';
    data.Properties.VariableNames{'data3'} = 'PICoverRate_3';
    data.Properties.VariableNames{'data4'} = 'PICoverRate_4';
    data.Properties.VariableNames{'data5'} = 'RMSE(combined the results without optical flow)';
    data.Properties.VariableNames{'data6'} = 'RMSE(combined the results with optical flow)';
    data.Properties.VariableNames{'data7'} = 'MAPE(combined the results without optical flow)';
    data.Properties.VariableNames{'data8'} = 'MAPE(combined the results with optical flow)';
    savename=strcat('RMSE&CoverRate&MAPE.csv');
    writetable(data,savename) 
    toc; 
end