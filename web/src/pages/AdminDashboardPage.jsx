import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import ChatBubble from '../components/ChatBubble';
import TemplateAnalysis from '../components/TemplateAnalysis';
import API from '../api/api';
import { getConsistentThreatScore, getThreatLevel, getAttackTarget } from '../utils/threatUtils';

// Modal xem chi tiết mẫu
function TemplateModal({ template, onClose }) {
  if (!template) return null;

  let messages = [];
  try {
    messages = typeof template.messages_json === 'string'
      ? JSON.parse(template.messages_json)
      : template.messages_json || [];
  } catch { messages = []; }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/75 backdrop-blur-sm animate-fadeIn">
      <div className="w-full max-w-2xl bg-surface-container-low border border-white/10 rounded-2xl shadow-2xl overflow-hidden flex flex-col max-h-[90vh]">
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-white/10 bg-surface-container">
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-primary text-[20px]">description</span>
            <span className="font-headline-sm text-sm font-bold text-on-surface">
              Chi tiết hồ sơ: {template.title || 'Mẫu không tên'}
            </span>
          </div>
          <button
            onClick={onClose}
            className="w-8 h-8 rounded-lg bg-surface-container-high hover:bg-surface-container-highest text-on-surface flex items-center justify-center transition-colors"
          >
            <span className="material-symbols-outlined text-[18px]">close</span>
          </button>
        </div>

        {/* Body */}
        <div className="p-5 overflow-y-auto space-y-4">
          {(() => {
            const danger = getConsistentThreatScore(template);
            const isSafe = template.scam_type === 'Tin nhắn an toàn / Bình thường' || danger < 40;
            return (
              <div className="flex flex-wrap items-center gap-2 text-xs">
                <span className="font-label-badge bg-primary-container/20 text-primary border border-primary/30 px-2 py-0.5 rounded uppercase">
                  {template.platform || 'SMS'}
                </span>
                {isSafe ? (
                  <span className="font-label-badge bg-[#10b981]/20 text-emerald-700 border border-[#10b981]/30 px-2 py-0.5 rounded font-bold">
                    MẪU AN TOÀN ĐỐI CHIẾU
                  </span>
                ) : (
                  <span className="font-label-badge bg-error-container/20 text-error border border-error/30 px-2 py-0.5 rounded">
                    {template.scam_type || 'Lừa đảo'}
                  </span>
                )}
                <span className={`font-label-badge px-2 py-0.5 rounded font-mono font-bold border ${
                  isSafe
                    ? 'text-emerald-700 bg-[#10b981]/20 border-[#10b981]/30'
                    : 'text-error bg-error-container/20 border-error/30'
                }`}>
                  {isSafe ? `AN TOÀN (${danger}%)` : `RỦI RO: ${danger}%`}
                </span>
                <span className="font-label-badge px-2 py-0.5 rounded text-on-surface-variant bg-surface-container border border-white/10">
                  MỤC TIÊU: <span className="text-primary font-semibold">{getAttackTarget(template)}</span>
                </span>
              </div>
            );
          })()}

          {/* Raw / Extracted Messages */}
          <div>
            <div className="text-xs font-label-badge text-secondary mb-2 uppercase">
              Nội dung tin nhắn ghi nhận:
            </div>
            {messages.length > 0 ? (
              <div className="p-3 bg-surface-container rounded-xl space-y-2 border border-white/5">
                {messages.map((msg, idx) => (
                  <ChatBubble
                    key={idx}
                    sender={msg.sender || 'unknown'}
                    text={msg.text || msg.content || ''}
                  />
                ))}
              </div>
            ) : (
              <div className="p-3 bg-surface-container rounded-xl font-code-telemetry text-sm text-on-surface border border-white/5">
                {template.content || template.message || 'Không có tin nhắn thô'}
              </div>
            )}
          </div>

          {/* Analysis */}
          {(template.analysis || template.multi_agent_debate) && (
            <div className="p-3 bg-surface-container rounded-xl border border-white/5">
              <div className="font-label-badge text-xs text-tertiary uppercase mb-1">
                Phân tích giám định AI:
              </div>
              <TemplateAnalysis template={template} />
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

// Tab 1: Quản lý API Key
function ApiKeysTab() {
  const [keys, setKeys] = useState([]);
  const [loading, setLoading] = useState(true);
  const [newLabel, setNewLabel] = useState('');
  const [newKey, setNewKey] = useState('');
  const [adding, setAdding] = useState(false);
  const [error, setError] = useState('');

  // ── Gemini Model Realtime Switching ──────────────────────────────────────────
  const defaultSupportedModels = [
    {
      id: 'gemini-3.5-flash',
      name: 'Gemini 3.5 Flash',
      badge: 'Khuyên dùng',
      description: 'Thế hệ mới nhất, tối ưu lý luận an ninh mạng, phản hồi tức thì và chính xác cao.',
      isDefault: true,
    },
    {
      id: 'gemini-3.0-flash',
      name: 'Gemini 3.0 Flash',
      badge: 'Tốc độ cao',
      description: 'Cân bằng tối ưu giữa tốc độ phân tích và khả năng phát hiện thủ đoạn tinh vi.',
      isDefault: false,
    },
    {
      id: 'gemini-2.5-flash',
      name: 'Gemini 2.5 Flash',
      badge: 'Chuyên sâu',
      description: 'Xử lý ổn định cao, nhận diện cấu trúc lừa đảo và tin nhắn mẫu chuẩn xác.',
      isDefault: false,
    },
  ];

  const [activeModel, setActiveModel] = useState('gemini-3.5-flash');
  const [supportedModels, setSupportedModels] = useState(defaultSupportedModels);
  const [switchingModel, setSwitchingModel] = useState(false);
  const [modelSuccessMsg, setModelSuccessMsg] = useState('');

  const fetchActiveModel = async () => {
    try {
      const res = await API.get('/api/admin/active-model');
      if (res.data?.activeModel) {
        setActiveModel(res.data.activeModel);
      }
      if (Array.isArray(res.data?.supportedModels) && res.data.supportedModels.length > 0) {
        setSupportedModels(res.data.supportedModels);
      }
    } catch (err) {
      console.warn('Could not fetch active model:', err);
    }
  };

  const handleSwitchModel = async (modelId) => {
    if (modelId === activeModel || switchingModel) return;
    setSwitchingModel(true);
    setModelSuccessMsg('');
    try {
      const res = await API.post('/api/admin/active-model', { model: modelId });
      setActiveModel(res.data.activeModel || modelId);
      setModelSuccessMsg(`Đã chuyển đổi model toàn hệ thống sang ${res.data.activeModel || modelId} thành công (Realtime)!`);
      setTimeout(() => setModelSuccessMsg(''), 4500);
    } catch (err) {
      alert(err.response?.data?.error || 'Không thể chuyển đổi model AI.');
    } finally {
      setSwitchingModel(false);
    }
  };

  const fetchKeys = async () => {
    try {
      const res = await API.get('/api/admin/api-keys');
      setKeys(res.data.data || []);
    } catch {
      setError('Không thể tải danh sách API key.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchKeys();
    fetchActiveModel();
  }, []);

  const handleToggle = async (id, current) => {
    try {
      await API.patch(`/api/admin/api-keys/${id}`, { isActive: !current });
      setKeys(keys.map(k => (k.id === id || k._id === id) ? { ...k, is_active: !current } : k));
    } catch {
      alert('Không thể cập nhật trạng thái.');
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Bạn có chắc muốn xóa API key này không?')) return;
    try {
      await API.delete(`/api/admin/api-keys/${id}`);
      setKeys(keys.filter(k => k.id !== id && k._id !== id));
    } catch {
      alert('Không thể xóa API key.');
    }
  };

  const handleAdd = async (e) => {
    e.preventDefault();
    if (!newKey.trim()) return;
    setAdding(true);
    setError('');
    try {
      const res = await API.post('/api/admin/api-keys', {
        label: newLabel.trim() || 'Gemini Key',
        apiKey: newKey.trim()
      });
      setKeys([...keys, res.data.data]);
      setNewLabel('');
      setNewKey('');
    } catch (err) {
      setError(err.response?.data?.message || 'Không thể thêm API key.');
    } finally {
      setAdding(false);
    }
  };

  const displayModels = supportedModels.length > 0 ? supportedModels : defaultSupportedModels;

  return (
    <div className="space-y-6">
      {/* ── Model Selection Realtime Card ── */}
      <div className="bg-surface-container-low p-space-md rounded-xl border border-white/5 space-y-4">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 border-b border-white/5 pb-3">
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-primary text-[22px]">neurology</span>
            <div>
              <h3 className="font-title-md text-sm font-bold text-on-surface">
                Chuyển Đổi Model AI Hệ Thống (Realtime)
              </h3>
              <p className="text-[11px] text-on-surface-variant">
                Lựa chọn phiên bản Gemini Flash (2.5 – 3.5). Không sử dụng dòng Lite. Thay đổi tức thì không cần khởi động lại.
              </p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <span className="relative flex h-2.5 w-2.5">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-[#10b981] opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-[#10b981]"></span>
            </span>
            <span className="font-mono text-xs font-bold text-primary">
              {activeModel}
            </span>
          </div>
        </div>

        {modelSuccessMsg && (
          <div className="flex items-center gap-2 p-2.5 text-xs bg-[#10b981]/15 border border-[#10b981]/30 rounded-lg text-emerald-700">
            <span className="material-symbols-outlined text-[18px]">check_circle</span>
            <span>{modelSuccessMsg}</span>
          </div>
        )}

        <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
          {displayModels.map((m) => {
            const isSelected = activeModel === m.id;
            return (
              <div
                key={m.id}
                onClick={() => handleSwitchModel(m.id)}
                className={`relative p-3.5 rounded-xl border transition-all cursor-pointer flex flex-col justify-between ${
                  isSelected
                    ? 'bg-primary/10 border-primary shadow-[0_0_15px_rgba(255,180,168,0.15)] ring-1 ring-primary/40'
                    : 'bg-surface-container border-white/5 hover:border-white/20 hover:bg-surface-container-high'
                } ${switchingModel ? 'opacity-70 pointer-events-none' : ''}`}
              >
                <div>
                  <div className="flex items-center justify-between gap-1 mb-1.5">
                    <span className="font-bold text-xs text-on-surface flex items-center gap-1.5">
                      {m.name}
                      {m.badge && (
                        <span className={`text-[10px] px-1.5 py-0.5 rounded font-semibold ${
                          isSelected ? 'bg-primary text-on-primary' : 'bg-surface-container-highest text-on-surface-variant'
                        }`}>
                          {m.badge}
                        </span>
                      )}
                    </span>
                    <span className={`material-symbols-outlined text-[18px] ${isSelected ? 'text-primary' : 'text-on-surface-variant/40'}`}>
                      {isSelected ? 'radio_button_checked' : 'radio_button_unchecked'}
                    </span>
                  </div>
                  <p className="text-[11px] text-on-surface-variant leading-relaxed mb-3">
                    {m.description}
                  </p>
                </div>

                <div className="pt-2 border-t border-white/5 flex items-center justify-between text-[11px]">
                  <span className="font-mono text-[10px] text-on-surface-variant">{m.id}</span>
                  <button
                    type="button"
                    disabled={isSelected || switchingModel}
                    className={`px-2 py-1 rounded text-[10px] font-bold transition-colors ${
                      isSelected
                        ? 'bg-primary/20 text-primary cursor-default'
                        : 'bg-surface-container-highest text-on-surface hover:bg-primary hover:text-on-primary'
                    }`}
                  >
                    {isSelected ? 'Đang hoạt động' : 'Kích hoạt'}
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Add key form */}
      <div className="bg-surface-container-low p-space-md rounded-xl border border-white/5">
        <div className="flex items-center gap-2 mb-3">
          <span className="material-symbols-outlined text-primary text-[20px]">add_circle</span>
          <h3 className="font-title-md text-sm font-bold text-on-surface">Thêm Gemini API Key Mới</h3>
        </div>

        {error && (
          <div className="p-2 mb-3 text-xs bg-error-container/20 border border-error/30 rounded text-error">
            {error}
          </div>
        )}

        <form onSubmit={handleAdd} className="grid grid-cols-1 sm:grid-cols-12 gap-2">
          <div className="sm:col-span-4">
            <input
              type="text"
              placeholder="Nhãn (VD: Key dự phòng 02)"
              value={newLabel}
              onChange={(e) => setNewLabel(e.target.value)}
              className="w-full bg-surface-container text-xs text-on-surface px-3 py-2 rounded-lg border border-white/5 focus:outline-none focus:border-primary"
            />
          </div>
          <div className="sm:col-span-6">
            <input
              type="password"
              placeholder="Nhập API Key (AIzaSy...)"
              value={newKey}
              onChange={(e) => setNewKey(e.target.value)}
              className="w-full bg-surface-container text-xs text-on-surface px-3 py-2 rounded-lg border border-white/5 focus:outline-none focus:border-primary font-mono"
            />
          </div>
          <div className="sm:col-span-2">
            <button
              type="submit"
              disabled={adding}
              className="w-full h-full py-2 bg-primary-container hover:bg-inverse-primary text-on-primary-container text-xs font-bold rounded-lg transition-colors flex items-center justify-center gap-1"
            >
              <span>{adding ? 'Đang thêm...' : 'Lưu Key'}</span>
            </button>
          </div>
        </form>
      </div>

      {/* Keys List */}
      <div className="bg-surface-container-low p-space-md rounded-xl border border-white/5">
        <div className="flex items-center justify-between mb-4">
          <h3 className="font-title-md text-sm font-bold text-on-surface">
            Danh Sách API Keys ({keys.length})
          </h3>
          <span className="font-label-badge text-[11px] text-tertiary">
            HỆ THỐNG XOAY VÒNG KEY TỰ ĐỘNG
          </span>
        </div>

        {loading ? (
          <div className="p-6 text-center text-xs text-on-surface-variant">Đang tải...</div>
        ) : keys.length === 0 ? (
          <div className="p-6 text-center text-xs text-on-surface-variant">Chưa cấu hình API key nào.</div>
        ) : (
          <div className="space-y-2">
            {keys.map((k) => {
              const id = k.id || k._id;
              const isActive = k.is_active !== false;
              return (
                <div
                  key={id}
                  className="flex items-center justify-between p-3 bg-surface-container rounded-lg border border-white/5 text-xs"
                >
                  <div className="flex items-center gap-3">
                    <span className={`w-2 h-2 rounded-full ${isActive ? 'bg-[#10b981]' : 'bg-secondary'}`}></span>
                    <div>
                      <div className="font-semibold text-on-surface">{k.label || 'Gemini Key'}</div>
                      <div className="font-mono text-[11px] text-on-surface-variant">
                        {k.api_key_masked || (k.api_key ? `••••${k.api_key.slice(-6)}` : '••••••••')}
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => handleToggle(id, isActive)}
                      className={`px-2 py-1 rounded text-[11px] font-semibold transition-colors ${
                        isActive ? 'bg-[#10b981]/20 text-emerald-700' : 'bg-secondary/20 text-secondary'
                      }`}
                    >
                      {isActive ? 'Kích hoạt' : 'Tạm tắt'}
                    </button>
                    <button
                      onClick={() => handleDelete(id)}
                      className="p-1 text-on-surface-variant hover:text-error transition-colors"
                      title="Xóa"
                    >
                      <span className="material-symbols-outlined text-[16px]">delete</span>
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}

// Tab 2: Quản lý mẫu tin nhắn (Moderation)
function TemplatesTab() {
  const [templates, setTemplates] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedTemplate, setSelectedTemplate] = useState(null);
  const [filterType, setFilterType] = useState('ALL'); // 'ALL' | 'RISK' | 'SAFE' | 'PENDING' | 'APPROVED'
  const [searchQuery, setSearchQuery] = useState('');

  const fetchAll = async () => {
    try {
      const res = await API.get('/api/admin/templates');
      setTemplates(res.data.data || []);
    } catch {
      setTemplates([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchAll(); }, []);

  const handleApprove = async (id, currentApproved) => {
    try {
      await API.put(`/api/admin/templates/${id}`, { isApproved: !currentApproved });
      setTemplates(templates.map(t => (t.id === id || t._id === id) ? { ...t, is_approved: !currentApproved } : t));
    } catch {
      alert('Không thể cập nhật trạng thái duyệt.');
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Bạn có chắc muốn xóa mẫu này?')) return;
    try {
      await API.delete(`/api/admin/templates/${id}`);
      setTemplates(templates.filter(t => t.id !== id && t._id !== id));
    } catch {
      alert('Không thể xóa mẫu.');
    }
  };

  const safeCount = templates.filter(t => t.scam_type === 'Tin nhắn an toàn / Bình thường' || getConsistentThreatScore(t) < 40).length;
  const riskCount = templates.filter(t => t.scam_type !== 'Tin nhắn an toàn / Bình thường' && getConsistentThreatScore(t) >= 40).length;
  const pendingCount = templates.filter(t => !t.is_approved && t.scam_type !== 'Tin nhắn an toàn / Bình thường').length;
  const approvedCount = templates.filter(t => t.is_approved).length;

  const filteredTemplates = templates.filter((tpl) => {
    const danger = getConsistentThreatScore(tpl);
    const isSafe = tpl.scam_type === 'Tin nhắn an toàn / Bình thường' || danger < 40;

    // Filter by type
    if (filterType === 'RISK' && isSafe) return false;
    if (filterType === 'SAFE' && !isSafe) return false;
    if (filterType === 'PENDING' && (tpl.is_approved || isSafe)) return false;
    if (filterType === 'APPROVED' && !tpl.is_approved) return false;

    // Search
    if (searchQuery.trim()) {
      const term = searchQuery.toLowerCase();
      const matchTitle = tpl.title?.toLowerCase().includes(term);
      const matchType = tpl.scam_type?.toLowerCase().includes(term);
      const matchPlatform = tpl.platform?.toLowerCase().includes(term);
      const matchAnalysis = tpl.analysis?.toLowerCase().includes(term);
      if (!matchTitle && !matchType && !matchPlatform && !matchAnalysis) return false;
    }

    return true;
  });

  return (
    <div className="bg-surface-container-low p-space-md rounded-xl border border-white/5 space-y-4">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-white/5 pb-3">
        <div>
          <h3 className="font-title-md text-sm font-bold text-on-surface flex items-center gap-2">
            <span>Bàn Kiểm Duyệt Mẫu Tin Nghi Vấn ({templates.length})</span>
            {safeCount > 0 && (
              <span className="text-[11px] px-2 py-0.5 rounded-none bg-[#10b981]/20 text-emerald-700 font-semibold">
                {safeCount} mẫu an toàn đối chiếu
              </span>
            )}
          </h3>
          <p className="text-xs text-on-surface-variant mt-0.5">
            Quản lý toàn bộ mẫu tin nhắn người dùng gửi lên gồm cả mẫu lừa đảo nghi vấn và mẫu an toàn dùng làm cơ sở đối chiếu cho AI.
          </p>
        </div>

        {/* Search */}
        <div className="relative min-w-[240px]">
          <span className="material-symbols-outlined absolute left-2.5 top-1/2 -translate-y-1/2 text-on-surface-variant text-[16px]">
            search
          </span>
          <input
            type="text"
            placeholder="Tìm kiếm mẫu tin nhắn..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full bg-surface-container text-xs text-on-surface pl-8 pr-3 py-1.5 rounded-lg border border-white/5 focus:outline-none focus:border-primary"
          />
        </div>
      </div>

      {/* Filter Tabs */}
      <div className="flex flex-wrap items-center gap-1.5 pt-1">
        {[
          { id: 'ALL', label: `Tất cả (${templates.length})` },
          { id: 'RISK', label: `Mẫu rủi ro (${riskCount})` },
          { id: 'SAFE', label: `Mẫu an toàn đối chiếu (${safeCount})`, icon: 'verified_user' },
          { id: 'PENDING', label: `Chờ duyệt (${pendingCount})` },
          { id: 'APPROVED', label: `Đã duyệt (${approvedCount})` },
        ].map((f) => (
          <button
            key={f.id}
            onClick={() => setFilterType(f.id)}
            className={`px-3 py-1 rounded-lg text-xs font-semibold transition-colors flex items-center gap-1 ${
              filterType === f.id
                ? 'bg-primary-container text-on-primary-container shadow-sm'
                : 'bg-surface-container text-on-surface-variant hover:text-on-surface hover:bg-surface-container-high'
            }`}
          >
            {f.icon && <span className="material-symbols-outlined text-[13px]">{f.icon}</span>}
            <span>{f.label}</span>
          </button>
        ))}
      </div>

      {loading ? (
        <div className="p-8 text-center text-xs text-on-surface-variant">Đang tải danh sách mẫu...</div>
      ) : filteredTemplates.length === 0 ? (
        <div className="p-8 text-center text-xs text-on-surface-variant">Không tìm thấy mẫu tin nhắn nào phù hợp bộ lọc.</div>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs text-on-surface">
            <thead>
              <tr className="border-b border-white/10 text-on-surface-variant font-label-badge">
                <th className="py-2.5 px-3">TIÊU ĐỀ & THỦ ĐOẠN</th>
                <th className="py-2.5 px-3">NỀN TẢNG</th>
                <th className="py-2.5 px-3">PHÂN LOẠI / RỦI RO</th>
                <th className="py-2.5 px-3">TRẠNG THÁI</th>
                <th className="py-2.5 px-3 text-right">THAO TÁC</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {filteredTemplates.map((tpl) => {
                const id = tpl.id || tpl._id;
                const isApproved = tpl.is_approved === true;
                const danger = getConsistentThreatScore(tpl);
                const isSafe = tpl.scam_type === 'Tin nhắn an toàn / Bình thường' || danger < 40;

                return (
                  <tr key={id} className="hover:bg-surface-container/50 transition-colors">
                    <td className="py-3 px-3">
                      <div className="font-semibold text-on-surface max-w-xs truncate flex items-center gap-1.5">
                        {isSafe ? (
                          <span className="material-symbols-outlined text-[15px] text-emerald-700 shrink-0" title="Mẫu an toàn đối chiếu">
                            verified_user
                          </span>
                        ) : (
                          <span className="material-symbols-outlined text-[15px] text-error shrink-0" title="Mẫu rủi ro lừa đảo">
                            warning
                          </span>
                        )}
                        <span className="truncate">{tpl.title || tpl.scam_type || 'Mẫu tin nhắn'}</span>
                      </div>
                      <div className="text-[11px] text-on-surface-variant truncate max-w-xs mt-0.5">
                        {tpl.content || tpl.analysis || 'Không có mô tả'}
                      </div>
                    </td>

                    <td className="py-3 px-3">
                      <span className="font-label-badge bg-surface-container px-2 py-0.5 rounded uppercase">
                        {tpl.platform || 'SMS'}
                      </span>
                    </td>

                    <td className="py-3 px-3 font-semibold font-mono">
                      {isSafe ? (
                        <span className="text-emerald-700 bg-[#10b981]/15 px-2 py-0.5 rounded text-[11px] font-bold">
                          AN TOÀN ({danger}%)
                        </span>
                      ) : (
                        <span className="text-error bg-error/15 px-2 py-0.5 rounded text-[11px] font-bold">
                          RỦI RO {danger}%
                        </span>
                      )}
                    </td>

                    <td className="py-3 px-3">
                      {isSafe ? (
                        <span className="font-label-badge px-2 py-0.5 rounded text-[10px] font-bold bg-[#10b981]/20 text-emerald-700">
                          MẪU ĐỐI CHIẾU
                        </span>
                      ) : (
                        <span
                          className={`font-label-badge px-2 py-0.5 rounded text-[10px] font-bold ${
                            isApproved
                              ? 'bg-[#10b981]/20 text-emerald-700'
                              : 'bg-warning/20 text-warning'
                          }`}
                        >
                          {isApproved ? 'ĐÃ DUYỆT' : 'CHỜ DUYỆT'}
                        </span>
                      )}
                    </td>

                    <td className="py-3 px-3 text-right">
                      <div className="inline-flex items-center gap-1">
                        <button
                          onClick={() => setSelectedTemplate(tpl)}
                          className="p-1 hover:text-primary transition-colors"
                          title="Xem chi tiết"
                        >
                          <span className="material-symbols-outlined text-[16px]">visibility</span>
                        </button>
                        {!isSafe && (
                          <button
                            onClick={() => handleApprove(id, isApproved)}
                            className={`p-1 transition-colors ${
                              isApproved ? 'hover:text-warning text-emerald-700' : 'hover:text-emerald-700 text-warning'
                            }`}
                            title={isApproved ? 'Thu hồi duyệt' : 'Duyệt mẫu'}
                          >
                            <span className="material-symbols-outlined text-[16px]">
                              {isApproved ? 'published_with_changes' : 'check_circle'}
                            </span>
                          </button>
                        )}
                        <button
                          onClick={() => handleDelete(id)}
                          className="p-1 hover:text-error text-on-surface-variant transition-colors"
                          title="Xóa mẫu"
                        >
                          <span className="material-symbols-outlined text-[16px]">delete</span>
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      {/* Modal */}
      {selectedTemplate && (
        <TemplateModal
          template={selectedTemplate}
          onClose={() => setSelectedTemplate(null)}
        />
      )}
    </div>
  );
}

// Modal đổi tên tài khoản
function RenameUserModal({ user, onClose, onUpdated }) {
  const [newUsername, setNewUsername] = useState(user?.username || '');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!newUsername.trim()) {
      setError('Vui lòng nhập tên tài khoản mới.');
      return;
    }
    setLoading(true);
    setError('');
    try {
      await API.patch(`/api/admin/users/${user.id}`, { new_username: newUsername.trim() });
      onUpdated();
      onClose();
    } catch (err) {
      setError(err.response?.data?.error || 'Đổi tên tài khoản thất bại.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-fadeIn">
      <div className="w-full max-w-md bg-surface-container-low border border-white/10 p-5 rounded-none shadow-2xl">
        <div className="flex items-center justify-between pb-3 mb-4 border-b border-white/10">
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-primary text-[20px]">badge</span>
            <h3 className="font-title-md text-sm font-bold text-on-surface">Đổi Tên Tài Khoản</h3>
          </div>
          <button
            onClick={onClose}
            className="p-1 text-on-surface-variant hover:text-on-surface rounded-none"
          >
            <span className="material-symbols-outlined text-[18px]">close</span>
          </button>
        </div>

        {error && (
          <div className="p-3 mb-4 bg-error-container/20 border border-error/30 text-error text-xs flex items-center gap-2 rounded-none">
            <span className="material-symbols-outlined text-[16px]">warning</span>
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-medium text-on-surface-variant mb-1">
              Tên tài khoản hiện tại: <span className="font-bold text-on-surface">{user.username}</span>
            </label>
            <label className="block text-xs font-medium text-on-surface mb-1 mt-3">
              Tên tài khoản mới
            </label>
            <input
              type="text"
              value={newUsername}
              onChange={(e) => setNewUsername(e.target.value)}
              placeholder="ví dụ: mod_thao_soc..."
              className="w-full bg-surface-container text-on-surface text-xs px-3 py-2 rounded-none border border-white/10 focus:outline-none focus:border-primary"
            />
          </div>

          <div className="flex items-center justify-end gap-2 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="px-3 py-2 text-xs text-on-surface-variant hover:text-on-surface rounded-none border border-white/10"
            >
              Hủy
            </button>
            <button
              type="submit"
              disabled={loading}
              className="px-4 py-2 text-xs font-semibold bg-primary-container hover:bg-inverse-primary text-on-primary-container rounded-none transition-all disabled:opacity-50 flex items-center gap-1.5"
            >
              {loading ? 'Đang lưu...' : 'Lưu Thay Đổi'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

// Modal đổi mật khẩu
function ChangePasswordModal({ user, onClose, onUpdated }) {
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!password || password.length < 12) {
      setError('Mật khẩu mới phải có ít nhất 12 ký tự.');
      return;
    }
    setLoading(true);
    setError('');
    try {
      await API.patch(`/api/admin/users/${user.id}`, { password });
      onUpdated('Đã đổi mật khẩu thành công!');
      onClose();
    } catch (err) {
      setError(err.response?.data?.error || 'Đổi mật khẩu thất bại.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-fadeIn">
      <div className="w-full max-w-md bg-surface-container-low border border-white/10 p-5 rounded-none shadow-2xl">
        <div className="flex items-center justify-between pb-3 mb-4 border-b border-white/10">
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-primary text-[20px]">lock_reset</span>
            <h3 className="font-title-md text-sm font-bold text-on-surface">Đặt Lại Mật Khẩu</h3>
          </div>
          <button
            onClick={onClose}
            className="p-1 text-on-surface-variant hover:text-on-surface rounded-none"
          >
            <span className="material-symbols-outlined text-[18px]">close</span>
          </button>
        </div>

        {error && (
          <div className="p-3 mb-4 bg-error-container/20 border border-error/30 text-error text-xs flex items-center gap-2 rounded-none">
            <span className="material-symbols-outlined text-[16px]">warning</span>
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-medium text-on-surface-variant mb-1">
              Đổi mật khẩu cho: <span className="font-bold text-on-surface">{user.username}</span>
            </label>
            <label className="block text-xs font-medium text-on-surface mb-1 mt-3">
              Mật khẩu mới
            </label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Tối thiểu 12 ký tự..."
              className="w-full bg-surface-container text-on-surface text-xs px-3 py-2 rounded-none border border-white/10 focus:outline-none focus:border-primary"
            />
          </div>

          <div className="flex items-center justify-end gap-2 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="px-3 py-2 text-xs text-on-surface-variant hover:text-on-surface rounded-none border border-white/10"
            >
              Hủy
            </button>
            <button
              type="submit"
              disabled={loading}
              className="px-4 py-2 text-xs font-semibold bg-primary-container hover:bg-inverse-primary text-on-primary-container rounded-none transition-all disabled:opacity-50 flex items-center gap-1.5"
            >
              {loading ? 'Đang cập nhật...' : 'Cập Nhật Mật Khẩu'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

// Tab 3: Quản lý phân quyền & Tạo tài khoản kiểm duyệt viên
function UsersTab() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [newUsername, setNewUsername] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [newRole, setNewRole] = useState('moderator');
  const [creating, setCreating] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const [renamingUser, setRenamingUser] = useState(null);
  const [passUser, setPassUser] = useState(null);

  const fetchUsers = async () => {
    try {
      const res = await API.get('/api/admin/users');
      setUsers(res.data.data || []);
    } catch {
      setError('Không thể tải danh sách tài khoản.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const handleCreateUser = async (e) => {
    e.preventDefault();
    setError('');
    setSuccess('');

    if (!newUsername.trim()) {
      setError('Vui lòng nhập tên đăng nhập.');
      return;
    }
    if (!newPassword || newPassword.length < 12) {
      setError('Mật khẩu phải có ít nhất 12 ký tự.');
      return;
    }

    setCreating(true);
    try {
      const res = await API.post('/api/admin/users', {
        username: newUsername.trim(),
        password: newPassword,
        role: newRole,
      });
      setSuccess(res.data?.message || 'Đã tạo tài khoản thành công!');
      setNewUsername('');
      setNewPassword('');
      setNewRole('moderator');
      fetchUsers();
    } catch (err) {
      setError(err.response?.data?.error || 'Tạo tài khoản thất bại.');
    } finally {
      setCreating(false);
    }
  };

  const handleToggleActive = async (userId, currentActive, username) => {
    if (username?.toLowerCase() === 'admin') {
      alert('Không thể khóa tài khoản Quản trị viên mặc định.');
      return;
    }
    const willLock = currentActive !== false;
    const actionText = willLock ? 'KHÓA' : 'MỞ KHÓA';
    if (!window.confirm(`Bạn có chắc muốn ${actionText} tài khoản "${username}" không?`)) return;

    try {
      await API.patch(`/api/admin/users/${userId}`, { is_active: !willLock });
      setUsers(users.map((u) => (u.id === userId ? { ...u, is_active: !willLock } : u)));
    } catch (err) {
      alert(err.response?.data?.error || 'Không thể thay đổi trạng thái tài khoản.');
    }
  };

  const handleDeleteUser = async (userId, username) => {
    if (username?.toLowerCase() === 'admin') {
      alert('Không thể xóa tài khoản Quản trị viên mặc định.');
      return;
    }
    if (!window.confirm(`Bạn có chắc muốn XÓA VĨNH VIỄN tài khoản "${username}" không? Hành động này không thể hoàn tác.`)) return;

    try {
      await API.delete(`/api/admin/users/${userId}`);
      setUsers(users.filter((u) => u.id !== userId));
    } catch (err) {
      alert(err.response?.data?.error || 'Không thể xóa tài khoản.');
    }
  };

  return (
    <div className="grid grid-cols-1 lg:grid-cols-12 gap-space-lg items-start">
      {/* Cột trái: Form tạo tài khoản kiểm duyệt viên (5 cols) */}
      <div className="lg:col-span-5 bg-surface-container-low p-space-md rounded-none border border-white/5 space-y-4">
        <div>
          <div className="flex items-center gap-2 text-primary mb-1">
            <span className="material-symbols-outlined text-[20px]">person_add</span>
            <h3 className="font-title-md text-sm font-bold text-on-surface">
              Tạo Tài Khoản Phân Quyền
            </h3>
          </div>
          <p className="text-xs text-on-surface-variant">
            Cấp tài khoản kiểm duyệt viên (chỉ có quyền kiểm duyệt tin nhắn lừa đảo để đưa lên kho mẫu)
          </p>
        </div>

        {error && (
          <div className="p-3 bg-error-container/20 border border-error/30 rounded-none text-error text-xs flex items-center gap-2">
            <span className="material-symbols-outlined text-[16px]">warning</span>
            <span>{error}</span>
          </div>
        )}

        {success && (
          <div className="p-3 bg-[#10b981]/20 border border-[#10b981]/30 rounded-none text-emerald-700 text-xs flex items-center gap-2">
            <span className="material-symbols-outlined text-[16px]">check_circle</span>
            <span>{success}</span>
          </div>
        )}

        <form onSubmit={handleCreateUser} className="space-y-3">
          <div>
            <label className="block text-xs font-medium text-on-surface mb-1">
              Tên tài khoản (Username)
            </label>
            <input
              type="text"
              value={newUsername}
              onChange={(e) => setNewUsername(e.target.value)}
              placeholder="ví dụ: mod_thao, kiemduyet_01..."
              className="w-full bg-surface-container text-on-surface text-xs px-3 py-2 rounded-none border border-white/10 focus:outline-none focus:border-primary"
            />
          </div>

          <div>
            <label className="block text-xs font-medium text-on-surface mb-1">
              Mật khẩu khởi tạo
            </label>
            <input
              type="password"
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              placeholder="Tối thiểu 12 ký tự..."
              className="w-full bg-surface-container text-on-surface text-xs px-3 py-2 rounded-none border border-white/10 focus:outline-none focus:border-primary"
            />
          </div>

          <div>
            <label className="block text-xs font-medium text-on-surface mb-1">
              Phân quyền tài khoản
            </label>
            <select
              value={newRole}
              onChange={(e) => setNewRole(e.target.value)}
              className="w-full bg-surface-container text-on-surface text-xs px-3 py-2 rounded-none border border-white/10 focus:outline-none focus:border-primary"
            >
              <option value="moderator">Kiểm duyệt viên (Moderator) - Duyệt tin nhắn lừa đảo</option>
              <option value="admin">Quản trị viên (Admin) - Toàn quyền hệ thống</option>
            </select>
            <p className="text-[11px] text-on-surface-variant mt-1.5 leading-relaxed">
              * Tài khoản Kiểm duyệt viên chỉ có quyền truy cập vào Bàn kiểm duyệt tin nhắn lừa đảo để phê duyệt đưa lên trang mẫu tin. Không thể truy cập Quản trị API Key hay Quản lý phân quyền.
            </p>
          </div>

          <button
            type="submit"
            disabled={creating}
            className="w-full py-2.5 px-3 bg-primary-container hover:bg-inverse-primary text-on-primary-container font-semibold text-xs rounded-none transition-all flex items-center justify-center gap-1.5 shadow-sm mt-2 disabled:opacity-50"
          >
            {creating ? (
              <>
                <span className="w-3.5 h-3.5 rounded-full border-2 border-white/30 border-t-white animate-spin"></span>
                <span>Đang khởi tạo...</span>
              </>
            ) : (
              <>
                <span className="material-symbols-outlined text-[16px]">add_moderator</span>
                <span>Tạo Tài Khoản Ngay</span>
              </>
            )}
          </button>
        </form>
      </div>

      {/* Cột phải: Bảng danh sách tài khoản (7 cols) */}
      <div className="lg:col-span-7 bg-surface-container-low p-space-md rounded-none border border-white/5">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h3 className="font-title-md text-sm font-bold text-on-surface">
              Danh Sách Nhân Sự Phân Quyền ({users.length})
            </h3>
            <p className="text-xs text-on-surface-variant mt-0.5">
              Quản lý tài khoản kiểm duyệt: đổi tên, đổi mật khẩu, khóa/mở khóa hoặc xóa tài khoản
            </p>
          </div>
          <button
            onClick={fetchUsers}
            className="p-1.5 text-on-surface-variant hover:text-primary rounded-none transition-colors"
            title="Làm mới"
          >
            <span className="material-symbols-outlined text-[18px]">refresh</span>
          </button>
        </div>

        {loading ? (
          <div className="p-8 text-center text-xs text-on-surface-variant">Đang tải danh sách tài khoản...</div>
        ) : users.length === 0 ? (
          <div className="p-8 text-center text-xs text-on-surface-variant">Chưa có tài khoản nào khác.</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs text-on-surface">
              <thead>
                <tr className="border-b border-white/10 text-on-surface-variant font-label-badge text-[11px]">
                  <th className="py-2.5 px-3">TÀI KHOẢN</th>
                  <th className="py-2.5 px-3">BẢO MẬT</th>
                  <th className="py-2.5 px-3">VAI TRÒ</th>
                  <th className="py-2.5 px-3">TRẠNG THÁI</th>
                  <th className="py-2.5 px-3 text-right">THAO TÁC</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/5">
                {users.map((u) => {
                  const isMaster = u.username?.toLowerCase() === 'admin';
                  const isAdminRole = u.role === 'admin';
                  const isActive = u.is_active !== false;

                  return (
                    <tr key={u.id} className="hover:bg-surface-container/50 transition-colors">
                      <td className="py-3 px-3">
                        <div className="flex items-center gap-2">
                          <div className="w-7 h-7 rounded-none bg-primary/20 text-primary flex items-center justify-center font-bold text-[11px] uppercase border border-primary/30">
                            {u.username ? u.username[0] : 'U'}
                          </div>
                          <div>
                            <div className="font-semibold text-on-surface flex items-center gap-1.5">
                              <span>{u.username}</span>
                              {isMaster && (
                                <span className="font-label-badge text-[9px] bg-primary-container text-on-primary-container px-1 rounded-none">
                                  GỐC
                                </span>
                              )}
                            </div>
                            <span className="text-[10px] text-on-surface-variant">
                              {u.created_at ? new Date(u.created_at).toLocaleDateString('vi-VN') : 'Mặc định'}
                            </span>
                          </div>
                        </div>
                      </td>

                      {/* Mật khẩu không được trả về hoặc lưu ở dạng có thể đọc. */}
                      <td className="py-3 px-3">
                        <span className="text-xs text-on-surface-variant">Mật khẩu được ẩn</span>
                      </td>

                      <td className="py-3 px-3">
                        <span
                          className={`font-label-badge px-2 py-0.5 rounded-none text-[10px] font-bold ${
                            isAdminRole
                              ? 'bg-primary-container/20 text-primary border border-primary/30'
                              : 'bg-tertiary-container/20 text-tertiary border border-tertiary/30'
                          }`}
                        >
                          {isAdminRole ? 'QUẢN TRỊ VIÊN' : 'KIỂM DUYỆT VIÊN'}
                        </span>
                      </td>

                      <td className="py-3 px-3">
                        <span
                          className={`inline-flex items-center gap-1 font-label-badge px-2 py-0.5 rounded-none text-[10px] font-bold ${
                            isActive
                              ? 'bg-[#10b981]/20 text-emerald-700 border border-[#10b981]/30'
                              : 'bg-error-container/20 text-error border border-error/30'
                          }`}
                        >
                          <span
                            className={`w-1.5 h-1.5 rounded-full ${
                              isActive ? 'bg-[#10b981]' : 'bg-error'
                            }`}
                          ></span>
                          {isActive ? 'Hoạt động' : 'Đã khóa'}
                        </span>
                      </td>

                      <td className="py-3 px-3 text-right">
                        {!isMaster ? (
                          <div className="inline-flex items-center gap-1">
                            {/* Đổi tên */}
                            <button
                              onClick={() => setRenamingUser(u)}
                              className="p-1.5 text-on-surface-variant hover:text-primary transition-colors rounded-none border border-transparent hover:border-white/10"
                              title="Đổi tên tài khoản"
                            >
                              <span className="material-symbols-outlined text-[16px]">edit</span>
                            </button>

                            {/* Đổi mật khẩu */}
                            <button
                              onClick={() => setPassUser(u)}
                              className="p-1.5 text-on-surface-variant hover:text-primary transition-colors rounded-none border border-transparent hover:border-white/10"
                              title="Đổi mật khẩu"
                            >
                              <span className="material-symbols-outlined text-[16px]">key</span>
                            </button>

                            {/* Khóa / Mở khóa */}
                            <button
                              onClick={() => handleToggleActive(u.id, u.is_active, u.username)}
                              className={`p-1.5 transition-colors rounded-none border border-transparent hover:border-white/10 ${
                                isActive
                                  ? 'text-on-surface-variant hover:text-warning'
                                  : 'text-error hover:text-emerald-700'
                              }`}
                              title={isActive ? 'Khóa tài khoản' : 'Mở khóa tài khoản'}
                            >
                              <span className="material-symbols-outlined text-[16px]">
                                {isActive ? 'lock' : 'lock_open'}
                              </span>
                            </button>

                            {/* Xóa tài khoản */}
                            <button
                              onClick={() => handleDeleteUser(u.id, u.username)}
                              className="p-1.5 text-on-surface-variant hover:text-error transition-colors rounded-none border border-transparent hover:border-white/10"
                              title="Xóa tài khoản"
                            >
                              <span className="material-symbols-outlined text-[16px]">delete</span>
                            </button>
                          </div>
                        ) : (
                          <span className="text-[10px] text-on-surface-variant italic">Mặc định</span>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Modals */}
      {renamingUser && (
        <RenameUserModal
          user={renamingUser}
          onClose={() => setRenamingUser(null)}
          onUpdated={() => {
            fetchUsers();
            setSuccess('Đã cập nhật tên tài khoản thành công!');
          }}
        />
      )}

      {passUser && (
        <ChangePasswordModal
          user={passUser}
          onClose={() => setPassUser(null)}
          onUpdated={(msg) => {
            fetchUsers();
            if (msg) setSuccess(msg);
          }}
        />
      )}
    </div>
  );
}

// Main Page
export default function AdminDashboardPage() {
  const [activeTab, setActiveTab] = useState('moderation');
  const { isAdmin, isModerator, logout } = useAuth();
  const navigate = useNavigate();

  return (
    <main className="w-full pt-8 pb-20 bg-surface min-h-screen relative overflow-hidden">
      {/* Ambient Orb */}
      <div className="absolute -top-32 right-10 w-96 h-96 bg-primary/10 rounded-full blur-3xl pointer-events-none"></div>

      <div className="max-w-[1280px] mx-auto px-4 sm:px-6 relative z-10">
        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-space-lg">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <span className="font-label-badge text-xs text-primary bg-primary-container/20 border border-primary/30 px-2 py-0.5 rounded">
                {isAdmin ? 'SOC TIER-2 OPERATIONAL CONSOLE' : 'KIỂM DUYỆT VIÊN (MODERATOR CONSOLE)'}
              </span>
            </div>
            <h1 className="font-headline-sm text-2xl font-bold text-on-surface">
              {isAdmin ? 'Quản Trị Hệ Thống & Kiểm Duyệt An Ninh' : 'Bàn Làm Việc Kiểm Duyệt Viên'}
            </h1>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => {
                logout();
                window.location.href = '/';
              }}
              className="py-1.5 px-3 bg-surface-container hover:bg-error/20 hover:text-error text-on-surface-variant text-xs font-title-md rounded-lg border border-white/5 transition-colors flex items-center gap-1.5"
            >
              <span className="material-symbols-outlined text-[16px]">logout</span>
              <span>Đăng xuất</span>
            </button>
          </div>
        </div>

        {/* Tab Switcher */}
        {isAdmin && (
          <div className="flex items-center gap-2 p-1 bg-surface-container-low border border-white/5 rounded-xl w-fit mb-space-lg">
            <button
              onClick={() => setActiveTab('moderation')}
              className={`px-4 py-2 rounded-lg text-xs font-title-md flex items-center gap-2 transition-all ${
                activeTab === 'moderation'
                  ? 'bg-primary-container text-on-primary-container font-semibold shadow-sm'
                  : 'text-on-surface-variant hover:text-on-surface'
              }`}
            >
              <span className="material-symbols-outlined text-[18px]">verified_user</span>
              <span>Bàn Kiểm Duyệt Tin</span>
            </button>

            <button
              onClick={() => setActiveTab('apikeys')}
              className={`px-4 py-2 rounded-lg text-xs font-title-md flex items-center gap-2 transition-all ${
                activeTab === 'apikeys'
                  ? 'bg-primary-container text-on-primary-container font-semibold shadow-sm'
                  : 'text-on-surface-variant hover:text-on-surface'
              }`}
            >
              <span className="material-symbols-outlined text-[18px]">key</span>
              <span>Quản Lý API Key Gemini</span>
            </button>

            <button
              onClick={() => setActiveTab('users')}
              className={`px-4 py-2 rounded-lg text-xs font-title-md flex items-center gap-2 transition-all ${
                activeTab === 'users'
                  ? 'bg-primary-container text-on-primary-container font-semibold shadow-sm'
                  : 'text-on-surface-variant hover:text-on-surface'
              }`}
            >
              <span className="material-symbols-outlined text-[18px]">manage_accounts</span>
              <span>Quản Lý Phân Quyền</span>
            </button>
          </div>
        )}

        {/* Tab Content */}
        {activeTab === 'moderation' && <TemplatesTab />}
        {isAdmin && activeTab === 'apikeys' && <ApiKeysTab />}
        {isAdmin && activeTab === 'users' && <UsersTab />}
      </div>
    </main>
  );
}
