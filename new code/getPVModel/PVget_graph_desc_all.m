% -----------------------------------------------------------------
% This function is only for debugging
% -------------------------------------------------------------------
function PVget_graph_desc_all(x, y_pred_3,y_pred_4, y_true, boundaries_1, boundaries_2,name,max_xtime)     
    %% CHANGE hour and value
    %     if you want see  0 to 23 graph 
    t=0;   
    for i=1:size(x,1)
           t=t+1;
           if x(i) == max_xtime 
               set_point=t;           
           end
    end
    x1=zeros(size(x)); % chage x of form (0~23 hour)
    x1(end-set_point+1:end,1)=x(1:set_point);
    x1(1:end-set_point,1)=x(set_point+1:end); 
    y_pred1=zeros(size(y_pred_3));% chage y_pred of form (0~23 hour)
    y_pred1(end-set_point+1:end,1)=y_pred_3(1:set_point);
    y_pred1(1:end-set_point,1)=y_pred_3(set_point+1:end);
    y_pred2=zeros(size(y_pred_4));% chage y_pred of form (0~23 hour)
    y_pred2(end-set_point+1:end,1)=y_pred_4(1:set_point);
    y_pred2(1:end-set_point,1)=y_pred_4(set_point+1:end);
    y_true1=zeros(size(y_true));
    y_true1(end-set_point+1:end,1)=y_true(1:set_point);
    y_true1(1:end-set_point,1)=y_true(set_point+1:end);% chage y_true of form (0~23 hour)   
    %% Graph description for prediction result 
    f = figure;
    hold on;
    p1=plot(x, y_pred_3,'g','LineWidth',1);
    p2=plot(x, y_pred_4,'b','LineWidth',1);
    if isempty(y_true) == 0
        p3=plot(x, y_true,'r','LineWidth',1);
    else
        p3=plot(zeros(x,1),'LineWidth',1);
    end
    if isempty(boundaries_1) == 0
        boundaries1=zeros(size(boundaries_1));
        boundaries1(end-set_point+1:end)=boundaries_1(1:set_point);
        boundaries1(1:end-set_point)=boundaries_1(set_point+1:end);% chage boundaries of form (0~23 hour)
        p4=plot(x,boundaries_1(:,1),'c--','LineWidth',0.7);
        p5=plot(x,boundaries_1(:,2),'c--','LineWidth',0.7);
    end
    if isempty(boundaries_2) == 0
        boundaries2=zeros(size(boundaries_2));
        boundaries2(end-set_point+1:end)=boundaries_2(1:set_point);
        boundaries2(1:end-set_point)=boundaries_2(set_point+1:end);% chage boundaries of form (0~23 hour)
        p6=plot(x,boundaries_2(:,1),'m--','LineWidth',0.7);
        p7=plot(x,boundaries_2(:,2),'m--','LineWidth',0.7);
    end
    xlabel('Time [h]');
    ylabel('Generation [kW]');
    title(name);
    legend([p1,p2,p3,p4,p6,p5,p7],'predicted Load without optical flow', 'predicted Load with optical flow','True','Prediction Interval(without optical flow)', 'Prediction Interval(with optical flow)');
end