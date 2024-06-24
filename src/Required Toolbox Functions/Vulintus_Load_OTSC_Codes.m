function serial_codes = Vulintus_Load_OTSC_Codes

%	Vulintus_Load_OTSC_Codes.m
%
%	Vulintus, Inc.
%
%	OmniTrak Serial Communication (OTSC) library.
%
%	Library documentation:
%	https://github.com/Vulintus/OmniTrak_Serial_Communication
%
%	This function was programmatically generated: 2024-06-11, 03:37:20 (UTC)
%

serial_codes = [];

serial_codes.CLEAR = 0;                            %Reset communication with the device.
serial_codes.REQ_COMM_VERIFY = 1;                  %Request verification that the connected device is using the OTSC serial code library.
serial_codes.REQ_DEVICE_ID = 2;                    %Request the device type ID number.
serial_codes.DEVICE_ID = 3;                        %Set/report the device type ID number.
serial_codes.REQ_USERSET_ALIAS = 4;                %Request the user-set name for the device.
serial_codes.USERSET_ALIAS = 5;                    %Set/report the user-set name for the device.
serial_codes.REQ_VULINTUS_ALIAS = 6;               %Request the Vulintus alias (adjective/noun serial number) for the device.
serial_codes.VULINTUS_ALIAS = 7;                   %Set/report the Vulintus alias (adjective/noun serial number) for the device.

serial_codes.REQ_MAC_ADDR = 10;                    %Request the device MAC address.
serial_codes.MAC_ADDR = 11;                        %Report the device MAC address.
serial_codes.REQ_MCU_SERIALNUM = 12;               %Request the device microcontroller serial number.
serial_codes.MCU_SERIALNUM = 13;                   %Report the device microcontroller serial number.

serial_codes.FW_FILENAME = 21;                     %Report the firmware filename.
serial_codes.REQ_FW_FILENAME = 22;                 %Request the firmware filename.
serial_codes.FW_DATE = 23;                         %Report the firmware upload date.
serial_codes.REQ_FW_DATE = 24;                     %Request the firmware upload date.
serial_codes.FW_TIME = 25;                         %Report the firmware upload time.
serial_codes.REQ_FW_TIME = 26;                     %Request the firmware upload time.

serial_codes.REQ_LIB_VER = 31;                     %Request the OTSC serial code library version.
serial_codes.LIB_VER = 32;                         %Report the OTSC serial code library version.
serial_codes.UNKNOWN_BLOCK_ERROR = 33;             %Indicate an unknown block code error.
serial_codes.ERROR_INDICATOR = 34;                 %Indicate an error and send the associated error code.

serial_codes.REQ_CUR_FEEDER = 50;                  %Request the current dispenser index.
serial_codes.CUR_FEEDER = 51;                      %Set/report the current dispenser index.
serial_codes.REQ_FEED_TRIG_DUR = 52;               %Request the current dispenser triggger duration, in milliseconds.
serial_codes.FEED_TRIG_DUR = 53;                   %Set/report the current dispenser triggger duration, in milliseconds.
serial_codes.TRIGGER_FEEDER = 54;                  %Trigger feeding on the currently-selected dispenser.
serial_codes.STOP_FEED = 55;                       %Immediately shut off any active feeding trigger.
serial_codes.DISPENSE_FIRMWARE = 56;               %Report that a feeding was automatically triggered in the device firmware.

