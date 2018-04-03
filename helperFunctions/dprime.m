function [d] = dprime(pHit,pFA)

d = norminv(pHit) - norminv(pFA);