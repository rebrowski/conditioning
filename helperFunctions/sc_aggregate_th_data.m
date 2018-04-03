function [th_before th_after]=sc_aggregate_th_data(logdir)

if ~exist('logdir', 'var');
    logdir = cd;
    p_w_d = logdir;
else
    p_w_d = pwd;
    cd(logdir);
end

dirs = dir;
ss_counter = 1;

th_before = [];
th_after =[];

for d = 1:length(dirs)
    if dirs(d).isdir && isempty(strfind(dirs(d).name, '.'))
        
        cd(dirs(d).name);
        file = dir('*th_data_1*');
        load(file.name);
        data1 = data;
        
        file = dir('*th_data_2*');
        load (file.name);
        data2 = data;
        clear data;
        
        if ss_counter == 1
            th_before = data1;
            th_after = data2;
        else
            for r = 1:length(data1)
                fn = fieldnames(data1);
                for f = 1:length(fn)
                    th_before.(fn{f})(ss_counter,:) = ...
                        data1.(fn{f});
                    th_after.(fn{f})(ss_counter,:) = ...
                        data2.(fn{f});
                end
            end
        end 
        ss_counter = ss_counter + 1;
        cd ..
    end
end

cd(p_w_d);