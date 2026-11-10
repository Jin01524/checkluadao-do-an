import { useState } from 'react';
import ChatBubble from './ChatBubble';

export default function ResultCard({ result }) {
  const [copied, setCopied] = useState(false);

  if (!result) return null;

  const {
    isChatScreenshot = true,
    isScam,
    scamType,
    confidenceScore: dangerLevel = null,
    warningPoints = [],
    messages = [],
    analysis: summary,
    recommendations = [],
    extractedUrls = [],
    exfiltrationVector = 'none',
    multiAgentDebate,
    attackTarget,
    ocrUsed,
    ocrExtractedText,
  } = result;

  const [showDebate, setShowDebate] = useState(true);

  const VECTOR_MAP = {
    none: {
      label: 'Kênh chiếm đoạt: Không phát hiện (An toàn)',
      sub: 'Không có liên kết lạ, không yêu cầu OTP, mật khẩu hay chuyển tiền',
      badgeClass: 'text-emerald-700 bg-emerald-500/10 border-emerald-500/30',
      icon: 'verified_user',
    },
    phishing_link: {
      label: 'Kênh chiếm đoạt: Liên kết giả mạo (Phishing Link)',
      sub: 'Chứa website lạ hoặc tên miền rút gọn nhằm đánh cắp thông tin',
      badgeClass: 'text-rose-700 bg-rose-500/10 border-rose-500/30',
      icon: 'link_off',
    },
    otp_theft: {
      label: 'Kênh chiếm đoạt: Đánh cắp mã OTP / Mật khẩu',
      sub: 'Dụ dỗ cung cấp mã xác thực giao dịch hoặc mật khẩu ngân hàng',
      badgeClass: 'text-rose-700 bg-rose-500/10 border-rose-500/30',
      icon: 'lock_reset',
    },
    money_transfer: {
      label: 'Kênh chiếm đoạt: Yêu cầu chuyển tiền / Nộp phí',
      sub: 'Hối thúc chuyển khoản vào số tài khoản cá nhân hoặc nạp tiền giữ chỗ',
      badgeClass: 'text-rose-700 bg-rose-500/10 border-rose-500/30',
      icon: 'payments',
    },
    apk_malware: {
      label: 'Kênh chiếm đoạt: Mã độc / Tải ứng dụng ngoài (.APK)',
      sub: 'Yêu cầu tải app giả danh cổng dịch vụ công hoặc ngân hàng',
      badgeClass: 'text-rose-700 bg-rose-500/10 border-rose-500/30',
      icon: 'phone_android',
    },
    unauthorized_contact: {
      label: 'Kênh chiếm đoạt: Số lạ / Liên hệ không chính thức',
      sub: 'Yêu cầu gọi số hotline giả mạo hoặc nhắn qua Zalo/Telegram cá nhân',
      badgeClass: 'text-amber-700 bg-amber-500/10 border-amber-500/30',
      icon: 'contact_phone',
    },
  };

  const currentVector = VECTOR_MAP[exfiltrationVector] || VECTOR_MAP.none;

  const caseId = `#CK-${Math.floor(1000 + Math.random() * 9000)}`;

  const handleShare = () => {
    if (navigator.share) {
      navigator.share({
        title: `Cảnh báo lừa đảo: ${scamType || 'CheckLuaDao'}`,
        text: `Hệ thống AI CheckLuaDao vừa phát hiện tin nhắn có nguy cơ lừa đảo${dangerLevel == null ? '' : ` (điểm rủi ro ${dangerLevel}/100)`}. Xem chi tiết tại CheckLuaDao.`,
        url: window.location.href,
      }).catch(() => {});
    } else {
      navigator.clipboard.writeText(
        `[CẢNH BÁO LỪA ĐẢO - CheckLuaDao]\nLoại: ${scamType || 'Chưa rõ'}\n${dangerLevel == null ? '' : `Điểm rủi ro: ${dangerLevel}/100\n`}Chi tiết: ${summary || ''}`
      );
      setCopied(true);
      setTimeout(() => setCopied(false), 2500);
    }
  };

  if (isChatScreenshot === false) {
    return (
      <div className="bg-surface-container rounded-none p-space-lg shadow-xl flex flex-col gap-space-md border border-white/5">
        <div className="flex items-center gap-space-xs p-space-md bg-warning/15 border border-warning/30 rounded-none text-warning">
          <span className="material-symbols-outlined text-[28px]">image_not_supported</span>
          <div>
            <div className="font-title-md text-title-md font-bold">
              Ảnh không chứa tin nhắn nhận diện được
            </div>
            <div className="font-body-sm text-body-sm text-on-surface-variant mt-1">
              {summary || 'Ảnh tải lên không hiển thị rõ nội dung hộp thoại tin nhắn. Vui lòng chụp lại màn hình rõ ràng hơn.'}
            </div>
          </div>
        </div>
      </div>
    );
  }

  const isHighRisk = isScam && dangerLevel != null && dangerLevel >= 70;
  const isMediumRisk = isScam && !isHighRisk;

  return (
    <div className="bg-surface-container rounded-none p-space-lg shadow-xl flex flex-col gap-space-md border border-white/10 animate-fadeIn">
      {/* Risk Header Badge */}
      <div className="flex items-center justify-between pb-space-xs border-b border-white/5">
        <div className="flex items-center gap-2">
          <span
            className={`w-3 h-3 rounded-full ${
              isHighRisk ? 'bg-error animate-pulse' : isMediumRisk ? 'bg-warning animate-pulse' : 'bg-[#10b981]'
            }`}
          ></span>
          <span
            className={`font-label-badge text-label-badge uppercase tracking-wider ${
              isHighRisk ? 'text-error' : isMediumRisk ? 'text-warning' : 'text-emerald-700'
            }`}
          >
            KẾT QUẢ PHÂN TÍCH SỐ
          </span>
        </div>
        <span className="font-code-telemetry text-code-telemetry text-secondary">
          MÃ ĐƠN: {caseId}
        </span>
      </div>

      {/* Risk Status Banner */}
      <div
        className={`p-space-md rounded-none shadow-md flex flex-col gap-space-2xs border ${
          isScam
            ? 'bg-error-container/40 border-error/30 text-on-error-container'
            : 'bg-[#10b981]/15 border-[#10b981]/30 text-on-surface'
        }`}
      >
        <div className="flex items-center justify-between gap-space-xs">
          <div className="flex items-center gap-2">
            <span className={`material-symbols-outlined text-[28px] ${isScam ? 'text-error' : 'text-emerald-700'}`}>
              {isScam ? 'warning' : 'verified_user'}
            </span>
            <span className="font-headline-sm text-headline-sm font-bold uppercase tracking-tight">
              {isScam
                ? isHighRisk
                  ? `RỦI RO RẤT CAO (${dangerLevel}/100)`
                  : `CẢNH BÁO NGHI VẤN${dangerLevel == null ? '' : ` (${dangerLevel}/100)`}`
                : 'AN TOÀN / KHÔNG PHÁT HIỆN LỪA ĐẢO'}
            </span>
          </div>
        </div>

        <p className="font-title-md text-title-md font-semibold text-on-surface">
          {isScam
            ? scamType
              ? `THỦ ĐOẠN: ${scamType.toUpperCase()}`
              : 'DẤU HIỆU TẤN CÔNG PHI KỸ THUẬT NGUY HIỂM'
            : 'Nội dung tin nhắn không có các đặc trưng thao túng tài chính hay đường dẫn độc hại'}
        </p>

        {/* Progress gauge bar */}
        {dangerLevel != null && <div className="w-full bg-surface-container-lowest h-2 rounded-none overflow-hidden mt-1.5">
          <div
            className={`h-full rounded-none transition-all duration-1000 ${
              isHighRisk ? 'bg-error' : isMediumRisk ? 'bg-warning' : 'bg-[#10b981]'
            }`}
            style={{ width: `${Math.max(dangerLevel, 10)}%` }}
          ></div>
        </div>}
      </div>

      {/* Exfiltration Vector Chip (Ma Trận Kênh Chiếm Đoạt) */}
      <div className={`p-2.5 border rounded-none flex items-start gap-2.5 ${currentVector.badgeClass}`}>
        <span className="material-symbols-outlined text-[20px] flex-shrink-0 mt-0.5">
          {currentVector.icon}
        </span>
        <div className="flex flex-col">
          <span className="font-mono text-xs font-bold tracking-tight">
            {currentVector.label}
          </span>
          <span className="text-[11px] opacity-80 leading-snug mt-0.5">
            {currentVector.sub}
          </span>
        </div>
      </div>

      {/* Multi-Agent Deliberation Panel (XAI - Explainable AI) */}
      {multiAgentDebate && (
        <div className="border border-white/10 bg-surface-container-lowest rounded-none overflow-hidden">
          <div
            onClick={() => setShowDebate(!showDebate)}
            className="flex items-center justify-between p-3 bg-surface-container-high/50 cursor-pointer hover:bg-surface-container-high transition-colors select-none border-b border-white/5"
          >
            <div className="flex items-center gap-2">
              <span className="material-symbols-outlined text-[18px] text-primary">diversity_3</span>
              <div>
                <span className="font-mono text-xs font-bold text-on-surface tracking-wider uppercase">
                  Nhật Ký Tranh Luận Giữa 3 Tác Tử AI (Multi-Agent Deliberation Log)
                </span>
                <p className="text-[11px] text-on-surface-variant">
                  Cơ chế giải trình minh bạch (XAI) nhằm phát hiện thủ đoạn và triệt tiêu báo động sai (False Positive)
                </p>
              </div>
            </div>
            <span className="material-symbols-outlined text-on-surface-variant transition-transform text-[20px]">
              {showDebate ? 'expand_less' : 'expand_more'}
            </span>
          </div>

          {showDebate && (
            <div className="p-3.5 space-y-3 bg-slate-50 text-xs">
              {/* Agent 1 */}
              <div className="p-3 bg-error-container/10 border-l-2 border-error/70 flex flex-col gap-1">
                <div className="flex items-center justify-between">
                  <span className="font-mono font-bold text-error uppercase flex items-center gap-1.5 text-[11px]">
                    <span className="material-symbols-outlined text-[15px]">radar</span>
                    AI 1: Nhận định rủi ro
                  </span>
                </div>
                <p className="text-on-surface-variant leading-relaxed text-[12px] mt-0.5">
                  {multiAgentDebate.threatHunterAnalysis || 'Đang quét phân tích ngữ nghĩa và các chỉ số kích động tâm lý khẩn cấp.'}
                </p>
              </div>

              {/* Agent 2 */}
              <div className="p-3 bg-emerald-500/10 border-l-2 border-emerald-500/70 flex flex-col gap-1">
                <div className="flex items-center justify-between">
                  <span className="font-mono font-bold text-emerald-700 uppercase flex items-center gap-1.5 text-[11px]">
                    <span className="material-symbols-outlined text-[15px]">policy</span>
                    AI 2: Nhận định an toàn
                  </span>
                </div>
                <p className="text-on-surface-variant leading-relaxed text-[12px] mt-0.5">
                  {multiAgentDebate.auditorDefense || 'Đang đối chiếu ma trận kênh chiếm đoạt từ xa và quy tắc địa điểm vật lý.'}
                </p>
              </div>

              {/* Agent 3 */}
              <div className="p-3 bg-primary/10 border-l-2 border-primary flex flex-col gap-1">
                <div className="flex items-center justify-between">
                  <span className="font-mono font-bold text-primary uppercase flex items-center gap-1.5 text-[11px]">
                    <span className="material-symbols-outlined text-[15px]">gavel</span>
                    AI 3: Kết luận
                  </span>
                </div>
                <p className="text-on-surface leading-relaxed text-[12px] font-medium mt-0.5">
                  {multiAgentDebate.arbiterVerdict || 'Đã tổng hợp ý kiến phản biện và đưa ra phán quyết đồng thuận cuối cùng.'}
                </p>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Psychological manipulation & Warning Indicators */}
      {warningPoints.length > 0 && (
        <div className="flex flex-col gap-2">
          <div className="flex items-center gap-1.5 font-label-badge text-[11px] text-error uppercase">
            <span className="material-symbols-outlined text-[16px]">flag</span>
            <span>Các dấu hiệu vi phạm nhận diện ({warningPoints.length})</span>
          </div>
          <div className="space-y-2">
            {warningPoints.map((point, idx) => (
              <div
                key={idx}
                className="flex items-start gap-2.5 p-2.5 bg-surface-container-high/60 rounded-none border border-error/20 text-on-surface"
              >
                <span className="material-symbols-outlined text-error text-[18px] flex-shrink-0 mt-0.5">
                  report
                </span>
                <span className="font-body-sm text-body-sm text-on-surface leading-snug">
                  {point}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Local OCR Raw Text Extraction */}
      {ocrExtractedText && (
        <div className="p-space-sm bg-surface-container-low rounded-none border border-emerald-500/20">
          <div className="flex items-center justify-between mb-1.5">
            <div className="flex items-center gap-1.5 font-label-badge text-[11px] text-emerald-700 uppercase">
              <span className="material-symbols-outlined text-[16px]">document_scanner</span>
              <span>Văn bản nhận diện từ ảnh</span>
            </div>
            <span className="text-[9px] font-mono px-1.5 py-0.5 bg-emerald-500/20 text-emerald-700 uppercase">
              OCR cục bộ
            </span>
          </div>
          <div className="max-h-36 overflow-y-auto p-2 bg-slate-50 border border-white/5 font-code-telemetry text-[11px] text-on-surface-variant leading-relaxed whitespace-pre-line">
            {ocrExtractedText}
          </div>
        </div>
      )}

      {/* Extracted Chat Messages if any */}
      {!ocrUsed && messages.length > 0 && (
        <div className="flex flex-col gap-2 pt-2 border-t border-white/5">
          <div className="flex items-center gap-1.5 font-label-badge text-[11px] text-secondary uppercase">
            <span className="material-symbols-outlined text-[16px]">chat</span>
            <span>Đoạn trích xuất từ tin nhắn</span>
          </div>
          <div className="max-h-48 overflow-y-auto space-y-1.5 p-2 bg-surface-container-lowest rounded-none">
            {messages.map((msg, i) => (
              <ChatBubble key={i} sender={msg.sender} text={msg.text} />
            ))}
          </div>
        </div>
      )}

      {/* Safety recommendations */}
      <div className="p-space-sm bg-surface-container-low rounded-none border border-white/5">
        <div className="flex items-center gap-1.5 font-label-badge text-[11px] text-primary uppercase mb-1">
          <span className="material-symbols-outlined text-[16px]">health_and_safety</span>
          <span>Khuyến nghị an toàn tức thì</span>
        </div>
        <ul className="space-y-1 font-body-sm text-body-sm text-on-surface-variant list-disc pl-4">
          <li>Tuyệt đối KHÔNG nhấp vào bất kỳ liên kết nào trong tin nhắn.</li>
          <li>Không cung cấp mã OTP, mật khẩu hay thông tin căn cước công dân.</li>
          <li>Chặn số điện thoại/tài khoản người gửi và thông báo cho người thân.</li>
        </ul>
      </div>

      {/* Actions */}
      <div className="flex flex-wrap items-center gap-2 pt-2 border-t border-white/5">
        <button
          type="button"
          onClick={handleShare}
          className="flex-1 py-2 px-3 bg-surface-bright hover:bg-surface-container-highest text-on-surface rounded-none font-title-md text-xs font-semibold flex items-center justify-center gap-1.5 transition-colors border border-white/10"
        >
          <span className="material-symbols-outlined text-[16px]">share</span>
          <span>{copied ? 'Đã sao chép cảnh báo!' : 'Chia sẻ cảnh báo'}</span>
        </button>

        <a
          href="tel:18001031"
          className="py-2 px-3 bg-error-container hover:bg-error text-error hover:text-white rounded-none font-title-md text-xs font-semibold flex items-center justify-center gap-1.5 transition-colors"
          title="Tổng đài An toàn mạng quốc gia"
        >
          <span className="material-symbols-outlined text-[16px]">e911_emergency</span>
          <span>Tổng đài 1800.1031</span>
        </a>
      </div>
    </div>
  );
}
