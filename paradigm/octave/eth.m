function eth(subject,logs_dir, run, n_trials_per_stimulus)

%% this script estimates thresholds using the QUEST procedure for eight
%% images (for now)

more off;

% save date_time at the beginning
formatOut = 'dd-mmmm-yyyy_HH-MM-SS';
date_time = datestr(now,formatOut);

if nargin < 3
  run = 1; % we do only one run here for now...
end
if nargin < 4
  n_trials_per_stimulus = 32;
end

% run script from where it resides!!
stimuli_dir=strcat(cd,filesep,'stimuli', filesep);

addpath(genpath(cd)); % add palmedes toolbox to the path


%% SETUP

cfg.subject = subject;
cfg.run = run;
cfg.windowed_mode = 0;
cfg.do_daq = false;
cfg.do_serial_port = false;
cfg.keys_to_use = 'keyboard' % could also be set to 'numpad' 

subj_awareness = {'gesehen', 'nicht gesehen'};

% pictures
img_extension = '.jpg';

cfg.images = {'briefcase', 'bucket','cap', 'chicken', 'fish', 'kiwi', 'pear', 'shoe'};

if run < 2
    % randomize image-order
    k = randperm(length(cfg.images));
    for s = 1:length(cfg.images)
        images_(s) = cfg.images(k(s));
    end
    cfg.images = images_;
    clear images_

else
    % if this is the second run, load the stimulus-order used in the first run
    filename = ls(strcat(logs_dir, filesep, '*thresholds_1*'));
    load(filename);
    cfg.images = thresholds.image;
    
    thresholds_run1=thresholds;
    clear thresholds;
    
    thresholds_run1.image = thresholds_run1.image(3:8);
    thresholds_run1.th_noise_variance = thresholds_run1.th_noise_variance(3:8);
    thresholds_run1.th_stim_instensities_pal = thresholds_run1.th_stim_instensities_pal(3:8);

end

% exclude the images that will be shown/were shown clearly visible in the
% sc-experiment from threshold estimation
above_th_images{1} = cfg.images{1};
above_th_images{2} = cfg.images{2};
cfg.images = cfg.images(3:end);

% load picture stimuli
for s = 1 : length(cfg.images)
    cfg.imdata{s}=imread (strcat(stimuli_dir, cfg.images{s}, img_extension));
end

% show all images to choose from which was shown
cfg.mbi = 15; %margin between images
cfg.imsize = 80; % height and width (rectangular)

% number of trials params
if nargin < 3
    n_trials_per_stimulus = 32; %usually: 28, make it divisible by 4;
end
n_stimuli = length(cfg.images);
cfg.n_stimuli = n_stimuli;
n_trials = length(cfg.images) * n_trials_per_stimulus;

%QUEST parameters
max_noise = 2.5; % maximum noise, was 2.5 for the first patient
min_noise = 0.0; % no noise

xMin_pal = min_noise; % minimal stimulus intensity for palmedes
xMax_pal = max_noise; % max intensity palmedes

step_size = 0.1;
lambda = 0.05; % lapse rate
beta = 0.5; % slope
gamma = 1/n_stimuli; % guess rate

% screen paramters
currentScreen = 0;

% setup.m usually writes a variable to a file, whether the
% ptb-scripts should be run in windowed mode or not

origin = [800 400]; % only used in windowed mode

% open a screen
if cfg.windowed_mode
    screen_size = [800 600];
    [cfg.wPtr,cfg.rect]= Screen('OpenWindow', currentScreen, [], [  origin(1) ...
        origin(2) ...
        origin(1) + screen_size(1) ...
        origin(2) + screen_size(2)]);
    
else
    [cfg.wPtr,cfg.rect]= Screen('OpenWindow', currentScreen);
    screen_size = [cfg.rect(3), cfg.rect(4)];
    HideCursor;
end;

screen_center = [screen_size(1)/2, screen_size(2)/2];

cfg.white = WhiteIndex(currentScreen);
cfg.black = BlackIndex(currentScreen);

% check monitor refresh rate

if Screen('NominalFrameRate', cfg.wPtr) > 61 || ...
        Screen('NominalFrameRate', cfg.wPtr) < 59
    disp('Wrong Refresh Rate Setting, set to 60Hz...');
    sca;
    return;
end;

% timing
cfg.fixation_duration = 0.292;
cfg.jitter = 1; % jitter the duration of fixation-point?
cfg.jitter_min = 0.3;
cfg.jitter_max = 0.8;

