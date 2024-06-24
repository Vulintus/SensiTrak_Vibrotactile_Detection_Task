function Vulintus_Behavior_Update_Controls(fig, mode)

%
%Vulintus_Behavior_Update_Controls.m - Vulintus, Inc.
%
%   2AFC_UPDATE_CONTROLS_DURING_IDLE enables or disables all of the 
%   uicontrol and uimenu objects on a Vulintus Common Behavior-based GUI
%   depending on the current program mode ('idle' or 'session') passed to
%   the function.
%   
%   UPDATE LOG:
%   2024-02-28 - Drew Sloan - Function first implemented, adapted from
%                             STAP_2AFC_Update_Controls_During_Idle.m.
%   2024-04-11 - Drew Sloan - Switched from using a global run variable to
%                             a "run" field in the main figure UserData.
%

%Update the figure callbacks.
handles = fig.UserData;                                                     %Grab the handles structure from the main GUI.
handles.mainfig.CloseRequestFcn = ...
    {@Vulintus_Behavior_Set_Run_Field,handles.run_state.root.close};        %Set the callback for when the user tries to close the GUI.

if ~isfield(handles, 'ui')                                                  %If there's no "ui" field...
    warning(['%s -> No user interface objects were found in the '...
        'handles structure.'],upper(mfilename));                            %Show a warning.
    return                                                                  %Skip execution of the rest of the function.
end

%Update the menu callbacks.
if isfield(handles.ui,'menu')

    %Update the "Stages" uimenu.
    if isfield(handles.ui.menu,'stages') && ...
            isfield(handles,'stages_sync') && ...
            isfield(handles.stages_sync,'google_spreadsheet_edit_url')        
        handles.ui.menu.stages.view_spreadsheet.MenuSelectedFcn = ...
            {@Vulintus_Open_Google_Spreadsheet,...
            handles.stages_sync.google_spreadsheet_edit_url};               %Set the callback for the "Open Spreadsheet" submenu option.
    end

    %Update the "Preferences" uimenu.
    if isfield(handles.ui.menu,'pref')                                      %If there's a preferences menu...
        if isfield(handles.ui.menu.pref,'open_datapath')                    %Preferences >> Open Data Directory
            handles.ui.menu.pref.open_datapath.MenuSelectedFcn = ...
                {@Vulintus_Open_Directory,handles.datapath};                %Set the callback for the "Open Data Directory" submenu option.
        end
        if isfield(handles.ui.menu.pref,'set_datapath')                     %Preferences >> Set Data Directory
            handles.ui.menu.pref.set_datapath.MenuSelectedFcn = ...
                @Vulintus_Behavior_Set_Datapath;                            %Set the callback for the "Set Data Directory" submenu option.
        end
        if isfield(handles.ui.menu.pref,'err_report_on')                    %Preferences >> Error Report
            set([handles.ui.menu.pref.err_report_on,...
                handles.ui.menu.pref.err_report_off],...
                'MenuSelectedFcn',@Vulintus_Behavior_Set_Error_Reporting);  %Set the callback for turning off/on automatic error reporting.
        end
        if isfield(handles.ui.menu.pref,'error_reports')                    %Preferences >> View Error Reports
            handles.ui.menu.pref.error_reports.MenuSelectedFcn = ...
                {@Vulintus_Behavior_Open_Error_Reports,handles.mainpath};   %Set the callback for opening the error reports directory.
        end
        if isfield(handles.ui.menu.pref,'config_dir')                       %Preferences >> Configuration Files...
            handles.ui.menu.pref.config_dir.MenuSelectedFcn = ...
                {@Vulintus_Open_Directory,handles.mainpath};                %Set the callback for opening the configuration directory.
        end
    end

    %Update the "Camera" uimenu.
    if isfield(handles.ui.menu,'camera')
        if isfield(handles.ui.menu.pref,'view_webcam')                      %Camera >> View Webcam
            handles.ui.menu.camera.view_webcam.MenuSelectedFcn = ...
                {@Vulintus_Behavior_Set_Run_Field,...
                handles.run_state.idle_webcam_preview};                     %Set the callback for the "View Webcam" option.
        end
    end

