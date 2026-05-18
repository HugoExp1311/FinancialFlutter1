# 🚀 Hướng Dẫn Chạy GitHub Actions (Trên Web)

## 📋 Tổng Quan

Sau khi đã tạo các file workflow (`.github/workflows/*.yml`), bạn có thể chạy chúng theo 2 cách:
1. **Tự động** - Khi push code lên GitHub
2. **Thủ công** - Chạy trực tiếp trên GitHub Actions tab

---

## 🎯 Phương Pháp 1: Tự Động (Recommended)

### Bước 1: Push Code Lên GitHub

```bash
# Cách 1: Dùng script có sẵn
.\git_push.bat

# Cách 2: Thủ công
git add .
git commit -m "ci: add GitHub Actions workflows"
git push origin main
```

### Bước 2: Xem Workflow Chạy

1. Mở trình duyệt, vào repository GitHub của bạn
2. Click vào tab **Actions** (ở menu trên cùng)
3. Bạn sẽ thấy workflow đang chạy với tên commit vừa push

![Actions Tab](https://docs.github.com/assets/cb-73000/mw-1440/images/help/repository/actions-tab.webp)

### Bước 3: Xem Chi Tiết

1. Click vào workflow run (dòng có tên commit)
2. Xem từng job đang chạy (màu vàng = đang chạy, xanh = thành công, đỏ = lỗi)
3. Click vào job để xem logs chi tiết

---

## 🎯 Phương Pháp 2: Chạy Thủ Công (Manual Trigger)

### Bước 1: Cấu Hình Secrets (Chỉ làm 1 lần)

1. Vào repository GitHub
2. Click **Settings** (tab trên cùng)
3. Sidebar bên trái → **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Thêm 2 secrets:

**Secret 1:**
```
Name: SUPABASE_URL
Value: https://baypebptjfrnclsgtddd.supabase.co
```

**Secret 2:**
```
Name: SUPABASE_ANON_KEY
Value: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJheXBlYnB0amZybmNsc2d0ZGRkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxNjY0NjMsImV4cCI6MjA4Nzc0MjQ2M30.U8zveBOWHHWDfY1J_P9ezRPqifoXGR9kFmjE25BuKD4
```

![Add Secret](https://docs.github.com/assets/cb-28517/mw-1440/images/help/settings/actions-secrets-new.webp)

---

### Bước 2: Chạy Main Pipeline

1. Vào tab **Actions**
2. Sidebar bên trái → Click **Finance AI - CI/CD Pipeline**
3. Bên phải → Click nút **Run workflow** (dropdown)
4. Chọn branch (thường là `main`)
5. Click nút **Run workflow** (xanh lá)

![Run Workflow](https://docs.github.com/assets/cb-29297/mw-1440/images/help/actions/workflow-dispatch-button.webp)

**Workflow này sẽ:**
- ✅ Analyze Flutter code
- ✅ Build Web (CanvasKit)
- ✅ Build Android APK
- ✅ Test microservices
- ✅ Build Docker images
- ✅ Integration test

**Thời gian:** ~10-15 phút

---

### Bước 3: Chạy Dependency Check

1. Vào tab **Actions**
2. Sidebar → Click **Dependency Check & Update**
3. Click **Run workflow** → Chọn branch → **Run workflow**

**Workflow này sẽ:**
- ✅ Kiểm tra outdated packages
- ✅ Security vulnerability scan
- ✅ Docker image scan

**Thời gian:** ~5 phút

---

### Bước 4: Chạy Release Management

1. Vào tab **Actions**
2. Sidebar → Click **Release Management**
3. Click **Run workflow**
4. **Nhập version** (ví dụ: `1.0.0`) hoặc để trống để auto-increment
5. Click **Run workflow**

**Workflow này sẽ:**
- ✅ Tạo Git tag mới
- ✅ Build APK + Web archive
- ✅ Generate changelog
- ✅ Tạo GitHub Release

**Thời gian:** ~12 phút

---

## 📦 Bước 5: Download Artifacts

Sau khi workflow chạy xong:

1. Click vào workflow run (màu xanh = thành công)
2. Scroll xuống phần **Artifacts**
3. Download:
   - `android-apk` - Chứa 3 file APK (arm-v7a, arm64-v8a, x86_64)
   - `web-build` - Chứa toàn bộ Flutter Web build

![Artifacts](https://docs.github.com/assets/cb-61981/mw-1440/images/help/repository/artifact-drop-down-updated.webp)

---

## 🔍 Xem Logs Chi Tiết

### Khi workflow bị lỗi (màu đỏ):

1. Click vào workflow run bị lỗi
2. Click vào job bị lỗi (có icon ❌)
3. Click vào step bị lỗi để xem logs
4. Copy error message để debug

**Ví dụ lỗi thường gặp:**

```
Error: Secrets not found
→ Kiểm tra lại đã add SUPABASE_URL và SUPABASE_ANON_KEY chưa
```

```
Error: Flutter analyze failed
→ Chạy flutter analyze trên local để xem lỗi cụ thể
```

```
Error: Docker build failed
→ Kiểm tra Dockerfile syntax
```

---

## 📊 Dashboard Overview

Sau khi chạy vài lần, bạn sẽ thấy dashboard như này:

```
┌─────────────────────────────────────────────────────────┐
│  Actions                                                 │
├─────────────────────────────────────────────────────────┤
│  ✅ Finance AI - CI/CD Pipeline      #12  main  10m ago │
│  ✅ Dependency Check & Update        #5   main  2h ago  │
│  ✅ Release Management               #3   main  1d ago  │
│  ❌ Finance AI - CI/CD Pipeline      #11  main  2d ago  │
└─────────────────────────────────────────────────────────┘
```

---

## 🎯 Workflow Triggers (Khi nào tự động chạy)

| Workflow | Trigger | Điều kiện |
|----------|---------|-----------|
| **Main Pipeline** | Push/PR | Khi push vào `main` hoặc `develop` |
| **Dependency Check** | Schedule | Mỗi thứ 2 lúc 2h sáng (UTC) |
| **Release Management** | Push | Khi push vào `main` (không ignore docs) |

---

## ✅ Checklist Trước Khi Chạy Lần Đầu

- [ ] Đã push file `.github/workflows/*.yml` lên GitHub
- [ ] Đã add 2 secrets (SUPABASE_URL, SUPABASE_ANON_KEY)
- [ ] Đã test `flutter analyze` trên local (không có lỗi)
- [ ] Đã test `docker-compose up` trên local (chạy được)

---

## 🆘 Troubleshooting

### ❌ "Workflow not found"
→ Đảm bảo file `.yml` nằm đúng trong thư mục `.github/workflows/`

### ❌ "Secrets not found"
→ Kiểm tra tên secrets (phân biệt hoa thường)
→ Đảm bảo add vào **Repository secrets**, không phải Environment secrets

### ❌ "Permission denied"
→ Vào Settings → Actions → General
→ Chọn "Read and write permissions"

### ❌ Workflow không tự động chạy khi push
→ Kiểm tra branch name (phải là `main` hoặc `develop`)
→ Kiểm tra file path không nằm trong `paths-ignore`

---

## 📚 Tài Liệu Tham Khảo

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Secrets Management](https://docs.github.com/en/actions/security-guides/encrypted-secrets)

---

## 🎉 Kết Luận

Sau khi setup xong, workflow sẽ tự động chạy mỗi khi bạn push code. Bạn chỉ cần:

1. **Viết code** → Test local
2. **Push code** → `.\git_push.bat`
3. **Xem Actions tab** → Đợi build xong
4. **Download APK** → Deploy hoặc test

**Đơn giản vậy thôi!** 🚀