cfg.forward_mask_duration = 0.159;
cfg.stimulus_duration = 0.059;
cfg.backward_mask_duration = 0.159;
cfg.blank_duration = 0.992;


% Keyboard Stuff
%%%%%%%%%%%%%%%%
KbName('UnifyKeyNames');

if strfind(cfg.keys_to_use, 'keyboard')>0
    % keys 1 to 8 on the keyboard above the letter-keys
    keys = {'1!','2@', '3#', '4$', '5%', '6^', '7&', '8*'};
    
    cfg.seen_button_str = '1!';
    cfg.unseen_button_str = '0)';

else
    % keys 1 to 8 on the numberpad
    keys =  {'1','2', '3', '4', '5', '6', '7', '8'};
    
    cfg.seen_button_str = '1';
    cfg.unseen_button_str = '0';

end

for i = 1:n_stimuli
    eval(sprintf('%s%d%s%s%s', 'k', i, '=KbName(''',keys{i},''');'));
    cfg.keymap(i) = eval(sprintf('%s%d', 'k', i));
    cfg.keymapstr(i) = num2str(i);
end

cfg.image_positions = 1:n_stimuli;  % stimulus index

cfg.seen_button = KbName(cfg.seen_button_str);
cfg.unseen_button = KbName(cfg.unseen_button_str);
cfg.seen_button_str = '1';
cfg.unseen_button_str = '0';

cfg.seen_instruction_l=subj_awareness{1};
cfg.seen_instruction_r=subj_awareness{2};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define/ Load Fixtion Spot ans Masks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% define fixation spot
fixation_spot_size = 10;
cfg.fixation_spot = [   screen_center(1) - fixation_spot_size, ...
    screen_center(2) - fixation_spot_size, ...
    screen_center(1) + fixation_spot_size, ...
    screen_center(2) + fixation_spot_size];

% load left oriented masks
img_extension = '.jpg';
for i=1:3
    l_masks{i}=imread( strcat (stimuli_dir, 'l_mask_', num2str(i), '_320x320', img_extension));
end
% load right-oriented masks
for i=1:3
    r_masks{i}=imread( strcat (stimuli_dir, 'r_mask_', num2str(i), '_320x320', img_extension));
end
cfg.masks = {l_masks; r_masks};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Setup PALMEDES Toolbox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cfg.PMs=cell(n_stimuli);

for s=1:n_stimuli
    % palmedes struct for objective threshold estimation
    cfg.PMs{s}=PAL_AMRF_setupRF('xMin', xMin_pal, 'xMax', xMax_pal, ...
                                'stopCriterion', 'trials', 'stopRule', n_trials_per_stimulus, ...
                                'beta',beta, 'priorAlphaRange', xMin_pal:step_size:xMax_pal, 'gamma', gamma, 'lambda', lambda);
    cfg.PMs{s}.stimulus = cfg.images{s};
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFINE THE TRIALS FOR UPCOMING RUN%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

trial_counter = 1;

for current_stim = 1:n_stimuli
    for i = 1:n_trials_per_stimulus
        
        trials{trial_counter}.stimulus_name = cfg.images{current_stim};
        trials{trial_counter}.stim_nr = current_stim;            
        
% $$$         if run < 2
% $$$             
% $$$             switch mod(i,4) % 25% visible, 75% to estimate threshold
% $$$               case 0
% $$$                 trials{trial_counter}.th = 2; % clearly visible
% $$$               case 1
% $$$                 trials{trial_counter}.th = 2; % above th
% $$$               otherwise
% $$$                 trials{trial_counter}.th = 1; % @ th
% $$$             end
% $$$             
% $$$         else
            
            switch mod(i,4) % 25% twice the noise of th, 25% 1.5
                            % times the noise of th, 25% th, 25% no noise
              case 0
                trials{trial_counter}.th = 0; % below th
              case 1
                trials{trial_counter}.th = 2; % above th
              case 2
                trials{trial_counter}.th = 1; % @ th
              case 3
                trials{trial_counter}.th = 0.5; % 1.5 threshold intensity
            end
            
            
% $$$         end
        trial_counter = trial_counter + 1;
    end
end

%Shuffle the trial-sequence
t = randperm(length(trials));
for i = 1: length (trials)
    trials_(i) = trials(t(i));
end
trials = trials_;
clear trials_;


%% daq
% event codes:
cfg.fix_event                   = 1;        % fixation onset
cfg.fmask_event                 = 2;        % forward mask onset
cfg.bmask_event                 = 3;        % backward mask onset
cfg.blank_event                 = 4;        % blank onset
cfg.stim_decision_event         = 5;        % category decision instruction onset
cfg.stim_decision_response_correct_event  = 6;        % category decision correct
cfg.stim_decision_response_incorrect_event= 7;        % category decision incorrect
cfg.seen_decision_event         = 8;        % seen decision instruction onset
cfg.seen_response_event         = 9;        % seen response
cfg.unseen_response_event       = 10;       % unseen response
cfg.event0                      = 14;       % start of experiment (0.1 sec intervals)

% initialize daq and serial port if needed
if cfg.do_daq ==true
    cfg.daq=daqInit();
else
    cfg.daq=0;
end

if cfg.do_serial_port == true
    cfg.port_name = '/dev/ttyS0';
    cfg.port=initSerialPort(cfg.port_name);
else
    cfg.port_name='none';
    cfg.port = 0;
end



%% RUN THROUGH EXPERIMENT 

cfg.data_counter = 1;

Screen('FillRect', cfg.wPtr, BlackIndex(cfg.wPtr), cfg.rect);

% if this is matlab under debian it seems to have issues finding the font
% Screen('TextFont', cfg.wPtr,  '-adobe-times-medium-i-normal--25-180-100-100-p-125-iso8859-1');

% Usually (octave, debian), use this one:
% Screen('TextFont', cfg.wPtr, 'Helvetica');

% Display Intructions/ Response-Mapping
% draw a little instruction 
offset = 350;
linespacing = 25;

DrawFormattedText(cfg.wPtr, 'Ihnen werden Bilder schnell und zum Teil verrauscht dargeboten.' , screen_center(1)-offset,screen_center(2)-2*linespacing, WhiteIndex(cfg.wPtr));

DrawFormattedText(cfg.wPtr, 'Nachfolgend sollen Sie angeben (allenfalls auch durch Raten),' , screen_center(1)-offset,screen_center(2)-1*linespacing, WhiteIndex(cfg.wPtr));

DrawFormattedText(cfg.wPtr, 'welches es war, und ob Sie es auch tatsächlich sehen konnten -' , screen_center(1)-offset,screen_center(2), WhiteIndex(cfg.wPtr));

DrawFormattedText(cfg.wPtr, 'bzw. ob Sie raten mussten.' , screen_center(1)-offset,screen_center(2)+1*linespacing, WhiteIndex(cfg.wPtr));

Screen('Flip', cfg.wPtr);
KbWait();

%%% show images next to each other

imsize = 80;
mbi = 15; %margin between imagex
y_offset =0;

for i = 1:n_stimuli
    textures(i)=Screen('MakeTexture', cfg.wPtr, cfg.imdata{cfg.image_positions(i)});
end
s_m = (cfg.rect(3)-(n_stimuli*mbi + n_stimuli* imsize))/2; % how much space is there left of the first and right of the last image?
for i=0:n_stimuli-1
    x1(i+1) = s_m+i*imsize+i*mbi;
end
x2 = x1+imsize;
y1 = repmat((cfg.rect(4)/2)-(imsize/2)+y_offset,1,n_stimuli);
y2 = repmat((cfg.rect(4)/2)+(imsize/2)+y_offset,1,n_stimuli);
locations = [x1; y1; x2; y2];

Screen('DrawTextures', cfg.wPtr, textures, [], locations);

% draw corresponding buttons underneath
for i = 1:n_stimuli
    DrawFormattedText(cfg.wPtr, cfg.keymapstr(i), (x1(i)+x2(i))/2, y2(i)+15, WhiteIndex(cfg.wPtr));
end

Screen('Flip', cfg.wPtr);

WaitSecs(1);
% wait for a response
KbWait;

% show seen/unseen instructions
ts =  16;
ll = ts*length(cfg.seen_instruction_l);
rr = 2*ts;

DrawFormattedText(cfg.wPtr, cfg.seen_instruction_l, ...
    cfg.rect(3)/2 - ll, cfg.rect(4)/2-15, cfg.white);

DrawFormattedText(cfg.wPtr, cfg.seen_instruction_r, ...
    cfg.rect(3)/2 + rr, cfg.rect(4)/2-15, cfg.white);

% show buttons underneath
left_offset = ceil(ts*(length(cfg.seen_instruction_l)/2)+ts);
right_offset = ceil(ts*(length(cfg.seen_instruction_r)/2));

DrawFormattedText(cfg.wPtr, cfg.seen_button_str, ...
    cfg.rect(3)/2 - left_offset, cfg.rect(4)/2+15, cfg.white);

DrawFormattedText(cfg.wPtr, cfg.unseen_button_str, ...
    cfg.rect(3)/2 + right_offset, cfg.rect(4)/2+15, cfg.white);

Screen('Flip',cfg.wPtr);
% wait for a response
KbWait([],2);
KbCheck;


cfg.x_pal = 0;
cfg.x_ = 0;


%% PRACTICE RUN

if run == 0 % PRACTICE RUN, only a few trials
    for i = 1:n_trials_per_stimulus
        
        stim = randi(n_stimuli);
        cfg.current_stim = stim;
        cfg.stimulus = cfg.imdata{stim};
        
        if randi(2)==1 % present some with no noise
            cfg.noise_variance = 0;
            cfg.th = 2;
            
            present_trial(cfg);
            
        else % and some with noise
            cfg.noise_variance = max_noise;
            cfg.th = 0;
            
            present_trial(cfg);
            
        end        
    end
end


%% MAIN EXPERIMENT
if run > 0 % run through the first threshold-estimation run of six images
    tic
    for trial_counter = 1:length(trials)
        
        cfg.current_stim = trials{trial_counter}.stim_nr;
        cfg.th = trials{trial_counter}.th;
        cfg.stimulus = cfg.imdata{cfg.current_stim};
        
        if run == 1
            
            % get suggested stimulus intensity from palmedes
            cfg.x_pal = cfg.PMs{cfg.current_stim}.xCurrent;
            
            % reverse the suggested stimulus instensity of palmedes to account for the fact
            % that higher stimulus intensity means lower noise variance            
            cfg.x_ = xMax_pal - cfg.x_pal;
            
            switch trials{trial_counter}.th % overwrite suggestion form palmedes if indicated
              case 0 % half threshold condition
                cfg.x_ = cfg.x_ * 2; % double the noise
                if cfg.x_ > max_noise
                    cfg.x_ = max_noise;
                end
              case 2 % above threshold condition
                cfg.x_ = min_noise;
            end
            
        end
           
        if run == 2  % do nothing adaptively anymore, but just
                     % present with the intensities used during
                     % conditioning.m
            
            cfg.x_ = thresholds_run1.th_noise_variance(cfg.current_stim);
            cfg.x_pal = thresholds_run1.th_stim_instensities_pal(cfg.current_stim);
            
            if trials{trial_counter}.th == 0 % half threshold condition
                cfg.x_ = cfg.x_ * 2; % double the noise
                if cfg.x_ > max_noise
                    cfg.x_ = max_noise;
                end
            end
            
            if trials{trial_counter}.th == 2
                cfg.x_ = min_noise;
            end
            
            if trials{trial_counter}.th < 1 && trials{trial_counter}.th > 0
                cfg.x_ = cfg.x_ * 1.5;
                if cfg.x_ > max_noise
                    cfg.x_ = max_noise;
                end
            end
            
            
        end
        % update Palmedes
        % reverse the actually used stim intensity back for palmedes
        cfg.x_pal = xMax_pal - cfg.x_;    
        cfg.noise_variance = cfg.x_;
        
        cfg=present_trial(cfg);
        
        cfg.data_counter = cfg.data_counter + 1;
        Screen('Close');
    end
    
    
    % save after each run
    cfg.data.elapsed_time = toc;
    data = cfg.data;
    PMs = cfg.PMs;
    
    % save current thresholds for each image separately to be used with
    % sc.m    
    thresholds.max_noise = max_noise;
    thresholds.min_noise = min_noise;

    thresholds.xMin_pal = xMin_pal;
    thresholds.xMax_pal = xMax_pal;

    % now add the two images for the clearly viisble condition to
    % the beginning of the output array
    thresholds.image{1} = above_th_images{1};
    thresholds.image{2} = above_th_images{2};
    
    thresholds.th_noise_variance = [NaN NaN];
    thresholds.th_stim_instensities_pal = [NaN NaN];
    
    % ... and the actually measured ones after that
    for s = 1:n_stimuli
        thresholds.image{s+2} = cfg.images{s};
        
        pal_th = cfg.PMs{s}.mean;
        
        % reverse the suggested stimulus of palmedes to account for the fact
        % that higher stimulus intensity means lower noise variance
        noise_th = xMax_pal - pal_th;
        thresholds.th_noise_variance(s+2) = noise_th;
        thresholds.th_stim_instensities_pal(s+2) = cfg.PMs{s}.mean;
        
    end     
    save(strcat(logs_dir,filesep, num2str(subject), '_thresholds_', num2str(run),'_', date_time ,'.mat'), 'thresholds', '-v7');
    save(strcat(logs_dir, filesep, num2str(subject), '_eth_data_ ', num2str(run),'_', date_time ,'.mat'), 'data', '-v7');
    save(strcat(logs_dir, filesep, num2str(subject), '_PMs_', num2str(run) ,'_', date_time, '.mat'), 'PMs');

end

if cfg.do_serial_port == true
    IOPort('CloseAll');
end

Screen('CloseAll');
ShowCursor;

end


%% Subroutines

function [cfg] = present_trial(cfg)

% add noise to image
cfg.stimulus = make_noise_image(cfg.stimulus, 0, cfg.noise_variance);

% Randomly select Masks
mask_orientation = randi([1 2]);
forward_mask = cfg.masks{mask_orientation}{randi([1 3])};
if mask_orientation == 1
    mask_orientation = 2;
else
    mask_orientation = 1;
end
backward_mask = cfg.masks{mask_orientation}{randi([1 3])};

% generate daq event code for the stimulus
cfg.stim_event = cfg.current_stim * 10 + cfg.th;

% Show Fixation
if cfg.jitter > 0
    cfg.fixation_duration = cfg.jitter_min + (cfg.jitter_max-cfg.jitter_min)*rand();
end

Screen('FillOval', cfg.wPtr, cfg.white, cfg.fixation_spot);
[VBLTimestamp, cfg.data.trial_onset(cfg.data_counter), FlipTimestamp, Missed, Beampos] = Screen(cfg.wPtr,'Flip');

% send triggers
if cfg.do_daq==true
    daqOut(cfg.daq, cfg.fix_event);
end
if cfg.do_serial_port == true
    send_serial(cfg.port, cfg.fix_event);
end

% Show mask, stimulus, mask, blank
cfg.data.forward_mask_onset(cfg.data_counter) = present_image(cfg, forward_mask, cfg.data.trial_onset(cfg.data_counter) + cfg.fixation_duration);
if cfg.do_daq==true
    daqOut(cfg.daq, cfg.fmask_event);
end
if cfg.do_serial_port == true
    send_serial(cfg.port, cfg.fmask_event);
end

cfg.data.stimulus_onset(cfg.data_counter) = present_image(cfg, cfg.stimulus, cfg.data.forward_mask_onset(cfg.data_counter) + cfg.forward_mask_duration);

if cfg.do_daq==true
    daqOut(cfg.daq, cfg.stim_event);
end
if cfg.do_serial_port == true
    send_serial(cfg.port, cfg.stim_event);
end

cfg.data.backward_mask_onset(cfg.data_counter) = present_image(cfg, backward_mask, cfg.data.stimulus_onset(cfg.data_counter) + cfg.stimulus_duration);

if cfg.do_daq==true
    daqOut(cfg.daq, cfg.bmask_event);
end
if cfg.do_serial_port == true
    send_serial(cfg.port, cfg.bmask_event);
end

cfg.data.blank_onset(cfg.data_counter) = Screen(cfg.wPtr,'Flip', cfg.data.backward_mask_onset(cfg.data_counter) + cfg.backward_mask_duration);

if cfg.do_daq == true
    daqOut(cfg.daq, cfg.blank_event);
end
if cfg.do_serial_port == true
    send_serial(cfg.port, cfg.blank_event);
end
cfg = choose_image(cfg, cfg.data.blank_onset(cfg.data_counter) + cfg.blank_duration);

% get seen decision response
[cfg.data.seen_decision_onset(cfg.data_counter), cfg.data.seen_decision_response(cfg.data_counter), cfg.data.seen_decision_rt(cfg.data_counter)] ...
    = get_seen_response(cfg, GetSecs()+0.3, cfg.seen_decision_event);
% classify seen decision according to current reponse mapping
cfg.data.seen(cfg.data_counter) = classify_seen_decision(cfg, cfg.data.seen_decision_response(cfg.data_counter));

if cfg.data.seen(cfg.data_counter)
    if cfg.do_daq == true
        daqOut(cfg.daq, cfg.seen_response_event);
    end
    if cfg.do_serial_port
        send_serial(cfg.port, cfg.blank_event);
    end
else
    if cfg.do_daq == true
        daqOut(cfg.daq, cfg.unseen_response_event);
    end
    if cfg.do_serial_port == true
        send_serial(cfg.port, cfg.unseen_response_event);
    end
end

% log additional stuff
cfg.data.stim_nr(cfg.data_counter) = cfg.current_stim;
cfg.data.stim_event(cfg.data_counter) = cfg.stim_event;
cfg.data.noise_variance(cfg.data_counter) = cfg.noise_variance;
cfg.data.th(cfg.data_counter) = cfg.th;
cfg.data.subject(cfg.data_counter) = cfg.subject;
cfg.data.run(cfg.data_counter) = cfg.run;
cfg.data.seen_button(cfg.data_counter) = cfg.seen_button;
cfg.data.unseen_button(cfg.data_counter) = cfg.unseen_button;
cfg.data.presented_stim_str{cfg.data_counter} = cfg.images{cfg.current_stim};

cfg.PMs{cfg.current_stim}=PAL_AMRF_updateRF(cfg.PMs{cfg.current_stim},cfg.x_pal, cfg.data.correct(cfg.data_counter));

% add additional logging variables to the palmedes structs
i_spec = length(cfg.PMs{cfg.current_stim}.x);

% threshold type (below, @, above threshold)
cfg.PMs{cfg.current_stim}.thc_type(i_spec) = cfg.data.th(cfg.data_counter);

% session
cfg.PMs{cfg.current_stim}.run(i_spec) = cfg.run;

% noise variance (i.e., inversed stimulus intensity that
% palmedes uses
cfg.PMs{cfg.current_stim}.noise_variance(i_spec) = cfg.x_;

% responses, rts, category decision
cfg.PMs{cfg.current_stim}.response_obj(i_spec) = cfg.data.correct(cfg.data_counter);
cfg.PMs{cfg.current_stim}.response_obj_rt(i_spec) = cfg.data.stim_choice_rt(cfg.data_counter);

% responses, rts, seen decision
cfg.PMs{cfg.current_stim}.response_suj(i_spec) = cfg.data.seen(cfg.data_counter);
cfg.PMs{cfg.current_stim}.response_suj_rt(i_spec) = cfg.data.seen_decision_rt(cfg.data_counter);

end

function seen = classify_seen_decision(cfg, response)

if response == cfg.seen_button
    seen = 1;
else
    seen = 0;
end
end

function [StimulusOnsetTime, response, rt] = get_seen_response(cfg, when, daq_code)

% show seen/unseen instructions

ts =  16;
ll = ts*length(cfg.seen_instruction_l);
rr = 2*ts;

DrawFormattedText(cfg.wPtr, cfg.seen_instruction_l, ...
    cfg.rect(3)/2 - ll, cfg.rect(4)/2-15, cfg.white);

DrawFormattedText(cfg.wPtr, cfg.seen_instruction_r, ...
    cfg.rect(3)/2 + rr, cfg.rect(4)/2-15, cfg.white);

% show buttons underneath
left_offset = ceil(ts*(length(cfg.seen_instruction_l)/2)+ts);
right_offset = ceil(ts*(length(cfg.seen_instruction_r)/2));

DrawFormattedText(cfg.wPtr, cfg.seen_button_str, ...
    cfg.rect(3)/2 - left_offset, cfg.rect(4)/2+15, cfg.white);

DrawFormattedText(cfg.wPtr, cfg.unseen_button_str, ...
    cfg.rect(3)/2 + right_offset, cfg.rect(4)/2+15, cfg.white);

[VBLTimestamp, StimulusOnsetTime, FlipTimestamp, Missed, Beampos] =  Screen('Flip', cfg.wPtr, when);

t0 = GetSecs;
t1 = KbWait;
[ keyIsDown, t, r ] = KbCheck;
response = find(r);
if length(response)>1
    response=response(1);
end

while ~(response == cfg.seen_button || response == cfg.unseen_button)
    t1=KbWait([],2);
    [ keyIsDown, t, r ] = KbCheck;
    response = find(r);
    if length(response)>1
        response=response(1);
    end
end
daqOut(cfg.daq, daq_code);
rt = 1000*(t1 - t0);

end
