function OmniTrakFileWrite_WriteBlock_V1_TIME_ZONE_OFFSET(fid, block_code)

%
%OmniTrakFileWrite_WriteBlock_V1_TIME_ZONE_OFFSET.m - Vulintus, Inc.
%
%   OMNITRAKFILEWRITE_WRITEBLOCK_V1_TIME_ZONE_OFFSET adds the time zone
%   offset, in units of days, between the local computer's time zone and
%   UTC time.
%   
%   UPDATE LOG:
%   2024-04-23 - Drew Sloan - Function first created.
%

fwrite(fid,block_code,'uint16');                                            %OmniTrak file format block code.
dt = datenum(datetime('now','TimeZone','local')) - ...
    datenum(datetime('now','TimeZone','UTC'));                              %Calculate the different between the computer time and UTC time.
fwrite(fid,dt,'float64');                                                   %Write the time zone offset as a serial date number.