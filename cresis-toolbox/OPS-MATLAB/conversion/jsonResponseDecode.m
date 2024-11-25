function [status,outData] = jsonResponseDecode(jsonResponse)
% [status,outData] = jsonResponseDecode(jsonResponse))
%
% (1) Decodes JSON string to MATLAB structure
% (2) Checks and appropritly handles error/warning status
%
% Input:
%   jsonResponse: json string from server
%
% Output:
%   an error may be thrown, OR
%
%   decoded_json: a matlab structure decoded from json_response
%
% Author: Kyle W. Purdon

if isempty(jsonResponse)
  
  error('NO DATA RETURNED FROM SERVER');
  
else
  
  try
    
    % CONVERT JSON TO MATLAB (FROMJSON VERSION)
    response = fromjson(jsonResponse);
    status = response.status;
    data = response.data;
    
  catch ME
    
    % IF FROMJSON() FAILS REVERT TO LOADJSON()
    warning('fromjson() failed, loadjson() will be used.')
    if (regexp(jsonResponse,'[\{\}\]\[]','once'))
      response = loadjson(jsonResponse);
    else
      error('No json string returned.');
    end
    status = response.status;
    data = response.data;
    
    % FORMAT LOADJSON OUTPUT TO MATCH FROMJSON OUTPUT
    if status == 1 && ~isempty(data) && isstruct(data)
      dataFns = fieldnames(data);
      for fidx = 1:length(dataFns)
        data.(dataFns{fidx}) = data.(dataFns{fidx}).';
      end
    end
    
  end
  
  if status == 0
    
    outData = data;
    error(data); % THROW ERROR ON FAILURE
    return
    
  elseif status == 2
    
    outData = data;
    warning(data); % THROW WARNING ON ISSUE
    return;
    
  else
    
    outData = data;
    
  end
  
end
end