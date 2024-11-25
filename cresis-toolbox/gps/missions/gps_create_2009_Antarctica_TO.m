% script gps_create_2009_antarctica_TO
%
% Makes the GPS files for 2009 Antarctica TO field season
%
% See also: fix_gps_2009_antarctica_TO.m which was used to generate
% most of the code in this file.

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2009_Antarctica_TO');
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
%% User Settings
% ======================================================================
debug_level = 1;

in_base_path = fullfile(data_support_path,'2009_Antarctica_TO');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

% %% 20091212_01
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_12122009.txt');
% out_fns{file_idx} = 'gps_20091212_01.mat';
% file_type{file_idx} = 'Novatel';
% params{file_idx} = struct('time_reference','gps');
% gps_source{file_idx} = 'Novatel-Final';
% sync_flag{file_idx} = 0;
% 
% %% 20091222_01: THIS FILE HAS LARGE INS JUMPS
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_12212009.txt');
% out_fns{file_idx} = 'gps_20091222_01.mat';
% file_type{file_idx} = 'Novatel';
% params{file_idx} = struct('time_reference','gps');
% gps_source{file_idx} = 'Novatel-Final';
% sync_flag{file_idx} = 0;
% 
% %% 20091222_02
% %% 20091223_01
% 
% %% 20091224_01
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'rover_ppp_antarctica_12242009_TC.txt');
% out_fns{file_idx} = 'gps_20091224_01.mat';
% file_type{file_idx} = 'Novatel';
% params{file_idx} = struct('time_reference','gps');
% gps_source{file_idx} = 'Novatel-Final';
% sync_flag{file_idx} = 0;
% 
% %% 20091228_01
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_12272009.txt');
% out_fns{file_idx} = 'gps_20091228_01.mat';
% file_type{file_idx} = 'Novatel';
% params{file_idx} = struct('time_reference','gps');
% gps_source{file_idx} = 'Novatel-Final';
% sync_flag{file_idx} = 0;
% 
% %% 20091228_02
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_12282009_1.txt');
% out_fns{file_idx} = 'gps_20091228_02.mat';
% file_type{file_idx} = 'Novatel';
% params{file_idx} = struct('time_reference','gps');
% gps_source{file_idx} = 'Novatel-Final';
% sync_flag{file_idx} = 0;
% 
% %% 20091229_01
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_12282009_2.txt');
% out_fns{file_idx} = 'gps_20091229_01.mat';
% file_type{file_idx} = 'Novatel';
% params{file_idx} = struct('time_reference','gps');
% gps_source{file_idx} = 'Novatel-Final';
% sync_flag{file_idx} = 0;
% 
% %% 20091230_01
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_12302009_1.txt');
% out_fns{file_idx} = 'gps_20091230_01.mat';
% file_type{file_idx} = 'Novatel';
% params{file_idx} = struct('time_reference','gps');
% gps_source{file_idx} = 'Novatel-Final';
% sync_flag{file_idx} = 0;
% 
% %% 20091230_02
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_12302009_2.txt');
% out_fns{file_idx} = 'gps_20091230_02.mat';
% file_type{file_idx} = 'Novatel';
% params{file_idx} = struct('time_reference','gps');
% gps_source{file_idx} = 'Novatel-Final';
% sync_flag{file_idx} = 0;
% 
% %% 20100101_01
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_12312009.txt');
% out_fns{file_idx} = 'gps_20100101_01.mat';
% file_type{file_idx} = 'Novatel';
% params{file_idx} = struct('time_reference','gps');
% gps_source{file_idx} = 'Novatel-Final';
% sync_flag{file_idx} = 0;
% 
% %% 20100101_02
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_01012010.txt');
% out_fns{file_idx} = 'gps_20100101_02.mat';
% file_type{file_idx} = 'Novatel';
% params{file_idx} = struct('time_reference','gps');
% gps_source{file_idx} = 'Novatel-Final';
% sync_flag{file_idx} = 0;

%% 20100103_01
file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_01022010.txt');
out_fns{file_idx} = 'gps_20100103_01.mat';
file_type{file_idx} = 'Novatel';
params{file_idx} = struct('time_reference','gps');
gps_source{file_idx} = 'Novatel-Final';
sync_flag{file_idx} = 0;

%% 20100103_02
file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_01032010_1.txt');
out_fns{file_idx} = 'gps_20100103_02.mat';
file_type{file_idx} = 'Novatel';
params{file_idx} = struct('time_reference','gps');
gps_source{file_idx} = 'Novatel-Final';
sync_flag{file_idx} = 0;

