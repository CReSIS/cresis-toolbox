function merge(param,param_override)
% merge(param,param_override)
%
% 1. Loads coincident LIDAR data if it exists
% 2. Loads DTU sea surface DEM and arctic/antarctica land DEM, combines
%    these two DEMS taking land DEM over sea surface DEM.
% 3. Combines LIDAR data and DEM data, taking LIDAR data over DEM data.
%    Uses elevation to interpolate where data are not available.
% 4. Estimates Tadc_adjust or t_ref error by comparing radar surface from
%    the specified layer source and the LIDAR/DEM combination.
%    * The error is calculated as the correction that needs to be applied. In
%      other words if the radar surface twtt is too large, then the error is
%      reported as a negative number.
%    * This error should be added to param.radar.wfs.Tadc_adjust for pulsed systems.
%    * This error should be added to param.radar.wfs.t_ref for deramp systems.
% 5. Estimates GPS offset by comparing radar surface and LIDAR/DEM. This offset
%    should be added to param.records.gps.time_offset.
% 6. For deramp systems, uses the LIDAR/DEM data to determine the Nyquist
%    zone and sets the records.settings.nyquist_zone based on this.
%    The second decimal mask in frames.proc_mode is also set to one for
%    frames that will be outside max_nyquist_zone.
%
% See run_check_surface.m for how to run.
%
% cat /N/dcwan/projects/cresis/output/ct_tmp/check_surface/snow/2017_Greenland_P3/*.txt
%
%
% Author: John Paden

% =====================================================================
%% General Setup
% =====================================================================
param = merge_structs(param, param_override);

fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', mfilename, param.day_seg, datestr(now));
fprintf('=====================================================================\n');

% =====================================================================
%% Input checks
% =====================================================================

%% Input Checks: layerdata_merge
if ~isfield(param,'layerdata_merge') || isempty(param.layerdata_merge)
  param.layerdata_merge = [];
end

if ~isfield(param.layerdata_merge,'new') || isempty(param.layerdata_merge.new)
  param.layerdata_merge.new = '';
end

if ~isfield(param.layerdata_merge,'old') || isempty(param.layerdata_merge.old)
  param.layerdata_merge.old = 'layer';
end

% =====================================================================
%% layerdata object
% =====================================================================

% Create the layerdata object for this segment
layers = layerdata(param,param.layerdata_merge.old);

% =====================================================================
%% GUI
% =====================================================================

% Create or open the GUI
layers.create_ui();

%% Load layers
% =========================================================================
layers.gui_layers{end+1} = layerdata(layers.param,param.layerdata_merge.new);
layers.gui_layers{end}.check_layer_organizer();
layers.gui_layers{end}.check_all_frames();

%% Set auto-merge settings 
% =========================================================================


%% Update user interface
% =========================================================================
layers.update_ui();
