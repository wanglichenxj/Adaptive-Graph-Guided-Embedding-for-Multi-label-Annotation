% =====================
% Adaptive Graph Guided Embedding for Multi-label Annotation (AG2E)
% =====================
% Author: Lichen Wang
% Date: Dec. 27, 2018
% E-mail: wanglichenxj@gmail.com

% Citation:
% @inproceedings{AG2E_IJCAI18_Lichen,
% 	title={Adaptive Graph Guided Embedding for Multi-label Annotation.},
% 	author={Wang, Lichen and Ding, Zhengming and Fu, Yun},
% 	booktitle={IJCAI},
% 	pages={2798--2804},
% 	year={2018}
% }
% =====================

clc;
clear all;
close all;
warning off;

% Load datasets
load('Datasets/CUB_VGG_feature.mat');
addpath('Codes');

% Feature normalization
Xl = fea_norm(Xl);
Xu = fea_norm(Xu);

% Set parameters
psize = 100;
mu = 50;
lambda = 100;
k_w = 20;
t_w = 50;
k_s = 80;

% Running AG2E for multi-label recovery
disp('===== CUB Dataset Test =====');
[Precision, Recall, F1, Retri] = ...
    AG2E(Xl,Xu,Yl,Yu,psize,mu,lambda,k_w,t_w,k_s);
% Display performance
disp('==== Average Performance: ====');
disp(['Precision = ', num2str(Precision),...
    '  Recall = ', num2str(Recall),'  F1 = ',num2str(F1),...
    '  Non_retri = ',num2str(Retri)]);

