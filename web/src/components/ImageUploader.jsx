import { useRef, useState, useEffect } from 'react';

export async function compressImage(file) {
  const MAX_WIDTH = 1920;
  const QUALITY = 0.82;

  return new Promise((resolve, reject) => {
    const img = new Image();
    const url = URL.createObjectURL(file);

    img.onload = () => {
      URL.revokeObjectURL(url);

      let { width, height } = img;
      if (width > MAX_WIDTH) {
        height = Math.round((height * MAX_WIDTH) / width);
        width = MAX_WIDTH;
      }

      const canvas = document.createElement('canvas');
      canvas.width = width;
      canvas.height = height;

      const ctx = canvas.getContext('2d');
      ctx.drawImage(img, 0, 0, width, height);

      canvas.toBlob(
        (blob) => {
          if (blob) resolve(blob);
          else reject(new Error('Không thể nén ảnh'));
        },
        'image/jpeg',
        QUALITY
      );
    };

    img.onerror = () => {
      URL.revokeObjectURL(url);
      reject(new Error('Không thể đọc ảnh'));
    };

    img.src = url;
  });
}

const MAX_FILES = 5;
const MAX_SIZE_MB = 10;

export default function ImageUploader({ files = [], onChange }) {
  const inputRef = useRef(null);
  const [dragOver, setDragOver] = useState(false);
  const [error, setError] = useState('');
  const [processing, setProcessing] = useState(false);

  const processFiles = async (incoming) => {
    setError('');
    const remaining = MAX_FILES - files.length;
    if (remaining <= 0) {
      setError(`Chỉ được tải tối đa ${MAX_FILES} ảnh cho mỗi phiên phân tích.`);
      return;
    }

    const toProcess = Array.from(incoming).slice(0, remaining);
    setProcessing(true);

    try {
      const newItems = [];
      for (const file of toProcess) {
        if (!file.type.startsWith('image/')) {
          setError(`Tệp "${file.name}" không phải là ảnh hợp lệ.`);
          continue;
        }
        if (file.size > MAX_SIZE_MB * 1024 * 1024) {
          setError(`Tệp "${file.name}" vượt quá ${MAX_SIZE_MB}MB.`);
          continue;
        }

        const preview = URL.createObjectURL(file);
        const compressed = await compressImage(file);
        newItems.push({ file, preview, compressed });
      }

      if (newItems.length > 0) {
        onChange([...files, ...newItems]);
      }
    } catch (err) {
      setError('Đã xảy ra lỗi khi xử lý ảnh: ' + err.message);
    } finally {
      setProcessing(false);
    }
  };

  const handleDrop = (e) => {
    e.preventDefault();
    setDragOver(false);
    if (e.dataTransfer.files?.length) {
      processFiles(e.dataTransfer.files);
    }
  };

  const handleRemove = (index) => {
    const item = files[index];
    if (item?.preview) URL.revokeObjectURL(item.preview);
    const updated = files.filter((_, i) => i !== index);
    onChange(updated);
  };

  const handlePaste = async () => {
    try {
      const clipboardItems = await navigator.clipboard.read();
      const imageBlobs = [];
      for (const item of clipboardItems) {
        for (const type of item.types) {
          if (type.startsWith('image/')) {
            const blob = await item.getType(type);
            const file = new File([blob], `paste_${Date.now()}.png`, { type });
            imageBlobs.push(file);
          }
        }
      }
      if (imageBlobs.length > 0) {
        processFiles(imageBlobs);
      } else {
        setError('Không tìm thấy ảnh nào trong bộ nhớ tạm (Clipboard). Hãy chụp màn hình trước.');
      }
    } catch (err) {
      setError('Trình duyệt chưa cấp quyền đọc Clipboard. Bạn có thể nhấn Ctrl+V trực tiếp trên trang.');
    }
  };

  // Listen to global Ctrl+V paste
  useEffect(() => {
    const handleGlobalPaste = (e) => {
      const items = e.clipboardData?.items;
      if (!items) return;
      const pastedFiles = [];
      for (let i = 0; i < items.length; i++) {
        if (items[i].type.indexOf('image') !== -1) {
          const file = items[i].getAsFile();
          if (file) pastedFiles.push(file);
        }
      }
      if (pastedFiles.length > 0) {
        processFiles(pastedFiles);
      }
    };
    window.addEventListener('paste', handleGlobalPaste);
    return () => window.removeEventListener('paste', handleGlobalPaste);
  }, [files]);

  return (
    <div className="flex flex-col gap-space-sm">
      {/* Upload Zone */}
      <div
        onDragOver={(e) => { e.preventDefault(); setDragOver(true); }}
        onDragLeave={() => setDragOver(false)}
        onDrop={handleDrop}
        className={`relative bg-surface-container rounded-none p-space-md flex flex-col sm:flex-row gap-space-md items-center border transition-all ${
          dragOver
            ? 'border-primary bg-primary-container/10 ring-2 ring-primary/40'
            : 'border-white/5 hover:border-white/10'
        }`}
      >
        <input
          ref={inputRef}
          type="file"
          accept="image/png, image/jpeg, image/webp"
          multiple
          className="hidden"
          onChange={(e) => {
            if (e.target.files) processFiles(e.target.files);
            e.target.value = '';
          }}
        />

        {/* Upload Action Area */}
        <div className="w-full flex flex-col items-center text-center justify-center py-space-sm px-space-xs">
          <div className="w-14 h-14 rounded-full bg-primary-container/20 border border-primary/30 text-primary flex items-center justify-center mb-space-xs">
            <span className="material-symbols-outlined text-[32px]">
              {processing ? 'hourglass_top' : 'cloud_upload'}
            </span>
          </div>

          <div className="font-title-md text-title-md text-on-surface mb-space-2xs font-semibold">
            Kéo & thả ảnh chụp màn hình vào đây
          </div>

          <p className="font-body-sm text-body-sm text-on-surface-variant mb-space-sm max-w-md">
            Hỗ trợ định dạng JPG, PNG, WEBP lên đến 10MB (tối đa {MAX_FILES} ảnh). Hệ thống tự động khử dữ liệu nhạy cảm cá nhân.
          </p>

          <div className="flex flex-wrap gap-space-xs justify-center">
            <button
              type="button"
              onClick={() => inputRef.current?.click()}
              className="px-space-sm py-space-xs bg-surface-bright hover:bg-surface-container-highest text-on-surface font-title-md text-title-md rounded-lg shadow-sm transition-colors flex items-center gap-space-2xs border border-white/10"
            >
              <span className="material-symbols-outlined text-[18px] text-primary">add_photo_alternate</span>
              <span>Chọn ảnh từ máy</span>
            </button>

            <button
              type="button"
              onClick={handlePaste}
              className="px-space-sm py-space-xs bg-surface-container-high hover:bg-surface-container-highest text-primary font-title-md text-title-md rounded-lg transition-colors flex items-center gap-space-2xs border border-primary/20"
            >
              <span className="material-symbols-outlined text-[18px]">content_paste</span>
              <span>Dán từ bộ nhớ</span>
            </button>
          </div>
        </div>
      </div>

      {/* Error message */}
      {error && (
        <div className="flex items-center gap-2 p-3 bg-error-container/20 border border-error/30 rounded-xl text-error text-body-sm">
          <span className="material-symbols-outlined text-[18px]">error</span>
          <span>{error}</span>
        </div>
      )}

      {/* Previews List */}
      {files.length > 0 && (
        <div className="flex flex-col gap-2">
          <div className="flex items-center justify-between text-xs text-on-surface-variant px-1 font-label-badge">
            <span>ẢNH ĐÃ CHỌN ({files.length}/{MAX_FILES})</span>
            <button
              type="button"
              onClick={() => {
                files.forEach((f) => f.preview && URL.revokeObjectURL(f.preview));
                onChange([]);
              }}
              className="text-error hover:underline"
            >
              Xóa tất cả
            </button>
          </div>

          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-3">
            {files.map((item, idx) => (
              <div
                key={idx}
                className="relative bg-surface-container-low border border-white/10 rounded-none overflow-hidden group p-2 flex flex-col gap-2"
              >
                <div className="w-full h-32 bg-surface-container-lowest rounded-none overflow-hidden flex items-center justify-center">
                  <img
                    src={item.preview}
                    alt={`Preview ${idx + 1}`}
                    className="w-full h-full object-contain"
                  />
                </div>

                <div className="flex items-center justify-between text-[11px] font-label-caption text-on-surface-variant truncate">
                  <span className="truncate max-w-[80px]" title={item.file.name}>
                    {item.file.name}
                  </span>
                  <span className="text-primary font-bold">
                    {(item.file.size / 1024).toFixed(0)} KB
                  </span>
                </div>

                {/* Remove button */}
                <button
                  type="button"
                  onClick={() => handleRemove(idx)}
                  className="absolute top-3 right-3 w-6 h-6 rounded-full bg-[#000000]/80 hover:bg-error text-white flex items-center justify-center transition-colors"
                  title="Xóa ảnh này"
                >
                  <span className="material-symbols-outlined text-[14px]">close</span>
                </button>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
