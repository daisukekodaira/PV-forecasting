    %% Integrate individual forecasting algorithms
    function PVset_err_distribution(y_ValidEstIndv,valid_data,train_data,path)
        start_err_distribution = tic;           
        %% load file
        building_num = num2str(valid_data(2,1));
        load_name = '\PV_pso_coeff_';
        load_name = strcat(path,load_name,building_num,'.mat');
        load(load_name,'-mat');
        coeff=coeff;
        coeff4=coeff4;
        %% create test data and training data
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
        for i=1:size(train_data,1)/48
            past_data(1:48,i) = train_data(48*i-47:48*i,15); % forecast generation
        end
        Past_Data = past_data(1:48,end-29:end);
        for i=1:30
            actual_measurements(:,i) = valid_data(48*i-47:48*i,15); % Actual measurement generation
        end
        percentage = 0.05;
        SE = sqrt(var(Past_Data,0,2)); 
        Past_Data = sort(Past_Data,2);
        n = size(Past_Data,2);
        for i = 1:48
            t(i,1) = Past_Data(i, round((1+percentage)/2)); 
        end
        err = t.*SE*(sort(1/n))*(sort(n-1));   
        L_boundary = y_est - err; % past lower boundary
        for m = 1:30
            for i = 1:48
                if L_boundary(i,m) < 0
                    L_boundary(i,m) = 0;
                end
            end
        end
        U_boundary = y_est + err; % past upper boundary
        count(1:30,1) = 0;
        n=48;
        for m=1:30
            for i=1:48
                if L_boundary(i,m)<=actual_measurements(i,m) && actual_measurements(i,m)<=U_boundary(i,m)
                    count(m,1)=count(m,1)+1;
                end
            end
        end
        PICP=count/n; % cover rate (30 days)       
        [max_PICP,m]=max(PICP); 
        for i=1:30
            pv_predict(48*i-47:48*i,1) = y_est(:,i);
            UB(48*i-47:48*i,1) = U_boundary(:,i);
            LB(48*i-47:48*i,1) = L_boundary(:,i);
        end
        train_data = (horzcat(valid_data(1:48*30,7:8),pv_predict))';
        test_data = (horzcat(valid_data(1:48,7:8),y_est(1:48,m)))';
        boundary = horzcat(UB,LB);
        pso_boundary = boundary(48*29+1:48*30,:);
        numFeatures = size(train_data,1); % Number of input layer
        numResponses = 2; % Number of output layer
        numHiddenUnits = 25; % Number of the first hidden layer
        ub1(1,1:numFeatures)=1;
        lb1(1,1:numFeatures)=0;
        ub2(1,1:numHiddenUnits)=1;
        lb2(1,1:numHiddenUnits)=0;        
        options_pso = optimoptions('particleswarm', 'MaxIterations',2000,'FunctionTolerance', 1e-25, 'MaxStallIterations', 1500,'Display', 'none');
        options = trainingOptions('adam', ...
            'MaxEpochs',200, ...
            'GradientThreshold',1.2, ...
            'InitialLearnRate',0.01, ...
            'LearnRateSchedule','piecewise', ...
            'LearnRateDropPeriod',125, ...
            'LearnRateDropFactor',0.2, ...
            'Verbose',0);        % training option
        test_data(3,:) = (y_est(:,m))';
        PICP = max_PICP;
        %% decide weight
        while PICP<0.95 
            objFunc = @(weight) objectiveFunc(weight, y_est(:,m), pso_boundary);
            W = particleswarm(objFunc,numFeatures,lb1,ub1, options_pso);    % Weights between the input layer and the first hidden layer
            Weight1(1,:)=W;
            Weight1(2,:)=W;
            objFunc = @(weight) objectiveFunc(weight, y_est(:,m), pso_boundary);
            W = particleswarm(objFunc,numHiddenUnits,lb2,ub2, options_pso);   % Weights between the first hidden layer and the output layer
            Weight2(1,:)=W;
            Weight2(2,:)=W;            
            Layers = [ ...
                sequenceInputLayer(numFeatures) 
                fullyConnectedLayer(numResponses,'Weights',Weight1)
                lstmLayer(numHiddenUnits)
                fullyConnectedLayer(numResponses,'Weights',Weight2)
                regressionLayer]; 
            UBLB_net = trainNetwork(train_data,(boundary)',Layers,options);   % train
           % test PI
            UBLB_net = predictAndUpdateState(UBLB_net,test_data);
            [UBLB_net,YPred_solar(:,1:48)] = predictAndUpdateState(UBLB_net,test_data(:,end-48+1:end));
            numTimeStepsTest = size(test_data,2);
            for i = 1:numTimeStepsTest
                [UBLB_net,pre_UBLB(:,i+48)] = predictAndUpdateState(UBLB_net,test_data(:,i),'ExecutionEnvironment','auto');
            end
            result_UBLB=(pre_UBLB(:,48+1:end))';
            upBound = result_UBLB(:,1);
            lwBound = result_UBLB(:,2);
            for i=1:size(result_UBLB,1)
                if upBound(i,1)<0
                    upBound(i,1)=0;
                    lwBound(i,1)=0;
                end
                if lwBound(i,1)<0
                    lwBound(i,1)=0;
                end        
            end
            % calculate PICP,PINAW,CWC
            dif_boundary=upBound-lwBound;
            count=0;
            n=48;
            x=100;
            for i=1:48
                if lwBound(i)<=actual_measurements(i,m) && actual_measurements(i,m)<=upBound(i)
                    count=count+1;
                end
            end
            PICP=count/n;
            if PICP < 1 - percentage
                ganma=1;
            else
                ganma=0;
            end
            PINAW=sum(dif_boundary)/n/(max(y_est(:,30))-min(y_est(:,30)));    
            CWC=PINAW*(1+ganma/exp(x*(PICP-(1 - percentage))));               
        end
        % function of PSO
        function total_err = objectiveFunc(weight, y_est, result_UBLB) 
            ensembleForecasted = sum(y_est.*weight, 2);  
            err1 = sum(abs(result_UBLB(:,1) - ensembleForecasted));
            err2 = sum(abs(result_UBLB(:,2) - ensembleForecasted));
            err3 = abs(1-sum(weight));
            total_err = err1+err2+100*err3;
        end   
       %% save file
        save_name='\PV_err_distribution_';
        building_num = num2str(valid_data(1,1)); % Get building index
        save_name = strcat(path,save_name,building_num,'.mat');
        save(save_name)
        end_err_distribution = toc(start_err_distribution)
    end