% run a palmedes fit and save parameters
function [Alpha Beta] = fit_curve(StimLevels, NumPos)

% intial paramter-values
    Alpha = 1;
    Beta = 0.5;
    Gamma = 1/6;
    Lambda = 0.005;
    
    paramsValues = [Alpha Beta Gamma Lambda];
    paramsFree = [1 1 0 0];
    
    %PF = @PAL_Gumbel;
    PF = @PAL_Weibull;
    %PF = @PAL_Logistic;

    OutOfNum = ones(1,length(NumPos));
    
    [paramsValues LL exitflag output] = ...
        PAL_PFML_Fit(StimLevels,NumPos, OutOfNum, ...
                     paramsValues, paramsFree, PF);

    Alpha = paramsValues(1);
    Beta = paramsValues(2);
    
end