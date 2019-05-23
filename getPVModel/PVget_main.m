clear all;
clc;
close all;
pass = pwd;
y_pred = PVget_getPVModel([pwd,'\','shortterm4.csv'],...
                        [pwd,'\','forecast4.csv'],...
                        [pwd,'\','ResultData.csv'])