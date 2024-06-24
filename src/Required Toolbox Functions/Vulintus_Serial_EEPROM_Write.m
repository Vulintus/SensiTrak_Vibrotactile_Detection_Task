function Vulintus_Serial_EEPROM_Write(serialcon,cmd,addr,data,type)

%Vulintus_Serial_EEPROM_Write.m - Vulintus, Inc., 2022
%
%   VULINTUS_SERIAL_EEPROM_WRITE sends via serial, in order, the 
%       1) OTMP command to write bytes to the EEPROM,
%       2) target EEPROM address, followed by the,
%       3) number of bytes to write, and
%       4) bytes of the specified data, broken down by data type.
%
%   UPDATE LOG:
%   2022-03-03 - Drew Sloan - Function first created, adapted from
%                             Vulintus_OTSC_Transaction_uint32.m.
%   2024-06-06 - Drew Sloan - Added the option to use the older deprecated
%                             serial functions.
%


vulintus_serial = Vulintus_Serial_Basic_Functions(serialcon);               %Load the basic serial functions for either "serialport" or "serial".

vulintus_serial.write(cmd,'uint16');                                        %Write the EEPROM write command.
vulintus_serial.write(addr,'uint32');                                       %Write the target EEPROM address.
if isempty(data)                                                            %If no data was sent...
    vulintus_serial.write(0,'uint8');                                       %Send a zero for the number of following bytes.
else                                                                        %Otherwise, if data is to be sent...
    switch lower(type)                                                      %Switch between the available data types...
        case {'uint8','int8','char'}                                        %For 8-bit data types...
            N = numel(data);                                                %The number of bytes is the size of the array.
        case {'uint16','int16'}                                             %For 16-bit data types...
            N = 2*numel(data);                                              %The number of bytes is the 2x size of the array.
        case {'uint32','int32','single'}                                    %For 32-bit data types...
            N = 4*numel(data);                                              %The number of bytes is the 4x size of the array. 
        case {'double'}                                                     %For 64-bit data types...
            N = 8*numel(data);                                              %The number of bytes is the 8x size of the array.
    end
    vulintus_serial.write(data,type);                                       %Send the data as the specified type.
end