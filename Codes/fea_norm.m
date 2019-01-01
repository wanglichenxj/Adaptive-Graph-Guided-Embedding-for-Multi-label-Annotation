function [X_norm]=fea_norm(X)
% ===================
% Feature metrix normalization code
% ===================
% Author: Lichen Wang
% Date: Dec. 27, 2018
% E-mail: wanglichenxj@gmail.com

% Input: Feature metrix X in d*N format, where d is feature dimension
% Output: Normalized feature metrix X_norm in d*N
% ===================
X_norm=X; % Initialize output
n=size(X,2);
for i = 1:n
    X_norm(:,i) = (X(:,i)-mean(X(:,i)))/std(X(:,i));
end
