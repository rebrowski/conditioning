function output = sc_split_th_data_by_levels(data)

%%% split up data into thresholding-conditions

fields = fieldnames(data);

levels = unique(data.th);

for k = 1:length(levels)
    is{k} = find(data.th == levels(k));
end

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
