function bbox = detectPlate(img)
% DETECTPLATE - ตรวจจับป้ายทะเบียนโดย focus บริเวณด้านหน้ากลาง
%
% Syntax:
%   bbox = detectPlate(img)
%
% Input:
%   img - RGB or grayscale image (ภาพรถยนต์)
%
% Output:
%   bbox - [x, y, width, height] ในพิกัดของภาพต้นฉบับ
%          หรือ [] ถ้าไม่พบป้ายทะเบียน
%
% Example:
%   img = imread('car.jpg');
%   bbox = detectPlate(img);
%   if ~isempty(bbox)
%       plateImg = imcrop(img, bbox);
%       imshow(plateImg);
%   end
%
% Description:
%   ใช้ Multi-Stage Pipeline:
%   1. ROI Selection (Center-Front Focus Zone)
%   2. Preprocessing (HSV V-channel + CLAHE)
%   3. Edge Detection (Canny)
%   4. Morphological Operations
%   5. Candidate Filtering (Aspect Ratio, Area, Solidity, etc.)
%   6. Scoring & Selection
%
% Author: LPR-2568 Project
% Date: 2025

    %% ========================================
    %% 1. INPUT VALIDATION
    %% ========================================
    if isempty(img)
        error('detectPlate:EmptyImage', 'Input image is empty');
    end
    
    % Convert to grayscale if needed
    if size(img, 3) == 3
        grayImg = rgb2gray(img);
    else
        grayImg = img;
    end
    
    [imgHeight, imgWidth] = size(grayImg);
    
    if imgHeight < 100 || imgWidth < 100
        warning('detectPlate:SmallImage', 'Image size too small: %dx%d', imgWidth, imgHeight);
        bbox = [];
        return;
    end
    
    %% ========================================
    %% 2. DEFINE CENTER-FRONT ROI (GREEN BOX AREA)
    %% ========================================
    % Horizontal: 25%-75% (center 50% width)
    xStart = round(imgWidth * 0.25);
    xEnd = round(imgWidth * 0.75);
    
    % Vertical: 40%-80% (lower-middle 40% height)
    yStart = round(imgHeight * 0.40);
    yEnd = round(imgHeight * 0.80);
    
    % Extract ROI
    roi = grayImg(yStart:yEnd, xStart:xEnd);
    [roiHeight, roiWidth] = size(roi);
    
    fprintf('Image: %dx%d | ROI: %dx%d pixels\n', imgWidth, imgHeight, roiWidth, roiHeight);
    
    %% ========================================
    %% 3. PREPROCESSING (HSV V-channel + CLAHE)
    %% ========================================
    if size(img, 3) == 3
        % Use HSV V-channel (better for license plate colors)
        hsvImg = rgb2hsv(img);
        vChannel = hsvImg(:, :, 3);
        roiPreprocessed = vChannel(yStart:yEnd, xStart:xEnd);
    else
        roiPreprocessed = roi;
    end
    
    % Apply CLAHE (Contrast Limited Adaptive Histogram Equalization)
    roiPreprocessed = adapthisteq(roiPreprocessed, ...
                                  'ClipLimit', 0.02, ...
                                  'NumTiles', [8 8]);
    
    %% ========================================
    %% 4. EDGE DETECTION
    %% ========================================
    % Canny with lower thresholds (more sensitive)
    edgeMap = edge(roiPreprocessed, 'Canny', [0.05, 0.20]);
    
    %% ========================================
    %% 5. MORPHOLOGICAL OPERATIONS (VERY CONSERVATIVE)
    %% ========================================
    % Step 1: Closing - เชื่อมตัวอักษรเบาๆ
    se1 = strel('rectangle', [2, 8]);  % ลดจาก [3,10] → [2,8]
    morphClosed = imclose(edgeMap, se1);
    
    % Step 2: Fill holes
    morphFilled = imfill(morphClosed, 'holes');
    
    % Step 3: Dilate เล็กน้อยมาก
    se2 = strel('rectangle', [1, 3]);  % ลดจาก [2,5] → [1,3]
    morphDilated = imdilate(morphFilled, se2);
    
    % Step 4: Opening - แยก objects ที่เชื่อมกัน
    se3 = strel('rectangle', [2, 2]);
    morphOpened = imopen(morphDilated, se3);
    
    % Step 5: Remove small noise objects
    morphCleaned = bwareaopen(morphOpened, 200);  % ลดจาก 300 → 200
    
    %% ========================================
    %% 6. FIND REGIONS (CONNECTED COMPONENTS)
    %% ========================================
    stats = regionprops(morphCleaned, 'BoundingBox', 'Area', ...
                       'Solidity', 'Extent', 'Eccentricity');
    
    if isempty(stats)
        fprintf('⚠️  No regions found in ROI\n');
        bbox = [];
        return;
    end
    
    fprintf('Found %d regions in ROI\n', length(stats));
    
    %% ========================================
    %% 7. CANDIDATE FILTERING
    %% ========================================
    roiArea = roiHeight * roiWidth;
    
    % Preallocate arrays (Best Practice - No warnings)
    maxCandidates = length(stats);
    candidates = zeros(maxCandidates, 1);
    candidateScores = zeros(maxCandidates, 1);
    candidateCount = 0;
    
    for i = 1:length(stats)
        bbox_roi = stats(i).BoundingBox;
        w = bbox_roi(3);
        h = bbox_roi(4);
        area = stats(i).Area;
        solidity = stats(i).Solidity;
        extent = stats(i).Extent;
        
        % --- Feature Calculations ---
        aspectRatio = w / h;
        relativeArea = area / roiArea;
        
        % --- Filtering Criteria (RELAXED) ---
        validAR = (aspectRatio >= 2.0) && (aspectRatio <= 6.0);  % ขยายจาก 2.5-5.5
        validArea = (relativeArea >= 0.005) && (relativeArea <= 0.25);  % ขยาย
        validSolidity = (solidity >= 0.55);  % ลดจาก 0.65
        validExtent = (extent >= 0.35);  % ลดจาก 0.45
        
        % --- Edge Density Check ---
        x = max(1, round(bbox_roi(1)));
        y = max(1, round(bbox_roi(2)));
        x2 = min(round(x + w), roiWidth);
        y2 = min(round(y + h), roiHeight);
        
        if x < x2 && y < y2
            roiEdges = edgeMap(y:y2, x:x2);
            edgeDensity = sum(roiEdges(:)) / (w * h);
            validEdgeDensity = (edgeDensity >= 0.10);  % ลดจาก 0.12
        else
            validEdgeDensity = false;
        end
        
        % --- Check All Criteria ---
        if validAR && validArea && validSolidity && validExtent && validEdgeDensity
            candidateCount = candidateCount + 1;
            candidates(candidateCount) = i;
            
            % Calculate Score
            score = calculateScore(aspectRatio, relativeArea, solidity, ...
                                 extent, edgeDensity, bbox_roi, roiHeight);
            candidateScores(candidateCount) = score;
            
            fprintf('  ✓ Region %d: AR=%.2f, Area=%.4f, Sol=%.2f, Ext=%.2f, EdgeD=%.3f [Score: %.1f]\n', ...
                    i, aspectRatio, relativeArea, solidity, extent, edgeDensity, score);
        else
            fprintf('  ✗ Region %d: AR=%.2f (Checks: AR:%d Area:%d Sol:%d Ext:%d Edge:%d)\n', ...
                    i, aspectRatio, validAR, validArea, validSolidity, validExtent, validEdgeDensity);
        end
    end
    
    % Trim arrays to actual size
    candidates = candidates(1:candidateCount);
    candidateScores = candidateScores(1:candidateCount);
    
    %% ========================================
    %% 8. SELECT BEST CANDIDATE
    %% ========================================
    if isempty(candidates)
        fprintf('⚠️  No valid candidates found\n');
        bbox = [];
        return;
    end
    
    [maxScore, bestIdx] = max(candidateScores);
    bestRegion = candidates(bestIdx);
    bbox_roi = stats(bestRegion).BoundingBox;
    
    fprintf('\n🎯 Selected Region %d (Score: %.1f/100)\n', bestRegion, maxScore);
    
    %% ========================================
    %% 9. CONVERT TO ORIGINAL IMAGE COORDINATES
    %% ========================================
    % ROI coordinates → Original image coordinates
    bbox = [bbox_roi(1) + xStart - 1, ...  % x
            bbox_roi(2) + yStart - 1, ...  % y
            bbox_roi(3), ...               % width
            bbox_roi(4)];                  % height
    
    fprintf('Final BBox: [%.0f, %.0f, %.0f, %.0f]\n', bbox(1), bbox(2), bbox(3), bbox(4));
