function [data, block_i] = Vulintus_Serial_Read_Stream(serialcon,serial_codes,varargin)

%Vulintus_Serial_Read_Stream.m - Vulintus, Inc., 2022
%
%   VULINTUS_SERIAL_READ_STREAM checks the serial line for any new
%   streaming data, and returns an data structure organizing any data
%   packets it finds.
%
%   UPDATE LOG:
%   03/03/2022 - Drew Sloan - Function first created.
%   05/24/2022 - Drew Sloan - Added a 'verbose' output option for debugging
%       purposes.
%   12/05/2022 - Camilo - added functionality for douple optical switch

verbose = 0;                                                                %Default to non-verbose output.
for i = 1:numel(varargin)                                                   %Step through all of the variable input arguments.
    switch lower(varargin{i})                                               %Switch between recognized arguments.
        case 'verbose'                                                      %Request verbose output.
            verbose = 1;                                                    %Set the verbose flag to 1.            
            all_codenames = fieldnames(serial_codes);                       %Grab all of the serial code names.
            all_codes = nan(size(all_codenames));                           %Create a matrix to hold all serial codes.
            for j = 1:numel(all_codes)                                      %Step through each code...            
                if isequal(all_codenames{j},upper(all_codenames{j}))        %If the fieldname is all uppercase...
                    all_codes(j) = serial_codes.(all_codenames{j});         %Grab the value for each serial code name.
                end
            end
            all_codenames(isnan(all_codes)) = [];                           %Kick out all non-code fields.
            all_codes(isnan(all_codes)) = [];                               %Kick out all NaN values.
    end
end

vulintus_serial = Vulintus_Serial_Basic_Functions(serialcon);               %Load the basic serial functions for either "serialport" or "serial".

data = struct('type',[],'timestamp',[],'value',[]);                         %Assume no streaming data has been received.
block_i = 0;                                                                %Data block counter.
read_next = 1;                                                              %Boolean for ending a stream read leaving bytes on the serial line.

while (vulintus_serial.bytes_available() > 1) && (read_next)                %Loop for as long as there's two or more bytes available.
    
    if ~isempty(serialcon.UserData)                                         %If a block code was queued from a previous read.
        code = serialcon.UserData;                                          %Load the code.
        serialcon.UserData = [];                                            %Clear the queued block code from the serial object's UserData.
    else                                                                    %Otherwise...
        code = vulintus_serial.read(1,'uint16');                            %Read in the next unsigned 16-bit integer block code.
        
        if verbose == 1                                                     %If verbose debugging output is requested...
            fprintf(1,'%1.0f >> ', code);                                   %Print the code value.
            fprintf(1,'%s\n',...
                Vulintus_Serial_Read_Stream_Match_Codename(code,...
                serial_codes));                                             %Print the code name.
        end
        
    end
    
    block_i = block_i + 1;                                                  %Increment the block count.
    
    switch code                                                             %Switch between the recognized serial codes.
                
        case {  serial_codes.AP_ERROR,...
                }                                                           %Simple notifications.
            codename = ...
                Vulintus_Serial_Read_Stream_Match_Codename(code,...
                serial_codes);                                              %Match the codename.
            data(block_i).type = codename(6:end);                           %Save the packet type to the data structure.
            continue                                                        %Skip to the next block code.
            
        case {  serial_codes.ERROR_INDICATOR,...
                serial_codes.CENTER_OFFSET,...
                }                                                           %2-byte packet codes.
            packet_size = 2;                                                %Number of bytes in the associated packet.
            
        case {  serial_codes.MOVEMENT_START,...
                serial_codes.MOVEMENT_COMPLETE,...
                serial_codes.HOMING_COMPLETE,...
                serial_codes.RECENTER_COMPLETE,...                          % added by -cs
                serial_codes.FORCE_BASELINE,...
                serial_codes.FORCE_SLOPE,...
                }                                                           %4-byte packet codes.
            packet_size = 4;                                                %Number of bytes in the associated packet.
            
        case {  serial_codes.POKE_BITMASK,...
                serial_codes.LICK_BITMASK,...
                serial_codes.DISPENSE_FIRMWARE,...
             }                                                              %5-byte packet codes.
            packet_size = 5;                                                %Number of bytes in the associated packet.
            
