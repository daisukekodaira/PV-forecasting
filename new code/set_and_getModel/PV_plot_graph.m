function PV_plot_graph(forecast_1day,boundary,name)  
    f = figure;
    hold on;
    p1=plot(forecast_1day(:,1),forecast_1day(:,2),'g','LineWidth',1);
    p2=plot(forecast_1day(:,1),forecast_1day(:,end),'r','LineWidth',1);
    if isempty(boundary) == 0 
        p3=plot(forecast_1day(:,1),boundary(:,1),'b--','LineWidth',0.7);
        plot(forecast_1day(:,1),boundary(:,2),'b--','LineWidth',0.7);
    end
    xlabel('時間 [hour]');
    ylabel('発電出力 [kW]');
    title(name);
    if isempty(boundary) == 0 
        legend([p1,p2,p3],'予測値', '実測値', '予測区間');
    else
        legend('予測値', '実測値');
    end
    hold off;
end