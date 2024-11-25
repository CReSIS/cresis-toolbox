function create_picking_spreadsheet(param_fn,xls_fn_dir,pick_param)
% create_picking_spreadsheet(param_fn,xls_fn_dir,pick_param)
%
% Creates picking assignment table using param spreadsheet.
% Must be run on a Windows machine with Excel.
%
% INPUT:
%  param_fn: String, absolute filepath + filename to MS Excel params spreadsheet(.xls).
%  xls_fn_dir: String, absolute output directory
%  pick_param: Structure controlling operation of this function
%   .mode: String containing either "ascii" or "excel". If ascii, the
%     function creates a list of all frames that are selected in the
%     spreadsheet.
%
% GLOBAL VARIABLES USED:
%   gRadar: struct from CReSIS startup.m
%
% OUTPUT:
%   Excel picking spreadsheet ready for upload to Google Docs.
%
% EXAMPLE:
%   param_fn = ct_filename_param('rds_param_2013_Antarctica_P3.xls');
%   xls_fn_dir = 'C:\';
%   create_picking_spreadsheet(param_fn,xls_fn_dir);
%
%   params = read_param_xls(ct_filename_param('accum_param_2019_Antarctica_TObas.xls'));
%   params = ct_set_params(params,'cmd.generic',1);
%   params = ct_set_params(params,'cmd.generic',0,'cmd.notes','do not process');
%   xls_fn_dir = '~/';
%   create_picking_spreadsheet(params,xls_fn_dir);
%
% Author: John King
%
% See also: read_param_xls.m

%% Input argument checking
global gRadar;

if ~exist('pick_param','var')
  pick_param = [];
end

if ~isfield(pick_param,'mode') || isempty(pick_param.mode)
  pick_param.mode = 'ascii';
end

%% Read in the param spreadsheet
if ischar(param_fn)
  params = read_param_xls(param_fn);
else
  params = param_fn;
end

%% Create Excel spreadsheet
output_dir = ct_output_dir(params(1).radar_name);
if strcmpi(pick_param.mode,'ascii')
  fn = fullfile(xls_fn_dir, sprintf('%s_picking_%s.txt', output_dir, params(1).season_name));
  [fid,msg] = fopen(fn,'wb');
  if fid<0
    error('Failed to open file %s\n', msg);
  end
  
elseif strcmpi(pick_param.mode,'excel')
  
  xls_fn = fullfile(xls_fn_dir, sprintf('%s_picking_%s.xls', output_dir, params(1).season_name));
  
  if exist(xls_fn,'file')
    warning('File %s already exists, overwriting', xls_fn);
    delete(xls_fn);
  end

  fprintf('Creating %s \n\n', xls_fn);
  
  % Create column header line.
  col_header      = {'Segment','NumFrames','Surface','Bottom',...
    'Owner','Notes','QC','QC_Owner'};
  xlswrite(xls_fn, col_header,  'sheet1', 'A1')

end

%% Read in segment and frame data

% Create data rows
data_row_idx = 0;
for params_idx = 1:length(params)
  param = params(params_idx);
  
  % Ignore segments with 'do no process' note.
  if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
    continue;
  end
  
  frames = frames_load(param); % Load frames into variable "frames"
  
  if strcmpi(pick_param.mode,'ascii')
    for frm = 1:length(frames.frame_idxs)
      fprintf('%s_%03d\t\t0\n', param.day_seg, frm);
      fprintf(fid,'%s_%03d\t\t0\n', param.day_seg, frm);
    end
  elseif strcmpi(pick_param.mode,'excel')
    data_row{1} = param.day_seg;
    data_row{2} = length(frames.frame_idxs);
    data_row{3} = 0;
    data_row{4} = 0;
    data_row{5} = '';
    data_row{6} = '';
    data_row{7} = 0;
    data_row{8} = '';
    data_row_idx = data_row_idx + 1;
    xlswrite(xls_fn, data_row, 'sheet1', sprintf('A%d',data_row_idx + 1));
  end
end

%% Write data to excel file
if strcmpi(pick_param.mode,'ascii')
  fclose(fid);
  fprintf('File done: %s\n', fn);
  
elseif strcmpi(pick_param.mode,'excel')
  % Create Excel_Application COM.
  Excel       = actxserver('Excel.Application');
  
  try
    % Make Excel Invisible.
    Excel.Visible = 0;
    
    % Define the workbook & sheet to operate on
    Workbook    = Excel.Workbooks.Open(xls_fn);
    sheet       = Workbook.Worksheets.Item('sheet1');
    sheet.Name = sprintf('%s_picked', param.season_name);
    
    Workbook.Worksheets.Item('Sheet2').Delete
    Workbook.Worksheets.Item('Sheet3').Delete
    
    % Activate Sheet1
    sheet.Activate();
    
    columns = {'C','D','G'};
    
    for column = columns
      range = sprintf('%s2:%s%d',column{1},column{1},data_row_idx+1);
      
      % Green when the value is 1.
      sheet.Range(range).FormatConditions.Add(1,3,'1');
      sheet.Range(range).FormatConditions.Item(1).interior.ColorIndex = 4;
      
      % Red when the value is 0.
      sheet.Range(range).FormatConditions.Add(1, 3, '0');
      sheet.Range(range).FormatConditions.Item(2).interior.ColorIndex = 3;
      
      % Yellow when the value is between .1 & .9.
      sheet.Range(range).FormatConditions.Add(1, 1, '0.001', '0.999');
      sheet.Range(range).FormatConditions.Item(3).interior.ColorIndex = 6;
    end
    
    % Auto-Fit All Columns
    Excel.ActiveSheet.Columns.AutoFit;
    
    % Make header columns bold
    sheet.Range('A1:H1').Font.Bold = 1;
    
    %% Save & Close Connection
    invoke(Workbook, 'Save');
    invoke(Excel, 'Quit');
    
    delete(Excel);
    
  catch ME
    warning(ME.getReport());
    invoke(Excel, 'Quit');
    delete(Excel);
  end
