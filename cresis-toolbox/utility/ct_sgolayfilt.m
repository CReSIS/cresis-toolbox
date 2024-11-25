function y=ct_sgolayfilt(X,K,F)
% y=ct_sgolayfilt(X,K,F)
%
% Wrapper function for sgolayfilt to handle arbitrary input data lengths.
%
% X is assumed to be a vector
% K is assumed to be a scalar
% F is assumed to be a scalar
%
% Y is assumed to match X is size

if isempty(X)
  y=[];
  return;
end

F = min(2*floor((length(X)-1)/2)+1,2*floor((F-1)/2)+1);
K = min(F-1,K);

y=sgolayfilt(X,K,F);
