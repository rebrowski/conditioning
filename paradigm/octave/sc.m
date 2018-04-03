function sc(subject, initial_reward, debug)
% Main Script to run the Subliminal Conditioning Pilot Study
    
t0 = GetSecs();

debug = false;

if debug
    n_trials_eth_practice = 2;  % N trials total
    n_trials_eth = 1;           % N trials for each stimulus
    n_trials_sc_practice = 1;   % N trials for each stimulus
    n_trials_sc = ones(1,4);    % N trials for each stimulus    
else
    n_trials_eth_practice = 8;  % N trials total
    n_trials_eth = 32;          % N trials for each stimulus
    n_trials_sc_practice = 5;   % N trials for each stimulus
    n_trials_sc = [8 16 36 36]; % N trials for each stimulus
end
reward_sizes = [0.2 0.4 0.6 1];

if nargin < 1
  subject = myinput('Subject-Nr.?:');
end

if nargin < 2
  initial_reward = 10;
end

% save date_time at the beginning

formatOut = 'dd-mmmm-yyyy_HH-MM-SS';
date_time = datestr(now,formatOut);
formatOut = 'dd-mmmm-yyyy';
today_str = datestr(now,formatOut);

% make logfile directory for the current subject

logdir =strcat(cd, filesep,'logs',filesep, num2str(subject), '_', today_str);
disp(logdir);
if ~exist(logdir, 'dir')
  mkdir(logdir)
else
  disp('Subject Number already used today!');  
  go_on = myinput(sprintf('\n%s\n%s\n','Continue anyway?', 'Yes:1,No:0'));
  if ~go_on
    return;
  end;
end

%% estimate the thresholds I

% practice 
clc
myinput('Press enter to practice the perception-task'); 

% practice estimate thresholds
eth(subject, logdir, 0, n_trials_eth_practice);
myinput('Press Enter once');     % just the clear the inputs made earlier
                                 % from the command prompt
while myinput('nochmal? 0:nein, 1:ja')>0
  eth(subject, logdir, 0, n_trials_eth_practice);
  myinput('Press Enter once'); % just the clear the inputs made earlier
                                 % from the command prompt
end
% initial threshold estimation
clc
myinput('Press Enter to continue with the perception-task');
run = 1; % estimate thresholds

eth(subject, logdir, run, n_trials_eth);

%% conditioning 

% practice-run
myinput('Press Enter to practice the conditioning-task.');
conditioning(subject, 0, 10, 0.2, n_trials_sc_practice);
myinput('Press Enter once');     % just the clear the inputs made earlier
                                 % from the command prompt
while myinput('nochmal? 0:nein, 1:ja')>0
  conditioning(subject, 0, 10, 0.2, n_trials_sc_practice);
  myinput('Press Enter once');     % just the clear the inputs made earlier
                                   % from the command prompt
end


% real runs
for run = 1:4
  clc
  myinput(sprintf('%s %d','Press Enter to continue with the conditioning-task, run', run)); 
  initial_reward =  conditioning(subject, run, initial_reward, ...
                                     reward_sizes(run), n_trials_sc(run), ...
                                     logdir);
     
  myinput('Press Enter once'); % just the clear the inputs made earlier
                                 % from the command prompt
      
  data.awareness_rating(run) = myinput(sprintf('%s\n%s\n',['Wie ' ...
                      'häufig haben sie das Bild oder Teile/Andeutungen davon erkennen können (0-10)?'], ...
                      ['0(Nie) - 1,2,3,4 - 5 (etwa 50%)' ...
                      ' - 7,8,9 - 10(Immer)']));
end

%% estimate the thresholds II
clc
myinput('Press enter to estimate thresholds again'); 
run = 2;

eth(subject, logdir, run,  n_trials_eth);

% a small interview on demographics 
myinput('Press Enter once'); % just the clear the inputs made earlier
                           % from the command prompt
data.age = myinput('Bitte geben Sie Ihr Alter ein und drücken Sie Eingabe');
data.gender = myinput(['Bitte geben Sie Ihr Geschlecht an (0=männlich, ' ...
                    '1=weiblich) und drücken Sie Eingabe']);
data.elapsed_time = GetSecs()-t0;
save(strcat(logdir,filesep, num2str(subject), '_interview_', date_time ...
            ,'.mat'), 'data', '-v7');
disp(sprintf('%s %.2f %s','Endgültiger Kontostand:', initial_reward,'EUR.'));
end



    
