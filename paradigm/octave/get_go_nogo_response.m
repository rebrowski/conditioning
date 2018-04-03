function cfg = get_go_nogo_response(cfg, when)

%% variant as in Kouider 2013: only ask for go-responses and record RTs thereof
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DrawFormattedText(cfg.wPtr, '?','center', 'center', WhiteIndex(cfg.wPtr));
[VBLTimestamp, StimulusOnsetTime, FlipTimestamp, Missed, Beampos] =  Screen('Flip', cfg.wPtr, when);

t0 = StimulusOnsetTime;

cfg.data.go_nogo_screen_onset(cfg.data_counter) = StimulusOnsetTime;

keyIsDown = 0;
go_response = false;
keyCode = 0;

% wait two seconds for a go response
while ~keyIsDown && (GetSecs - t0) < 2
    [keyIsDown, time, keyCode ] = KbCheck;
    if keyIsDown 
        if find(keyCode==1) == cfg.go_button;
            t1 = time;
            go_response = true;
            if cfg.do_daq == true
                daqOut(cfg.daq, cfg.go_response_event);
            end
            if cfg.do_serial_port == true
                send_serial(cfg.port, cfg.go_response_event);
            end

            break;
        else
            % wrong button pressed
            keyIsDown = 0;
            WaitSecs(0.3);
        end
    end
end

% log the response
if go_response
    cfg.data.go_rt(cfg.data_counter) = t1-t0;
    cfg.data.go_response(cfg.data_counter) = 1;
    cfg.data.go_response_time(cfg.data_counter) = t1;
else
    cfg.data.go_rt(cfg.data_counter) = NaN;
    cfg.data.go_response(cfg.data_counter) = 0;
    cfg.data.go_response_time(cfg.data_counter) = NaN;
end    
    
%% TBD: original way as in pessiglione et al. 2008: check after some time whether go-button is pressed down
% ---------------------------------------------------------------------------------------------------
% the problem with that is that we don't get any RT-measures, especially not for no-go trials...

