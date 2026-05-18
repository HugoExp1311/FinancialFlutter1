# 🎯 CI/CD Pipeline - Quick Reference

## 📁 Workflows Overview

Dự án có **4 workflows** tự động hóa:

| Workflow | File | Trigger | Mục đích |
|----------|------|---------|----------|
| **Main Pipeline** | `main.yml` | Push/PR to main/develop | Build, test toàn bộ hệ thống |
| **Dependency Check** | `dependency-check.yml` | Weekly (Monday 2AM) | Kiểm tra dependencies lỗi thời & bảo mật |
| **Release Management** | `release.yml` | Push to main | Tự động tạo release + tag + changelog |
| **Manual Trigger** | All workflows | Manual via Actions tab | Chạy thủ công khi cần |

---

## 🚀 Quick Start

### 1. Cấu hình Secrets (Bắt buộc)

Vào **Settings** → **Secrets and variables** → **Actions**, thêm:

```
SUPABASE_URL=https://baypebptjfrnclsgtddd.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 2. Push Code

```bash
git add .
git commit -m "feat: add new feature"
git push origin develop  # Test build only
git push origin main     # Full deploy
```

### 3. Xem Kết Quả

- **Actions Tab**: Xem workflow đang chạy
- **Releases**: Download APK/Web build
- **Security**: Xem vulnerability scan

---

## 📊 Pipeline Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    PUSH CODE TO GITHUB                       │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
┌───────────────┐         ┌───────────────┐
│ Analyze Code  │         │ Test Services │
│ (Flutter)     │         │ (Dart)        │
└───────┬───────┘         └───────┬───────┘
        │                         │
        └────────────┬────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
┌───────────────┐         ┌───────────────┐
│  Build Web    │         │ Build Android │
│  (CanvasKit)  │         │  (APK)        │
└───────┬───────┘         └───────┬───────┘
        │                         │
        └────────────┬────────────┘
                     │
                     ▼
            ┌────────────────┐
            │ Build Docker   │
            │ Images         │
            └────────┬───────┘
                     │
                     ▼
            ┌────────────────┐
            │ Integration    │
            │ Test           │
            └────────┬───────┘
                     │
                     ▼
            ┌────────────────┐
            │ ✅ Complete    │
            │ Download APK   │
            │ from Artifacts │
            └────────────────┘
```

---

## 🎯 Common Tasks

### ✅ Chạy Full Pipeline
```bash
git push origin main
```

### ✅ Test Build (Không Deploy)
```bash
git push origin develop
```

### ✅ Tạo Release Thủ Công
1. Vào **Actions** tab
2. Chọn **Release Management**
3. Click **Run workflow**
4. Nhập version (e.g., `1.2.0`)
5. Click **Run**

### ✅ Kiểm Tra Dependencies
1. Vào **Actions** tab
2. Chọn **Dependency Check & Update**
3. Click **Run workflow**

### ✅ Download APK
1. Vào **Actions** tab
2. Chọn workflow run thành công
3. Scroll xuống **Artifacts**
4. Download `android-apk`

---

## 🐛 Troubleshooting

### ❌ "Secrets not found"
→ Kiểm tra lại tên secrets (phân biệt hoa thường)
→ Đảm bảo đã add vào **Repository secrets**, không phải Environment secrets

### ❌ "Flutter analyze failed"
→ Chạy `flutter analyze` trên local
→ Sửa warnings/errors trước khi push

### ❌ "Docker build failed"
→ Test build local: `docker build -f microservices/transaction_service/Dockerfile .`
→ Kiểm tra Dockerfile syntax

### ❌ "Deploy failed - SSH timeout"
→ Kiểm tra SSH_PRIVATE_KEY đã paste đúng format
→ Test SSH thủ công: `ssh -i ~/.ssh/key user@server`

### ❌ "Integration test failed"
→ Kiểm tra SUPABASE_URL và SUPABASE_ANON_KEY
→ Xem logs: Click vào failed job → Xem chi tiết

---

## 📈 Monitoring

### Build Status Badge
Thêm vào README.md:
```markdown
![CI/CD](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/main.yml/badge.svg)
```

### Xem Logs
1. **Actions** tab → Click vào workflow run
2. Click vào job bị lỗi
3. Expand step để xem chi tiết

### Security Alerts
1. **Security** tab → **Dependabot alerts**
2. Xem vulnerabilities được scan tự động

---

## 🔧 Customization

### Thay đổi Flutter Version
Edit `main.yml`:
```yaml
env:
  FLUTTER_VERSION: '3.24.0'  # Đổi version ở đây
```

### Tắt Auto-Deploy
Xóa hoặc comment job `deploy-production` trong `main.yml`

### Thay đổi Schedule
Edit `dependency-check.yml`:
```yaml
on:
  schedule:
    - cron: '0 2 * * 1'  # Đổi schedule ở đây
```

---

## 📚 Resources

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Flutter CI/CD Guide](https://docs.flutter.dev/deployment/cd)
- [Docker Compose CI](https://docs.docker.com/compose/ci/)
- [Cron Expression Generator](https://crontab.guru/)

---

## ✅ Checklist Before First Run

- [ ] Đã add 2 Secrets vào GitHub (SUPABASE_URL, SUPABASE_ANON_KEY)
- [ ] Đã test `flutter analyze` trên local (không có lỗi)
- [ ] Đã test `docker-compose up` trên local (chạy được)
- [ ] Đã đọc file `README.md` trong thư mục `.github/workflows`

---

**🎉 Sau khi hoàn thành checklist, push code lên và xem pipeline chạy!**

**📦 Kết quả:** APK và Web build sẽ có trong tab **Artifacts** sau khi workflow hoàn tất.
