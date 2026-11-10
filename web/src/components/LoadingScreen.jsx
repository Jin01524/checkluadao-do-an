import { useEffect, useState } from 'react';

export default function LoadingScreen() {
  const [progress, setProgress] = useState(5);

  useEffect(() => {
    // Simulate progress over ~30 seconds
    const intervals = [
      { delay: 500, value: 15 },
      { delay: 2000, value: 30 },
      { delay: 5000, value: 48 },
      { delay: 9000, value: 62 },
      { delay: 14000, value: 74 },
      { delay: 20000, value: 85 },
      { delay: 26000, value: 93 },
    ];

    const timers = intervals.map(({ delay, value }) =>
      setTimeout(() => setProgress(value), delay)
    );

    return () => timers.forEach(clearTimeout);
  }, []);

  return (
    <div className="loading-screen">
      <div className="loading-logo">🛡️</div>
      <h1 className="loading-title">Hệ thống đang khởi động...</h1>
      <p className="loading-subtitle">
        Vui lòng đợi trong giây lát, điều này chỉ mất 20–30 giây lần đầu truy cập
      </p>

      <div className="loading-progress-bar">
        <div
          className="loading-progress-fill"
          style={{ width: `${progress}%` }}
        />
      </div>
      <span className="loading-percent">{progress}%</span>
    </div>
  );
}
