% script gps_create_2009_greenland_P3_DGPSwINS
%
% Makes the DGPSwINS files for 2009 Greenland P3 field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2009_Greenland_P3');
if ~exist(gps_path,'dir')
  fprintf('Making directory %s\n', gps_path);
  fprintf('  Press a key to proceed\n');
  pause;
  mkdir(gps_path);
end

if isempty(data_support_path)
  data_support_path = gRadar.data_support_path;
end

% ======================================================================
% User Settings
% ======================================================================
debug_level = 1;

in_base_path = fullfile(data_support_path,'2009_Greenland_P3');
gps_path = fullfile(support_path,'gps','2009_Greenland_P3');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {};

% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'sbet_27MarPPPFinal.out');
% out_fns{file_idx} = 'gps_20090327.mat';
% file_type{file_idx} = 'Applanix';
% params{file_idx} = struct('year',2009,'month',03,'day',27,'time_reference','utc');
% gps_source{file_idx} = 'atm-final_20090717';
% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'sbet_30MarPPPFinal.out');
% out_fns{file_idx} = 'gps_20090330.mat';
% file_type{file_idx} = 'Applanix';
% params{file_idx} = struct('year',2009,'month',03,'day',30,'time_reference','utc');
% gps_source{file_idx} = 'atm-final_20090717';
% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'sbet_31MarPPPFinal.out');
% out_fns{file_idx} = 'gps_20090331.mat';
% file_type{file_idx} = 'Applanix';
% params{file_idx} = struct('year',2009,'month',03,'day',31,'time_reference','utc');
% gps_source{file_idx} = 'atm-final_20090717';
% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'sbet_01AprPPPFinal.out');
% out_fns{file_idx} = 'gps_20090401.mat';
% file_type{file_idx} = 'Applanix';
% params{file_idx} = struct('year',2009,'month',04,'day',01,'time_reference','utc');
% gps_source{file_idx} = 'atm-final_20090717';
% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'sbet_02AprPPPFinal.out');
% out_fns{file_idx} = 'gps_20090402.mat';
% file_type{file_idx} = 'Applanix';
% params{file_idx} = struct('year',2009,'month',04,'day',02,'time_reference','utc');
% gps_source{file_idx} = 'atm-final_20090717';
% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'sbet_05AprPPPFinal.out');
% out_fns{file_idx} = 'gps_20090405.mat';
% file_type{file_idx} = 'Applanix';
% params{file_idx} = struct('year',2009,'month',04,'day',05,'time_reference','utc');
% gps_source{file_idx} = 'atm-final_20090717';
%  
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'sbet_06AprPPPFinal.out');
% out_fns{file_idx} = 'gps_20090406.mat';
% file_type{file_idx} = 'Applanix';
% params{file_idx} = struct('year',2009,'month',04,'day',06,'time_reference','utc');
% gps_source{file_idx} = 'atm-final_20090717';
% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'sbet_14AprPPPFinal.out');
% out_fns{file_idx} = 'gps_20090414.mat';
% file_type{file_idx} = 'Applanix';
% params{file_idx} = struct('year',2009,'month',04,'day',14,'time_reference','utc');
% gps_source{file_idx} = 'atm-final_20090717';
% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'sbet_15AprPPPFinal.out');
% out_fns{file_idx} = 'gps_20090415.mat';
% file_type{file_idx} = 'Applanix';
% params{file_idx} = struct('year',2009,'month',04,'day',15,'time_reference','utc');
% gps_source{file_idx} = 'atm-final_20090717';
% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'sbet_16AprPPPFinal.out');
% out_fns{file_idx} = 'gps_20090416.mat';
% file_type{file_idx} = 'Applanix';
% params{file_idx} = struct('year',2009,'month',04,'day',16,'time_reference','utc');
% gps_source{file_idx} = 'atm-final_20090717';
% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'sbet_17AprPPPFinal.out');
% out_fns{file_idx} = 'gps_20090417.mat';
% file_type{file_idx} = 'Applanix';
% params{file_idx} = struct('year',2009,'month',04,'day',17,'time_reference','utc');
% gps_source{file_idx} = 'atm-final_20090717';
% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'sbet_20AprPPPFinal.out');
% out_fns{file_idx} = 'gps_20090420.mat';
% file_type{file_idx} = 'Applanix';
% params{file_idx} = struct('year',2009,'month',04,'day',20,'time_reference','utc');
% gps_source{file_idx} = 'atm-final_20090717';
% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'sbet_21AprPPPFinal.out');
% out_fns{file_idx} = 'gps_20090421.mat';
% file_type{file_idx} = 'Applanix';
% params{file_idx} = struct('year',2009,'month',04,'day',21,'time_reference','utc');
% gps_source{file_idx} = 'atm-final_20090717';
% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'sbet_22AprPPPFinal.out');
% out_fns{file_idx} = 'gps_20090422.mat';
% file_type{file_idx} = 'Applanix';
% params{file_idx} = struct('year',2009,'month',04,'day',22,'time_reference','utc');
% gps_source{file_idx} = 'atm-final_20090717';
% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'sbet_23AprPPPFinal.out');
% out_fns{file_idx} = 'gps_20090423.mat';
% file_type{file_idx} = 'Applanix';
% params{file_idx} = struct('year',2009,'month',04,'day',23,'time_reference','utc');
% gps_source{file_idx} = 'atm-final_20090717';
% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'sbet_24AprPPPFinal.out');
% out_fns{file_idx} = 'gps_20090424.mat';
% file_type{file_idx} = 'Applanix';
% params{file_idx} = struct('year',2009,'month',04,'day',24,'time_reference','utc');
% gps_source{file_idx} = 'atm-final_20090717';
% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'sbet_25AprPPPFinal.out');
% out_fns{file_idx} = 'gps_20090425.mat';
% file_type{file_idx} = 'Applanix';
% params{file_idx} = struct('year',2009,'month',04,'day',25,'time_reference','utc');
% gps_source{file_idx} = 'atm-final_20090717';
% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'20090427_aa_l12_cfm_itrf05_11aug09_thu3_ilul_retrieved_20150601_ATM');
% out_fns{file_idx} = 'gps_20090427.mat';
% file_type{file_idx} = 'Traj+General_ASCII';
% params{file_idx} = struct('year',2009,'month',04,'day',27,'time_reference','utc');
% in_fns_ins{file_idx} = fullfile(in_base_path,'20090427_ATM_vldInsExtract.txt');
% params_ins{file_idx} = [];
% params_ins{file_idx}.format_str = '%f%f%f%f%f%f';
% params_ins{file_idx}.types = {'year','day','sec','pitch_deg','roll_deg','heading_deg'};
% params_ins{file_idx}.textscan = {'delimiter',',','emptyvalue',NaN};
% params_ins{file_idx}.headerlines = 1;
% params_ins{file_idx}.time_reference = 'utc';
% gps_source{file_idx} = 'atm-final_20150601';
% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'sbet_28AprPPPFinal.out');
% out_fns{file_idx} = 'gps_20090428.mat';
% file_type{file_idx} = 'Applanix';
% params{file_idx} = struct('year',2009,'month',04,'day',28,'time_reference','utc');
% gps_source{file_idx} = 'atm-final_20090717';
% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'sbet_01MayPPPFinal.out');
% out_fns{file_idx} = 'gps_20090501.mat';
% file_type{file_idx} = 'Applanix';
% params{file_idx} = struct('year',2009,'month',05,'day',01,'time_reference','utc');
% gps_source{file_idx} = 'atm-final_20090717';
% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'sbet_02MayPPPFinal.out');
% out_fns{file_idx} = 'gps_20090502.mat';
% file_type{file_idx} = 'Applanix';
% params{file_idx} = struct('year',2009,'month',05,'day',02,'time_reference','utc');
% gps_source{file_idx} = 'atm-final_20090717';
% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'20090505_aa_l12_cfm_itrf05_11aug09_613a_retrieved_20150601_ATM');
% out_fns{file_idx} = 'gps_20090505.mat';
% file_type{file_idx} = 'Traj+General_ASCII';
% params{file_idx} = struct('year',2009,'month',5,'day',5,'time_reference','utc','input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f%f');
% in_fns_ins{file_idx} = fullfile(in_base_path,'20090505_ATM_vldInsExtract.txt');
% params_ins{file_idx} = [];
% params_ins{file_idx}.format_str = '%f%f%f%f%f%f';
% params_ins{file_idx}.types = {'year','day','sec','pitch_deg','roll_deg','heading_deg'};
% params_ins{file_idx}.textscan = {'delimiter',',','emptyvalue',NaN};
% params_ins{file_idx}.headerlines = 1;
% params_ins{file_idx}.time_reference = 'utc';
% gps_source{file_idx} = 'atm-final_20150601';

% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(in_base_path,'sbet_06MayFlt','','PPPFinal.out');
% out_fns{file_idx} = 'gps_20090506.mat';
% file_type{file_idx} = 'Applanix';
% params{file_idx} = struct('year',2009,'month',05,'day',06,'time_reference','utc');
% gps_source{file_idx} = 'atm-final_20090717';


% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