end
    
%Update the dropdown callbacks.
if isfield(handles.ui,'drop_subject')                                       %If the GUI has a subjects drop-down menu...
    handles.ui.drop_subject.ValueChangedFcn = ...
        {@Vulintus_Behavior_Set_Run_Field,...
        handles.run_state.idle_select_subject};                             %Set the callback for the subject drop-down menu.
end
if isfield(handles.ui,'drop_stage')                                         %If the GUI has a stages drop-down menu...
    handles.ui.drop_stage.ValueChangedFcn = ...
        {@Vulintus_Behavior_Set_Run_Field,...
        handles.run_state.idle_select_stage};                               %Set the callback for the stage selection drop-down menu.
end

%Update the pause button.
if isfield(handles.ui,'btn_pause')                                          %If the GUI has a pause button...
    handles.ui.btn_pause.ButtonPushedFcn = ...
        {@Vulintus_Behavior_Set_Run_Field,...
        handles.run_state.session_pause};                                   %Set the callback for the pause button.
end

switch mode                                                                 %Switch between the different behavior program modes.

    case 'idle'                                                             %Idle mode.
        
        %Update the Start/Stop button.
        if isfield(handles.ui,'btn_start')                                  %If there's a start button.
            handles.ui.btn_start.Text = 'START';                            %Set the text on the Start/Stop button.
            handles.ui.btn_start.FontColor = [0 0.5 0];                     %Set the font color Start/Stop buttonto dark green.
            handles.ui.btn_start.ButtonPushedFcn = ...
                {@Vulintus_Behavior_Set_Run_Field,...
                handles.run_state.root.session};                            %Set the callback for the Start/Stop button.
        end

        %Enable all uicontrol objects.
        Vulintus_All_Uicontrols_Enable(handles.mainfig,'on');               %Enable all of the uicontrols.

        %Disable the pause button.
        if isfield(handles.ui,'btn_pause')                                  %If the GUI has a pause button...
            handles.ui.btn_pause.Enable = 'off';                            %Disable the pause button.
        end
        
        %Disable the trial table if unused.
        if isfield(handles.ui,'tbl_trial')                                  %If the GUI has a trial table...
            data = handles.ui.tbl_trial.Data;                               %Grab the data from the trial table.
            if isempty(data)                                                %If there's no data yet...
                handles.ui.tbl_trial.Enable = 'off';                        %Disable the trial table.
            end
        end

        %Update the manual feed buttons.
        if isfield(handles.ui,'btn_feed')                                   %If the GUI has a manual feed button.
            handles.ui.btn_feed(1).ButtonPushedFcn = ...
                {@Vulintus_Behavior_Set_Run_Field,...
                handles.run_state.idle_manual_feed_left};                   %Set the callback for the Manual Feed button (left, default).
            if length(handles.ui.btn_feed) > 1                              %If there's a second feed button...
                handles.ui.btn_right_feed.ButtonPushedFcn = ...
                    {@Vulintus_Behavior_Set_Run_Field,...
                    handles.run_state.idle_manual_feed_right};              %Set the callback for the Manual Feed button (right).
            end
        end

    case 'session'                                                          %Session mode.

        %Disable all uicontrol objects.
        Vulintus_All_Uicontrols_Enable(handles.mainfig,'off');              %Disable all of the uicontrols.

        if isfield(handles.ui,'menu')                                       %If this GUI has a menubar...

            %Update the "Camera" uimenu.
            if isfield(handles.ui.menu,'camera') && ...
                    isfield(handles.ui.menu.pref,'view_webcam') 
                handles.ui.menu.camera.h.Enable = 'on';                     %Enable the camera menu.
                handles.ui.menu.camera.view_webcam.Enable = 'on';           %Enable the "View Webcam" option.
            end
    
