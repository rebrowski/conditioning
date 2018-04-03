
function output_image = make_noise_image(input, mean, variance)
% adds gaussian noise to an image
% handels so far only uint8 images I guess...

input = double(input) / 255;
output_image = input + sqrt(variance)*randn(size(input)) + mean;
output_image = max(0,min(output_image,1));
output_image = uint8(output_image*255);

end




