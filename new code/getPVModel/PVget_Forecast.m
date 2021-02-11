function RMSE=PVget_Forecast(predicted_PV,PV_ID,observed,forecastData)
%% Display graph  
% make x timestep
timestep=csvread(forecastData,1,4,[1,4,48,5]);
xtime=timestep(:,1);
for i=1:size(xtime,1)
    if xtime(i) < xtime(1)
       xtime(i)=xtime(i)+24;
    end
end  
% display graph
Number=num2str(PV_ID);
graphname_kmeans=strcat('k-means for forecast data ',Number);
graphname_ANN=strcat('ANN for forecast data ',Number);
graphname_LSTM=strcat('LSTM for forecast data ',Number);
graphname_opticalflow=strcat('opticalflow ',Number);
PVget_graph_desc(xtime, predicted_PV(1).data, [], observed, [], [], graphname_kmeans); % k-means
PVget_graph_desc(xtime, predicted_PV(2).data, [], observed, [], [], graphname_ANN); % ANN
PVget_graph_desc(xtime, predicted_PV(3).data, [], observed, [], [], graphname_LSTM); % LSTM
PVget_graph_desc(xtime, predicted_PV(4).data, [], observed, [], [], graphname_opticalflow);     
%% calculate RMSE
data_num=size(predicted_PV(1),1);
for i=1:data_num %SE=Square Error
    SE(i,1)= (predicted_PV(1).data(i)-observed(i))^2;
    SE(i,2)= (predicted_PV(2).data(i)-observed(i))^2;
    SE(i,3)= (predicted_PV(3).data(i)-observed(i))^2;
    SE(i,4)= (predicted_PV(4).data(i)-observed(i))^2;             
end               
RMSE(1)=sqrt(sum(SE(:,1))/48);
RMSE(2)=sqrt(sum(SE(:,2))/48);
RMSE(3)=sqrt(sum(SE(:,3))/48);
RMSE(4)=sqrt(sum(SE(:,4))/48);   