%% 20100104_01
file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_01032010_2.txt');
out_fns{file_idx} = 'gps_20100104_01.mat';
file_type{file_idx} = 'Novatel';
params{file_idx} = struct('time_reference','gps');
gps_source{file_idx} = 'Novatel-Final';
sync_flag{file_idx} = 0;

%% 20100104_02
file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'rover_ppp_antarctica_01042010_1_TC.txt');
out_fns{file_idx} = 'gps_20100104_02.mat';
file_type{file_idx} = 'Novatel';
params{file_idx} = struct('time_reference','gps');
gps_source{file_idx} = 'Novatel-Final';
sync_flag{file_idx} = 0;

%% 20100105_01
file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'rover_ppp_antarctica_01042010_2_TC.txt');
out_fns{file_idx} = 'gps_20100105_01.mat';
file_type{file_idx} = 'Novatel';
params{file_idx} = struct('time_reference','gps');
gps_source{file_idx} = 'Novatel-Final';
sync_flag{file_idx} = 0;

%% 20100105_02
file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_01052010_1.txt');
out_fns{file_idx} = 'gps_20100105_02.mat';
file_type{file_idx} = 'Novatel';
params{file_idx} = struct('time_reference','gps');
gps_source{file_idx} = 'Novatel-Final';
sync_flag{file_idx} = 0;

%% 20100106_01
file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_01052010_2.txt');
out_fns{file_idx} = 'gps_20100106_01.mat';
file_type{file_idx} = 'Novatel';
params{file_idx} = struct('time_reference','gps');
gps_source{file_idx} = 'Novatel-Final';
sync_flag{file_idx} = 0;

%% 20100106_02
file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_01052010_3.txt');
out_fns{file_idx} = 'gps_20100106_02.mat';
file_type{file_idx} = 'Novatel';
params{file_idx} = struct('time_reference','gps');
gps_source{file_idx} = 'Novatel-Final';
sync_flag{file_idx} = 0;

%% 20100106_03
file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_01052010_4.txt');
out_fns{file_idx} = 'gps_20100106_03.mat';
file_type{file_idx} = 'Novatel';
params{file_idx} = struct('time_reference','gps');
gps_source{file_idx} = 'Novatel-Final';
sync_flag{file_idx} = 0;

%% 20100106_04
file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_01062010_1.txt');
out_fns{file_idx} = 'gps_20100106_04.mat';
file_type{file_idx} = 'Novatel';
params{file_idx} = struct('time_reference','gps');
gps_source{file_idx} = 'Novatel-Final';
sync_flag{file_idx} = 0;

%% 20100106_05
file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_01062010_2.txt');
out_fns{file_idx} = 'gps_20100106_05.mat';
file_type{file_idx} = 'Novatel';
params{file_idx} = struct('time_reference','gps');
gps_source{file_idx} = 'Novatel-Final';
sync_flag{file_idx} = 0;

%% 20100108_01
file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_01072010.txt');
out_fns{file_idx} = 'gps_20100108_01.mat';
file_type{file_idx} = 'Novatel';
params{file_idx} = struct('time_reference','gps');
gps_source{file_idx} = 'Novatel-Final';
sync_flag{file_idx} = 0;

%% 20100108_02
file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'rover_ppp_antarctica_01082010_LC.txt');
out_fns{file_idx} = 'gps_20100108_02.mat';
file_type{file_idx} = 'Novatel';
params{file_idx} = struct('time_reference','gps');
gps_source{file_idx} = 'Novatel-Final';
sync_flag{file_idx} = 0;

%% 20100111_01
file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_01102010.txt');
out_fns{file_idx} = 'gps_20100111_01.mat';
file_type{file_idx} = 'Novatel';
params{file_idx} = struct('time_reference','gps');
gps_source{file_idx} = 'Novatel-Final';
sync_flag{file_idx} = 0;

%% 20100111_02
file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_01112010_1.txt');
out_fns{file_idx} = 'gps_20100111_02.mat';
file_type{file_idx} = 'Novatel';
params{file_idx} = struct('time_reference','gps');
gps_source{file_idx} = 'Novatel-Final';
sync_flag{file_idx} = 0;

%% 20100112_01
file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_01112010_2.txt');
out_fns{file_idx} = 'gps_20100112_01.mat';
file_type{file_idx} = 'Novatel';
params{file_idx} = struct('time_reference','gps');
gps_source{file_idx} = 'Novatel-Final';
sync_flag{file_idx} = 0;

%% 20100112_02
file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_01112010_3.txt');
out_fns{file_idx} = 'gps_20100112_02.mat';
file_type{file_idx} = 'Novatel';
params{file_idx} = struct('time_reference','gps');
gps_source{file_idx} = 'Novatel-Final';
sync_flag{file_idx} = 0;

