% script matlab_speed_test.m

%% CPU Test
if 1
  %% CPU: Date and Time, Version, OS
  fprintf('date_time\t%s\n', datestr(now,'yyyymmdd_HHMMSS'));
  A = ver('Matlab');
  fprintf('version\t%s\n', A.Release);
  if ~isempty(which('detect_os'))
    [OS, OSVersion] = detect_os;
    fprintf('OS\t%s\t%s\n', OS, mat2str_generic(OSVersion));
  else
    if ispc
      fprintf('OS\t%s\t%s\n', 'Windows', '');
    elseif isunix
      fprintf('OS\t%s\t%s\n', 'Linux', '');
    elseif ismac
      fprintf('OS\t%s\t%s\n', 'Mac', '');
    end
  end
  
  %% CPU: FFT speed test
  start_time = tic;
  fprintf('fft_start\t%g\n', toc(start_time));
  A = randn(10e3,5e3) + 1i*randn(10e3,5e3);
  fprintf('fft_data_creation\t%g\n', toc(start_time));
  for run = 1:500
    B = fft(A);
  end
  fprintf('fft_done\t%g\n', toc(start_time));
  
  %% CPU: Matrix Inversion speed test
  start_time = tic;
  fprintf('mat_inv_start\t%g\n', toc(start_time));
  A = randn(15,15,1e5) + 1i*randn(15,15,1e5);
  fprintf('mat_inv_creation\t%g\n', toc(start_time));
  B = zeros(size(A));
  for run = 1:40
    for rline = 1:size(A,3)
      B(:,:,rline) = inv(A(:,:,rline));
    end
  end
  fprintf('mat_inv_done\t%g\n', toc(start_time));
  
  %% CPU: Component wise matrix multiplies
  start_time = tic;
  fprintf('mat_mult_start\t%g\n', toc(start_time));
  A = randn(10e3,5e3) + 1i*randn(10e3,5e3);
  B = randn(10e3,5e3) + 1i*randn(10e3,5e3);
  fprintf('mat_mult_creation\t%g\n', toc(start_time));
  for run = 1:300
    C = A .* B;
  end
  fprintf('mat_mult_done\t%g\n', toc(start_time));
end

%% GPU Section (verify parallel toolbox gpuDeviceCount is in the path)
if 1 && ~isempty(which('gpuDeviceCount'))
  % gpuDeviceTable
  for gpu_idx = 1:gpuDeviceCount
    gpu_dev = gpuDevice(gpu_idx);
    
    %% GPU: Determine size of matrix to operate on based on GPU memory
    % 8 bytes per sample, 3 copies in memory, 10e3 rows, 80% utilization
    cols = min(10e3,floor(gpu_dev.TotalMemory / 10e3 / 8 / 3 * 0.8));
    if cols == 10e3
      fprintf('GPU\t%s\n', gpu_dev.Name);
    else
      fprintf('GPU\t%s: only using %d instead of 10000 columns due to VRAM limitation\n', gpu_dev.Name, cols);
    end

    %% GPU: FFT speed test
    start_time = tic;
    fprintf('fft_start\t%g\n', toc(start_time));
    A = randn(10e3,10e3,'single') + 1i*randn(10e3,10e3,'single');
    % gpurng(0, 'Philox');
    % B = randn(10e3,5e3,'single','gpuArray') + 1i*randn(10e3,5e3,'single','gpuArray');
    B = gpuArray(A);
    % underlyingType(B)
    fprintf('fft_data_creation\t%g\n', toc(start_time));
    for run = 1:500
      C = fft(B);
    end
    
    %% GPU: Copy result to CPU RAM
    % gather ensures all GPU operations are completed and then copies the
    % results back into CPU RAM
    D = gather(C);
    fprintf('fft_done\t%g\n', toc(start_time));
    E = fft(A);
    fprintf('fft_error\t%g\n', sum(abs(E(:)-D(:))));
  end
end
