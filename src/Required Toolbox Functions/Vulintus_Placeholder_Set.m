function timestamp = Vulintus_Placeholder_Set(placeholder_file)

%
%Vulintus_Placeholder_Set.m - Vulintus, Inc.
%
%   VULINTUS_PLACEHOLDER_SET creates a new placeholder file at the
%   specified location containing the file create time as a single 64-bit
%   timestamp in the serial date number format.
%
%   UPDATE LOG:
%   2024-03-25 - Drew Sloan - Function first created.
%

fid = fopen(placeholder_file,'w');                                          %Open the placeholder file for writing.
timestamp = datenum(datetime('now'));                                       %#ok<DATNM> %Grab the serial date number for the current 
fwrite(fid,timestamp,'float64');                                            %Write the timestamp to the file as a 64-bit floating point number.
fclose(fid);                                                                %Close the file.