%% 20100116_01
file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_01162010_2.txt');
out_fns{file_idx} = 'gps_20100116_01.mat';
file_type{file_idx} = 'Novatel';
params{file_idx} = struct('time_reference','gps');
gps_source{file_idx} = 'Novatel-Final';
sync_flag{file_idx} = 0;

%% 20100116_02
file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_01162010_3.txt');
out_fns{file_idx} = 'gps_20100116_02.mat';
file_type{file_idx} = 'Novatel';
params{file_idx} = struct('time_reference','gps');
gps_source{file_idx} = 'Novatel-Final';
sync_flag{file_idx} = 0;

%% 20100117_01
file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_01162010_4.txt');
out_fns{file_idx} = 'gps_20100117_01.mat';
file_type{file_idx} = 'Novatel';
params{file_idx} = struct('time_reference','gps');
gps_source{file_idx} = 'Novatel-Final';
sync_flag{file_idx} = 0;

%% 20100117_02
file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_01172010_1.txt');
out_fns{file_idx} = 'gps_20100117_02.mat';
file_type{file_idx} = 'Novatel';
params{file_idx} = struct('time_reference','gps');
gps_source{file_idx} = 'Novatel-Final';
sync_flag{file_idx} = 0;

%% 20100118_01
file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_01172010_2.txt');
out_fns{file_idx} = 'gps_20100118_01.mat';
file_type{file_idx} = 'Novatel';
params{file_idx} = struct('time_reference','gps');
gps_source{file_idx} = 'Novatel-Final';
sync_flag{file_idx} = 0;

%% 20100118_02
file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_01182010_1.txt');
out_fns{file_idx} = 'gps_20100118_02.mat';
file_type{file_idx} = 'Novatel';
params{file_idx} = struct('time_reference','gps');
gps_source{file_idx} = 'Novatel-Final';
sync_flag{file_idx} = 0;

%% 20100119_01
file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'rover_diff_antarctica_01182010_3.txt');
out_fns{file_idx} = 'gps_20100119_01.mat';
file_type{file_idx} = 'Novatel';
params{file_idx} = struct('time_reference','gps');
gps_source{file_idx} = 'Novatel-Final';
sync_flag{file_idx} = 0;

% ======================================================================
%% Read and translate files according to user settings
% ======================================================================
gps_create;


% ======================================================================
%% Combine partial-day files into a single file and delete partial files
% ======================================================================
partial_gps_fns = get_filenames(gps_path,'gps_','_','.mat');
gps.gps_time = [];
gps.lat = [];
gps.lon = [];
gps.elev = [];
gps.roll = [];
gps.pitch = [];
gps.heading = [];
done = false;
queued_gps_fns = {};
for gps_idx = 1:length(partial_gps_fns)
  queued_gps_fns{end+1} = partial_gps_fns{gps_idx};
  new_gps = load(partial_gps_fns{gps_idx});
  gps.gps_time = [gps.gps_time new_gps.gps_time];
  gps.lat = [gps.lat new_gps.lat];
  gps.lon = [gps.lon new_gps.lon];
  gps.elev = [gps.elev new_gps.elev];
  gps.roll = [gps.roll new_gps.roll];
  gps.pitch = [gps.pitch new_gps.pitch];
  gps.heading = [gps.heading new_gps.heading];
  gps.gps_source = new_gps.gps_source;
  [tmp gps_fn_name gps_fn_ext] = fileparts(partial_gps_fns{gps_idx});
  if gps_idx == length(partial_gps_fns)
    done = true;...
  else
    [tmp next_gps_fn_name] = fileparts(partial_gps_fns{gps_idx+1});
    if ~strcmp(gps_fn_name(5:13),next_gps_fn_name(5:13))
      done = true;
    end
  end
  if done
    gps_fn = fullfile(gps_path, [gps_fn_name(1:12) gps_fn_ext]);
    fprintf('Combined file: %s\n', gps_fn);
    save(gps_fn,'-struct','gps');
    % Clean up (delete) the partial files
    for delete_idx = 1:length(queued_gps_fns)
      delete(queued_gps_fns{delete_idx});
    end
    gps.gps_time = [];
    gps.lat = [];
    gps.lon = [];
    gps.elev = [];
    gps.roll = [];
    gps.pitch = [];
    gps.heading = [];
    done = false;
    queued_gps_fns = {};
  end
end



