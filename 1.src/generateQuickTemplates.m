function generateQuickTemplates()
% generateQuickTemplates - สร้าง OCR templates ทั้งหมด 55 ตัว
%
% คำอธิบาย:
%   สร้างรูปภาพ template สำหรับการจดจำตัวอักษร
%   - Numbers: 0-9 (10 templates)
%   - Thai chars: ก-ฮ (44 templates)
%   - Special: - (1 template)
%
% หมายเหตุ: ไม่รวมอักษรละติน (A-Z) เพราะป้ายทะเบียนไทยไม่มี
%
% Output: Binary images (42x24 pixels) ใน 3.templates/
%   3.templates/numbers/
%   3.templates/thai_chars/
%   3.templates/special/
%
% รูปแบบ Template:
%   - ตัวอักษร: สีขาว (255)
%   - พื้นหลัง: สีดำ (0)
%   - ขนาด: 42 (สูง) x 24 (กว้าง) pixels
%
% วิธีใช้:
%   cd('LPR-2568/1.src')
%   generateQuickTemplates()
%
% ผู้เขียน: ขจรยุทธ ต้นภูบาล
% วิชา: EN2143201 - Digital Image Processing
% วันที่: 30 กันยายน 2568

fprintf('\n');
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('  TASK 2.2: สร้าง OCR Templates\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

%% โหลด character mappings
fprintf('📂 โหลดข้อมูลตัวอักษร...\n');

if ~exist('../4.utils/char_mapping.mat', 'file')
    error('❌ ไม่พบไฟล์ mapping! กรุณารัน createMappingFiles() ก่อน');
end

load('../4.utils/char_mapping.mat', 'mapping');
fprintf('   ✅ โหลดแล้ว: 4.utils/char_mapping.mat\n');
fprintf('   ✅ จำนวนตัวอักษรที่ต้องสร้าง: %d\n\n', mapping.total);

%% ตั้งค่า
config.template_height = 42;
config.template_width = 24;
config.font_thai = 'Angsana New';
config.font_number = 'Arial Black';
config.font_size_default = 32;
config.padding = 3;

fprintf('⚙️  การตั้งค่า Template:\n');
fprintf('   • ขนาด: %dx%d pixels\n', config.template_height, config.template_width);
fprintf('   • ฟอนต์ไทย: %s\n', config.font_thai);
fprintf('   • ฟอนต์ตัวเลข: %s\n', config.font_number);
fprintf('   • ขนาดฟอนต์: %d pt\n', config.font_size_default);
fprintf('   • Padding: %d pixels\n\n', config.padding);

%% สร้างโฟลเดอร์
fprintf('📁 สร้างโฟลเดอร์ templates...\n');

folders = {'../3.templates/numbers', '../3.templates/thai_chars', ...
           '../3.templates/special'};

for i = 1:length(folders)
    if ~exist(folders{i}, 'dir')
        mkdir(folders{i});
    end
end

fprintf('   ✅ สร้างแล้ว: 3.templates/numbers/\n');
fprintf('   ✅ สร้างแล้ว: 3.templates/thai_chars/\n');
fprintf('   ✅ สร้างแล้ว: 3.templates/special/\n\n');

%% 1. สร้างตัวเลข (0-9)
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('📊 สร้างตัวเลข (0-9)...\n');
fprintf('═══════════════════════════════════════════════════════════\n');

for i = 1:length(mapping.number_chars)
    char_val = mapping.number_chars(i);
    filename = sprintf('../3.templates/numbers/%s.png', char_val);
    
    createCharacterImage(char_val, config.font_number, ...
                        config.font_size_default, filename, config);
    
    fprintf('  [%2d/10] สร้างแล้ว: %s\n', i, filename);
end

fprintf('✅ ตัวเลขสร้างเสร็จ: 10/10\n\n');

%% 2. สร้างอักษรไทย (ก-ฮ)
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('🇹🇭 สร้างอักษรไทย (ก-ฮ)...\n');
fprintf('═══════════════════════════════════════════════════════════\n');

for i = 1:length(mapping.thai_chars)
    char_val = mapping.thai_chars(i);
    char_name = mapping.thai_names{i};
    filename = sprintf('../3.templates/thai_chars/%s.png', char_name);
    
    createCharacterImage(char_val, config.font_thai, ...
                        config.font_size_default, filename, config);
    
    if mod(i, 10) == 0 || i == length(mapping.thai_chars)
        fprintf('  [%2d/44] สร้างแล้ว: %s (%s)\n', i, char_name, char_val);
    end
end

fprintf('✅ อักษรไทยสร้างเสร็จ: 44/44\n\n');

%% 3. สร้างอักขระพิเศษ (-)
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('➖ สร้างอักขระพิเศษ (-)...\n');
fprintf('═══════════════════════════════════════════════════════════\n');

filename = '../3.templates/special/dash.png';
createCharacterImage('-', config.font_number, ...
                    config.font_size_default, filename, config);

fprintf('  [1/1] สร้างแล้ว: %s\n', filename);
fprintf('✅ อักขระพิเศษสร้างเสร็จ: 1/1\n\n');

%% สรุปผล
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('✅ สร้าง TEMPLATES สำเร็จ!\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

fprintf('📊 สรุป:\n');
fprintf('   • ตัวเลข:        10 templates ✅\n');
fprintf('   • อักษรไทย:      44 templates ✅\n');
fprintf('   • อักขระพิเศษ:    1 template  ✅\n');
fprintf('   ───────────────────────────────────\n');
fprintf('   • รวมทั้งหมด:    55 templates ✅\n\n');

fprintf('📁 ตำแหน่งไฟล์: 3.templates/\n');
fprintf('   ├── numbers/      (10 files)\n');
fprintf('   ├── thai_chars/   (44 files)\n');
fprintf('   └── special/      (1 file)\n\n');

fprintf('⏭️  ขั้นตอนต่อไป:\n');
fprintf('   รัน: testTemplates()\n');
fprintf('   จะตรวจสอบ templates ที่สร้างขึ้น\n\n');

fprintf('═══════════════════════════════════════════════════════════\n\n');

end


%% ฟังก์ชันช่วย: สร้างรูปภาพตัวอักษร
function createCharacterImage(char_val, font_name, font_size, output_path, config)
% createCharacterImage - สร้าง binary image จากตัวอักษร
%
% Inputs:
%   char_val: ตัวอักษรที่ต้องการสร้าง
%   font_name: ชื่อฟอนต์
%   font_size: ขนาดฟอนต์ (pt)
%   output_path: path สำหรับบันทึก
%   config: configuration struct

% สร้าง figure แบบซ่อน
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
img_bw = ~imbinarize(img_gray, threshold);  % Invert: ตัวอักษรเป็นสีขาว

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