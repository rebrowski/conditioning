function balance = conditioning(subject, run, initial_reward, reward_size, n_trials_per_cell, logs_dir)

%%% do the subliminal conditioning task
more off;

% save date_time at the beginning
formatOut = 'dd-mmmm-yyyy_HH-MM-SS';
date_time = datestr(now,formatOut);


cfg.subject = subject;
cfg.run = run;
cfg.initial_reward = initial_reward;
cfg.reward_size = reward_size;
cfg.do_daq = false;
cfg.do_serial_port = false;
cfg.windowed_mode = 0;

% run script from where it resides!!
stimuli_dir=strcat(cd,filesep,'stimuli', filesep);

%% load the thresholds struct (output from eth.m) for the current subject
formatOut = 'dd-mmmm-yyyy';
today_str = datestr(now,formatOut);

if nargin < 6
  logs_dir = strcat(cd, filesep, 'logs');
end
if run > 0 % 
  file = ls(strcat(logs_dir,filesep, num2str(subject), '*_thresholds*.mat'));
  load(file);
  images = thresholds.image;
  ths = thresholds.th_noise_variance;
end

%% setup some things
switch run
    case 1  % no noise
        cfg.th_str = {'>th'};
        cfg.images = images(1:2);
        cfg.thresholds = [0 0]; % thresholds have not been measured
                                % for these images
	if nargin < 5
          n_trials_per_cell = 4;
	end
        cfg.noise_factor = 0;
    case 2  % 1 * threshold noise variance
        cfg.th_str = {'@th'};
        if nargin < 5
          n_trials_per_cell = 8;
	end
        cfg.noise_factor = 1;
        cfg.images = images(3:4);
        cfg.thresholds = ths(3:4);
        
    case 3 % 1.5 * threshold noise variance
        cfg.th_str = {'<th'};     
	if nargin < 5
          n_trials_per_cell = 32;
	end
        cfg.noise_factor = 1.5;
        cfg.images = images(5:6);
        cfg.thresholds = ths(5:6);
        
    case 4 % 2 * threshold
        cfg.th_str = {'<<th'};     
        if nargin < 5
          n_trials_per_cell = 32;
	end
        cfg.noise_factor = 2;
        cfg.images = images(7:8);
        cfg.thresholds = ths(7:8);

    case 0 % practicce
        cfg.th_str = {'>th'};
	if nargin < 5
	  n_trials_per_cell = 3;
	end
	cfg.noise_factor = 0;
	cfg.images = {'clothes19', 'clothes20'};
        cfg.thresholds = [ 0 0 ];
end

%clear ths thresholds images;
r_ = randperm(2);

%1. rewarding (r)       2. punishing (p
cfg.images =    {cfg.images{r_(1)}      cfg.images{r_(2)} };
cfg.thresholds = [cfg.thresholds(r_(1)) cfg.thresholds(r_(2)) ];


%% define the upcoming trials

n_conditions = 2;       % can be 3 for all three condition (rewarding, punishing, and neutral) 
			%... you could set this to 2 if you want to ditch the neutral condition
n_thresholds = 1;       % only one value for noise-varinace is used in each run

n_trials = n_trials_per_cell * n_conditions * n_thresholds;

data.condition = [];
data.threshold = [];

for i = 1:n_conditions
    for t = 0:n_thresholds-1
        data.condition = [data.condition repmat(i,1,n_trials_per_cell)];
        data.threshold = [data.threshold repmat(t,1,n_trials_per_cell)];
    end
end

%[trials.condition; trials.threshold]

%Shuffle the trial-sequence
t = randperm(n_trials);
for i = 1: n_trials
    trials_.condition(i) = data.condition(t(i));
    trials_.threshold(i) = data.threshold(t(i));
end

% make string variables for condition, and threshold codes
cfg.condition_str = {'r', 'p', 'n'};
for i=1:n_trials
    data.condition_str{i} = cfg.condition_str{data.condition(i)};
end

data = trials_;
clear trials_;

data.subject = subject;
data.run = run;
data.th = cfg.th_str;

%% timing vars
cfg.fixation_duration = 0.292;
cfg.jitter = 1; % jitter the duration of fixation-point?
cfg.jitter_min = 0.3;
cfg.jitter_max = 0.8;

cfg.forward_mask_duration = 0.159;
cfg.stimulus_duration = 0.059;
cfg.backward_mask_duration = 0.159;
cfg.blank_duration = 0.992;
cfg.blank_before_choice_feedback_duration = 0.3;
cfg.choice_feedback_duration = 1.0;
cfg.blank_before_reward_feedback_duration = 0.3;
cfg.reward_feedback_duration = 1.5;

%% load images
img_extension = '.jpg';

for i = 1:n_conditions % r, p, n
    cfg.imdata{i}=imread (strcat(stimuli_dir, cfg.images{i}, img_extension));
end

% load masks
    % left oriented masks
for i=1:3
    l_masks{i}=imread( strcat (stimuli_dir, 'l_mask_', num2str(i), '_320x320', img_extension));
end
    % right-oriented masks
for i=1:3
    r_masks{i}=imread( strcat (stimuli_dir, 'r_mask_', num2str(i), '_320x320', img_extension));
end
cfg.masks = {l_masks; r_masks};

cfg.reward_image = imread( strcat (stimuli_dir, 'yeseuro', img_extension));
cfg.punish_image = imread( strcat (stimuli_dir, 'noeuro', img_extension));
cfg.nothing_image = imread( strcat (stimuli_dir, 'nothing', img_extension));

%% daq
% event codes:

% cfg.stim_event is generated in present_sc_trial.m: 
%       11 rewarding at th)
%       10 rewarding below th
%       21 punishing at th
%       20 rewarding below th
%       31 neutral at th
%       30 neutral below th

