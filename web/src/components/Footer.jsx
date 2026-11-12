export default function Footer() {
  return (
    <footer className="w-full bg-surface-container-lowest py-space-2xl border-t border-white/5 mt-auto">
      <div className="max-w-[1280px] mx-auto px-4 sm:px-6">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-space-xl mb-space-2xl">
          {/* Col 1: Brand & Initiative */}
          <div>
            <div className="flex items-center gap-space-xs mb-space-md">
              <div className="relative flex items-center justify-center w-8 h-8 rounded-xl bg-primary-container/20 border border-primary/30">
                <span className="material-symbols-outlined text-primary text-[20px]">shield</span>
              </div>
              <span className="font-headline-sm text-headline-sm text-on-surface font-bold">
                Check<span className="text-primary">LuaDao</span>
              </span>
            </div>
            <p className="font-body-sm text-body-sm text-on-surface-variant">
              Hệ sinh thái AI bảo vệ công dân Việt Nam trước các chiến dịch lừa đảo tài chính, mạo danh cơ quan tư pháp và mã độc trực tuyến.
            </p>
          </div>

          {/* Col 2: Cooperation & Academic */}
          <div>
            <div className="font-title-md text-title-md text-on-surface mb-space-md uppercase tracking-wider">
              Đơn vị phát triển & Hợp tác
            </div>
            <ul className="space-y-space-xs font-body-sm text-body-sm text-on-surface-variant">
              <li className="flex items-center gap-space-2xs hover:text-on-surface transition-colors cursor-pointer">
                <span className="material-symbols-outlined text-[16px] text-primary">school</span>
                <span>Đại học Kiến trúc Đà Nẵng</span>
              </li>
              <li className="flex items-center gap-space-2xs hover:text-on-surface transition-colors cursor-pointer">
                <span className="material-symbols-outlined text-[16px] text-primary">person</span>
                <span>Tác giả: Võ Ngọc Bình, Trần Mỹ Nhung</span>
              </li>
            </ul>
          </div>

          {/* Col 3: Privacy & Security */}
          <div>
            <div className="font-title-md text-title-md text-on-surface mb-space-md uppercase tracking-wider">
              Bảo mật & Quyền riêng tư
            </div>
            <p className="font-body-sm text-body-sm text-on-surface-variant mb-space-sm">
              Mọi nội dung tin nhắn và tệp phân tích đều được khử định danh (De-identification) bằng thuật toán mã hóa SHA-256 trước khi xử lý qua mô hình học sâu.
            </p>
            <div className="flex gap-space-sm font-label-caption text-label-caption text-secondary">
              <span className="hover:text-on-surface cursor-pointer transition-colors">Chính sách dữ liệu</span>
              <span>•</span>
              <span className="hover:text-on-surface cursor-pointer transition-colors">Điều khoản bảo vệ người dùng</span>
            </div>
          </div>
        </div>

        {/* Bottom bar */}
        <div className="pt-space-lg border-t border-white/5 font-body-sm text-body-sm text-on-surface-variant text-center md:text-left">
          © {new Date().getFullYear()} CheckLuaDao Platform. Sáng kiến bảo vệ an toàn cộng đồng số Việt Nam.
        </div>
      </div>
    </footer>
  );
}
