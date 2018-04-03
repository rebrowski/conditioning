function cfg = present_sc_trial(cfg)

%% set up things for the upcoming trial
% select stimulus and add noise to image
cfg.stimulus = make_noise_image(cfg.imdata{cfg.condition}, 0, cfg.noise_variance);

cfg.data.stim{cfg.data_counter} = cfg.images{cfg.condition};
cfg.noise_variance(cfg.data_counter) = cfg.noise_variance;

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
cfg.stim_event = cfg.condition * 10 + cfg.th;
cfg.data.stim_event(cfg.data_counter) = cfg.stim_event;

%% present things

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

%% get go/no-go response:

cfg = get_go_nogo_response(cfg, cfg.data.blank_onset(cfg.data_counter) + cfg.blank_duration);

Screen('Close');

end












