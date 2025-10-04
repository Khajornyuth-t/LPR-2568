function bbox = detectPlateBoth(img)
% DETECTPLATEBOTH - ใช้ทั้ง Color-based และ Edge-based detection
%
% Syntax:
%   bbox = detectPlateBoth(img)
%
% Input:
%   img - RGB or grayscale image
%
% Output:
%   bbox - [x, y, width, height] หรือ [] ถ้าไม่เจอ
%
% Strategy:
%   1. ลอง Color-based ก่อน (ถ้าเป็น RGB)
%   2. ถ้าไม่เจอ ลอง Edge-based
%
% Author: LPR-2568 Project
% Date: 2025

    fprintf('\n========================================\n');
    fprintf('HYBRID DETECTION (Color + Edge)\n');
    fprintf('========================================\n');
    
    bbox = [];
    
    %% Try Color-based first (if RGB)
    if size(img, 3) == 3
        fprintf('\n--- Trying Color-Based Detection ---\n');
        try
            bbox = detectPlateColor(img);
        catch ME
            fprintf('Color-based failed: %s\n', ME.message);
        end
    end
    
    %% If not found, try Edge-based
    if isempty(bbox)
        fprintf('\n--- Trying Edge-Based Detection ---\n');
        try
            bbox = detectPlate(img);
        catch ME
            fprintf('Edge-based failed: %s\n', ME.message);
        end
    end
    
    %% Result
    if ~isempty(bbox)
        fprintf('\n✅ Detection successful!\n');
        fprintf('BBox: [%.0f, %.0f, %.0f, %.0f]\n', bbox);
    else
        fprintf('\n❌ Both methods failed\n');
    end
    fprintf('========================================\n\n');
end