%         case {  serial_codes.STAP_FORCE_VAL,...
%                 serial_codes.STTC_FORCE_VAL}                                %6-byte packet codes.
%             packet_size = 6;                                                %Number of bytes in the associated packet.

        case serial_codes.LICK_CAP
            packet_size = 8;                                                %Number of bytes in the associated packet.

        case serial_codes.THERM_XY_PIX
            packet_size = 9;                                                %Number of bytes in the associated packet.

        case serial_codes.THERM_PIXELS_FP62
            packet_size = 1031;                                             %Number of bytes in the associated packet.
            
        otherwise                                                           %Any unrecognized block code.
            codename = ...
                Vulintus_Serial_Read_Stream_Match_Codename(code,...
                serial_codes);                                              %Match the codename.
            if isempty(codename)                                            %If the code value isn't recognized at all...
                warning('%s - Unknown OTSC block code: %1.0f',...
                    upper(mfilename),code);                                 %Create the warning message. 
            elseif strcmpi(codename,'UNKNOWN_BLOCK_ERROR')                  %If the code was for an unknown block error...
                warning(['%s - Controller reported an unknown block ' ...
                    'error for OTSC block value 0x%X.'],...
                    upper(mfilename),...
                    vulintus_serial.read(1,'uint16'));                      %Create the warning message. 
            else                                                            %Otherwise...
                warning(['%s - Need to finish coding for packet'...
                    ' type ''%s''.'],upper(mfilename),codename);            %Create the warning message. 
            end                    
            flush(serialcon);                                               %Flush any remaining bytes off the serial line.
            continue                                                        %Skip to the next block code.
            
    end
    
    if vulintus_serial.bytes_available() >= packet_size                     %If the expected packet was received...
        
        switch code                                                         %Switch between the recognized serial codes.               
            
            case serial_codes.ERROR_INDICATOR                               %Error indicator.
                data(block_i).type = 'CC_ERROR_INDICATOR';                  %Label the packet as a error indicator.
                data(block_i).value = vulintus_serial.read(1,'uint16');     %Read in the unsigned 16-bit integer error code.
                
            case serial_codes.MOVEMENT_START                                %Timestamped movement start indicator.
                data(block_i).type = 'CC_MOVEMENT_START';                   %Label the packet as a movement start indicator.
                data(block_i).timestamp = ...
                    vulintus_serial.read(1,'uint32');                       %Read in the unsigned 32-bit integer timestamp.
                
            case serial_codes.MOVEMENT_COMPLETE                             %Timestamped movement complete indicator.
                data(block_i).type = 'CC_MOVEMENT_COMPLETE';                %Label the packet as a movement complete indicator.
                data(block_i).timestamp = ...
                    vulintus_serial.read(1,'uint32');                       %Read in the unsigned 32-bit integer timestamp.
                
            case serial_codes.HOMING_COMPLETE                               %Timestamped homing complete indicator.
                data(block_i).type = 'CC_HOMING_COMPLETE';                  %Label the packet as a homing complete indicator.
                data(block_i).timestamp = ...
                    vulintus_serial.read(1,'uint32');                       %Read in the unsigned 32-bit integer timestamp.                
            
            case serial_codes.RECENTER_COMPLETE                             %Timestamped recenter complete indicator. -cs
                data(block_i).type = 'RECENTER_COMPLETE';                   %Label the packet as a recetner complete indicator. -cs
                data(block_i).timestamp = ...
                    vulintus_serial.read(1,'uint32');   

            case serial_codes.DISPENSE_FIRMWARE                             %Report that a feeding was automatically triggered in the device firmware.
                data(block_i).type = 'DISPENSE_FIRMWARE';                   %Label the packet as a dispenser timing.
                data(block_i).timestamp = ...
                    vulintus_serial.read(1,'uint32');                       %Read in the unsigned 32-bit integer timestamp. 
                data(block_i).value = vulintus_serial.read(1,'uint8');      %Read in the dispenser index.
                % fprintf(1,'DISPENSE_FIRMWARE\n');

            case serial_codes.THERM_PIXELS_FP62                             %Thermal pixel image as a fixed-point 6/2 type.
                data(block_i).type = 'THERM_PIXELS_FP62';                   %Label the packet as a thermal pixel image..
                data(block_i).timestamp = ...
                    vulintus_serial.read(1,'uint32');                       %Read in the unsigned 32-bit integer timestamp. 
                data(block_i).value = vulintus_serial.read(1027,'uint8');   %Read in the thermal image.

            case serial_codes.THERM_XY_PIX                                  %Current thermal hotspot x-y position, in units of pixels.
                data(block_i).type = 'THERM_XY_PIX';                        %Label the packet as a thermal pixel image..
                data(block_i).timestamp = ...
                    vulintus_serial.read(1,'uint32');                       %Read in the unsigned 32-bit integer timestamp. 
                data(block_i).value = [vulintus_serial.read(3,'uint8'),...
                    vulintus_serial.read(1,'single')];                      %Read in the hotspot data.

            case serial_codes.POKE_BITMASK                                  %Timestamped nosepoke value.
                data(block_i).type = 'POKE_BITMASK';                        %Label the packet as a nosepoke value.
                data(block_i).timestamp = ...
                    vulintus_serial.read(1,'uint32');                       %Read in the unsigned 32-bit integer timestamp.
                data(block_i).value = vulintus_serial.read(1,'uint8');      %Read in the unsigned 8-bit integer bitmask.            

            case serial_codes.LICK_BITMASK                                  %Timestamped lick sensor value.
                data(block_i).type = 'LICK_BITMASK';                        %Label the packet as a lick sensor value.
                data(block_i).timestamp = ...
                    vulintus_serial.read(1,'uint32');                       %Read in the unsigned 32-bit integer timestamp.
                data(block_i).value = vulintus_serial.read(1,'uint8');      %Read in the unsigned 8-bit integer bitmask.
                % fprintf(1,'LICK_BITMASK\n');

            case serial_codes.LICK_CAP                                      %Timestamped lick sensor value.
                data(block_i).type = 'LICK_CAP';                            %Label the packet as a nosepoke value.
                data(block_i).timestamp = ...
                    vulintus_serial.read(1,'uint32');                       %Read in the unsigned 32-bit integer timestamp.
                data(block_i).value = [vulintus_serial.read(2,'uint8'),...
                    vulintus_serial.read(1,'uint16')];                      %Read in the unsigned 8-bit integer bitmask.
                % fprintf(1,'LICK_CAP\n');

            case serial_codes.FORCE_VAL                                     %Timestamped STTC force value.
                data(block_i).type = 'FORCE_VAL';                           %Label the packet as a force value.
                data(block_i).timestamp = ...
                    vulintus_serial.read(1,'uint32');                       %Read in the unsigned 32-bit integer timestamp.
                data(block_i).value = vulintus_serial.read(1,'uint16');     %Read in the unsigned 16-bit integer ADC reading.
                
