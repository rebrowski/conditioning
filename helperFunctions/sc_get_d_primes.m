function [dprimes stimnames] = sc_get_d_primes(logdir, hfacorrection)

% collect eth-data from all subjects, compute d-primes per stimulus
% and th-level and return a matrix with all data: 
% dprimes(subject,th-test,th-level,stimulus)
% stimnames(subject, th-test, stimulus)

if ~exist('logdir', 'var')
    logdir = pwd;
else
    p_w_d = pwd;
    cd(logdir);
end

if ~exist('hfacorrection', 'var')
    hfacorrection = 'snodgrass&corwin1988';
    %hfacorrection = 'none'
end


%% go through subjects directories
dirs = dir;
ss_counter = 1;
dprimes = [];

for d = 1:length(dirs)
    if dirs(d).isdir && isempty(strfind(dirs(d).name, '.'))
        cd(dirs(d).name);
        
        %% load the the data
        
        files{1} = dir('*th_data_1*');
        files{2} = dir('*th_data_2*');
        
        if length(files{1})>0 && length(files{2}) >0
            
            for th = 1:2
                load(files{th}.name);
                
                %% split data by th-levels
                bylevels=sc_split_th_data_by_levels(data);

                clear data;
                
                for i = 1:length(bylevels) % loop over th levels
                    [stim h fa] = sc_hits_fa(bylevels{i}, hfacorrection);
                    
                    hs(i,:) = h;
                    fas(i,:) = fa;
                end

                % get d-prime values for each stimulus and each condition
                for s =1:length(stim)
                    for c = 1:length(bylevels)
                        
                        dps(c,s) = dprime(hs(c,s), fas(c,s));

                    end
                end
                
                dprimes(ss_counter, th, :,:) = dps;
                stimnames{ss_counter,th} = stim;
            end
            
            ss_counter = ss_counter + 1;
        else
            warning(sprintf('%s %s %s', ['At least one threshold-chck data file is missing!' ...
                                'in '], dirs(d).name, '!'));
        end
        
        
        cd ..
    end
end

cd(p_w_d)
