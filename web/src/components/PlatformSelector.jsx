import { useState } from 'react';

const PLATFORMS = [
  { id: 'sms', label: 'SMS / Brand', icon: 'sms', iconColor: 'text-primary' },
  { id: 'facebook', label: 'Facebook', icon: 'public', iconColor: 'text-[#1877F2]' },
  { id: 'telegram', label: 'Telegram', icon: 'send', iconColor: 'text-[#229ED9]' },
  { id: 'zalo', label: 'Zalo', icon: 'forum', iconColor: 'text-[#0068FF]' },
  { id: 'other', label: 'Khác', icon: 'devices_other', iconColor: 'text-secondary' },
];

export default function PlatformSelector({ value, onChange }) {
  const [customName, setCustomName] = useState('');

  const isOtherSelected = value === 'other' || (
    value && !PLATFORMS.slice(0, 4).find(p => p.id === value)
  );

  const handleSelect = (id) => {
    if (id === 'other') {
      onChange(customName || 'other');
    } else {
      onChange(id);
    }
  };

  const handleCustomChange = (e) => {
    const val = e.target.value;
    setCustomName(val);
    onChange(val || 'other');
  };

  const selectedId = PLATFORMS.find(p => p.id === value)?.id || (isOtherSelected ? 'other' : '');

  return (
    <div className="flex flex-col gap-space-xs">
      <div className="flex items-center justify-between">
        <label className="font-title-md text-title-md text-on-surface font-medium">
          Nền tảng bạn nhận tin nhắn này:
        </label>
        {selectedId && (
          <span className="font-label-badge text-[11px] text-primary bg-primary-container/20 px-2 py-0.5 rounded-none border border-primary/30 uppercase">
            Đã chọn: {selectedId.toUpperCase()}
          </span>
        )}
      </div>

      <div className="grid grid-cols-2 sm:grid-cols-5 gap-space-xs" id="platform-selector">
        {PLATFORMS.map((platform) => {
          const isSelected = selectedId === platform.id;
          return (
            <div
              key={platform.id}
              onClick={() => handleSelect(platform.id)}
              className={`cursor-pointer relative flex flex-col items-center gap-space-2xs p-space-xs rounded-none transition-all border ${
                isSelected
                  ? 'bg-surface-container-high border-primary shadow-[0_0_12px_rgba(180,197,255,0.2)] ring-1 ring-primary'
                  : 'bg-surface-container border-white/5 hover:bg-surface-container-high hover:border-white/10'
              }`}
            >
              {/* Radio Indicator */}
              <div className="w-full flex justify-end">
                <span
                  className={`w-3.5 h-3.5 rounded-full flex items-center justify-center transition-colors ${
                    isSelected ? 'bg-primary' : 'bg-surface-container-lowest border border-white/20'
                  }`}
                >
                  {isSelected && <span className="w-1.5 h-1.5 rounded-full bg-on-primary"></span>}
                </span>
              </div>

              {/* Icon */}
              <span className={`material-symbols-outlined text-[26px] ${platform.iconColor}`}>
                {platform.icon}
              </span>

              {/* Label */}
              <span className="font-label-caption text-label-caption text-on-surface font-medium">
                {platform.label}
              </span>
            </div>
          );
        })}
      </div>

      {/* Input if 'other' is selected */}
      {selectedId === 'other' && (
        <div className="mt-space-2xs animate-fadeIn">
          <input
            type="text"
            className="w-full bg-surface-container text-on-surface text-body-sm px-space-sm py-space-xs rounded-none border border-white/10 focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary placeholder-on-surface-variant/50"
            placeholder="Nhập tên nền tảng (Ví dụ: Viber, WhatsApp, Gmail, TikTok...)"
            value={customName}
            onChange={handleCustomChange}
            autoFocus
          />
        </div>
      )}
    </div>
  );
}
