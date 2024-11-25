function en = ct_generic_en(param)

if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
  en = 0;
else
  en = 1;
end
