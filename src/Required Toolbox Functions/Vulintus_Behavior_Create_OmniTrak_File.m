function ofbc_write = Vulintus_Behavior_Create_OmniTrak_File(fig)

%
%Vulintus_Behavior_Create_OmniTrak_File.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_CREATE_OMNITRAK_FILE creates an Vulintus *.OmniTrak 
%   format file to receive Vulintus behavioral program session data and 
%   starts the file with a standardized header.
%   
%   UPDATE LOG:
%   2024-04-22 - Drew Sloan - Function first created, adapted from
%                             ST_Tactile_2AFC_Write_File_Header.m.
%

data_path = fullfile(fig.UserData.datapath,...
    upper(fig.UserData.cur_subject));                                       %Create the subfolder name for this subject.
if ~exist(data_path,'dir')                                                  %If the subject subfolder doesn't already exist...
    mkdir(data_path);                                                       %Create the subject subfolder.
end
date_string = char(datetime,'yyyyMMdd''T''hhmmss');                         %Create a timestamp string.
s = fig.UserData.cur_stage;                                                 %Grab the stage index.
stage = fig.UserData.stages(s).name;                                        %Grab the stage name.
stage(stage == ' ') = [];                                                   %Kick out all spaces.
short_filename = sprintf(   '%s_%s_%s_%s.OmniTrak',...
                            upper(fig.UserData.cur_subject),...
                            date_string,...
                            fig.UserData.program.abbreviation,...
                            stage);                                         %Create the new filename.
full_filename = fullfile(data_path,short_filename);                         %Add the path to the filename.

ofbc_write = OmniTrak_File_Writer(full_filename);                           %Create the OFBC file-writer structure.

if isfield(fig.UserData,'ui') && isfield(fig.UserData.ui,'msgbox')          %If there's a messagebox in the GUI.
    str = sprintf('%s - Writing session data to file:',...
        char(datetime,'hh:mm:ss'));                                         %Create a message string.
    Add_Msg(fig.UserData.ui.msgbox,str);                                    %Show the message in the messagebox.
    Add_Msg(fig.UserData.ui.msgbox,['          ' fullfile(data_path,' ')]); %Show the user the session data path.
    Add_Msg(fig.UserData.ui.msgbox,['          ' short_filename]);          %Show the user the session data file name.
end



%System name.
if isfield(fig.UserData,'system_name') && ...
        ~isempty(fig.UserData.system_name)                                  %If a system name is specified in the handles structure.
    ofbc_write.system_name(fig.UserData.system_name);                       %Write the Vulintus system name to the file.
end

%Computer name.
if isfield(fig.UserData,'computer') && ...
        isfield(fig.UserData.computer,'name') && ...
        ~isempty(fig.UserData.computer.name)                                %If a computer name is specified in the handles structure.
    ofbc_write.computer_name(fig.UserData.computer.name);                   %Write the computer name to the file.
end

%User-set alias (a.k.a. user system name).
if isfield(fig.UserData,'ctrl') && ...
        isfield(fig.UserData.ctrl,'device') && ...
        isfield(fig.UserData.ctrl.device,'userset_alias') && ...
        ~isempty(fig.UserData.ctrl.device.userset_alias)                    %If an user-set alias is specified in the handles structure.
    ofbc_write.userset_alias(fig.UserData.ctrl.device.userset_alias);       %Write the system user-set alias to the file.
end

%COM Port.
if isfield(fig.UserData,'ctrl') && ...
        isfield(fig.UserData.ctrl,'port') && ...
        ~isempty(fig.UserData.ctrl.port)                                    %If a COM port is specified in the handles structure.
    ofbc_write.com_port(fig.UserData.ctrl.port);                            %Write the COM port to the file.
end

%Time zone offset.
ofbc_write.time_zone_offset();                                              %Write the time zone offset block.

%Firmware filename.
if isfield(fig.UserData,'ctrl') && ...
        isfield(fig.UserData.ctrl,'device') && ...
        isfield(fig.UserData.ctrl.device,'get_firmware_filename') && ...
        ~isempty(fig.UserData.ctrl.device.get_firmware_filename)            %If a firmware filename-fetching function is set in the handles structure...
    fig.UserData.ctrl.otsc.clear();                                         %Clear the serial line.
    str = fig.UserData.ctrl.device.get_firmware_filename();                 %Grab the firmware filename.
    if ~isempty(str)                                                        %If a firmware filename was returned.
        ofbc_write.ctrl_fw_filename(str);                                   %Write the controller firmware filename to the file.
    end
end

%Firmware date.
if isfield(fig.UserData,'ctrl') && ...
        isfield(fig.UserData.ctrl,'device') && ...
        isfield(fig.UserData.ctrl.device,'get_firmware_date') && ...
        ~isempty(fig.UserData.ctrl.device.get_firmware_date)                %If a firmware date-fetching function is set in the handles structure...
    fig.UserData.ctrl.otsc.clear();                                         %Clear the serial line.
    str = fig.UserData.ctrl.device.get_firmware_date();                     %Grab the firmware compilation date.
    if ~isempty(str)                                                        %If a firmware date was returned.
        ofbc_write.ctrl_fw_date(str);                                       %Write the controller firmware compilation date to the file.
    end
end

%Firmware time.
if isfield(fig.UserData,'ctrl') && ...
        isfield(fig.UserData.ctrl,'device') && ...
        isfield(fig.UserData.ctrl.device,'get_firmware_time') && ...
        ~isempty(fig.UserData.ctrl.device.get_firmware_time)                %If a firmware time-fetching function is set in the handles structure...
    fig.UserData.ctrl.otsc.clear();                                         %Clear the serial line.
    str = fig.UserData.ctrl.device.get_firmware_time();                     %Grab the firmware compilation time.
    if ~isempty(str)                                                        %If a firmware date was returned.
        ofbc_write.ctrl_fw_time(str);                                       %Write the controller firmware compilation time to the file.
    end
end

%Subject.
if isfield(fig.UserData,'cur_subject') && ...
        ~isempty(fig.UserData.cur_subject)                                  %If a subject name is specified in the handles structure.
    ofbc_write.subject_name(fig.UserData.cur_subject);                      %Write the subject name to the file.
end

%Experiment name.
if isfield(fig.UserData,'task') && ~isempty(fig.UserData.task)              %If a experiment/task name is specified in the handles structure.
    ofbc_write.exp_name(fig.UserData.task);                                 %Write the experiment/task name to the file.
end

%Stage name and description.
if isfield(fig.UserData,'cur_stage') && ~isempty(fig.UserData.cur_stage)    %If a stage index is specified in the handles structure.
    s = fig.UserData.cur_stage;                                             %Grab the stage index.    
    ofbc_write.stage_name(fig.UserData.stages(s).name);                     %Write the stage name to the file.
    ofbc_write.stage_description(fig.UserData.stages(s).description);       %Write the stage description to the file.
end