%             %Update the "Calibration" uimenu.
%             handles.ui.menu.cal.h.Enable = 'on';                             %Enable the calibration menu.
%             handles.ui.menu.cal.reset_baseline.MenuSelectedFcn = ...
%                 {@Vulintus_Behavior_Set_Run_Field,...
%                     handles.run_state.session_reset_baseline};              %Set the callback for the "Reset Baseline" option.
%             handles.ui.menu.cal.reset_baseline.Enable = 'on';               %Enable the "Reset Baseline" option.
%             handles.ui.menu.cal.rehome_handle.Enable = 'on';                %Enable the "Re-Home Handle" option.
%             handles.ui.menu.cal.adjust_midline.Enable = 'off';              %Disable the "Adjust Handle Home Position" option.

            %Update the "Stages" uimenu.
            if isfield(handles.ui.menu,'stages') && ...
                    isfield(handles.ui.menu.stages,'view_spreadsheet')      %If the menu has a "View Spreadsheet" option...
                handles.ui.menu.stages.h.Enable = 'on';                     %Enable the camera menu.
                handles.ui.menu.stages.view_spreadsheet.Enable = 'on';      %Enable the "View Spreadsheet" option.
            end
    
            %Update the "Preferences" uimenu.
            if isfield(handles.ui.menu,'pref')                              %If there's a preferences menu...
                handles.ui.menu.pref.h.Enable = 'on';                       %Enable the preferences menu.
                if isfield(handles.ui.menu.pref,'open_datapath')            %Preferences >> Open Data Directory        
                    handles.ui.menu.pref.open_datapath.Enable = 'on';       %Enable the "Open Datapath" option.
                end
                if isfield(handles.ui.menu.pref,'error_reports')            %Preferences >> View Error Reports
                    handles.ui.menu.pref.error_reports.Enable = 'on';       %Enable the "View Error Reports" option.
                end
                if isfield(handles.ui.menu.pref,'config_dir')               %Preferences >> Configuration Files...
                    handles.ui.menu.pref.config_dir.Enable = 'on';          %Enable the "Configuration Files..." option.
                end
            end

        end

        %Enable the trial table.
        if isfield(handles.ui,'tbl_trial')                                  %If the GUI has a trial table...              
            handles.ui.tbl_trial.Enable = 'on';                             %Enable the trial table.
            handles.ui.tbl_trial.Data = {};                                 %Clear any existing data from the trial table.
        end

        %Enable the manual feed buttons.
        if isfield(handles.ui,'btn_feed')                                   %If the GUI has a manual feed button.            
            handles.ui.btn_feed(1).ButtonPushedFcn = ...
                {@Vulintus_Behavior_Set_Run_Field,...
                handles.run_state.session_manual_feed_left};                %Set the callback for the Manual Feed button (left, default).
            if length(handles.ui.btn_feed) > 1                              %If there's a second feed button...
                handles.ui.btn_right_feed.ButtonPushedFcn = ...
                    {@Vulintus_Behavior_Set_Run_Field,...
                    handles.run_state.session_manual_feed_right};           %Set the callback for the Manual Feed button (right).
            end
            set(handles.ui.btn_feed,'Enable','on');                         %Enable all manual feed buttons.
        end
        
        %Enable the pause button.
        if isfield(handles.ui,'btn_pause')                                  %If the GUI has a pause button...
            handles.ui.btn_pause.Enable = 'on';                             %Enable the pause button.
        end
        
        %Change the Start/Stop button to stop mode.
        if isfield(handles.ui,'btn_start')                                  %If there's a start button.
            handles.ui.btn_start.Text = 'STOP';                             %Update the string on the Start/Stop button.
            handles.ui.btn_start.FontColor = [0.5 0 0];                     %Update the string on the Start/Stop button.
            handles.ui.btn_start.ButtonPushedFcn = ...
                {@Vulintus_Behavior_Set_Run_Field,...
                handles.run_state.root.idle};                               %Set the Start/Stop button callback.
            handles.ui.btn_start.Enable = 'on';                             %Enable the Start/Stop button.
        end
        
end

fig.UserData = handles;                                                     %Re-pin the handles structure to the main figure.    

drawnow;                                                                    %Immediately update the figure.