serial_codes.MODULE_REHOME = 59;                   %Initiate the homing routine on the module.
serial_codes.HOMING_COMPLETE = 60;                 %Indicate that a module's homing routine is complete.
serial_codes.MOVEMENT_START = 61;                  %Indicate that a commanded movement has started.
serial_codes.MOVEMENT_COMPLETE = 62;               %Indicate that a commanded movement is complete.
serial_codes.MODULE_RETRACT = 63;                  %Retract the module movement to it's starting or base position.
serial_codes.REQ_TARGET_POS_MM = 64;               %Request the current target position of a module movement, in millimeters.
serial_codes.TARGET_POS_MM = 65;                   %Set/report the target position of a module movement, in millimeters.
serial_codes.REQ_CUR_POS_MM = 66;                  %Request the current  position of the module movement, in millimeters.
serial_codes.CUR_POS_MM = 67;                      %Set/report the current position of the module movement, in millimeters.
serial_codes.REQ_MIN_POS_MM = 68;                  %Request the current minimum position of a module movement, in millimeters.
serial_codes.MIN_POS_MM = 69;                      %Set/report the current minimum position of a module movement, in millimeters.
serial_codes.REQ_MAX_POS_MM = 70;                  %Request the current maximum position of a module movement, in millimeters.
serial_codes.MAX_POS_MM = 71;                      %Set/report the current maximum position of a module movement, in millimeters.
serial_codes.REQ_MIN_SPEED_MM_S = 72;              %Request the current minimum speed (i.e. motor start speed), in millimeters/second.
serial_codes.MIN_SPEED_MM_S = 73;                  %Set/report the current minimum speed (i.e. motor start speed), in millimeters/second.
serial_codes.REQ_MAX_SPEED_MM_S = 74;              %Request the current maximum speed, in millimeters/second.
serial_codes.MAX_SPEED_MM_S = 75;                  %Set/report the current maximum speed, in millimeters/second.
serial_codes.REQ_ACCEL_MM_S2 = 76;                 %Request the current movement acceleration, in millimeters/second^2.
serial_codes.ACCEL_MM_S2 = 77;                     %Set/report the current movement acceleration, in millimeters/second^2.
serial_codes.REQ_MOTOR_CURRENT = 78;               %Request the current motor current setting, in milliamps.
serial_codes.MOTOR_CURRENT = 79;                   %Set/report the current motor current setting, in milliamps.
serial_codes.REQ_MAX_MOTOR_CURRENT = 80;           %Request the maximum possible motor current, in milliamps.
serial_codes.MAX_MOTOR_CURRENT = 81;               %Set/report the maximum possible motor current, in milliamps.

serial_codes.STREAM_PERIOD = 101;                  %Set/report the current streaming period, in milliseconds.
serial_codes.REQ_STREAM_PERIOD = 102;              %Request the current streaming period, in milliseconds.
serial_codes.STREAM_ENABLE = 103;                  %Enable/disable streaming from the device.

serial_codes.AP_DIST_X = 110;                      %Set/report the autopositioner x position, in millimeters.
serial_codes.REQ_AP_DIST_X = 111;                  %Request the current autopositioner x position, in millimeters.
serial_codes.AP_ERROR = 112;                       %Indicate an autopositioning error.

serial_codes.READ_FROM_NVM = 120;                  %Read bytes from non-volatile memory.
serial_codes.WRITE_TO_NVM = 121;                   %Write bytes to non-volatile memory.
serial_codes.REQ_NVM_SIZE = 122;                   %Request the non-volatile memory size.
serial_codes.NVM_SIZE = 123;                       %Report the non-volatile memory size.

serial_codes.PLAY_TONE = 256;                      %Play the specified tone.
serial_codes.STOP_TONE = 257;                      %Stop any currently playing tone.
serial_codes.REQ_NUM_TONES = 258;                  %Request the number of queueable tones.
serial_codes.NUM_TONES = 259;                      %Report the number of queueable tones.
serial_codes.TONE_INDEX = 260;                     %Set/report the current tone index.
serial_codes.REQ_TONE_INDEX = 261;                 %Request the current tone index.
serial_codes.TONE_FREQ = 262;                      %Set/report the frequency of the current tone, in Hertz.
serial_codes.REQ_TONE_FREQ = 263;                  %Request the frequency of the current tone, in Hertz.
serial_codes.TONE_DUR = 264;                       %Set/report the duration of the current tone, in milliseconds.
serial_codes.REQ_TONE_DUR = 265;                   %Return the duration of the current tone in milliseconds.
serial_codes.TONE_VOLUME = 266;                    %Set/report the volume of the current tone, normalized from 0 to 1.
serial_codes.REQ_TONE_VOLUME = 267;                %Request the volume of the current tone, normalized from 0 to 1.

serial_codes.INDICATOR_LEDS_ON = 352;              %Set/report whether the indicator LEDs are turned on (0 = off, 1 = on).

