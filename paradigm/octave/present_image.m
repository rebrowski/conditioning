function StimulusOnsetTime = present_image(cfg, image, when)

texture=Screen('MakeTexture', cfg.wPtr, image);
Screen('DrawTexture', cfg.wPtr, texture);
[VBLTimestamp, StimulusOnsetTime, FlipTimestamp, Missed, Beampos] = Screen(cfg.wPtr,'Flip', when);

end