function [h xs alpha_ beta_]=psychometric_curve(StimLevels,NumPos,OutOfNum, condition, ...
                              color, do_labels, do_bootstrap, Nbins, ...
                                   nperms)
    
    if ~exist('do_labels', 'var')
        do_labels = true;
    end
    
    if ~exist('do_bootstrap', 'var')
        do_bootstrap = false;
    end
    
    if ~exist('Nbins', 'var')
        Nbins = 6;
    end

    if ~exist('nperms', 'var')
        nperms = 10;
    end
    
    Alpha = 1;
    Beta = 0.5;
    Gamma = 1/6;
    Lambda = 0.005;
    
    paramsValues = [Alpha Beta Gamma Lambda];
    paramsFree = [1 1 0 0];
    
    %PF = @PAL_Gumbel;
    PF = @PAL_Weibull;
    %PF = @PAL_Logistic;
        
    [paramsValues LL exitflag output] = ...
    PAL_PFML_Fit(StimLevels,NumPos, OutOfNum, ...
    paramsValues, paramsFree, PF);
    
    
    alpha_ = paramsValues(1);
    beta_ = paramsValues(2);
    x = 0:0.1:2.5;
    %pcorrect = PAL_Gumbel(paramsValues, x);
    pcorrect = PAL_Weibull(paramsValues, x);
    h = plot(x, pcorrect, 'Color', color);
    hold on

    %% bootstrap error of estimates and plot

    if do_bootstrap       

        [SD paramsSim LLSim converged] = ...
            PAL_PFML_BootstrapParametric(StimLevels, OutOfNum, paramsValues, paramsFree, nperms, PF);
        pcorrect_pE = PAL_Weibull(paramsValues+SD, x);
        pcorrect_nE = PAL_Weibull(paramsValues-SD, x);
        
        X=[x, fliplr(x)];
        Y=[pcorrect_pE,fliplr(pcorrect_nE)];
        f=fill(X,Y,color);
        
        alpha(0.2);   
        set(f,'EdgeColor','none'),
        hold on        
    end
    
    %% do N equidistant bins of data
    %    bins = [0 0.5 1 1.5 2 2.5]
    
    if ~ischar(Nbins)
        bins = 0:2.5/(Nbins):2.5;
        for i = 1:length(bins)-1
            is = find(StimLevels >= bins(i) & StimLevels < bins(i+1));
            mean_correct(i) = mean(NumPos(is));
            sem_correct(i) = 2*std(NumPos(is))/sqrt(length(NumPos(is)));
            xs(i) = mean(StimLevels(is));
            xs_sem(i) = 2*std(StimLevels(is))/sqrt(length(StimLevels(is)));
        end    
    elseif strcmp('per_condition', Nbins)
        
        %% average over th-condition
        thlevels = unique(condition);
        
        for i = 1:length(thlevels)
            is = find(condition == thlevels(i));
            mean_correct(i) = mean(NumPos(is));
            sem_correct(i) = std(NumPos(is))/sqrt(length(NumPos(is)));
            xs(i) = mean(StimLevels(is));
            xs_sem(i) = std(StimLevels(is))/sqrt(length(StimLevels(is)));
        end



    end
    
    errorbar(xs, mean_correct, sem_correct, '*', 'Color', color);
    %errorbarxy(xs, mean_correct, xs_sem, sem_correct, {'*', ...
    %                        color, color});
        
    hold on
            
    if do_labels
        xlabel('stimulus intensity');
        ylabel('proportion correct');
    end
    
    box off
end
