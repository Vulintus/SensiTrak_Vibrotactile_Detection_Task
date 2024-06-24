function Vulintus_Serial_Port_Matching_File_Update(com_port, device_name, alias)

%Vulintus_Serial_Port_Matching_File_Update.m - Vulintus, Inc.
%
%   VULINTUS_SERIAL_PORT_MATCHING_FILE_UPDATE updates the historical COM 
%   port pairing information stored in the Vulintus Common Configuration 
%   AppData folder with the currently-connected device information.
%
%   UPDATE LOG:
%   2024-02-27 - Drew Sloan - Function first created, branched from
%                             Vulintus_Serial_Port_List.m.
%

config_path = Vulintus_Set_AppData_Path('Common Configuration');            %Grab the directory for common Vulintus task application data.
port_matching_file = fullfile(config_path,...
    'omnitrak_com_port_info_new.config');                                   %Set the filename for the port matching file.

if exist(port_matching_file,'file')                                         %If the port matching file exists...
    pairing_info = Vulintus_TSV_File_Read(port_matching_file);              %Read in the saved pairing info.
else                                                                        %Otherwise, if the port matching file doesn't exist...
    pairing_info = {};                                                      %Return an empty cell array.
end

if ~isempty(pairing_info)                                                   %If the pairing info isn't empty...
    i = ~strcmpi(pairing_info(:,1), com_port) & ...
        strcmpi(pairing_info(:,3), alias);                                  %Check to see if this alias is matched with any other COM port
    pairing_info(i,:) = [];                                                 %Kick out the outdated pairings.   
    i = strcmpi(pairing_info(:,1), com_port);                               %Check to see if this COM port is already in the port matching file.
else                                                                        %Otherwise, if the pairing info is empty...
    i = 0;                                                                  %Set the index to zero.
end

if ~any(i)                                                                  %If the port isn't in the existing list.    
    i = size(pairing_info,1) + 1;                                           %Add a new row.
end
pairing_info(i,:) = {com_port, device_name, alias};                         %Add the device information to the list.

for i = 1:size(pairing_info,1)                                              %Step through each device.
    if isempty(pairing_info{i,3})                                           %If there is no alias...
        pairing_info{i,3} = char(255);                                      %Set the alias to "ÿ".
    end
end

pairing_info = sortrows(pairing_info,[3,1,2]);                              %Sort the pairing info by alias, then COM port, then device type.

for i = 1:size(pairing_info,1)                                              %Step through each device.
    if strcmpi(pairing_info{i,3},char(255))                                 %If the alias is set to "ÿ"...
        pairing_info{i,3} = [];                                             %Set the alias to empty brackets.
    end
end

Vulintus_TSV_File_Write(pairing_info, port_matching_file);                  %Write the pairing info back to the port matching file.