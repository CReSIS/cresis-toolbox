% script startup.m
%
% This is a template startup.m file.
%
% STEPS TO SETUP MATLAB ENVIRONMENT ARE ON WIKI:
%  https://wiki.cresis.ku.edu/
%
% Step 1
%  PC:
%  Rename this file to startup.m and place in:
%    C:\Users\USERNAME\Documents\MATLAB
%
%  LINUX-KU:
%  Rename this file to startup.m and place in /users/USERNAME/.matlab/
%  LINUX-IU:
%  Rename this file to startup.m and place in /N/u/USERNAME/Quarry/.matlab/
%
% Step 2
%  Modify one of the profiles below and set cur_profile
%  - Probably just need to update path_override and tmp_file_path
%
% Step 3
%  Restart matlab making suring the this startup script runs.
%
% Authors: John Paden

if ~(~ismcc && isdeployed)
  
  %% ===> SELECT CURRENT PROFILE HERE <===
  % cur_profile: Set the current profile to load (match to pidx below)
  % Profile Windows (PROFILE 1)
  % Profile Linux/Mac (PROFILE 2)
  % KU Profile Linux (PROFILE 3)
  % KU Field Profile Linux (PROFILE 4)
  % KU Desktop Profile Windows (PROFILE 5)
  % IU Profile Linux (PROFILE 6)
  % AWI Profile Field Windows (PROFILE 7)
  % AWI Profile Field Linux (PROFILE 8)
  % AWI Profile Ollie (PROFILE 9)
  if ispc
    cur_profile = 1; % Put your default Windows profile here
  else
    cur_profile = 2; % Put your default Linux/Mac profile here
  end
  
  fprintf('Startup Script Running\n');
  
  format short; format compact;

  %% Profile Windows (PROFILE 1)
  % ----------------------------------------------------------------------
  pidx = 1; % profile index
  profile(pidx).path_override             = fullfile(getenv('USERPROFILE'),'My Documents','scripts','matlab');
  profile(pidx).path                      = fullfile(getenv('USERPROFILE'),'My Documents','scripts','cresis-toolbox','cresis-toolbox');
  profile(pidx).param_path                = fullfile(getenv('USERPROFILE'),'My Documents','scripts','ct_params');
  
  profile(pidx).tmp_file_path             = 'C:\tmp\ct_user_tmp\';
  
  profile(pidx).data_path                 = 'C:\';
  profile(pidx).data_support_path         = 'C:\metadata\';
  profile(pidx).support_path              = 'C:\csarp_support\';
  profile(pidx).out_path                  = 'C:\output\';
  profile(pidx).gis_path                  = 'C:\GIS_data\';
  profile(pidx).ct_tmp_file_path          = fullfile(profile(pidx).out_path,'ct_tmp');
  
  profile(pidx).cluster.data_location       = fullfile(profile(pidx).tmp_file_path,'cluster-temp');
  
  profile(pidx).cluster.type                  = 'matlab';
  %profile(pidx).cluster.type                  = 'debug';
  profile(pidx).cluster.max_jobs_active       = 4;
  profile(pidx).cluster.max_time_per_job      = 2*86400;
  profile(pidx).cluster.desired_time_per_job  = 0;
  profile(pidx).cluster.max_retries           = 1;
  profile(pidx).cluster.submit_pause          = 0;
  profile(pidx).cluster.stat_pause            = 1;
  
  profile(pidx).ops.url = 'https://ops.cresis.ku.edu/';
  profile(pidx).ops.google_map_api_key = 'AIzaSyCNexiP6WcIda8ZEa2MnwznWrGotDoLu0w'; % Fill in with your Google API key
  
  
  %% Profile Linux/Mac (PROFILE 2)
  % ----------------------------------------------------------------------
  pidx = 2; % profile index
  home_dir = getenv('HOME');
  profile(pidx).path_override             = sprintf('%s/scripts/matlab/',home_dir);
  profile(pidx).path                      = sprintf('%s/scripts/cresis-toolbox/cresis-toolbox/',home_dir);
  profile(pidx).param_path                = sprintf('%s/scripts/ct_params/',home_dir);

  profile(pidx).tmp_file_path             = sprintf('%s/scratch/ct_user_tmp/',home_dir);

  profile(pidx).data_path                 = sprintf('%s/scratch/',home_dir);
  profile(pidx).data_support_path         = sprintf('%s/scratch/metadata/',home_dir);
  profile(pidx).support_path              = sprintf('%s/scratch/csarp_support/',home_dir);
  profile(pidx).out_path                  = sprintf('%s/scratch/',home_dir);
  profile(pidx).gis_path                  = sprintf('%s/scratch/GIS_data/',home_dir);
  profile(pidx).ct_tmp_file_path          = fullfile(profile(pidx).out_path,'ct_tmp');
 
  profile(pidx).cluster.data_location       = fullfile(profile(pidx).tmp_file_path,'cluster-temp');

  profile(pidx).cluster.type                    = 'matlab';
  %profile(pidx).cluster.type                    = 'slurm';
  %profile(pidx).cluster.type                    = 'ollie';
  %profile(pidx).cluster.type                    = 'debug';
  profile(pidx).cluster.max_jobs_active         = 128;
  profile(pidx).cluster.max_time_per_job        = 2*86400;
  profile(pidx).cluster.desired_time_per_job    = 2*3600;
  profile(pidx).cluster.max_retries             = 2;
  profile(pidx).cluster.submit_pause            = 0.2;
  profile(pidx).cluster.stat_pause              = 2;
  profile(pidx).cluster.file_check_pause        = 4;
  
  profile(pidx).ops.url = 'https://ops.cresis.ku.edu/';
  profile(pidx).ops.google_map_api_key = 'AIzaSyCNexiP6WcIda8ZEa2MnwznWrGotDoLu0w'; % Fill in with your Google API key
  
  
  %% KU Profile Linux (PROFILE 3)
  % ----------------------------------------------------------------------
  pidx = 3; % profile index
  home_dir = getenv('HOME');
  profile(pidx).path_override             = sprintf('%s/scripts/matlab/',home_dir);
  profile(pidx).path                      = sprintf('%s/scripts/cresis-toolbox/cresis-toolbox/',home_dir);
  profile(pidx).param_path                = sprintf('%s/scripts/ct_params/',home_dir);
  
  username = getenv('USER');
  profile(pidx).tmp_file_path             = sprintf('/cresis/snfs1/scratch/%s/ct_user_tmp/',username);
  
  profile(pidx).data_path                 = '/cresis/snfs1/data/';
  profile(pidx).data_support_path         = '/cresis/snfs1/dataproducts/metadata/';
  profile(pidx).support_path              = '/cresis/snfs1/dataproducts/csarp_support/';
  profile(pidx).out_path                  = '/cresis/snfs1/dataproducts/ct_data/';
  profile(pidx).gis_path                  = '/cresis/snfs1/dataproducts/GIS_data/';
  profile(pidx).ct_tmp_file_path          = fullfile(profile(pidx).out_path,'ct_tmp');
  
  profile(pidx).cluster.data_location       = fullfile(profile(pidx).tmp_file_path,'cluster-temp');
  
  profile(pidx).cluster.type                  = 'slurm';
  %profile(pidx).cluster.type                  = 'matlab';
  %profile(pidx).cluster.type                  = 'debug';
  profile(pidx).cluster.max_jobs_active       = 96;
  profile(pidx).cluster.max_time_per_job      = 2*86400;
  profile(pidx).cluster.desired_time_per_job  = 0;
  profile(pidx).cluster.max_retries           = 2;
  profile(pidx).cluster.submit_pause          = 0.2;
  profile(pidx).cluster.stat_pause            = 2;
  profile(pidx).cluster.file_check_pause      = 4;
  profile(pidx).cluster.job_complete_pause    = 60;
  profile(pidx).cluster.mem_to_ppn            = 0.9 * 16e9 / 8;
  % profile(pidx).cluster.mem_to_ppn            = 0.9 * 256e9 / 24;
  profile(pidx).cluster.max_ppn               = 4;
  profile(pidx).cluster.max_mem_per_job       = 16e9;
  profile(pidx).cluster.mem_mult_mode          = 'debug';
  profile(pidx).cluster.slurm_submit_arguments = '--partition=cresis -N 1 -n 1 --cpus-per-task=%p --mem=%m --time=%t';
  %profile(pidx).cluster.cpu_time_mult         = 2;
  %profile(pidx).cluster.mem_mult              = 2;
  %profile(pidx).cluster.ppn_fixed             = 4;

  profile(pidx).ops.url = 'https://ops.cresis.ku.edu/';
  profile(pidx).ops.google_map_api_key = 'AIzaSyCNexiP6WcIda8ZEa2MnwznWrGotDoLu0w'; % Fill in with your Google API key
  
  
  %% KU Field Profile Linux (PROFILE 4)
  % ----------------------------------------------------------------------
  pidx = 4; % profile index
  profile(pidx).path_override             = '/scratch/scripts/matlab/';
  profile(pidx).path                      = '/scratch/scripts/cresis-toolbox/cresis-toolbox/';
  profile(pidx).param_path                = '/scratch/scripts/ct_params/';
  
  profile(pidx).tmp_file_path             = '/scratch/tmp/';
  
  profile(pidx).data_path                 = '/scratch/';
  profile(pidx).data_support_path         = '/scratch/metadata/';
  profile(pidx).support_path              = '/scratch/csarp_support/';
  profile(pidx).out_path                  = '/scratch/';
  profile(pidx).gis_path                  = '/scratch/GIS_data';
  profile(pidx).ct_tmp_file_path          = fullfile(profile(pidx).out_path,'ct_tmp');
  
  profile(pidx).cluster.data_location       = fullfile(profile(pidx).tmp_file_path,'cluster-temp');
  
  profile(pidx).cluster.type                  = 'torque';
  %profile(pidx).cluster.type                  = 'matlab';
  %profile(pidx).cluster.type                  = 'debug';
  profile(pidx).cluster.max_jobs_active       = 128;
  profile(pidx).cluster.max_time_per_job      = 2*86400;
  profile(pidx).cluster.desired_time_per_job  = 0;
  profile(pidx).cluster.max_retries           = 2;
  profile(pidx).cluster.submit_pause          = 0.2;
  profile(pidx).cluster.stat_pause            = 2;
  profile(pidx).cluster.file_check_pause      = 4;
  profile(pidx).cluster.mem_to_ppn            = 0.9 * 131754468000 / 46;
  profile(pidx).cluster.max_ppn               = 6;
  profile(pidx).cluster.job_complete_pause    = 5;
  profile(pidx).cluster.max_mem_per_job       = 126e9;
  profile(pidx).cluster.mem_mult_mode          = 'debug';

  profile(pidx).ops.url = 'https://ops.cresis.ku.edu/';
  profile(pidx).ops.google_map_api_key = 'AIzaSyCNexiP6WcIda8ZEa2MnwznWrGotDoLu0w'; % Fill in with your Google API key
  
  
  %% KU Desktop Profile Windows (PROFILE 5)
  % ----------------------------------------------------------------------
  % V:\ --> \\cfs1.cresis.ku.edu\data\
  % X:\ --> \\cfs1.cresis.ku.edu\dataproducts\
  pidx = 5; % profile index
  profile(pidx).path_override             = fullfile(getenv('USERPROFILE'),'My Documents','scripts','matlab');
  profile(pidx).path                      = fullfile(getenv('USERPROFILE'),'My Documents','scripts','cresis-toolbox','cresis-toolbox');
  profile(pidx).param_path                = fullfile(getenv('USERPROFILE'),'My Documents','scripts','ct_params');
  
  profile(pidx).tmp_file_path             = 'C:\temp\ct_user_tmp\';
  
  profile(pidx).data_path                 = 'V:/';
  profile(pidx).data_support_path         = 'X:/metadata/';
  profile(pidx).support_path              = 'X:/csarp_support/';
  profile(pidx).out_path                  = 'X:/ct_data/';
  profile(pidx).gis_path                  = 'X:/GIS_data/';
  profile(pidx).ct_tmp_file_path          = fullfile(profile(pidx).out_path,'ct_tmp');
  
  profile(pidx).cluster.data_location       = fullfile(profile(pidx).tmp_file_path,'cluster-temp');
  
  profile(pidx).cluster.type                  = 'matlab';
  %profile(pidx).cluster.type                  = 'debug';
  profile(pidx).cluster.max_jobs_active       = 4;
  profile(pidx).cluster.max_time_per_job      = 2*86400;
  profile(pidx).cluster.desired_time_per_job  = 0;
  profile(pidx).cluster.max_retries           = 1;
  profile(pidx).cluster.submit_pause          = 0;
  profile(pidx).cluster.stat_pause            = 1;

  profile(pidx).ops.url = 'https://ops.cresis.ku.edu/';
  profile(pidx).ops.google_map_api_key = 'AIzaSyCNexiP6WcIda8ZEa2MnwznWrGotDoLu0w'; % Fill in with your Google API key
  
  %% IU Profile Linux (PROFILE 6)
  % ----------------------------------------------------------------------
  pidx = 6; % profile index
  home_dir = getenv('HOME');
  profile(pidx).path_override             = sprintf('%s/scripts/matlab/',home_dir);
  profile(pidx).path                      = sprintf('%s/scripts/cresis-toolbox/cresis-toolbox/',home_dir);
  profile(pidx).param_path                = sprintf('%s/scripts/ct_params/',home_dir);
  
  username = getenv('USER');
  profile(pidx).tmp_file_path             = sprintf('/N/slate/%s/ct_user_tmp/',username); % scratch may be on dcwan or slate
  
  profile(pidx).data_path                 = '/N/dcwan/projects/cresis/';
  profile(pidx).data_support_path         = '/N/dcwan/projects/cresis/metadata/';
  profile(pidx).support_path              = '/N/dcwan/projects/cresis/csarp_support/';
  profile(pidx).out_path                  = '/N/dcwan/projects/cresis/output/';
  profile(pidx).gis_path                  = '/N/dcwan/projects/cresis/GIS_data';
  profile(pidx).ct_tmp_file_path          = fullfile(profile(pidx).out_path,'ct_tmp');

  profile(pidx).cluster.data_location       = fullfile(profile(pidx).tmp_file_path,'cluster-temp');
  
  %profile(pidx).cluster.type                  = 'slurm';
  %profile(pidx).cluster.type                  = 'torque';
  %profile(pidx).cluster.type                  = 'matlab';
  profile(pidx).cluster.type                  = 'debug';
  if 0
    profile(pidx).cluster.ssh_hostname          = 'karst.uits.iu.edu';
    profile(pidx).cluster.mem_to_ppn            = 0.9 * 32e9 / 16;
    profile(pidx).cluster.max_ppn               = 8;
    profile(pidx).cluster.max_mem_per_job       = 30e9;
    profile(pidx).cluster.mem_mult_mode          = 'debug';
  else
    profile(pidx).cluster.mem_to_ppn            = 0.9 * 256e9 / 24;
    profile(pidx).cluster.max_ppn               = 12;
    profile(pidx).cluster.max_mem_per_job       = 250e9;
    profile(pidx).cluster.mem_mult_mode          = 'auto';
  end
  profile(pidx).cluster.max_jobs_active       = 512;
  profile(pidx).cluster.max_time_per_job      = 4*86400;
  profile(pidx).cluster.desired_time_per_job  = 2*3600;
  profile(pidx).cluster.max_retries           = 2;
  profile(pidx).cluster.submit_pause          = 1;
  profile(pidx).cluster.stat_pause            = 10;
  profile(pidx).cluster.file_check_pause      = 0;

  profile(pidx).cluster.slurm_submit_arguments = '-N 1 -n 1 --cpus-per-task=%p --mem=%m --time=%t';
  %profile(pidx).cluster.slurm_submit_arguments = '-p debug -N 1 -n 1 --cpus-per-task=%p --mem=%m --time=%t';

  profile(pidx).ops.url = 'https://ops.cresis.ku.edu/';
  profile(pidx).ops.google_map_api_key = 'AIzaSyCNexiP6WcIda8ZEa2MnwznWrGotDoLu0w'; % Fill in with your Google API key
  
  
  %% AWI Profile Field Windows (PROFILE 7)
  % ----------------------------------------------------------------------
  pidx = 7; % profile index
  base_dir = 'S:\Scratch\';
  profile(pidx).path_override             = fullfile(base_dir,'scripts','matlab');
  profile(pidx).path                      = fullfile(base_dir,'scripts','cresis-toolbox','cresis-toolbox');
  profile(pidx).param_path                = fullfile(base_dir,'scripts','ct_params');
  
  profile(pidx).tmp_file_path             = fullfile(base_dir,'scripts','ct_user_tmp');
  
  profile(pidx).data_path                 = fullfile(base_dir,'scripts');
  profile(pidx).data_support_path         = fullfile(base_dir,'scripts','metadata');
  profile(pidx).support_path              = fullfile(base_dir,'scripts','csarp_support');
  profile(pidx).out_path                  = fullfile(base_dir,'scripts');
  profile(pidx).gis_path                  = fullfile(base_dir,'scripts','GIS_data');
  profile(pidx).ct_tmp_file_path          = fullfile(profile(pidx).out_path,'ct_tmp');
  
  profile(pidx).cluster.data_location       = fullfile(profile(pidx).tmp_file_path,'cluster-temp');

  profile(pidx).cluster.type                  = 'matlab';
  %profile(pidx).cluster.type                  = 'debug';
  profile(pidx).cluster.max_jobs_active       = 4;
  profile(pidx).cluster.max_time_per_job      = 2*86400;
  profile(pidx).cluster.desired_time_per_job  = 0;
  profile(pidx).cluster.max_retries           = 1;
  profile(pidx).cluster.submit_pause          = 0;
  profile(pidx).cluster.stat_pause            = 1;

  profile(pidx).ops.url = 'https://ops.cresis.ku.edu/';
  profile(pidx).ops.google_map_api_key = 'AIzaSyCNexiP6WcIda8ZEa2MnwznWrGotDoLu0w'; % Fill in with your Google API key
  
  
  %% AWI Profile Field Linux (PROFILE 8)
  % ----------------------------------------------------------------------
  pidx = 8; % profile index
  profile(pidx).path_override             = '/mnt/Scratch/scripts/matlab/';
  profile(pidx).path                      = '/mnt/Scratch/scripts/cresis-toolbox/cresis-toolbox/';
  profile(pidx).param_path                = '/mnt/Scratch/scripts/ct_params/';
  
  profile(pidx).tmp_file_path             = '/mnt/Scratch/ct_user_tmp/';
  
  profile(pidx).data_path                 = '/mnt/AWI_SSD0/';
  profile(pidx).data_support_path         = '/mnt/Scratch/metadata/';
  profile(pidx).support_path              = '/mnt/Scratch/csarp_support/';
  profile(pidx).out_path                  = '/mnt/Scratch/';
  profile(pidx).gis_path                  = '/mnt/Scratch/GIS_data/';
  profile(pidx).ct_tmp_file_path          = fullfile(profile(pidx).out_path,'ct_tmp');
  
  profile(pidx).cluster.data_location       = fullfile(profile(pidx).tmp_file_path,'cluster-temp');
  
  profile(pidx).cluster.type                  = 'torque';
  %profile(pidx).cluster.type                  = 'matlab';
  %profile(pidx).cluster.type                  = 'debug';
  profile(pidx).cluster.max_jobs_active       = 128;
  profile(pidx).cluster.max_time_per_job      = 2*86400;
  profile(pidx).cluster.desired_time_per_job  = 0;
  profile(pidx).cluster.max_retries           = 2;
  profile(pidx).cluster.submit_pause          = 0.2;
  profile(pidx).cluster.stat_pause            = 2;
  profile(pidx).cluster.file_check_pause      = 4;
  profile(pidx).cluster.job_complete_pause    = 5;
  profile(pidx).cluster.mem_to_ppn            = 0.9 * 64e9 / 8;
  profile(pidx).cluster.max_ppn               = 4;
  profile(pidx).cluster.max_mem_per_job       = 62e9;
  profile(pidx).cluster.mem_mult_mode          = 'debug';

  profile(pidx).ops.url = 'https://ops.cresis.ku.edu/';
  profile(pidx).ops.google_map_api_key = 'AIzaSyCNexiP6WcIda8ZEa2MnwznWrGotDoLu0w'; % Fill in with your Google API key
  
  
  %% AWI Profile Ollie (PROFILE 9)
  % ----------------------------------------------------------------------
  pidx = 9; % profile index
  username = getenv('USER');
  profile(pidx).path_override             = sprintf('/work/ollie/%s/scripts/matlab/',username);
  profile(pidx).path                      = sprintf('/work/ollie/%s/scripts/cresis-toolbox/cresis-toolbox/',username);
  profile(pidx).param_path                = sprintf('/work/ollie/%s/scripts/ct_params/',username);
  profile(pidx).slurm_jobs_path           = sprintf('/work/ollie/%s/jobs/',username);

  profile(pidx).tmp_file_path             = sprintf('/work/ollie/%s/Scratch/ct_user_tmp/',username);

  profile(pidx).data_path                 = sprintf('/work/ollie/%s/Data/',username);
  profile(pidx).data_support_path         = sprintf('/work/ollie/%s/Scratch/metadata/',username);
  profile(pidx).support_path              = sprintf('/work/ollie/%s/Scratch/csarp_support/',username);
  profile(pidx).out_path                  = sprintf('/work/ollie/%s/Scratch/',username);
  profile(pidx).gis_path                  = sprintf('/work/ollie/%s/GIS_data/',username);
  profile(pidx).ct_tmp_file_path          = fullfile(profile(pidx).out_path,'ct_tmp');
 
  profile(pidx).cluster.data_location       = fullfile(profile(pidx).tmp_file_path,'cluster-temp');

  %profile(pidx).cluster.type                    = 'matlab';
  profile(pidx).cluster.type                    = 'slurm';
  %profile(pidx).cluster.type                    = 'ollie';
  %profile(pidx).cluster.type                    = 'debug';
  profile(pidx).cluster.max_jobs_active         = 128;
  profile(pidx).cluster.max_time_per_job        = 2*86400;
  profile(pidx).cluster.desired_time_per_job    = 2*3600;
  profile(pidx).cluster.max_retries             = 2;
  profile(pidx).cluster.submit_pause            = 1;
  profile(pidx).cluster.stat_pause              = 10;
  profile(pidx).cluster.file_check_pause        = 4;
  profile(pidx).cluster.job_complete_pause      = 30;
  profile(pidx).cluster.mem_to_ppn              = 0.9 * 64e9 / 36;
  profile(pidx).cluster.max_ppn                 = 18;
  profile(pidx).cluster.max_mem_per_job         = 62e9;
  profile(pidx).cluster.mem_mult_mode            = 'debug';

  profile(pidx).cluster.mcc                     = 'system_eval';

  profile(pidx).ops.url = 'https://ops.cresis.ku.edu/';
  profile(pidx).ops.google_map_api_key = 'AIzaSyCNexiP6WcIda8ZEa2MnwznWrGotDoLu0w'; % Fill in with your Google API key
  
  
  %% Startup code (Automated Section)
  % =====================================================================
  
  fprintf('  Resetting path\n');
  path(pathdef);
  AdditionalPaths = {};
  
  if ~exist(profile(cur_profile).path,'dir')
    fprintf('Cresis toolbox not found: %s\n', profile(cur_profile).path);
  else
    fprintf('  Adding cresis path: %s\n',profile(cur_profile).path);
    % Add get_filenames to the path
    addpath(fullfile(profile(cur_profile).path));
    addpath(fullfile(profile(cur_profile).path,'utility'));
    % Add each directory which is not an svn support directory to the path
    fns = get_filenames(profile(cur_profile).path,'','','',struct('type','d','recursive',1));
    if ispc
      addpath(profile(cur_profile).path);
      AdditionalPaths{end+1} = profile(cur_profile).path;
    end
    for fn_idx = 1:length(fns)
      [fn_dir fn_name] = fileparts(fns{fn_idx});
      if ~isempty(fn_name) && fn_name(1) ~= '@' && fn_name(1) ~= '+' ...
          && isempty(strfind(fns{fn_idx},'.svn')) && isempty(strfind(fns{fn_idx},'.git'))
        % Ignore .svn directories and Matlab class and package directories
        addpath(fns{fn_idx});
        AdditionalPaths{end+1} = fns{fn_idx};
      end
    end
  end
  
  if ~exist(profile(cur_profile).path_override,'dir')
    fprintf('Personal toolbox not found: %s\n', profile(cur_profile).path_override);
  else
    % Add personal path after cresis-toolbox so that it overrides cresis-toolbox
    fprintf('  Adding personal path: %s\n',profile(cur_profile).path_override);
    fns = get_filenames(profile(cur_profile).path_override,'','','',struct('type','d','recursive',1));
    addpath(profile(cur_profile).path_override);
    AdditionalPaths{end+1} = profile(cur_profile).path_override;
    for fn_idx = 1:length(fns)
      [fn_dir fn_name] = fileparts(fns{fn_idx});
      if ~isempty(fn_name) && fn_name(1) ~= '@' && fn_name(1) ~= '+' ...
          && isempty(strfind(fns{fn_idx},'.svn')) && isempty(strfind(fns{fn_idx},'.git'))
        % Ignore .svn directories and Matlab class and package directories
        addpath(fns{fn_idx});
        AdditionalPaths{end+1} = fns{fn_idx};
      end
    end
  end
  
  fprintf('  Setting global preferences in global variable gRadar\n');
  global gRadar;
  
  % .cluster: structure with default cluster scheduler arguments
  gRadar.cluster = profile(cur_profile).cluster;
  % .sched.hidden_depends_funs = cell vector of strings containing
  %   all the dependent functions that should be included when the
  %   torque_compile function is called. This list should only include
  %   functions which are passed in (e.g. "@hanning" from param spreadsheet)
  %   since all directly dependent functions will automatically be included.
  %   Second cell entry is date check level in torque_compile:
  %     0: do not check for this file (system commands)
  %     1: check this file and its dependencies (function pointers)
  %     2: check this file and its dependencies only if "fun" is not
  %        specified in call to torque_compile.m (all functions called
  %        by torque_compile)
  % =======================================================================
  % REMINDER: Run cluster_compile after making changes to this list!
  % =======================================================================
  gRadar.cluster.hidden_depend_funs = {};
  gRadar.cluster.hidden_depend_funs{end+1} = {'tomo_collate_task.m' 2};
  gRadar.cluster.hidden_depend_funs{end+1} = {'analysis_task.m' 2};
  gRadar.cluster.hidden_depend_funs{end+1} = {'analysis_combine_task.m' 2};
  gRadar.cluster.hidden_depend_funs{end+1} = {'analysis_task_stats_max.m' 2};
  gRadar.cluster.hidden_depend_funs{end+1} = {'analysis_task_stats_kx.m' 2};
  gRadar.cluster.hidden_depend_funs{end+1} = {'qlook_task.m' 2};
  gRadar.cluster.hidden_depend_funs{end+1} = {'qlook_combine_task.m' 2};
  gRadar.cluster.hidden_depend_funs{end+1} = {'sar_coord_task.m' 2};
  gRadar.cluster.hidden_depend_funs{end+1} = {'sar_task.m' 2};
  gRadar.cluster.hidden_depend_funs{end+1} = {'array_task.m' 2};
  gRadar.cluster.hidden_depend_funs{end+1} = {'array_combine_task.m' 2};
  gRadar.cluster.hidden_depend_funs{end+1} = {'nsidc_delivery_script_task.m' 2};
  gRadar.cluster.hidden_depend_funs{end+1} = {'preprocess_task.m' 2};
  gRadar.cluster.hidden_depend_funs{end+1} = {'layer_tracker_task.m' 2};
  gRadar.cluster.hidden_depend_funs{end+1} = {'layer_tracker_combine_task.m' 2};
  gRadar.cluster.hidden_depend_funs{end+1} = {'sim_doa_task.m' 2};
  gRadar.cluster.hidden_depend_funs{end+1} = {'hanning.m' 0};
  gRadar.cluster.hidden_depend_funs{end+1} = {'hamming.m' 0};
  gRadar.cluster.hidden_depend_funs{end+1} = {'blackman.m' 0};
  gRadar.cluster.hidden_depend_funs{end+1} = {'tukeywin.m' 0};
  gRadar.cluster.hidden_depend_funs{end+1} = {'tukeywin_trim.m' 1};
  gRadar.cluster.hidden_depend_funs{end+1} = {'chebwin.m' 0};
  gRadar.cluster.hidden_depend_funs{end+1} = {'kaiser.m' 0};
  gRadar.cluster.hidden_depend_funs{end+1} = {'boxcar.m' 0};
  gRadar.cluster.hidden_depend_funs{end+1} = {'butter.m' 0};
  gRadar.cluster.hidden_depend_funs{end+1} = {'array_proc_sv.m' 1};
  gRadar.cluster.hidden_depend_funs{end+1} = {'lever_arm.m' 1};
  gRadar.cluster.hidden_depend_funs{end+1} = {'doa_nonlcon.m' 1};
  gRadar.cluster.hidden_depend_funs{end+1} = {'burst_noise_corr.m' 1};
  gRadar.cluster.hidden_depend_funs{end+1} = {'burst_noise_bad_samples.m' 1};
  % =======================================================================
  % REMINDER: Run cluster_compile after making changes to this list!
  % =======================================================================

  % .path = used by the scheduler to build the file dependency path
  %   typically this is the same at .path
  gRadar.path = profile(cur_profile).path;
  % .path_override = used by the scheduler to build the file dependency
  %   path, however only files that also exist in the .path directory
  %   will be overwritten so that if a file only exists in .path_override
  %   it will not be included in the file dependency list
  gRadar.path_override = profile(cur_profile).path_override;
  % .param_path = parameter spreadsheet folder
  gRadar.param_path = profile(cur_profile).param_path;
  % .tmp_path = this is where personal temporary files will be stored (e.g.
  %   the picker should store files here)
  gRadar.tmp_path = profile(cur_profile).tmp_file_path;
  % .tmp_path = this is where global temporary files will be stored (e.g.
  %   create records, headers, etc. files should be stored here so that
  %   the process can be resumed by anyone without having to redo all
  %   the work or track down other people's temporary files)
  gRadar.ct_tmp_path = profile(cur_profile).ct_tmp_file_path;
  
  % .data_path = where the data is stored, the records and vectors files
  %   contain relative paths to the data from this base path
  gRadar.data_path = profile(cur_profile).data_path;
  % .data_support_path = where the support data is stored, the
  %   make_gps_* functions have relative paths to the data from here
  gRadar.data_support_path = profile(cur_profile).data_support_path;
  % .support_path = where the support data is stored, this includes
  %   radar configs, gps, vectors, records, frames, and GIS files
  gRadar.support_path = profile(cur_profile).support_path;
  % .out_path = where the output directories are stored (i.e. quick look,
  %   csarp, combine, pick, and post results)
  gRadar.out_path = profile(cur_profile).out_path;
  % .GIS_path = where GIS files are stored (e.g. Landsat-7 imagery)
  gRadar.gis_path = profile(cur_profile).gis_path;
  % .ct_file_lock_check: logical that determines if lock state should be
  %   checked
  if isfield(profile(cur_profile),'ct_file_lock_check')
    gRadar.ct_file_lock_check = profile(cur_profile).ct_file_lock_check;
  else
    gRadar.ct_file_lock_check = true;
  end
  % .ct_file_lock: logical that determines if lock state will be enabled
  %   when files are created
  if isfield(profile(cur_profile),'ct_file_lock')
    gRadar.ct_file_lock = profile(cur_profile).ct_file_lock;
  else
    gRadar.ct_file_lock = false;
  end
  % .slurm_jobs_path = where param structures are stored for slurm scripts
  if ~isfield(profile(cur_profile),'slurm_jobs_path')
    profile(cur_profile).slurm_jobs_path = '';
  end  
  gRadar.slurm_jobs_path = profile(cur_profile).slurm_jobs_path;  
  % .ops: structure of open polar server specific parameters
  if isfield(profile(cur_profile),'ops')
    gRadar.ops = profile(cur_profile).ops;
  end
  
  clear profile cur_profile fn_dir fn_idx fn_name fns pidx;

else
  % fprintf('Compiling code: not running addpath in the compiled code\n');
end
