
% script run_basic_rx_chan_equalization
%
% Runs basic_rx_chan_equalization
%
% Author: John Paden, Logan Smith

% Enable Just One Radar Setup
radar_setup = 'MCORDS5';

%% RDS: MCORDS5
if strcmpi(radar_setup,'MCORDS5')
  [param,defaults] = default_radar_params_2022_Greenland_Polar5_rds;
  
  % .file_search_mode: Specify how to search for a file: 'last_file',
  %   'specific', 'default', 'segment', 'map', or empty to be asked
  param.config.file_search_mode = 'segment';

  % .config.base_dir_search: cell vector of paths to search for data files
  param.config.base_dir_search = {'\\192.168.1.100\d\awi','C:\rds\2022_Greenland_Polar5\20220512\','D:\awi\','/cresis/snfs1/scratch/2016_Germany_AWI_tests/AWI_ICE_bak/test_flight','/mnt/AWI_SSD0/1604261202/UWB/'};
  
  % .config.img: wf-adc pair list which specifies which waveform-adc pairs
  % to analyze
  %wf = 1; adcs = 1:24; ref = 12; % Waveform 1, All ADCs
  wf = 1; adcs = 1:8; ref = 4; % Waveform 1, Left subarray
  %wf = 1; adcs = 9:16; ref = 4; % Waveform 1, Center subarray
  %wf = 1; adcs = 17:24; ref = 4; % Waveform 1, Right subarray
  param.config.img = cat(2,wf*ones(length(adcs),1),adcs.');

  % .config.ref_wf_adc: index into config.img wf-adc pair list to use as
  % the reference for equalization
  param.config.ref_wf_adc = ref;
  
  % .config.recs: two element vector specifying which records/range-lines
  % to load [start_record num_records]
  param.config.recs = [0 inf];
  
  % .config.presums: Number of additional software presums (coherent
  % averaging) to do
  param.config.presums = 20;
  
  % .config.delay: the method used to calculate delay between the channels
  param.config.delay = struct('method','xcorr_complex','ref_bins',-20:20,'search_bins',-7:7,'Mt',64)
end

%% RDS: MCORDS5_P3 (Accumulation Radar)
if strcmpi(radar_setup,'MCORDS5_P3')
  [param,defaults] = default_radar_params_2017_Greenland_P3_accum;
  
  % .file_search_mode: Specify how to search for a file: 'last_file',
  %   'specific', 'default', or empty to be asked
  param.file_search_mode = '';

  % .base_dir_search: cell vector of paths to search for data files
  param.base_dir_search = {'/process-archive/20170322/accum/'};
  
  % .img: wf-adc pair list which specifies which waveform-adc pairs to
  %   analyze
  wf = 1; adcs = 1:4; ref = 2; % Waveform 1, All ADCs
  param.img = cat(2,wf*ones(length(adcs),1),adcs.'); param.ref_wf_adc = ref;
  
  % .recs: two element vector specifying which records/range-lines to load
  %   [start_record num_records]
  param.recs = [0 inf];
  
  % .presums: Number of additional software presums (coherent averaging) to do
  param.presums = 20;
  
  % .delay: the method used to calculate delay between the channels
  param.delay = struct('method','xcorr_complex','ref_bins',-20:20,'search_bins',-7:7,'Mt',64)
end

%% RDS: MCORDS3_P3
if strcmpi(radar_setup,'MCORDS3_P3')
  [param,defaults] = default_radar_params_2014_Greenland_P3_mcords;
  
  % .file_search_mode: Specify how to search for a file: 'last_file', 'specific'
  param.file_search_mode = '';
  param.multiple_files = true;

  % .base_dir_search: cell vector of paths to search for data files
  param.base_dir_search = {'/cresis/snfs1/data/MCoRDS/2014_Greenland_P3/20140401/'};
  
  % .img: wf-adc pair list which specifies which waveform-adc pairs to
  %   analyze
  param.img = cat(2,2*ones(15,1),[2:16].'); param.ref_wf_adc = 3;
  
  % .recs: two element vector specifying which records/range-lines to load
  %   [start_record num_records]
  param.recs = [0 inf];
  
  % .presums: Number of additional software presums (coherent averaging) to do
  param.presums = 10;
  
  % .delay: the method used to calculate delay between the channels
  param.delay = struct('method','xcorr_complex','ref_bins',-20:20,'search_bins',-7:7,'Mt',64)
end

%% RDS: MCORDS3_DC8
if strcmpi(radar_setup,'MCORDS3_DC8')
  [param,defaults] = default_radar_params_2016_Antarctica_DC8_mcords;
  
  % .file_search_mode: Specify how to search for a file: 'last_file', 'specific'
  param.file_search_mode = 'segment';
  param.multiple_files = true;

  % .base_dir_search: cell vector of paths to search for data files
  param.base_dir_search = {'/cresis/snfs1/data/MCoRDS/2016_Antarctica_DC8/20161024/'};
  
  % .img: wf-adc pair list which specifies which waveform-adc pairs to
  %   analyze
  param.img = cat(2,1*ones(6,1),[1:6].'); param.ref_wf_adc = 5;
  
  % .recs: two element vector specifying which records/range-lines to load
  %   [start_record num_records]
  param.recs = [0 inf];
  
  % .presums: Number of additional software presums (coherent averaging) to do
  param.presums = 10;
  
  % .delay: the method used to calculate delay between the channels
  param.delay = struct('method','xcorr_complex','ref_bins',-20:20,'search_bins',-7:7,'Mt',64)
end

%% Automated Section

basic_rx_chan_equalization(param,defaults);
