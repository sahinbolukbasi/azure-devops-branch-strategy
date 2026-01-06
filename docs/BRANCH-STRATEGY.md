# 📚 Azure DevOps Branch Stratejisi ve CI/CD Pipeline Dokümantasyonu

## İçindekiler
1. [Genel Bakış](#1-genel-bakış)
2. [Branch Yapısı](#2-branch-yapısı)
3. [Ortamlar (Environments)](#3-ortamlar-environments)
4. [Geliştirici Senaryoları](#4-geliştirici-senaryoları)
5. [Pipeline Akışları](#5-pipeline-akışları)
6. [Hata Senaryoları ve Çözümleri](#6-hata-senaryoları-ve-çözümleri)

---

## 1. Genel Bakış

Bu pipeline, **Business Central** uygulamaları için tasarlanmış profesyonel bir CI/CD akışıdır. Temel prensipler:

| Prensip | Açıklama |
|---------|----------|
| **Hiyerarşik Akış** | Kod her zaman `sandbox → release → main` sırasıyla ilerler |
| **PR Zorunluluğu** | Tüm merge işlemleri Pull Request ile yapılır |
| **Otomatik Senkronizasyon** | Production deployment sonrası tüm branch'ler otomatik güncellenir |
| **Conflict Koruması** | Çakışma durumunda pipeline durur ve manuel müdahale ister |

---

## 2. Branch Yapısı

```
                              ┌─────────────────────────────────────┐
                              │              MAIN                   │
                              │         (Production/Canlı)          │
                              │    🔒 Korumalı - Direkt push yok    │
                              └──────────────────┬──────────────────┘
                                                 │
                         ┌───────────────────────┼───────────────────────┐
                         │                       │                       │
                         ▼                       │                       ▼
              ┌─────────────────────┐            │            ┌─────────────────────┐
              │      RELEASE        │            │            │     hotfix/*        │
              │  (Pre-Production)   │◄───────────┘            │  (Acil Düzeltme)    │
              │ 🔒 Korumalı branch  │                         │  main'den açılır    │
              └─────────┬───────────┘                         │  main'e merge olur  │
                        │                                     └─────────────────────┘
        ┌───────────────┼───────────────┐
        │               │               │
        ▼               │               ▼
┌──────────────┐        │        ┌──────────────┐
│   SANDBOX    │        │        │   bugfix/*   │
│ (Development)│◄───────┘        │(Release Fix) │
│🔒 Korumalı   │                 │release'den   │
└──────┬───────┘                 │açılır        │
       │                         └──────────────┘
       │
       ▼
┌──────────────┐
│  feature/*   │
│(Yeni Özellik)│
│sandbox'dan   │
│açılır        │
└──────────────┘
```

### Branch Türleri ve Kuralları

| Branch | Kaynak | Hedef | Açıklama | Ömrü |
|--------|--------|-------|----------|------|
| `main` | - | - | Production kodu, her zaman stabil | Kalıcı |
| `release` | sandbox, bugfix/* | main | Pre-production test ortamı | Kalıcı |
| `sandbox` | feature/* | release | Development/Test ortamı | Kalıcı |
| `feature/*` | sandbox | sandbox | Yeni özellik geliştirme | Geçici |
| `bugfix/*` | release | release | Release ortamı hata düzeltme | Geçici |
| `hotfix/*` | main | main | Acil production düzeltme | Geçici |

---

## 3. Ortamlar (Environments)

### Sandbox Environment
- **Tetikleyen Branch'ler:** sandbox, feature/*, release, bugfix/*
- **Kullanım:** Geliştirme testi, Entegrasyon testi, UAT (Release için)

### Production Environment
- **Tetikleyen Branch'ler:** main, hotfix/*
- **Kullanım:** Son kullanıcı erişimi, Canlı sistem

---

## 4. Geliştirici Senaryoları

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
git add . 
git commit -m "feat: Satış raporu eklendi"
git push origin feature/satis-raporu
```

#### Adım 3: Pull Request Açma (Sandbox'a)
1. Azure DevOps'a gidin
2. Repos → Pull Requests → New Pull Request
3. Source: feature/satis-raporu, Target: sandbox
4. Create butonuna tıklayın

#### Adım 4: Pipeline Çalışması
PR açıldığında: Validate → Build

#### Adım 5: Merge İşlemi
PR onaylandıktan sonra Complete butonuna tıklayın.
Merge sonrası: Build → Deploy to Sandbox

---

### 📗 Senaryo 2: Sandbox'tan Release'e Çıkma

1. Repos → Pull Requests → New Pull Request
2. Source: sandbox, Target: release
3. Merge sonrası: Build → Release Staging (Sandbox'a UAT için deploy)

---

### 📕 Senaryo 3: Release'den Production'a Çıkma

1. Repos → Pull Requests → New Pull Request
2. Source: release, Target: main
3. Merge sonrası: Build → Deploy to Production → Back-Merge (Main→Release→Sandbox)

---

### 📙 Senaryo 4: Hotfix (Acil Canlı Düzeltme)

⚠️ ÖNEMLİ: Hotfix MUTLAKA main'den açılır!

```bash
git checkout main
git pull origin main
git checkout -b hotfix/kritik-fatura-hatasi
# Düzeltme yap
git add . 
git commit -m "hotfix: Fatura hesaplama hatası düzeltildi"
git push origin hotfix/kritik-fatura-hatasi
```

PR: hotfix/kritik-fatura-hatasi → main

Pipeline: Build → Deploy Production → Hotfix Back-Merge → Cleanup

---

### 📒 Senaryo 5: Bugfix (Release Ortamı Düzeltme)

⚠️ ÖNEMLİ: Bugfix MUTLAKA release'den açılır!

```bash
git checkout release
git pull origin release
git checkout -b bugfix/rapor-formatlama-hatasi
# Düzeltme yap
git add .
git commit -m "bugfix: Rapor tarih formatı düzeltildi"
git push origin bugfix/rapor-formatlama-hatasi
```

PR: bugfix/rapor-formatlama-hatasi → release

Pipeline: Build → Release Staging → Bugfix Back-Merge → Cleanup

⚠️ NOT: Bugfix henüz Production'a gitmedi! Production'a almak için release → main PR açılmalı

---

## 5. Pipeline Akışları

### Tüm Stage'lerin Özeti

| Stage | Koşul | İş |
|-------|-------|-----|
| 🔍 Validate | Sadece PR'larda | Branch kurallarını kontrol eder |
| 🔨 Build | Her zaman | Kodu derler, artifact oluşturur |
| 🧪 Deploy to Sandbox | sandbox veya feature/* | Sandbox ortamına deployment |
| 🎯 Release Staging | release veya bugfix/* | Release kodunu test ortamına deploy |
| 🌟 Deploy to Production | main veya hotfix/* | Canlı ortama deployment |
| 🔄 Back-Merge (Main) | main branch | Main → Release → Sandbox sync |
| 🔥 Hotfix Back-Merge | hotfix/* branch | Hotfix → Release → Sandbox sync |
| 🐛 Bugfix Back-Merge | bugfix/* branch | Release → Sandbox sync |
| 🧹 Cleanup | hotfix/* veya bugfix/* | Geçici branch'i siler |

### Branch'e Göre Çalışan Stage'ler

| Branch | Validate | Build | Sandbox | Release Stage | Production | Back-Merge | Cleanup |
|--------|----------|-------|---------|---------------|------------|------------|---------|
| feature/* (PR) | ✅ | ✅ | - | - | - | - | - |
| feature/* (push) | - | ✅ | ✅ | - | - | - | - |
| sandbox | - | ✅ | ✅ | - | - | - | - |
| bugfix/* (PR) | ✅ | ✅ | - | - | - | - | - |
| bugfix/* (push) | - | ✅ | - | ✅ | - | ✅ | ✅ |
| release | - | ✅ | - | ✅ | - | - | - |
| hotfix/* (PR) | ✅ | ✅ | - | - | - | - | - |
| hotfix/* (push) | - | ✅ | - | - | ✅ | ✅ | ✅ |
| main | - | ✅ | - | - | ✅ | ✅ | - |

---

## 6. Hata Senaryoları ve Çözümleri

### ❌ Hata 1: Yanlış Branch'e PR Açma

**Çözüm:**
1. PR'ı kapatın
2. Doğru akışı takip edin: feature/* → sandbox → release → main
3. Önce sandbox'a PR açın

### ❌ Hata 2: Back-Merge Conflict

**Çözüm:**
```bash
git checkout release
git pull origin release
git merge origin/main
# Conflict'leri çözün
git add .
git commit -m "Merge main into release - conflict resolved"
git push origin release
```

### ❌ Hata 3: Build Hatası

**Çözüm:**
```bash
./CompileApp.ps1
# Hataları düzeltin
git add .
git commit -m "fix: Build hatası düzeltildi"
git push
```

---

## 📋 Hızlı Referans Kartı

### Yeni Özellik
```bash
git checkout sandbox
git checkout -b feature/isim
# geliştirme
PR: feature/isim → sandbox
```

### Release Hata Düzeltme
```bash
git checkout release
git checkout -b bugfix/isim
# düzeltme
PR: bugfix/isim → release
```

### Acil Canlı Düzeltme
```bash
git checkout main
git checkout -b hotfix/isim
# düzeltme
PR: hotfix/isim → main
```

### İzin Verilen PR Akışları
- → sandbox: feature/*
- → release: sandbox, bugfix/*
- → main: release, hotfix/*

---

*Bu döküman son olarak 2026-01-06 tarihinde güncellenmiştir.*