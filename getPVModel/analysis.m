data= csvread('newpvdata4.csv',1,0);
PastData_ANN(~any(PastData_ANN(:,12),2),:) = []; 