serial_codes.CUE_LIGHT_ON = 384;                   %Turn on the specified cue light.
serial_codes.CUE_LIGHT_OFF = 385;                  %Turn off any currently-showing cue light.
serial_codes.NUM_CUE_LIGHTS = 386;                 %Report the number of queueable cue lights.
serial_codes.REQ_NUM_CUE_LIGHTS = 387;             %Request the number of queueable cue lights.
serial_codes.CUE_LIGHT_INDEX = 388;                %Set/report the current cue light index.
serial_codes.REQ_CUE_LIGHT_INDEX = 389;            %Request the current cue light index.
serial_codes.CUE_LIGHT_RGBW = 390;                 %Set/report the RGBW values for the current cue light (0-255).
serial_codes.REQ_CUE_LIGHT_RGBW = 391;             %Request the RGBW values for the current cue light (0-255).
serial_codes.CUE_LIGHT_DUR = 392;                  %Set/report the current cue light duration, in milliseconds.
serial_codes.REQ_CUE_LIGHT_DUR = 393;              %Request the current cue light duration, in milliseconds.
serial_codes.CUE_LIGHT_MASK = 394;                 %Set/report the cue light enable bitmask.
serial_codes.REQ_CUE_LIGHT_MASK = 395;             %Request the cue light enable bitmask.
serial_codes.CUE_LIGHT_QUEUE_SIZE = 396;           %Set/report the number of queueable cue light stimuli.
serial_codes.REQ_CUE_LIGHT_QUEUE_SIZE = 397;       %Request the number of queueable cue light stimuli.
serial_codes.CUE_LIGHT_QUEUE_INDEX = 398;          %Set/report the current cue light queue index.
serial_codes.REQ_CUE_LIGHT_QUEUE_INDEX = 399;      %Request the current cue light queue index.

serial_codes.CAGE_LIGHT_ON = 416;                  %Turn on the overhead cage light.
serial_codes.CAGE_LIGHT_OFF = 417;                 %Turn off the overhead cage light.
serial_codes.CAGE_LIGHT_RGBW = 418;                %Set/report the RGBW values for the overhead cage light (0-255).
serial_codes.REQ_CAGE_LIGHT_RGBW = 419;            %Request the RGBW values for the overhead cage light (0-255).
serial_codes.CAGE_LIGHT_DUR = 420;                 %Set/report the overhead cage light duration, in milliseconds.
serial_codes.REQ_CAGE_LIGHT_DUR = 421;             %Request the overhead cage light duration, in milliseconds.

serial_codes.POKE_BITMASK = 512;                   %Set/report the current nosepoke status bitmask.
serial_codes.REQ_POKE_BITMASK = 513;               %Request the current nosepoke status bitmask.
serial_codes.POKE_ADC = 514;                       %Report the current nosepoke analog reading.
serial_codes.REQ_POKE_ADC = 515;                   %Request the current nosepoke analog reading.
serial_codes.POKE_MINMAX = 516;                    %Set/report the minimum and maximum ADC values of the nosepoke infrared sensor history, in ADC ticks.
serial_codes.REQ_POKE_MINMAX = 517;                %Request the minimum and maximum ADC values of the nosepoke infrared sensor history, in ADC ticks.
serial_codes.POKE_THRESH_FL = 518;                 %Set/report the current nosepoke threshold setting, normalized from 0 to 1.
serial_codes.REQ_POKE_THRESH_FL = 519;             %Request the current nosepoke threshold setting, normalized from 0 to 1.
serial_codes.POKE_THRESH_ADC = 520;                %Set/report the current nosepoke threshold setting, in ADC ticks.
serial_codes.REQ_POKE_THRESH_ADC = 521;            %Request the current nosepoke auto-threshold setting, in ADC ticks.
serial_codes.POKE_THRESH_AUTO = 522;               %Set/report the current nosepoke auto-thresholding setting (0 = fixed, 1 = autoset).
serial_codes.REQ_POKE_THRESH_AUTO = 523;           %Request the current nosepoke auto-thresholding setting (0 = fixed, 1 = autoset).
serial_codes.POKE_RESET = 524;                     %Reset the nosepoke infrared sensor history.
serial_codes.POKE_INDEX = 525;                     %Set/report the current nosepoke index for multi-nosepoke modules.
serial_codes.REQ_POKE_INDEX = 526;                 %Request the current nosepoke index for multi-nosepoke modules.

