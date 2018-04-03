function [out out_mean] = sc_aggregate_per_stimulus(conditioning, ...
                                                    th1, th2)
    
    %conditioning = sc_aggregate_data(logdir);
    % [th1 th2] = sc_aggregate_th_data;
    th1 = sc_reverse_noise_variance(th1);
    th2 = sc_reverse_noise_variance(th1);

    %% fix that th-levels 0.5 and 1 are the same during th1
    is = th1.th == 0.5;
    th1.th(is) = 1;

    %% aggregate data
    % aggreate th1/2 data across stimuli, and across subjects
    stims = unique(conditioning{1}.stim);
    nsubs = size(th1.correct, 1);
    
    for s = 1:length(stims)
        for r = 2:4
            
            % initialize output vars
            out(s,r).name = stims{s};
            out(s,r).correct_pre = [];
            out(s,r).correct_r = [];
            out(s,r).correct_p = [];
            out(s,r).intensity_pre = [];
            out(s,r).intensity_r = [];
            out(s,r).intensity_p = [];
            out(s,r).subj_r = [];
            out(s,r).subj_p = [];
            out(s,r).subj_pre = [];
        
            
            for subj = 1:nsubs
                % was stimulus presented in this run of the
                % conditioning part?

                is_c = find(strcmp(conditioning{r}.stim(subj,:),stims{s}));
                
                if  length(is_c) > 0;
                    
                    % get is from th2
                    is = find(strcmp(th2.presented_stim_str(subj,:), ...
                                     stims{s}));
                    correct = th2.correct(subj,is);
                    intensity = th2.intensity(subj,is);
                    
                    
                    % was stim rewarding or punishing?
                    if conditioning{r}.condition(subj,is_c(1)) == 1
                        out(s,r).correct_r = [out(s,r).correct_r correct];
                        out(s,r).intensity_r = [out(s,r).intensity_r intensity];
                        out(s,r).subj_r = [out(s,r).subj_r repmat(subj,1,length(correct))];
                    else
                        out(s,r).correct_p = [out(s,r).correct_p correct];
                        out(s,r).intensity_p = [out(s,r).intensity_p intensity];
                        out(s,r).subj_p = [out(s,r).subj_p repmat(subj,1,length(correct))];
                    end
 
                    % get is from th1
                    is = find(strcmp(th1.presented_stim_str(subj,:), ...
                                     stims{s}));
                    correct = th1.correct(subj,is);
                    intensity = th1.intensity(subj,is);
                    
                    out(s,r).correct_pre = [out(s,r).correct_pre ...
                                        correct];
                    out(s,r).intensity_pre = [out(s,r).intensity_pre ...
                                        intensity];
                    out(s,r).subj_pre = [out(s,r).subj_pre repmat(subj,1,length(correct))];
                end
            end
        end
    end
    
    %% average across stimuli
    for r = 2:4
            out_mean(r).correct_pre = [];
            out_mean(r).correct_r = [];
            out_mean(r).correct_p = [];
            out_mean(r).intensity_pre = [];
            out_mean(r).intensity_r = [];
            out_mean(r).intensity_p = [];
            out_mean(r).subj_r = [];
            out_mean(r).subj_p = [];
            out_mean(r).subj_pre = [];
            
            fields = fieldnames(out_mean(r));
            
        for s=1:length(stims)
            for f = 1:numel(fields)            
               out_mean(r).(fields{f}) = [out_mean(r).(fields{f})  out(s,r).(fields{f})];
             end
        end
    end
    
end

                   
                                        

