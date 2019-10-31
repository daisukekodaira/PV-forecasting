clear all
clc
close all
warning('off','all');
y_pred = PVget_getPVModel([pwd,'\','PST_20190210DDG.csv'],...
                        [pwd,'\','PFP_20190210DDG.csv'],...
                        [pwd,'\','ResultData.csv'])