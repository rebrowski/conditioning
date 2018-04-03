function data = sc_aggregate_data(logdir)

if ~exist('logdir', 'var')
    logdir = pwd;
    p_w_d = logdir;
else
    p_w_d = pwd;
    cd(logdir);
end

dirs = dir;
ss_counter = 1;
data = [];

for d = 1:length(dirs)
    if dirs(d).isdir && isempty(strfind(dirs(d).name, '.'))
        cd(dirs(d).name);
        
        data_ = sc_load_conditioning_data;
        
        if ss_counter == 1
            data = data_;
        else
          
            for r = 1:length(data_)
                fn = fieldnames(data_{r});
                for f = 1:length(fn)
                    % skip the fields go.. or nogo_choice_feedback_onset
                    % because they can be of unequal length between subjects 
                    if isempty(strfind( fn{f},'feedback_screen_onset'))
                        data{r}.(fn{f})(ss_counter,:) = ...
                            data_{r}.(fn{f});
                    end
                    
                end
            end 
        end
        ss_counter = ss_counter + 1;
        cd ..        
    end
end

cd(p_w_d);