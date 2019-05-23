clear all;
clc;
close all;
pass = pwd;
y_pred = PVget_getPVModel([pwd,'\','shortterm.csv'],...
                        [pwd,'\','forecast.csv'],...
                        [pwd,'\','ResultData.csv'])