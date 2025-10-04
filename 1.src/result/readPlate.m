function [plate_text, confidence, debug_info] = readPlate(plate_img, templates, options)
% readPlate - Complete OCR pipeline for license plate recognition
%
% This is the main function that combines all OCR steps:
%   1. Preprocessing (preprocessPlate)
%   2. Character segmentation (segmentCharacters)
%   3. Character recognition (recognizeCharacter)
%   4. Format validation (validatePlateFormat)
%
% Syntax:
%   plate_text = readPlate(plate_img, templates)
%   [plate_text, confidence] = readPlate(plate_img, templates)
%   [plate_text, confidence, debug_info] = readPlate(plate_img, templates, options)
%
% Inputs:
%   plate_img - Cropped license plate image (from detection)
%   templates - Template structure (from templates.mat)
%   options   - (Optional) Recognition parameters
%
% Outputs:
%   plate_text - Recognized plate text (e.g., "กก-1234")
%   confidence - Overall confidence score (0-1)
%   debug_info - Detailed information about each step
%
% Example:
%   load('templates/templates.mat');
%   plate_img = imread('detected_plates/plate_001.jpg');
%   [text, conf] = readPlate(plate_img, templates);
%   fprintf('Plate: %s (%.1f%% confidence)\n', text, conf*100);

    %% Handle inputs
    if nargin < 3
        options = struct();
    end
    
    %% Default parameters
    if ~isfield(options, 'preprocessMethod'), options.preprocessMethod = 'otsu'; end
    if ~isfield(options, 'minCharConfidence'), options.minCharConfidence = 0.3; end
    if ~isfield(options, 'validateFormat'), options.validateFormat = true; end
    if ~isfield(options, 'debugMode'), options.debugMode = false; end
    
    %% Initialize outputs
    plate_text = '';
    confidence = 0;
    debug_info = struct();
    
    %% Input validation
    if isempty(plate_img)
        warning('Empty plate image');
        return;
    end
    
    try
        %% Step 1: Preprocessing
        if options.debugMode
            fprintf('Step 1: Preprocessing plate image...\n');
        end
        
        preprocess_opts = struct();
        preprocess_opts.method = options.preprocessMethod;
        preprocess_opts.debugMode = false;
        
        [gray_img, binary_img, preprocess_debug] = preprocessPlate(plate_img, preprocess_opts);
        
        debug_info.preprocessing = preprocess_debug;
        debug_info.gray_image = gray_img;
        debug_info.binary_image = binary_img;
        
        %% Step 2: Character Segmentation
        if options.debugMode
            fprintf('Step 2: Segmenting characters...\n');
        end
        
        segment_opts = struct();
        segment_opts.debugMode = false;
        
        [char_images, char_boxes, segment_debug] = segmentCharacters(binary_img, gray_img, segment_opts);
        
        num_chars = length(char_images);
        debug_info.segmentation = segment_debug;
        debug_info.char_images = char_images;
        debug_info.char_boxes = char_boxes;
        debug_info.num_chars = num_chars;
        
        if options.debugMode
            fprintf('  → Found %d characters\n', num_chars);
        end
        
        if num_chars == 0
            if options.debugMode
                fprintf('  ✗ No characters found\n');
            end
            return;
        end
        
        %% Step 3: Character Recognition
        if options.debugMode
            fprintf('Step 3: Recognizing characters...\n');
        end
        
        recognize_opts = struct();
        recognize_opts.minConfidence = options.minCharConfidence;
        recognize_opts.debugMode = false;
        
        recognized_chars = cell(num_chars, 1);
        char_confidences = zeros(num_chars, 1);
        char_scores_all = cell(num_chars, 1);
        
        for i = 1:num_chars
            [char, conf, scores] = recognizeCharacter(char_images{i}, templates, recognize_opts);
            recognized_chars{i} = char;
            char_confidences(i) = conf;
            char_scores_all{i} = scores;
            
            if options.debugMode
                fprintf('  Char %d: "%s" (%.1f%%)\n', i, char, conf*100);
            end
        end
        
        debug_info.recognized_chars = recognized_chars;
        debug_info.char_confidences = char_confidences;
        debug_info.all_scores = char_scores_all;
        
        %% Step 4: Combine characters
        raw_text = strjoin(recognized_chars, '');
        avg_confidence = mean(char_confidences);
        
        if options.debugMode
            fprintf('Step 4: Raw text: "%s" (avg conf: %.1f%%)\n', raw_text, avg_confidence*100);
        end
        
        debug_info.raw_text = raw_text;
        debug_info.raw_confidence = avg_confidence;
        
        %% Step 5: Format Validation
        if options.validateFormat
            if options.debugMode
                fprintf('Step 5: Validating format...\n');
            end
            
            validate_opts = struct();
            validate_opts.strictMode = false;
            validate_opts.fixErrors = true;
            
            [is_valid, plate_type, formatted_text] = validatePlateFormat(raw_text, validate_opts);
            
            debug_info.is_valid_format = is_valid;
            debug_info.plate_type = plate_type;
            debug_info.formatted_text = formatted_text;
            
            if options.debugMode
                if is_valid
                    fprintf('  ✓ Valid %s format\n', plate_type);
                    fprintf('  → Formatted: "%s"\n', formatted_text);
                else
                    fprintf('  ⚠ Invalid format (using raw text)\n');
                end
            end
            
            % Use formatted text if valid, otherwise use raw
            if is_valid
                plate_text = formatted_text;
            else
                plate_text = raw_text;
            end
        else
            plate_text = raw_text;
            debug_info.is_valid_format = false;
            debug_info.plate_type = 'unknown';
        end
        
        %% Calculate overall confidence
        % Combine character confidence with format validity
        if debug_info.is_valid_format
            % Boost confidence if format is valid
            confidence = avg_confidence * 1.1;
            confidence = min(confidence, 1.0); % Cap at 1.0
        else
            % Penalize if format is invalid
            confidence = avg_confidence * 0.9;
        end
        
        debug_info.final_confidence = confidence;
        
        %% Debug visualization
        if options.debugMode
            fprintf('\n=== FINAL RESULT ===\n');
            fprintf('Plate Text: "%s"\n', plate_text);
            fprintf('Confidence: %.1f%%\n', confidence*100);
            fprintf('Characters: %d\n', num_chars);
            fprintf('Valid Format: %s\n', mat2str(debug_info.is_valid_format));
            if debug_info.is_valid_format
                fprintf('Plate Type: %s\n', debug_info.plate_type);
            end
            fprintf('===================\n\n');
            
            % Create visualization
            visualizeOCRResult(plate_img, debug_info);
        end
        
    catch ME
        warning('readPlate:Error', '%s', ME.message);
        debug_info.error = ME.message;
        debug_info.error_stack = ME.stack;
    end
