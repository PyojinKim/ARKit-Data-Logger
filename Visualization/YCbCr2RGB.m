function colorsRGB = YCbCr2RGB(colorsYCbCr)

numColors = size(colorsYCbCr,2);
colorsRGB = zeros(3,numColors);
for k = 1:numColors
    
    % YCbCr color space
    Y = colorsYCbCr(1,k);
    Cb = colorsYCbCr(2,k);
    Cr = colorsYCbCr(3,k);
    
    % RGB color space
    R = (1000*Y + 1402*(Cr-128)) / 1000;
    G = (1000*Y - 714*(Cr-128) - 334*(Cb-128)) / 1000;
    B = (1000*Y + 1772*(Cb-128)) / 1000;
    colorsRGB(:,k) = [R; G; B];
end

end

