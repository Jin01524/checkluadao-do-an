import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import API from '../api/api';
import { DEFAULT_TEMPLATES } from '../data/defaultTemplates';
import { normalizeThreatScore, getThreatLevel } from '../utils/threatUtils';

export default function TemplatesPage() {
  const [templates, setTemplates] = useState(DEFAULT_TEMPLATES);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [selectedStatus, setSelectedStatus] = useState('ALL'); // 'ALL' | 'VERIFIED' | 'UNVERIFIED'
  const navigate = useNavigate();

  useEffect(() => {
    const fetchTemplates = async () => {
      try {
        const allTemplates = [];
        let offset = 0;
        let hasMore = true;
        while (hasMore) {
          const res = await API.get('/api/templates', { params: { limit: 50, offset } });
          if (!Array.isArray(res.data?.data)) throw new Error('Danh sách mẫu không hợp lệ');
          allTemplates.push(...res.data.data);
          offset += res.data.data.length;
          hasMore = res.data.hasMore === true && res.data.data.length > 0;
        }
        setTemplates(allTemplates);
      } catch (err) {
        console.warn('[TemplatesPage] Using offline threat library:', err.message);
        setTemplates(DEFAULT_TEMPLATES);
      } finally {
        setLoading(false);
      }
    };
    fetchTemplates();
  }, []);

  const filtered = templates.filter((tpl) => {
    const matchesSearch =
      !search ||
      tpl.title?.toLowerCase().includes(search.toLowerCase()) ||
      tpl.scam_type?.toLowerCase().includes(search.toLowerCase()) ||
      tpl.platform?.toLowerCase().includes(search.toLowerCase());

    const matchesStatus =
      selectedStatus === 'ALL' ||
      (selectedStatus === 'VERIFIED' && Boolean(tpl.is_approved)) ||
      (selectedStatus === 'UNVERIFIED' && !tpl.is_approved);

    return matchesSearch && matchesStatus;
  });

  const verifiedCount = templates.filter((t) => t.is_approved).length;
  const unverifiedCount = templates.filter((t) => !t.is_approved).length;

  return (
    <main className="w-full pt-8 pb-20 bg-surface min-h-screen relative overflow-hidden">
      {/* Background Cyber Orbs */}
      <div className="absolute -top-40 right-10 w-96 h-96 bg-primary/10 rounded-full blur-3xl pointer-events-none"></div>
      <div className="absolute top-80 -left-20 w-80 h-80 bg-error/10 rounded-full blur-3xl pointer-events-none"></div>

      <div className="max-w-[1280px] mx-auto px-4 sm:px-6 relative z-10">
        {/* Header Section */}
        <section className="mb-space-xl">
          <div className="flex flex-col lg:flex-row lg:items-end justify-between gap-space-md mb-space-lg">
            <div className="max-w-3xl">
              <h1 className="font-headline-lg text-2xl sm:text-3xl lg:text-headline-lg text-on-surface tracking-tight mb-space-2xs font-bold">
                Kho Mẫu Tin Nhắn
              </h1>
              <p className="font-body-md text-body-md text-on-surface-variant max-w-2xl">
                Tham khảo các mẫu tin nhắn đã phân tích. Trạng thái kiểm duyệt được ghi rõ trên từng mẫu; mẫu chưa kiểm duyệt cần được xác minh thêm.
              </p>
            </div>

            {/* Metric Pulse Cards */}
            <div className="flex items-center gap-space-xs bg-surface-container-low p-space-xs rounded-none border border-white/5 self-start lg:self-auto flex-wrap sm:flex-nowrap">
              <div className="px-space-sm py-space-2xs bg-surface-container rounded-none">
                <span className="font-label-caption text-label-caption text-on-surface-variant block">Tổng số mẫu</span>
                <span className="font-headline-sm text-headline-sm text-primary font-bold">{templates.length > 0 ? `${templates.length}` : '0'}</span>
              </div>

              <div className="px-space-sm py-space-2xs bg-surface-container rounded-none">
                <span className="font-label-caption text-label-caption text-on-surface-variant block">Đã kiểm định</span>
                <span className="font-headline-sm text-headline-sm text-emerald-700 font-bold">{verifiedCount}</span>
              </div>

              <div className="px-space-sm py-space-2xs bg-surface-container rounded-none">
                <span className="font-label-caption text-label-caption text-on-surface-variant block">Chưa kiểm định</span>
                <span className="font-headline-sm text-headline-sm text-amber-700 font-bold">{unverifiedCount}</span>
              </div>
            </div>
          </div>

          {/* Smart Filter Control Deck */}
          <div className="bg-surface-container-low p-space-md rounded-none shadow-md border border-white/5 space-y-space-md">
            {/* Search Bar */}
            <div className="relative w-full">
              <span className="material-symbols-outlined absolute left-space-sm top-1/2 -translate-y-1/2 text-on-surface-variant text-[20px]">
                search
              </span>
              <input
                type="text"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Tìm kiếm theo từ khóa lừa đảo, tên ngân hàng, cơ quan mạo danh, đường dẫn độc hại..."
                className="w-full bg-surface-container text-on-surface text-body-md pl-12 pr-4 py-3 rounded-none border border-white/5 focus:outline-none focus:ring-1 focus:ring-primary placeholder-on-surface-variant/40"
              />
              {search && (
                <button
                  onClick={() => setSearch('')}
                  className="absolute right-4 top-1/2 -translate-y-1/2 text-on-surface-variant hover:text-on-surface"
                >
                  <span className="material-symbols-outlined text-[18px]">close</span>
                </button>
              )}
            </div>

            {/* Status Filter Pills */}
            <div className="flex flex-wrap items-center justify-between gap-3 pt-1 border-t border-white/5">
              <div className="flex flex-wrap items-center gap-2">
                <span className="text-xs font-label-badge text-on-surface-variant mr-1">TRẠNG THÁI:</span>
                {[
                  { id: 'ALL', label: 'Tất cả' },
                  { id: 'VERIFIED', label: 'Đã kiểm định', icon: 'verified' },
                  { id: 'UNVERIFIED', label: 'Chưa được kiểm định', icon: 'schedule' },
                ].map((s) => (
                  <button
                    key={s.id}
                    onClick={() => setSelectedStatus(s.id)}
                    className={`px-3 py-1.5 rounded-none text-xs font-title-md transition-colors flex items-center gap-1.5 ${
                      selectedStatus === s.id
                        ? 'bg-primary-container text-on-primary-container font-semibold shadow-sm'
                        : 'bg-surface-container text-on-surface-variant hover:text-on-surface hover:bg-surface-container-high'
                    }`}
                  >
                    {s.icon && <span className="material-symbols-outlined text-[14px]">{s.icon}</span>}
                    <span>{s.label}</span>
                  </button>
                ))}
              </div>

            </div>
          </div>
        </section>

        {/* Loading Skeleton */}
        {loading && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-space-lg">
            {[1, 2, 3, 4, 5, 6].map((i) => (
              <div key={i} className="bg-surface-container-low rounded-none p-space-lg border border-white/5 animate-pulse min-h-[200px] flex flex-col justify-between">
                <div className="flex justify-between items-center">
                  <div className="w-24 h-5 bg-surface-container-high rounded-none"></div>
                  <div className="w-16 h-4 bg-surface-container-high rounded-none"></div>
                </div>
                <div className="w-full h-8 bg-surface-container-high rounded-none my-3"></div>
                <div className="w-32 h-4 bg-surface-container-high rounded-none"></div>
              </div>
            ))}
          </div>
        )}

        {/* Error Alert */}
        {error && (
          <div className="flex items-center gap-2 p-4 bg-error-container/20 border border-error/40 rounded-none text-error mb-6">
            <span className="material-symbols-outlined">error</span>
            <span>{error}</span>
          </div>
        )}

        {/* Empty State */}
        {!loading && !error && filtered.length === 0 && (
          <div className="bg-surface-container-low rounded-none p-space-2xl border border-white/5 text-center flex flex-col items-center justify-center min-h-[300px]">
            <span className="material-symbols-outlined text-[48px] text-on-surface-variant/40 mb-3">
              folder_off
            </span>
            <div className="font-headline-sm text-on-surface font-semibold">
              Không tìm thấy mẫu tin nhắn phù hợp
            </div>
            <p className="font-body-sm text-on-surface-variant mt-1 max-w-sm">
              Thử thay đổi từ khóa tìm kiếm hoặc trạng thái kiểm định.
            </p>
          </div>
        )}

        {/* Templates Grid */}
        {!loading && filtered.length > 0 && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-space-lg">
            {filtered.map((tpl) => {
              const id = tpl.id || tpl._id;
              const isSafe = tpl.scam_type === 'Tin nhắn an toàn / Bình thường';
              const danger = !isSafe && tpl.confidence_score != null && Number.isFinite(Number(tpl.confidence_score))
                ? normalizeThreatScore(tpl.confidence_score, 0)
                : null;
              const threat = danger == null ? null : getThreatLevel(danger);

              return (
                <article
                  key={id}
                  onClick={() => {
                    window.location.href = `/templates/${id}`;
                  }}
                  className="bg-surface-container-low hover:bg-surface-container rounded-none p-space-lg border border-white/5 hover:border-primary/40 transition-all cursor-pointer shadow-sm hover:shadow-lg flex flex-col justify-between group"
                >
                  <div>
                    {/* Top Row: Severity, Verification Status & Case Code */}
                    <div className="flex items-center justify-between gap-2 mb-space-xs flex-wrap">
                      <div className="flex items-center gap-1.5 flex-wrap">
                        <span
                          className={`font-label-badge text-label-badge px-2 py-0.5 rounded-none font-bold border ${threat?.badgeClass || 'text-on-surface-variant bg-surface-container border-outline/30'}`}
                        >
                          {isSafe ? 'AI đánh giá an toàn' : threat ? `${threat.level} - ${danger}%` : 'Chưa có điểm rủi ro'}
                        </span>

                        {/* Verification Status Badge */}
                        {tpl.is_approved ? (
                          <span className="inline-flex items-center gap-1 text-[11px] font-medium text-emerald-700 bg-[#10b981]/10 border border-[#10b981]/25 px-1.5 py-0.5">
                            <span className="material-symbols-outlined text-[13px]">verified</span>
                            <span>Đã kiểm định thông tin</span>
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 text-[11px] font-medium text-amber-700 bg-amber-400/10 border border-amber-400/25 px-1.5 py-0.5">
                            <span className="material-symbols-outlined text-[13px]">schedule</span>
                            <span>Chưa được kiểm định</span>
                          </span>
                        )}
                      </div>

                      <span className="font-code-telemetry text-code-telemetry text-outline">
                        #CASE-{String(id).slice(-5).toUpperCase()}
                      </span>
                    </div>

                    {/* Title */}
                    <h2 className="font-title-md text-title-md text-on-surface font-bold group-hover:text-primary transition-colors line-clamp-2 mb-1.5">
                      {tpl.title || tpl.scam_type || 'Mẫu tin nhắn lừa đảo'}
                    </h2>

                    {/* Excerpt / Summary */}
                    <p className="font-body-sm text-body-sm text-on-surface-variant line-clamp-3 mb-space-sm">
                      {tpl.analysis || tpl.summary || tpl.content || 'Chiến dịch lừa đảo mạo danh nhằm chiếm đoạt tài khoản hoặc mã xác thực của người dùng.'}
                    </p>
                  </div>

                  {/* Meta Footer */}
                  <div className="flex items-center justify-end pt-space-xs border-t border-white/5 text-xs text-on-surface-variant font-label-caption">
                    <span className="text-primary font-semibold flex items-center gap-0.5 group-hover:translate-x-1 transition-transform">
                      <span>Xem chi tiết</span>
                      <span className="material-symbols-outlined text-[14px]">arrow_forward</span>
                    </span>
                  </div>
                </article>
              );
            })}
          </div>
        )}
      </div>
    </main>
  );
}