serial_codes.LICK_BITMASK = 544;                   %Set/report the current lick sensor status bitmask.
serial_codes.REQ_LICK_BITMASK = 545;               %Request the current lick sensor status bitmask.
serial_codes.LICK_CAP = 546;                       %Report the current lick sensor capacitance reading.
serial_codes.REQ_LICK_CAP = 547;                   %Request the current lick sensor capacitance reading.
serial_codes.LICK_MINMAX = 548;                    %Set/report the minimum and maximum capacitance values of the lick sensor capacitance history.
serial_codes.REQ_LICK_MINMAX = 549;                %Request the minimum and maximum capacitance values of the lick sensor capacitance history.
serial_codes.LICK_THRESH_FL = 550;                 %Set/report the current lick sensor threshold setting, normalized from 0 to 1.
serial_codes.REQ_LICK_THRESH_FL = 551;             %Request the current lick sensor threshold setting, normalized from 0 to 1.
serial_codes.LICK_THRESH_CAP = 552;                %Set/report the current lick sensor threshold setting.
serial_codes.REQ_LICK_THRESH_CAP = 553;            %Request the current lick sensor auto-threshold setting.
serial_codes.LICK_THRESH_AUTO = 554;               %Set/report the current lick sensor auto-thresholding setting (0 = fixed, 1 = autoset <default>).
serial_codes.REQ_LICK_THRESH_AUTO = 555;           %Request the current lick sensor auto-thresholding setting (0 = fixed, 1 = autoset <default>).
serial_codes.LICK_RESET = 556;                     %Reset the lick sensor infrared capacitance history.
serial_codes.LICK_INDEX = 557;                     %Set/report the current lick sensor index for multi-lick sensor modules.
serial_codes.REQ_LICK_INDEX = 558;                 %Request the current lick sensor index for multi-lick sensor modules.
serial_codes.LICK_RESET_TIMEOUT = 559;             %Set/report the current lick sensor reset timeout duration, in milliseconds (0 = no time-out reset).
serial_codes.REQ_LICK_RESET_TIMEOUT = 560;         %Request the current lick sensor reset timeout duration, in milliseconds (0 = no time-out reset).

serial_codes.TOUCH_BITMASK = 640;                  %Set/report the current capacitive touch status bitmask.
serial_codes.REQ_TOUCH_BITMASK = 641;              %Request the current capacitive touch status bitmask.

serial_codes.REQ_THERM_PIXELS_INT_K = 768;         %Request a thermal pixel image as 16-bit unsigned integers in units of deciKelvin (dK, or Kelvin * 10).
serial_codes.THERM_PIXELS_INT_K = 769;             %Report a thermal image as 16-bit unsigned integers in units of deciKelvin (dK, or Kelvin * 10).
serial_codes.REQ_THERM_PIXELS_FP62 = 770;          %Request a thermal pixel image as a fixed-point 6/2 type (6 bits for the unsigned integer part, 2 bits for the decimal part), in units of Celcius.
serial_codes.THERM_PIXELS_FP62 = 771;              %Report a thermal pixel image as a fixed-point 6/2 type (6 bits for the unsigned integer part, 2 bits for the decimal part), in units of Celcius. This allows temperatures from 0 to 63.75 C.

serial_codes.REQ_THERM_XY_PIX = 784;               %Request the current thermal hotspot x-y position, in units of pixels.
serial_codes.THERM_XY_PIX = 785;                   %Report the current thermal hotspot x-y position, in units of pixels.

serial_codes.REQ_AMBIENT_TEMP = 800;               %Request the current ambient temperature as a 32-bit float, in units of Celsius.
serial_codes.AMBIENT_TEMP = 801;                   %Report the current ambient temperature as a 32-bit float, in units of Celsius.

