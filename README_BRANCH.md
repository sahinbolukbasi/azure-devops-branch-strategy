# Azure DevOps Branch ve CI/CD Stratejisi Dokümantasyonu

## 1. Amaç ve Kapsam
Bu doküman; **main, release ve sandbox** ana branch yapısını esas alan, hotfix, feature ve CI/CD süreçlerini kapsayan, Azure DevOps üzerinde kurumsal ölçekte uygulanabilir bir **branch + pipeline stratejisi** tanımlar. Hedef; hataları minimize eden, geri alınabilirliği yüksek, otomasyona dayalı ve ekip ölçeğinde sürdürülebilir bir yapı kurmaktır.

---

## 2. Ana Branch Yapısı

### 2.1 `main` (Production Kaynağı)
- Canlı ortamın **tek doğruluk kaynağıdır**
- Doğrudan commit **yasaktır**
- Sadece:
  - `release` branch PR’ları
  - `hotfix/*` branch PR’ları
  kabul edilir

**Kurallar:**
- Min. 2 reviewer
- Build + test pipeline zorunlu
- Squash merge (opsiyonel, tavsiye edilir)

---

### 2.2 `release` (Staging / UAT)
- Yayına çıkacak kodların stabilize edildiği alandır
- **Sadece `sandbox` üzerinden PR kabul eder**
- Versiyonlama, tag ve artifact üretimi burada yapılır

**Kurallar:**
- `sandbox → release` dışında PR yasak
- Otomatik version bump + changelog
- Tag zorunlu (örn: `v1.4.2`)

---

### 2.3 `sandbox` (Development Entegrasyon)
- Günlük geliştirme ve feature entegrasyon alanıdır
- Feature branch’ler buradan açılır ve buraya merge edilir

**Kurallar:**
- Feature PR’ları zorunlu
- Otomatik build + unit test
- Manuel deploy (opsiyonel)

---

## 3. Feature Branch Stratejisi

### 3.1 Feature Branch Açma
- Kaynak: `sandbox`
- Format:
```
feature/<workitemId>-kisa-aciklama
```
Örnek:
```
feature/1234-login-validation
```

### 3.2 Feature Geliştirme Akışı
1. `sandbox` → feature branch
2. Geliştirme + local test
3. PR → `sandbox`
4. PR sonrası feature branch **silinir**

> ❗ Feature branch’ler **asla `main` veya `release` ile merge edilmez**

---

## 4. Hotfix Stratejisi

### 4.1 Hotfix Branch Oluşturma
- Kaynak: `main`
- Format:
```
hotfix/<issueId>-kisa-aciklama
```

### 4.2 Hotfix Akışı
1. `main` → `hotfix/*`
2. Düzeltme yapılır
3. PR → `main`
4. Merge sonrası otomasyon devreye girer

---

## 5. Hotfix Sonrası Otomatik Senkronizasyon

### 5.1 Hedef
Hotfix `main`’e merge edildikten sonra:
- `release` güncellensin
- `sandbox` güncellensin

### 5.2 Önerilen Yöntem: Pipeline Tabanlı PR Otomasyonu

#### Akış
- `main` branch’ine merge trigger
- Pipeline aşağıdaki adımları çalıştırır:

1. `main → release` otomatik PR oluştur
2. `release → sandbox` otomatik PR oluştur

Bu PR’lar:
- Auto-complete açık
- Reviewer zorunlu (opsiyonel)

#### Kullanılabilecek Araçlar
- Azure DevOps REST API
- `az repos pr create`
- Service Connection (PAT veya Managed Identity)

---

## 6. Pipeline Mimarisi

### 6.1 CI – Sandbox Pipeline
**Trigger:**
- `sandbox`
- `feature/*`

**Adımlar:**
- Build
- Unit Test
- Static Code Analysis

---

### 6.2 Release Pipeline
**Trigger:**
- `release`

**Adımlar:**
- Version bump (SemVer)
- Changelog generation
- Artifact publish
- Tag creation

---

### 6.3 Production Pipeline
**Trigger:**
- `main`

**Adımlar:**
- Final build
- Security scan
- Production deploy

---

## 7. Branch Policy ve Koruma Mekanizmaları

### 7.1 Ortak Kurallar
- Direct push kapalı
- PR zorunlu
- Build validation zorunlu

### 7.2 Branch Bazlı Policy Tablosu

| Branch   | Min Reviewer | Build Zorunlu | Kim Merge Edebilir |
|--------|--------------|---------------|-------------------|
| main   | 2            | ✅            | Lead / DevOps     |
| release| 2            | ✅            | Senior Dev        |
| sandbox| 1            | ✅            | Dev Team          |

---

## 8. Release Branch Yönetimi

### 8.1 Release Branch Sayısı
- Aktif **son 5 release** korunur
- Daha eski olanlar:
  - Manuel veya pipeline ile arşivlenir
  - Tag’ler kalıcıdır

### 8.2 Önerilen Format
```
release/2025.03
release/2025.04
```

---

## 9. Versiyonlama ve Tag Stratejisi

- Semantic Versioning
```
MAJOR.MINOR.PATCH
```

