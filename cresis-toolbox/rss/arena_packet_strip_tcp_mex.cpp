// Compile with mex -v -largeArrayDims arena_packet_strip_tcp_mex.cpp
//   -v: verbose
//   -largeArrayDims: required for 64 bit
//   Note: Matlab automatically deallocates memory from mx*alloc
//   Note: Usually you need to cd into the directory containing the .cpp file before compiling
//
// Reads TCP/IP datastream Remote Sensing Solutions Arena ADC/DAQ files.
// Data record byte offset and headers are extracted and returned.
//
// Assumptions:
// 1. Files are <2^31 bytes so the 32 bit integer can be used for record offsets
//
// Loading steps:
// 1. Search for radar sync markers and extract record byte offsets and
//    timing header fields into hdr
// 2. Return hdr which contains file locations for markers and timing header fields
// 3. Return state information for the next call to arena_packet_strip_tcp_mex
//
// Run with no arguments to see syntax.
//
// Author: John Paden

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <algorithm>
#include "mat.h"
#include "mex.h"

const ptrdiff_t ALLOC_INCREMENT = 128;

/*
 * usage of MEX-file
 */
void
printUsage(int line_number)
{
  mexPrintf("Failed arena_packet_strip_mex on line %d\n", line_number);
  mexPrintf("[hdr,last_bytes_len,num_expected,pkt_counter] \n");
  mexPrintf("   = %s(fn,out_fn,last_bytes,last_bytes_len,num_expected,\n", mexFunctionName());
  mexPrintf("        pkt_counter,min_num_expected,max_num_expected,default_num_expected,\n");
  mexPrintf("        num_header_fields,length_field_offset);\n");
  mexPrintf("\n");
  mexPrintf(" fn: char containing input filename\n");
  mexPrintf(" out_fn: char NOT USED\n");
  mexPrintf(" last_bytes: uint8 vector (MUST BE PREALLOCATED TO BE num_header_fields*8)\n");
  mexPrintf(" last_bytes_len: int32 containing length of last_bytes, set to -1 on first call\n");
  mexPrintf(" num_expected: int32 containing number of expected bytes before the next sync,\n");
  mexPrintf("   -1 means unknown/unlocked and searching for frame sync, set to -1 on first call\n");
  mexPrintf(" pkt_counter: int32 NOT USED, set to -1 on first call\n");
  mexPrintf(" min_num_expected: minimum record size in bytes. Set to avoid bad header length field causing large data loss.\n");
  mexPrintf(" max_num_expected: maximum record size in bytes. Set to avoid bad header length field causing large data loss.\n");
  mexPrintf(" default_num_expected: default record size in bytes, used when min/max record size is violated\n");
  mexPrintf("   Usually set to min_num_expected.\n");
  mexPrintf(" num_header_fields: int32 containing the number of 8 byte blocks in the header\n");
  mexPrintf("   Header must include the record length field to guarantee files are ready properly.\n");
  mexPrintf(" length_field_offset: int32 containing byte offset of length field from sync\n");
  mexPrintf("\n");
  mexPrintf(" hdr: N by Nx uint64 matrix containing header fields for each record. First 4 bytes of header\n");
  mexPrintf("   sync field is overwritten with the offset to the record in the output file.\n");
  mexPrintf(" last_bytes_len: int32 containing length of valid data stored in last_bytes\n");
  mexPrintf(" num_expected: int32 containing number of expected bytes before the next sync, -1 means unlocked and searching for frame sync\n");
  mexPrintf(" pkt_counter: int32 NOT USED\n");
  mexPrintf("\n");
  mexPrintf(" last_bytes is modified in place\n");
  mexPrintf("\n");
  mexPrintf("When loading a sequence of files, the files should be loaded in the order\n");
  mexPrintf("collected. The first call should have last_bytes_len, num_expected, and\n");
  mexPrintf("pkt_counter all set to -1. Subsequent calls should use the returned values\n");
  mexPrintf("of these fields.\n");
  mexPrintf("\n");
  mexPrintf("Example:\n");
  mexPrintf(" See run_arena_packet_strip.m\n");
}