serial_codes.REQ_TOF_DIST = 896;                   %Request the current time-of-flight distance reading, in units of millimeters (float32).
serial_codes.TOF_DIST = 897;                       %Report the current time-of-flight distance reading, in units of millimeters (float32).

serial_codes.VIB_DUR = 16384;                      %Set/report the current vibration pulse duration, in microseconds.
serial_codes.REQ_VIB_DUR = 16385;                  %Request the current vibration pulse duration, in microseconds.
serial_codes.VIB_IPI = 16386;                      %Set/report the current vibration train onset-to-onset inter-pulse interval, in microseconds.
serial_codes.REQ_VIB_IPI = 16387;                  %Request the current vibration train onset-to-onset inter-pulse interval, in microseconds.
serial_codes.VIB_N_PULSE = 16388;                  %Set/report the current vibration train duration, in number of pulses.
serial_codes.REQ_VIB_N_PULSE = 16389;              %Request the current vibration train duration, in number of pulses.
serial_codes.VIB_GAP_START = 16390;                %Set/report the current vibration train skipped pulses starting index.
serial_codes.REQ_VIB_GAP_START = 16391;            %Request the current vibration train skipped pulses starting index.
serial_codes.VIB_GAP_STOP = 16392;                 %Set/report the current vibration train skipped pulses stop index.
serial_codes.REQ_VIB_GAP_STOP = 16393;             %Request the current vibration train skipped pulses stop index.
serial_codes.START_VIB = 16394;                    %Immediately start the vibration pulse train.
serial_codes.STOP_VIB = 16395;                     %Immediately stop the vibration pulse train.
serial_codes.VIB_MASK_ENABLE = 16396;              %Enable/disable vibration tone masking (0 = disabled, 1 = enabled).
serial_codes.VIB_TONE_FREQ = 16397;                %Set/report the currently selected vibration masking tone's frequency, in Hz.
serial_codes.REQ_VIB_TONE_FREQ = 16398;            %Request the currently selected vibration masking tone's frequency, in Hz.
serial_codes.VIB_TONE_DUR = 16399;                 %Set/report the currently selected vibration masking tone's duration, in milliseconds.
serial_codes.REQ_VIB_TONE_DUR = 16400;             %Request the currently selected vibration masking tone's duration, in milliseconds.
serial_codes.VIB_TASK_MODE = 16401;                %Set/report the current vibration task mode (1 = BURST, 2 = GAP).
serial_codes.REQ_VIB_TASK_MODE = 16402;            %Request the current vibration task mode (1 = BURST, 2 = GAP).
serial_codes.VIB_INDEX = 16403;                    %Set/report the current vibration motor/actuator index.
serial_codes.REQ_VIB_INDEX = 16404;                %Request the current vibration motor/actuator index.

serial_codes.STAP_REQ_FORCE_VAL = 16650;           %Request the current primary force/loadcell value. DEPRECATED: Switch to REQ_PRIMARY FORCE_VAL (0xAA0A).
serial_codes.STAP_FORCE_VAL = 16651;               %Report the current force/loadcell value. DEPRECATED: Switch to PRIMARY FORCE_VAL (0xAA0B).
serial_codes.STAP_REQ_FORCE_BASELINE = 16652;      %Request the current force calibration baseline, in ADC ticks.
serial_codes.STAP_FORCE_BASELINE = 16653;          %Set/report the current force calibration baseline, in ADC ticks.
serial_codes.STAP_REQ_FORCE_SLOPE = 16654;         %Request the current force calibration slope, in grams per ADC tick.
serial_codes.STAP_FORCE_SLOPE = 16655;             %Set/report the current force calibration slope, in grams per ADC tick.
serial_codes.STAP_REQ_DIGPOT_BASELINE = 16656;     %Request the current force baseline-adjusting digital potentiometer setting.
serial_codes.STAP_DIGPOT_BASELINE = 16657;         %Set/report the current force baseline-adjusting digital potentiometer setting.

serial_codes.STAP_STEPS_PER_ROT = 16665;           %Set/report the number of steps per full revolution for the stepper motor.
serial_codes.STAP_REQ_STEPS_PER_ROT = 16666;       %Return the current number of steps per full revolution for the stepper motor.

