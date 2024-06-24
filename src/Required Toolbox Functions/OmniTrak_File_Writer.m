function file_writer = OmniTrak_File_Writer(filename)

%
%OmniTrak_File_Writer.m - Vulintus, Inc., 2024.
%
%   OMNITRAK_FILE_WRITER opens a new *.OmniTrak format file with the
%   specified filename and passes back a function structure for writing new
%   blocks into the file.
%
%   UPDATE LOG:
%   2024-04-23 - Drew Sloan - Function first created.
%


[fid,errmsg] = fopen(filename,'w');                                         %Open the data file as a binary file for writing.
if fid == -1                                                                %If the file could not be created...
    errordlg(sprintf(['Could not create the *.OmniTrak data file '...
        'at:\n\n%s\n\nError:\n\n%s'],filename,...
        errmsg),'OmniTrak File Write Error');                               %Show an error dialog box.
end

ofbc = Load_OmniTrak_File_Block_Codes(1);                                   %Load the OmniTrak file format block code libary.

%File format verification and version.
fwrite(fid,ofbc.OMNITRAK_FILE_VERIFY,'uint16');                             %The first block of the file should equal 0xABCD to indicate a Vulintus *.OmniTrak file.
fwrite(fid,ofbc.FILE_VERSION,'uint16');                                     %The second block of the file should be the file version indicator.
fwrite(fid,ofbc.CUR_DEF_VERSION,'uint16');                                  %Write the current file version.

%File creation start time.
fwrite(fid,ofbc.CLOCK_FILE_START,'uint16');                                 %Write the file start serial date number block code.
fwrite(fid,now,'float64');                                                  %Write the current serial date number.

file_writer = struct('fid',fid,'filename',filename);                        %Initialize an OFBC file-writing structure.
file_writer.close = @()OmniTrakFileWrite_Close(fid, ofbc.CLOCK_FILE_STOP);  %Add the file-closing function.


% CUR_DEF_VERSION: 1
% OMNITRAK_FILE_VERIFY: 43981
% FILE_VERSION: 1
% MS_FILE_START: 2
% MS_FILE_STOP: 3
% SUBJECT_DEPRECATED: 4
% CLOCK_FILE_START: 6
% CLOCK_FILE_STOP: 7
% DEVICE_FILE_INDEX: 10
% NTP_SYNC: 20
% NTP_SYNC_FAIL: 21
% MS_US_CLOCK_SYNC: 22
% MS_TIMER_ROLLOVER: 23
% US_TIMER_ROLLOVER: 24

% Block code: TIME_ZONE_OFFSET = 25.
file_writer.time_zone_offset = @()OmniTrakFileWrite_WriteBlock_V1_TIME_ZONE_OFFSET(fid, ofbc.TIME_ZONE_OFFSET);

% TIME_ZONE_OFFSET_HHMM: 26
% RTC_STRING_DEPRECATED: 30
% RTC_STRING: 31
% RTC_VALUES: 32
% ORIGINAL_FILENAME: 40
% RENAMED_FILE: 41
% DOWNLOAD_TIME: 42
% DOWNLOAD_SYSTEM: 43
% INCOMPLETE_BLOCK: 50
% USER_TIME: 60
% SYSTEM_TYPE: 100

% Block code: SYSTEM_NAME = 101.
file_writer.system_name = @(str)OmniTrakFileWrite_WriteBlock_V1_Short_Character_Block(fid, ofbc.SYSTEM_NAME, str);

% SYSTEM_HW_VER: 102
% SYSTEM_FW_VER: 103
% SYSTEM_SN: 104
% SYSTEM_MFR: 105

% Block code: COMPUTER_NAME = 106.
file_writer.computer_name = @(str)OmniTrakFileWrite_WriteBlock_V1_Short_Character_Block(fid, ofbc.COMPUTER_NAME, str);

% Block code: COM_PORT = 107.
file_writer.com_port = @(str)OmniTrakFileWrite_WriteBlock_V1_Short_Character_Block(fid, ofbc.COM_PORT, str);

