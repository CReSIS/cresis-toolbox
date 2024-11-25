function echo_plot_param = echo_plot_profile(profile_str)
% echo_plot_param = echo_plot_profile(profile_str)
%
% Converts echo_plot profile_str string into corresponding echo_plot_param
% structure. If profile_str is a struct, then this struct is used. Either
% way, input checks are done on the structure.
%
% Inputs:
% =========================================================================
%
% echo_plot_param: A structure or string. If a string, it should contain
% the profile name (e.g. 'TWTT', 'WGS84', 'DEPTH', or 'RANGE'). If a
% struct, it should be an echo_plot echo_plot_param structure.
%
% Outputs:
% =========================================================================
%
% echo_plot_param: structure containing parameters for echo_plot.m. If
% profile_str is a string, then this struct contains the default values for
% the profile selected. See "Input Checks" section for details. Structure also
% contains elevation_compensation "param" input fields. See that function
% for details on those fields.
%
% Examples:
%   echo_plot_param = echo_plot_profile('DEPTH');
%
% Author: John Paden, Dhagash Kapadia
%
% See also: echo_plot.m, echo_plot_profile.m, elevation_compensation.m,
% load_L1B.m, run_echo_plot.m
  
%% echo_plot_param profile fill
% =========================================================================
if isempty(profile_str)
  profile_str = 'TWTT';
end
if ischar(profile_str)
  
  echo_plot_param = [];
  
  if strcmpi(profile_str, 'DEPTH')
    echo_plot_param.mode_y_axis = 'DEPTH';
    
  elseif strcmpi(profile_str, 'RANGE')
    echo_plot_param.mode_y_axis = 'range';
    
  elseif strcmpi(profile_str, 'NONE')
    echo_plot_param.mode_y_axis = 'twtt';
    echo_plot_param.plot_en = false;
    
  elseif strcmpi(profile_str, 'TWTT')
    echo_plot_param.mode_y_axis = 'twtt';
    
  elseif strcmpi(profile_str, 'WGS84')
    echo_plot_param.mode_y_axis = 'wgs84';
  end
  
elseif ~isstruct(profile_str)
  error('echo_plot_param input must be a string or structure.');
  
else
  % Must be a struct which we copy into echo_plot_param
  echo_plot_param = profile_str;
end

%% Input checks: echo_plot specific
% =========================================================================
% elevation_compensation.m specific parameters (input "param") are stored
% in this strcuture, but that function will do input checks on those
% parameters

% h_fig: figure handle to use in echo_plot
if ~isfield(echo_plot_param, 'h_fig') || isempty(echo_plot_param.h_fig)
  echo_plot_param.h_fig = [];
end

% .mode_x_axis: String specifying the x-axis type. The options are
% 'ALONG_TRACK', 'GPS_TIME', or 'RANGE_LINE'.
if ~isfield(echo_plot_param, 'mode_x_axis') || isempty(echo_plot_param.mode_x_axis)
  echo_plot_param.mode_x_axis = 'RANGE_LINE';
end

% .mode_y_axis: String specifying the y-axis type. The options are 'DEPTH',
% 'RANGE', 'TWTT', or 'WGS84'.
if ~isfield(echo_plot_param, 'mode_y_axis') || isempty(echo_plot_param.mode_y_axis)
  echo_plot_param.mode_y_axis = 'TWTT';
end

% plot_en: logical to enable plotting or not, default is true. If false,
% echo_plot just loads the variables and prepares them for plotting.
if ~isfield(echo_plot_param, 'plot_en') || isempty(echo_plot_param.plot_en)
  echo_plot_param.plot_en = true;
end
