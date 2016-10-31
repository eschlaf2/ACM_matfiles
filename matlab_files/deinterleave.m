function [signal, triggers] = deinterleave(img)

signal = img(:,:,1:2:end);
triggers = img(:,:,2:2:end);

end
