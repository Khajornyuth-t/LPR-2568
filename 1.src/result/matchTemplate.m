function [score, best_match] = matchTemplate(char_img, template_img)
% matchTemplate - Match character image with template using correlation
%
% Syntax:
%   score = matchTemplate(char_img, template_img)
%   [score, best_match] = matchTemplate(char_img, template_img)
%
% Inputs:
%   char_img     - Character image to recognize (binary)
%   template_img - Reference template image (binary)
%
% Outputs:
%   score      - Similarity score (0-1, higher is better)
%   best_match - Aligned template for visualization
%
% Example:
%   score = matchTemplate(char_img, template_img);
%   if score > 0.7
%       disp('Good match!');
%   end

    %% Input validation
    if isempty(char_img) || isempty(template_img)
        score = 0;
        best_match = [];
        return;
    end
    
    %% Convert to binary if needed
    if ~islogical(char_img)
        char_img = imbinarize(char_img);
    end
    
    if ~islogical(template_img)
        template_img = imbinarize(template_img);
    end
    
    %% Resize character to match template size
    % Get sizes
    [char_h, char_w] = size(char_img);
    [temp_h, temp_w] = size(template_img);
    
    % Resize character to template size while preserving aspect ratio
    char_aspect = char_w / char_h;
    temp_aspect = temp_w / temp_h;
    
    if char_aspect > temp_aspect
        % Character is wider - fit to template width
        new_w = temp_w;
        new_h = round(temp_w / char_aspect);
    else
        % Character is taller - fit to template height
        new_h = temp_h;
        new_w = round(temp_h * char_aspect);
    end
    
    % Ensure minimum size
    new_h = max(new_h, 1);
    new_w = max(new_w, 1);
    
    % Resize
    char_resized = imresize(char_img, [new_h, new_w]);
    
    %% Center the resized character in template-sized canvas
    canvas = false(temp_h, temp_w);
    
    % Calculate position to center the character
    start_y = round((temp_h - new_h) / 2) + 1;
    start_x = round((temp_w - new_w) / 2) + 1;
    
    % Place character in center
    end_y = min(start_y + new_h - 1, temp_h);
    end_x = min(start_x + new_w - 1, temp_w);
    
    actual_h = end_y - start_y + 1;
    actual_w = end_x - start_x + 1;
    
    canvas(start_y:end_y, start_x:end_x) = char_resized(1:actual_h, 1:actual_w);
    
    char_aligned = canvas;
    
    %% Method 1: Normalized Cross-Correlation
    % Convert to double for correlation
    char_double = double(char_aligned);
    temp_double = double(template_img);
    
    % Compute correlation coefficient
    ncc = corrcoef(char_double(:), temp_double(:));
    score_ncc = (ncc(1,2) + 1) / 2; % Normalize to 0-1
    
    % Handle NaN (when one image is all zeros)
    if isnan(score_ncc)
        score_ncc = 0;
    end
    
    %% Method 2: Intersection over Union (IoU)
    intersection = sum(char_aligned(:) & template_img(:));
    union = sum(char_aligned(:) | template_img(:));
    
    if union > 0
        score_iou = intersection / union;
    else
        score_iou = 0;
    end
    
    %% Method 3: Pixel-wise similarity
    % Count matching pixels
    matching_pixels = sum(char_aligned(:) == template_img(:));
    total_pixels = numel(char_aligned);
    score_pixel = matching_pixels / total_pixels;
    
    %% Method 4: Hamming distance
    % XOR gives different pixels
    different_pixels = sum(xor(char_aligned(:), template_img(:)));
    score_hamming = 1 - (different_pixels / total_pixels);
    
    %% Combine scores (weighted average)
    % NCC is most reliable for shape matching
    % IoU is good for overlap measurement
    weights = [0.4, 0.3, 0.2, 0.1]; % [NCC, IoU, Pixel, Hamming]
    scores = [score_ncc, score_iou, score_pixel, score_hamming];
    
    score = sum(weights .* scores);
    
    %% Ensure score is in valid range
    score = max(0, min(1, score));
    
    %% Return aligned template for visualization
    best_match = char_aligned;
    
end