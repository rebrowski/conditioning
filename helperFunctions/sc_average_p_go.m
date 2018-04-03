function [p_go_avg p_go_sem p_go]=sc_average_p_go(logs_dir, mode, hfacorrection)

% goes through every subjects logfile-directory and collects
% the proportion of go-responses per condition(reward/punishing)
% and run (> th @th <th <<th)

if ~exist('logs_dir', 'var')
    logs_dir = pwd;
    p_w_d = logs_dir;
else
    p_w_d = pwd;
    cd(logs_dir);
end


% mode = 0; % all data included
% mode = 1; % only use the first half of trials in each run
% mode = 2; % only use the second half of trials in each run
if ~exist('mode', 'var') || isempty(mode)
    mode = 0;
end

if ~exist('hfacorrection', 'var') || isempty(hfacorrection)
    hfacorrection = 'none';
    %hfacorrection = 'snodgrass&corwin1988';
end

dirs = dir;
ss_counter = 1;

for d = 1:length(dirs)
    if dirs(d).isdir && isempty(strfind(dirs(d).name, '.'))
        cd(dirs(d).name);
        
        data = sc_load_conditioning_data;
        
        if mode > 0
            
            for r = 1:length(data)
                fields = fieldnames(data{r});
                if mode == 1
                    from = 1;
                    to = length(data{r}.go_response)/2;
                elseif mode == 2
                    from = length(data{r}.go_response)/2 +1;
                    to = length(data {r}.go_response);
                end
                
                for i = 1:numel(fields)
                    if length(data{r}.(fields{i})) == length(data{r}.go_response)
                        data{r}.(fields{i}) = data{r}.(fields{i})(from:to);
                    end  
                end
            end
        end
        
        [data pgo] = sc_get_p_go_per_cond(data, hfacorrection);
        p_go(ss_counter,:,:) = pgo;
        
        ss_counter = ss_counter + 1;
        
        cd ..       
        
    end
end

p_go_avg = squeeze(mean(p_go));
p_go_sem = squeeze(std(p_go)./sqrt(length(p_go)));

cd(p_w_d);
end