- Tag sadece `release` ve `main` üzerinde
- Pipeline otomatik üretir

---

## 10. Riskler ve Önlemler

| Risk | Önlem |
|----|------|
| Hotfix çakışması | Otomatik PR + review |
| Release drift | Sadece sandbox PR |
| Feature kaosu | Naming + auto delete |
| İnsan hatası | Pipeline enforcement |

---

## 11. Feature → Sandbox → Release → Main Akışı (Detaylı)

Bu bölüm, **feature geliştirmesinden production’a kadar olan ideal ve hatasız akışı** netleştirir ve pipeline + PR + hotfix senaryolarının birbiriyle çakışmadan çalışmasını garanti altına alır.

---

## 11.1 Feature → Sandbox

### Akış
1. Feature branch **sandbox**’tan açılır
2. Geliştirme yapılır
3. PR → `sandbox`
4. CI pipeline çalışır

### Pipeline Davranışı
- Build
- Unit test
- Artifact üretimi (geçici)

> Feature branch **asla release veya main’e gitmez**

---

## 11.2 Sandbox → Release (Kontrollü Geçiş)

### Ne Zaman?
- Sprint sonu
- Release adayı hazır

### Akış
1. PR: `sandbox → release/x.y`
2. Release pipeline tetiklenir

### Release Pipeline Sorumlulukları
- Stabil build
- Version bump (örn: 1.4.0 → 1.4.1)
- Changelog üretimi
- Artifact publish
- Release tag (`v1.4.1`)

### Bugfix Bu Aşamada Gelirse
- Kaynak **sandbox**
- Bugfix branch sandbox’tan açılır
- Tekrar PR → sandbox → release

> ❗ Release aşamasında bugfix varsa **hotfix açılmaz**

---

## 11.3 Release → Main (Production)

### Akış
1. PR: `release/x.y → main`
2. Production pipeline tetiklenir

### Production Pipeline
- Final build
- Güvenlik kontrolleri
- Production deploy

> Main’e merge edilen her commit **deploy edilebilir** kabul edilir

---

## 11.4 Hotfix Akışı (Production Bug)

### Ne Zaman Hotfix?
- Bug **production’da**
- Release beklenemez

### Akış
1. `main → hotfix/issue-id`
2. Fix yapılır
3. PR → `main`

---

## 11.5 Hotfix Sonrası Otomatik Senkronizasyon

Hotfix `main`’e merge edildikten sonra **diğer branch’ler mutlaka güncellenmelidir**.

### Otomatik Akış (Pipeline)

1. `main → release` PR oluştur
2. `release → sandbox` PR oluştur

### Neden PR?
- Branch policy korunur
- Conflict görünür olur
- İzlenebilirlik artar

---

## 12. Örnek Tek Pipeline – Branch Aware (Final)

```yaml
trigger:
  branches:
    include:
      - sandbox
      - main
      - release/*
      - hotfix/*

pool:
  vmImage: windows-latest

variables:
  isSandbox: $[eq(variables['Build.SourceBranch'], 'refs/heads/sandbox')]
  isRelease: $[startsWith(variables['Build.SourceBranch'], 'refs/heads/release/')]
  isMain: $[eq(variables['Build.SourceBranch'], 'refs/heads/main')]
  isHotfix: $[startsWith(variables['Build.SourceBranch'], 'refs/heads/hotfix/')]

stages:

# CI – Feature & Sandbox
- stage: CI
  condition: or(eq(variables.isSandbox, true), eq(variables.isHotfix, true))
  jobs:
    - job: Build
      steps:
        - checkout: self
        - task: PowerShell@2
          inputs:
            targetType: filePath
            filePath: CompileApp.ps1
        - task: PublishBuildArtifacts@1
          inputs:
            pathtoPublish: $(Build.StagingDirectory)
            artifactName: ci

# Release
- stage: Release
  condition: eq(variables.isRelease, true)
  jobs:
    - job: ReleaseBuild
      steps:
        - checkout: self
        - task: PowerShell@2
          displayName: Build & Version
          inputs:
            targetType: filePath
            filePath: CompileApp.ps1
        - task: PublishBuildArtifacts@1
          inputs:
            pathtoPublish: $(Build.StagingDirectory)
            artifactName: release

# Production
- stage: Production
  condition: eq(variables.isMain, true)
  jobs:
    - job: Prod
      steps:
        - checkout: self
        - task: PowerShell@2
          displayName: Final Build
          inputs:
            targetType: filePath
            filePath: CompileApp.ps1
```

---

## 13. Bu Yapının Garantileri

- Feature asla prod’a kaçmaz
- Release yalnızca sandbox’tan beslenir
- Hotfix her zaman diğer branch’lere geri yayılır
- Pipeline + policy birlikte çalışır

---

## 14. Net Tavsiye

> Bu yapı **Azure DevOps + Business Central AL** için gerçek hayatta sorunsuz çalışan, denetlenebilir ve ölçeklenebilir bir modeldir.

Bir sonraki adımda istersen:
- Hotfix sonrası otomatik PR script’i
- Version bump + tag PowerShell
- Branch policy ekran ekran ayarları
hazırlayabilirim.

