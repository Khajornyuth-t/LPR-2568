function generateQuickTemplates()
% generateQuickTemplates - สร้าง OCR templates ทั้งหมด 81 ตัว
%
% Description:
%   สร้างรูปภาพ template สำหรับการจดจำตัวอักษร
%   - Numbers: 0-9 (10 templates)
%   - Thai chars: ก-ฮ (44 templates)
%   - Latin chars: A-Z (26 templates)
%   - Special: - (1 template)
%
% Output: Binary images (42x24 pixels) in 3.templates/
%   3.templates/numbers/
%   3.templates/thai_chars/
%   3.templates/latin_chars/
%   3.templates/special/
%
% Template Convention:
%   - Character: White (255)
%   - Background: Black (0)
%   - Size: 42 (height) x 24 (width) pixels
%
% Usage:
%   cd('LPR-2568/1.src')
%   generateQuickTemplates()
%
% Author: Khajornyuth Tonphuban
% Course: EN2143201 - Digital Image Processing
% Date: 30 September 2025

fprintf('\n');
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('  TASK 2.2: Generating OCR Templates\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

%% Load character mappings
fprintf('📂 Loading character mappings...\n');

if ~exist('../4.utils/char_mapping.mat', 'file')
    error('❌ Mapping file not found! Please run createMappingFiles() first.');
end

load('../4.utils/char_mapping.mat', 'mapping');
fprintf('   ✅ Loaded: 4.utils/char_mapping.mat\n');
fprintf('   ✅ Total characters to generate: %d\n\n', mapping.total);

%% Configuration
config.template_height = 42;
config.template_width = 24;
config.font_thai = 'Angsana New';
config.font_latin = 'Arial Black';
config.font_number = 'Arial Black';
config.font_size_default = 32;
config.font_size_I = 34;  % Special for Latin "I"
config.padding = 3;

fprintf('⚙️  Template Configuration:\n');
fprintf('   • Size: %dx%d pixels\n', config.template_height, config.template_width);
fprintf('   • Thai font: %s\n', config.font_thai);
fprintf('   • Latin/Number font: %s\n', config.font_latin);
fprintf('   • Default font size: %d pt\n', config.font_size_default);
fprintf('   • Padding: %d pixels\n\n', config.padding);

%% Create template folders
fprintf('📁 Creating template directories...\n');

folders = {'../3.templates/numbers', '../3.templates/thai_chars', ...
           '../3.templates/latin_chars', '../3.templates/special'};

for i = 1:length(folders)
    if ~exist(folders{i}, 'dir')
        mkdir(folders{i});
    end
end

fprintf('   ✅ Created: 3.templates/numbers/\n');
fprintf('   ✅ Created: 3.templates/thai_chars/\n');
fprintf('   ✅ Created: 3.templates/latin_chars/\n');
fprintf('   ✅ Created: 3.templates/special/\n\n');

%% 1. Generate Numbers (0-9)
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('📊 Generating Numbers (0-9)...\n');
fprintf('═══════════════════════════════════════════════════════════\n');

for i = 1:length(mapping.number_chars)
    char_val = mapping.number_chars(i);
    filename = sprintf('../3.templates/numbers/%s.png', char_val);
    
    createCharacterImage(char_val, config.font_number, ...
                        config.font_size_default, filename, config);
    
    fprintf('  [%2d/10] Created: %s\n', i, filename);
end

fprintf('✅ Numbers complete: 10/10\n\n');

%% 2. Generate Thai Characters (ก-ฮ)
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('🇹🇭 Generating Thai Characters (ก-ฮ)...\n');
fprintf('═══════════════════════════════════════════════════════════\n');

for i = 1:length(mapping.thai_chars)
    char_val = mapping.thai_chars(i);
    char_name = mapping.thai_names{i};
    filename = sprintf('../3.templates/thai_chars/%s.png', char_name);
    
    createCharacterImage(char_val, config.font_thai, ...
                        config.font_size_default, filename, config);
    
    if mod(i, 10) == 0 || i == length(mapping.thai_chars)
        fprintf('  [%2d/44] Created: %s (%s)\n', i, char_name, char_val);
    end
end

fprintf('✅ Thai characters complete: 44/44\n\n');

%% 3. Generate Latin Characters (A-Z)
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('🔤 Generating Latin Characters (A-Z)...\n');
fprintf('═══════════════════════════════════════════════════════════\n');

for i = 1:length(mapping.latin_chars)
    char_val = mapping.latin_chars(i);
    filename = sprintf('../3.templates/latin_chars/%s.png', char_val);
    
    % Special handling for Latin "I"
    if char_val == 'I'
        font_size = config.font_size_I;
        fprintf('  [%2d/26] Created: %s (⚠️  Special: size=%d)\n', i, filename, font_size);
    else
        font_size = config.font_size_default;
        if mod(i, 5) == 0 || i == length(mapping.latin_chars)
            fprintf('  [%2d/26] Created: %s\n', i, filename);
        end
    end
    
    createCharacterImage(char_val, config.font_latin, ...
                        font_size, filename, config);
end

fprintf('✅ Latin characters complete: 26/26\n\n');

%% 4. Generate Special Character (-)
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('➖ Generating Special Character (-)...\n');
fprintf('═══════════════════════════════════════════════════════════\n');

filename = '../3.templates/special/dash.png';
createCharacterImage('-', config.font_latin, ...
                    config.font_size_default, filename, config);

fprintf('  [1/1] Created: %s\n', filename);
fprintf('✅ Special character complete: 1/1\n\n');

%% Summary
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('✅ TEMPLATE GENERATION COMPLETE!\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

fprintf('📊 Summary:\n');
fprintf('   • Numbers:         10 templates ✅\n');
fprintf('   • Thai chars:      44 templates ✅\n');
fprintf('   • Latin chars:     26 templates ✅\n');
fprintf('   • Special:          1 template  ✅\n');
fprintf('   ───────────────────────────────────\n');
fprintf('   • TOTAL:           81 templates ✅\n\n');

fprintf('📁 Output Location: 3.templates/\n');
fprintf('   ├── numbers/      (10 files)\n');
fprintf('   ├── thai_chars/   (44 files)\n');
fprintf('   ├── latin_chars/  (26 files)\n');
fprintf('   └── special/      (1 file)\n\n');

fprintf('⏭️  Next Step:\n');
fprintf('   Run: testTemplates()\n');
fprintf('   This will validate all generated templates\n\n');

fprintf('═══════════════════════════════════════════════════════════\n\n');

end


%% Helper Function: Create Character Image
function createCharacterImage(char_val, font_name, font_size, output_path, config)
% createCharacterImage - สร้าง binary image จาก character
%
% Inputs:
%   char_val: ตัวอักษรที่ต้องการสร้าง
%   font_name: ชื่อ font
%   font_size: ขนาด font (pt)
%   output_path: path สำหรับบันทึก
%   config: configuration struct

% สร้าง figure แบบไม่แสดง
fig = figure('Visible', 'off', 'Color', 'white', 'Position', [0, 0, 200, 200]);
ax = axes('Parent', fig, 'Position', [0, 0, 1, 1]);
axis(ax, 'off');

% เขียนตัวอักษร
text(ax, 0.5, 0.5, char_val, ...
     'FontName', font_name, ...
     'FontSize', font_size, ...
     'FontWeight', 'bold', ...
     'HorizontalAlignment', 'center', ...
     'VerticalAlignment', 'middle', ...
     'Color', 'black');

% Capture เป็นภาพ
frame = getframe(fig);
img = frame.cdata;

% แปลงเป็น grayscale
img_gray = rgb2gray(img);

% Binarize (threshold)
threshold = graythresh(img_gray);
img_bw = ~imbinarize(img_gray, threshold);  % Invert: ตัวอักษรเป็นขาว

% Crop เอาเฉพาะส่วนที่มีตัวอักษร
[rows, cols] = find(img_bw);

if ~isempty(rows)
    row_min = max(1, min(rows) - config.padding);
    row_max = min(size(img_bw, 1), max(rows) + config.padding);
    col_min = max(1, min(cols) - config.padding);
    col_max = min(size(img_bw, 2), max(cols) + config.padding);
    
    img_cropped = img_bw(row_min:row_max, col_min:col_max);
else
    % ถ้าไม่เจอตัวอักษร ใช้ภาพเดิม
    img_cropped = img_bw;
end

% Resize เป็นขนาดมาตรฐาน
img_resized = imresize(img_cropped, [config.template_height, config.template_width]);

% แปลงเป็น binary อีกครั้ง (เผื่อ resize ทำให้เกิด gray values)
img_final = img_resized > 0.5;

% บันทึก
imwrite(img_final, output_path);

% ปิด figure
close(fig);

end