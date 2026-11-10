const agents = [
  { key: 'threatHunterAnalysis', label: 'AI 1 · Phân tích rủi ro', icon: 'warning', color: 'text-error' },
  { key: 'auditorDefense', label: 'AI 2 · Phân tích an toàn', icon: 'verified_user', color: 'text-emerald-700' },
  { key: 'arbiterVerdict', label: 'AI 3 · Kết luận', icon: 'gavel', color: 'text-primary' },
];

export default function TemplateAnalysis({ template }) {
  const debate = template?.multi_agent_debate;
  const hasThreeAnalyses = debate && agents.every(({ key }) => typeof debate[key] === 'string' && debate[key].trim());

  if (!hasThreeAnalyses) {
    return <p className="text-sm text-on-surface-variant leading-relaxed">{template?.analysis || 'Chưa có phân tích chi tiết cho mẫu này.'}</p>;
  }

  return (
    <div className="space-y-3">
      {agents.map(({ key, label, icon, color }) => (
        <section key={key} className="rounded-xl border border-white/10 bg-surface-container p-3">
          <h3 className={`mb-1 flex items-center gap-2 text-xs font-bold uppercase tracking-wide ${color}`}>
            <span className="material-symbols-outlined text-[17px]">{icon}</span>
            {label}
          </h3>
          <p className="whitespace-pre-wrap text-sm leading-relaxed text-on-surface-variant">{debate[key]}</p>
        </section>
      ))}
    </div>
  );
}
