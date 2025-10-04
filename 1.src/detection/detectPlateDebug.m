function bbox = detectPlateDebug(img, showDebug)
% DETECTPLATEDEBUG - Debug version with visualization and relaxed parameters
%
% Syntax:
%   bbox = detectPlateDebug(img, showDebug)
%
% Input:
%   img       - RGB or grayscale image
%   showDebug - true/false (default: true) แสดงภาพทุกขั้นตอน
%
% Output:
%   bbox - [x, y, width, height] หรือ [] ถ้าไม่เจอ

    if nargin < 2
        showDebug = true;
    end
    
    %% ========================================
    %% 1. INPUT VALIDATION
    %% ========================================
    if isempty(img)
        error('Input image is empty');
    end
    
    if size(img, 3) == 3
        grayImg = rgb2gray(img);
    else
        grayImg = img;
    end
    
    [imgHeight, imgWidth] = size(grayImg);
    
    %% ========================================
    %% 2. DEFINE ROI
    %% ========================================
    xStart = round(imgWidth * 0.25);
    xEnd = round(imgWidth * 0.75);
    yStart = round(imgHeight * 0.40);
    yEnd = round(imgHeight * 0.80);
    
    roi = grayImg(yStart:yEnd, xStart:xEnd);
    [roiHeight, roiWidth] = size(roi);
    
    fprintf('Image: %dx%d | ROI: %dx%d pixels\n', imgWidth, imgHeight, roiWidth, roiHeight);
    
    %% ========================================
    %% 3. PREPROCESSING
    %% ========================================
    if size(img, 3) == 3
        hsvImg = rgb2hsv(img);
        vChannel = hsvImg(:, :, 3);
        roiPreprocessed = vChannel(yStart:yEnd, xStart:xEnd);
    else
        roiPreprocessed = roi;
    end
    
    roiPreprocessed = adapthisteq(roiPreprocessed, 'ClipLimit', 0.02, 'NumTiles', [8 8]);
    
    %% ========================================
    %% 4. EDGE DETECTION
    %% ========================================
    edgeMap = edge(roiPreprocessed, 'Canny', [0.05, 0.20]);
    
    %% ========================================
    %% 5. MORPHOLOGICAL OPERATIONS
    %% ========================================
    se1 = strel('rectangle', [2, 8]);
    morphClosed = imclose(edgeMap, se1);
    morphFilled = imfill(morphClosed, 'holes');
    se2 = strel('rectangle', [1, 3]);
    morphDilated = imdilate(morphFilled, se2);
    se3 = strel('rectangle', [2, 2]);
    morphOpened = imopen(morphDilated, se3);
    morphCleaned = bwareaopen(morphOpened, 200);
    
    %% ========================================
    %% 6. FIND REGIONS
    %% ========================================
    stats = regionprops(morphCleaned, 'BoundingBox', 'Area', ...
                       'Solidity', 'Extent', 'Eccentricity');
    
    if isempty(stats)
        fprintf('⚠️  No regions found\n');
        bbox = [];
        return;
    end
    
    fprintf('Found %d regions\n', length(stats));
    
    %% ========================================
    %% 7. RELAXED FILTERING (สำหรับ Debug)
    %% ========================================
    roiArea = roiHeight * roiWidth;
    
    maxCandidates = length(stats);
    candidates = zeros(maxCandidates, 1);
    candidateScores = zeros(maxCandidates, 1);
    candidateCount = 0;
    
    % RELAXED PARAMETERS (ตรงกับเวอร์ชันหลัก)
    AR_MIN = 2.0;
    AR_MAX = 6.0;
    AREA_MIN = 0.005;
    AREA_MAX = 0.25;
    SOLIDITY_MIN = 0.55;
    EXTENT_MIN = 0.35;
    EDGE_DENSITY_MIN = 0.10;
    
    for i = 1:length(stats)
        bbox_roi = stats(i).BoundingBox;
        w = bbox_roi(3);
        h = bbox_roi(4);
        area = stats(i).Area;
        solidity = stats(i).Solidity;
        extent = stats(i).Extent;
        
        aspectRatio = w / h;
        relativeArea = area / roiArea;
        
        % Relaxed criteria
        validAR = (aspectRatio >= AR_MIN) && (aspectRatio <= AR_MAX);
        validArea = (relativeArea >= AREA_MIN) && (relativeArea <= AREA_MAX);
        validSolidity = (solidity >= SOLIDITY_MIN);
        validExtent = (extent >= EXTENT_MIN);
        
        % Edge Density
        x = max(1, round(bbox_roi(1)));
        y = max(1, round(bbox_roi(2)));
        x2 = min(round(x + w), roiWidth);
        y2 = min(round(y + h), roiHeight);
        
        if x < x2 && y < y2
            roiEdges = edgeMap(y:y2, x:x2);
            edgeDensity = sum(roiEdges(:)) / (w * h);
            validEdgeDensity = (edgeDensity >= EDGE_DENSITY_MIN);
        else
            edgeDensity = 0;
            validEdgeDensity = false;
        end
        
        % Print ALL regions with details
        fprintf('Region %d: AR=%.2f, Area=%.4f, Sol=%.2f, Ext=%.2f, EdgeD=%.3f', ...
                i, aspectRatio, relativeArea, solidity, extent, edgeDensity);
        
        if validAR && validArea && validSolidity && validExtent && validEdgeDensity
            candidateCount = candidateCount + 1;
            candidates(candidateCount) = i;
            
            score = calculateScoreRelaxed(aspectRatio, relativeArea, solidity, ...
                                        extent, edgeDensity, bbox_roi, roiHeight);
            candidateScores(candidateCount) = score;
            
            fprintf(' ✓ [Score: %.1f]\n', score);
        else
            fprintf(' ✗ (AR:%d Area:%d Sol:%d Ext:%d Edge:%d)\n', ...
                    validAR, validArea, validSolidity, validExtent, validEdgeDensity);
        end
    end
    
    candidates = candidates(1:candidateCount);
    candidateScores = candidateScores(1:candidateCount);
    
    %% ========================================
    %% 8. SELECT BEST
    %% ========================================
    if isempty(candidates)
        fprintf('⚠️  No valid candidates found\n');
        bbox = [];
    else
        [maxScore, bestIdx] = max(candidateScores);
        bestRegion = candidates(bestIdx);
        bbox_roi = stats(bestRegion).BoundingBox;
        
        fprintf('\n🎯 Selected Region %d (Score: %.1f)\n', bestRegion, maxScore);
        
        bbox = [bbox_roi(1) + xStart - 1, ...
                bbox_roi(2) + yStart - 1, ...
                bbox_roi(3), ...
                bbox_roi(4)];
    end
    
    %% ========================================
    %% 9. VISUALIZATION
    %% ========================================
    if showDebug
        figure('Position', [50, 50, 1400, 900], 'Name', 'Detection Debug');
        
        % Row 1
        subplot(2,4,1);
        imshow(img);
        title('1. Original', 'FontWeight', 'bold');
        hold on;
        rectangle('Position', [xStart, yStart, xEnd-xStart, yEnd-yStart], ...
                  'EdgeColor', 'g', 'LineWidth', 2);
        hold off;
        
        subplot(2,4,2);
        imshow(roi);
        title('2. ROI', 'FontWeight', 'bold');
        
        subplot(2,4,3);
        imshow(roiPreprocessed);
        title('3. Preprocessed', 'FontWeight', 'bold');
        
        subplot(2,4,4);
        imshow(edgeMap);
        title('4. Edges', 'FontWeight', 'bold');
        
        % Row 2
        subplot(2,4,5);
        imshow(morphClosed);
        title('5. Closed', 'FontWeight', 'bold');
        
        subplot(2,4,6);
        imshow(morphFilled);
        title('6. Filled', 'FontWeight', 'bold');
        
        subplot(2,4,7);
        imshow(morphCleaned);
        title('7. Cleaned + Opened', 'FontWeight', 'bold');
        hold on;
        % Draw all regions
        for i = 1:length(stats)
            bbox_roi = stats(i).BoundingBox;
            rectangle('Position', bbox_roi, 'EdgeColor', 'y', 'LineWidth', 1);
            text(bbox_roi(1), bbox_roi(2)-5, sprintf('%d', i), ...
                 'Color', 'y', 'FontSize', 10, 'FontWeight', 'bold');
        end
        hold off;
        
        subplot(2,4,8);
        imshow(img);
        title('8. Result', 'FontWeight', 'bold');
        hold on;
        rectangle('Position', [xStart, yStart, xEnd-xStart, yEnd-yStart], ...
                  'EdgeColor', 'g', 'LineWidth', 1.5, 'LineStyle', '--');
        
        % Draw all candidates in yellow
        for i = 1:candidateCount
            idx = candidates(i);
            bbox_roi = stats(idx).BoundingBox;
            bbox_full = [bbox_roi(1) + xStart - 1, bbox_roi(2) + yStart - 1, ...
                        bbox_roi(3), bbox_roi(4)];
            rectangle('Position', bbox_full, 'EdgeColor', 'y', 'LineWidth', 1.5);
        end
        
        % Draw best in red
        if ~isempty(bbox)
            rectangle('Position', bbox, 'EdgeColor', 'r', 'LineWidth', 3);
            text(bbox(1), bbox(2)-10, 'DETECTED', ...
                 'Color', 'r', 'FontSize', 14, 'FontWeight', 'bold', ...
                 'BackgroundColor', 'w');
        else
            text(10, 30, '⚠️ NOT DETECTED', ...
                 'Color', 'r', 'FontSize', 14, 'FontWeight', 'bold', ...
                 'BackgroundColor', 'w');
        end
        hold off;
    end
