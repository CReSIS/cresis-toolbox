% script run_multipass
%
% Script for running multipass.m
%
% Authors: Cody Barnett, Bailey Miller, John Paden
%
% See also: multipass.combine_passes.m, multipass.run_combine_passes.m,
% multipass.multipass.m, multipass.run_multipass.m

%% User Settings
% =========================================================================

global gRadar;
param_override = [];
param = [];

example_str = 'egig_2011_2012_2014_2018_allwf';

% param.multipass.layer: Choose which layers to include in the coregistered output.
% Default is surface and bottom from CSARP_layer.
%param_override.multipass.layer = struct('name',{'surface' 'bottom_qc'},'source',{'ops'});
%param_override.multipass.layer = struct('name',{'surface' 'bottom_qc' 'surface'},'source',{'ops','ops','lidar'},'lidar_source','atm');

if strcmpi(example_str,'Thwaites_201902_201912_202001')
  %% Thwaites Line 1 20190201_01, 20191225_01, 20200127_01
  param.multipass.fn = fullfile(gRadar.out_path,'accum','2018_Antarctica_TObas','CSARP_multipass','Thwaites_201902_201912_202001.mat');
  
  param.multipass.rbins = [];
  
  param.multipass.baseline_master_idx = 1;
  param.multipass.master_idx = 1;
  
  param.multipass.pass_en_mask = [];
  param.multipass.output_fn_midfix = [];
  param.multipass.coregistration_time_shift = [0 0 0];
  param.multipass.comp_mode = 2;
end

if strcmpi(example_str,'Petermann_line1_2011_2014_2015_2017_2018_2019')
  %% Petermann Line 1 2011, 2014, 2015, 2017, 2018, 2019
  param.multipass.fn = fullfile(gRadar.out_path,'rds','2011_Greenland_P3','CSARP_multipass','Petermann_line1_2011_2014_2015_2017_2018_2019');
  
  param.multipass.rbins = [];
  
  param.multipass.baseline_master_idx = 1;
  param.multipass.master_idx = 1;
  
  param.multipass.pass_en_mask = [];
  param.multipass.output_fn_midfix = [];
  param.multipass.coregistration_time_shift = [0 0 0 0 0 0];
  param.multipass.comp_mode = 2;
end

if strcmpi(example_str,'Petermann_line2_2013_2014_2017')
  %% Petermann Line 2 2013, 2014, 2017
  param.multipass.fn = fullfile(gRadar.out_path,'rds','2013_Greenland_P3','CSARP_multipass','Petermann_line2_2013_2014_2017');
  
  param.multipass.rbins = [];
  
  param.multipass.baseline_master_idx = 1;
  param.multipass.master_idx = 1;
  
  param.multipass.pass_en_mask = [];
  param.multipass.output_fn_midfix = [];
  param.multipass.coregistration_time_shift = [0 0 0];
  param.multipass.comp_mode = 2;
end

if strcmpi(example_str,'Petermann_line4_2010_2011_2013_2014_2017')
  %% Petermann Line 4 2010, 2011, 2013, 2014, 2017
  param.multipass.fn = fullfile(gRadar.out_path,'rds','2010_Greenland_DC8','CSARP_multipass','Petermann_line4_2010_2011_2013_2014_2017');
  
  param.multipass.rbins = [];
  
  param.multipass.baseline_master_idx = 1;
  param.multipass.master_idx = 1;
  
  param.multipass.pass_en_mask = [];
  param.multipass.output_fn_midfix = [];
  param.multipass.coregistration_time_shift = [0 0 0 0 0];
  param.multipass.comp_mode = 2;
  
end

if strcmpi(example_str,'Petermann_oblique_2014_2015_2017_2018')
  %% Petermann Oblique 2014, 2017, 2018
  param.multipass.fn = fullfile(gRadar.out_path,'rds','2014_Greenland_P3','CSARP_multipass','Petermann_oblique_2014_2015_2017_2018');
  
  param.multipass.rbins = [];
  
  param.multipass.baseline_master_idx = 1;
  param.multipass.master_idx = 1;
  
  param.multipass.pass_en_mask = [];
  param.multipass.output_fn_midfix = [];
  param.multipass.coregistration_time_shift = [0 0 0 0];
  param.multipass.comp_mode = 2;
end

if strcmpi(example_str,'79N_line1_2010_2014_2016_2018')
  %% 79N Line 1 2010, 2014, 2016, 2018, 2019
  param.multipass.fn = fullfile(gRadar.out_path,'rds','2014_Greenland_P3','CSARP_multipass','79N_line1_2010_2014_2016_2018');
  
  param.multipass.rbins = [];
  
  param.multipass.baseline_master_idx = 2;
  param.multipass.master_idx = 2;
  
  param.multipass.pass_en_mask = [];
  param.multipass.output_fn_midfix = [];
  param.multipass.coregistration_time_shift = [0 0 0 0 0];
  param.multipass.comp_mode = 2;
  param.multipass.time_gate = [2e-6 13e-6];
