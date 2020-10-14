function channels_out = format_channels(channels_in)
% function channels_out = format_channels(channels_in)
%
% Checks that channels are given in the correct format
% Inputs:
%    - channels_in: string, char array or cell array of strings
% Outputs:
%    - channels_out: cell array of strings

if iscell(channels_in)
    channels_out = channels_in;    
elseif ischar(channels_in) || isstring(channels_in)
    channels_out = {channels_in};
else
    error('Channels must be a string or a cell array');
end
