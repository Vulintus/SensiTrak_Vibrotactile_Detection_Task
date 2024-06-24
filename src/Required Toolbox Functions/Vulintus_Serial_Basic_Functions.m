function vulintus_serial = Vulintus_Serial_Basic_Functions(serialcon)

%Vulintus_Serial_Basic_Functions.m - Vulintus, Inc., 2024
%
%   VULINTUS_SERIAL_BASIC_FUNCTIONS creates a function structure including
%   the basic read, write, bytes available, and flush functions for either 
%   a 'serialport' or 'serial' class object.
%
%   UPDATE LOG:
%   2024-06-06 - Drew Sloan - Function first created.
%


vulintus_serial = struct;                                                   %Create a structure.

switch class(serialcon)                                                     %Switch between the types of serial connections.

    case 'internal.Serialport'                                              %Newer serialport functions.
        vulintus_serial.bytes_available = @serialcon.NumBytesAvailable;     %Number of bytes available.
        vulintus_serial.flush = @(varargin)flush(serialcon,varargin{:});    %Buffer flush functions.
        vulintus_serial.read = ...
            @(count,datatype)read(serialcon,count,datatype);                %Read data from the serialport object.
        vulintus_serial.write = ...
            @(data,datatype)write(serialcon,data,datatype);                 %Write data to the serialport object.

    case 'serial'                                                           %Older, deprecated serial functions.
        vulintus_serial.bytes_available = @serialcon.BytesAvailable;        %Number of bytes available.
        vulintus_serial.flush = ...
            @()Vulintus_Serial_Basic_Functions_Flush_Serial(serialcon);     %Buffer flush functions.
        vulintus_serial.read = ...
            @(count,datatype)fread(serialcon,count,datatype);               %Read data from the serialport object.
        vulintus_serial.write = ...
            @(data,datatype)fwrite(serialcon,data,datatype);                %Write data to the serialport object.

end


function Vulintus_Serial_Basic_Functions_Flush_Serial(serialcon)
if serialcon.BytesAvailable                                                 %If there's currently any data on the serial line.
    fread(serialcon,serialcon.BytesAvailable);                              %Clear the input buffer.
end