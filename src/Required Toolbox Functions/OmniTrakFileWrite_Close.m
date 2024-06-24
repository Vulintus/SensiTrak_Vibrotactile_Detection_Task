function OmniTrakFileWrite_Close(fid, ofbc_clock_file_stop)

%
%OmniTrakFileWrite_Close.m - Vulintus, Inc.
%
%   OMNITRAKFILEWRITE_CLOSE adds a time-stamped file-closing block to the
%   specified *.OmniTrak file and then closes the file.
%   
%   UPDATE LOG:
%   2024-04-23 - Drew Sloan - Function first created.
%

fwrite(fid,ofbc_clock_file_stop,'uint16');                                  %-CLOCK_FILE_STOP- block code.
fwrite(fid,now,'float64');                                                  %Serial date number written as a 64-bit floating point.