function pairing_info = Vulintus_Serial_Port_Matching_File_Read

%Vulintus_Serial_Port_Matching_File_Read.m - Vulintus, Inc.
%
%   VULINTUS_SERIAL_PORT_MATCHING_FILE_READ reads in the historical COM port
%   pairing information stored in the Vulintus Common Configuration AppData
%   folder.
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