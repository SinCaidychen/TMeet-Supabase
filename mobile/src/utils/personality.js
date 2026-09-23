// TODO (오승화): thay hàm này bằng lệnh gọi OpenAI API thật để phân tích tính cách
// du lịch từ tag + motto, như mô tả trong đơn đăng ký đề tài. Hiện tại chỉ ghép
// chuỗi đơn giản để luồng onboarding -> lưu DB -> hiển thị chạy được hết end-to-end.
export function summarizePersonality(tags, motto) {
  const tagText = tags.length ? tags.join(", ") : "chưa chọn phong cách";
  return {
    summary: `Thích: ${tagText}. Motto: "${motto || "—"}"`,
    isPlaceholder: true,
  };
}
