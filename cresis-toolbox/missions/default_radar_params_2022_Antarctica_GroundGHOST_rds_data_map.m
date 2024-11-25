function data_map = default_radar_params_2022_Antarctica_GroundGHOST_rds_data_map(day_seg)
% data_map = default_radar_params_2022_Antarctica_GroundGHOST_rds_data_map(day_seg)
%
% Used to create param.records.data_map.
%
% Support function for default_radar_params_2022_Antarctica_GroundGHOST_rds
% and in general for the dataset corresponding to
%   season: 2022_Antarctica_BaslerMKB
%   radar: rds
%
% Author: John Paden
%
% See also: default_radar_params_2022_Antarctica_GroundGHOST_rds

data_map = {...
    [0 0 0 1 1
    1 2 0 2 1
    2 4 0 3 1
    3 6 0 4 1
    4 0 1 1 2
    5 2 1 2 2
    6 4 1 3 2
    7 6 1 4 2
    8 0 2 1 3
    9 2 2 2 3
    10 4 2 3 3
    11 6 2 4 3
    12 0 3 1 4
    13 2 3 2 4
    14 4 3 3 4
    15 6 3 4 4], ...
    [0 0 0 1 5
    1 2 0 2 5
    2 4 0 3 5
    3 6 0 4 5
    4 0 1 1 6
    5 2 1 2 6
    6 4 1 3 6
    7 6 1 4 6
    8 0 2 1 7
    9 2 2 2 7
    10 4 2 3 7
    11 6 2 4 7
    12 0 3 1 8
    13 2 3 2 8
    14 4 3 3 8
    15 6 3 4 8]};
