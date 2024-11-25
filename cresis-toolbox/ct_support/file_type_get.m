function file_type = file_type_get(source)
% file_type = file_type_get(source)
%
% source: if a string, then it specifies a file path and the
% "file_type" field will be loaded from that file.
% if a struct, then it returns the "file_type" field from the struct
% For old file formats (including structures loaded from old files), it
% will try to determine the file type based on the fields that exist in the
% file or in the structure.
%
% file_type: string containing the file type

if ischar(source)
  % source is a filename
  file_vars = whos('-file',source);
  file_type_idx = find(strcmp('file_type',{file_vars.name}));
  if ~isempty(file_type_idx)
    % Done!
    load(source,'file_type');
    return;
  end
  
  % This is an old file with no file_type field. We determine the file type
  % now by looking at its contents:
  
  field_idx = find(strcmp('param_qlook',{file_vars.name}));
  if ~isempty(field_idx)
    file_type = 'qlook';
    return;
  end
  
  field_idx = find(strcmp('param_get_heights',{file_vars.name}));
  if ~isempty(field_idx)
    file_type = 'qlook';
    return;
  end
  
  field_idx = find(strcmp('param_array',{file_vars.name}));
  if ~isempty(field_idx)
    file_type = 'array';
    return;
  end
  
  field_idx = find(strcmp('param_combine',{file_vars.name}));
  if ~isempty(field_idx)
    file_type = 'array';
    return;
  end
  
  field_idx = find(strcmp('records',{file_vars.name}));
  if ~isempty(field_idx)
    file_type = 'param';
    return;
  end
  
  field_idx = find(strcmp('surf',{file_vars.name}));
  if ~isempty(field_idx)
    file_type = 'surf';
    return;
  end
  
  error('File type is not currently supported by file_type_get.');
  
elseif isstruct(source)
  if isfield(source,'file_type')
    % Done!
    file_type = source.file_type;
    return;
  end

  % This is an old file struct with no file_type field. We determine the
  % file type now by looking at its contents:
  
  if isfield(source,'param_qlook')
    file_type = 'qlook';
    return;
  end
  
  if isfield(source,'param_get_heights')
    file_type = 'qlook';
    return;
  end
  
  if isfield(source,'param_array')
    file_type = 'array';
    return;
  end
  
  if isfield(source,'param_combine')
    file_type = 'array';
    return;
  end
  
  if isfield(source,'records')
    file_type = 'param';
    return;
  end
  
  if isfield(source,'surf')
    file_type = 'surf';
    return;
  end
  
end