cfg.fix_event                               = 201;        % fixation onset
cfg.fmask_event                             = 202;        % forward mask onset
cfg.bmask_event                             = 203;        % backward mask onset
cfg.blank_event                             = 204;        % blank onset
cfg.go_nogo_screen                          = 205;        % screen with the question mark on it, waiting for a response
cfg.go_choice_feedback_screen               = 206;        % give feedback whether a go or nogo response was made
cfg.nogo_choice_feedback_screen             = 207;
cfg.rewarding_feedback_screen               = 208;        % give feedback whether there was win or loss or no change
cfg.punishing_feedback_screen               = 209;        % give feedback whether there was win or loss or no change
cfg.neutral_feedback_screen                 = 210;

cfg.go_response_event                       = 1;        
cfg.nogo_response_event                     = 2;        % category decision correct
cfg.event0                                  = 32;       % start of experiment (0.1 sec intervals)

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

%% setup ptb
% Buttons Setup
KbName('UnifyKeyNames');
cfg.go_button = KbName('space');

% Screen Setup
currentScreen = 0;
origin = [800 400]; % only used in windowed mode
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

% define fixation spot
fixation_spot_size = 10;
cfg.fixation_spot = [   screen_center(1) - fixation_spot_size, ...
    screen_center(2) - fixation_spot_size, ...
    screen_center(1) + fixation_spot_size, ...
    screen_center(2) + fixation_spot_size];
cfg.screen_center = screen_center;


%% run through experiment
% open a screen
Screen('FillRect', cfg.wPtr, BlackIndex(cfg.wPtr), cfg.rect);

% show some simple instruction
linespacing = 25;
offset = 300;
DrawFormattedText(cfg.wPtr, 'Mit einer GO-Antwort (Leertaste) können Sie entweder', screen_center(1)-offset, screen_center(2)-linespacing, WhiteIndex(cfg.wPtr));
DrawFormattedText(cfg.wPtr, sprintf('%.2f %s', cfg.reward_size,'EUR gewinnen oder verlieren.'), screen_center(1)-offset, screen_center(2), WhiteIndex(cfg.wPtr));

DrawFormattedText(cfg.wPtr, 'Erfolgt kein Tastendruck (NO-GO),', screen_center(1)-offset, screen_center(2)+2*linespacing
, WhiteIndex(cfg.wPtr));

DrawFormattedText(cfg.wPtr, 'können Sie weder gewinnen noch verlieren.', screen_center(1)-offset, screen_center(2)+3*linespacing, WhiteIndex(cfg.wPtr));



 


			
Screen('Flip', cfg.wPtr);
% wait for a response
KbWait;

% present a trial:
%%%%%%%%%%%%%%%%%%%%%%%%%

% reward condition
% ----------------
% 1. go responses is rewarded:
% cfg.condition = 1 
% cfg.condition_str = 'r'
% 
% 2. go response is punished
% cfg.condition = 2 
% cfg.condition_str = 'p'
% 
% 3. nothing happens after go response (neutral)
% cfg.condition = 3 
% cfg.condition_str = 'n'
%     
% threshold condition
% -------------------
% cfg.th = 1; % present stimulus near threshold
% cfg.th = 0; % present stimulus below (1/2) threshold


cfg.condition_str = {'r', 'p', 'n'};
cfg.data = data;
cfg.data.reward = [];
cfg.data.money = [];
cfg.data.gain = [];
cfg.data.initial_reward = cfg.initial_reward;

cfg.data.subject = subject;
cfg.data.run = run;

for t = 1:n_trials
    
    cfg.data_counter = t;
    cfg.condition = data.condition(t);
    cfg.th = data.threshold(t);
    
    cfg.noise_variance = cfg.thresholds(cfg.condition);
    if cfg.th == 0
        cfg.noise_variance = cfg.noise_variance * cfg.noise_factor;
    end
    
    %if isnan(cfg.noise_variance)
    %    cfg.noise_variance = 0;
    %end
    
    
    cfg=present_sc_trial(cfg);
    
    Screen('Close');
end


if cfg.do_serial_port == true
    IOPort('CloseAll');
end

%% 

balance = cfg.data.money(end);

%% write logs to disk
disp(strcat('Kontostand: ', num2str(cfg.data.money(n_trials))));
data = cfg.data;
formatOut = 'dd-mmmm-yyyy_HH-MM-SS';
if run > 0 % don't log the practice run
  save(strcat(logs_dir, filesep, num2str(subject), '_sc_data_run_',num2str(run),'_',date_time, '.mat'), 'data', '-v7');
end
Screen('CloseAll');
ShowCursor;

end



