function [varargout] = deinterleave(img,num_chan)
% deinterleave signals. Ouput is a cell with num_chan elements
if nargin == 1
    num_chan = 2;
end

for chan = 1:num_chan
    varargout{chan} = img(:,:,chan:num_chan:end);
end
end
