    %% Integrate individual forecasting algorithms
    function PVset_err_distribution(y_ValidEstIndv,valid_data,valid_predictors,ValidDays,path)
        start_err_distribution = tic;   
        %% load file
        building_num = num2str(valid_data(2,1));
        load_name = '\PV_pso_coeff_';
        load_name = strcat(path,load_name,building_num,'.mat');
        load(load_name,'-mat');
        %% three method
        % integrate into one ensemble forecasting model with optimal coefficients
        [~,numCols]=size(coeff(1,:));
        for hour = 1:24
            for i = 1:numCols
                if i == 1
                   y_est(1+(hour-1)*2:hour*2,:) = coeff(hour,i).*y_ValidEstIndv(i).data(1+(hour-1)*2:hour*2,:);
                else
                   y_est(1+(hour-1)*2:hour*2,:) = y_est(1+(hour-1)*2:hour*2,:) + coeff(hour,i).*y_ValidEstIndv(i).data(1+(hour-1)*2:hour*2,:);  
                end
            end
        end       
        % Restructure
        for day = 1:ValidDays        
            y_ValidEstComb(1+(day-1)*48:day*48, 1) = y_est(:, day);
        end
        % error from validation data[%] error[%], hours, Quaters    
        err = [y_ValidEstComb - valid_data(:,end) valid_predictors(:,5) valid_predictors(:,6)];  
        [row_err,~]=size(err);
        for n=1:row_err/48
            err([48*n-47:48*n],2)=transpose([0 0 1 1 2 2 3 3 4 4 5 5 6 6 7 7 8 8 9 9 10 10 11 11 12 12 13 13 14 14 15 15 16 16 17 17 18 18 19 19 20 20 21 21 22 22 23 23]) ;
        end
        % Initialize the structure for error distribution
        % structure of err_distribution.data is as below:
        % row=25hours(0~24 in "LongTermPastData"), columns=4quarters.
        % For instance, "err_distribution(1,1).data" means 0am 0(first) quarter, which contains array like [e1,e2] 
        for hour = 1:25
            for quarter = 1:2
                err_distribution_3(hour,quarter).data(1) = NaN;            
            end
        end   
        % build the error distibution
        for k = 1:size(err,1)
            if isnan(err_distribution_3(err(k,2)+1, err(k,3)).data(1)) == 1
                err_distribution_3(err(k,2)+1, err(k,3)).data(1) = err(k,1);
            else
                err_distribution_3(err(k,2)+1, err(k,3)).data(end+1) = err(k,1);
            end
        end 
        %% four method
        [~,numCols]=size(coeff4(1,:));
        for hour = 1:24
            for i = 1:numCols
                if i == 1
                   y_est(1+(hour-1)*2:hour*2,:) = coeff4(hour,i).*y_ValidEstIndv(i).data(1+(hour-1)*2:hour*2,:);
                else
                   y_est(1+(hour-1)*2:hour*2,:) = y_est(1+(hour-1)*2:hour*2,:) + coeff4(hour,i).*y_ValidEstIndv(i).data(1+(hour-1)*2:hour*2,:);  
                end
            end
        end       
        % Restructure
        for day = 1:ValidDays        
            y_ValidEstComb(1+(day-1)*48:day*48, 1) = y_est(:, day);
        end
        % error from validation data[%] error[%], hours, Quaters    
        err = [y_ValidEstComb - valid_data(:,end) valid_predictors(:,5) valid_predictors(:,6)];  
        [row_err,~]=size(err);
        for n=1:row_err/48
            err([48*n-47:48*n],2)=transpose([0 0 1 1 2 2 3 3 4 4 5 5 6 6 7 7 8 8 9 9 10 10 11 11 12 12 13 13 14 14 15 15 16 16 17 17 18 18 19 19 20 20 21 21 22 22 23 23]) ;
        end
        % Initialize the structure for error distribution
        % structure of err_distribution.data is as below:
        % row=25hours(0~24 in "LongTermPastData"), columns=4quarters.
        % For instance, "err_distribution(1,1).data" means 0am 0(first) quarter, which contains array like [e1,e2] 
        for hour = 1:25
            for quarter = 1:2
                err_distribution_4(hour,quarter).data(1) = NaN;            
            end
        end   
        % build the error distibution
        for k = 1:size(err,1)
            if isnan(err_distribution_4(err(k,2)+1, err(k,3)).data(1)) == 1
                err_distribution_4(err(k,2)+1, err(k,3)).data(1) = err(k,1);
            else
                err_distribution_4(err(k,2)+1, err(k,3)).data(end+1) = err(k,1);
            end
        end 
       %% save file
        save_name='\PV_err_distribution_';
        building_num = num2str(valid_data(1,1)); % Get building index
        save_name = strcat(path,save_name,building_num,'.mat');
        save(save_name,'err_distribution_3','err_distribution_4')
        end_err_distribution = toc(start_err_distribution)
    end