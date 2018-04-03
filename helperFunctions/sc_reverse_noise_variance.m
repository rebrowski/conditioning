function data=vc_reverse_noise_variance(PM)
if ~ isfield(PM, 'intensity')
    %PM.intensity = (PM.noise_variance * - 1) + max(PM.noise_variance);
    PM.intensity = (PM.noise_variance * - 1) + 2.5;
end
data=PM;
end