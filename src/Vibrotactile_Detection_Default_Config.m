function Vibrotactile_Detection_Default_Config(behavior)

%
% Vibrotactile_Detection_Default_Config.m - Vulintus, Inc.
%
%   PELLET_PRESENTATION_DEFAULT_CONFIG loads the default configuration 
%   settings for the SensiTrak vibrotactile detection task behavior program 
%   running through the Vulintus Common Behavior framework.
%   
%   UPDATE LOG:
%   2024-11-08 - Drew Sloan - Function first created, adapted from
%                             "Pellet_Presentation_Default_Config.m".
%


if ~isfield(behavior.stage,'sync')                                          %If the stages synchronization field hasn't been created yet.
    behavior.stage.sync = struct;                                           %Create the field.
end

%Set the google spreadsheet TSV-download address.
% behavior.stage.sync.google_spreadsheet_url = ...
%     'https://docs.google.com/spreadsheets/d/e/2PACX-1vSdvthKmNrq7BF4pjP7_d96Gk7diArwOLVucWVChWB6fiCeuQykIe2kFaQDalPTjPI7bZlLpafantUX/pub?gid=0&single=true&output=tsv';                       

%Set the google spreadsheet edit URL.
% behavior.stage.sync.google_spreadsheet_edit_url = ...
%     'https://docs.google.com/spreadsheets/d/1OCK_8ckrrWsmYC3fVg9tf54YyFmOTxS_k2chZOt4jJQ/';       

%Autopositioner offset.
ap_offset = 57;
behavior.program.params.autopositioner_offset = ap_offset;
behavior.ctrl.vpb.ap_offset.set(ap_offset);
fprintf('%s - Autopositioner offset set to %1.0f mm.\n', char(datetime,'HH:mm:ss.SSS'), ap_offset);

%Minimum reach distance.
behavior.program.params.min_reach_distance = 10;

%Streaming settings for the modules.
behavior.program.params.stream_settings = struct([]);                       %Create an empty structure to hold streaming settings.
behavior.program.params.stream_settings(1).sku = 'ST-VT';                   %Vibrotactile module.
behavior.program.params.stream_settings(1).sample_period = 10000;           %Sampling period is 10,000 microseconds.
behavior.program.params.stream_settings(1).mode = 1;                        %Set the streaming mode to periodic.
behavior.program.params.stream_settings(1).chunk_size = 11;                 %Chunk size is 11 bytes (LOADCELL_VAL_GM).
behavior.program.params.stream_settings(1).chunk_timeout = 3000;            %Chunking timeout is 3 milliseconds.

%Sampling settings.
behavior.program.params.pre_trial_sampling = 0.5;                           %Pre-trial sampling period, in seconds.
behavior.program.params.post_trial_sampling = 0.1;                          %Post-trial sampling period, in seconds.

%Handling functions for all relevant incoming OTSC packets.
behavior.ctrl.stream.fcn('LOADCELL_VAL_GM') = ...
    @(src, varargin)behavior.program.fcn.process_input('LOADCELL_VAL_GM',...
    src, varargin{:});                                                      %Loadcell value in grams.
behavior.ctrl.stream.fcn('POKE_BITMASK') = ...
    @(src, varargin)behavior.program.fcn.process_input('POKE_BITMASK',...
    src, varargin{:});                                                      %Nosepoke bitmask.
behavior.ctrl.stream.fcn('CAPSENSE_VALUE') = ...
    @(src, varargin)behavior.program.fcn.process_input('CAPSENSE_VALUE',...
    src, varargin{:});                                                      %Lick sensor capacitance.
behavior.ctrl.stream.fcn('CAPSENSE_BITMASK') = ...
    @(src, varargin)behavior.program.fcn.process_input('CAPSENSE_BITMASK',...
    src, varargin{:});                                                      %Lick sensor bitmask.
behavior.ctrl.stream.fcn('DISPENSE_FIRMWARE') = ...
    @(src, varargin)behavior.program.fcn.process_input('DISPENSE_FIRMWARE',...
    src, varargin{:});                                                      %Firmware-triggered dispensing indicator.


% handles.stage_mode = 2;                                                     %Set the default stage selection mode to 2 (1 = local TSV file, 2 = Google Spreadsheet).
% handles.stage_url = ['https://docs.google.com/spreadsheets/d/e/2PACX-1v'...
%     'SfSiU9bjKvWnQ_ZF6GY5-2NK2DuFIqqdV1sAj7AWgPm8QFdydaoqnV50mK5mwQ5jTW'...
%     '66Q_s2145gcN/pub?gid=0&single=true&output=tsv'];                       %Set the google spreadsheet address.
% handles.stim = 0;                                                           %Disable stimulation by default.
% handles.positioner_offset = 48;                                             %Set the zero position offset of the autopositioner, in millimeters.
% handles.datapath = 'C:\Vulintus Data\Vibrotactile Detection Task\';         %Set the primary local data path for saving data files.
% handles.ratname = [];                                                       %Create a field to hold the rat's name.
% handles.debounce = 0;                                                       %Don't debounce the signal by default.
% handles.enable_error_reporting = 1;                                         %Enable automatic error reports by default.
% handles.err_rcpt = 'drew@vulintus.com';                                     %Automatically send any error reports to Drew Sloan.
% handles.ir_initiation_threshold = 0.20;                                     %Set the IR initiation threshold, as a proportion of the total range.
% handles.ir_detector = 'bounce';                                             %Set the IR polarity ("bounce" or "beam");
% handles.init_trig = 'off';                                                  %Turn on/off the trial initiation trigger signal.