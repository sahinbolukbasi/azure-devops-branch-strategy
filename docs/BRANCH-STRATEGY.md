# 📚 Azure DevOps Branch Stratejisi ve CI/CD Pipeline Dokümantasyonu

## İçindekiler
1. [Genel Bakış](#1-genel-bakış)
2. [Branch Yapısı](#2-branch-yapısı)
3. [PR Kuralları](#3-pr-kuralları)
4. [Build ve Merge Kuralları](#4-build-ve-merge-kuralları)
5. [Geliştirici Senaryoları](#5-geliştirici-senaryoları)
6. [Pipeline Akışları](#6-pipeline-akışları)
7. [Hata Senaryoları ve Çözümleri](#7-hata-senaryoları-ve-çözümleri)

---

## 1. Genel Bakış

Bu pipeline, **Business Central** uygulamaları için tasarlanmış profesyonel bir CI/CD akışıdır. 

### Temel Prensipler

| Prensip | Açıklama |
|---------|----------|
| **Hiyerarşik Akış** | Kod her zaman `feature/* → sandbox → release → main` sırasıyla ilerler |
| **PR Zorunluluğu** | Tüm merge işlemleri Pull Request ile yapılır |
| **Akıllı Build** | Sadece kritik merge'lerde (release, main) derleme yapılır |
| **Otomatik Senkronizasyon** | Bugfix/Hotfix sonrası alt branch'ler otomatik güncellenir |
| **Hata Önleme** | Yanlış PR'lar validation aşamasında engellenir |

### Ne Zaman Build Yapılır? 

| Durum | Build |
|-------|-------|
| PR açıldığında | ❌ Sadece Validation |
| `feature/* → sandbox` merge | ❌ Build yok |
| `sandbox → release` merge | ✅ Build |
| `bugfix/* → release` merge | ✅ Build |
| `release → main` merge | ✅ Build |
| `hotfix/* → main` merge | ✅ Build |

---

## 2. Branch Yapısı

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
              │  ← bugfix/*         │                         │  📌 BUILD yapılır   │
              └─────────┬───────────┘                         └─────────────────────┘
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
       │                         │ 📌 BUILD     │
       ▼                         │    yapılır   │
┌──────────────┐                 └──────��───────┘
│  feature/*   │
│(Yeni Özellik)│
│              │
│ 📌 sandbox'dan│
│    açılır    │
│ 📌 sandbox'a │
│    PR açılır │
│ 📌 BUILD YOK │
└──────────────┘
```

### Branch Türleri ve Kuralları

| Branch | Nereden Açılır | Nereye PR Açılır | Build | Back-Merge | Ömrü |
|--------|----------------|------------------|-------|------------|------|
| `main` | - | - | - | - | Kalıcı |
| `release` | - | `main` | ✅ | `→ sandbox` | Kalıcı |
| `sandbox` | - | `release` | ✅ | - | Kalıcı |
| `feature/*` | `sandbox` | `sandbox` | ❌ | - | Geçici |
| `bugfix/*` | `release` | `release` | ✅ | `→ sandbox` | Geçici |
| `hotfix/*` | `main` | `main` | ✅ | `→ release → sandbox` | Geçici |

---

## 3. PR Kuralları

### İzin Verilen PR Akışları

```
╔═���═════════════════════════════════════════════════════════════════════════╗
║                              PR KURALLARI                                  ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║  SANDBOX'A PR AÇILABİLİR:                                                  ║
║  ┌─────────────────────────────────────────────────────────────────────┐  ║
║  │  ✅ feature/*     → Yeni özellik geliştirmeleri                     │  ║
║  │  ❌ Diğer tümü    → YASAK                                           │  ║
║  └─────────────────────────────────────────────────────────────────────┘  ║
║                                                                           ║
║  RELEASE'E PR AÇILABİLİR:                                                 ║
║  ┌─────────────────────────────────────────────────────────────────────┐  ║
║  │  ✅ sandbox       → Normal geliştirme akışı                         │  ║
║  │  ✅ bugfix/*      → Release ortamı hata düzeltmeleri                │  ║
║  │  ❌ Diğer tümü    → YASAK                                           │  ║
║  └─────────────────────────────────────────────────────────────────────┘  ║
║                                                                           ║
║  MAIN'E PR AÇILABİLİR:                                                    ║
║  ┌─────────────────────────────────────────────────────────────────────┐  ║
║  │  ✅ release       → Normal release akışı                            │  ║
║  │  ✅ hotfix/*      → Acil canlı düzeltmeleri                         │  ║
║  │  ❌ Diğer tümü    → YASAK                                           │  ║
║  └─────────────────────────────────────────────────────────────────────┘  ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

### Yasak PR Örnekleri

| Kaynak | Hedef | Sonuç | Doğru Akış |
|--------|-------|-------|------------|
| `feature/*` | `release` | ❌ YASAK | `feature/* → sandbox → release` |
| `feature/*` | `main` | ❌ YASAK | `feature/* → sandbox → release → main` |
| `sandbox` | `main` | ❌ YASAK | `sandbox → release → main` |
| `bugfix/*` | `main` | ❌ YASAK | `bugfix/* → release → main` |
| `bugfix/*` | `sandbox` | ❌ YASAK | `bugfix/* → release` (back-merge otomatik) |
| `hotfix/*` | `release` | ❌ YASAK | `hotfix/* → main` (back-merge otomatik) |

---

## 4. Build ve Merge Kuralları

### Build Matrisi

| Merge İşlemi | Tetiklenen Branch | Validation | Build | Back-Merge |
|--------------|-------------------|------------|-------|------------|
| `feature/* → sandbox` PR | - | ✅ | ❌ | - |
| `feature/* → sandbox` merge | `sandbox` | - | ❌ | - |
| `sandbox → release` PR | - | ✅ | ❌ | - |
| `sandbox → release` merge | `release` | - | ✅ | `→ sandbox` |
| `bugfix/* → release` PR | - | ✅ | ❌ | - |
| `bugfix/* → release` merge | `release` | - | ✅ | `→ sandbox` |
| `release → main` PR | - | ✅ | ❌ | - |
| `release → main` merge | `main` | - | ✅ | `→ release → sandbox` |
| `hotfix/* → main` PR | - | ✅ | ❌ | - |
| `hotfix/* → main` merge | `main` | - | ✅ | `→ release → sandbox` |

### Back-Merge Akışları

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                           BACK-MERGE AKIŞLARI                              ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║  BUGFIX MERGE SONRASI:                                                    ║
║  ┌─────────────────────────────────────────────────────────────────────┐  ║
║  │  bugfix/* → release (merge)                                         │  ║
║  │       │                                                             │  ║
║  │       ▼                                                             │  ║
║  │  BUILD ✅                                                           │  ║
║  │       │                                                             │  ║
║  │       ▼                                                             │  ║
║  │  release → sandbox (otomatik back-merge)                            │  ║
║  └─────────────────────────────────────────────────────────────────────┘  ║
║                                                                           ║
║  HOTFIX MERGE SONRASI:                                                    ║
║  ┌─────────────────────────────────────────────────────────────────────┐  ║
║  │  hotfix/* → main (merge)                                            │  ║
║  │       │                                                             │  ║
║  │       ▼                                                             │  ║
║  │  BUILD ✅                                                           │  ║
║  │       │                                                             │  ║
║  │       ▼                                                             │  ║
║  │  main → release (otomatik back-merge)                               │  ║
║  │       │                                                             │  ║
║  │       ▼                                                             │  ║
║  │  release → sandbox (otomatik back-merge)                            │  ║
║  └─────────────────────────────────────────────────────────────────────┘  ║
║                                                                           ║
║  NORMAL RELEASE SONRASI:                                                  ║
║  ┌─────────────────────────────────────────────────────────────────────┐  ║
║  │  release → main (merge)                                             │  ║
║  │       │                                                             │  ║
║  │       ▼                                                             │  ║
║  │  BUILD ✅                                                           │  ║
║  │       │                                                             │  ║
║  │       ▼                                                             │  ║
║  │  main → release → sandbox (otomatik back-merge)                     │  ║
║  └─────────────────────────────────────────────────────────────────────┘  ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

---

## 5. Geliştirici Senaryoları

### 📘 Senaryo 1: Yeni Özellik Geliştirme (Feature)

**Durum:** Yeni bir satış raporu eklemek istiyorsunuz. 

#### Adım 1: Feature Branch Oluşturma
```bash
git checkout sandbox
git pull origin sandbox
git checkout -b feature/satis-raporu
```

#### Adım 2: Geliştirme Yapma
```bash
# Kodunuzu yazın... 
git add .
git commit -m "feat: Satış raporu eklendi"
git push origin feature/satis-raporu
```

#### Adım 3: Pull Request Açma (Sandbox'a)
1. Azure DevOps'a gidin
2. Repos → Pull Requests → New Pull Request
3. Source: `feature/satis-raporu`, Target: `sandbox`
4. Create butonuna tıklayın

#### Adım 4: Pipeline Çalışması
```
PR açıldığında: 
┌─────────────────────────────────────┐
│  🔍 Validation                      │
│     ✅ feature/* → sandbox GEÇERLI │
│     ⚡ Build yapılmayacak           │
└─────────────────────────────────────┘
```

#### Adım 5: Merge İşlemi
- PR onaylandıktan sonra "Complete" butonuna tıklayın
- **Build yapılmaz**, kod sandbox'a merge edilir
- Sandbox ortamında test edin

---

### 📗 Senaryo 2: Sandbox'tan Release'e Çıkma

**Durum:** Sandbox'taki özellikler test edildi, release'e çıkılacak.

#### Adım 1: PR Açma
1. Repos → Pull Requests → New Pull Request
2. Source: `sandbox`, Target: `release`

#### Adım 2: Pipeline Çalışması
```
PR açıldığında: 
┌─────────────────────────────────────┐
│  🔍 Validation                      │
│     ✅ sandbox → release GEÇERLI   │
│     📦 Merge sonrası BUILD         │
└─────────────────────────────────────┘

Merge sonrası:
┌─────────────────────────────────────┐
│  🔨 Build (Release)                 │
│     📦 Uygulama derlenir            │
│     📤 Artifact oluşturulur         │
├─────────────────────────────────────┤
│  🔄 Back-Merge                      │
│     release → sandbox sync          │
└─────────────────────────────────────┘
```

---

### 📕 Senaryo 3: Release'den Production'a Çıkma

**Durum:** Release test edildi, canlıya alınacak.

#### Adım 1: PR Açma
1. Repos → Pull Requests → New Pull Request
2. Source: `release`, Target: `main`

#### Adım 2: Pipeline Çalışması
```
PR açıldığında:
┌─────────────────────────────────────┐
│  🔍 Validation                      │
│     ✅ release → main GEÇERLI      │
│     📦 Merge sonrası BUILD         │
└─────────────────────────────────────┘

Merge sonrası: 
┌─────────────────────────────────────┐
│  🔨 Build (Production)              │
│     📦 Uygulama derlenir            │
│     📤 Artifact oluşturulur         │
├─────────────────────────────────────┤
│  🔄 Back-Merge                      │
│     main → release sync             │
│     release → sandbox sync          │
└─────────────────────────────────────┘
```

#### Adım 3: Canlıya Alma
- Tag eklenince ayrı deployment pipeline çalışır

---

### 📙 Senaryo 4: Hotfix (Acil Canlı Düzeltme)

**Durum:** Production'da kritik bir hata var, acil düzeltilmeli! 

⚠️ **ÖNEMLİ:** Hotfix **MUTLAKA** `main`'den açılır! 

#### Adım 1: Hotfix Branch Oluşturma
```bash
git checkout main
git pull origin main
git checkout -b hotfix/kritik-fatura-hatasi
```

#### Adım 2: Düzeltme Yapma
```bash
# Hatayı düzeltin...
git add .
git commit -m "hotfix: Fatura hesaplama hatası düzeltildi"
git push origin hotfix/kritik-fatura-hatasi
```

#### Adım 3: PR Açma (Main'e)
1. Source: `hotfix/kritik-fatura-hatasi`
2. Target: `main`

#### Adım 4: Pipeline Çalışması
```
PR açıldığında: 
┌─────────────────────────────────────┐
│  🔍 Validation                      │
│     ✅ hotfix/* → main GEÇERLI     │
│     🔥 Acil düzeltme modu!           │
└─────────────────────────────────────┘

Merge sonrası: 
┌─────────────────────────────────────┐
│  🔨 Build (Production)              │
│     📦 Uygulama derlenir            │
├─────────────────────────────────────┤
│  🔄 Back-Merge                      │
│     main → release sync             │
│     release → sandbox sync          │
│     (Tüm branch'ler güncellenir!)   │
└─────────────────────────────────────┘
```

---

### 📒 Senaryo 5: Bugfix (Release Ortamı Düzeltme)

**Durum:** Release ortamında test sırasında bir hata bulundu. 

⚠️ **ÖNEMLİ:** Bugfix **MUTLAKA** `release`'den açılır!

#### Adım 1: Bugfix Branch Oluşturma
```bash
git checkout release
git pull origin release
git checkout -b bugfix/rapor-formatlama-hatasi
```

#### Adım 2: Düzeltme Yapma
```bash
# Hatayı düzeltin...
git add . 
git commit -m "bugfix:  Rapor tarih formatı düzeltildi"
git push origin bugfix/rapor-formatlama-hatasi
```

#### Adım 3: PR Açma (Release'e)
1. Source: `bugfix/rapor-formatlama-hatasi`
2. Target: `release`

#### Adım 4: Pipeline Çalışması
```
PR açıldığında:
┌─────────────────────────────────────┐
│  🔍 Validation                      │
│     ✅ bugfix/* → release GEÇERLI  │
│     🐛 Hata düzeltme modu           │
└─────────────────────────────────────┘

Merge sonrası: 
┌─────────────────────────────────────┐
│  🔨 Build (Release)                 │
│     📦 Uygulama derlenir            │
├─────────────────────────────────────┤
│  🔄 Back-Merge                      │
│     release → sandbox sync          │
│     (Sandbox da güncellenir!)       │
└─────────────────────────────────────┘
```

⚠️ **NOT:** Bugfix henüz Production'a gitmedi!  Production'a almak için `release → main` PR açılmalı.

---

## 6. Pipeline Akışları

### Stage Özeti

| Stage | Koşul | İş |
|-------|-------|-----|
| 🔍 Validate | Sadece PR'larda | Branch kurallarını kontrol eder, yanlış PR'ları engeller |
| 🔨 Build (Release) | `release` branch push | Kodu derler, artifact oluşturur |
| 🔨 Build (Main) | `main` branch push | Kodu derler, artifact oluşturur |
| 🔄 Back-Merge (Release) | `release` build sonrası | `release → sandbox` sync |
| 🔄 Back-Merge (Main) | `main` build sonrası | `main → release → sandbox` sync |

### Akış Diyagramı

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                              NORMAL AKIŞ                                   ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║   feature/xyz ──PR──→ sandbox ──PR──→ release ──PR──→ main               ║
║                │              │               │                           ║
║            Validate       Validate         Validate                       ║
║           (no build)      + BUILD          + BUILD                        ║
║                              │               │                            ║
║                              ▼               ▼                            ║
║                         Back-merge      Back-merge                        ║
║                         → sandbox       → release                         ║
║                                         → sandbox                         ║
║                                                                           ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                              BUGFIX AKIŞI                                  ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║   release ──branch──→ bugfix/xyz ──PR──→ release                         ║
║                                     │                                     ║
║                                 Validate                                  ║
║                                     │                                     ║
║                                   merge                                   ║
║                                     │                                     ║
║                                  BUILD                                    ║
║                                     │                                     ║
║                               Back-merge                                  ║
║                               → sandbox                                   ║
║                                                                           ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                              HOTFIX AKIŞI                                  ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║   main ──branch──→ hotfix/acil ──PR──→ main                              ║
║                                   │                                       ║
║                               Validate                                    ║
║                                   │                                       ║
║                                 merge                                     ║
║                                   │                                       ║
║                                BUILD                                      ║
║                                   │                                       ║
║                             Back-merge                                    ║
║                             → release                                     ║
║                             → sandbox                                     ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

---

## 7. Hata Senaryoları ve Çözümleri

### ❌ Hata 1: Yanlış Branch'e PR Açma

**Belirti:** PR açtığınızda Validation hatası alıyorsunuz.

**Örnek Hata Mesajı:**
```
╔═══════════════════════════════════════════════════════════════════╗
║             ❌ RELEASE BRANCH KURALI İHLALİ!                        ║
╠═══════════════════════════════════════════════════════════════════╣
║  Release branch'e SADECE şu kaynaklardan PR açılabilir:           ║
║    ✅ sandbox      → Normal geliştirme akışı                      ║
║    ✅ bugfix/*     → Release ortamı düzeltmeleri                  ║
║  ❌ SİZİN BRANCH:  feature/xyz                                      ║
╚═══════════════════════════════════════════════════════════════════╝
```

**Çözüm:**
1. PR'ı kapatın
2. Doğru akışı takip edin: 
   - `feature/*` → önce `sandbox`'a PR açın
   - `sandbox` → sonra `release`'e PR açın
   - `release` → en son `main`'e PR açın

---

### ❌ Hata 2: Back-Merge Conflict

**Belirti:** Pipeline'da back-merge aşamasında conflict uyarısı. 

**Çözüm (Release → Sandbox conflict):**
```bash
git checkout sandbox
git pull origin sandbox
git merge origin/release
# Conflict'leri çözün (VS Code veya başka bir editörde)
git add .
git commit -m "Merge release into sandbox - conflict resolved"
git push origin sandbox
```

**Çözüm (Main → Release conflict):**
```bash
git checkout release
git pull origin release
git merge origin/main
# Conflict'leri çözün
git add .
git commit -m "Merge main into release - conflict resolved"
git push origin release
```

---

### ❌ Hata 3: Build Hatası

**Belirti:** Build aşamasında derleme hatası.

**Çözüm:**
```bash
# Lokal ortamda test edin
./CompileApp.ps1

# Hataları düzeltin
git add .
git commit -m "fix: Build hatası düzeltildi"
git push
```

---

### ❌ Hata 4: Hotfix'i Yanlış Branch'den Açma

**Belirti:** Hotfix'i `release` veya `sandbox`'dan açtınız.

**Çözüm:**
```bash
# Yanlış branch'i silin
git branch -D hotfix/yanlis-branch
git push origin --delete hotfix/yanlis-branch

# Doğru şekilde main'den açın
git checkout main
git pull origin main
git checkout -b hotfix/dogru-branch
```

---

## 📋 Hızlı Referans Kartı

### Yeni Özellik (Feature)
```bash
git checkout sandbox
git checkout -b feature/isim
# geliştirme
git push origin feature/isim
# PR:  feature/isim → sandbox (BUILD YOK)
```

### Release Hata Düzeltme (Bugfix)
```bash
git checkout release
git checkout -b bugfix/isim
# düzeltme
git push origin bugfix/isim
# PR:  bugfix/isim → release (BUILD + back-merge sandbox)
```

### Acil Canlı Düzeltme (Hotfix)
```bash
git checkout main
git checkout -b hotfix/isim
# düzeltme
git push origin hotfix/isim
# PR: hotfix/isim → main (BUILD + back-merge release & sandbox)
```

### İzin Verilen PR Akışları
```
┌─────────────────────────────────────────────────────────┐
│  → sandbox :  SADECE feature/*                           │
│  → release : SADECE sandbox, bugfix/*                   │
│  → main    : SADECE release, hotfix/*                   │
└─────────────────────────────────────────────────────────┘
```

### Build Yapılan Durumlar
```
┌─────────────────────────────────────────────────────────┐
│  ✅ BUILD:  sandbox → release merge                      │
│  ✅ BUILD: bugfix/* → release merge                     │
│  ✅ BUILD: release → main merge                         │
│  ✅ BUILD: hotfix/* → main merge                        │
│  ❌ NO BUILD: feature/* → sandbox merge                 │
│  ❌ NO BUILD:  Tüm PR'lar (sadece validation)            │
└─────────────────────────────────────────────────────────┘
```

---

*Bu döküman son olarak 2026-01-06 tarihinde güncellenmiştir.*
