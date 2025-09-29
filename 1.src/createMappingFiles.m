function createMappingFiles()
% createMappingFiles - สร้างไฟล์ mapping สำหรับ characters ทั้งหมด
%
% Description:
%   สร้างฐานข้อมูลตัวอักษรสำหรับป้ายทะเบียนไทย 81 ตัว
%   - Numbers: 0-9 (10 ตัว)
%   - Thai consonants: ก-ฮ (44 ตัว)
%   - Latin letters: A-Z (26 ตัว)
%   - Special: - (1 ตัว)
%
% Output Files (in 1.src/ directory):
%   utils/char_mapping.mat           - MATLAB data structure
%   utils/thai_unicode.txt           - Thai character reference
%   utils/latin_mapping.txt          - Latin/Number reference
%
% Usage:
%   cd('LPR-2568/1.src')
%   createMappingFiles()
%
% Author: Khajornyuth Tonphuban
% Course: EN2143201 - Digital Image Processing
% Date: 30 September 2025

fprintf('\n');
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('  TASK 2.1: Creating Character Mapping Files\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

%% 1. Define Thai Characters (44 consonants)
fprintf('📝 Step 1/3: Defining Thai characters...\n');

% Thai consonants used in Thai license plates (ก-ฮ, 44 characters)
thai_chars = ['ก','ข','ฃ','ค','ฅ','ฆ','ง',...
              'จ','ฉ','ช','ซ','ฌ','ญ',...
              'ฎ','ฏ','ฐ','ฑ','ฒ','ณ',...
              'ด','ต','ถ','ท','ธ','น',...
              'บ','ป','ผ','ฝ','พ','ฟ','ภ','ม',...
              'ย','ร','ฤ','ล','ฦ','ว',...
              'ศ','ษ','ส','ห','ฬ','อ','ฮ'];

% Thai romanized names (for filename)
thai_names = {'kor_kai','khor_khai','khor_khuat','khor_khwai','khor_khon',...
              'khor_rakhang','ngor_ngu',...
              'jor_jan','chor_ching','chor_chang','sor_so','chor_choe','yor_ying',...
              'dor_chada','tor_patak','thor_than','thor_montho','thor_phuthao','nor_nen',...
              'dor_dek','tor_tao','thor_thung','thor_thahan','thor_thong','nor_nu',...
              'bor_baimai','por_pla','phor_phung','for_fa','phor_phan','for_fan','phor_samphao','mor_ma',...
              'yor_yak','ror_rua','rue','lor_ling','lue','wor_waen',...
              'sor_sala','sor_rusi','sor_suea','hor_hip','lor_chula','or_ang','hor_nokhuk'};

fprintf('   ✅ Thai consonants: %d characters\n', length(thai_chars));

%% 2. Define Latin Characters (A-Z)
fprintf('📝 Step 2/3: Defining Latin characters...\n');

latin_chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

fprintf('   ✅ Latin letters: %d characters\n', length(latin_chars));
fprintf('   ⚠️  Critical: "I" vs "1", "O" vs "0"\n');

%% 3. Define Numbers (0-9)
fprintf('📝 Step 3/3: Defining numbers and special characters...\n');

number_chars = '0123456789';
special_chars = '-';

fprintf('   ✅ Numbers: %d characters\n', length(number_chars));
fprintf('   ✅ Special: %d character\n', length(special_chars));

%% 4. Create mapping structure
fprintf('\n💾 Creating mapping structure...\n');

mapping = struct();
mapping.thai_chars = thai_chars;
mapping.thai_names = thai_names;
mapping.latin_chars = latin_chars;
mapping.number_chars = number_chars;
mapping.special_chars = special_chars;

% Summary
mapping.total = length(thai_chars) + length(latin_chars) + ...
                length(number_chars) + length(special_chars);

fprintf('   ✅ Total characters: %d\n', mapping.total);

%% 5. Create output directory
fprintf('\n💾 Saving files...\n');

if ~exist('../4.utils', 'dir')
    mkdir('../4.utils');
    fprintf('   ✅ Created directory: 4.utils/\n');
end

%% 6. Save MATLAB data file
save('../4.utils/char_mapping.mat', 'mapping');
fprintf('   ✅ Saved: 4.utils/char_mapping.mat\n');

%% 7. Create Thai Unicode reference file
fid = fopen('../4.utils/thai_unicode.txt', 'w', 'n', 'UTF-8');
fprintf(fid, '═══════════════════════════════════════════════════════════\n');
fprintf(fid, 'Thai Character Mapping for License Plate Recognition\n');
fprintf(fid, '═══════════════════════════════════════════════════════════\n');
fprintf(fid, 'Total: %d Thai consonants (ก-ฮ)\n', length(thai_chars));
fprintf(fid, 'Generated: %s\n', datetime('now', 'Format', 'dd-MMM-yyyy HH:mm:ss'));
fprintf(fid, '═══════════════════════════════════════════════════════════\n\n');

fprintf(fid, 'No.\tChar\tFilename\t\tUnicode\n');
fprintf(fid, '───────────────────────────────────────────────────────────\n');

for i = 1:length(thai_chars)
    fprintf(fid, '%2d\t%s\t%-20s\tU+%04X\n', ...
            i, ...
            thai_chars(i), ...
            [thai_names{i} '.png'], ...
            double(thai_chars(i)));
end

fprintf(fid, '\n═══════════════════════════════════════════════════════════\n');
fprintf(fid, 'Examples from Real License Plates:\n');
fprintf(fid, '═══════════════════════════════════════════════════════════\n');
fprintf(fid, '  กก 3534   (kor_kai, kor_kai)\n');
fprintf(fid, '  ศร 1818   (sor_sala, ror_rua)\n');
fprintf(fid, '  ฌต 936    (chor_choe, tor_tao)\n');
fprintf(fid, '  ทป 9784   (thor_thahan, por_pla)\n');
fprintf(fid, '═══════════════════════════════════════════════════════════\n');

fclose(fid);
fprintf('   ✅ Saved: 4.utils/thai_unicode.txt\n');

%% 8. Create Latin/Number mapping file
fid = fopen('../4.utils/latin_mapping.txt', 'w', 'n', 'UTF-8');
fprintf(fid, '═══════════════════════════════════════════════════════════\n');
fprintf(fid, 'Latin & Number Character Mapping\n');
fprintf(fid, '═══════════════════════════════════════════════════════════\n');
fprintf(fid, 'Total: %d characters\n', length(latin_chars) + length(number_chars) + length(special_chars));
fprintf(fid, 'Generated: %s\n', datetime('now', 'Format', 'dd-MMM-yyyy HH:mm:ss'));
fprintf(fid, '═══════════════════════════════════════════════════════════\n\n');

% Latin letters
fprintf(fid, '1. LATIN LETTERS (26 characters)\n');
fprintf(fid, '───────────────────────────────────────────────────────────\n');
fprintf(fid, '%s\n\n', latin_chars);

for i = 1:length(latin_chars)
    char_val = latin_chars(i);
    fprintf(fid, '%c\t→\t%c.png\t(U+%04X)\n', char_val, char_val, double(char_val));
end

% Numbers
fprintf(fid, '\n2. NUMBERS (10 characters)\n');
fprintf(fid, '───────────────────────────────────────────────────────────\n');
fprintf(fid, '%s\n\n', number_chars);

for i = 1:length(number_chars)
    char_val = number_chars(i);
    fprintf(fid, '%c\t→\t%c.png\t(U+%04X)\n', char_val, char_val, double(char_val));
end

% Special
fprintf(fid, '\n3. SPECIAL CHARACTERS (1 character)\n');
fprintf(fid, '───────────────────────────────────────────────────────────\n');
fprintf(fid, '%s\t→\tdash.png\t(U+%04X)\n', special_chars, double(special_chars));

% Critical pairs
fprintf(fid, '\n═══════════════════════════════════════════════════════════\n');
fprintf(fid, '⚠️  CRITICAL PAIRS (易混淆字元)\n');
fprintf(fid, '═══════════════════════════════════════════════════════════\n');
fprintf(fid, '1. Latin "I" (U+0049) vs Digit "1" (U+0031)\n');
fprintf(fid, '   ├─ Template: I.png vs 1.png\n');
fprintf(fid, '   ├─ Example: I5-2578 (Latin I + Digit 5)\n');
fprintf(fid, '   └─ Solution: Context-based recognition\n\n');

fprintf(fid, '2. Latin "O" (U+004F) vs Digit "0" (U+0030)\n');
fprintf(fid, '   ├─ Template: O.png vs 0.png\n');
fprintf(fid, '   └─ Note: Less common in Thai plates\n');

fprintf(fid, '\n═══════════════════════════════════════════════════════════\n');
fprintf(fid, 'Examples from Real License Plates:\n');
fprintf(fid, '═══════════════════════════════════════════════════════════\n');
fprintf(fid, '  Type 1 (Yellow): I5-2578  (Latin-Digit-Dash-Digits)\n');
fprintf(fid, '  Type 1 (Yellow): 1ก1234   (Digit-Thai-Digits)\n');
fprintf(fid, '  Type 2 (White):  กก3534   (Thai-Thai-Digits)\n');
fprintf(fid, '═══════════════════════════════════════════════════════════\n');

fclose(fid);
fprintf('   ✅ Saved: 4.utils/latin_mapping.txt\n');

%% 9. Display summary
fprintf('\n');
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('✅ MAPPING FILES CREATED SUCCESSFULLY!\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

fprintf('📊 Summary:\n');
fprintf('   • Thai consonants:  %2d characters\n', length(thai_chars));
fprintf('   • Latin letters:    %2d characters\n', length(latin_chars));
fprintf('   • Numbers:          %2d characters\n', length(number_chars));
fprintf('   • Special:          %2d character\n', length(special_chars));
fprintf('   ─────────────────────────────────────\n');
fprintf('   • TOTAL:            %2d characters\n', mapping.total);
fprintf('\n');

fprintf('📁 Output Files:\n');
fprintf('   ✅ 4.utils/char_mapping.mat      (MATLAB data)\n');
fprintf('   ✅ 4.utils/thai_unicode.txt      (Thai reference)\n');
fprintf('   ✅ 4.utils/latin_mapping.txt     (Latin/Number reference)\n');
fprintf('\n');

fprintf('⏭️  Next Step:\n');
fprintf('   Run: generateQuickTemplates()\n');
fprintf('   This will create 81 template images in 3.templates/\n');
fprintf('\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

end