end

%% ========================================
%% HELPER: RELAXED SCORING
%% ========================================
function score = calculateScoreRelaxed(aspectRatio, relativeArea, solidity, ...
                                      extent, edgeDensity, bbox_roi, roiHeight)
    score = 0;
    
    % Aspect Ratio (35)
    if aspectRatio >= 3.0 && aspectRatio <= 4.5
        score = score + 35;
    elseif aspectRatio >= 2.5 && aspectRatio <= 5.5
        score = score + 25;
    elseif aspectRatio >= 2.0 && aspectRatio <= 6.0
        score = score + 15;
    end
    
    % Area (20)
    if relativeArea >= 0.02 && relativeArea <= 0.10
        score = score + 20;
    elseif relativeArea >= 0.01 && relativeArea <= 0.18
        score = score + 14;
    elseif relativeArea >= 0.005 && relativeArea <= 0.25
        score = score + 8;
    end
    
    % Solidity (15)
    if solidity >= 0.75
        score = score + 15;
    elseif solidity >= 0.65
        score = score + 12;
    elseif solidity >= 0.55
        score = score + 8;
    end
    
    % Extent (10)
    if extent >= 0.60
        score = score + 10;
    elseif extent >= 0.50
        score = score + 7;
    elseif extent >= 0.35
        score = score + 4;
    end
    
    % Edge Density (15)
    if edgeDensity >= 0.18
        score = score + 15;
    elseif edgeDensity >= 0.13
        score = score + 12;
    elseif edgeDensity >= 0.10
        score = score + 8;
    end
    
    % Position (5)
    centerY = bbox_roi(2) + bbox_roi(4)/2;
    normalizedY = centerY / roiHeight;
    if normalizedY >= 0.35 && normalizedY <= 0.65
        score = score + 5;
    elseif normalizedY >= 0.25 && normalizedY <= 0.75
        score = score + 3;
    elseif normalizedY >= 0.15 && normalizedY <= 0.85
        score = score + 1;
    end
end