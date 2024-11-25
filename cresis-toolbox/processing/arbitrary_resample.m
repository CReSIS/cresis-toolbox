function data = arbitrary_resample(data_in, x, out_x, param)
% data = arbitrary_resample(data_in, x, out_x, param)
%
% This function resamples or interpolates the input data from nonuniform
% input spacing to nonuniform output spacing.
%
% data_in = Nt by Nx input array
% x = Nx length vector, sample position of data_in columns (meters)
% out_x = N length vector (meters)
% param = struct controlling operation
%  .filt_len = sinc-method only, length of sinc filter (meters)
%  .dx = filter bandwidth (meters)
%  .method = 'sinc' or 'spline'
%
% data = Nt by N output array, columns sampled at out_x positions
%
% SINC method
% Convolution kernel is a tapered (Hanning) sinc function of length
% param.filt_len and first null at param.dx.
%
% SPLINE method
%
% Author: John Paden

data = zeros(size(data_in,1),length(out_x));
if strcmpi(param.method,'sinc')
  start_idx = find(x > out_x(1) - param.filt_len/2,1);
  stop_idx = find(x > out_x(1) + param.filt_len/2,1);
  for rline = 1:length(out_x)
    % Update start_idx and stop_idx
    while x(start_idx) < out_x(rline) - param.filt_len/2 && start_idx < size(data_in,2)
      start_idx = start_idx + 1;
    end
    while stop_idx <= size(data_in,2) && x(stop_idx) < out_x(rline) + param.filt_len/2
      stop_idx = stop_idx + 1;
    end
    idxs = (start_idx:stop_idx-1).';
    
    % Determine sinc kernel and normalize
    x_off = reshape(x(idxs)-out_x(rline),[length(idxs) 1]);
    Hwin = (0.50 + 0.50*cos(2*pi*x_off/param.filt_len)) .* sinc( x_off / param.dx );
    if isempty(Hwin)
      % No sample support for out_x(rline)
      data(:,rline) = 0;
    elseif length(Hwin) == 1
      data(:,rline) = data_in(:,idxs);
    else
      % Normalize Hwin based on the distance travelled (this is mostly to
      % deal with changes in speed which happen for ground based data). We
      % also prevent discontinuities in the along-track from being weighted
      % to much by capping the normalization at param.dx (i.e. a single
      % input cannot be weighted more than one output sample).
      norm_Hwin = min(param.dx,abs([x_off(2)-x_off(1); (x_off(3:end)-x_off(1:end-2))/2; x_off(end)-x_off(end-1)])) / param.dx;
      Hwin = Hwin .* norm_Hwin;
      data(:,rline) = data_in(:,idxs)*Hwin;
    end
  end
  
elseif strcmpi(param.method,'spline')
  start_idx = find(x > x(1) - param.dx/2,1);
  stop_idx = find(x > x(1) + param.dx/2,1);
  for rline = 1:length(x)
    % Update start_idx and stop_idx
    while x(start_idx) < x(rline) - param.dx/2 && start_idx < size(data_in,2)
      start_idx = start_idx + 1;
    end
    while stop_idx < size(data_in,2) && x(stop_idx) < x(rline) + param.dx/2
      stop_idx = stop_idx + 1;
    end
    idxs = (start_idx:stop_idx-1).';
    
    % Determine window and normalize
    if 1
      x_off = reshape(x(idxs)-x(rline),[length(idxs) 1]);
      Hwin = (0.50 + 0.50*cos(2*pi*x_off/(2*param.dx)));
      Hwin = Hwin/sum(Hwin);
      data(:,rline) = data_in(:,idxs)*Hwin;
    else
      data(:,rline) = mean(data_in(:,idxs),2);
    end
  end
  
  data = interp1(x.',data.',out_x,'spline').';
else
  error('Unsupported method %s', param.method);
end

return;

% Example Test Code
BW = 1/5;
time = 0:1:1e4;
dt = time(2)-time(1);
BW_pos = 0.01;
[B,A] = butter(2,BW_pos);
time2 = time + filtfilt(B,A,1/BW_pos*0.3*dt*randn(size(time)));
time2 = sort(time2);
if 1
  % Random signal
  [B,A] = butter(2,BW);
  x = filtfilt(B,A,randn(size(time)));
  Mt = 10;
  Nt = length(time)
  x_os = interpft(x,Mt*Nt);
  time_os = (0:Nt*Mt-1)*dt/Mt;
  x2 = interp1(time_os, x_os, time2);
else
  % Tone
  x = cos(2*pi*1/(2*dt)*BW*time);
  x2 = cos(2*pi*1/(2*dt)*BW*time2);
end
good_idxs = find(time>time2(1) & time<time2(end));
time = time(good_idxs);
x = x(good_idxs);
param = 3*dt;
y1 = arbitrary_resample(x2,time2,time,struct('filt_len',param*20,'dx',param,'method','sinc'));
y2 = arbitrary_resample(x2,time2,time,struct('filt_len',param*10,'dx',param,'method','sinc'));
y3 = arbitrary_resample(x2,time2,time,struct('filt_len',NaN,'dx',param,'method','spline'));
figure(1); clf;
plot(time,x,'-o');
hold on;
plot(time2,x2,'-x');
plot(time,y1,'r-x');
plot(time,y2,'g-o');
plot(time,y3,'c-x');
hold off;


