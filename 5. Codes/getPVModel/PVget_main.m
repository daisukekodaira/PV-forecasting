clear all;
clc;
close all;
warning('off','all');
y_pred = PVget_getPVModel([pwd,'\','PV_ShortTerm_201808010819.csv'],...
                        [pwd,'\','PV_Forecast_201808010802.csv'],...
                        [pwd,'\','ResultData.csv'])