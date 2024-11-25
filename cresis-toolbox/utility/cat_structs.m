function S_out = cat_structs(dim,S1,S2,cat_fields_flag)
% S_out = cat_structs(dim,S1,S2,cat_fields_flag)
%
% Concatenates two structures. Allows for dissimilar fields. Fields that do
% not exist just get a [] put in them.
%
% dim: dimension to concatenate on
% S1: first struct
% S2: second struct to be concatenated to the end of S1
%
% S_out = concatenated structure array
%
% Examples:
%
% S1 = [];
% S1.A = 1;
% S1(2).A = 3;
% S2 = [];
% S2.B = 2;
% S_out = cat_structs(2,S1,S2);
% S_out(1)
% S_out(2)
% S_out(3)
% 
% S1 = [];
% S1.A.B = 1;
% S1(2).A.B = 3;
% S2 = [];
% S2.A.C = 4;
% S2.B = 2;
% S_out = cat_structs(2,S1,S2);
% S_out(1)
% S_out(2)
% S_out(3)
% S_out(1).A
% S_out(2).A
% S_out(3).A
%
% Authors: John Paden

% Input check

if ~exist('cat_fields_flag','var')
  cat_fields_flag = false;
end

% Handle simple cases
if isempty(S2)
  S_out = S1;
  return;
end
if isempty(S1)
  S_out = S2;
  return;
end

% Setup to merge structs
S_out = S1;
S1_fields = fieldnames(S1);
S2_fields = fieldnames(S2);
S_out_fields = union(S1_fields,S2_fields);

% Add missing fields to S1
missfields = setdiff(S_out_fields,S1_fields);
for idx = 1:length(missfields)
  S1(1).(missfields{idx}) = [];
end

% Add missing fields to S2
missfields = setdiff(S_out_fields,S2_fields);
for idx = 1:length(missfields)
  S2(1).(missfields{idx}) = [];
end

if ~cat_fields_flag
  S_out = cat(dim,S1,S2);
else
  for idx = 1:length(S_out_fields)
    try
      S_out.(S_out_fields{idx}) = cat(dim,S1.(S_out_fields{idx}),S2.(S_out_fields{idx}));
    catch
      try
        S_out.(S_out_fields{idx}) = S1.(S_out_fields{idx});
      end
    end
  end
end
