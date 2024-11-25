function s = ct_rmfield(s,rm_field_names)

s = rmfield(s,intersect(fieldnames(s),rm_field_names));