end

if strcmpi(example_str,'Humboldt_line1_2012_2013_2014_2017')
  %% Humboldt Line 1 2012, 2013, 2014, 2017
  param.multipass.fn = fullfile(gRadar.out_path,'rds','2013_Greenland_P3','CSARP_multipass','Humboldt_line1_2012_2013_2014_2017');
  
  param.multipass.rbins = [];
  
  param.multipass.baseline_master_idx = 1;
  param.multipass.master_idx = 1;
  
  param.multipass.pass_en_mask = [];
  param.multipass.output_fn_midfix = [];
  param.multipass.coregistration_time_shift = [0 0 0 0];
  param.multipass.comp_mode = 2;
  param.multipass.time_gate = [2e-6 13e-6];
end

if strcmpi(example_str,'Ryder_line1_2011_2013_2015_2019')
  %% Ryder Line 1 2011, 2013, 2015, 2019
  param.multipass.fn = fullfile(gRadar.out_path,'rds','2015_Greenland_C130','CSARP_multipass','Ryder_line1_2011_2013_2015_2019');
  
  param.multipass.rbins = [];
  
  % Use 2015 for master_idx since it runs parallel to glacier
  param.multipass.baseline_master_idx = 3;
  param.multipass.master_idx = 3;
  
  param.multipass.pass_en_mask = [];
  param.multipass.output_fn_midfix = [];
  param.multipass.coregistration_time_shift = [0 0 0 0];
  param.multipass.comp_mode = 2;
  param.multipass.time_gate = [2e-6 15e-6];
end

if strcmpi(example_str,'Steensby_line1_2011_2013_2015_2019')
  %% Steensby Line 1 2011, 2013, 2015, 2019
  param.multipass.fn = fullfile(gRadar.out_path,'rds','2013_Greenland_P3','CSARP_multipass','Steensby_line1_2011_2013_2015_2019');
  
  param.multipass.rbins = [];
  
  param.multipass.baseline_master_idx = 2;
  param.multipass.master_idx = 2;
  
  param.multipass.pass_en_mask = [];
  param.multipass.output_fn_midfix = [];
  param.multipass.coregistration_time_shift = [0 0 0 0];
  param.multipass.comp_mode = 2;
  param.multipass.time_gate = [2e-6 10e-6];
end

if strcmpi(example_str,'ZI_line1_2010_2014_2016_2017_2018_2019')
  %% Zachariae Isstrom Line 1 2010, 2014, 2016, 2017, 2018, 2019
  param.multipass.fn = fullfile(gRadar.out_path,'rds','2014_Greenland_P3','CSARP_multipass','ZI_line1_2010_2014_2016_2017_2018_2019');
  
  param.multipass.rbins = [];
  
  param.multipass.baseline_master_idx = 2;
  param.multipass.master_idx = 2;
  
  param.multipass.pass_en_mask = [];
  param.multipass.output_fn_midfix = [];
  param.multipass.coregistration_time_shift = [0 0 0 0 0 0];
  param.multipass.comp_mode = 2;
  param.multipass.time_gate = [2e-6 13e-6];
end

if strcmpi(example_str,'camp_century_2014_same_day')
  %% Camp Century: 2014 Greenland P3 same day
  param.multipass.fn = fullfile(gRadar.out_path,'rds','2014_Greenland_P3','CSARP_multipass','camp_century_2014_same_day');
  
  param.multipass.rbins = [];
  
  param.multipass.baseline_master_idx = 8;
  param.multipass.master_idx = 8;
  
  param.multipass.pass_en_mask = [];
  param.multipass.output_fn_midfix = [];
  param.multipass.coregistration_time_shift = [];
  param.multipass.comp_mode = 1:4;
  param.multipass.time_gate = [];
  
  %Load equalization vector (sar specific)
  eqvec1 = [122.5 121.6 126.7 105.5 130.1 120.1 128.7 -0.0 -134.2 121.1 36.4 125.8 -171.5 -1.0 128.4];
  eqvec2 = eqvec1;
  neweq = [42.8 45.5 48.2 50.9 53.6 56.3 58.9 0.0 2.7 5.4 8.1 93.6 96.3 99.0 101.7]/2;
  neweq = [neweq neweq];
  
  if 1 && exist('neweq','var') && ~isempty(neweq)
    eqvec1 = eqvec1-neweq(1:length(eqvec1));
    eqvec2 = eqvec2-neweq(length(eqvec1)+1:end);
  end
  
  equalization1 = 10.^(zeros(1,15)/20) .* exp(1i*(eqvec1)/180*pi);
  equalization2 = 10.^(zeros(1,15)/20) .* exp(1i*(eqvec2)/180*pi);
  param.multipass.equalization = [equalization1 equalization2];
  
  param.multipass.debug_plots = {'NA'};
