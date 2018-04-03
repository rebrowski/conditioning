% writes data to DAQ with device index daq (if~=0) and returns time.
function daqTime = daqOut(daq,data)
    if daq
        DaqDOut(daq, 0, data);
        daqTime = GetSecs();
        DaqDOut(daq, 0, 0);
    else
        daqTime= GetSecs();
        fprintf(1, '-> %d\n', data)
    end
end
