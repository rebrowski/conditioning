function [out awareness_ratings] = sc_aggregate_interview_data(logdir)

    if ~exist('logdir', 'var')
        logdir = cd;
        p_w_d = logdir;
    else
        p_w_d = pwd;
        cd(logdir);
    end
    
    
    dirs = dir;
    ss_counter = 1;
    out = [];
    for d = 1:length(dirs)
        if dirs(d).isdir && isempty(strfind(dirs(d).name, '.'))
            cd(dirs(d).name);

            file = dir('*interview*');

            if length(file)>0
                load(file.name);
                
                out{ss_counter}=data;
                clear data;
                ss_counter = ss_counter + 1;
            else

                warning(sprintf('%s %s %s', ['No interview data found  ' ...
                                    'in '], dirs(d).name, '!'));
                                
                data.awareness_rating = [NaN NaN NaN NaN];
                data.age = NaN;
                data.gender = NaN;
                data.elapsed_time = NaN;
                out{ss_counter} = data;
                clear data;
                ss_counter = ss_counter + 1;
            end
            
            cd ..
        end
    end
    
    for i = 1:length(out)
        awareness_ratings(i,:) = out{i}.awareness_rating;
    end
    

    cd(p_w_d);