% DEVICE_ALIAS: 108
% PRIMARY_MODULE: 110
% PRIMARY_INPUT: 111
% SAMD_CHIP_ID: 112
% WIFI_MAC_ADDR: 120
% WIFI_IP4_ADDR: 121
% ESP8266_CHIP_ID: 122
% ESP8266_FLASH_ID: 123

% Block code: USER_SYSTEM_NAME = 130.
file_writer.userset_alias = @(str)OmniTrakFileWrite_WriteBlock_V1_Short_Character_Block(fid, ofbc.USER_SYSTEM_NAME, str);

% DEVICE_RESET_COUNT: 140

% Block code: CTRL_FW_FILENAME = 141.
file_writer.ctrl_fw_filename = @(str)OmniTrakFileWrite_WriteBlock_V1_Short_Character_Block(fid, ofbc.CTRL_FW_FILENAME, str);

% Block code: CTRL_FW_DATE = 142.
file_writer.ctrl_fw_date = @(str)OmniTrakFileWrite_WriteBlock_V1_Short_Character_Block(fid, ofbc.CTRL_FW_DATE, str);

% Block code: CTRL_FW_TIME = 143.
file_writer.ctrl_fw_time = @(str)OmniTrakFileWrite_WriteBlock_V1_Short_Character_Block(fid, ofbc.CTRL_FW_TIME, str);

% MODULE_FW_FILENAME: 144
% MODULE_FW_DATE: 145
% MODULE_FW_TIME: 146
% WINC1500_MAC_ADDR: 150
% WINC1500_IP4_ADDR: 151
% BATTERY_SOC: 170
% BATTERY_VOLTS: 171
% BATTERY_CURRENT: 172
% BATTERY_FULL: 173
% BATTERY_REMAIN: 174
% BATTERY_POWER: 175
% BATTERY_SOH: 176
% BATTERY_STATUS: 177
% FEED_SERVO_MAX_RPM: 190
% FEED_SERVO_SPEED: 191

% Block code: SUBJECT_NAME = 200.
file_writer.subject_name = @(str)OmniTrakFileWrite_WriteBlock_V1_Long_Character_Block(fid, ofbc.SUBJECT_NAME, str);

% GROUP_NAME: 201

% Block code: EXP_NAME = 300.
file_writer.exp_name = @(str)OmniTrakFileWrite_WriteBlock_V1_Long_Character_Block(fid, ofbc.EXP_NAME, str);

% TASK_TYPE: 301

% Block code: STAGE_NAME = 400.
file_writer.stage_name = @(str)OmniTrakFileWrite_WriteBlock_V1_Long_Character_Block(fid, ofbc.STAGE_NAME, str);


% Block code: STAGE_DESCRIPTION = 401.
file_writer.stage_description = @(str)OmniTrakFileWrite_WriteBlock_V1_Long_Character_Block(fid, ofbc.STAGE_DESCRIPTION, str);

