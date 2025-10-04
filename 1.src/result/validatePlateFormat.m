function [is_valid, plate_type, formatted_text] = validatePlateFormat(plate_text, options)
% validatePlateFormat - Validate Thai license plate format
%
% Syntax:
%   is_valid = validatePlateFormat(plate_text)
%   [is_valid, plate_type] = validatePlateFormat(plate_text)
%   [is_valid, plate_type, formatted_text] = validatePlateFormat(plate_text, options)
%
% Inputs:
%   plate_text - Recognized text from OCR
%   options    - (Optional) Validation parameters
%
% Outputs:
%   is_valid       - Boolean: true if valid format
%   plate_type     - Type of plate ('standard', 'new', 'motorcycle', 'unknown')
%   formatted_text - Cleaned and formatted text
%
% Thai License Plate Formats:
%   Standard (Old):     XX-XXXX   (2 Thai + dash + 4 digits)
%   New Format:         XXXX      (1 digit + 2 Thai + 4 digits, no dash)
%   Motorcycle:         XX-XXX    (2 Thai + dash + 3 digits)
%   Provincial:         XXX-XXXX  (Thai province + digits)
%
% Example:
%   [valid, type] = validatePlateFormat('gor_kaid7dash1234');
%   if valid
%       fprintf('Valid %s plate\n', type);
%   end

    %% Handle inputs
    if nargin < 2
        options = struct();
    end
    
    %% Default parameters
    if ~isfield(options, 'strictMode'), options.strictMode = false; end
    if ~isfield(options, 'fixErrors'), options.fixErrors = true; end
    
    %% Initialize outputs
    is_valid = false;
    plate_type = 'unknown';
    formatted_text = '';
    
    %% Input validation
    if isempty(plate_text) || ~ischar(plate_text)
        return;
    end
    
    %% Preprocessing: Convert template names to actual characters
    cleaned_text = convertTemplateNames(plate_text);
    
    %% Count character types
    num_thai = countThaiChars(cleaned_text);
    num_digits = countDigits(cleaned_text);
    num_dash = countDashes(cleaned_text);
    total_chars = length(cleaned_text);
    
    %% Validate based on patterns
    
    % Pattern 1: Standard format (XX-XXXX)
    % 2 Thai + 1 dash + 4 digits = 7 characters
    if total_chars == 7 && num_thai == 2 && num_digits == 4 && num_dash == 1
        % Check position of dash (should be at position 3)
        if cleaned_text(3) == '-'
            is_valid = true;
            plate_type = 'standard';
            formatted_text = cleaned_text;
            return;
        end
    end
    
    % Pattern 2: New format (1XXX-XXXX)
    % 1 digit + 2 Thai + 1 dash + 4 digits = 8 characters
    if total_chars == 8 && num_thai == 2 && num_digits == 5 && num_dash == 1
        % Check if first char is digit and dash at position 4
        if isDigitChar(cleaned_text(1)) && cleaned_text(4) == '-'
            is_valid = true;
            plate_type = 'new';
            formatted_text = cleaned_text;
            return;
        end
    end
    
    % Pattern 3: Motorcycle (XX-XXX)
    % 2 Thai + 1 dash + 3 digits = 6 characters
    if total_chars == 6 && num_thai == 2 && num_digits == 3 && num_dash == 1
        if cleaned_text(3) == '-'
            is_valid = true;
            plate_type = 'motorcycle';
            formatted_text = cleaned_text;
            return;
        end
    end
    
    % Pattern 4: Provincial (varies)
    % Province code (Thai) + digits
    if num_thai >= 1 && num_digits >= 3 && total_chars >= 5
        is_valid = true;
        plate_type = 'provincial';
        formatted_text = cleaned_text;
        return;
    end
    
    %% Attempt to fix common errors if enabled
    if options.fixErrors && ~is_valid
        [fixed_text, fixed] = attemptFix(cleaned_text, num_thai, num_digits);
        if fixed
            % Recursively validate the fixed text
            [is_valid, plate_type, formatted_text] = validatePlateFormat(fixed_text);
            return;
        end
    end
    
    %% If not strict mode, accept partial matches
    if ~options.strictMode
        % Accept if we have reasonable number of characters
        if total_chars >= 5 && (num_thai >= 1 || num_digits >= 3)
            is_valid = true;
            plate_type = 'partial';
            formatted_text = cleaned_text;
            return;
        end
    end
    
    %% No valid pattern found
    formatted_text = cleaned_text;
