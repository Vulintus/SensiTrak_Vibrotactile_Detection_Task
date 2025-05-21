function stages = Vulintus_Behavior_Stages_Read(stage_path, varargin)

%
%Vulintus_Behavior_Read_Stages.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_READ_STAGES loads stage information from the stages
%   subfolder in the configuration folder. If a Google spreadsheet link is
%   passed, it will download that stage information and update all stage
%   files listed in spreadsheet.
%   
%   UPDATE LOG:
%   2024-02-29 - Drew Sloan - Function first created, adapted from
%                             Stop_Task_Read_Stages.m
%

if nargin > 1                                                               %If stage synchronization information was passed.
    stages_sync = varargin{1};                                              %A stage synchronization structure should be the first input.
else                                                                        %Otherwise...
    stages_sync = struct;                                                   %Create a stage synchronization structure.
end
     
if ~exist(stage_path,'dir')                                                 %If the stage path doesn't exist yet...
    mkdir(stage_path);                                                      %Create it.
end

if isfield(stages_sync,'google_spreadsheet_url')                            %If a Google spreadsheet URL was defined...
    try                                                                     %Try to read in the stage information from the web.
        data = Read_Google_Spreadsheet(stages_sync.google_spreadsheet_url); %Read in the stage information from the Google Docs URL.
        field_row = 0;                                                      %Assume no field row is found.
        for i = 2:size(data,1)                                              %Step through each row of the data.
            if ischar(data{i,1}) && data{i,1}(1) == '.'                     %If the cell entry is preceded by a period...
                field_row = i;                                              %Use this row as the field name row.
                break                                                       %Skip the remaining rows.
            end
        end
        if field_row ~= 0                                                   %If a field name row was found...
            stage_fields = data(field_row,:);                               %Grab all of the field names.
            for i = 1:length(stage_fields)                                  %Step through the stage fields.
                stage_fields{i} = lower(stage_fields{i});                   %Make the field all lower-case.
                stage_fields{i}(stage_fields{i} == '_') = ' ';              %Replace all underscores with spaces.
                bad_chars = (stage_fields{i} < 32) | ...
                            (stage_fields{i} > 32 & stage_fields{i} < 48) | ...
                            (stage_fields{i} > 57 & stage_fields{i} < 97) | ...
                            (stage_fields{i} > 122);                        %Find all non-field-friendly characters.
                stage_fields{i}(bad_chars) = [];                            %Kick out all non-field-friendly characters.
                stage_fields{i} = strtrim(stage_fields{i});                 %Trim off any leading or trailing spaces.
                stage_fields{i}(stage_fields{i} == ' ') = '_';              %Replace all spaces with underscores.
            end
            if any(strcmpi(stage_fields,'name'))                            %If there's a "name" column...
                for i = (field_row+1):size(data,1)                          %Step through each row of the data.
                    temp = struct;                                          %Reset a structure to hold the stage info.
                    for j = 1:length(stage_fields)                          %Step through each column.
                        if ~isempty(stage_fields{j})                        %If there's a field name for this column...
                            if ~isempty(data{i,j})                          %If there's data in this cell...
                                temp.(stage_fields{j}) = strtrim(data{i,j});%Copy the cell value into the temporary structure.
                            end
                        end
                    end
                    if isfield(temp,'name') && ~isempty(temp.name)          %If a name was set for this stage...
                        filename = [upper(temp.name) '.STAGE'];             %Create the filename.
                        filename(filename == ' ') = '_';                    %Replace all spaces with underscores.
                        filename = fullfile(stage_path,filename);           %Add the stage path to the filename.
                        Vulintus_JSON_File_Write(temp, filename);           %Write the configuration to a JSON file.
                    end
                end
            else                                                            %Otherwise, if no "name" colume was found.
                warning(['%s -> No "name" column was found in the '...
                    'specified stages spreadsheet:\n\t%s'],...
                upper(mfilename),stages_sync.google_spreadsheet_url);       %Show a warning.
            end
        else                                                                %Otherwise, if no field name row was found.
            warning(['%s -> No field names row was found in the '...
                'specified stages spreadsheet:\n\t%s'],...
                upper(mfilename),stages_sync.google_spreadsheet_url);       %Show a warning.
        end
    catch err                                                               %If there's an error...
        warning(['%s -> Could not read the specified stages '...
            'spreadsheet.\n\t%s:%s'], upper(mfilename), err.identifier,...
            err.message);                                                   %Show a warning.
    end
end

stages = struct;                                                            %Create a stages structure.
stage_files = dir(fullfile(stage_path,'*.STAGE'));                          %Find all stage files in the stage folder.
for i = 1:length(stage_files)                                               %Step through each stage file.
    stages(i).filename = fullfile(stage_path, stage_files(i).name);         %Add the path to the filename.
    temp = Vulintus_JSON_File_Read(stages(i).filename);                     %Read in the stage file.
    temp_fields = fieldnames(temp);                                         %Grab all of the fieldnames from the temporary structure.
    for f = 1:length(temp_fields)                                           %Step through each field.
        stages(i).(temp_fields{f}) = temp.(temp_fields{f});                 %Copy each field to the stages structure.
    end
end

for i = 1:length(stages)                                                    %Step through the stages.
    if all(isfield(stages,{'name','description'}))                           %If the stage structure has both number and description fields.
        stages(i).list_str = [stages(i).name ': ' stages(i).description];   %Create a list selection string with the stage name and descriptions.
    else                                                                    %Otherwise...
        stages(i).list_str = stages(i).name;                                %Create a list selection string with just the stage name.
    end
end