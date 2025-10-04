function plateImg = extractPlate(img, bbox)
% EXTRACTPLATE - Crop ป้ายทะเบียนออกจากภาพ
%
% Syntax:
%   plateImg = extractPlate(img, bbox)
%
% Input:
%   img  - RGB or grayscale image (ภาพต้นฉบับ)
%   bbox - [x, y, width, height] bounding box ของป้ายทะเบียน
%
% Output:
%   plateImg - ภาพป้ายทะเบียนที่ crop แล้ว (RGB or grayscale)
%            - หรือ [] ถ้า bbox ไม่ถูกต้อง
%
% Example:
%   img = imread('car.jpg');
%   bbox = detectPlate(img);
%   if ~isempty(bbox)
%       plateImg = extractPlate(img, bbox);
%       imshow(plateImg);
%   end
%
% Author: LPR-2568 Project
% Date: 2025

    %% ========================================
    %% 1. INPUT VALIDATION
    %% ========================================
    if isempty(img)
        warning('extractPlate:EmptyImage', 'Input image is empty');
        plateImg = [];
        return;
    end
    
    if isempty(bbox)
        warning('extractPlate:EmptyBBox', 'Bounding box is empty');
        plateImg = [];
        return;
    end
    
    if length(bbox) ~= 4
        error('extractPlate:InvalidBBox', 'BBox must be [x, y, width, height]');
    end
    
    %% ========================================
    %% 2. GET IMAGE DIMENSIONS
    %% ========================================
    [imgHeight, imgWidth, ~] = size(img);
    
    %% ========================================
    %% 3. VALIDATE AND ADJUST BBOX
    %% ========================================
    x = round(bbox(1));
    y = round(bbox(2));
    w = round(bbox(3));
    h = round(bbox(4));
    
    % Ensure bbox is within image bounds
    x = max(1, min(x, imgWidth));
    y = max(1, min(y, imgHeight));
    
    % Adjust width and height if needed
    if x + w > imgWidth
        w = imgWidth - x;
    end
    
    if y + h > imgHeight
        h = imgHeight - y;
    end
    
    % Check if valid region exists
    if w <= 0 || h <= 0
        warning('extractPlate:InvalidRegion', 'Invalid crop region after adjustment');
        plateImg = [];
        return;
    end
    
    %% ========================================
    %% 4. CROP IMAGE
    %% ========================================
    try
        plateImg = imcrop(img, [x, y, w, h]);
        
        fprintf('Extracted plate: %dx%d pixels at [%d, %d]\n', w, h, x, y);
    catch ME
        warning('extractPlate:CropFailed', 'Failed to crop image: %s', ME.message);
        plateImg = [];
    end
end