% wrapper function that inits daq
% returns device index on success and 0 on error.
function daq = daqInit()
    daq = 0;
    try
        daq = DaqFind;
        DaqDConfigPort(daq,0,0); % set up port A for output
    catch
        err = psychlasterror;
        warning('effort:daq_error', 'DAQ not found: %s', err.message)
        daq = 0;
        input('Hit Enter to continue without DAQ...');
    end
end
