function OmniTrakFileWrite_WriteBlock_V1_Long_Character_Block(fid, block_code, str)

%
%OmniTrakFileWrite_WriteBlock_V1_Long_Character_Block.m - Vulintus, Inc.
%
%   OMNITRAKFILEWRITE_WRITEBLOCK_V1_LONG_CHARACTER_BLOCK adds the
%   specified character block to an *.OmniTrak data file, with a maximum
%   character count of 65,535.
%   
%   UPDATE LOG:
%   2024-04-23 - Drew Sloan - Function first created.
%

fwrite(fid,block_code,'uint16');                                            %OmniTrak file format block code.
fwrite(fid,length(str),'uint16');                                           %Number of characters in the specified string.
fwrite(fid,str,'uchar');                                                    %Characters of the string.