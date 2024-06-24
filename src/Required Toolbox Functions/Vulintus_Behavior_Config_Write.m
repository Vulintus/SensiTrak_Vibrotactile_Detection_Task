function Vulintus_Behavior_Config_Write(filename, handles, config_fields)

%
%Vulintus_Behavior_Config_Write.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_CONFIG_WRITE create a *.config file linking the specificed 
%   customizable behavioral parameters ("fields") stored in a configuration
%   structure ("handles") to currently-set values.
%   
%   UPDATE LOG:
%   2021-10-05 - Drew Sloan - Function first created, adapted from
%                             LED_Detection_Task_Write_Config.m.
%   2024-02-28 - Drew Sloan - Renamed from "Vulintus_Behavior_Write_Config"
%                             to "Vulintus_Behavior_Config_Write".
%


if ~isempty(config_fields)                                                  %If the fields input isn't empty...
    config = struct;                                                        %Create a temporary structure.    
    for f = 1:length(config_fields)                                         %Step through each set of fields/subfields to include.
        config = Vulintus_Copy_Subfield(config, handles, config_fields{f}); %Copy each field/subfield to the temporary structure.
    end
    Vulintus_JSON_File_Write(config, filename);                             %Write the configuration to a JSON file.
end