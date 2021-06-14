% Return the boundaries of confidence interval
function [lwBound, upBound] = PV_ci(prob_prediction, percentage)    
    % Sort the array
    srtPred = sort(prob_prediction,2);
    size_PI = size(srtPred,2);
    lower = round(size_PI*percentage);
    upper = round(size_PI*(1-percentage));
    if lower < 1 
        lower = 1;
    elseif size_PI < lower
        lower = size_PI;
    end
    % boudaries must be more than zero
    lwBound = srtPred(:,lower);
    if lwBound < 0
        lwBound = 0;
    end
    upBound = srtPred(:,upper);
end    