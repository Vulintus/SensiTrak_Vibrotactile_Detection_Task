function [port_list, varargout] = Vulintus_Serial_Port_List(varargin)

%Vulintus_Serial_Port_List.m - Vulintus, Inc.
%
%   VULINTUS_SERIAL_PORT_LIST finds all connected serial port devices and
%   pairs the assigned COM port with device descriptions stored in the
%   system registry.
%
%   UPDATE LOG:
%   2021-11-29 - Drew Sloan - Function first created.
%   2024-02-27 - Drew Sloan - Branched the port matching file read
%                             functions into dedicated functions.
%   2024-06-06 - Drew Sloan - Added the option to use the older deprecated
%                             serial functions.
%

if datetime(version('-date')) > datetime('2019-09-17')                      %If the version is 2019b or newer...
    use_serialport = true;                                                  %Use the newer serialport functions by default.
else                                                                        %Otherwise...
    use_serialport = false;                                                 %Use the older serial functions by default.
end
if nargin > 0                                                               %If at least one input argument was included...
    use_serialport = varargin{1};                                           %Assume the serial function version setting was passed.
end

% List all active COM ports.
if use_serialport                                                           %If we're using the newer serialport functions...
    ports = serialportlist('all');                                          %Grab all serial ports.    
    available_ports = serialportlist('available');                          %Find all ports that are currently available.
else                                                                        %Otherwise, if we're using the older serial functions...
    ports = instrhwinfo('serial');                                          %Grab information about the available serial ports.
    available_ports = ports.AvailableSerialPorts;                           %Find all ports that are currently available.
    ports = ports.SerialPorts;                                              %Save the list of all serial ports regardless of whether they're busy.
end
port_list = cell(numel(ports),4);                                           %Create an N-by-4 cell array to hold port info.
if isempty(ports)                                                           %If no serial ports were found...
    port_list = {};                                                         %Set the function output to empty.
    return                                                                  %Skip execution of the rest of the function.
end

% Label ports as available or busy.
for i = 1:numel(ports)                                                      %Step through each port.
    port_list{i,1} = ports{i};                                              %Copy the port name to the first column of the list.
    if any(strcmpi(port_list{i,1},available_ports))                         %If the serial port is available...
        port_list{i,2} = 'available';                                       %List the port as available.
    else                                                                    %Otherwise...
        port_list{i,2} = 'busy';                                            %List the port as busy.
    end
end

% Grab the VID, PID, and device description for all known USB devices.
key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\';              %Set the registry query field.
[~, txt] = dos(['REG QUERY ' key ' /s /f "FriendlyName" /t "REG_SZ"']);     %Query the registry for all USB devices.
txt = textscan(txt,'%s','delimiter','\t');                                  %Parse the text by row.
txt = cat(1,txt{:});                                                        %Reshape the cell array into a vertical array.
dev_info = struct(  'description',  [],...
                    'alias',        [],...
                    'port',         [],...
                    'vid',          [],...
                    'pid',          []);                                    %Create a structure to hold device information.
dev_i = 0;                                                                  %Create a device counter.
for i = 1:length(txt)                                                       %Step through each entry.
    if startsWith(txt{i},key)                                               %If the line starts with the key.
        dev_i = dev_i + 1;                                                  %Increment the device counter.
        if contains(txt{i},'VID_')                                          %If this line includes a VID.
            j = strfind(txt{i},'VID_');                                     %Find the device VID.
            dev_info(dev_i).vid = txt{i}(j+4:j+7);                          %Grab the VID.
        end
        if contains(txt{i},'PID_')                                          %If this line includes a PID.
            j = strfind(txt{i},'PID_');                                     %Find the device PID.
            dev_info(dev_i).pid = txt{i}(j+4:j+7);                          %Grab the PID.
        end
        if contains(txt{i+1},'REG_SZ')                                      %If this line includes a device description.
            j = strfind(txt{i+1},'REG_SZ');                                 %Find the REG_SZ preceding the description on the following line.
            dev_info(dev_i).description = strtrim(txt{i+1}(j+7:end));       %Grab the port description.
        end
    end
end
keepers = zeros(length(dev_info),1);                                        %Create a matrix to mark devices for exclusion.
for i = 1:length(dev_info)                                                  %Step through each device.
    if contains(dev_info(i).description,'(COM')                             %If the description includes a COM port.
        j = strfind(dev_info(i).description,'(COM');                        %Find the start of the COM port number.
        dev_info(i).port = dev_info(i).description(j+1:end-1);              %Grab the COM port number.
        dev_info(i).description(j:end) = [];                                %Trim the port number off the description.
        dev_info(i).description = strtrim(dev_info(i).description);         %Trim off any leading or following spaces.
        keepers(i) = 1;                                                     %Mark the device for inclusion.
    end
end
dev_info(keepers == 0) = [];                                                %Kick out all non-COM devices.


% Check the VIDs and PIDs for Vulintus devices.
usb_pid_list = Vulintus_USB_VID_PID_List;                                   %Grab the list of USB VIDs and PIDs for Vulintus devices.
for i = 1:length(dev_info)                                                  %Step through each device.    
    a = strcmpi(dev_info(i).vid,usb_pid_list(:,1));                         %Find all Vulintus devices with this VID.
    b = strcmpi(dev_info(i).pid,usb_pid_list(:,2));                         %Find all Vulintus devices with this PID.
    if any(a & b)                                                           %If there's a match for both...
        dev_info(i).description = usb_pid_list{a & b, 3};                   %Replace the device description.
    end
end

% Check the port matching file for any user-set aliases.
pairing_info = Vulintus_Serial_Port_Matching_File_Read;                     %Read in the saved pairing info.
if ~isempty(pairing_info)                                                   %If any port-pairing information was found.
    for i = 1:length(dev_info)                                              %Step through each device.    
        a = strcmpi(dev_info(i).port,pairing_info(:,1));                    %Find any matches for this COM port.
        if any(a)                                                           %If there's a match...            
            dev_info(i).alias = pairing_info{a,3};                          %Set the device alias.
            if ~any(strcmpi(dev_info(i).description,usb_pid_list(:,3)))     %If the device descrciption wasn't set from the VID/PID...
                dev_info(i).description = pairing_info{a,2};                %Set the device description.
            end
        end
    end
end

% Pair each active port with it's device information.
for i = 1:size(port_list,1)                                                 %Step through each port.
    j = strcmpi({dev_info.port},port_list{i,1});                            %Find the port in the USB device list.    
    if any(j)                                                               %If a matching port was found...
        port_list{i,3} = dev_info(j).description;                           %Grab the port description.
        port_list{i,4} = dev_info(j).alias;                                 %Grab the device alias.
    elseif ~isempty(pairing_info)                                           %Otherwise...
        j = strcmpi(port_list{i,1}, pairing_info(:,1));                     %Check for matches in the saved pairing info.
        if any(j)                                                           %If there's pairing info for this COM port...
            port_list{i,3} = pairing_info{j,2};                             %Grab the port description.
            port_list{i,4} = pairing_info{j,3};                             %Grab the device alias.
            dev_info(end+1).port = port_list{i,1};                          %#ok<AGROW> %Add the COM port to the device list.
            dev_info(end).description = pairing_info{j,2};                  %Copy over the device description.
            dev_info(end).alias = pairing_info{j,3};                        %Copy over the userset alias.
        end
    end
end

% Set the output arguments.
varargout{1} = dev_info;                                                    %Return the device info (if requested).