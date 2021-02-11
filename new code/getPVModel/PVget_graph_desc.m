function PVget_graph_desc(x, y_pred,y_pred_4, y_true, boundaries_1, boundaries_2,name)     
    %% Graph description for prediction result 
    f = figure;
    hold on;
    p1=plot(x, y_pred,'g','LineWidth',1);
    if isempty(y_pred_4) == 0
        p2=plot(x, y_pred_4,'b','LineWidth',1);
    end
    if isempty(y_true) == 0
        p3=plot(x, y_true,'r','LineWidth',1);
    end
    if isempty(boundaries_1) == 0
        p4=plot(x,boundaries_1(:,1),'m--','LineWidth',0.7);
        p5=plot(x,boundaries_1(:,2),'m--','LineWidth',0.7);
    end
    if isempty(boundaries_2) == 0
        p6=plot(x,boundaries_2(:,1),'c--','LineWidth',0.7);
        p7=plot(x,boundaries_2(:,2),'c--','LineWidth',0.7);
    end
    xlabel('Time [h]');
    ylabel('Generation [kW]');
    title(name);
    if isempty(boundaries_1) == 0 && isempty(boundaries_2) == 0
        legend([p1,p2,p3,p4,p6,p5,p7],'predicted Load without optical flow', 'predicted Load with optical flow','True','Prediction Interval(without optical flow)','Prediction Interval(with optical flow)');
    else
        legend('predicted Load', 'True', 'Prediction Interval');
    end
    hold off;
end