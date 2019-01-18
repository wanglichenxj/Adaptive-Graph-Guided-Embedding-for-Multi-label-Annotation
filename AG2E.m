function [pre_res,rec_res,f1_res,retri_res]=AG2E(Xl,Xu,Yl,Yu,psize,mu,lambda,k_w,t_w,k_s)
% =====================
% Adaptive Graph Guided Embedding for Multi-label Annotation (AG2E)
% =====================
% Author: Lichen Wang
% Date: Dec. 27, 2018
% E-mail: wanglichenxj@gmail.com

% Input: Labeled and unlabeled feature metrix, Xl and Xu, in d*N format
%        Ground-truth label Yl and Yu(for evaluation)
%        Parameters: psize->Projection dimension mu lambda k_w t_w and k_s
% Output: Average performance of precision, recall, F1, 
%         and non-zero retrienval

% % Citation:
% @inproceedings{AG2E_IJCAI18_Lichen,
% 	title={Adaptive Graph Guided Embedding for Multi-label Annotation.},
% 	author={Wang, Lichen and Ding, Zhengming and Fu, Yun},
% 	booktitle={IJCAI},
% 	pages={2798--2804},
% 	year={2018}
% }
% =====================

% Show configurations
disp(['Parameters: Psize = ',num2str(psize),'  mu = ',num2str(mu),...
    '  lambda = ',num2str(lambda),'  k_w = ',num2str(k_w),...
    '  t_w = ',num2str(t_w),'  k_s = ',num2str(k_s)]);

% Get all variable sizes
n_l = size(Xl,2);
n_u = size(Xu,2);
n_x = n_l+n_u;
m_y = size(Yl,1);
m_x = size(Xl,1);

X = [Xl Xu]; % Comcatenate source and target feature

% Generate graph
option = [];
option.NeighborMode = 'KNN';
option.WeightMode = 'HeatKernel';
option.k = k_w;
option.t = t_w;
W = constructW(X',option);
W = full(W); % Convert from sparse metrix
D = diag(sum(W,2));
L = D-(W+W')./2;

% Initialize H and XHX
H = eye(n_x)-1/(n_x)*ones(n_x,n_x);
XHX=X*H*X';
% Initialize P
eig_matrix = X*L*X'+lambda*eye(m_x);
[P,~] = eigs(double(eig_matrix),double(XHX),psize,'SM');
P = single(P');

% Initialize S
PX=P*X;
k=k_s;
% Initialize weighted distance
distX_initial =  L2_distance_1(PX,PX);
[distXs, idx] = sort(distX_initial,2);
distX = distX_initial;
S = single(zeros(n_x));
rr = single(zeros(n_x,1));
for i = 1:n_x
    di = distXs(i,2:k+2);
    rr(i) = 0.5*(k*di(k+1)-sum(di(1:k)));
    id = idx(i,2:k+2);
    S(i,id) = (di(k+1)-di)/(k*di(k+1)-sum(di(1:k))+eps);   
end
alpha = mean(rr);

% save results for each optimization loop
pre_m = [];
rec_m = [];
f1_m = [];
retri_m = [];

% ===== Start optimization =====
disp('Start optimization:');
for loop=1:7
    
    % Update F
    if loop==1
        SS = (S+S')/2;
        D = diag(sum(SS));
        L = D-SS;
    end    
    Llu=L(1:n_l,n_l+1:n_x);
    Luu=L(n_l+1:n_x,n_l+1:n_x);    
    Luu=Luu+0.00001*eye(size(Luu));
    temp_Fu=-Yl*Llu/Luu;
    F=[Yl,temp_Fu];
    
    % Update S
    if loop ==1
        distX = distX;
    else        
        PX=P*X;
        distX =  L2_distance_1(PX,PX);
        [~, idx] = sort(distX,2);
    end
    distf = L2_distance_1(F,F);    
    S = zeros(n_x);
    for i=1:n_x                                                        
        idxa0 = idx(i,2:k+1);
        dfi = distf(i,idxa0);
        dxi = distX(i,idxa0);
        ad = -(dxi+mu*dfi)/(alpha);
        S(i,idxa0) = EProjSimplex_new(ad);
    end
    S = single(S); % singlize the S after the optimization    
    SS = (S+S')/2;                                       
    D = diag(sum(SS));
    L = D-SS;
    
    % Update P
    eig_matrix = X*L*X'+lambda*eye(m_x);
    [P,~] = eigs(double(eig_matrix),double(XHX),psize,'SM');
    P = single(P');  
    
    % Evaluation for each optimization loop
    Fu = F(:,n_l+1:n_x); % Get predicted multi-label
    [prec, rec, f1, retrieved] = evaluate_PRFN(Yu,Fu,5); % Evaluation
    
    % save results for each loop
    pre_m = [pre_m, prec];
    rec_m = [rec_m, rec];
    f1_m = [f1_m, f1];
    retri_m = [retri_m, retrieved];    
    
    % Display evaluation results for each loop
    disp(['loop=',num2str(loop),' Prec=',num2str(prec),...
        ' rec=',num2str(rec),' f1=',num2str(f1),...
        ' retri=',num2str(retrieved)]);    
end

% Get average performance for the last 3 samples
pre_res = mean(pre_m(end-3:end));
rec_res = mean(rec_m(end-3:end));
f1_res = mean(f1_m(end-3:end));
retri_res = mean(retri_m(end-3:end));
