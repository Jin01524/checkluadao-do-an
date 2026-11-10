/**
 * ChatBubble – hiển thị bong bóng tin nhắn mô phỏng
 * Props:
 *   sender: "scammer" | "user" | "unknown"
 *   text: string
 */
export default function ChatBubble({ sender = 'unknown', text }) {
  const labelMap = {
    scammer: 'Kẻ lừa đảo',
    user: 'Bạn',
    unknown: 'Không rõ',
  };

  return (
    <div className={`chat-bubble-wrapper ${sender}`}>
      <span className="chat-bubble-label">{labelMap[sender] || 'Không rõ'}</span>
      <div className={`chat-bubble ${sender}`}>
        {text}
      </div>
    </div>
  );
}
