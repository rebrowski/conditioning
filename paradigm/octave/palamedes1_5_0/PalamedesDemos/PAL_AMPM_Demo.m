%
%PAL_AMPM_Demo  Demonstrates use of Palamedes routines to implement a
%'Psi Method' adaptive procedure (Kontsevich & Tyler, 1999). User is 
%prompted to indicate whether stimuli should be placed to optimize 
%estimation of threshold and slope only (in which case a specific value for 
%the lapse rate is assumed) or whether placement should also optimize 
%estimation of the lapse rate (the latter method ('Psi+') avoids bias in 
%threshold and slope estimates that occurs when the Psi method assumes a 
%specific value of the lapse rate and data are subsequently fitted using a 
%Maximum-Likelihood method with the lapse rate freed, see Prins [2012a,b]).
%
%The program then completes a run of 120 total trials. Halfway (after 60 
%trials) run is interrupted, intermediate results are stored to disk, 
%data are cleared from memory, then reloaded from disk, and run continues 
%(as if collection of total number of trials is split among two sessions on 
%separate occassions). The posterior from first session serves as the prior 
%to second session.
%
%After each trial, program displays the posterior (in case of Psi+, it
%shows three planes [threshold x slope, threshold x lapse, and slope x
%lapse] that intersect at maximum value in the posterior). It also
%displays a plot of proportion correct as a function of stimulus intensity
%(area of symbol is proportional to proportion of stimuli presented at
%stimulus intensity). Included in this plot is the generating PF, the PF
%fitted by Bayesian method (as in Kontsevich & Tyler, 1999) and the PF
%fitted by a Maximum-Likelihood method using a free lapse rate. A third
%plot shows stimulus placement on a trial-by-trial basis.
%
%At conclusion of the 120 trials, results of the Bayesian fits are
%presented to the screen.
%
%Note that the Psi method may also be set up to optimize estimation of the
%guess rate as well (as in, for example, a yes/no task).
%
%Demonstrates usage of Palamedes functions:
%-PAL_AMPM_setupPM
%-PAL_AMPM_updatePM
%secondary:
%PAL_Gumbel
%PAL_pdfNormal
%
%More information on any of these functions may be found by typing
%help followed by the name of the function. e.g., help PAL_AMPM_setupPM
%
%References:
%
%Kontsevich, LL & Tyler, CW (1999). Bayesian adaptive estimation of
%psychometric slope and threshold. Vision Research, 39, 2729-2737.
%
%Prins, N (2012a). The psychometric function: The lapse rate revisited.
%Journal of Vision.
%
%Prins, N (2012b). The adaptive Psi method and the lapse rate. Poster
%presented at the 12th annual meeting of the Vision Sciences Society.
%http://f1000.com/posters/browse/summary/1090339
%
%NP (May 2012)

clear all;  %Clear all existing variables from memory

fprintf('\nType help PAL_AMPM_Demo for information on this demo.\n\n');

if exist('OCTAVE_VERSION','builtin');
    fprintf('\nUnder Octave, Figure does not render exactly as intended. Visit\n');
    fprintf('www.palamedestoolbox.org/demosfiguregallery.html to see figure\n');
    fprintf('as intended.\n\n');
end

disp('Placement to optimize threshold and slope only (0) or threshold, slope and lapse rate (1)?')
PsiOrPsiPlus = input('Type 0 or 1: ');

%Simulated observer's characteristics
PF = @PAL_Gumbel;
trueParams = [0 1 .5 0.03];

numTrials = 120;

%Set up Psi Method procedure:

%Specify which values to include in prior (i.e, the values to be considered for the parameters)
alphaOffset = rand(1)*.3 - .15; %Jitter prior around position centered on true values
betaOffset = rand(1)*.3 - .15;
priorAlphaRange = linspace(PF([0 1 0 0],.1,'inverse'),PF([0 1 0 0],.9999,'inverse'),41) + alphaOffset;
priorBetaRange = linspace(log10(.0625),log10(16),41) + betaOffset;
priorGammaRange = .5;

if PsiOrPsiPlus == 0
    priorLambdaRange = .03;           %Lapse Rate to be assumed
else
    priorLambdaRange = 0:0.01:.1;
end

%Define which parameters are free in Maximum Likelihood fit
freeParams = [1 1 0 1];

