function n_bytes = Vulintus_Return_Data_Type_Size(data_type)

%Vulintus_Return_Data_Type_Size.m - Vulintus, Inc., 2024
%
%   VULINTUS_RETURN_DATA_TYPE_SIZE returns the size, in bytes, of a single
%   element of the classes specified by "data_type".
%
%   UPDATE LOG:
%   2024-06-07 - Drew Sloan - Function first created.
%

switch lower(data_type)                                                     %Switch between the available data types...
    case {'int8','uint8','char'}                                            %For 8-bit data types...
        n_bytes = 1;                                                        %The number of bytes is the size of the request.
    case {'int16','uint16'}                                                 %For 16-bit data types...
        n_bytes = 2;                                                        %The number of bytes is the 2x size of the request.
    case {'int32','uint32','single'}                                        %For 32-bit data types...
        n_bytes = 4;                                                        %The number of bytes is the 4x size of the request. 
    case {'uint64','double'}                                                %For 64-bit data types...
        n_bytes = 8;                                                        %The number of bytes is the 8x size of the request.
    otherwise                                                               %For any unrecognized classes.
        error('ERROR IN %s: Unrecognized variable class "%s"',...
            upper(mfilename),data_type);                                    %Show an error.
end     