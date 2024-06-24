function Vulintus_Serial_Close(serialcon,stream_cmd)

%Vulintus_Serial_Close.m - Vulintus, Inc., 2022
%
%   VULINTUS_SERIAL_CLOSE closes the specified serial connection,
%   performing all necessary housekeeping functions and then deleting the
%   objects.
%
%   UPDATE LOG:
%   02/25/2022 - Drew Sloan - Function first created.
%

vulintus_serial = Vulintus_Serial_Basic_Functions(serialcon);               %Load the basic serial functions for either "serialport" or "serial".
Vulintus_OTSC_Transaction(serialcon,...
    stream_cmd,...
    'data',{0,'uint8'});                                                    %Disable streaming on the device.
pause(0.01);                                                                %Pause for 10 milliseconds.
vulintus_serial.flush();                                                    %Clear the input buffers.
delete(serialcon);                                                          %Delete the serial object.