void
mexFunction( int nlhs,
             mxArray *plhs[],
             int nrhs,
             const mxArray *prhs[]
           )
{
  char *filename;
  ptrdiff_t buffersize;

  if (nlhs!=4) {
    printUsage(__LINE__);
    return;
  }

  /*
   * error checking for input arguments
   */
  if (nrhs!=11) {
    printUsage(__LINE__);
    return;
  }

  if ( !mxIsChar(prhs[0]) )
  {
    mexPrintf("%d: First argument must be input filename\n", __LINE__);
    printUsage(__LINE__);
    return;
  }
  if ( !mxIsChar(prhs[1]) )
  {
    mexPrintf("%d: Second argument must be output filename\n", __LINE__);
    printUsage(__LINE__);
    return;
  }
  
  if ( !mxIsClass(prhs[2], "uint8") )
  {
    mexPrintf("%d: Third argument must be a preallocated uint8 vector\n", __LINE__);
    printUsage(__LINE__);
    return;
  }
  
  for (int input_idx = 3; input_idx <= 10; input_idx++) 
  {
    if ( !mxIsClass(prhs[input_idx], "int32") 
            || mxGetM(prhs[input_idx]) != 1 
            || mxGetN(prhs[input_idx]) != 1)
    {
      mexPrintf("%d: Argument %d must be int32 scalar\n", __LINE__,input_idx+1);
      printUsage(__LINE__);
      return;
    }
  }
  
  // Declare inputs
  char *last_bytes = (char*)mxGetPr(prhs[2]);
  int *last_bytes_len = (int*)mxGetPr(prhs[3]);
  int *num_expected = (int*)mxGetPr(prhs[4]);
  int *pkt_counter = (int*)mxGetPr(prhs[5]);
  int *min_num_expected = (int*)mxGetPr(prhs[6]);
  int *max_num_expected = (int*)mxGetPr(prhs[7]);
  int *default_num_expected = (int*)mxGetPr(prhs[8]);
  int *num_header_fields = (int*)mxGetPr(prhs[9]);
  int *length_field_offset = (int*)mxGetPr(prhs[10]);
  
  ptrdiff_t header_size = *num_header_fields * 8;
  
  // Create variable outputs (allocating the memory later)
  plhs[0]=mxCreateNumericMatrix(0,0,mxUINT64_CLASS,mxREAL);
  plhs[1]=mxCreateNumericMatrix(1,1,mxINT32_CLASS,mxREAL);
  plhs[2]=mxCreateNumericMatrix(1,1,mxINT32_CLASS,mxREAL);
  plhs[3]=mxCreateNumericMatrix(1,1,mxINT32_CLASS,mxREAL);

  /*
   * get filename to read from
   */
  buffersize=mxGetM(prhs[0])*mxGetN(prhs[0])+1;
  filename=(char*)mxCalloc(buffersize,sizeof(char));
  if (filename==NULL)
  {
    mexPrintf("%d: Memory allocation failure\n", __LINE__);
    return;
  }
  mxGetString(prhs[0],filename,buffersize);

  /*
   * read in data file
   */
  FILE *fptr;
  size_t file_size;
  char *data;
  
  fptr = fopen(filename,"rb"); // "b" required for windows to avoid \r issues
  mxFree(filename);
  if (fptr == 0)
  {
    mexPrintf("%d: Input file failed to open\n", __LINE__);
    return;
  }

  fseek(fptr, 0, SEEK_END);
  file_size = ftell(fptr);
  fseek(fptr, 0, SEEK_SET);
  
  data = (char *)mxMalloc(file_size);
  if (data==NULL)
  {
    mexPrintf("%d: Memory allocation failure\n", __LINE__);
    return;
  }
  fread(data, 1, file_size, fptr);

  fclose(fptr);
  
  /*
   * Preallocate hdr array:
   *   This is dynamically reallocated as required during parsing.
   */
  char *hdr;
  ptrdiff_t num_hdr = 0;
  ptrdiff_t alloc_hdr = ALLOC_INCREMENT;
  hdr = (char *)mxMalloc(header_size * alloc_hdr);
  if (hdr==NULL)
  {
    mexPrintf("%d: Memory allocation failure\n", __LINE__);
    return;
  }

  /*
   * Parse data and write out packets into header
   */
  
  // Setup for parsing
  int num_expected_original = -1; // Just for debugging
  int last_record_offset = -1; // Just for debugging
  int out_offset = 0; // Offset in the output file
  
  // ======================================================================
  // Special case for when header started in previous file
  // ======================================================================
  // If last_bytes_len > 0, then a sync has already been found in the
  // previous file (could be from the previous file) and the rest of
  // the header should be right at the start of this file.
  if (*last_bytes_len > 0)
  {
    // 1. Copy new header to hdr
    if (num_hdr >= alloc_hdr)
    {
      alloc_hdr += ALLOC_INCREMENT;
      char *hdr_tmp;
      hdr_tmp = (char *)mxRealloc(hdr, header_size * alloc_hdr);
      if (hdr_tmp==NULL)
      {
        mexPrintf("%d: Memory allocation failure\n", __LINE__);
        return;
      }
      hdr = hdr_tmp;
    }
    unsigned int hdr_type = (*((unsigned int *)(hdr+8))) & 0x7FFFFFFF;
    memcpy(hdr+num_hdr*header_size,last_bytes,*last_bytes_len);
    memcpy(hdr+num_hdr*header_size+*last_bytes_len,data,header_size-*last_bytes_len);
    //mexPrintf("%d: %lld %d 0x%016llx\n", __LINE__, idx, num_hdr+1, ((unsigned long long int *)(hdr+num_hdr*header_size))[0]);
    // 2. Write output file offset for this record into hdr (overwriting the first 32 bits of the current header)
    //    offset can be negative and this means that the record starts in the previous file and the offset is measured from the end of the file
    ((unsigned int *)(hdr+num_hdr*header_size))[0] = -*last_bytes_len;
    num_hdr++;
    // 3a. Check length_field_offset
    ptrdiff_t radar_header_length_offset = 12-*last_bytes_len; // Offset of radar header length field from start
    int expected_length_field_offset;
    if (radar_header_length_offset < 0)
    {
      // Profile data format and length fields were in the last bytes from the previous file
      expected_length_field_offset = 20+(*(int *)(last_bytes+12));
    }
    else
    {
      // Profile data format and length fields are in this file
      expected_length_field_offset = 20+(*(int *)(data+radar_header_length_offset));
    }
    if (*length_field_offset != expected_length_field_offset)
    {
      mexPrintf("%d: length_field_offset may be wrong:\n  length_field_offset=%d, expected_length_field_offset=%d\n", __LINE__, *length_field_offset, expected_length_field_offset); // PADEN
    }
    // 3b. Determine number of bytes expected in this record
    ptrdiff_t data_length_offset = *length_field_offset-*last_bytes_len;
    *last_bytes_len = 0;
    int profile_data_format;
    if (data_length_offset < 0)
    {
      // Profile data format and length fields were in the last bytes from the previous file
      profile_data_format = (*(int *)(last_bytes+*length_field_offset-4));
      *num_expected = (*(int *)(last_bytes+*length_field_offset));
      data_length_offset = 0;
    }
    else
    {
      // Profile data format and length fields are in this file
      profile_data_format = (*(int *)(data+data_length_offset-4));
      *num_expected = (*(int *)(data+data_length_offset));
      data_length_offset += 4;
    }
    num_expected_original = *num_expected;
    //mexPrintf("%d: %d\n", __LINE__, *num_expected);
    int num_expected_bins = *num_expected;
    mexPrintf("%d: %x\n", __LINE__, profile_data_format);
    switch (profile_data_format)
    {
      case 0x00000000:
        // num_expected is in units of bytes
        // num_expected_bins needs to be adjusted for 16 bit range bins
        //  >>1 = /2, 2 byte samples
        num_expected_bins = num_expected_bins >> 1;
        break;
      case 0x00010000:
        // num_expected is in units of bytes
        // num_expected_bins needs to be adjusted for 16 bit IQ range bins
        //  >>2 = /4, 4 byte samples
        num_expected_bins = num_expected_bins >> 2;
        //*num_expected = *num_expected >> 1; // These three lines replaced the above line for temporary hack;
        //*num_expected = *num_expected - 1536*4; // con't from previous line.
        //num_expected_bins = num_expected_bins >> 3; // con't from previous line.
        break;
      case 0x00020000:
      case 0x00030000:
        // num_expected is in units of samples, needs to be in units of bytes
        // num_expected_bins is in units of samples, no adjustment needed
        //   <<3 = *8, 2 IQ channels, 4 byte samples or 2*4 = 8
        if (hdr_type==45) {
          // GHOST radar header
          *num_expected = *num_expected << 3;
        } else {
          num_expected_bins = num_expected_bins >> 3;
        }
        break;
    }
    if (num_expected_bins < *min_num_expected || num_expected_bins > *max_num_expected)
    {
      mexPrintf("%d: %d Bad Record Length %d outside of specified min-max range of %d to %d.\n", __LINE__, ((unsigned int *)(hdr+num_hdr*header_size))[0], num_expected_bins, *min_num_expected, *max_num_expected);
      *num_expected = *default_num_expected;
    }
    *num_expected = *num_expected + *length_field_offset + 4- *last_bytes_len;
  }
  
  // ======================================================================
  // Determine the file offset to start searching
  ptrdiff_t idx;
  if (*num_expected != -1)
  {
    // Start searching at the point in the file where we think the next
    // record should be (this location is based on the header contents
    // from the previous record from the previous file)
    idx = *num_expected;
    *num_expected = 0;
  }
  else
  {
    // Start searching at the start of the file since num_expected == -1
    // (indicating this is the first file in the segment).
    idx = 0;
  }
  
  // ======================================================================
  // Search loop that keeps looking for syncs until the end of the file.
  // Extracts the header at each sync.
  // ======================================================================
  while (idx < file_size)
  {
    // Search for sync (if sync locked, it should be the first uint64)
    const long long c_sync = 0x7F80000080000000;
    if (((unsigned long long *)(data+idx))[0] == c_sync)
    {
      if (*num_expected == -1)
      {
        mexPrintf("%d: Sync Found At %d\n",
                __LINE__, idx);
      }
      last_record_offset = idx; // Just for debugging
      // Found sync
      if (idx + header_size > file_size)
      {
        // Header does not fit in the remaining bytes of this file
        // 1. Fill last_bytes
        memcpy(last_bytes,(void*)(data+idx),file_size-idx);
        *last_bytes_len = file_size-idx;
        // 2. Skip to end
        // Uncomment next line for debugging
        //mexPrintf("%d: Sync Found At %d and is split across files.\n", __LINE__, idx);
        break;
      }
      else
      {
        // Header is complete
        // 1. Copy header to hdr
        if (num_hdr >= alloc_hdr)
        {
          alloc_hdr += ALLOC_INCREMENT;
          char *hdr_tmp;
          hdr_tmp = (char *)mxRealloc(hdr, header_size * alloc_hdr);
          if (hdr_tmp==NULL)
          {
            mexPrintf("%d: Memory allocation failure\n", __LINE__);
            return;
          }
          hdr = hdr_tmp;
        }
        unsigned int hdr_type = (*((unsigned int *)(data+idx+8))) & 0x7FFFFFFF;

        memcpy(hdr+num_hdr*header_size,(void*)(data+idx),header_size);
        // Uncomment next line for debugging
        //mexPrintf("%d: %lld %d 0x%016llx\n", __LINE__, idx, num_hdr+1, ((unsigned long long int *)(hdr+num_hdr*header_size))[0]);
        // 2. Write output file offset into header (overwriting the first 32 bits of the header)
        ((unsigned int *)(hdr+num_hdr*header_size))[0] = idx;
        num_hdr++;
        // 3a. Check length_field_offset
        int expected_length_field_offset;
        // 12 is offset of radar header length field from start
        // 20+HEADER_LENGTH_FIELD is the byte offset to the payload length
        expected_length_field_offset = 20+(*(int *)(data + idx + 12));
        if (*length_field_offset != expected_length_field_offset)
        {
          mexPrintf("%d: length_field_offset may be wrong:\n  length_field_offset=%d, expected_length_field_offset=%d\n", __LINE__, *length_field_offset, expected_length_field_offset); // PADEN
        }
        // 3b. Determine payload length (number of bytes expected in this record)
        idx += *length_field_offset;
        *last_bytes_len = 0;
        int profile_data_format;
        profile_data_format = (*(int *)(data + idx - 4));
        *num_expected = (*(int *)(data + idx));
        num_expected_original = *num_expected;
        int num_expected_bins = *num_expected;
        //mexPrintf("%d: %x\n", __LINE__, profile_data_format);
        switch (profile_data_format)
        {
          case 0x00000000:
            // num_expected is in units of bytes
            // num_expected_bins needs to be adjusted for 16 bit range bins
            //  >>1 = /2, 2 byte samples
            num_expected_bins = num_expected_bins >> 1;
            break;
          case 0x00010000:
            // num_expected is in units of bytes
            // num_expected_bins needs to be adjusted for 16 bit IQ range bins
            //  >>2 = /4, 4 byte samples
            num_expected_bins = num_expected_bins >> 2;
            //*num_expected = *num_expected >> 1; // These three lines replaced the above line for temporary hack;
            //*num_expected = *num_expected - 1536*4; // con't from previous line.
            //num_expected_bins = num_expected_bins >> 3; // con't from previous line.
            break;
          case 0x00020000:
          case 0x00030000:
            // num_expected is in units of samples, needs to be in units of bytes
            // num_expected_bins is in units of samples, no adjustment needed
            //   <<3 = *8, 2 IQ channels, 4 byte samples or 2*4 = 8
            if (hdr_type==45) {
              // GHOST radar header
              *num_expected = *num_expected << 3;
            } else {
              num_expected_bins = num_expected_bins >> 3;
            }
            break;
        }
        idx += 4 + *num_expected; // Skip to the end of the record
        // Uncomment next line for debugging
        //mexPrintf("%d: expect %d bytes, new record expected at %d of %d bytes\n", __LINE__, *num_expected, idx, file_size);
        if (num_expected_bins < *min_num_expected || num_expected_bins > *max_num_expected)
        {
          mexPrintf("%d: %d Bad Record Length %d outside of specified min-max range of %d to %d.\n", __LINE__, ((unsigned int *)(hdr+num_hdr*header_size))[0], num_expected_bins, *min_num_expected, *max_num_expected);
          *num_expected = *default_num_expected;
        }
      }
    }
    else
    {
      if (*num_expected != -1)
      {
        // Since num_expected != -1, we were locked and have now become unlocked
        mexPrintf("%d: Sync Lost LastSync(%d) ExpectedSync(%d) LastRecordSize(%d)\n",
                __LINE__, last_record_offset, idx, num_expected_original);
        // Uncomment next seven lines for debugging
        mexPrintf("Bytes around the expected location of the sync:\n");
        for (ptrdiff_t debug_idx=0; debug_idx<std::min((ptrdiff_t)16,idx); debug_idx++)
        {
          mexPrintf("  %d 0x%016llx\n", debug_idx-8, ((unsigned long long *)(data+idx-64))[debug_idx]);
        }
        // Print out last header to help with debugging
        if (num_hdr > 0)
        {
          mexPrintf("Last good header:\n");
          for (int header_idx=0; header_idx<*num_header_fields; header_idx++)
          {
            mexPrintf("  %d 0x%016llx\n", header_idx, ((unsigned long long int *)(hdr+(num_hdr-1)*header_size))[header_idx]);
          }
          if (num_hdr > 1)
          {
            mexPrintf("Good header before last good header:\n");
            for (int header_idx=0; header_idx<*num_header_fields; header_idx++)
            {
              mexPrintf("  %d 0x%016llx\n", header_idx, ((unsigned long long int *)(hdr+(num_hdr-2)*header_size))[header_idx]);
            }
          }
          // Remove the last header
          mexPrintf("  Marking record %d as bad\n", num_hdr);
          ((unsigned int *)(hdr+(num_hdr-1)*header_size))[0] = -2^31;
        }
        else
        {
          mexPrintf("  First record so no record header to print\n");
        }
        *num_expected = -1;
      }
      idx += 8;
    }
  }
  
  if (*num_expected > 0)
  {
    *num_expected = idx - file_size;
  }
  
  // Copy hdr to output
  /* Point mxArray to dynamicData */
  mxSetData(plhs[0], hdr);
  mxSetM(plhs[0], *num_header_fields);
  mxSetN(plhs[0], num_hdr);
  
  ((int *)mxGetPr(plhs[1]))[0] = *last_bytes_len;
  ((int *)mxGetPr(plhs[2]))[0] = *num_expected;
  ((int *)mxGetPr(plhs[3]))[0] = *pkt_counter;

  return;
}