end

if strcmpi(example_str,'camp_century_2011_2012_2013_2014')
  %% Camp Century: 2011, 2012, 2013, 2014 Greenland P3
  param.multipass.fn = fullfile(gRadar.out_path,'rds','2014_Greenland_P3','CSARP_multipass','camp_century_2011_2012_2013_2014');
  
  param.multipass.rbins = 220:420;
  
  param.multipass.baseline_master_idx = 8;
  param.multipass.master_idx = 8;
  
  param.multipass.pass_en_mask = [];
  param.multipass.output_fn_midfix = [];
  param.multipass.coregistration_time_shift = [];
  param.multipass.comp_mode = 1;
  param.multipass.time_gate = [];
end

if strcmpi(example_str,'summit_2012_2014_allwf')
  %% Summit Camp: 2012-2014
  param.multipass.fn = fullfile(gRadar.out_path,'rds','2014_Greenland_P3','CSARP_multipass','summit_2012_2014_allwf');
  
  param.multipass.rbins = [];
  
  if 0
    % All passes: estimate coregistration
    param.multipass.comp_mode = 2;
    param.multipass.slope_correction_en = true;
    param.multipass.baseline_master_idx = 8;
    param.multipass.master_idx = 8;
    param.multipass.output_fn_midfix = '';
    param.multipass.pass_en_mask = false(1,30);
    param.multipass.pass_en_mask(1:30) = true;
  elseif 0
    % All passes: estimate equalization all passes
    param.multipass.comp_mode = 1;
    param.multipass.slope_correction_en = true;
    param.multipass.baseline_master_idx = 8;
    param.multipass.master_idx = 8;
    param.multipass.output_fn_midfix = '';
    param.multipass.pass_en_mask = false(1,30);
    param.multipass.pass_en_mask(1:30) = true;
  elseif 0
    % Single season only: estimate cross-track slope
    % Run tomo.cross_track_slope_est after this
    param.multipass.comp_mode = 2;
    param.multipass.baseline_master_idx = 8;
    param.multipass.master_idx = 8;
    param.multipass.output_fn_midfix = '_2014';
    param.multipass.pass_en_mask = false(1,30);
    param.multipass.pass_en_mask(1:15) = true;
  elseif 0
    % All passes: prepare SLC images to form interferograms all passes
    % Run tomo.tomo_insar_image after this
    param.multipass.comp_mode = 3;
    param.multipass.slope_correction_en = true;
    param.multipass.baseline_master_idx = 8;
    param.multipass.master_idx = 8;
    param.multipass.output_fn_midfix = '';
    param.multipass.pass_en_mask = false(1,30);
    param.multipass.pass_en_mask(1:30) = true;
  elseif 0
    % TEST: 2012 only using 2014 as master; useful for 2012 equalization
    param.multipass.comp_mode = 2;
    param.multipass.baseline_master_idx = 8;
    param.multipass.master_idx = 15+8;
    param.multipass.output_fn_midfix = '_2012';
    param.multipass.pass_en_mask = false(1,30);
    param.multipass.pass_en_mask(16:30) = true;
  else 0
    % TEST: 2012 only using 2012 as master; useful for 2012 equalization
    param.multipass.comp_mode = 2;
    param.multipass.baseline_master_idx = 15+8;
    param.multipass.master_idx = 15+8;
    param.multipass.output_fn_midfix = '_2012master';
    param.multipass.pass_en_mask = false(1,30);
    param.multipass.pass_en_mask(16:30) = true;
  end
  
  param.multipass.coregistration_time_shift = [];
  param.multipass.time_gate = [];
  
%   param.multipass.equalization = 10.^(zeros(1,30)) ...
%     .* exp(1i*([7.9 22.5 19.7 22.7 29.9 14.9 22.3 0.0 1.5 5.4 13.4 19.2 17.1 17.8 22.7 167.4 166.3 177.1 164.3 -177.6 165.9 171.6 155.3 154.6 157.5 164.6 179.0 176.7 174.8 -129.8]/180*pi));
  
  param.multipass.debug_plots = {'debug','coherent'};
end


