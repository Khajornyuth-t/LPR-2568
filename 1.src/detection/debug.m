% Load image
img = imread('../../2.data/images/LPR0010.bmp');

% Detect
bbox = detectPlate(img);

% Check result
if ~isempty(bbox)
    fprintf('✅ Detected at: [%.0f, %.0f, %.0f, %.0f]\n', bbox);
    
    % Crop plate
    plateImg = imcrop(img, bbox);
    
    % Display
    figure;
    subplot(1,2,1);
    imshow(img);
    rectangle('Position', bbox, 'EdgeColor', 'r', 'LineWidth', 2);
    title('Detection');
    
    subplot(1,2,2);
    imshow(plateImg);
    title('Extracted Plate');
else
    fprintf('❌ No plate detected\n');
end