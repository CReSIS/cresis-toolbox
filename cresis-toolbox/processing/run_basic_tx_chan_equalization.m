% script run_basic_tx_chan_equalization
%
% Runs basic_tx_chan_equalization
%
% Author: John Paden

% Enable Just One Radar Setup
radar_setup = 'MCORDS5';

%% RDS: MCORDS5
if strcmpi(radar_setup,'MCORDS5')
  [param,defaults] = default_radar_params_2022_Greenland_Polar5_rds;
  
  % .file_search_mode: Specify how to search for a file: 'last_file',
  %   'specific', 'default', 'segment', 'map', or empty to be asked
  param.config.file_search_mode = 'segment';
  
  % .base_dir_search: cell vector of paths to search for data files
  param.config.base_dir_search = {'\\192.168.1.100\d\awi','C:\rds\2022_Greenland_Polar5\20220512\','D:\awi\','/cresis/snfs1/scratch/2016_Germany_AWI_tests/AWI_ICE_bak/test_flight','/mnt/AWI_SSD0/1604261202/UWB/'};
  
  % out_xml_fn_dir = String containing the directory where the new XML file
  %   will be placed
  if ispc
    param.basic_tx_chan_equal.out_xml_fn_dir = 'C:\waveforms\';
    param.basic_tx_chan_equal.arena_base_dir = 'C:\Users\Administrator\Desktop\Arena_Shared\configs\';
    param.basic_tx_chan_equal.arena_base_dir = 'C:\arena_waveforms\';
  else
    param.basic_tx_chan_equal.out_xml_fn_dir = '~/waveforms/';
    param.basic_tx_chan_equal.arena_base_dir = '~/arena_waveforms/';
  end
  
elseif strcmpi(radar_setup,'MCORDS3')
  [param,defaults] = default_radar_params_2016_Antarctica_DC8_mcords;
  
  % .file_search_mode: Specify how to search for a file: 'last_file',
  %   'specific', 'default', 'segment', 'map', or empty to be asked
  param.file_search_mode = 'segment';

  % .base_dir_search: cell vector of paths to search for data files
  param.base_dir_search = {'W:\','/process/mcords/','/mnt/AWI_SSD0/1604261202/UWB/'};
  
  % out_xml_fn_dir = String containing the directory where the new XML file
  %   will be placed
  if ispc
    param.out_xml_fn_dir = 'Z:\waveforms\';
  else
    param.out_xml_fn_dir = '~/waveforms/';
  end
end

%% Automated Section

basic_tx_chan_equalization(param,defaults);