if strcmpi(example_str,'egig_2011_2012_2014_2018_allwf')
  %% EGIG line: 2011-2018
  param.multipass.fn = fullfile(gRadar.out_path,'rds','2014_Greenland_P3','CSARP_multipass','egig_2011_2012_2014_2018_allwf');
  
  param.multipass.rbins = [];
  
  if 0
    % All passes: estimate coregistration
    param.multipass.comp_mode = 2;
    param.multipass.slope_correction_en = false;
    param.multipass.baseline_master_idx = 8;
    param.multipass.master_idx = 8;
    param.multipass.output_fn_midfix = '';
    param.multipass.pass_en_mask = false(1,75);
    param.multipass.pass_en_mask(1:75) = true;
    param.multipass.rbins = 300:750;
  elseif 0
    % All passes: estimate equalization all passes
    param.multipass.comp_mode = 1;
    param.multipass.slope_correction_en = false;
    param.multipass.baseline_master_idx = 8;
    param.multipass.master_idx = 8;
    param.multipass.output_fn_midfix = '';
    param.multipass.pass_en_mask = false(1,75);
    param.multipass.pass_en_mask(1:75) = true;
  elseif 0
    % Single season only: estimate cross-track slope
    % Run tomo.cross_track_slope_est after this
    param.multipass.comp_mode = 2; 
    param.multipass.slope_correction_en = false;
    param.multipass.baseline_master_idx = 8;
    param.multipass.master_idx = 8;
    param.multipass.output_fn_midfix = '_2014';
    param.multipass.pass_en_mask = false(1,75);
    param.multipass.pass_en_mask(1:15) = true;
  elseif 1
    % All passes: prepare SLC images to form interferograms all passes
    % Run tomo.tomo_insar_image after this
    param.multipass.comp_mode = 3;
    param.multipass.slope_correction_en = true;
    param.multipass.baseline_master_idx = 8;
    param.multipass.master_idx = 8;
    param.multipass.output_fn_midfix = '';
    param.multipass.pass_en_mask = false(1,75);
    param.multipass.pass_en_mask(1:75) = true;
  end
  
%   param.multipass.coregistration_time_shift = [];
  param.multipass.coregistration_time_shift = [0.05 0 0 -0.05 0 0 0 0 0.05 -0.05 0 0 0 0.05 0 0.35 0.3 0.35 0.3 0.35 0.35 0.3 0.25 0.35 0.3 0.3 0.3 0.25 0.3 0.25 0.25 0.3 0.3 0.25 0.3 0.25 0.25 0.3 0.25 0.3 0.25 0.3 0.35 0.3 0.35 0.15 0.1 0.15 0.15 0.1 0.1 0.15 0.1 0.1 0.1 0.1 0.1 0.15 0.05 0.1 0.1 0.05 0.1 0.1 0.05 0.05 0.1 0.05 0.1 0.1 0.1 0.05 0.1 0 0.1];
  param.multipass.time_gate = [];

  param.multipass.equalization = 10.^([13.7 14.1 13.7 12.9 13.2 14.3 14.0 15.0 12.5 16.0 15.1 12.6 11.9 11.2 12.6 -13.1 -10.8 -14.5 -13.2 -14.4 -15.1 -15.6 1.8 3.8 3.0 2.6 1.2 3.2 5.9 2.2 -17.7 -13.7 -18.0 -14.9 -1.9 -17.6 -19.0 -3.5 2.4 -1.2 -1.7 -1.1 2.2 10.5 -0.5 -0.0 -0.2 0.0 -0.2 -0.1 1.6 -0.8 -0.2 -0.0 -0.3 -0.3 -1.9 -0.8 -0.2 -0.7 -2.1 -2.3 -2.1 -2.2 -1.9 -0.3 -2.5 -1.9 -1.6 -1.7 -1.9 -3.3 -2.1 -1.8 -2.0]/20) ...
    .* exp(1i*([4.9 18.4 15.2 19.2 23.2 15.2 22.6 0.0 0.5 6.8 13.3 9.2 5.8 6.0 10.1 44.2 40.7 47.0 49.0 41.8 40.8 47.0 29.7 32.8 30.9 38.5 37.5 36.0 37.2 30.7 -74.7 -110.5 -58.3 -104.2 -128.8 -69.7 -56.9 -128.8 -127.6 -126.6 -120.4 -124.6 -125.4 -130.3 -130.2 140.1 142.9 143.9 148.2 157.8 154.1 162.0 145.6 159.4 150.4 155.2 160.2 146.3 146.9 141.9 56.5 61.9 62.2 64.3 74.6 70.8 80.2 62.3 77.0 69.0 71.5 77.4 63.3 63.2 60.0]/180*pi));
  % param.multipass.equalization = 10.^(zeros(1,75)) ...
  %   .* exp(1i*(zeros(1,75)/180*pi));
  
  param.multipass.debug_plots = {'debug','coherent'};
end

%% Automated section
% =========================================================================
%Load param variable
[fn_dir, param.multipass.pass_name] = fileparts(param.multipass.fn);
% Input checking
if exist('param_override','var')
  param_override = merge_structs(gRadar,param_override);
else
  param_override = gRadar;
end

% Run multipass
%multipass.multipass(param, param_override);
multipass.multipass
