function StimulusOnsetTime = present_feedback(cfg, image, when)

texture=Screen('MakeTexture', cfg.wPtr, image);
Screen('DrawTexture', cfg.wPtr, texture);

text = sprintf('%s : %.2f %s', 'Kontostand', cfg.data.money(cfg.data_counter), 'EUR'); 

DrawFormattedText(cfg.wPtr, text,'center', 200, WhiteIndex(cfg.wPtr));

[VBLTimestamp, StimulusOnsetTime, FlipTimestamp, Missed, Beampos] = Screen(cfg.wPtr,'Flip', when);

end
