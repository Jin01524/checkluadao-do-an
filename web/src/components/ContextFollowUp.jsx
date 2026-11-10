import { useEffect, useState } from 'react';

export default function ContextFollowUp({ result, busy, onNewScan }) {
  const invalid = result.assessment?.status === 'invalid_input';
  const [sentReply, setSentReply] = useState(result.suggestedReply?.text || '');
  const [copied, setCopied] = useState(false);
  const [skipSuggestion, setSkipSuggestion] = useState(false);
  const [error, setError] = useState('');
  const canCopy = result.allowedActions?.includes('copy_suggested_reply') && Boolean(result.suggestedReply?.text);

  useEffect(() => {
    setSentReply(result.suggestedReply?.text || '');
    setCopied(false);
    setSkipSuggestion(false);
    setError('');
  }, [result]);

  const copyReply = async () => {
    try {
      await navigator.clipboard.writeText(sentReply.trim());
      setCopied(true);
      setError('');
    } catch {
      setError('Không sao chép được. Bạn có thể chọn và sao chép đoạn chữ phía trên.');
    }
  };

  return (
    <section className="bg-surface-container border border-warning/40 p-space-lg shadow-md space-y-4" aria-live="polite">
      <div className="flex items-start gap-3">
        <span className="material-symbols-outlined text-warning text-3xl">help_outline</span>
        <div>
          <h2 className="font-headline-sm font-bold text-on-surface">{invalid ? 'Chưa đọc được nội dung' : 'Chưa đủ ngữ cảnh để kết luận'}</h2>
          <p className="text-sm text-on-surface-variant mt-1">{result.assessment?.reason || 'Hãy lấy thêm thông tin trước khi đánh giá.'}</p>
          <p className="text-xs text-warning mt-2">{invalid ? 'Hãy chụp lại ảnh rõ hơn hoặc dán nội dung tin nhắn để quét lại.' : 'Chưa thể xác nhận tin này an toàn. Lượt này không được lưu.'}</p>
        </div>
      </div>

      {!invalid && canCopy && !skipSuggestion && (
        <div className="border-2 border-primary bg-primary/5 p-4 space-y-3">
          <label htmlFor="suggested-reply" className="block text-sm font-semibold">AI gợi ý bạn hỏi lại người gửi</label>
          <textarea id="suggested-reply" value={sentReply} maxLength={160} rows={2}
            onChange={(event) => setSentReply(event.target.value)}
            className="w-full border border-primary/30 bg-white p-3 text-base font-semibold text-on-surface" />
          <p className="text-xs text-on-surface-variant">Nếu đây là số/tài khoản lạ, việc trả lời có thể xác nhận bạn đang hoạt động. Bạn có thể bỏ qua bước này.</p>
          <div className="flex flex-wrap gap-2">
            <button type="button" onClick={copyReply} disabled={!sentReply.trim() || busy}
              className="bg-primary-container text-white px-4 py-2 text-sm font-semibold disabled:opacity-50">
              {copied ? 'Đã sao chép' : 'Sao chép tin nhắn'}
            </button>
            <button type="button" onClick={() => setSkipSuggestion(true)} disabled={busy}
              className="border border-white/20 bg-white px-4 py-2 text-sm font-semibold">
              Bỏ qua
            </button>
          </div>
        </div>
      )}

      {!invalid && <p className="text-sm text-on-surface-variant">Khi có phản hồi mới, chụp hoặc dán lại đoạn hội thoại gồm tin ban đầu và phản hồi mới. Hệ thống sẽ phân tích như một lượt mới, không giữ phiên cũ.</p>}
      {error && <p role="alert" className="text-xs text-error">{error}</p>}
      {!invalid && <p className="text-xs text-on-surface-variant">Lời người gửi tự khai không chứng minh danh tính. Nếu họ yêu cầu tiền, OTP hoặc truy cập liên kết, hãy dừng phản hồi và xác minh qua kênh chính thức.</p>}
      <button type="button" onClick={onNewScan} disabled={busy}
        className="bg-primary-container text-white px-4 py-3 text-sm font-semibold disabled:opacity-50">
        Quét lượt mới
      </button>
    </section>
  );
}
