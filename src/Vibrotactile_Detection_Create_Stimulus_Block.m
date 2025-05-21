function stim_block = Vibrotactile_Detection_Create_Stimulus_Block(params)

%
% Vibrotactile_Detection_Task_Create_Stimulus_Block.m
% 
%   copyright 2019, Vulintus, Inc.
%
%   VIBROTACTILE_DETECTION_TASK_CREATE_STIMULUS_BLOCK creates a new 
%   randomized block of vibration pulse rates for testing with in the
%   SensiTrak Vibrotactile Detection task.
%   
%   UPDATE LOG:
%   2019-11-20 - Drew Sloan - Function first implemented.
%

if strcmpi(params.mask_vib_on,'off') && (params.silent_ratio > 0)           %If we're doing silent catch trials...
    nd = 0;                                                                 %Create a decimal place counter.
    while (floor(params.catch_prob*params.silent_ratio*10^nd) ~= ...
            params.catch_prob*params.silent_ratio*10^nd)                    %Loop until there's no additional decimals.
        nd = nd + 1;                                                        %Increment the decimal place counter.
    end
    num_trials = 10^(nd);                                                   %Calculate the number of total trials necessary to present the required proporation of catch trials.
    num_catch = params.catch_prob*params.silent_ratio*num_trials;           %Calculate the number of catch trials.
else                                                                        %Otherwise, if we're not doing silent catch trials.
    nd = 0;                                                                 %Create a decimal place counter.
    while (floor(params.catch_prob*10^nd) ~= params.catch_prob*10^nd)       %Loop until there's no additional decimals.
        nd = nd + 1;                                                        %Increment the decimal place counter.
    end
    num_trials = 10^(nd);                                                   %Calculate the number of total trials necessary to present the required proporation of catch trials.
    num_catch = params.catch_prob*num_trials;                               %Calculate the number of catch trials.
end
temp = gcd(num_trials, num_catch);                                          %Find the greatest common divisor for the two numbers.
num_trials = num_trials/temp;                                               %Reduce the number of total trials to the minimum.
num_catch = num_trials*params.catch_prob;                                   %Reduce the number of catch trials to the minimum.
nv = numel(params.vib_rates);                                               %Grab the number of vibration rates.
ng = numel(params.gap_durs);                                                %Grab the number of gap lengths.
stim_block = nan(nv*ng,2);                                                  %Create a matrix to hold the vibration rates and gap lengths.
for i = 1:nv                                                                %Step through the vibration rates.
    for j = 1:ng                                                            %Step through the gap lengths.
        stim_block(j + (i-1)*ng, 1) = params.vib_rates(i);                  %Save the vibration rate.
        stim_block(j + (i-1)*ng, 2) = params.gap_durs(j);                   %Save the gap length.
    end
end
stim_block = repmat(stim_block, num_trials, 1);                             %Create a matrix of vibration rate list copies.
catch_trials = zeros(size(stim_block,1),1);                                 %Create a same size matrix to flag trials as catch trials.
if strcmpi(params.mask_vib_on,'off') && (params.silent_ratio > 0)           %If we're doing silent catch trials...
    N = num_catch*nv*ng*params.silent_ratio;                                %Calculate the total number of silent catch trials.
    catch_trials(1:N) = 2;                                                  %Set the silent catch trials.
    catch_trials((N+1):(num_catch*nv*ng)) = 1;                              %Set the masker catch trials.
else                                                                        %Otherwise, if there's no silent catch trials.
    catch_trials(1:(num_catch*nv*ng)) = 1;                                  %Label the required number of trials as catch trials.
end
i = randperm(size(stim_block,1));                                           %Create random indices for the block.
stim_block = [stim_block(i,:), catch_trials(i)];                            %Randomize the stimulus block and add the catch trial flags as a columm