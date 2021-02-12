% Return the boundaries of confidence interval
function [lwBound, upBound] = PVget_PI(PV_ID,yDetermPred,time_data,path)    
    %% Load mat files
    building_num = num2str(PV_ID(1,1));
    load_name = '\PV_err_distribution_';
    load_name = strcat(path,load_name,building_num,'.mat');
    load(load_name,'-mat');
    %% create PI
    test_data = (horzcat(time_data,yDetermPred))';
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
end    