% [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();
% 
% if keyIsDown && keyCode == cfg.go_button
%     cfg.data.go(cfg.data_counter) = 1;
% else
%     cfg.data.go(cfg.data_counter) = 0;
% end

%% TBD: a different approach would be to press a button for both, go and no-go, and record the RTs
% ------------------------------------------------------------------------------------------

% t0 = GetSecs;
% t1 = KbWait;
% [ keyIsDown, t, r ] = KbCheck;
% response = find(r);
% if length(response)>1
%     response=response(1);
% end
% 
% while ~(response == cfg.go_button || response == cfg.nogo_button)
%     t1=KbWait([],2);
%     [ keyIsDown, t, r ] = KbCheck;
%     response = find(r);
%     if length(response)>1
%         response=response(1);
%     end
% end
% 
% rt = 1000*(t1 - t0);
% 
% if response == cfg.go_button
%     daqOut(cfg.daq, cfg.go_response_event);
%     cfg.data.go_reponse(cfg.data_counter) = 1;
%     cfg.data.go_rt = rt;
% end

%% Give Feedback which Response was made (Go/NoGo)
%%

WaitSecs(cfg.blank_before_choice_feedback_duration);

if cfg.data.go_response(cfg.data_counter) == 1
    
    DrawFormattedText(cfg.wPtr, 'GO!','center', 'center', WhiteIndex(cfg.wPtr));
    [VBLTimestamp, StimulusOnsetTime, FlipTimestamp, Missed, Beampos] =  Screen('Flip', cfg.wPtr, when);
    cfg.data.go_choice_feedback_screen_onset(cfg.data_counter)=StimulusOnsetTime;
    
    if cfg.do_daq == true
        daqOut(cfg.daq, cfg.go_choice_feedback_screen);
    end
    if cfg.do_serial_port == true
        send_serial(cfg.port, cfg.go_choice_feedback_screen);
    end

else
    
    DrawFormattedText(cfg.wPtr, 'NO.','center', 'center', WhiteIndex(cfg.wPtr));
    [VBLTimestamp, StimulusOnsetTime, FlipTimestamp, Missed, Beampos] =  Screen('Flip', cfg.wPtr, when);
    cfg.data.nogo_choice_feedback_screen_onset(cfg.data_counter)=StimulusOnsetTime;
    
    if cfg.do_daq == true
        daqOut(cfg.daq, cfg.nogo_choice_feedback_screen);
    end
    if cfg.do_serial_port == true
        send_serial(cfg.port, cfg.nogo_choice_feedback_screen);
    end
end

WaitSecs(cfg.choice_feedback_duration);

%% Give Feedback about win or loss or nothing

% GoResponse made!
if cfg.data.go_response(cfg.data_counter) == 1
    if cfg.data.condition(cfg.data_counter) == 1 % reward
        
        
        cfg.data.reward(cfg.data_counter) = 1; % this binary
        cfg.data.gain(cfg.data_counter) = cfg.reward_size; % money
				% gained in that trial
        
        cfg = update_balance(cfg);         
        
        cfg.data.rewarding_feedback_screen_onset(cfg.data_counter) = present_feedback(cfg, cfg.reward_image,GetSecs()+cfg.blank_before_reward_feedback_duration);
        if cfg.do_daq == true
            daqOut(cfg.daq, cfg.rewarding_feedback_screen);
        end
        if cfg.do_serial_port == true
            send_serial(cfg.port, cfg.rewarding_feedback_screen);
        end

    end
    if cfg.data.condition(cfg.data_counter) == 2 % punish
        
        
        cfg.data.reward(cfg.data_counter) = -1; 
        cfg.data.gain(cfg.data_counter) = -cfg.reward_size;

        % update Kontostand
        cfg = update_balance(cfg);


	cfg.data.punishing_feedback_screen_onset(cfg.data_counter) = present_feedback(cfg, cfg.punish_image,GetSecs()+cfg.blank_before_reward_feedback_duration);
        if cfg.do_daq == true
            daqOut(cfg.daq, cfg.punishing_feedback_screen);
        end
        if cfg.do_serial_port == true
            send_serial(cfg.port, cfg.punishing_feedback_screen);
        end
    end
    if cfg.data.condition(cfg.data_counter) == 3 % neutral stimulus shown -> nothing feedback
        
        cfg.data.reward(cfg.data_counter) = 0; 
        cfg.data.gain(cfg.data_counter) = 0;
        % update Kontostand
        cfg = update_balance(cfg);

        cfg.data.neutral_feedback_screen_onset(cfg.data_counter) = present_feedback(cfg, cfg.nothing_image,GetSecs()+cfg.blank_before_reward_feedback_duration);
        if cfg.do_daq == true
            daqOut(cfg.daq, cfg.neutral_feedback_screen);
        end
        if cfg.do_serial_port == true
            send_serial(cfg.port, cfg.neutral_feedback_screen);
        end
    end
    
else %nogo response made -> nothing feedback
    
    cfg.data.reward(cfg.data_counter) = 0; 
    cfg.data.gain(cfg.data_counter) = 0; % money
    cfg = update_balance(cfg);


    cfg.data.neutral_feedback_screen_onset(cfg.data_counter) = present_feedback(cfg, cfg.nothing_image,GetSecs()+cfg.blank_before_reward_feedback_duration);
    if cfg.do_daq == true
        daqOut(cfg.daq, cfg.neutral_feedback_screen);
    end
    if cfg.do_serial_port == true
        send_serial(cfg.port, cfg.neutral_feedback_screen);
    end
    
   
    
end


WaitSecs(cfg.choice_feedback_duration);
Screen('Close');




end


function cfg = update_balance (cfg)
  if cfg.data_counter > 1
     cfg.data.money(cfg.data_counter)= cfg.data.money(cfg.data_counter -1) + cfg.data.gain(cfg.data_counter);
  else
     cfg.data.money(cfg.data_counter)= cfg.data.initial_reward + cfg.data.gain(cfg.data_counter);
  end

end
