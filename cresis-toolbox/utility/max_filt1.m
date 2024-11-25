function y = max_filt1(x,n)
% y = max_filt1(x,n)
%
% Similar to medfilt1 except that it takes the maximum instead of the
% median.
%
% Better handling of edges.
% Handles NaN.
% Only operates on first dimension, except for row vectors.
% Only allows n to be odd.

size_x = size(x);

y = zeros(size_x);

if size(x,1) == 1
  y = max_filt1_1D(x.',n);
else
  for col = 1:prod(size_x(2:end))
    y(:,col) = max_filt1_1D(x(:,col),n);
  end
end

end

function x = max_filt1_1D(x,n)

N = length(x);

% Since multiple calls to max would be very slow for long vectors, we
% construct a matrix of all the vectors that we need to take a max of
% and call max one time.
xx = nan(n,N);
num_isnan = zeros(1,N);
rel_n = -(n-1)/2 : (n-1)/2;
for k=1:n
  if rel_n(k) < 0
    xx(k,1-rel_n(k):end) = x(1:end+rel_n(k));
  elseif rel_n(k) > 0
    xx(k,1:end-rel_n(k)) = x(1+rel_n(k):end);
  else
    xx(k,:) = x;
  end
  num_isnan = num_isnan + isnan(xx(k,:));
end
x = max(xx);

end