end

%% Visualization Helper
function visualizeOCRResult(plate_img, debug)
    % Create comprehensive visualization of OCR pipeline
    
    figure('Name', 'OCR Pipeline Result', 'Position', [100, 100, 1400, 800]);
    
    % Original image
    subplot(3, 4, 1);
    imshow(plate_img);
    title('1. Original Plate');
    
    % Grayscale
    subplot(3, 4, 2);
    if isfield(debug, 'gray_image')
        imshow(debug.gray_image);
    end
    title('2. Grayscale');
    
    % Binary
    subplot(3, 4, 3);
    if isfield(debug, 'binary_image')
        imshow(debug.binary_image);
    end
    title('3. Binary');
    
    % Segmentation
    subplot(3, 4, 4);
    imshow(plate_img);
    hold on;
    if isfield(debug, 'char_boxes') && ~isempty(debug.char_boxes)
        for i = 1:size(debug.char_boxes, 1)
            rectangle('Position', debug.char_boxes(i, :), 'EdgeColor', 'r', 'LineWidth', 2);
            text(debug.char_boxes(i, 1), debug.char_boxes(i, 2)-5, sprintf('%d', i), ...
                'Color', 'yellow', 'FontSize', 10, 'FontWeight', 'bold');
        end
    end
    hold off;
    title(sprintf('4. Segmentation (%d chars)', debug.num_chars));
    
    % Individual characters
    subplot(3, 4, [5, 6, 7, 8]);
    if isfield(debug, 'char_images') && ~isempty(debug.char_images)
        num_chars = length(debug.char_images);
        max_h = max(cellfun(@(x) size(x, 1), debug.char_images));
        combined = [];
        
        for i = 1:num_chars
            char_img = debug.char_images{i};
            char_resized = imresize(char_img, [max_h, NaN]);
            
            % Add separator and character
            combined = [combined, ones(max_h, 5), char_resized]; %#ok<AGROW>
        end
        
        imshow(combined);
        
        % Add recognized text below
        if isfield(debug, 'recognized_chars')
            text_str = strjoin(debug.recognized_chars, ' ');
            title(sprintf('5. Characters: %s', text_str));
        else
            title('5. Segmented Characters');
        end
    else
        axis off;
        text(0.5, 0.5, 'No characters detected', 'HorizontalAlignment', 'center');
        title('5. No Characters');
    end
    
    % Confidence plot
    subplot(3, 4, [9, 10]);
    if isfield(debug, 'char_confidences') && ~isempty(debug.char_confidences)
        bar(debug.char_confidences);
        ylim([0, 1]);
        xlabel('Character Index');
        ylabel('Confidence');
        title(sprintf('6. Character Confidences (avg: %.1f%%)', mean(debug.char_confidences)*100));
        grid on;
    else
        axis off;
        text(0.5, 0.5, 'No confidence data', 'HorizontalAlignment', 'center');
    end
    
    % Result summary
    subplot(3, 4, [11, 12]);
    axis off;
    
    summary_text = sprintf('FINAL RESULT\n\n');
    
    if isfield(debug, 'formatted_text')
        summary_text = sprintf('%sPlate Text:\n  "%s"\n\n', summary_text, debug.formatted_text);
    end
    
    if isfield(debug, 'final_confidence')
        summary_text = sprintf('%sConfidence: %.1f%%\n\n', summary_text, debug.final_confidence*100);
    end
    
    if isfield(debug, 'is_valid_format')
        summary_text = sprintf('%sValid Format: %s\n', summary_text, mat2str(debug.is_valid_format));
    end
    
    if isfield(debug, 'plate_type')
        summary_text = sprintf('%sPlate Type: %s\n', summary_text, debug.plate_type);
    end
    
    text(0.1, 0.7, summary_text, 'FontSize', 12, 'FontName', 'Courier', ...
        'VerticalAlignment', 'top', 'FontWeight', 'bold');
end