end

%% ========================================
%% HELPER FUNCTION: SCORING SYSTEM
%% ========================================
function score = calculateScore(aspectRatio, relativeArea, solidity, ...
                               extent, edgeDensity, bbox_roi, roiHeight)
% CALCULATESCORE - คำนวณคะแนนความน่าจะเป็นที่จะเป็นป้ายทะเบียน (RELAXED)
%
% Scoring breakdown (100 points total):
%   - Aspect Ratio:  35 points
%   - Relative Area: 20 points
%   - Solidity:      15 points
%   - Extent:        10 points
%   - Edge Density:  15 points
%   - Position:       5 points

    score = 0;
    
    % ===== 1. Aspect Ratio (35 points) =====
    % ป้ายทะเบียนไทยมีสัดส่วน ≈ 3:1 ถึง 4:1
    if aspectRatio >= 3.0 && aspectRatio <= 4.5
        score = score + 35;  % Perfect range
    elseif aspectRatio >= 2.5 && aspectRatio <= 5.5
        score = score + 25;  % Good range
    elseif aspectRatio >= 2.0 && aspectRatio <= 6.0
        score = score + 15;  % Acceptable range
    end
    
    % ===== 2. Relative Area (20 points) =====
    % ป้ายไม่ควรเล็กหรือใหญ่เกินไป (% ของ ROI)
    if relativeArea >= 0.02 && relativeArea <= 0.10
        score = score + 20;  % Ideal size
    elseif relativeArea >= 0.01 && relativeArea <= 0.18
        score = score + 14;  % Good size
    elseif relativeArea >= 0.005 && relativeArea <= 0.25
        score = score + 8;   % Acceptable
    end
    
    % ===== 3. Solidity (15 points) =====
    % Solidity = Area / ConvexArea
    if solidity >= 0.75
        score = score + 15;
    elseif solidity >= 0.65
        score = score + 12;
    elseif solidity >= 0.55
        score = score + 8;
    end
    
    % ===== 4. Extent (10 points) =====
    % Extent = Area / BoundingBoxArea (ความเต็มของกรอบ)
    if extent >= 0.60
        score = score + 10;  % Very full
    elseif extent >= 0.50
        score = score + 7;   % Good
    elseif extent >= 0.35
        score = score + 4;   % Acceptable
    end
    
    % ===== 5. Edge Density (15 points) =====
    % ป้ายทะเบียนมีตัวอักษรหนาแน่น → edges เยอะ
    if edgeDensity >= 0.18
        score = score + 15;  % Very high density
    elseif edgeDensity >= 0.13
        score = score + 12;  % High density
    elseif edgeDensity >= 0.10
        score = score + 8;   % Acceptable
    end
    
    % ===== 6. Position Preference (5 points) =====
    % ป้ายมักอยู่ตรงกลาง ROI (vertically)
    centerY = bbox_roi(2) + bbox_roi(4)/2;
    normalizedY = centerY / roiHeight;
    
    if normalizedY >= 0.35 && normalizedY <= 0.65
        score = score + 5;   % Center position
    elseif normalizedY >= 0.25 && normalizedY <= 0.75
        score = score + 3;   % Near center
    elseif normalizedY >= 0.15 && normalizedY <= 0.85
        score = score + 1;   % Acceptable position
    end
end