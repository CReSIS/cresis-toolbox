function x = interpft_memeff(x,new_length,dim)
% x = interpft_memeff(x,new_length,dim)
%
% Simplified and memory efficient interpft.m, new_length > size(x,dim)

if ~exist('dim','var')
  dim = 1;
end

% Get the current size
siz = size(x);

% Operate on specified dimension (permute that dim to row-dim)
if dim ~= 1
  perm = [dim:max(length(size(x)),dim) 1:dim-1];
  x = permute(x,perm);
end

% Get a few parameters about the data
[old_length,N] = size(x);
x_real = isreal(x);

x = fft(x,[],1);

% Determine where zero padding needs to be added
nyqst = ceil((old_length+1)/2);
% Zero pad in the middle of the frequency spectrum (this also turns the
% input x matrix into a 2D matrix)
x = [x(1:nyqst,:) ; zeros(new_length-old_length,N) ; x(nyqst+1:old_length,:)];
% Handle split bin that occurs for even number
if rem(old_length,2) == 0
  x(nyqst,:) = x(nyqst,:)/2;
  x(nyqst+new_length-old_length,:) = x(nyqst,:);
end

x = ifft(x,[],1);

% Handle potential rounding errors that lead to complex data
if x_real, x = real(x); end

% Handle fft/ifft scaling
x = x * new_length / old_length;

% Reshape matrix back to its original size before turning into 2D matrix
x = reshape(x,[size(x,1) siz(2:end)]);

% Operate on specified dimension (permute back)
if dim ~= 1
  x = ipermute(x,perm);
end
