%
%PAL_Entropy  Shannon entropy of probability density function
%
%   syntax: Entropy = PAL_Entropy(pdf,{optional: # of dimensions})
%
%   Entropy = PAL_Entropy(pdf) returns the Shannon entropy (in 'nats') of 
%   the (discrete) N-D probability density function in the vector or matrix 
%   'pdf'.
%
%   Examples:
%
%   y = PAL_Entropy([.5 .5]) returns:
%
%   y = 
%       0.6931
%
%   y = log2(exp(PAL_Entropy([.5 .5]))) returns entropy in units of bits:
%
%   y = 
%       1
% 
%   y = log10(exp(PAL_Entropy([.5 .5]))) returns entropy in units of bans:
%
%   y = 
%       0.3010
%
%   Entropy = PAL_Entropy(pdf, nds), where nds is a positive integer 
%   returns an array of Entropy values calculated across the first 'nds' 
%   dimensions of 'pdf'.
%
%   Example:
%
%   y = PAL_Entropy([.5 .5; 1 0]',1) returns:
%
%   y =
%        0.6931         0
%
%Introduced: Palamedes version 1.0.0 (NP)
%Modified: Palamedes version 1.1.0, 1.5.0 (see History.m)

function Entropy = PAL_Entropy(pdf,varargin)

warningstates = warning('query','all');
warning off MATLAB:log:logOfZero

nds = ndims(pdf);

if ~isempty(varargin)
    nds = varargin{1};
end

Entropy = pdf.*log(pdf);
Entropy(isnan(Entropy)) = 0;          %effectively defines 0.*log(0) to equal 0.

for d = 1:nds
    Entropy = sum(Entropy,d);    
end
Entropy = -Entropy;
warning(warningstates)