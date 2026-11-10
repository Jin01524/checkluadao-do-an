import 'package:flutter/material.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE7F0FF), Color(0xFFF6F9FF)],
            ),
            border: Border.all(color: const Color(0xFFCCE0FF)),
            borderRadius: BorderRadius.zero,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.health_and_safety_outlined,
                color: Color(0xFF0037B0),
                size: 30,
              ),
              const SizedBox(height: 12),
              const Text(
                'HƯỚNG DẪN AN TOÀN',
                style: TextStyle(
                  color: Color(0xFF0037B0),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Bạn cần được hỗ trợ?',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nếu bạn nghi ngờ một tin nhắn hoặc đã làm theo yêu cầu, hãy ưu tiên bảo vệ tài khoản và tiền của mình.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Card(
          color: const Color(0xFFFFE8E8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.crisis_alert_outlined, color: Color(0xFFBA1A1A)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Vừa chuyển tiền hoặc lộ tài khoản?',
                        style: TextStyle(
                          color: Color(0xFFBA1A1A),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hãy liên hệ ngân hàng qua số trên ứng dụng, thẻ hoặc website chính thức để yêu cầu khóa và tra soát giao dịch ngay.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'CÁC BƯỚC XỬ LÝ',
          style: TextStyle(
            color: Color(0xFF0037B0),
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        _step(
          Icons.account_balance_outlined,
          '01  Liên hệ ngân hàng trước',
          'Yêu cầu khóa tài khoản hoặc thẻ và tra soát giao dịch nghi vấn. Chuẩn bị mã giao dịch, thời gian và tài khoản nhận.',
        ),
        _step(
          Icons.folder_copy_outlined,
          '02  Giữ lại bằng chứng',
          'Lưu tin nhắn, liên kết, lịch sử cuộc gọi, ảnh chụp và chứng từ. Không xóa hội thoại nghi vấn.',
        ),
        _step(
          Icons.local_police_outlined,
          '03  Trình báo sự việc',
          'Cung cấp bằng chứng cho cơ quan công an tại địa phương và làm theo hướng dẫn chính thức.',
        ),
        _step(
          Icons.lock_reset_outlined,
          '04  Bảo vệ các tài khoản khác',
          'Đổi mật khẩu bằng thiết bị tin cậy, đăng xuất phiên lạ và bật xác thực nhiều lớp.',
        ),
        const SizedBox(height: 18),
        const Text(
          'CẨM NANG PHÒNG TRÁNH',
          style: TextStyle(
            color: Color(0xFF0037B0),
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        const Card(
          child: ExpansionTile(
            leading: Icon(
              Icons.verified_user_outlined,
              color: Color(0xFF0037B0),
            ),
            title: Text('Nhận diện yêu cầu đáng ngờ'),
            childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(
                'Dừng lại khi ai đó yêu cầu OTP, mật khẩu, cài ứng dụng ngoài kho chính thức hoặc chuyển tiền gấp. Tự tìm kênh liên hệ chính thức để xác minh.',
              ),
            ],
          ),
        ),
        const Card(
          child: ExpansionTile(
            leading: Icon(Icons.sms_failed_outlined, color: Color(0xFF0037B0)),
            title: Text('Tin nhắn mạo danh'),
            childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(
                'Tên người gửi và giao diện quen thuộc vẫn có thể bị giả mạo. Kiểm tra địa chỉ trang web, ứng dụng và yêu cầu chuyển tiền qua kênh riêng của tổ chức.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _step(IconData icon, String title, String body) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(icon, color: const Color(0xFF0037B0)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
