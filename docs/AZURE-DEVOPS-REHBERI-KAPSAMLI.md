# 📚 Azure DevOps Branch Stratejisi - Kapsamlı Rehber

> Bu doküman, Azure DevOps üzerinde branch yönetimi, PR akışları, CI/CD pipeline, Work Item bağlama, Tag ekleme ve onaylayıcı süreçlerini tek bir kaynakta toplar.

---

## 📑 İçindekiler

1. [Branch Yapısı ve Hiyerarşisi](#1-branch-yapısı-ve-hiyerarşisi)
2. [Branch Türleri ve Kuralları](#2-branch-türleri-ve-kuralları)
3. [PR (Pull Request) Kuralları](#3-pr-pull-request-kuralları)
4. [Geliştirme Senaryoları](#4-geliştirme-senaryoları)
5. [Build ve Pipeline Kuralları](#5-build-ve-pipeline-kuralları)
6. [Back-Merge Akışları](#6-back-merge-akışları)
7. [Work Item Yönetimi](#7-work-item-yönetimi)
8. [Tag ve Versiyonlama](#8-tag-ve-versiyonlama)
9. [Branch Policy Ayarları](#9-branch-policy-ayarları)
10. [Hata Senaryoları ve Çözümleri](#10-hata-senaryoları-ve-çözümleri)
11. [Hızlı Referans](#11-hızlı-referans)

---

## 1. Branch Yapısı ve Hiyerarşisi

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                           BRANCH HİYERARŞİSİ                               ║
╚═══════════════════════════════════════════════════════════════════════════╝

                              ┌─────────────────────────────────────┐
                              │              MAIN                   │
                              │         (Production/Canlı)          │
                              │    🔒 Korumalı - Direkt push yok    │
                              │                                     │
                              │  ← release (normal akış)            │
                              │  ← hotfix/* (acil düzeltme)         │
                              └──────────────────┬──────────────────┘
                                                 │
                         ┌───────────────────────┼───────────────────────┐
                         │                       │                       │
                         ▼                       │                       ▼
              ┌─────────────────────┐            │            ┌─────────────────────┐
              │      RELEASE        │            │            │     hotfix/*        │
              │  (Pre-Production)   │◄───────────┘            │  (Acil Düzeltme)    │
              │ 🔒 Korumalı branch  │                         │                     │
              │                     │                         │  📌 main'den açılır │
              │  ← sandbox          │                         │  📌 main'e PR açılır│
              │  ← bugfix/*         │                         └─────────────────────┘
              └─────────┬───────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
        ▼               │               ▼
┌──────────────┐        │        ┌──────────────┐
│   SANDBOX    │        │        │   bugfix/*   │
│ (Development)│◄───────┘        │(Release Fix) │
│🔒 Korumalı   │                 │              │
│              │                 │ 📌 release'den│
│  ← feature/* │                 │    açılır    │
└──────┬───────┘                 │ 📌 release'e │
       │                         │    PR açılır │
       ▼                         └──────────────┘
┌──────────────┐
│  feature/*   │
│(Yeni Özellik)│
│              │
│ 📌 sandbox'dan│
│    açılır    │
│ 📌 sandbox'a │
│    PR açılır │
└──────────────┘
```
<img width="800" height="339" alt="image" src="https://github.com/user-attachments/assets/31f1f270-6cf4-4a7a-9bc4-57df7cb87e67" />

---

## 2. Branch Türleri ve Kuralları

| Branch | Ortam | Nereden Açılır | Nereye PR | Build | Onaylayıcı | Ömrü |
|--------|-------|----------------|-----------|-------|------------|------|
| `main` | Production | - | - | ✅ | 2 kişi | Kalıcı |
| `release` | Pre-Prod | - | `main` | ✅ | 2 kişi | Kalıcı |
| `sandbox` | Development | - | `release` | ✅ | 1 kişi | Kalıcı |
| `feature/*` | - | `sandbox` | `sandbox` | ❌ | 1 kişi | Geçici |
| `bugfix/*` | - | `release` | `release` | ✅ | 1 kişi | Geçici |
| `hotfix/*` | - | `main` | `main` | ✅ | 1 kişi | Geçici |

### Branch İsimlendirme Standardı

| Tip | Format | Örnek |
|-----|--------|-------|
| Feature | `feature/<workitem-id>-kisa-aciklama` | `feature/1234-satis-raporu` |
| Bugfix | `bugfix/<workitem-id>-hata-aciklamasi` | `bugfix/5678-tarih-formati` |
| Hotfix | `hotfix/<workitem-id>-kritik-duzeltme` | `hotfix/9999-fatura-hatasi` |

---

## 3. PR (Pull Request) Kuralları

### İzin Verilen PR Akışları

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                              PR KURALLARI                                  ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║  SANDBOX'A PR:                                                            ║
║  ┌─────────────────────────────────────────────────────────────────────┐  ║
║  │  ✅ feature/*     → sandbox                                         │  ║
║  │  ❌ release, main, bugfix/*, hotfix/* → YASAK                       │  ║
║  └─────────────────────────────────────────────────────────────────────┘  ║
║                                                                           ║
║  RELEASE'E PR:                                                            ║
║  ┌─────────────────────────────────────────────────────────────────────┐  ║
║  │  ✅ sandbox       → release (normal akış)                           │  ║
║  │  ✅ bugfix/*      → release (düzeltme)                              │  ║
║  │  ❌ feature/*, main, hotfix/* → YASAK                               │  ║
║  └─────────────────────────────────────────────────────────────────────┘  ║
║                                                                           ║
║  MAIN'E PR:                                                               ║
║  ┌─────────────────────────────────────────────────────────────────────┐  ║
║  │  ✅ release       → main (normal release)                           │  ║
║  │  ✅ hotfix/*      → main (acil düzeltme)                            │  ║
║  │  ❌ feature/*, bugfix/*, sandbox → YASAK                            │  ║
║  └─────────────────────────────────────────────────────────────────────┘  ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

### Yasak PR Örnekleri ve Doğru Akışlar

| Kaynak | Hedef | Sonuç | Doğru Akış |
|--------|-------|-------|------------|
| `feature/*` | `release` | ❌ YASAK | `feature/* → sandbox → release` |
| `feature/*` | `main` | ❌ YASAK | `feature/* → sandbox → release → main` |
| `sandbox` | `main` | ❌ YASAK | `sandbox → release → main` |
| `bugfix/*` | `main` | ❌ YASAK | `bugfix/* → release → main` |

### Azure DevOps'ta PR Açma

```
1. Azure DevOps → Repos → Pull Requests
2. "New pull request" butonuna tıklayın
3. Source ve Target branch seçin
4. PR bilgilerini doldurun:
   - Title: [FEATURE] #1234 - Açıklama
   - Description: Değişiklikler, test senaryoları
   - Reviewers: Gerekli kişileri ekleyin
   - Work Items: İlgili work item'ları bağlayın
5. "Create" butonuna tıklayın
```

---

## 4. Geliştirme Senaryoları

### 📘 Senaryo 1: Yeni Özellik (Feature)

```bash
# 1. Sandbox'tan feature branch oluştur
git checkout sandbox
git pull origin sandbox
git checkout -b feature/1234-satis-raporu

# 2. Geliştirme yap
# ... kod değişiklikleri ...

# 3. Commit ve push
git add .
git commit -m "[FEATURE] #1234 - Satış raporu eklendi"
git push origin feature/1234-satis-raporu

# 4. Azure DevOps'ta sandbox'a PR aç
# 5. Merge sonrası BUILD YAPILMAZ
```

### 📗 Senaryo 2: Sandbox → Release

```bash
# Azure DevOps'ta PR aç:
# Source: sandbox → Target: release

# Merge sonrası:
# ✅ BUILD yapılır
# ✅ Back-merge: release → sandbox
```

### 📕 Senaryo 3: Release → Main (Production)

```bash
# Azure DevOps'ta PR aç:
# Source: release → Target: main

# Merge sonrası:
# ✅ BUILD yapılır
# ✅ Back-merge: main → release → sandbox
```

### 📙 Senaryo 4: Hotfix (Acil Canlı Düzeltme)

⚠️ **ÖNEMLİ:** Hotfix **MUTLAKA** `main`'den açılır!

```bash
# 1. MAIN'den hotfix branch oluştur
git checkout main
git pull origin main
git checkout -b hotfix/9999-kritik-fatura-hatasi

# 2. Düzeltme yap
# ... minimum değişiklik ...

# 3. Commit ve push
git add .
git commit -m "[HOTFIX] #9999 - Kritik fatura hatası düzeltildi"
git push origin hotfix/9999-kritik-fatura-hatasi

# 4. MAIN'e PR aç
# 5. Merge sonrası:
#    ✅ BUILD yapılır
#    ✅ Back-merge: main → release → sandbox
```

### 📒 Senaryo 5: Bugfix (Release Düzeltme)

⚠️ **ÖNEMLİ:** Bugfix **MUTLAKA** `release`'den açılır!

```bash
# 1. RELEASE'den bugfix branch oluştur
git checkout release
git pull origin release
git checkout -b bugfix/5678-tarih-formati-hatasi

# 2. Düzeltme yap
git add .
git commit -m "[BUGFIX] #5678 - Tarih formatı düzeltildi"
git push origin bugfix/5678-tarih-formati-hatasi

# 3. RELEASE'e PR aç
# 4. Merge sonrası:
#    ✅ BUILD yapılır
#    ✅ Back-merge: release → sandbox
```

---

## 5. Build ve Pipeline Kuralları

### Build Matrisi

| Merge İşlemi | Build | Back-Merge |
|--------------|-------|------------|
| `feature/* → sandbox` PR | ❌ Sadece Validation | - |
| `feature/* → sandbox` merge | ❌ Build yok | - |
| `sandbox → release` merge | ✅ Build | `→ sandbox` |
| `bugfix/* → release` merge | ✅ Build | `→ sandbox` |
| `release → main` merge | ✅ Build | `→ release → sandbox` |
| `hotfix/* → main` merge | ✅ Build | `→ release → sandbox` |

### Pipeline Aşamaları

| Stage | Koşul | İş |
|-------|-------|-----|
| 🔍 Validate | Sadece PR'larda | Branch kurallarını kontrol eder |
| 🔨 Build (Release) | `release` push | Kodu derler, artifact oluşturur |
| 🔨 Build (Main) | `main` push | Kodu derler, artifact oluşturur |
| 🔄 Back-Merge | Build sonrası | Alt branch'leri senkronize eder |

---

## 6. Back-Merge Akışları

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                           BACK-MERGE AKIŞLARI                              ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║  BUGFIX MERGE SONRASI:                                                    ║
║  bugfix/* → release (merge) → BUILD ✅ → release → sandbox (back-merge)   ║
║                                                                           ║
║  HOTFIX MERGE SONRASI:                                                    ║
║  hotfix/* → main (merge) → BUILD ✅ → main → release → sandbox            ║
║                                                                           ║
║  NORMAL RELEASE SONRASI:                                                  ║
║  release → main (merge) → BUILD ✅ → main → release → sandbox             ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

---

## 7. Work Item Yönetimi

### Work Item Türleri
- **Epic**: Büyük ölçekli iş birimi
- **Feature**: Özellik geliştirme
- **User Story**: Kullanıcı hikayesi
- **Bug**: Hata bildirimi
- **Task**: Alt görev

### Commit Mesajında Work Item Bağlama

```bash
# Tek work item
git commit -m "[FEATURE] #1234 - Satış raporu eklendi"

# Birden fazla work item
git commit -m "[FEATURE] #1234 #1235 - Raporlar güncellendi"

# Otomatik kapatma
git commit -m "[BUGFIX] #5678 - Tarih formatı düzeltildi (Fixes #5678)"
```

### PR'da Work Item Bağlama

1. PR açarken "Link work items" bölümüne tıklayın
2. Work item ID'sini girin veya arama yapın
3. Work item seçin ve bağlayın

---

## 8. Tag ve Versiyonlama

### Semantic Versioning (SemVer)

```
v MAJOR . MINOR . PATCH
    │       │       │
    │       │       └── Bug fixes, küçük düzeltmeler
    │       │
    │       └── Yeni özellikler (geriye uyumlu)
    │
    └── Breaking changes (geriye uyumsuz değişiklikler)

Örnekler:
  v1.0.0 → v1.0.1  : Bug fix
  v1.0.0 → v1.1.0  : Yeni özellik eklendi
  v1.0.0 → v2.0.0  : Breaking change
```

### Terminal ile Tag Ekleme

```bash
# Tag eklenecek branch'e geçin
git checkout main
git pull origin main

# Annotated Tag oluşturma (önerilen)
git tag -a v1.0.0 -m "Version 1.0.0 - İlk release"

# Tag'i push edin
git push origin v1.0.0

# Tüm tag'leri push
git push origin --tags

# Tag'leri listele
git tag -l "v1.*"

# Tag sil (lokal + remote)
git tag -d v1.0.0
git push origin --delete v1.0.0
```

### Azure DevOps'ta Tag Ekleme

```
1. Repos → Tags → "New tag"
2. Name: v1.0.0
3. Based on: main
4. Description: Sürüm notları
5. "Create" butonuna tıklayın
```

---

## 9. Branch Policy Ayarları

### Önerilen Branch Policy Tablosu

| Policy | main | release | sandbox |
|--------|------|---------|---------|
| Min Reviewer | 2 | 2 | 1 |
| Build Validation | ✅ Required | ✅ Required | ✅ Required |
| Work Item Link | ✅ Required | ✅ Required | ☐ Optional |
| Comment Resolution | ✅ Required | ✅ Required | ✅ Required |
| Direct Push | ❌ Kapalı | ❌ Kapalı | ❌ Kapalı |
| Force Push | ❌ YASAK | ❌ YASAK | ❌ YASAK |

### Azure DevOps'ta Policy Konfigürasyonu

```
1. Project Settings → Repos → Repositories
2. İlgili repo → Policies → Branch Policies
3. Branch seçin (main, release, sandbox)
4. Politikaları ayarlayın:
   ☑ Require a minimum number of reviewers
   ☑ Check for linked work items
   ☑ Check for comment resolution
   ☑ Build validation
   ☑ Limit merge types (Merge, Squash)
```

---

## 10. Hata Senaryoları ve Çözümleri

### ❌ Hata 1: Branch Rule Violation

**Belirti:** PR açtığınızda validation hatası

**Çözüm:**
1. PR'ı kapatın
2. Doğru akışı izleyin:
   - `feature/*` → önce `sandbox`'a
   - `sandbox` → sonra `release`'e
   - `release` → en son `main`'e

### ❌ Hata 2: Merge Conflict

```bash
# Lokal'de conflict çözümü
git checkout feature/my-feature
git pull origin sandbox
git merge origin/sandbox

# Conflict'leri düzenleyin
git add .
git commit -m "Resolve merge conflicts"
git push origin feature/my-feature
```

### ❌ Hata 3: Build Hatası

```bash
# Lokal'de test edin
./CompileApp.ps1

# Hataları düzeltin
git add .
git commit -m "Fix build errors"
git push
```

### ❌ Hata 4: Reviewer Onayı Eksik

1. PR'da "Reviewers" bölümüne gidin
2. Yeterli sayıda reviewer ekleyin
3. Reviewer'lara bildirim gönderin

---

## 11. Hızlı Referans

### Branch Akış Özeti

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         BRANCH AKIŞ ÖZETİ                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  🔵 NORMAL GELİŞTİRME:                                                  │
│     feature/* ─PR→ sandbox ─PR→ release ─PR→ main                       │
│                                                                         │
│  🟠 BUGFIX (Release düzeltme):                                          │
│     release ─branch→ bugfix/* ─PR→ release                              │
│     (Otomatik back-merge: release → sandbox)                            │
│                                                                         │
│  🔴 HOTFIX (Acil düzeltme):                                             │
│     main ─branch→ hotfix/* ─PR→ main                                    │
│     (Otomatik back-merge: main → release → sandbox)                     │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Git Komut Referansı

| İşlem | Komut |
|-------|-------|
| Branch listele | `git branch -a` |
| Branch oluştur | `git checkout -b feature/isim` |
| Branch değiştir | `git checkout sandbox` |
| Değişiklikleri çek | `git pull origin sandbox` |
| Commit | `git commit -m "[FEATURE] #123 - Açıklama"` |
| Push | `git push origin feature/isim` |
| Tag ekle | `git tag -a v1.0.0 -m "Açıklama"` |
| Tag push | `git push origin v1.0.0` |

### PR Template

```markdown
## 📋 Değişiklik Özeti
[Değişikliklerin kısa açıklaması]

## 🎯 İlgili Work Item
Fixes #[work-item-id]

## ✅ Yapılan Değişiklikler
- [ ] Değişiklik 1
- [ ] Değişiklik 2

## 🧪 Test Senaryoları
- [ ] Test 1
- [ ] Test 2

## ⚠️ Breaking Changes
[Varsa açıklama]
```

### Code Review Checklist

```
📋 Genel Kontroller:
☐ Kod okunabilir ve anlaşılır mı?
☐ İsimlendirme standartlarına uygun mu?
☐ Gereksiz kod/yorum var mı?
☐ Hata yönetimi düzgün yapılmış mı?

🔒 Güvenlik Kontrolleri:
☐ Hassas veri açığa çıkmıyor mu?
☐ Input validation yapılmış mı?
☐ SQL injection riski var mı?

🎯 İş Kuralları:
☐ İş gereksinimleri karşılanıyor mu?
☐ Edge case'ler düşünülmüş mü?
☐ Work item ile uyumlu mu?
```

---

*Bu döküman son olarak 2026-01-16 tarihinde güncellenmiştir.*