%Stimulus values to select from (need not be equally spaced)
stimRange = linspace(PF([0 1 0 0],.1,'inverse'),PF([0 1 0 0],.9999,'inverse'),21);

%For plotting later:
xFine = min(stimRange)-(max(stimRange)-min(stimRange))/10:.01:max(stimRange)+(max(stimRange)-min(stimRange))/10;
                            
%Define prior (optional: if no prior specified, uniform prior will be used)
[alphas betas gammas lambdas] = ndgrid(priorAlphaRange, priorBetaRange, priorGammaRange, priorLambdaRange);
prior = PAL_pdfNormal(alphas,0,3).*PAL_pdfNormal(betas,0,3).*PAL_pdfNormal(lambdas,0.05,.05);  %choice of particular prior is rather arbitrary here
prior = prior/sum(sum(sum(sum(prior))));                                   %and should not be understood to imply it is a good one.

%For plotting later
alphas = squeeze(alphas);
betas = squeeze(betas);
lambdas = squeeze(lambdas);
clear gammas;    %g is not needed for plotting

%set up Psi procedure
PM = PAL_AMPM_setupPM('priorAlphaRange',priorAlphaRange,'priorBetaRange',priorBetaRange,'priorGammaRange',...
    priorGammaRange,'priorLambdaRange',priorLambdaRange, 'numtrials',floor(numTrials/2), 'PF' , PF,...
    'stimRange',stimRange,'prior',prior);

%Create figure
if exist('OCTAVE_VERSION','builtin')
    figure;
    LabelFontSize = 12;
    AxesFontSize = 10;
else
    figure('name','Psi Method Adaptive Procedure','units','normalized','position',[.1 .1 .8 .8]);
    LabelFontSize = 16;
    AxesFontSize = 14;
end

if exist('OCTAVE_VERSION','builtin')
    h1 = axes;
    h2 = axes;
    h3 = axes;
end

