% script run_basic_noise_analysis
%
% Runs basic_noise_analysis
%
% Author: John Paden

% Initialization
physical_constants;
param = [];

% Enable Just One Radar Setup
radar_setup = 'MCORDS5';

%% RDS: MCORDS5
if strcmpi(radar_setup,'MCORDS5')
  [param,defaults] = default_radar_params_2022_Greenland_Polar5_rds;
  
  % .file_search_mode: Specify how to search for a file: 'last_file',
  %   'specific', 'default', or empty to be asked
  param.config.file_search_mode = 'last_file';

  % .base_dir_search: cell vector of paths to search for data files
  param.config.base_dir_search = {'G:\20220603\','C:\rds\2022_Greenland_Polar5\20220512\','D:\awi\','\\192.168.1.100\D\AWI\'};
  
  % .pdf_en: Enable time domain, probability density function, and quantization plots
  param.basic_noise_analysis.pdf_en = false;
  % .psd_en: Enable PSD plot
  param.basic_noise_analysis.psd_en = true;
  
  % .img: wf-adc pair list which specifies which waveform-adc pairs to
  %   analyze
  wf = 3; adcs = 1:8;
  param.config.img = cat(2, wf*ones(length(adcs),1), adcs.');

  % .recs: two element vector specifying which records/range-lines to load
  %   [start_record num_records]
  param.config.recs = [0 250];
  
  % .presums: Number of additional software presums (coherent averaging) to do
  param.config.presums = 1;
end

%% RDS: MCORDS5
if strcmpi(radar_setup,'MCORDS5_P3')
  [param,defaults] = default_radar_params_2017_Greenland_P3_accum;
  
  % .file_search_mode: Specify how to search for a file: 'last_file',
  %   'specific', 'default', or empty to be asked
  param.file_search_mode = 'last_file';

  % .base_dir_search: cell vector of paths to search for data files
  param.base_dir_search = {'A:\'};
  
  % .pdf_en: Enable time domain, probability density function, and quantization plots
  param.pdf_en = false;
  % .psd_en: Enable PSD plot
  param.psd_en = true;
  
  % .img: wf-adc pair list which specifies which waveform-adc pairs to
  %   analyze
  wf = 2; adcs = 1:4;
  param.img = cat(2, wf*ones(length(adcs),1), adcs.');

  % .recs: two element vector specifying which records/range-lines to load
  %   [start_record num_records]
  param.recs = [0 250];
  
  % .presums: Number of additional software presums (coherent averaging) to do
  param.presums = 1;
end

%% RDS: MCORDS3_P3
if strcmpi(radar_setup,'MCORDS3_P3')
  [param,defaults] = default_radar_params_2017_Greenland_P3_mcords;
  
  % .file_search_mode: Specify how to search for a file: 'last_file',
  %   'specific', 'default', or empty to be asked
  param.file_search_mode = 'segment';

  % .base_dir_search: cell vector of paths to search for data files
  param.base_dir_search = {'Z:\'};
  
  % .pdf_en: Enable time domain, probability density function, and quantization plots
  param.pdf_en = false;
  % .psd_en: Enable PSD plot
  param.psd_en = true;
  
  % .img: wf-adc pair list which specifies which waveform-adc pairs to
  %   analyze
  wf = 3; adcs = 2:16;
  param.img = cat(2, wf*ones(length(adcs),1), adcs.');

  % .recs: two element vector specifying which records/range-lines to load
  %   [start_record num_records]
  param.recs = [];
  
  % .presums: Number of additional software presums (coherent averaging) to do
  param.presums = 1;
  
  % .noise_burst_removal: remove bursty noise
  param.noise_burst_removal = false;
end

%% RDS: MCORDS3_DC8
if strcmpi(radar_setup,'MCORDS3_DC8')
  [param,defaults] = default_radar_params_2016_Antarctica_DC8_mcords;
  
  % .file_search_mode: Specify how to search for a file: 'last_file',
  %   'specific', 'default', or empty to be asked
  param.file_search_mode = 'segment';

  % .base_dir_search: cell vector of paths to search for data files
  param.base_dir_search = {'D:\awi\','/process/mcords/','/mnt/AWI_SSD0/1604261202/UWB/'};
  
  % .pdf_en: Enable time domain, probability density function, and quantization plots
  param.pdf_en = false;
  % .psd_en: Enable PSD plot
  param.psd_en = true;
  
  % .img: wf-adc pair list which specifies which waveform-adc pairs to
  %   analyze
  wf = 3; adcs = 1:6;
  param.img = cat(2, wf*ones(length(adcs),1), adcs.');

  % .recs: two element vector specifying which records/range-lines to load
  %   [start_record num_records]
  param.recs = [];
  
  % .presums: Number of additional software presums (coherent averaging) to do
  param.presums = 1;
end

%% Automated Section

basic_noise_analysis(param,defaults);
