function [char_images, char_boxes, debug_info] = segmentCharacters(binary_img, original_img, options)
% segmentCharacters - Segment individual characters from license plate
%
% Syntax:
%   [char_images, char_boxes] = segmentCharacters(binary_img)
%   [char_images, char_boxes] = segmentCharacters(binary_img, original_img)
%   [char_images, char_boxes, debug_info] = segmentCharacters(binary_img, original_img, options)
%
% Inputs:
%   binary_img   - Binary plate image (from preprocessPlate)
%   original_img - Original grayscale image (for debugging)
%   options      - (Optional) Segmentation parameters
%
% Outputs:
%   char_images - Cell array of character images
%   char_boxes  - N x 4 matrix [x, y, width, height] for each character
%   debug_info  - Struct with intermediate results
%
% Example:
%   [gray, binary] = preprocessPlate(plate_img);
%   [chars, boxes] = segmentCharacters(binary, gray);
%   imshow(chars{1}); % Show first character

    %% Handle inputs
    if nargin < 2
        original_img = [];
    end
    
    if nargin < 3
        options = struct();
    end
    
    %% Default parameters
    if ~isfield(options, 'minCharWidth'), options.minCharWidth = 10; end
    if ~isfield(options, 'maxCharWidth'), options.maxCharWidth = 100; end
    if ~isfield(options, 'minCharHeight'), options.minCharHeight = 20; end
    if ~isfield(options, 'maxCharHeight'), options.maxCharHeight = 150; end
    if ~isfield(options, 'minAspectRatio'), options.minAspectRatio = 0.2; end
    if ~isfield(options, 'maxAspectRatio'), options.maxAspectRatio = 1.5; end
    if ~isfield(options, 'debugMode'), options.debugMode = false; end
    
    %% Initialize outputs
    debug_info = struct();
    debug_info.binary_input = binary_img;
    
    %% Step 1: Find connected components
    cc = bwconncomp(binary_img);
    stats = regionprops(cc, 'BoundingBox', 'Area', 'Centroid', 'Extent');
    
    debug_info.num_components = cc.NumObjects;
    debug_info.all_stats = stats;
    
    %% Step 2: Filter components by size and shape
    % Preallocate for maximum possible size
    temp_valid = false(length(stats), 1);
    
    for i = 1:length(stats)
        bbox = stats(i).BoundingBox;
        width = bbox(3);
        height = bbox(4);
        area = stats(i).Area;
        extent = stats(i).Extent;
        
        % Calculate aspect ratio
        if height > 0
            aspect_ratio = width / height;
        else
            aspect_ratio = 0;
        end
        
        % Filter criteria
        is_valid_width = width >= options.minCharWidth && width <= options.maxCharWidth;
        is_valid_height = height >= options.minCharHeight && height <= options.maxCharHeight;
        is_valid_aspect = aspect_ratio >= options.minAspectRatio && aspect_ratio <= options.maxAspectRatio;
        is_valid_area = area >= 50; % Minimum area to avoid noise
        is_valid_extent = extent >= 0.3; % Avoid very sparse regions
        
        temp_valid(i) = is_valid_width && is_valid_height && is_valid_aspect && is_valid_area && is_valid_extent;
    end
    
    % Get indices of valid components
    valid_indices = find(temp_valid);
    
    debug_info.num_valid = length(valid_indices);
    debug_info.valid_indices = valid_indices;
    
    %% Step 3: Sort characters from left to right
    if ~isempty(valid_indices)
        centroids = zeros(length(valid_indices), 2);
        for i = 1:length(valid_indices)
            centroids(i, :) = stats(valid_indices(i)).Centroid;
        end
        
        [~, sort_idx] = sort(centroids(:, 1)); % Sort by x-coordinate
        valid_indices = valid_indices(sort_idx);
        
        debug_info.sorted_indices = valid_indices;
    end
    
    %% Step 4: Extract character images
    num_chars = length(valid_indices);
    char_images = cell(num_chars, 1);
    char_boxes = zeros(num_chars, 4);
    
    for i = 1:num_chars
        idx = valid_indices(i);
        bbox = stats(idx).BoundingBox;
        
        % Round and ensure integer values
        x = round(bbox(1));
        y = round(bbox(2));
        w = round(bbox(3));
        h = round(bbox(4));
        
        % Ensure coordinates are within image bounds
        [img_h, img_w] = size(binary_img);
        x = max(1, min(x, img_w - w));
        y = max(1, min(y, img_h - h));
        
        % Crop character from binary image
        char_img = binary_img(y:y+h-1, x:x+w-1);
        
        % Add small padding
        char_img = padarray(char_img, [5 5], 0, 'both');
        
        % Store results
        char_images{i} = char_img;
        char_boxes(i, :) = [x, y, w, h];
    end
    
    debug_info.char_boxes = char_boxes;
    
    %% Step 5: Post-processing - Handle special cases
    % Check if dash (-) is detected
    % Thai plates usually have format: XX-XXXX or X-XXXX
    % We expect 6-8 characters total (including dash)
    
    if num_chars < 5
        warning('Only %d characters detected. Expected 6-8 characters.', num_chars);
        debug_info.warning = 'Too few characters';
    elseif num_chars > 9
        warning('Too many characters detected (%d). May have noise.', num_chars);
        debug_info.warning = 'Too many characters';
    end
    
    %% Debug visualization
    if options.debugMode
        figure('Name', 'Character Segmentation');
        
        % Show original with bounding boxes
        subplot(2, 2, 1);
        if ~isempty(original_img)
            imshow(original_img);
        else
            imshow(binary_img);
        end
        hold on;
        for i = 1:num_chars
            rectangle('Position', char_boxes(i, :), 'EdgeColor', 'r', 'LineWidth', 2);
            text(char_boxes(i, 1), char_boxes(i, 2) - 5, sprintf('%d', i), ...
                'Color', 'yellow', 'FontSize', 12, 'FontWeight', 'bold');
        end
        title(sprintf('Detected %d characters', num_chars));
        hold off;
        
        % Show binary image
        subplot(2, 2, 2);
        imshow(binary_img);
        title('Binary Input');
        
        % Show all segmented characters
        subplot(2, 2, [3, 4]);
        if num_chars > 0
            % Create montage of characters
            max_h = max(cellfun(@(x) size(x, 1), char_images));
            combined = [];
            for i = 1:num_chars
                char_resized = imresize(char_images{i}, [max_h, NaN]);
                combined = [combined, ones(max_h, 5), char_resized]; %#ok<AGROW>
            end
            imshow(combined);
            title('Segmented Characters (left to right)');
        else
            axis off;
            text(0.5, 0.5, 'No characters detected', 'HorizontalAlignment', 'center');
        end
    end
    
end