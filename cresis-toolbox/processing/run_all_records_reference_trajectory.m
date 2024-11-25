% script run_all_records_reference_trajectory
%
% Script for running records_reference_trajectory on many seasons at once.
%
% Author: John Paden
%
% See also: records_reference_trajectory.m,
% records_reference_trajectory_load.m, run_records_reference_trajectory.m,
% run_all_records_reference_trajectory.m

%% User Setup
% =====================================================================

param_override = [];

param_override.records_reference_trajectory.force_update = false;

run_all;

%% Automated Section
% =====================================================================

% Merge gRadar into param_override
global gRadar;
if exist('param_override','var')
  param_override = merge_structs(gRadar,param_override);
else
  param_override = gRadar;
end

%% Seasons
for param_fns_idx = 1:length(param_fns)
  %% Seasons: Load each season
  param_fn = ct_filename_param(param_fns{param_fns_idx});
  params = read_param_xls(param_fn);
  
  if 1
    % Select all segments
    params = ct_set_params(params,'cmd.generic',1);
    params = ct_set_params(params,'cmd.generic',0,'cmd.notes','do not process');
  else
    % Debug: Run a specific segment
    params = ct_set_params(params,'cmd.generic',0);
    params = ct_set_params(params,'cmd.generic',1,'day_seg','20120330_04');
  end
  
  %% Seasons: Segments
  for param_idx = 1:length(params)
    param = params(param_idx);
    if isfield(param.cmd,'generic') && ~iscell(param.cmd.generic) && ~ischar(param.cmd.generic) && param.cmd.generic
      %% Seasons: Segments: Input Checks
      % =====================================================================
      
      param = merge_structs(param, param_override);
      
      if ~isfield(param,'records_reference_trajectory') || isempty(param.records_reference_trajectory)
        param.records_reference_trajectory = [];
      end
      
      if ~isfield(param.records_reference_trajectory,'force_update') || isempty(param.records_reference_trajectory.force_update)
        param.records_reference_trajectory.force_update = true;
      end
      
      %% Seasons: Segments: Decide to create ref trajectory
      % Check for the existence of the reference trajectory file
      ref_fn_dir = ct_filename_out(param,'reference_trajectory','',1);
      ref_fn = fullfile(ref_fn_dir,sprintf('ref_%s.mat', param.day_seg));
      
      if param.records_reference_trajectory.force_update || ~exist(ref_fn,'file')
        %% Seasons: Segments: Create new reference trajectory
        records_reference_trajectory(param,[]);
        
      else
        %% Seasons: Segments: Perform debug operations
        
        if 1
          fprintf('Reference_trajectory_up_to_date\t%s\t%s\n', ref_fn, datestr(now,'yyyymmdd_HHMMSS'));
        elseif 0
          % DEBUG: Ensures lever_arm information in file
          mat_vars = whos('-file',ref_fn);
          if any(strcmp({mat_vars.name},'lever_arm_fh'))
            fprintf('Reference_trajectory_up_to_date\t%s\t%s\n', ref_fn, datestr(now,'yyyymmdd_HHMMSS'));
          else
            fprintf('Updating reference trajectory\t%s\t%s\n', ref_fn, datestr(now,'yyyymmdd_HHMMSS'));
            fprintf('  Loading_records\t%s\n', datestr(now,'yyyymmdd_HHMMSS'));
            records = records_load(param,'gps_source');
            
            trajectory_param = struct('gps_source',records.gps_source, ...
              'season_name',param.season_name,'radar_name',param.radar_name,'rx_path', 0, ...
              'tx_weights', [], 'lever_arm_fh', param.radar.lever_arm_fh);
            
            [lever_arm_val] = param.radar.lever_arm_fh(trajectory_param, [], 0);
            
            records.lever_arm_val = lever_arm_val;
            records.lever_arm_fh = param.radar.lever_arm_fh;
            fprintf('  Saving_updated_reference_trajectory\t%s\n', datestr(now,'yyyymmdd_HHMMSS'));
            ct_save(ref_fn,'-append','-struct','records','lever_arm_val','lever_arm_fh');
          end
        end
      end
    end
  end
end