serial_codes.STAP_MICROSTEP = 16670;               %Set/report the microstepping multiplier.
serial_codes.STAP_REQ_MICROSTEP = 16671;           %Request the current microstepping multiplier.
serial_codes.CUR_POS = 16672;                      %Set/report the target/current handle position, in micrometers.
serial_codes.REQ_CUR_POS = 16673;                  %Request the current handle position, in micrometers.
serial_codes.MIN_SPEED = 16674;                    %Set/report the minimum movement speed, in micrometers/second.
serial_codes.REQ_MIN_SPEED = 16675;                %Request the minimum movement speed, in micrometers/second.
serial_codes.MAX_SPEED = 16676;                    %Set/report the maximum movement speed, in micrometers/second.
serial_codes.REQ_MAX_SPEED = 16677;                %Request the maximum movement speed, in micrometers/second.
serial_codes.RAMP_N = 16678;                       %Set/report the cosine ramp length, in steps.
serial_codes.REQ_RAMP_N = 16679;                   %Request the cosine ramp length, in steps.
serial_codes.PITCH_CIRC = 16680;                   %Set/report the driving gear pitch circumference, in micrometers.
serial_codes.REQ_PITCH_CIRC = 16681;               %Request the driving gear pitch circumference, in micrometers.
serial_codes.CENTER_OFFSET = 16682;                %Set/report the center-to-slot detector offset, in micrometers.
serial_codes.REQ_CENTER_OFFSET = 16683;            %Request the center-to-slot detector offset, in micrometers.

serial_codes.TRIAL_SPEED = 16688;                  %Set/report the trial movement speed, in micrometers/second.
serial_codes.REQ_TRIAL_SPEED = 16689;              %Request the trial movement speed, in micrometers/second.
serial_codes.RECENTER = 16690;                     %Rapidly re-center the handle to the home position state.
serial_codes.RECENTER_COMPLETE = 16691;            %Indicate that the handle is recentered.

serial_codes.SINGLE_EXCURSION = 16705;             %Select excursion type:  direct single motion (L/R)
serial_codes.INCREASING_EXCURSION = 16706;         %Select excursion type:  deviation increase from midline
serial_codes.DRIFTING_EXCURSION = 16707;           %Select excursion type:  R/L motion with a net direction
serial_codes.SELECT_TEST_DEV_DEG = 16708;          %Set deviation degrees:  used in mode 65, 66 and 67
serial_codes.SELECT_BASE_DEV_DEG = 16709;          %Set the baseline rocking: used in mode 66 and 67
serial_codes.SELECT_SYMMETRY = 16710;              %Sets oscillation around midline or from mindline
serial_codes.SELECT_ACCEL = 16711;
serial_codes.SET_EXCURSION_TYPE = 16712;           %Set the excursion type (49 = simple movement, 50 = wandering wobble)
serial_codes.GET_EXCURSION_TYPE = 16713;           %Get the current excurion type.

serial_codes.CUR_DEBUG_MODE = 25924;               %Report the current debug mode ("Debug_ON_" or "Debug_OFF");

serial_codes.TOGGLE_DEBUG_MODE = 25956;            %Toggle OTSC debugging mode (type "db" in a serial monitor).

serial_codes.REQ_PRIMARY_FORCE_VAL = 43530;        %Request the current primary force/loadcell value.
serial_codes.PRIMARY_FORCE_VAL = 43531;            %Report the current force/loadcell value.
serial_codes.REQ_FORCE_BASELINE = 43532;           %Request the current force calibration baseline, in ADC ticks.
serial_codes.FORCE_BASELINE = 43533;               %Set/report the current force calibration baseline, in ADC ticks.
serial_codes.REQ_FORCE_SLOPE = 43534;              %Request the current force calibration slope, in grams per ADC tick.
serial_codes.FORCE_SLOPE = 43535;                  %Set/report the current force calibration slope, in grams per ADC tick.
serial_codes.REQ_DIGPOT_BASELINE = 43536;          %Request the current force baseline-adjusting digital potentiometer setting.
serial_codes.DIGPOT_BASELINE = 43537;              %Set/report the current force baseline-adjusting digital potentiometer setting.

