function output = sc_split_th_data_by_stimulus(data)

%%% split up data into thresholding-conditions

stimuli = unique(data.presented_stim_str);
  
for i = 1:length(stimuli)
    is{i} = find(strcmp(data.presented_stim_str,stimuli{i}));
end

fields = fieldnames(data);

for i = 1:numel(fields)
    for k = 1:length(is)
        if length(data.(fields{i})) > 1
            output{k}.(fields{i})=data.(fields{i})(is{k});
        else
            output{k}.(fields{i}) = data.(fields{i});
        end
    end
end

end
