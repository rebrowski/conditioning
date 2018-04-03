function [data out]=sc_get_p_go_per_cond(data, hfacorrection)

if ~exist('hfacorrection', 'var') || isempty(hfacorrection)
    hfacorrection == 'none'; 
    %hfacorrcetion = 'snodgrass&corwin1988';
end
verbose = false;

% probability of a go-response for rewarding and punishing stimuli
% assuming that data contains data from multiple runs:
% in sc-pilot out is a 4(threshold-level/run)x2 (condition(r vs p)) matrix
       
% overall: 
    for r = 1:length(data)
        
        if strcmp(hfacorrection, 'snodgrass&corwin1988')
            data{r}.prob_go_rewarding = (sum(data{r}.condition == 1 & data{r}.go_response ...
                                            == 1)+0.5)/ (sum(data{r}.condition==1)+1);
            data{r}.prob_go_punishing = (sum(data{r}.condition == 2 & data{r}.go_response ...
                                            == 1)+0.5)/ (sum(data{r}.condition==2)+1);
            
        else
            
            data{r}.prob_go_rewarding = sum(data{r}.condition == 1 & data{r}.go_response ...
                                            == 1)/ sum(data{r}.condition==1);
            data{r}.prob_go_punishing = sum(data{r}.condition == 2 & data{r}.go_response ...
                                            == 1)/ sum(data{r}.condition==2);
            
            if data{r}.prob_go_rewarding == 0
                data{r}.prob_go_rewarding = 0.01;
            end
            if data{r}.prob_go_rewarding == 1;
                data{r}.prob_go_rewarding = 0.99;
            end
            if data{r}.prob_go_punishing == 0
                data{r}.prob_go_punishing = 0.01;
            end
            if data{r}.prob_go_punishing == 1; 
                data{r}.prob_go_punishing = 0.01;
            end
        end

        out(r,1) = data{r}.prob_go_rewarding;            
        out(r,2) = data{r}.prob_go_punishing;
        
    end

    if verbose
        disp(sprintf('using %s to correct hits and fas', hfacorrection))
    end

    
end