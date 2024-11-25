% script sim.doa_example_wax % Cluster version
% 
% Example setup scripts for the sim.doa function. This includes examples
% that reproduce the Wax and Ziskind 1988 paper results (Fig 2, 3, 4, and
% 6).
%
% Author: John Paden, Theresa Stumpf, (cluster adaptation by Gordon Ariho)
%
% See also: sim.doa.m

fig_to_plot = 2; % Choose figure 2, 3, 4, or 6

%% Cluster Parameters
param_override = []; % X
param_override.cluster.type = 'torque'; 
% param_override.cluster.type = 'debug'; 

param_override.cpu_time = 50;
param_override.mem = 1e9;
param_override.cluster.ppn_fixed = 4;

global gRadar;
if exist('param_override','var')
  param_override = merge_structs(gRadar,param_override);
else
  param_override = gRadar;
end
param_override.sw_version = current_software_version;

%% Fig 2 Wax and Ziskind 1988
% =======================================================================
if fig_to_plot == 2
  %% Fig 2: Simulation parameters
  physical_constants;
  array_proc_methods;
  param = [];
  
  % Source parameters
  fc = 195e6;
  BW = 30e6;
%   fc = 312.5e6;
%   BW = 1e6;
  param.src.f0                      = fc-BW/2;
  param.src.f1                      = fc+BW/2;
  param.src.ft_wind                 = @hanning;
  param.src.lever_arm.fh            = @sim.lever_arm_example;
  param.src.lever_arm.args          = {[],1,[1:3],[0; c/fc/2; 0]};
  % DOA method parameters
  param.method.list                   = [MUSIC_DOA_METHOD MLE_METHOD];
  param.method.Nsv                    = 9;
  param.method.OneD_Nsv               = 128;
  param.method.src_limits             = {[-20 40]/180*pi,[-20 40]/180*pi};
  param.method.theta_guard            = 1.5/180*pi;
  param.method.nb_nd.init             = 'grid';
  param.method.wb_td.init             = 'grid';
  param.method.wb_td.widening_factor  = 1;
  param.method.wb_fd.init             = 'grid';
  param.method.wb_fd.filter_banks     = 1;
  
  % DOA monte carlo setup
  % Two equal power sources, sweep SNR
  % One source fixed at 0 deg, another fixed at 20 deg
  % Snapshots fixed at 10
  param.monte.SNR   = repmat(linspace(10,25,16).', [1 2]);
   if 0
    param.monte.SNR   = repmat(linspace(10,40,20).', [1 2]);
  end
  num_tests = size(param.monte.SNR,1);
  param.monte.DOA   = repmat([0 20],[num_tests 1]);
  param.monte.Nsnap = repmat(10,[num_tests 1]);
  param.monte.Nsnap = repmat(10,[num_tests 1]);
  param.monte.runs  = 1000; 
  param.monte.random_seed_offset = 0;
 
  
 
  %% Fig 2: Run the simulation
  results = sim.doa(param,param_override);
   
  %% Fig 2: Process and save the outputs
  RMSE = sim.doa_rmse(param,results);
  
  figure(1); clf
  plot(param.monte.SNR(:,1),RMSE(:,:,1).','.','LineWidth',2);
  grid on
  xlabel('Source SNR (dB)')
  ylabel('RMS error ( \circ )')
  legend(cellfun(@(x) regexprep(x,'_','\\_'), array_proc_method_strs(param.method.list), 'UniformOutput', false));
  title('Figure 2 from Wax and Ziskind 1988')
  
  figure(2); clf
  plot(param.monte.SNR(:,2),RMSE(:,:,2).','.','LineWidth',2);
  grid on
  xlabel('Source SNR (dB)')
  ylabel('RMS error ( \circ )')
  legend(cellfun(@(x) regexprep(x,'_','\\_'), array_proc_method_strs(param.method.list), 'UniformOutput', false));
  title('Complement to figure 2 from Wax and Ziskind (source 2)')
  
  % Save Outputs
  out_fn = ct_filename_tmp([],'wax_ziskind_fig2_src1.fig');
  fprintf('Saving %s\n', out_fn);
  ct_saveas(1,out_fn);
  out_fn = ct_filename_tmp([],'wax_ziskind_fig2_src2.fig');
  fprintf('Saving %s\n', out_fn);
  ct_saveas(2,out_fn);
  out_fn = ct_filename_tmp([],'wax_ziskind_fig2.mat');
  fprintf('Saving %s\n', out_fn);
  ct_save(out_fn,'param','results');
end

%% Fig 3 Wax and Ziskind 1988
% ======================================;=================================
if fig_to_plot == 3
  %% Fig 3: Setup simulation parameters
  physical_constants;
  array_proc_methods;
  param = [];
  
  % Source parameters
  fc = 312.5e6;
  BW = 1e6;
  param.src.f0                      = fc-BW/2;
  param.src.f1                      = fc+BW/2;
  param.src.ft_wind                 = @boxcar;
  param.src.lever_arm.fh            = @sim.lever_arm_example;
  param.src.lever_arm.args          = {[],1,[1:3],[0; c/fc/2; 0]};
  % DOA method parameters
  param.method.list                   = [MUSIC_DOA_METHOD MLE_METHOD];
  param.method.Nsv                    = 9;
  param.method.OneD_Nsv               = 128;
  param.method.src_limits             = {[-20 40]/180*pi,[-20 40]/180*pi};
  param.method.theta_guard            = 1.5/180*pi;
  param.method.nb_nd.init             = 'grid';
  param.method.wb_td.init             = 'grid';
  param.method.wb_td.widening_factor  = 1;
  param.method.wb_fd.init             = 'grid';
  param.method.wb_fd.filter_banks     = 1;
  
  % DOA monte carlo setup
  % Two equal power 20 dB sources
  % One source fixed at 0 deg, another fixed at 20 deg
  % Sweep snapshots 10 to 1000
  param.monte.Nsnap   = round(logspace(log10(10),log10(1000),21).');
  num_tests = size(param.monte.Nsnap,1);
  param.monte.SNR   = repmat([20 20] - 10*log10(3),[num_tests 1]);
%   param.monte.SNR   = repmat([20 20],[num_tests 1]);
  param.monte.DOA   = repmat([0 20],[num_tests 1]);
  param.monte.runs  = 1000;
  param.monte.random_seed_offset = 0;
  
  %% Fig 3: Run the simulation
  results = sim.doa(param,param_override);
  
  %% Fig 3: Process and save the outputs
  RMSE = sim.doa_rmse(param,results);
  
  figure(1); clf
  semilogx(param.monte.Nsnap,RMSE(:,:,1).','.','LineWidth',2);
  grid on
  xlabel('Snapshots')
  ylabel('RMS error ( \circ )')
  legend(cellfun(@(x) regexprep(x,'_','\\_'), array_proc_method_strs(param.method.list), 'UniformOutput', false));
  title('Figure 3 from Wax and Ziskind 1988')
  
  figure(2); clf
  semilogx(param.monte.Nsnap,RMSE(:,:,2).','.','LineWidth',2);
  grid on
  xlabel('Snapshots')
  ylabel('RMS error ( \circ )')
  legend(cellfun(@(x) regexprep(x,'_','\\_'), array_proc_method_strs(param.method.list), 'UniformOutput', false));
  title('Complement to figure 3 from Wax and Ziskind (source 2)')
  
  % Save Outputs
  out_fn = ct_filename_tmp([],'wax_ziskind_fig3_src1.fig');
  fprintf('Saving %s\n', out_fn);
  ct_saveas(1,out_fn);
  out_fn = ct_filename_tmp([],'wax_ziskind_fig3_src2.fig');
  fprintf('Saving %s\n', out_fn);
  ct_saveas(2,out_fn);
  out_fn = ct_filename_tmp([],'wax_ziskind_fig3.mat');
  fprintf('Saving %s\n', out_fn);
  ct_save(out_fn,'param','results');
end

%% Fig 4 Wax and Ziskind 1988
% =======================================================================
if fig_to_plot == 4
  %% Fig 4: Setup simulation parameters
  physical_constants;
  array_proc_methods;
  param = [];
  
  % Source parameters
  fc = 312.5e6;
  BW = 1e6;
  param.src.f0                      = fc-BW/2;
  param.src.f1                      = fc+BW/2;
  param.src.ft_wind                 = @boxcar;
  param.src.lever_arm.fh            = @sim.lever_arm_example;
  param.src.lever_arm.args          = {[],1,[1:3],[0; c/fc/2; 0]};
  % DOA method parameters
  param.method.list                   = [MUSIC_DOA_METHOD MLE_METHOD];
  param.method.Nsv                    = 9;
  param.method.OneD_Nsv               = 128;
  param.method.src_limits             = {[-20 40]/180*pi,[-20 40]/180*pi};
  param.method.theta_guard            = 1.5/180*pi;
  param.method.nb_nd.init             = 'grid';
  param.method.wb_td.init             = 'grid';
  param.method.wb_td.widening_factor  = 1;
  param.method.wb_fd.init             = 'grid';
  param.method.wb_fd.filter_banks     = 1;
  
  % DOA monte carlo setup
  % Two equal power 20 dB sources
  % One source fixed at 0 deg, another fixed at 5 deg
  % Sweep snapshots 100 to 1000
  param.monte.Nsnap   = round(logspace(log10(100),log10(1000),11).');
  num_tests = size(param.monte.Nsnap,1);
  param.monte.SNR   = repmat([20 20] - 10*log10(3),[num_tests 1]);
  param.monte.DOA   = repmat([0 5],[num_tests 1]);
  param.monte.runs  = 500;
  param.monte.random_seed_offset = 0;
  
  %% Fig 4: Run the simulation
  results = sim.doa(param,param_override);
  
  %% Fig 4: Process and save the outputs
  RMSE = sim.doa_rmse(param,results);
  
  figure(1); clf
  plot(param.monte.Nsnap,RMSE(:,:,1).','.','LineWidth',2);
  grid on
  xlabel('Snapshots')
  ylabel('RMS error ( \circ )')
  legend(cellfun(@(x) regexprep(x,'_','\\_'), array_proc_method_strs(param.method.list), 'UniformOutput', false));
  title('Figure 4 from Wax and Ziskind 1988')
  
  figure(2); clf
  plot(param.monte.Nsnap,RMSE(:,:,2).','.','LineWidth',2);
  grid on
  xlabel('Snapshots')
  ylabel('RMS error ( \circ )')
  legend(cellfun(@(x) regexprep(x,'_','\\_'), array_proc_method_strs(param.method.list), 'UniformOutput', false));
  title('Complement to figure 4 from Wax and Ziskind (source 2)')
  
  % Save Outputs
  out_fn = ct_filename_tmp([],'wax_ziskind_fig4_src1.fig');
  fprintf('Saving %s\n', out_fn);
  ct_saveas(1,out_fn);
  out_fn = ct_filename_tmp([],'wax_ziskind_fig4_src2.fig');
  fprintf('Saving %s\n', out_fn);
  ct_saveas(2,out_fn);
  out_fn = ct_filename_tmp([],'wax_ziskind_fig4.mat');
  fprintf('Saving %s\n', out_fn);
  ct_save(out_fn,'param','results');
end

%% Fig 6 Wax and Ziskind 1988
% =======================================================================
if fig_to_plot == 6
  %% Fig 6: Setup simulation parameters
  physical_constants;
  array_proc_methods;
  param = [];
  
  % Source parameters
  fc = 312.5e6;
  BW = 1e6;
  param.src.f0                      = fc-BW/2;
  param.src.f1                      = fc+BW/2;
  param.src.ft_wind                 = @boxcar;
  param.src.lever_arm.fh            = @sim.lever_arm_example;
  param.src.lever_arm.args          = {[],1,[1:7],[0; c/fc/2; 0]};
  % DOA method parameters
  param.method.list                   = [MUSIC_DOA_METHOD MLE_METHOD];
  param.method.Nsv                    = 64;
  param.method.OneD_Nsv               = 128;
  param.method.src_limits             = {[-20 20]/180*pi,[-20 20]/180*pi,[-20 20]/180*pi,[-20 20]/180*pi};
  param.method.theta_guard            = 1.5/180*pi;
  param.method.nb_nd.init             = 'ap';
  param.method.wb_td.init             = 'ap';
  param.method.wb_td.widening_factor  = 1;
  param.method.wb_fd.init             = 'ap';
  param.method.wb_fd.filter_banks     = 1;
  
  % DOA monte carlo setup
  % Four equal power 20 dB sources
  % Fixed at -8, -1, 5, and 15 deg
  % Sweep snapshots 100 to 1000
  param.monte.Nsnap   = round(logspace(log10(50),log10(500),11).');
  num_tests = size(param.monte.Nsnap,1);
  param.monte.SNR   = repmat([20 20 20 20],[num_tests 1]);
  param.monte.DOA   = repmat([-8 -1 5 15],[num_tests 1]);
  param.monte.runs  = 500;
  param.monte.random_seed_offset = 0;
  
  %% Fig 6: Run the simulation
  results = sim.doa(param,param_override);
  
  %% Fig 6: Process and save the outputs
  RMSE = sim.doa_rmse(param,results);
  
  figure(1); clf
  plot(param.monte.Nsnap,RMSE(:,:,3).','.','LineWidth',2);
  grid on
  xlabel('Snapshots')
  ylabel('RMS error ( \circ )')
  legend(cellfun(@(x) regexprep(x,'_','\\_'), array_proc_method_strs(param.method.list), 'UniformOutput', false));
  title('Figure 6 from Wax and Ziskind 1988')
  
  figure(2); clf
  plot(param.monte.Nsnap,RMSE(:,:,1).','.','LineWidth',2);
  grid on
  xlabel('Snapshots')
  ylabel('RMS error ( \circ )')
  legend(cellfun(@(x) regexprep(x,'_','\\_'), array_proc_method_strs(param.method.list), 'UniformOutput', false));
  title('Complement to figure 6 from Wax and Ziskind (source 1)')
  
  figure(3); clf
  plot(param.monte.Nsnap,RMSE(:,:,2).','.','LineWidth',2);
  grid on
  xlabel('Snapshots')
  ylabel('RMS error ( \circ )')
  legend(cellfun(@(x) regexprep(x,'_','\\_'), array_proc_method_strs(param.method.list), 'UniformOutput', false));
  title('Complement to figure 6 from Wax and Ziskind (source 2)')
  
  figure(4); clf
  plot(param.monte.Nsnap,RMSE(:,:,4).','.','LineWidth',2);
  grid on
  xlabel('Snapshots')
  ylabel('RMS error ( \circ )')
  legend(cellfun(@(x) regexprep(x,'_','\\_'), array_proc_method_strs(param.method.list), 'UniformOutput', false));
  title('Complement to figure 6 from Wax and Ziskind (source 4)')
  
  % Save Outputs
  out_fn = ct_filename_tmp([],'wax_ziskind_fig6_src1.fig');
  fprintf('Saving %s\n', out_fn);
  ct_saveas(1,out_fn);
  out_fn = ct_filename_tmp([],'wax_ziskind_fig6_src2.fig');
  fprintf('Saving %s\n', out_fn);
  ct_saveas(2,out_fn);
  out_fn = ct_filename_tmp([],'wax_ziskind_fig6_src3.fig');
  fprintf('Saving %s\n', out_fn);
  ct_saveas(3,out_fn);
  out_fn = ct_filename_tmp([],'wax_ziskind_fig6_src4.fig');
  fprintf('Saving %s\n', out_fn);
  ct_saveas(4,out_fn);
  out_fn = ct_filename_tmp([],'wax_ziskind_fig6.mat');
  fprintf('Saving %s\n', out_fn);
  ct_save(out_fn,'param','results');
  
end