%             case serial_codes.FORCE_VAL                                     %Timestamped STAP force value.
%                 data(block_i).type = 'FORCE_VAL';                           %Label the packet as a force value.
%                 data(block_i).timestamp = ...
%                     vulintus_serial.read(1,'uint32');                       %Read in the unsigned 32-bit integer timestamp.
%                 data(block_i).value = vulintus_serial.read(1,'uint16');     %Read in the unsigned 16-bit integer ADC reading.
                
            case serial_codes.FORCE_BASELINE                                %STAP force calibration baseline value.
                data(block_i).type = 'FORCE_BASELINE';                      %Label the packet as a force value.
                data(block_i).value = vulintus_serial.read(1,'single');     %Read in the saved float32 calibration value.
                
            case serial_codes.FORCE_SLOPE                                   %STAP force calibration slope value.
                data(block_i).type = 'FORCE_SLOPE';                         %Label the packet as a force value.
                data(block_i).value = vulintus_serial.read(1,'single');     %Read in the saved float32 calibration value.
                
%             case serial_codes.FORCE_BASELINE                                %STTC force calibration baseline value.
%                 data(block_i).type = 'FORCE_BASELINE';                      %Label the packet as a force value.
%                 data(block_i).value = vulintus_serial.read(1,'single');     %Read in the saved float32 calibration value.
%                 
%             case serial_codes.FORCE_SLOPE                                   %STTC force calibration slope value.
%                 data(block_i).type = 'FORCE_SLOPE';                         %Label the packet as a force value.
%                 data(block_i).value = vulintus_serial.read(1,'single');     %Read in the saved float32 calibration value.
                
            case serial_codes.CENTER_OFFSET                                 %STAP center offset calibration value.
                data(block_i).type = 'CENTER_OFFSET';                       %Label the packet as a force value.
                data(block_i).value = vulintus_serial.read(1,'uint16');     %Read in the saved 16-bit unsigned integer offset value.
            
        end
    
    else                                                            %Otherwise, if the serial read timed out...
        serialcon.UserData = code;                                  %Save the block code for the next stream read call.
        block_i = block_i - 1;                                      %Decrement the block count.
        read_next = 0;                                              %Stop the stream read.
    end
end


function codename = Vulintus_Serial_Read_Stream_Match_Codename(code,serial_codes)
fields = fieldnames(serial_codes);                                          %Grab all of the field names.
values = struct2cell(serial_codes);                                         %Grab all of the values as a cell array.
values = cell2mat(values(4:end));                                           %Convert the cell array to a matrix.
i = find(code == values) + 3;                                               %Find the index matching the code.
if ~isempty(i)                                                              %If a match was found...
    codename = fields{i};                                                   %Return the fieldname.
else                                                                        %Otherwise...
    codename = [];                                                          %Return empty brackets.
end