%Trial loop
while PM.stop ~= 1
    
    %Present trial here at stimulus intensity PM.xCurrent and collect
    %response.
    %Here we simulate a response instead (0: incorrect, 1: correct)    

    response = rand(1) < PF(trueParams, PM.xCurrent);
    PM = PAL_AMPM_updatePM(PM,response);

    %The previous two lines suffice for the Psi Method to function properly. 
    %The following is included only for purposes of demonstration.
    
    %Group trials of equal stimulus intensity
    [StimLevels NumPos OutOfNum] = PAL_PFML_GroupTrialsbyX(PM.x(1:length(PM.x)-1),PM.response,ones(size(PM.response)));
    
    trial = length(PM.response);
    
    %The following 7 lines merely serve to compare Maximum Likelihood (ML) fit
    %to Psi method fit. 
    if trial > 20   %Perform ML fit only after some data have been collected
        searchGrid.alpha = priorAlphaRange;
        searchGrid.beta = 10.^priorBetaRange;
        searchGrid.gamma = .5;
        searchGrid.lambda = priorLambdaRange;
        params = PAL_PFML_Fit(StimLevels, NumPos, OutOfNum,searchGrid, freeParams, PF,'lapselimits',[0 1]);
    end

    %The following 12 lines may be left out: They merely serve to 
    %demonstrate how to save data and continue collecting data at a later 
    %occassion picking up where testing left off.
    if PM.stop
        save savedPM PM         %by saving PM structure all data are saved
        if trial ~= numTrials   %do this only at end of first 'session' only, not at conclusion of this demo
            clear PM            %this clears all collected data from memory
            load savedPM        %load PM structure to pick up in second session where you left off in first session

            %Supply Palamedes with PM structure of first 'session' and continue
            %where you left off.
            PM = PAL_AMPM_setupPM(PM,'numtrials',numTrials);
            PM.stop = 0;
        end
    end
    
    %Plot things....
    if exist('OCTAVE_VERSION','builtin')  
        cla(h1)
        cla(h2)
        cla(h3)
    else
        clf    
    end
    if exist('OCTAVE_VERSION','builtin')
        axes(h1)
    else
        axes
    end
    [maxim I] = PAL_findMax(PM.pdf);    %Maximum in posterior (the three planes in figure of posterior intersect here)
    if size(PM.pdf,4) > 1 
        posterior = squeeze(PM.pdf);
        posterior(alphas ~= priorAlphaRange(I(1)) & betas ~= priorBetaRange(I(2)) & lambdas ~= priorLambdaRange(I(4))) = min(min(min(posterior(alphas == priorAlphaRange(I(4)) | betas == priorBetaRange(I(2)) | lambdas == priorLambdaRange(I(4))))));
        posterior = PAL_Scale0to1(posterior);        
        slice(permute(alphas,[3 1 2]), permute(lambdas,[3 1 2]), permute(betas,[3 1 2]), permute(posterior,[3 1 2]),priorAlphaRange(I(1)),priorLambdaRange(I(4)),priorBetaRange(I(2)))        
        set(gca,'units','normalized','position',[.1 .45 .3 .5],'fontsize',AxesFontSize);
        set(gca,'xlim',[min(priorAlphaRange) max(priorAlphaRange)],'ylim',[min(priorLambdaRange) max(priorLambdaRange)],'zlim',[min(priorBetaRange) max(priorBetaRange)])
        xlabel('Log Threshold','fontsize',LabelFontSize)
        ylabel('Lapse','fontsize',LabelFontSize)
        zlabel('Log Slope','fontsize',LabelFontSize)
    else
        surf(priorAlphaRange,priorBetaRange,(squeeze(PM.pdf(:,:,1,1)')))
        view(0,90)
        set(gca,'units','normalized','position',[.1 .5 .4 .4],'fontsize',AxesFontSize);
        axis image
        xlabel('Log Threshold','fontsize',LabelFontSize);
        ylabel('Log Slope','fontsize',LabelFontSize);
    end    
        
    %Create plot of trial sequence:
    if exist('OCTAVE_VERSION','builtin')
        axes(h2)
    else
        axes
    end
    t = 1:length(PM.x)-1;
    plot(t,PM.x(1:length(t)),'k');
    hold on;
    plot(1:length(t),PM.threshold,'b-','LineWidth',2)
    plot(t(PM.response == 1),PM.x(PM.response == 1),'ko', ...
        'MarkerFaceColor','k');
    plot(t(PM.response == 0),PM.x(PM.response == 0),'ko', ...
        'MarkerFaceColor','w');
    set(gca,'FontSize',AxesFontSize);
    line([1 numTrials], [trueParams(1) trueParams(1)],'linewidth', 2,...
        'linestyle', '--', 'color','k');
    xlabel('Trial','fontsize',LabelFontSize);
    ylabel('Log Stimulus Intensity','fontsize',LabelFontSize);
    set(gca,'units','normalized','position',[.1 .1 .85 .3]);
    ylim(1) = min(stimRange)-(max(stimRange)-min(stimRange))/10;
    ylim(2) = max(stimRange)+(max(stimRange)-min(stimRange))/10;
    axis([1 numTrials ylim])
    plot(1 + (numTrials-1)/40,.9*(ylim(2)-ylim(1))+ylim(1),'ko','markerfacecolor','k')
    text(1 + (numTrials-1)/30,.9*(ylim(2)-ylim(1))+ylim(1),'correct','fontsize',AxesFontSize)
    plot(1 + (numTrials-1)/40,.8*(ylim(2)-ylim(1))+ylim(1),'ko','markerfacecolor','w')
    text(1 + (numTrials-1)/30,.8*(ylim(2)-ylim(1))+ylim(1),'incorrect','fontsize',AxesFontSize)

    %Create plot of fits
    if exist('OCTAVE_VERSION','builtin')
        axes(h3)
    else
        axes
    end
        
    plot(xFine,PF(trueParams,xFine),'color','k','linewidth',2);
    hold on
    set(gca,'units','normalized','position',[.5 .5 .45 .4]);
    plot(xFine,PF([PM.threshold(trial) 10.^PM.slope(trial) PM.guess(trial) PM.lapse(trial)],xFine),'color',[0 .7 0],'linewidth',2)
    if trial > 20
        plot(xFine,PF(params,xFine),'color',[.7 0 0],'linewidth',2);
    end
    for sl = 1:length(StimLevels)        
        markersize = 12*sqrt(OutOfNum(sl)/sum(OutOfNum))/sqrt(max(OutOfNum)/sum(OutOfNum));
        plot(StimLevels(sl),NumPos(sl)/OutOfNum(sl),'o','markersize',markersize,'color','k','markerfacecolor','k')
    end
    set(gca,'xtick',[-1:.5:1],'ylim',[0 1],'xlim',[min(stimRange)-(max(stimRange)-min(stimRange))/10 max(stimRange)+(max(stimRange)-min(stimRange))/10])
    set(gca,'fontsize',AxesFontSize)
    text(0.2, .3,'Generating','fontsize',AxesFontSize,'horizontalalignment','left');
    text(0.2, .2,'Bayesian','fontsize',AxesFontSize,'horizontalalignment','left','color',[0 .7 0]);
    text(0.2, .1,'Maximum Likelihood','fontsize',AxesFontSize,'horizontalalignment','left','color',[.7 0 0]);
    ylabel('Proportion Correct','fontsize',LabelFontSize);
    xlabel('Log Stimulus Intensity','fontsize',LabelFontSize)

    drawnow  
    
end

%Print summary of results to screen
message = sprintf('\rThreshold estimate as marginal mean of posterior');
message = strcat(message, sprintf(': %6.4f',...
    PM.threshold(length(PM.threshold))));
disp(message);
message = sprintf('Slope estimate as marginal mean of posterior (Log units)');
message = strcat(message, sprintf(': %6.4f',...
    PM.slope(length(PM.slope))));
disp(message);
message = sprintf('Guess rate estimate as marginal mean of posterior');
message = strcat(message, sprintf(': %6.4f',...
    PM.guess(length(PM.guess))));
disp(message);
message = sprintf('Lapse rate estimate as marginal mean of posterior');
message = strcat(message, sprintf(': %6.4f',...
    PM.lapse(length(PM.lapse))));
disp(message);
message = sprintf('Threshold standard error as marginal sd of posterior');
message = strcat(message, sprintf(': %6.4f',...
    PM.seThreshold(length(PM.seThreshold))));
disp(message);
message = sprintf('Slope standard error as marginal sd of posterior (Log units)');
message = strcat(message, sprintf(': %6.4f',...
    PM.seSlope(length(PM.seSlope))));
disp(message);
message = sprintf('Guess rate standard error as marginal sd of posterior');
message = strcat(message, sprintf(': %6.4f',...
    PM.seGuess(length(PM.seGuess))));
disp(message);
message = sprintf('Lapse rate standard error as marginal sd of posterior');
message = strcat(message, sprintf(': %6.4f',...
    PM.seLapse(length(PM.seLapse))));
disp(message);
message = sprintf('\rThreshold estimate as marginal mean of posterior us');
message = strcat(message, sprintf('ing uniform prior: %6.4f',...
    PM.thresholdUniformPrior(length(PM.thresholdUniformPrior))));
disp(message);
message = sprintf('Slope estimate as marginal mean of posterior (Log units)');
message = strcat(message, sprintf(': %6.4f',...
    PM.slopeUniformPrior(length(PM.slopeUniformPrior))));
disp(message);
message = sprintf('Guess rate estimate as marginal mean of posterior us');
message = strcat(message, sprintf('ing uniform prior: %6.4f',...
    PM.guessUniformPrior(length(PM.guessUniformPrior))));
disp(message);
message = sprintf('Lapse rate estimate as marginal mean of posterior us');
message = strcat(message, sprintf('ing uniform prior: %6.4f',...
    PM.lapseUniformPrior(length(PM.lapseUniformPrior))));
disp(message);
message = sprintf('Threshold standard error as marginal sd of posterio');
message = strcat(message, sprintf('r using uniform prior: %6.4f',...
    PM.seThresholdUniformPrior(length(PM.seThresholdUniformPrior))));
disp(message);
message = sprintf('Slope standard error as marginal sd of posterior us');
message = strcat(message, sprintf('ing uniform prior (Log units): %6.4f',...
    PM.seSlopeUniformPrior(length(PM.seSlopeUniformPrior))));
disp(message);
message = sprintf('Guess rate standard error as marginal sd of posterior us');
message = strcat(message, sprintf('ing uniform prior: %6.4f',...
    PM.seGuessUniformPrior(length(PM.seGuessUniformPrior))));
disp(message);
message = sprintf('Lapse rate standard error as marginal sd of posterior us');
message = strcat(message, sprintf('ing uniform prior: %6.4f',...
    PM.seLapseUniformPrior(length(PM.seLapseUniformPrior))));
disp(message);