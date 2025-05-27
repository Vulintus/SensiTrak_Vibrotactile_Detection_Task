function Vibrotactile_Detection_Load_Stage(behavior, varargin)

%
% Vibrotactile_Detection_Load_Stage.m - Vulintus, Inc.
%
%   VIBROTACTILE_DETECTION_LOAD_STAGE loads in the parameters for a single
%   vibrotactile detection task training/testing stage and displays the
%   stage information on the GUI.
%   
%   UPDATE LOG:
%   2025-01-21 - Drew Sloan - Function first created, adapted from
%                             Pellet_Presentation_Load_Stage.m.
%   2025-05-20 - Drew Sloan - Added debounce setting.
%

s = behavior.stage.current;                                                 %Grab the current stage index.

if isempty(behavior.session)                                                %If the behavioral session class hasn't yet been created...
    behavior.session = Vulintus_Behavior_Session_Class;                     %Create an instance of the Vulintus Behavior session class.
    behavior.session.params = behavior.program.params;                      %Copy over all default session parameters.
end

exclude_fields = {'filename','name','description','list_str'};              %List the fields that we *don't* want to copy to the session class.
stage_fields = fieldnames(behavior.stage.list)';                            %Grab the stage parameters.
for field = stage_fields                                                    %Step through each field.
    if ~any(strcmpi(field{1},exclude_fields)) && ...
            ~isempty(behavior.stage.list(s).(field{1}))                     %If this isn't a field we don't want to copy...
        behavior.session.params(1).(field{1}) = ...
            behavior.stage.list(s).(field{1}).value;                        %Save the stage setting to the session class.
    end
end

if isnt_empty_field(behavior.status,'force_filter')                         %If a filter object is alread created for the force signal...
    if isnt_empty_field(behavior.session,'params','debounce_cutoff')        %If a debounce cutoff frequency was set...
        behavior.status.force_filter.cutoff = ...
            behavior.session.params.debounce_cutoff;                        %Set the cutoff to the specified frequency...
    elseif isnt_empty_field(behavior.session,'params','debounce')           %If a debounce time was set (in milliseconds)...
        behavior.status.force_filter.cutoff = ...
            1000/behavior.session.params.debounce;                          %Set the debounce frequency based on the period.
    end
end

Vulintus_Behavior_Update_Module_Settings(behavior.ctrl,...    
    behavior.session.params, behavior.program.instance.port,...
    behavior.program.instance.sku);                                         %Update any settings on the modules.

behavior.session.fcn.stream_enable = ...
    @(enable)Vulintus_Behavior_Stream_Enable(behavior, enable,...
    behavior.ui.port);                                                      %Set the stream enable function for this instance.

behavior.session.fcn.feed = @()behavior.ctrl.feed.start();                  %Set the feeding function.

ap_dist = behavior.session.params.autopositioner_offset - ...
    behavior.session.params.pos_start;                                      %Adjust the starting autopositioner position against the offset.
behavior.ctrl.vpb.ap_dist_x.set(ap_dist);                                   %Move the module to starting position.
fprintf(1,'%s - Setting position to %1.0f mm (%1.0f)\n',...
    char(datetime,'HH:mm:ss.SSS'), behavior.session.params.pos_start, ap_dist);

behavior.session.fcn.loadcell.rebaseline = [];                              %Clear any baseline reset function.
behavior.session.fcn.haptic.mode = [];                                      %Clear any mode-setting function.
behavior.session.fcn.haptic.start = [];                                     %Clear any haptic start function.
behavior.session.fcn.haptic.stop = [];                                      %Clear any haptic stop function.
behavior.session.fcn.haptic.ipi = [];                                       %Clear any inter-pulse interval-setting function.
behavior.session.fcn.haptic.num = [];                                       %Clear any pulse number-setting function.
behavior.session.fcn.haptic.gap = [];                                       %Clear any gap-setting functions.

for port_i = 1:length(behavior.program.instance.port)                       %Step through each port.

    switch behavior.program.instance.sku{port_i}                            %Switch between the device types.

        case 'ST-VT'                                                        %Vibrotactile module.
           
            %Set the vibration train parameters on the vibrotactile module.
            behavior.session.fcn.haptic.mode = ...
                @(mode)behavior.ctrl.haptic.pulse.mode.set(mode,...
                'passthrough',port_i);                                      %Set the pulse mode-setting function.
            switch lower(behavior.session.params.task_mode)                 %Switch between the different task modes.
                case {'burst','dummy_burst'}                                %Primary burst in dummy train is the Go signal.
                    behavior.session.fcn.haptic.mode('dummy_burst');        %Set the vibration train mode.
                case {'gap','dummy_gap'}                                    %Dummy gap in primary train is the go signal.
                    behavior.session.fcn.haptic.mode('dummy_gap');          %Set the vibration train mode.
                case 'silent_burst'                                         %Primary burst in silent background is the go signal.
                    behavior.session.fcn.haptic.mode('silent_burst');       %Set the vibration train mode.
                case 'silent_gap'                                           %Silent gap in primary train is the go signal.
                    behavior.session.fcn.haptic.mode('silent_gap');         %Set the vibration train mode.
            end
            
            behavior.session.fcn.haptic.start = ...
                @()behavior.ctrl.haptic.start('passthrough',port_i);        %Set the function to start the vibration train.

            behavior.session.fcn.haptic.stop = ...
                @()behavior.ctrl.haptic.stop('passthrough',port_i);         %Set the function to stop the vibration train.

            behavior.session.fcn.haptic.ipi = ...
                @(ipi)behavior.ctrl.haptic.pulse.ipi.set(ipi,...
                'passthrough',port_i);                                      %Set the function for setting the inter-pulse interval.
            
            behavior.session.fcn.haptic.num = ...
                @(vib_n)behavior.ctrl.haptic.pulse.num.set(vib_n,...
                'passthrough',port_i);                                      %Set the function for setting the number of pulses.

            behavior.session.fcn.haptic.gap = ...
                @(a,b)behavior.ctrl.haptic.pulse.gap.set([a,b],...
                'passthrough',port_i);                                      %Set the function for setting the gap.
            
            %Rebaseline the loadcell.
            behavior.session.fcn.loadcell.rebaseline = ...
                @()behavior.ctrl.loadcell.calibration.baseline.measure('passthrough',port_i);

        case 'OT-NP'                                                        %Nosepoke module.

            % if isnt_empty_field(behavior.session.params,'present_tone') && ...
            %         strcmpi(behavior.session.params.present_tone,'on')           %If the presentation tone is turned on...
            %     behavior.session.fcn.tone.feed = ...
            %         @()behavior.ctrl.tone.on(1,...
            %         'passthrough',port_i);                                  %Set the feed tone function.
            % end

    end    
end