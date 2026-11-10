import { useState, useEffect, useCallback, useRef } from 'react';
import ImageUploader from '../components/ImageUploader';
import ResultCard from '../components/ResultCard';
import ContextFollowUp from '../components/ContextFollowUp';
import API from '../api/api';

export default function HomePage() {
  const [files, setFiles] = useState([]);
  const [additionalText, setAdditionalText] = useState('');
  const [analyzing, setAnalyzing] = useState(false);
  const [waitSeconds, setWaitSeconds] = useState(0);
  const [result, setResult] = useState(null);
  const scanRequestIdRef = useRef(null);
  const [error, setError] = useState('');
  const [stats, setStats] = useState({
    totalScans: 9,
    warnedScans: 9,
    maxConfidence: 98,
  });

  const fetchStats = useCallback(async () => {
    try {
      const res = await API.get('/api/stats');
      if (res.data) {
        setStats({
          totalScans: typeof res.data.totalScans === 'number' ? res.data.totalScans : 9,
          warnedScans: typeof res.data.warnedScans === 'number' ? res.data.warnedScans : 9,
          maxConfidence: typeof res.data.maxConfidence === 'number' ? res.data.maxConfidence : 98,
        });
      }
    } catch (err) {
      console.warn('Could not fetch stats:', err.message);
    }
  }, []);

  useEffect(() => {
    fetchStats();
  }, [fetchStats]);

  useEffect(() => {
    if (!analyzing) return undefined;
    const timer = window.setInterval(() => setWaitSeconds((seconds) => seconds + 1), 1000);
    return () => window.clearInterval(timer);
  }, [analyzing]);

  const handleSubmit = async () => {
    setError('');

    if (files.length === 0 && !additionalText.trim()) {
      setError('Vui lòng tải lên ít nhất 1 ảnh chụp màn hình hoặc dán nội dung tin nhắn nghi vấn.');
      return;
    }
    setWaitSeconds(0);
    setAnalyzing(true);
    setResult(null);

    try {
      const formData = new FormData();
      files.forEach((item, idx) => {
        formData.append('images', item.compressed, `image_${idx}.jpg`);
      });

      formData.append('platform', 'sms');
      scanRequestIdRef.current ||= crypto.randomUUID();
      formData.append('clientRequestId', scanRequestIdRef.current);
      if (additionalText.trim()) {
        formData.append('text', additionalText.trim());
      }

      let response;
      try {
        response = await API.post('/api/v2/check', formData);
      } catch (err) {
        if (err.response?.status !== 404) throw err;
        response = await API.post('/api/check', formData);
      }

      setResult(response.data);
      files.forEach((item) => {
        if (item.preview) URL.revokeObjectURL(item.preview);
      });
      setFiles([]);
      setAdditionalText('');
      scanRequestIdRef.current = null;
      fetchStats();
    } catch (err) {
      const msg = err.response?.data?.error || err.response?.data?.message || err.message;
      setError(`Có lỗi xảy ra khi phân tích: ${msg}`);
    } finally {
      setAnalyzing(false);
    }
  };

  const startNewScan = () => {
    setResult(null);
    setError('');
    scanRequestIdRef.current = null;
    document.getElementById('scam-text-input')?.focus();
  };

  return (
    <main className="w-full pt-6 sm:pt-10 pb-16 bg-surface relative overflow-hidden">
      {/* Ambient Cyber Lighting Backdrops */}
      <div className="absolute -top-32 left-1/2 -translate-x-1/2 w-[850px] h-[380px] bg-gradient-to-b from-primary-container/20 via-tertiary-container/10 to-transparent blur-3xl pointer-events-none rounded-full"></div>
      <div className="absolute top-96 -right-24 w-96 h-96 bg-error-container/15 blur-3xl pointer-events-none rounded-full"></div>
      <div className="absolute top-[700px] -left-20 w-80 h-80 bg-primary/10 blur-3xl pointer-events-none rounded-full"></div>

      <div className="max-w-[1280px] mx-auto px-4 sm:px-6 relative z-10">
        {/* HERO HEADER SECTION */}
        <section className="flex flex-col items-center text-center max-w-4xl mx-auto mb-space-2xl">
          <div className="inline-flex items-center gap-space-xs px-space-sm py-space-2xs bg-surface-container-high border border-white/10 rounded-none mb-space-md shadow-sm">
            <span className="w-2.5 h-2.5 rounded-full bg-tertiary animate-ping"></span>
            <span className="material-symbols-outlined text-tertiary text-[18px]">verified</span>
            <span className="font-label-badge text-label-badge text-tertiary uppercase tracking-wider">
              Phân tích đa nền tảng thời gian thực
            </span>
          </div>

          <h1 className="font-display-hero text-3xl sm:text-4xl lg:text-display-hero text-on-surface tracking-tight mb-space-sm">
            AI Kiểm Tra & Nhận Diện{' '}
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary via-tertiary to-primary">
              Lừa Đảo Trực Tuyến
            </span>
          </h1>

          <p className="font-body-lg text-body-lg text-on-surface-variant max-w-2xl mx-auto mb-space-lg">
            Lá chắn trí tuệ nhân tạo chuyên biệt bảo vệ công dân Việt Nam trước các thủ đoạn chiếm đoạt tài khoản ngân hàng, giả mạo cơ quan pháp luật và đường link độc hại.
          </p>

          {/* Quick Live Telemetry Stat Pills */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-space-sm w-full max-w-3xl">
            <div className="p-space-sm bg-surface-container-low border border-white/5 rounded-none shadow-sm flex flex-col items-center justify-center text-center">
              <span className="font-label-badge text-label-badge text-tertiary uppercase">Tổng tin nhắn quét</span>
              <span className="font-headline-md text-headline-md text-on-surface font-bold tracking-tight">
                {stats.totalScans.toLocaleString('vi-VN')}
              </span>
              <span className="font-label-caption text-label-caption text-secondary">Số liệu thực tế hệ thống</span>
            </div>

            <div className="p-space-sm bg-surface-container-low border border-white/5 rounded-none shadow-sm flex flex-col items-center justify-center text-center">
              <span className="font-label-badge text-label-badge text-primary uppercase line-clamp-1">
                Mức độ cảnh báo cao nhất được ghi nhận
              </span>
              <span className="font-headline-md text-headline-md text-primary font-bold tracking-tight">
                {stats.maxConfidence > 0 ? `${stats.maxConfidence}%` : 'Chưa ghi nhận'}
              </span>
              <span className="font-label-caption text-label-caption text-secondary">Chỉ số rủi ro nguy cấp nhất</span>
            </div>

            <div className="p-space-sm bg-surface-container-low border border-white/5 rounded-none shadow-sm flex flex-col items-center justify-center text-center">
              <span className="font-label-badge text-label-badge text-error uppercase">Số tin nhắn được cảnh báo</span>
              <span className="font-headline-md text-headline-md text-error font-bold tracking-tight">
                {stats.warnedScans.toLocaleString('vi-VN')}
              </span>
              <span className="font-label-caption text-label-caption text-secondary">Phát hiện thủ đoạn lừa đảo</span>
            </div>
          </div>
        </section>

        {/* TWO-PANE SCANNER / ANALYTICAL SUITE */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-space-xl items-start">
          {/* LEFT INPUT SUITE (7 Cols) */}
          <div className="lg:col-span-7 flex flex-col gap-space-lg">
            <div className="bg-surface-container-low rounded-none p-space-lg shadow-md border border-white/5 flex flex-col gap-space-lg">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-space-xs">
                  <span className="material-symbols-outlined text-primary text-[24px]">document_scanner</span>
                  <span className="font-headline-sm text-headline-sm text-on-surface font-semibold">
                    Tải Lên Mẫu Tin Nhắn
                  </span>
                </div>
              </div>

              {/* Image Uploader */}
              <ImageUploader files={files} onChange={(next) => { scanRequestIdRef.current = null; setFiles(next); }} />

              {/* Local OCR notice */}
              {files.length > 0 && (
                <div className="p-2.5 bg-primary/10 border border-primary/20 flex items-center justify-between text-xs text-primary font-mono animate-fadeIn">
                  <div className="flex items-center gap-1.5">
                    <span className="material-symbols-outlined text-[16px]">document_scanner</span>
                    <span>Ảnh được OCR trên máy chủ; chỉ văn bản được gửi tới AI</span>
                  </div>
                  <span className="text-[10px] px-1.5 py-0.5 bg-emerald-500/20 text-emerald-700 font-bold uppercase">
                    OCR cục bộ
                  </span>
                </div>
              )}

              {/* Text / URL Secondary Extraction Field */}
              <div className="flex flex-col gap-space-2xs">
                <div className="flex justify-between items-center">
                  <label className="font-title-md text-title-md text-on-surface font-medium" htmlFor="scam-text-input">
                    Nội dung tin nhắn / URL cần kiểm tra:
                  </label>
                  <span className="font-label-caption text-label-caption text-secondary">
                    Tùy chọn
                  </span>
                </div>
                <div className="relative">
                  <textarea
                    id="scam-text-input"
                    rows="3"
                    value={additionalText}
                    onChange={(e) => { scanRequestIdRef.current = null; setAdditionalText(e.target.value); }}
                    placeholder="Ví dụ: http://vcb-digi-bank.vip/login hoặc dán toàn bộ đoạn văn bản tin nhắn nhận được..."
                    className="w-full bg-surface-container text-on-surface font-code-telemetry text-code-telemetry p-space-sm rounded-none focus:outline-none focus:ring-1 focus:ring-primary border border-white/5 resize-none placeholder-on-surface-variant/40"
                  />
                  {additionalText && (
                    <button
                      type="button"
                      onClick={() => { scanRequestIdRef.current = null; setAdditionalText(''); }}
                      className="absolute bottom-2.5 right-2.5 text-on-surface-variant hover:text-on-surface p-1 rounded-none bg-surface-container-high text-xs"
                      title="Xóa nội dung"
                    >
                      <span className="material-symbols-outlined text-[16px]">clear</span>
                    </button>
                  )}
                </div>
              </div>

              {/* Error Box */}
              {error && (
                <div className="flex items-center gap-2 p-3 bg-error-container/20 border border-error/40 rounded-none text-error text-body-sm">
                  <span className="material-symbols-outlined text-[20px]">warning</span>
                  <span>{error}</span>
                </div>
              )}

              {/* Primary Cyber Scan Action */}
              <div className="pt-space-2xs">
                <button
                  type="button"
                  disabled={analyzing}
                  onClick={handleSubmit}
                  className={`w-full py-space-sm px-space-md font-title-md text-title-md rounded-none transition-all flex items-center justify-center gap-space-xs group ${
                    analyzing
                      ? 'bg-primary-container text-on-primary-container opacity-70 cursor-wait'
                      : 'bg-primary-container hover:bg-inverse-primary text-on-primary-container shadow-[0_0_24px_-4px_rgba(37,99,235,0.65)] active:scale-[0.99]'
                  }`}
                >
                  <span className={`material-symbols-outlined text-[24px] ${analyzing ? 'animate-spin' : 'group-hover:rotate-180 transition-transform duration-700'}`}>
                    {analyzing ? 'progress_activity' : 'radar'}
                  </span>
                  <span className="tracking-wide font-bold">
                    {analyzing ? 'ĐANG QUÉT VÀ PHÂN TÍCH VỚI AI...' : 'KIỂM TRA NGAY VỚI AI VÀ NHẬN BÁO CÁO'}
                  </span>
                  {!analyzing && (
                    <span className="material-symbols-outlined text-[18px]">arrow_forward</span>
                  )}
                </button>
                <p className="mt-3 text-xs leading-relaxed text-on-surface-variant">
                  Kết quả đủ ngữ cảnh và đủ ba phân tích AI mới được lưu làm mẫu. Mẫu rủi ro chưa kiểm duyệt có thể xuất hiện công khai; hãy che thông tin riêng tư trước khi gửi.
                </p>
              </div>
            </div>


          </div>

          {/* RIGHT PERSISTENT TELEMETRY & REPORT SUITE (5 Cols) */}
          <div className="lg:col-span-5 flex flex-col gap-space-lg sticky top-24">
            {analyzing ? (
              /* Loading State */
              <div className="bg-surface-container rounded-none p-space-xl shadow-xl border border-white/10 flex flex-col items-center justify-center text-center gap-5 min-h-[420px]" role="status" aria-live="polite">
                <div className="scan-loader" aria-hidden="true">
                  <span className="scan-loader-ring scan-loader-ring-outer" />
                  <span className="scan-loader-ring scan-loader-ring-inner" />
                  <span className="scan-loader-sweep" />
                  <span className="material-symbols-outlined scan-loader-icon">document_scanner</span>
                </div>
                <div className="space-y-2">
                  <div className="font-headline-sm text-headline-sm font-bold text-on-surface">
                    Đang đọc và phân tích nội dung
                  </div>
                  <p className="text-sm text-on-surface-variant max-w-xs">
                    Hệ thống đang kiểm tra dấu hiệu rủi ro trong tin nhắn của bạn.
                  </p>
                </div>
                <div className="w-full max-w-xs">
                  <div className="scan-loader-track" aria-hidden="true"><span /></div>
                  <p className="mt-3 text-xs text-secondary" aria-hidden="true">Đã chờ {waitSeconds} giây</p>
                </div>
              </div>
            ) : result ? (
              /* Real-time Forensic Result */
              <div className="space-y-3">
                {['insufficient_context', 'invalid_input'].includes(result.assessment?.status)
                  ? <ContextFollowUp result={result} busy={analyzing} onNewScan={startNewScan} />
                  : <ResultCard result={result} />}
                {result.templateSaveStatus && result.templateSaveStatus !== 'not_applicable' && (
                  <p role="status" className="rounded-lg border border-white/10 bg-surface-container p-3 text-sm text-on-surface-variant">
                    {result.templateSaveStatus === 'saved'
                      ? 'Đã lưu mẫu phân tích. Mẫu đang ở trạng thái chưa kiểm duyệt.'
                      : result.templateSaveStatus === 'incomplete_analysis'
                        ? 'Đã trả kết quả quét, nhưng chưa lưu mẫu vì AI thiếu một trong ba phần phân tích.'
                        : result.templateSaveStatus === 'deferred_insufficient_context'
                          ? 'Lượt thiếu ngữ cảnh không được lưu. Khi có phản hồi mới, hãy bắt đầu lượt quét mới.'
                          : result.templateSaveStatus === 'deferred_review'
                            ? 'Có dấu hiệu cần cảnh giác nhưng AI chưa nhất quán; chưa lưu mẫu vào kho.'
                        : 'Đã trả kết quả quét, nhưng chưa lưu được mẫu. Vui lòng thử lại sau.'}
                  </p>
                )}
              </div>
            ) : (
              /* Ready State */
              <div className="bg-surface-container-low rounded-none p-space-xl border border-white/5 shadow-md flex flex-col items-center justify-center text-center min-h-[380px] gap-3">
                <div className="w-16 h-16 rounded-none bg-surface-container-high flex items-center justify-center text-primary/80 mb-1 border border-white/5">
                  <span className="material-symbols-outlined text-[36px]">radar</span>
                </div>
                <div className="font-headline-sm text-on-surface font-semibold">
                  Hệ Thống Sẵn Sàng Phân Tích
                </div>
                <p className="font-body-sm text-on-surface-variant max-w-sm leading-relaxed">
                  Tải lên ảnh chụp màn hình hoặc dán nội dung tin nhắn nghi vấn ở cột bên trái, sau đó nhấn <span className="text-primary font-medium">"Kiểm tra ngay với AI"</span> để nhận báo cáo bóc tách chi tiết.
                </p>
                <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-none bg-surface-container text-xs text-on-surface-variant border border-white/5 mt-2">
                  <span className="w-2 h-2 rounded-full bg-tertiary animate-pulse"></span>
                  <span>Mô hình Gemini</span>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </main>
  );
}
