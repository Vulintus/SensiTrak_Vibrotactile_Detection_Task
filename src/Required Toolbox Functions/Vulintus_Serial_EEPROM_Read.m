function [reply, code] = Vulintus_Serial_EEPROM_Read(serialcon,cmd,addr,N,datatype)

%Vulintus_Serial_EEPROM_Read.m - Vulintus, Inc., 2022
%
%   VULINTUS_SERIAL_EEPROM_READ sends the EEPROM read request
%   command, followed by the target address and number of bytes to read.
%   The function will then read in the received bytes as the type specified
%   by the user.
%
%   UPDATE LOG:
%   2022-03-03 - Drew Sloan - Function first created, adapted from
%                             Vulintus_Serial_Request_uint32.m.
%   2024-06-06 - Drew Sloan - Added the option to use the older deprecated
%                             serial functions.
%

reply = [];                                                                 %Assume no reply values will be received by default.
code = 0;                                                                   %Assume no reply code will be received by default.

switch lower(datatype)                                                      %Switch between the available data types...
    case {'uint8','int8','char'}                                            %For 8-bit data types...
        bytes_per_val = 1;                                                  %The number of bytes is the size of the request.
    case {'uint16','int16'}                                                 %For 16-bit data types...
        bytes_per_val = 2;                                                  %The number of bytes is the 2x size of the request.
    case {'uint32','int32','single'}                                        %For 32-bit data types...
        bytes_per_val = 4;                                                  %The number of bytes is the 4x size of the request. 
    case {'double'}                                                         %For 64-bit data types...
        bytes_per_val = 8;                                                  %The number of bytes is the 8x size of the request.
end

vulintus_serial = Vulintus_Serial_Basic_Functions(serialcon);               %Load the basic serial functions for either "serialport" or "serial".

if vulintus_serial.bytes_available() > 0                                    %If there's currently any data on the serial line.
    vulintus_serial.flush();                                                %Flush any existing bytes off the serial line.
end
vulintus_serial.write(cmd,'uint16');                                        %Write the command.
vulintus_serial.write(addr,'uint32');                                       %Write the EEPROM address.
vulintus_serial.write(N*bytes_per_val,'uint8');                             %Write the number of bytes to read back.
vulintus_serial.write(0,'uint8');                                           %Write a dummy byte to drive the Serial read loop on the device.
    
timeout_timer = tic;                                                        %Start a time-out timer.
while toc(timeout_timer) < 1 && ...
        vulintus_serial.bytes_available() < (2 + N*bytes_per_val)           %Loop for 1 second or until the expected reply shows up on the serial line.
    pause(0.01);                                                            %Pause for 10 milliseconds.
end
if vulintus_serial.bytes_available() >= 2                                   %If a block code was returned...
    code = vulintus_serial.read(1,'uint16');                                %Read in the unsigned 16-bit integer block code.
else                                                                        %Otherwise...
    return                                                                  %Skip execution of the rest of the function
end
N = floor(vulintus_serial.bytes_available()/bytes_per_val);                 %Set the number of values to read.
if N > 0                                                                    %If there's any integers on the serial line...        
    reply = vulintus_serial.read(N,datatype);                               %Read in the requested values as the specified type.
    reply = double(reply);                                                  %Convert the output type to double to play nice with comparisons in MATLAB.
end
vulintus_serial.flush();                                                    %Flush any remaining bytes off the serial line.