end

return;


%%
fprintf('Setting Conditional Formatting for %s \n\n', xls_fn);

% Set Range of values to manipulate.
columns     = {Alpha{1}, Alpha{5}, Alpha{9}, Alpha{13}, Alpha{14}}; % Columns A, E, I, M, N

for cond_idx = 1:length(columns)
  range = [columns{cond_idx}, num2str(2), ':',columns{cond_idx} num2str(length(Segment)+1)];
  
  % Green when the value is 1.
  sheet.Range(range).FormatConditions.Add(1,3,'1');
  sheet.Range(range).FormatConditions.Item(1).interior.ColorIndex = 4;
  
  % Red when the value is 0.
  sheet.Range(range).FormatConditions.Add(1, 3, '0');
  sheet.Range(range).FormatConditions.Item(2).interior.ColorIndex = 3;
  
  % Yellow when the value is between .1 & .9.
  sheet.Range(range).FormatConditions.Add(1, 1, '0.1', '0.9');
  sheet.Range(range).FormatConditions.Item(3).interior.ColorIndex = 6;
  
  % Blue when the value is .999
  sheet.Range(range).FormatConditions.Add(1, 3, '.9999');
  sheet.Range(range).FormatConditions.Item(4).interior.ColorIndex = 20;
end

range = [Alpha{5},num2str(length(Segment) + 6), ':', Alpha{5} ,num2str(length(Segment) + 8)];

% Green when the value is 1.
sheet.Range(range).FormatConditions.Add(1, 3, '1');
sheet.Range(range).FormatConditions.Item(1).interior.ColorIndex = 4;

% Red when the value is 0.
sheet.Range(range).FormatConditions.Add(1, 3, '0');
sheet.Range(range).FormatConditions.Item(2).interior.ColorIndex = 3;

% Yellow when the value is between .1 & .9.
sheet.Range(range).FormatConditions.Add(1, 1, '.0001', '.9999');
sheet.Range(range).FormatConditions.Item(3).interior.ColorIndex = 6;

%% Set Non-Conditionals

% Set CP, CQ & CF columns to med-gray
columns = Alpha(10:12); % Columns J:L
for summary_idx = 1:length(columns)
  range = [columns{summary_idx},num2str(2),':', columns{summary_idx}, num2str(length(Segment)+1)];
  
  % Interior Color = grey
  sheet.Range(range).Interior.ColorIndex = 48;
end

% Set summary row below table to med-gray.
columns = Alpha(1:12);  % Columns A:L
for sum_idx = 1:length(columns)
  range = [columns{sum_idx}, num2str(length(Segment)+2)];
  
  % Interior Color = grey
  sheet.Range(range).Interior.ColorIndex = 48;
end

% Set header for Completion Stats to gray.
% Set Type, Total Frames, Complete Frames & Percent Complete headers to light gray.
columns = Alpha(2:5);   % Columns B:E
for header_idx = 1:length(columns)
  range = [columns{header_idx}, num2str(length(Segment)+4)];
  
  % Interios Color = med-gray
  sheet.Range(range).Interior.ColorIndex = 16;
  
  range = [columns{header_idx}, num2str(length(Segment)+5)];
  
  % Interior Color = light gray
  sheet.Range(range).Interior.ColorIndex = 15;
end


% Set PICK, QC & FINAL to light gray.
range = [Alpha{2}, num2str(length(Segment)+6),':', Alpha{2}, num2str(length(Segment)+8)];

% Interior Color = light gray
sheet.Range(range).Interior.ColorIndex = 15;

columns = {Alpha{3:4}}; %#ok<*CCAT1> % Columns C:D
for stats_idx = 1:length(columns)
  range = [columns{stats_idx}, num2str(length(Segment)+6), ':', columns{stats_idx}, num2str(length(Segment)+8)];
  
  % Interior Color = gray
  sheet.Range(range).Interior.ColorIndex = 48;
end

%% Format Text
% Set all font sizes to 10 pt
sheet.Range('A1:N1').EntireColumn.Font.Size = 10;

% Set Header row BOLD
sheet.Range('A1').EntireRow.Font.Bold = 1;

% Center and merge "Completion Stats" header
range = ['B',num2str(length(Segment) + 4),':E', num2str(length(Segment)+ 4)];

sheet.Range(range).MergeCells = 1;
sheet.Range(range).HorizontalAlignment = -4108;

% Make "Completion Stats" header 12pt and bold
sheet.Range(range).Font.Size = 12;
sheet.Range(range).Font.Bold = 1;

% Bold 'PICK', 'QC', & 'FINAL' in "Completion Stats" table.
range = ['B', num2str(length(Segment)+6), ':B', num2str(length(Segment)+8)];
sheet.Range(range).Select;
sheet.Range(range).Font.Bold = 1;

% Auto-Fit All Columns
Excel.ActiveSheet.Columns.AutoFit;

%% Save & Close Connection
invoke(Workbook, 'Save');
invoke(Excel, 'Quit');

delete(Excel);

fprintf('%s Spreadsheet is Complete. \n\n', strcat(ss_name,'_Picking.xlsx'));

%% NOTES:
% 1) Percent-complete in stats table needs to be formatted to PERCENTAGE
% 2)    [Type, Total Frames, Complete Frames, Percent Complete] in stats table
%       need to be "text-wrapped"
% 3) First row needs to be "Frozen"
% 4) Lock summary cells.
% 5) make header for CReSIS standard format.
%
%