% AMG8833_ENABLED: 1000
% BMP280_ENABLED: 1001
% BME280_ENABLED: 1002
% BME680_ENABLED: 1003
% CCS811_ENABLED: 1004
% SGP30_ENABLED: 1005
% VL53L0X_ENABLED: 1006
% ALSPT19_ENABLED: 1007
% MLX90640_ENABLED: 1008
% ZMOD4410_ENABLED: 1009
% AMG8833_THERM_CONV: 1100
% AMG8833_THERM_FL: 1101
% AMG8833_THERM_INT: 1102
% AMG8833_PIXELS_CONV: 1110
% AMG8833_PIXELS_FL: 1111
% AMG8833_PIXELS_INT: 1112
% HTPA32X32_PIXELS_FP62: 1113
% HTPA32X32_PIXELS_INT_K: 1114
% HTPA32X32_AMBIENT_TEMP: 1115
% HTPA32X32_PIXELS_INT12_C: 1116
% BH1749_RGB: 1120
% DEBUG_SANITY_CHECK: 1121
% BME280_TEMP_FL: 1200
% BMP280_TEMP_FL: 1201
% BME680_TEMP_FL: 1202
% BME280_PRES_FL: 1210
% BMP280_PRES_FL: 1211
% BME680_PRES_FL: 1212
% BME280_HUM_FL: 1220
% BME680_HUM_FL: 1221
% BME680_GAS_FL: 1230
% VL53L0X_DIST: 1300
% VL53L0X_FAIL: 1301
% SGP30_SN: 1400
% SGP30_EC02: 1410
% SGP30_TVOC: 1420
% MLX90640_DEVICE_ID: 1500
% MLX90640_EEPROM_DUMP: 1501
% MLX90640_ADC_RES: 1502
% MLX90640_REFRESH_RATE: 1503
% MLX90640_I2C_CLOCKRATE: 1504
% MLX90640_PIXELS_TO: 1510
% MLX90640_PIXELS_IM: 1511
% MLX90640_PIXELS_INT: 1512
% MLX90640_I2C_TIME: 1520
% MLX90640_CALC_TIME: 1521
% MLX90640_IM_WRITE_TIME: 1522
% MLX90640_INT_WRITE_TIME: 1523
% ALSPT19_LIGHT: 1600
% ZMOD4410_MOX_BOUND: 1700
% ZMOD4410_CONFIG_PARAMS: 1701
% ZMOD4410_ERROR: 1702
% ZMOD4410_READING_FL: 1703
% ZMOD4410_READING_INT: 1704
% ZMOD4410_ECO2: 1710
% ZMOD4410_IAQ: 1711
% ZMOD4410_TVOC: 1712
% ZMOD4410_R_CDA: 1713
% LSM303_ACC_SETTINGS: 1800
% LSM303_MAG_SETTINGS: 1801
% LSM303_ACC_FL: 1802
% LSM303_MAG_FL: 1803
% LSM303_TEMP_FL: 1804
% SPECTRO_WAVELEN: 1900
% SPECTRO_TRACE: 1901
% PELLET_DISPENSE: 2000
% PELLET_FAILURE: 2001
% HARD_PAUSE_START: 2011
% SOFT_PAUSE_START: 2013
% POSITION_START_X: 2020
% POSITION_MOVE_X: 2021
% POSITION_START_XY: 2022
% POSITION_MOVE_XY: 2023
% POSITION_START_XYZ: 2024
% POSITION_MOVE_XYZ: 2025
% STREAM_INPUT_NAME: 2100
% CALIBRATION_BASELINE: 2200
% CALIBRATION_SLOPE: 2201
% CALIBRATION_BASELINE_ADJUST: 2202
% CALIBRATION_SLOPE_ADJUST: 2203
% HIT_THRESH_TYPE: 2300
% SECONDARY_THRESH_NAME: 2310
% INIT_THRESH_TYPE: 2320
% REMOTE_MANUAL_FEED: 2400
% HWUI_MANUAL_FEED: 2401
% FW_RANDOM_FEED: 2402
% SWUI_MANUAL_FEED_DEPRECATED: 2403
% FW_OPERANT_FEED: 2404
% SWUI_MANUAL_FEED: 2405
% SW_RANDOM_FEED: 2406
% SW_OPERANT_FEED: 2407
% MOTOTRAK_V3P0_OUTCOME: 2500
% MOTOTRAK_V3P0_SIGNAL: 2501
% OUTPUT_TRIGGER_NAME: 2600
% VIBRATION_TASK_TRIAL_OUTCOME: 2700
% LED_DETECTION_TASK_TRIAL_OUTCOME: 2710
% LIGHT_SRC_MODEL: 2711
% LIGHT_SRC_TYPE: 2712
% STTC_2AFC_TRIAL_OUTCOME: 2720
% STTC_NUM_PADS: 2721
% MODULE_MICROSTEP: 2722
% MODULE_STEPS_PER_ROT: 2723
% MODULE_PITCH_CIRC: 2730
% MODULE_CENTER_OFFSET: 2731
% STAP_2AFC_TRIAL_OUTCOME: 2740

% Block code: FR_TASK_TRIAL = 2800.
file_writer.fr_task_trial = @(trial,session,licks)OmniTrakFileWrite_WriteBlock_V1_FR_TASK_TRIAL(fid, ofbc.FR_TASK_TRIAL, trial, session, licks);



