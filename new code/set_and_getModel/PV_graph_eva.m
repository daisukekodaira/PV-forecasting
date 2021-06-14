function error_data = PV_graph_eva(PV_ID,forecast_1day,boundaries_2,boundaries_3,range)
    Number=num2str(PV_ID);
    for i=2:6
        if i==2
            name=strcat('ANN',Number);
        elseif i==3
            name=strcat('LSTM',Number);
        elseif i==4
            name=strcat('opticalflow',Number);
        elseif i==5
            name=strcat('machine learning',Number);
        else 
            name=strcat('machine learning and opticalflow',Number);
        end
        if i == 2 || i == 3 || i ==4
            PV_plot_graph(forecast_1day(:,[1 i end]),[],name);
        elseif i == 5
            PV_plot_graph(forecast_1day(:,[1 i end]),boundaries_2,name);
        else
            PV_plot_graph(forecast_1day(:,[1 i end]),boundaries_3,name);
        end
    end
    % calculate RMSE
    for i=1:range %SE=Square Error
        SE(i,1)= (forecast_1day(i,2)-forecast_1day(i,7))^2;
        SE(i,2)= (forecast_1day(i,3)-forecast_1day(i,7))^2;
        SE(i,3)= (forecast_1day(i,4)-forecast_1day(i,7))^2;
        SE(i,4)= (forecast_1day(i,5)-forecast_1day(i,7))^2;    
        SE(i,5)= (forecast_1day(i,6)-forecast_1day(i,7))^2;
    end               
    RMSE(1)=sqrt(sum(SE(:,1))/range);
    RMSE(2)=sqrt(sum(SE(:,2))/range);
    RMSE(3)=sqrt(sum(SE(:,3))/range);
    RMSE(4)=sqrt(sum(SE(:,4))/range);   
    RMSE(5)=sqrt(sum(SE(:,5))/range); 
    % calculate PI cover late
    count_2 = 0;
    count_3 = 0;
    for i = 1:range
        if (boundaries_2(i,1)<=forecast_1day(i,5)) && (forecast_1day(i,5)<=boundaries_2(i,2))
            count_2 = count_2+1;
        end
        if (boundaries_3(i,1)<=forecast_1day(i,6)) && (forecast_1day(i,6)<=boundaries_3(i,2))
            count_3 = count_3+1;
        end
    end
    PICoverRate_2 = 100*count_2/range;  
    PICoverRate_3 = 100*count_3/range; 
    error_data = horzcat(PV_ID,RMSE,PICoverRate_2,PICoverRate_3);
end