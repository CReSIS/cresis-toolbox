function robust_rmdir(fn_dir)

status = -1;
cluster_attempts = 0;
while status ~= 0
  try
    if exist(fn_dir,'dir')
      rmdir(fn_dir,'s');
    end
    status = 0;
  catch ME
    warning('rmdir failed');
    cluster_attempts = cluster_attempts + 1;
    pause(3);
    if cluster_attempts > 2
      warning('rmdir failed repeatedly. There is probably a permission or file system issue. The directory may need to be moved manually to prevent problems with the processing. Usually the directory can be deleted at some later time once the file system issues are resolved. The directory is:\n  %s', fn_dir);
      status = 0;
    end
  end
end
