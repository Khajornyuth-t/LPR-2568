function results = batchProcessAll_LPR2568(imagesDir, varargin)
% BATCHPROCESSALL_LPR2568  Run LPR on all LPR####.bmp under imagesDir
%
% Usage:
%   results = batchProcessAll_LPR2568(imagesDir)
%   results = batchProcessAll_LPR2568(imagesDir, opts)
%
% opts fields (optional):
%   .templatesDir (char) = ''
%   .saveDebug    (logical) = false
%   .verbose      (logical) = true

    % ---------- parse inputs ----------
    if nargin < 1
        error('imagesDir is required');
    end
    if nargin < 2
        opts = struct();
    else
        opts = varargin{1};
    end
    if ~isfield(opts,'templatesDir'), opts.templatesDir = ''; end
    if ~isfield(opts,'saveDebug'),    opts.saveDebug    = false; end
    if ~isfield(opts,'verbose'),      opts.verbose      = true;  end

    % ---------- list & sort files ----------
    listing = dir(fullfile(imagesDir, 'LPR*.bmp'));
    nums = nan(numel(listing),1);
    for i = 1:numel(listing)
        n = sscanf(listing(i).name,'LPR%04d.bmp');
        if ~isempty(n), nums(i) = n; end
    end
    [~, idx] = sort(nums);
    listing = listing(idx);

    % ---------- preallocate results ----------
    n = numel(listing);
    results = repmat(struct( ...
        'no', 0, ...
        'image_name', '', ...
        'plate_text', '', ...
        'confidence', 0, ...
        'elapsed_s', 0, ...
        'status', '', ...
        'note', ''), n, 1);

    % ---------- main loop ----------
    for i = 1:n
        t0 = tic;
        fn = listing(i).name;
        fpath = fullfile(imagesDir, fn);

        try
            % เรียก OCR หลัก (ใช้ของคุณน้ำก่อน ถ้าใช้ไม่ได้ค่อย fallback)
            [plateText, conf] = safeReadPlate(fpath, opts);

            % ตรวจรูปแบบป้าย ถ้ามีฟังก์ชันนี้
            try
                isValid = validatePlateFormat(plateText);
            catch
                isValid = ~isempty(plateText);
            end

            results(i).no         = i;
            results(i).image_name = fn;
            results(i).plate_text = plateText;
            results(i).confidence = conf;
            results(i).elapsed_s  = toc(t0);
            results(i).status     = tern(isValid && ~isempty(plateText), 'SUCCESS', 'CHECK');
            results(i).note       = '';

            if opts.verbose
                fprintf('%s -> %s (%.2f)\n', fn, plateText, conf);
            end

        catch ME
            results(i).no         = i;
            results(i).image_name = fn;
            results(i).plate_text = '';
            results(i).confidence = 0;
            results(i).elapsed_s  = toc(t0);
            results(i).status     = 'FAIL';
            results(i).note       = ME.message;

            if opts.verbose
                warning('Fail %s: %s', fn, ME.message);
            end
        end
    end
end  % <<< end ของ "ฟังก์ชันหลัก" ต้องมี และอยู่ตรงนี้พอดี

% ===== local helper (ชื่อต้องไม่ซ้ำชื่อไฟล์) =====
function y = tern(cond, a, b)
    if cond, y = a; else, y = b; end
end
