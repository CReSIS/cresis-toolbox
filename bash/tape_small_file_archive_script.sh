# small_file_archive_script.sh
# Puts all small files (<1048576 bytes) contained in the current directory
# into a tar file in the current directory. Also creates a text file with a
# listing of all the small files.

# CREATE SMALL FILE ARCHIVE SCRIPT
echo "First and only input should be the filename prefix for the tar file and is usually the radar directory concatenated with the season name folder (e.g. MCoRDS_2018_Antarctica_DC8)"
SEASON=$1
# CREATE 1 MB FILLER FILE CALLED delete_this_zero_file
dd if=/dev/zero bs=1 count=1048576 | tr '\0' '0' >delete_this_zero_file
# CREATE A TEXT FILE CONTAINING PATH TO ALL THE SMALL FILES
find ./ -type f -size -1048576c >$SEASON"_small_file_list.txt"
# CREATE AN ARCHIVE OF ALL THE SMALL FILES PLUS THE ZERO FILE WHICH ENSURES THE TAR IS >=1 MB
tar cf $SEASON"_small_file_archive.tar" delete_this_zero_file -T $SEASON"_small_file_list.txt"
# DELETE THE 1 MB FILLER FILE
rm delete_this_zero_file