% 20091212_01
%   rover_diff_antarctica_12122009
%   rover_ppp_antarctica_12122009_TC
%   rover_ppp_antarctica_12122009_LC
% 20091222_01
%   rover_diff_antarctica_12212009
%   rover_ppp_antarctica_12212009_TC
%   rover_ppp_antarctica_12212009_LC
% 20091222_02
%   rover_diff_antarctica_12212009
%   rover_ppp_antarctica_12212009_TC
%   rover_ppp_antarctica_12212009_LC
% 20091223_01
% 20091224_01
%   rover_ppp_antarctica_12242009_TC
% 20091228_01
%   rover_diff_antarctica_12272009
%   rover_ppp_antarctica_12272009_TC
%   rover_ppp_antarctica_12272009_LC
% 20091228_02
%   rover_diff_antarctica_12282009_1
%   rover_ppp_antarctica_12282009_1_TC
%   rover_ppp_antarctica_12282009_1_LC
% 20091229_01
%   rover_diff_antarctica_12282009_2
%   rover_ppp_antarctica_12282009_2_TC
%   rover_ppp_antarctica_12282009_2_LC
% 20091230_01
%   rover_diff_antarctica_12302009_1
%   rover_ppp_antarctica_12302009_1_TC
%   rover_ppp_antarctica_12302009_1_LC
% 20091230_02
%   rover_diff_antarctica_12302009_2
%   rover_ppp_antarctica_12302009_2_TC
%   rover_ppp_antarctica_12302009_2_LC
% 20100101_01
%   rover_diff_antarctica_12312009
% 20100101_02
%   rover_diff_antarctica_01012010
%   rover_ppp_antarctica_01012010_TC
% 20100103_01
%   rover_diff_antarctica_01022010
%   rover_ppp_antarctica_01022010_TC
% 20100103_02
%   rover_diff_antarctica_01032010_1
%   rover_ppp_antarctica_01032010_1_TC
%   rover_ppp_antarctica_01032010_1_LC
% 20100104_01
%   rover_diff_antarctica_01032010_2
%   rover_ppp_antarctica_01032010_2_TC
%   rover_ppp_antarctica_01032010_2_LC
% 20100104_02
%   rover_ppp_antarctica_01042010_1_TC
% 20100105_01
%   rover_ppp_antarctica_01042010_2_TC
% 20100105_02
%   rover_diff_antarctica_01052010_1
%   rover_ppp_antarctica_01052010_1_TC
%   rover_ppp_antarctica_01052010_1_LC
% 20100106_01
%   rover_diff_antarctica_01052010_2
%   rover_ppp_antarctica_01052010_2_LC
% 20100106_02
%   rover_diff_antarctica_01052010_3
%   rover_ppp_antarctica_01052010_3_LC
% 20100106_03
%   rover_diff_antarctica_01052010_4
%   rover_ppp_antarctica_01052010_4_LC
% 20100106_04
%   rover_diff_antarctica_01062010_1
%   rover_ppp_antarctica_01062010_1_LC
% 20100106_05
%   rover_diff_antarctica_01062010_2
%   rover_ppp_antarctica_01062010_2_LC
% 20100108_01
%   rover_diff_antarctica_01072010
%   rover_ppp_antarctica_01072010_TC
% 20100108_02
%   rover_ppp_antarctica_01082010_LC
% 20100111_01
%   rover_diff_antarctica_01102010
%   rover_ppp_antarctica_01102010_TC
% 20100111_02
%   rover_diff_antarctica_01112010_1
%   rover_ppp_antarctica_01112010_1_LC
% 20100112_01
%   rover_diff_antarctica_01112010_2
%   rover_ppp_antarctica_01112010_2_LC
% 20100112_02
%   rover_diff_antarctica_01112010_3
%   rover_ppp_antarctica_01112010_3_TC
% 20100116_01
%   rover_diff_antarctica_01162010_2
%   rover_ppp_antarctica_01162010_2_LC
% 20100116_02
%   rover_diff_antarctica_01162010_3
%   rover_ppp_antarctica_01162010_3_LC
% 20100117_01
%   rover_diff_antarctica_01162010_4
%   rover_ppp_antarctica_01162010_4_TC
% 20100117_02
%   rover_diff_antarctica_01172010_1
%   rover_ppp_antarctica_01172010_1_LC
% 20100118_01
%   rover_diff_antarctica_01172010_2
%   rover_ppp_antarctica_01172010_2_LC
% 20100118_02
%   rover_diff_antarctica_01182010_1
%   rover_ppp_antarctica_01182010_1_LC
% 20100119_01
%   rover_diff_antarctica_01182010_3
%   rover_ppp_antarctica_01182010_3_LC




