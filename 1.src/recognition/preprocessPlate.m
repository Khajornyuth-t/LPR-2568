function [processed_img, binary_img, debug_info] = preprocessPlate(plate_img, options)
% preprocessPlate - Preprocess license plate image for OCR
%
% Syntax:
%   [processed_img, binary_img] = preprocessPlate(plate_img)
%   [processed_img, binary_img, debug_info] = preprocessPlate(plate_img, options)
%
% Inputs:
%   plate_img - Input plate image (RGB or grayscale)
%   options   - (Optional) Preprocessing parameters
%
% Outputs:
%   processed_img - Enhanced grayscale image
%   binary_img    - Binary image ready for segmentation
%   debug_info    - Struct with intermediate results (for debugging)
%
% Example:
%   plate_img = imread('output/detected_plates/plate_001.jpg');
%   [gray, binary] = preprocessPlate(plate_img);
%   imshow(binary);

    %% Default options
    if nargin < 2
        options = struct();
    end
    
    % Set default parameters
    if ~isfield(options, 'method'), options.method = 'otsu'; end
    if ~isfield(options, 'enhanceContrast'), options.enhanceContrast = true; end
    if ~isfield(options, 'removeNoise'), options.removeNoise = true; end
    if ~isfield(options, 'morphClose'), options.morphClose = true; end
    if ~isfield(options, 'debugMode'), options.debugMode = false; end
    
    %% Initialize debug info
    debug_info = struct();
    
    %% Step 1: Convert to grayscale
    if size(plate_img, 3) == 3
        gray_img = rgb2gray(plate_img);
        debug_info.step1_grayscale = gray_img;
    else
        gray_img = plate_img;
        debug_info.step1_grayscale = gray_img;
    end
    
    %% Step 2: Resize if too small or too large
    [h, ~] = size(gray_img);
    targetHeight = 100; % Standard height for processing
    
    if h < 50 || h > 200
        scale = targetHeight / h;
        gray_img = imresize(gray_img, scale);
        debug_info.step2_resized = gray_img;
        debug_info.scaleFactor = scale;
    else
        debug_info.step2_resized = gray_img;
        debug_info.scaleFactor = 1;
    end
    
    %% Step 3: Enhance contrast (CLAHE)
    if options.enhanceContrast
        enhanced_img = adapthisteq(gray_img, 'ClipLimit', 0.02, 'Distribution', 'rayleigh');
        debug_info.step3_enhanced = enhanced_img;
    else
        enhanced_img = gray_img;
        debug_info.step3_enhanced = enhanced_img;
    end
    
    %% Step 4: Apply bilateral filter to reduce noise while preserving edges
    if options.removeNoise
        % Bilateral-like filtering using guided filter (MATLAB built-in)
        smooth_img = imguidedfilter(enhanced_img);
        debug_info.step4_smoothed = smooth_img;
    else
        smooth_img = enhanced_img;
        debug_info.step4_smoothed = smooth_img;
    end
    
    %% Step 5: Binarization
    switch lower(options.method)
        case 'otsu'
            % Otsu's method - automatic threshold
            level = graythresh(smooth_img);
            binary_img = imbinarize(smooth_img, level);
            debug_info.threshold = level;
            
        case 'adaptive'
            % Adaptive thresholding
            binary_img = imbinarize(smooth_img, 'adaptive', 'Sensitivity', 0.5);
            debug_info.threshold = 'adaptive';
            
        case 'sauvola'
            % Sauvola's method - good for varying illumination
            binary_img = imbinarize(smooth_img, 'adaptive', 'ForegroundPolarity', 'dark', 'Sensitivity', 0.4);
            debug_info.threshold = 'sauvola';
            
        otherwise
            error('Unknown binarization method: %s', options.method);
    end
    
    debug_info.step5_binary = binary_img;
    
    %% Step 6: Invert if needed (characters should be white on black)
    % Thai plates usually have dark text on white background
    % So we need white text on black background for processing
    if mean(binary_img(:)) > 0.5
        binary_img = ~binary_img;
        debug_info.step6_inverted = true;
    else
        debug_info.step6_inverted = false;
    end
    
    %% Step 7: Morphological operations to clean up
    if options.morphClose
        % Remove small noise
        binary_img = bwareaopen(binary_img, 20);
        
        % Close small gaps in characters
        se = strel('rectangle', [3, 3]);
        binary_img = imclose(binary_img, se);
        
        debug_info.step7_morphology = binary_img;
    else
        debug_info.step7_morphology = binary_img;
    end
    
    %% Output
    processed_img = smooth_img;
    
    %% Debug visualization
    if options.debugMode
        figure('Name', 'Plate Preprocessing Pipeline');
        
        subplot(3,3,1);
        imshow(plate_img);
        title('1. Original');
        
        subplot(3,3,2);
        imshow(debug_info.step1_grayscale);
        title('2. Grayscale');
        
        subplot(3,3,3);
        imshow(debug_info.step2_resized);
        title(sprintf('3. Resized (%.2fx)', debug_info.scaleFactor));
        
        subplot(3,3,4);
        imshow(debug_info.step3_enhanced);
        title('4. Enhanced (CLAHE)');
        
        subplot(3,3,5);
        imshow(debug_info.step4_smoothed);
        title('5. Smoothed');
        
        subplot(3,3,6);
        imshow(debug_info.step5_binary);
        title(sprintf('6. Binary (%s)', options.method));
        
        subplot(3,3,7);
        imshow(binary_img);
        if debug_info.step6_inverted
            title('7. Inverted');
        else
            title('7. Not inverted');
        end
        
        subplot(3,3,8);
        imshow(binary_img);
        title('8. Final Binary');
        
        subplot(3,3,9);
        imshow(processed_img);
        title('9. Final Grayscale');
    end
    
end