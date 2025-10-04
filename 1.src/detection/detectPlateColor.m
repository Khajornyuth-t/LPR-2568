function bbox = detectPlateColor(img)
% DETECTPLATECOLOR - ตรวจจับป้ายทะเบียนโดยใช้ Color-based filtering
%
% Syntax:
%   bbox = detectPlateColor(img)
%
% Input:
%   img - RGB image
%
% Output:
%   bbox - [x, y, width, height] หรือ [] ถ้าไม่เจอ
%
% Strategy:
%   1. Color Filtering (White/Yellow/Green/Red plates)
%   2. Morphological Operations
%   3. Shape Filtering (AR, Size)
%   4. Edge Density Verification
%
% Author: LPR-2568 Project
% Date: 2025

    %% ========================================
    %% 1. INPUT VALIDATION
    %% ========================================
    if isempty(img) || size(img, 3) ~= 3
        warning('detectPlateColor:InvalidInput', 'Input must be RGB image');
        bbox = [];
        return;
    end
    
    [imgHeight, imgWidth, ~] = size(img);
    
    %% ========================================
    %% 2. DEFINE ROI
    %% ========================================
    xStart = round(imgWidth * 0.25);
    xEnd = round(imgWidth * 0.75);
    yStart = round(imgHeight * 0.40);
    yEnd = round(imgHeight * 0.80);
    
    roiImg = img(yStart:yEnd, xStart:xEnd, :);
    [roiHeight, roiWidth, ~] = size(roiImg);
    
    fprintf('Image: %dx%d | ROI: %dx%d pixels\n', imgWidth, imgHeight, roiWidth, roiHeight);
    
    %% ========================================
    %% 3. COLOR-BASED SEGMENTATION
    %% ========================================
    % Convert to HSV
    hsvImg = rgb2hsv(roiImg);
    H = hsvImg(:,:,1);
    S = hsvImg(:,:,2);
    V = hsvImg(:,:,3);
    
    % ป้ายทะเบียนไทยมี 4 สี: ขาว, เหลือง, เขียว, แดง
    
    % 1. White Plate (ป้ายส่วนตัว - พื้นขาว ตัวอักษรดำ)
    whiteMask = (S < 0.2) & (V > 0.5);
    
    % 2. Yellow Plate (ป้ายสาธารณะ - พื้นเหลือง ตัวอักษรดำ)
    yellowMask = (H >= 0.12 & H <= 0.18) & (S > 0.3) & (V > 0.4);
    
    % 3. Green Plate (ป้ายชั่วคราว - พื้นเขียว ตัวอักษรขาว)
    greenMask = (H >= 0.25 & H <= 0.45) & (S > 0.2) & (V > 0.2);
    
    % 4. Red Plate (ป้ายทดลอง - พื้นแดง ตัวอักษรขาว)
    redMask = ((H >= 0.95 | H <= 0.05)) & (S > 0.3) & (V > 0.3);
    
    % Combine all color masks
    colorMask = whiteMask | yellowMask | greenMask | redMask;
    
    %% ========================================
    %% 4. MORPHOLOGICAL OPERATIONS
    %% ========================================
    % Close small gaps
    se1 = strel('rectangle', [3, 15]);
    morphClosed = imclose(colorMask, se1);
    
    % Fill holes
    morphFilled = imfill(morphClosed, 'holes');
    
    % Remove small objects
    morphCleaned = bwareaopen(morphFilled, 500);
    
    %% ========================================
    %% 5. FIND REGIONS
    %% ========================================
    stats = regionprops(morphCleaned, 'BoundingBox', 'Area', 'Solidity', 'Extent');
    
    if isempty(stats)
        fprintf('No color regions found\n');
        bbox = [];
        return;
    end
    
    fprintf('Found %d color regions\n', length(stats));
    
    %% ========================================
    %% 6. CANDIDATE FILTERING
    %% ========================================
    roiArea = roiHeight * roiWidth;
    
    candidates = zeros(length(stats), 1);
    candidateScores = zeros(length(stats), 1);
    candidateCount = 0;
    
    for i = 1:length(stats)
        bbox_roi = stats(i).BoundingBox;
        w = bbox_roi(3);
        h = bbox_roi(4);
        area = stats(i).Area;
        solidity = stats(i).Solidity;
        extent = stats(i).Extent;
        
        % Calculate features
        aspectRatio = w / h;
        relativeArea = area / roiArea;
        
        % Filtering criteria (เข้มงวดกว่าแบบเดิม)
        validAR = (aspectRatio >= 2.5) && (aspectRatio <= 5.0);
        validArea = (relativeArea >= 0.008) && (relativeArea <= 0.15);
        validSolidity = (solidity >= 0.60);
        validExtent = (extent >= 0.40);
        
        if validAR && validArea && validSolidity && validExtent
            candidateCount = candidateCount + 1;
            candidates(candidateCount) = i;
            
            % Calculate score
            score = calculateColorScore(aspectRatio, relativeArea, solidity, extent);
            candidateScores(candidateCount) = score;
            
            fprintf('  Region %d: AR=%.2f, Area=%.4f, Sol=%.2f, Ext=%.2f [Score: %.1f]\n', ...
                    i, aspectRatio, relativeArea, solidity, extent, score);
        end
    end
    
    candidates = candidates(1:candidateCount);
    candidateScores = candidateScores(1:candidateCount);
    
    %% ========================================
    %% 7. EDGE DENSITY VERIFICATION
    %% ========================================
    if isempty(candidates)
        fprintf('No valid candidates\n');
        bbox = [];
        return;
    end
    
    % Prepare edge map for verification
    grayROI = rgb2gray(roiImg);
    edgeMap = edge(grayROI, 'Canny', [0.1, 0.25]);
    
    % Sort by score
    [~, sortIdx] = sort(candidateScores, 'descend');
    sortedCandidates = candidates(sortIdx);
    
    % Try candidates from highest to lowest
    bbox = [];
    for idx = 1:length(sortedCandidates)
        regionIdx = sortedCandidates(idx);
        bbox_roi = stats(regionIdx).BoundingBox;
        
        % Extract region
        x = max(1, round(bbox_roi(1)));
        y = max(1, round(bbox_roi(2)));
        x2 = min(round(x + bbox_roi(3)), roiWidth);
        y2 = min(round(y + bbox_roi(4)), roiHeight);
        
        regionEdges = edgeMap(y:y2, x:x2);
        edgeDensity = sum(regionEdges(:)) / (bbox_roi(3) * bbox_roi(4));
        
        fprintf('  Region %d: Edge Density = %.3f ', regionIdx, edgeDensity);
        
        % ป้ายทะเบียนต้องมี edges พอสมควร (ตัวอักษร)
        if edgeDensity >= 0.10
            fprintf('VERIFIED\n');
            
            % Convert to original coordinates
            bbox = [bbox_roi(1) + xStart - 1, ...
                    bbox_roi(2) + yStart - 1, ...
                    bbox_roi(3), ...
                    bbox_roi(4)];
            break;
        else
            fprintf('FAILED (no text)\n');
        end
    end
    
    if isempty(bbox)
        fprintf('All candidates failed edge verification\n');
        return;
    end
    
    fprintf('Final BBox: [%.0f, %.0f, %.0f, %.0f]\n', bbox(1), bbox(2), bbox(3), bbox(4));
end

%% ========================================
%% HELPER: SCORING
%% ========================================
function score = calculateColorScore(aspectRatio, relativeArea, solidity, extent)
    score = 0;
    
    % Aspect Ratio (40 points)
    if aspectRatio >= 3.0 && aspectRatio <= 4.2
        score = score + 40;
    elseif aspectRatio >= 2.7 && aspectRatio <= 4.8
        score = score + 30;
    elseif aspectRatio >= 2.5 && aspectRatio <= 5.0
        score = score + 20;
    end
    
    % Relative Area (30 points)
    if relativeArea >= 0.015 && relativeArea <= 0.08
        score = score + 30;
    elseif relativeArea >= 0.01 && relativeArea <= 0.12
        score = score + 20;
    elseif relativeArea >= 0.008 && relativeArea <= 0.15
        score = score + 10;
    end
    
    % Solidity (15 points)
    if solidity >= 0.75
        score = score + 15;
    elseif solidity >= 0.65
        score = score + 10;
    elseif solidity >= 0.60
        score = score + 5;
    end
    
    % Extent (15 points)
    if extent >= 0.60
        score = score + 15;
    elseif extent >= 0.50
        score = score + 10;
    elseif extent >= 0.40
        score = score + 5;
    end
end