serial_codes.STEPS_PER_ROT = 43545;                %Set/report the number of steps per full revolution for the stepper motor.
serial_codes.REQ_STEPS_PER_ROT = 43546;            %Return the current number of steps per full revolution for the stepper motor.

serial_codes.MICROSTEP = 43550;                    %Set/report the microstepping multiplier.
serial_codes.REQ_MICROSTEP = 43551;                %Request the current microstepping multiplier.

serial_codes.NUM_PADS = 43560;                     %Set/report the number of texture positions on the carousel disc.
serial_codes.REQ_NUM_PADS = 43561;                 %Request the number of texture positions on the carousel disc.

serial_codes.CUR_PAD_I = 43570;                    %Set/report the current texture position index.
serial_codes.REQ_CUR_PAD_I = 43571;                %Return the current texture position index.
serial_codes.PAD_LABEL = 43572;                    %Set/report the current position label.
serial_codes.REQ_PAD_LABEL = 43573;                %Return the current position label.
serial_codes.ROTATE_CW = 43574;                    %Rotate one position clockwise (viewed from above).
serial_codes.ROTATE_CCW = 43575;                   %Rotate one position counter-clockwise (viewed from above).

serial_codes.VOLTAGE_IN = 43776;                   %Report the current input voltage to the device.
serial_codes.REQ_VOLTAGE_IN = 43777;               %Request the current input voltage to the device.
serial_codes.CURRENT_IN = 43778;                   %Report the current input current to the device, in milliamps.
serial_codes.REQ_CURRENT_IN = 43779;               %Request the current input current to the device, in milliamps.

serial_codes.COMM_VERIFY = 43981;                  %Verify use of the OTSC serial code library, responding to a REQ_COMM_VERIFY block.

serial_codes.PASSTHRU_DOWN = 48350;                %Route the immediately following block downstream to the specified port or VPB device.
serial_codes.PASSTHRU_UP = 48351;                  %Route the immediately following block upstream, typically to the controller or computer.
serial_codes.PASSTHRU_HOLD = 48352;                %Route all following blocks to the specified port or VPB device until the serial line is inactive for a set duration.
serial_codes.PASSTHRU_HOLD_DUR = 48353;            %Set/report the timeout duration for a passthrough hold, in milliseconds.
serial_codes.REQ_PASSTHRU_HOLD_DUR = 48354;        %Request the timeout duration for a passthrough hold, in milliseconds.

serial_codes.REQ_OTMP_IOUT = 48368;                %Request the OmniTrak Module Port (OTMP) output current for the specified port, in milliamps.
serial_codes.OTMP_IOUT = 48369;                    %Report the OmniTrak Module Port (OTMP) output current for the specified port, in milliamps.
serial_codes.REQ_OTMP_ACTIVE_PORTS = 48370;        %Request a bitmask indicating which OmniTrak Module Ports (OTMPs) are active based on current draw.
serial_codes.OTMP_ACTIVE_PORTS = 48371;            %Report a bitmask indicating which OmniTrak Module Ports (OTMPs) are active based on current draw.
serial_codes.REQ_OTMP_HIGH_VOLT = 48372;           %Request the current high voltage supply setting for the specified OmniTrak Module Port (0 = off <default>, 1 = high voltage enabled).
serial_codes.OTMP_HIGH_VOLT = 48373;               %Set/report the current high voltage supply setting for the specified OmniTrak Module Port (0 = off <default>, 1 = high voltage enabled).
serial_codes.REQ_OTMP_OVERCURRENT = 48374;         %Request a bitmask indicating which OmniTrak Module Ports (OTMPs) are in overcurrent shutdown.
serial_codes.OTMP_OTMP_OVERCURRENT = 48375;        %Report a bitmask indicating which OmniTrak Module Ports (OTMPs) are in overcurrent shutdown.

serial_codes.BROADCAST_OTMP = 48586;               %Route the immediately following block to all available OmniTrak Module Ports (RJ45 jacks).
