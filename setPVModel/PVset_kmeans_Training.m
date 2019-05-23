function PVset_kmeans_Training(LongTermpastData, path)

    %% Read inpudata
    train_data = LongTermpastData(~any(isnan(LongTermpastData),2),:); % Eliminate NaN from inputdata

    %     %% Format error check (to be modified)
    %     % "-1" if there is an error in the LongpastData's data form, or "1"
    %     [~,number_of_columns1] = size(train_data);
    %     if number_of_columns1 == 12
    %         error_status = 1;
    %     else
    %         error_status = -1;
    %     end

%     % Change the given value about "Cloud" from 2 to 1 at longTermPastData 
%     % It is only for KEPRI database (only for SGS project) because of KEPRI's input data problem.
%     [number_of_rows_in_the_train_data_sunlight,~] = size(train_data);
%     for for_change_cloud_2_to_1_sunlight=1:1:number_of_rows_in_the_train_data_sunlight
%         if  train_data(for_change_cloud_2_to_1_sunlight,10)==2
%               train_data(for_change_cloud_2_to_1_sunlight,10)=1 ;
%         end
%     end
    
    %% Kmeans clustering of sunlight data set
    % Extract appropriate data from inputdata for sunlight prediction
    %   P1(DayOfWeek) and P2(Holiday) are eliminated because 
    %   Sunlight doesn't have correlation with Day of week and holiday or not.
    %   These two predictor could make the simulation result worse.
    past_feature_sunlight = horzcat(train_data(:,1:5), train_data(:,9:10)); % combine 1~5 columns & 9,10 columns
    past_load_sunlight = train_data(:,11); % 11 : Real Sunlight
    % Set K for sunlight. 50 is experimentally chosen
    k_sunlight = 50; 
    [idx_sunlight,c_sunlight] = kmeans(past_load_sunlight,k_sunlight);
    % train model
    nb_sunlight = fitcnb(past_feature_sunlight, idx_sunlight,'Distribution','kernel');
        
    %% Kmeans clustering of PV generation data set
    % Extract appropriate data from inputdata for PV prediction
    %   In SGS project, P5(SolarIrradiance) has problem in terms of data itself. 
    %   So,  P5(SolarIrradiance) is not utilized to make prediction model.
    past_feature_PV = horzcat(train_data(:,5), train_data(:,9:10)); % Combine hour and P3(Temp), P4(CloudCover)
    past_load_PV = train_data(:,12); % 12 : load (PV generation)    
    
    %% Kmeans clustering of PV
    % Set K for sunlight. 50 is experimentally chosen
    k_PV = 35;
    [idx_PV,c_PV] = kmeans(past_load_PV,k_PV);
    % train model for Baysian theroy
    nb_PV = fitcnb(past_feature_PV, idx_PV,'Distribution','kernel');

    %% Save trained data in .mat files
    % idx_PV: 
    % idx_sunlight:
    % k_PV: optimal K for PV (experimentally chosen)
    % k_sunlight: optimal K for sunlight (experimentally chosen)
    % nb_PV: Trained Baysian model for PV
    % nb_sunlight: Trained Baysian model for sunlight
    % c_PV: 
    % c_sunlight:
    building_num = num2str(LongTermpastData(2,1)); % building number is necessary to be distinguished from other builiding mat files
    save_name = '\PV_Model_'; 
    save_name = strcat(path,save_name,building_num,'.mat'); 
    save(save_name, 'idx_PV','idx_sunlight', 'k_PV','k_sunlight', 'nb_PV','nb_sunlight', 'c_PV', 'c_sunlight');
end