function [character, confidence, all_scores] = recognizeCharacter(char_img, templates, options)
% recognizeCharacter - Recognize single character using template matching
%
% Syntax:
%   character = recognizeCharacter(char_img, templates)
%   [character, confidence] = recognizeCharacter(char_img, templates)
%   [character, confidence, all_scores] = recognizeCharacter(char_img, templates, options)
%
% Inputs:
%   char_img  - Single character image (binary or grayscale)
%   templates - Structure with Thai and digit templates
%   options   - (Optional) Recognition parameters
%
% Outputs:
%   character  - Recognized character (string)
%   confidence - Match confidence (0-1)
%   all_scores - Structure with all matching scores (for debugging)
%
% Example:
%   load('../../templates/templates.mat');
%   [char, conf] = recognizeCharacter(char_img, templates);
%   fprintf('Character: %s (%.1f%%)\n', char, conf*100);

    %% Handle inputs
    if nargin < 3
        options = struct();
    end
    
    %% Default parameters
    if ~isfield(options, 'minConfidence'), options.minConfidence = 0.3; end
    if ~isfield(options, 'debugMode'), options.debugMode = false; end
    
    %% Initialize outputs
    character = '';
    confidence = 0;
    all_scores = struct();
    
    %% Input validation
    if isempty(char_img)
        warning('Empty character image provided');
        return;
    end
    
    %% Convert to binary if needed
    if ~islogical(char_img)
        if max(char_img(:)) > 1
            char_img = imbinarize(char_img);
        else
            char_img = char_img > 0.5;
        end
    end
    
    %% Preprocess character image
    % Remove border padding if exists
    char_img = bwareaopen(char_img, 5); % Remove tiny noise
    
    % Find bounding box and crop tightly
    stats = regionprops(char_img, 'BoundingBox');
    if ~isempty(stats)
        bbox = stats(1).BoundingBox;
        x = max(1, round(bbox(1)));
        y = max(1, round(bbox(2)));
        w = round(bbox(3));
        h = round(bbox(4));
        
        [img_h, img_w] = size(char_img);
        x_end = min(x + w - 1, img_w);
        y_end = min(y + h - 1, img_h);
        
        char_img = char_img(y:y_end, x:x_end);
    end
    
    %% Match with all templates
    best_score = 0;
    best_char = '';
    best_category = '';
    
    % Thai characters
    if isfield(templates, 'thai')
        thai_chars = fieldnames(templates.thai);
        thai_scores = zeros(length(thai_chars), 1);
        
        for i = 1:length(thai_chars)
            char_name = thai_chars{i};
            template = templates.thai.(char_name);
            
            % Match
            score = matchTemplate(char_img, template);
            thai_scores(i) = score;
            
            % Update best match
            if score > best_score
                best_score = score;
                best_char = char_name;
                best_category = 'thai';
            end
        end
        
        all_scores.thai_chars = thai_chars;
        all_scores.thai_scores = thai_scores;
    end
    
    % Digits
    if isfield(templates, 'digits')
        digit_chars = fieldnames(templates.digits);
        digit_scores = zeros(length(digit_chars), 1);
        
        for i = 1:length(digit_chars)
            char_name = digit_chars{i};
            template = templates.digits.(char_name);
            
            % Match
            score = matchTemplate(char_img, template);
            digit_scores(i) = score;
            
            % Update best match
            if score > best_score
                best_score = score;
                best_char = char_name;
                best_category = 'digits';
            end
        end
        
        all_scores.digit_chars = digit_chars;
        all_scores.digit_scores = digit_scores;
    end
    
    % Special characters (dash, etc.)
    if isfield(templates, 'special')
        special_chars = fieldnames(templates.special);
        special_scores = zeros(length(special_chars), 1);
        
        for i = 1:length(special_chars)
            char_name = special_chars{i};
            template = templates.special.(char_name);
            
            % Match
            score = matchTemplate(char_img, template);
            special_scores(i) = score;
            
            % Update best match
            if score > best_score
                best_score = score;
                best_char = char_name;
                best_category = 'special';
            end
        end
        
        all_scores.special_chars = special_chars;
        all_scores.special_scores = special_scores;
    end
    
    %% Check confidence threshold
    if best_score >= options.minConfidence
        character = best_char;
        confidence = best_score;
        all_scores.best_category = best_category;
    else
        character = '?'; % Unknown character
        confidence = best_score;
        all_scores.best_category = 'unknown';
    end
    
    all_scores.best_score = best_score;
    all_scores.best_char = best_char;
    
    %% Debug visualization
    if options.debugMode && ~isempty(character) && character ~= '?'
        figure('Name', 'Character Recognition Debug');
        
        % Show input character
        subplot(2, 3, 1);
        imshow(char_img);
        title('Input Character');
        
        % Show best matching template
        subplot(2, 3, 2);
        if strcmp(best_category, 'thai')
            imshow(templates.thai.(best_char));
        elseif strcmp(best_category, 'digits')
            imshow(templates.digits.(best_char));
        elseif strcmp(best_category, 'special')
            imshow(templates.special.(best_char));
        end
        title(sprintf('Best Match: %s', best_char));
        
        % Show overlay
        subplot(2, 3, 3);
        [~, aligned] = matchTemplate(char_img, templates.(best_category).(best_char));
        overlay = cat(3, char_img, aligned, zeros(size(char_img)));
        imshow(overlay);
        title(sprintf('Overlay (Score: %.2f)', best_score));
        
        % Plot Thai character scores
        if isfield(all_scores, 'thai_scores')
            subplot(2, 3, 4);
            bar(all_scores.thai_scores);
            xlabel('Thai Character Index');
            ylabel('Score');
            title('Thai Character Scores');
            ylim([0, 1]);
            grid on;
        end
        
        % Plot digit scores
        if isfield(all_scores, 'digit_scores')
            subplot(2, 3, 5);
            bar(all_scores.digit_scores);
            xlabel('Digit Index');
            ylabel('Score');
            title('Digit Scores');
            ylim([0, 1]);
            grid on;
        end
        
        % Show top 5 matches
        subplot(2, 3, 6);
        axis off;
        
        % Combine all scores
        all_char_names = {};
        all_char_scores = [];
        
        if isfield(all_scores, 'thai_scores')
            all_char_names = [all_char_names; all_scores.thai_chars];
            all_char_scores = [all_char_scores; all_scores.thai_scores];
        end
        if isfield(all_scores, 'digit_scores')
            all_char_names = [all_char_names; all_scores.digit_chars];
            all_char_scores = [all_char_scores; all_scores.digit_scores];
        end
        
        [sorted_scores, idx] = sort(all_char_scores, 'descend');
        sorted_names = all_char_names(idx);
        
        text_str = sprintf('Top 5 Matches:\n\n');
        for i = 1:min(5, length(sorted_scores))
            text_str = sprintf('%s%d. %s: %.3f\n', text_str, i, sorted_names{i}, sorted_scores(i));
        end
        
        text(0.1, 0.5, text_str, 'FontSize', 10, 'FontName', 'Courier');
    end
    
end