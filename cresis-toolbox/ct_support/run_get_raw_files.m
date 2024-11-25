% script run_get_raw_files
%
% Script for running get_raw_files.
%
% Creates an output file containing the tape locations of
% all the files comprising the given frames.
%
% Authors: Reece Mathews
%
% See also: get_raw_files.m

%% USER INPUT

seasons = {'accum_param_2010_Greenland_P3', 'accum_param_2011_Greenland_P3', 'accum_param_2012_Greenland_P3', 'accum_param_2013_Greenland_P3', 'accum_param_2014_Greenland_P3', 'accum_param_2017_Greenland_P3', 'accum_param_2018_Greenland_P3'};
flight_lines = {
    {'20100508_01_112',  '20100508_01_113', '20100508_01_114', '20100508_01_115', '20100508_01_116',  '20100508_01_117', '20100508_01_118'}, ...
    {'20110419_01_006', '20110419_01_007', '20110419_01_008', '20110419_01_009', '20110419_01_010', '20110419_01_011', '20110419_01_012'}, ...
    {'20120418_01_127', '20120418_01_128', '20120418_01_129', '20120418_01_130', '20120418_01_131', '20120418_01_132'}, ...
    {'20130405_01_163', '20130405_01_164', '20130405_01_165', '20130405_01_166', '20130405_01_167', '20130405_01_168', '20130405_01_169'}, ...
    {'20140424_01_001', '20140424_01_002', '20140424_01_003', '20140424_01_004', '20140424_01_005', '20140424_01_005'}, ...
    {'20170422_01_167', '20170422_01_168', '20170422_01_169', '20170422_01_170', '20170422_01_168', '20170422_01_172'}, ...
    {'20180427_01_168', '20180427_01_169', '20180427_01_170', '20180427_01_171', '20180427_01_172', '20180427_01_173'}, ...
};

tape_list_path = '~/RAS_files_tapes_table.txt';
output_file = 'tapes.txt';

%% AUTOMATED PART

% Produce tape_list sorted by filenames
tape_list = readmatrix(tape_list_path, 'Delimiter', ' ', 'OutputType', 'string');
[~, file, ext] = fileparts(tape_list(:, 2));
tape_list = [tape_list file + ext];
tape_list = sortrows(tape_list, 3);

% Map directories to the corresponding small file archives
small_file_archives = string();
for file_idx = 1:size(tape_list, 1)
    filepath = tape_list{file_idx, 2};
    tapes = tape_list(file_idx, 1);
    if endsWith(filepath, "small_file_archive.tar")
        [parent, file_name, ext] = fileparts(filepath);
        file_name = [file_name ext];
        archive_idx = size(small_file_archives, 1) + 1;
        small_file_archives(archive_idx, 1) = tapes;
        small_file_archives(archive_idx, 2) = convertCharsToStrings(parent);
        small_file_archives(archive_idx, 3) = convertCharsToStrings(file_name);
    end
end
small_file_archives = sortrows(small_file_archives, 2);


output_fid = fopen(output_file,'w');

for season_idx=1:length(seasons)
    season_name = ct_filename_param(seasons{season_idx});
    frame_idxs = flight_lines{season_idx};

    [load_info,gps_time,recs] = get_raw_files(season_name, frame_idxs, {}, {}, {}, {}, tape_list, small_file_archives);

    fprintf(output_fid, '%s\n', seasons{season_idx});
    for file_list=1:length(load_info.filenames)
        fprintf(output_fid, 'Filelist: %d\n', file_list);
        fprintf(output_fid, 'tapes filename stored_filename\n');
        for file_idx=1:length(load_info.filenames{file_list})
          fprintf(output_fid, '%s %s %s\n', load_info.tapes{file_list}{file_idx}, load_info.filenames{file_list}{file_idx}, load_info.stored_filenames{file_list}{file_idx});
        end
    end
    fprintf(output_fid, '\n');
end

fclose(output_fid);