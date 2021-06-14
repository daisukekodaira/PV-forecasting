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
                   y_est(1+(hour-1)*2:hour*2,:) = y_est(1+(hour-1)*2:hour*2,:) + coeff(hour,i).*y_ValidEstIndv(i).data(1+(hour-1)*2:hour*2,:);  % from valid_data
                end
            end
        end       
        for i=1:size(train_data,1)/48
            past_data(1:48,i) = train_data(48*i-47:48*i,end-1); % generation (30 days) from train_data
        end
        Past_Data = past_data(1:48,end-29:end);
        for i=1:30
            actual_measurements(:,i) = valid_data(48*i-47:48*i,end); % Actual measurement generation , valid_data is test data
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
        [~,m]=max(PICP);         % Select Best performance day
        for i=1:30
            pv_predict(48*i-47:48*i,1) = y_est(:,i);
            UB(48*i-47:48*i,1) = U_boundary(:,i);
            LB(48*i-47:48*i,1) = L_boundary(:,i);
        end
        train_data = horzcat(train_data(1:48*30,5),pv_predict)';
        boundary = horzcat(UB,LB);
        numFeatures = size(train_data,1); % Number of input layer
        numResponses = 2; % Number of output layer
        ub1 = [1,2,1,0.8];
        lb1 = [0,1.2,0,0];       
        options_pso = optimoptions('particleswarm', 'MaxIterations',2500,'FunctionTolerance', 1e-25, 'MaxStallIterations', 2000,'Display', 'none','ObjectiveLimit',0.8);
        options = trainingOptions('adam', ...
            'MaxEpochs',1, ...
            'LearnRateSchedule','piecewise', ...
            'Verbose',0);        % training option
        %% decide weight
            objFunc = @(weight) objectiveFunc(weight, y_est(:,m),(train_data(1,1:48))');
            W = particleswarm(objFunc,numFeatures*2,lb1,ub1, options_pso);    % Weights between the input layer and the first hidden layer
            Weight(1,:)=W(1:2);
            Weight(2,:)=W(3:4);           
            Layers = [ ...
                sequenceInputLayer(numFeatures) 
                fullyConnectedLayer(numResponses,'Weights',Weight)
                regressionLayer]; 
            UBLB_net = trainNetwork(train_data,(boundary)',Layers,options);   % train           
        % function of PSO
        function cwc = objectiveFunc(weight, Y_est,time_data) 
            for k =1:size(Y_est,1)
                UpBound(k,1) =  time_data(k,1)*weight(1)+Y_est(k,1)*weight(2);
                LwBound(k,1) =  time_data(k,1)*weight(3)+Y_est(k,1)*weight(4);
            end
            for i=1:size(Y_est,1)
                if UpBound(i,1)<0
                    UpBound(i,1)=0;
                    LwBound(i,1)=0;
                end
                if LwBound(i,1)<0
                    LwBound(i,1)=0;
                end        
            end            
            Dif_boundary=UpBound-LwBound;
            Count=0;
            n=48;
            x=100;
            for l=1:48
                if LwBound(l)<=actual_measurements(l,m) && actual_measurements(l,m)<=UpBound(l)
                    Count=Count+1;
                end
            end
            picp=Count/n;
            if picp < 1 - percentage
                Ganma=1;
            else
                Ganma=0;
            end
            pinaw=sum(Dif_boundary)/n/(max(Y_est)-min(Y_est));    
            cwc=pinaw*(1+Ganma/exp(x*(picp-(1 - percentage))));     
        end   
       %% save file
        save_name='\PV_err_distribution_';
        building_num = num2str(valid_data(1,1)); % Get building index
        save_name = strcat(path,save_name,building_num,'.mat');
        save(save_name)
        end_err_distribution = toc(start_err_distribution)
    end