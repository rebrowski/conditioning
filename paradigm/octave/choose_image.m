function cfg = choose_image(cfg, when)

n_stimuli=cfg.n_stimuli;
imsize = 80;
mbi = 15; %margin between imagex
y_offset =0;

% cfg.rect(3): screen-width
% cfg.rect(4): screen-heigth
% m = margin, i = image:
% | ? | i | m | i | m | i | m | i | ? |
% cfg.mbi: margin between images
% cfg.imsize: height and width (rectangular)


%                 %x1     y1      x2      y2
% locations = [   0       200     100     300;
%                 150     200     250     300;
%                 300     200     400     300;
%                 450     200     550     300]';      
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
            
            
Screen('DrawTextures', cfg.wPtr, textures, [], locations);

% for i = 1:3
%     DrawFormattedText(cfg.wPtr, cfg.keymapstr(i), (x1(i)+x2(i))/2, y2(i)+15, WhiteIndex(cfg.wPtr));
% end

[VBLTimestamp, cfg.data.stimulus_choice_onset(cfg.data_counter), FlipTimestamp, Missed, Beampos] =  Screen('Flip', cfg.wPtr, when);

t0 = GetSecs;
t1 = KbWait;
[ keyIsDown, t, r ] = KbCheck;
response = find(r);

if length(response)>1
    response=response(1);
end

%while ~(response == cfg.keymap(1) || response == cfg.keymap(2) || response == cfg.keymap(3) || response == cfg.keymap(4))
while isempty(find(cfg.keymap == response))

    KbWait([],2);
    [ keyIsDown, t, r ] = KbCheck;
    response = find(r);
    if length(response)>1
        response=response(1);
    end
end

cfg.data.stim_choice_rt(cfg.data_counter) = 1000*(t1 - t0);

%%%% classifiy the image response into correct/incooret , category correct/
%%%% catgegory incorrect
button_pressed = find(cfg.keymap == find(r));
cfg.data.stim_choice_button(cfg.data_counter) = button_pressed;
cfg.data.chosen_stimulus(cfg.data_counter) = cfg.image_positions(button_pressed);
cfg.data.chosen_stim_str{cfg.data_counter} = cfg.images{cfg.image_positions(button_pressed)};

if cfg.current_stim == cfg.data.chosen_stimulus(cfg.data_counter)
    cfg.data.correct(cfg.data_counter) = 1;
else
    cfg.data.correct(cfg.data_counter) = 0;
end


%%% send a daq code
if cfg.data.correct(cfg.data_counter)
    if cfg.do_daq == true
        daqOut(cfg.daq, cfg.stim_decision_response_correct_event)
    end
    if cfg.do_serial_port == true
        send_serial(cfg.port, cfg.stim_decision_response_correct_event);
    end
else
    if cfg.do_daq == true
        daqOut(cfg.daq, cfg.stim_decision_response_incorrect_event)
    end
    if cfg.do_serial_port == true
        send_serial(cfg.port, cfg.stim_decision_response_incorrect_event);
    end
end

Screen('Close');

end