end

%% Helper Functions

function clean_text = convertTemplateNames(text)
    % Convert template names to actual characters
    clean_text = text;
    
    % Convert digit names (d0-d9)
    for i = 0:9
        pattern = sprintf('d%d', i);
        replacement = num2str(i);
        clean_text = strrep(clean_text, pattern, replacement);
    end
    
    % Convert Thai character names to representative letters
    % Note: This is simplified - you may want to keep Thai names
    % or convert to actual Thai Unicode characters
    
    % Common Thai characters in plates
    thai_map = struct(...
        'kor_kai', 'ก', ...
        'khor_khai', 'ข', ...
        'khor_khuat', 'ฃ', ...
        'khor_khon', 'ค', ...
        'ngor_ngu', 'ง', ...
        'chor_chang', 'ช', ...
        'sor_sala', 'ศ', ...
        'thor_thong', 'ท', ...
        'nor_nen', 'น', ...
        'bor_baimai', 'บ', ...
        'por_phan', 'ป', ...
        'phor_phung', 'ผ', ...
        'for_fa', 'ฟ', ...
        'phor_samphao', 'พ', ...
        'mor_ma', 'ม', ...
        'yor_yak', 'ย', ...
        'ror_rua', 'ร', ...
        'lor_ling', 'ล', ...
        'wor_waen', 'ว', ...
        'sor_so', 'ซ', ...
        'thor_thahan', 'ฐ', ...
        'thor_montho', 'ฑ', ...
        'dor_dek', 'ด', ...
        'tor_tao', 'ต', ...
        'jor_jan', 'จ', ...
        'chor_choe', 'ฉ', ...
        'yor_ying', 'ญ', ...
        'dor_chada', 'ฎ', ...
        'tor_patak', 'ฏ', ...
        'nor_nu', 'น', ...
        'por_pla', 'ป', ...
        'for_fan', 'ฝ', ...
        'lue', 'ฬ', ...
        'rue', 'ร' ...
    );
    
    thai_names = fieldnames(thai_map);
    for i = 1:length(thai_names)
        name = thai_names{i};
        char_val = thai_map.(name);
        clean_text = strrep(clean_text, name, char_val);
    end
    
    % Keep dash as is
    % dash is already '-'
end

function count = countThaiChars(text)
    % Count Thai characters (Unicode range or placeholder letters)
    count = 0;
    for i = 1:length(text)
        c = text(i);
        % Check if Thai Unicode (3585-3675) or our placeholder letters
        if (c >= 'ก' && c <= 'ฮ')
            count = count + 1;
        end
    end
end

function count = countDigits(text)
    % Count digit characters
    count = sum(isstrprop(text, 'digit'));
end

function count = countDashes(text)
    % Count dash characters
    count = sum(text == '-');
end

function result = isDigitChar(c)
    % Check if character is a digit
    result = isstrprop(c, 'digit');
end

function [fixed_text, success] = attemptFix(text, num_thai, num_digits)
    % Attempt to fix common OCR errors
    fixed_text = text;
    success = false;
    
    % Error 1: Missing dash
    % If we have 2 Thai + 4 digits but no dash, insert dash
    if num_thai == 2 && num_digits == 4 && ~contains(text, '-')
        % Find position between Thai and digits
        for i = 1:length(text)-1
            if isThaiChar(text(i)) && isDigitChar(text(i+1))
                % Insert dash
                fixed_text = [text(1:i) '-' text(i+1:end)];
                success = true;
                return;
            end
        end
    end
    
    % Error 2: Extra characters (noise)
    % Remove leading/trailing noise
    if length(text) > 8
        % Try to extract core pattern
        % Look for sequence of Thai-digits
        % This is simplified - you may need more sophisticated logic
    end
end

function result = isThaiChar(c)
    % Check if character is Thai
    result = (c >= 'ก' && c <= 'ฮ');
end