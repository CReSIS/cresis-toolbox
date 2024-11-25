% script run_all_frames_check
%
% Script for running records check on many seasons at once.
%
% Author: John Paden
%
% See also: check_data_products, frames_check, gps_check, records_check
% run_all_frames_check, run_all_gps_check, run_all_records_check

run_all;

for param_fns_idx = 1:length(param_fns)
  param_fn = param_fns{param_fns_idx};
  param = regexp(param_fn,'(?<radar_name>\w+)_param_(?<season_name>\w+)','names');
  frames_check(param);
end
