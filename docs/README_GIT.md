# 🌿 Azure DevOps Branch Stratejisi ve CI/CD Dokümantasyonu


## 🌳 Branch Yapısı

Projede üç ana (protected) branch bulunmaktadır:

```
┌─────────────────────────────────────────────────────────────────┐
│                        BRANCH HİYERARŞİSİ                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌─────────┐                                                   │
│   │  MAIN   │ ◄─── Canlı Ortam (Production)                     │
│   └────┬────┘                                                   │
│        │                                                        │
│        │ ▲ PR (Release → Main)                                  │
│        │ ▲ PR (Hotfix → Main)                                   │
│        │                                                        │
│   ┌────┴────┐                                                   │
│   │ RELEASE │ ◄─── Sürüm Hazırlık (Pre-Production)              │
│   └────┬────┘                                                   │
│        │                                                        │
│        │ ▲ PR (Sandbox → Release)                               │
│        │                                                        │
│   ┌────┴────┐                                                   │
│   │ SANDBOX │ ◄─── Entegrasyon & Test (Development)             │
│   └────┬────┘                                                   │
│        │                                                        │
│        │                                                        │
│   ┌────┴────────────────────────────────┐                       │
│   │  feature/*, bugfix/*, improvement/* │                       │
│   └─────────────────────────────────────┘                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Branch Tanımları

| Branch    | Ortam            | Amaç                             | Koruma Seviyesi |
|-----------|------------------|----------------------------------|-----------------|
| `main`    | Production       | Canlı ortamı temsil eder         | 🔴 En Yüksek    |
| `release` | Pre-Production   | Sürüm hazırlık ve son kontroller | 🟠 Yüksek       |
| `sandbox` | Development/Test | Entegrasyon ve test ortamı       | 🟡 Orta         |

---

## 🔄 Branch Akışları ve Kurallar

### 1. Sandbox Branch

```
┌──────────────────────────────────────────────────────────────┐
│                      SANDBOX KURALLARI                       │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ✅ Kabul Edilen PR Kaynakları:                              │
│     • feature/*                                              │
│     • bugfix/*                                               │
│                                                              │
│  ❌ Kabul Edilmeyen:                                         │
│     • Doğrudan commit                                        │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

#### 📖 Kurallar ve Politikalar

| Kural | Açıklama | Önem |
|-------|----------|------|
| **Kaynak Kısıtlaması** | Sandbox'a yalnızca `feature/*`, `bugfix/*` ve `improvement/*` branch'lerinden PR açılabilir. Diğer tüm kaynaklar pipeline tarafından otomatik reddedilir. | 🔴 Kritik |
| **Doğrudan Commit Yasağı** | Sandbox branch'ine doğrudan commit yapılamaz. Tüm değişiklikler PR sürecinden geçmelidir. Bu kural Azure DevOps branch policy ile zorlanır. | 🔴 Kritik |
| **Atlama Yasağı** | Sandbox atlanarak doğrudan Release veya Main'e geçiş yapılamaz. Bu, test edilmemiş kodun üretim ortamına geçmesini engeller. | 🔴 Kritik |
| **Otomatik Build** | Her başarılı merge işlemi sonrası CI/CD pipeline otomatik tetiklenir ve kod derlenir. | 🟡 Standart |

#### 📊 Sandbox Akış Şeması

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         SANDBOX AKIŞ DİYAGRAMI                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  📥 GİRİŞ (PR ile)                      📤 ÇIKIŞ (PR ile)               │
│  ─────────────────                      ──────────────────              │
│                                                                         │
│  ┌─────────────┐                        ┌─────────────┐                 │
│  │ feature/*   │────┐                   │   SANDBOX   │                 │
│  └─────────────┘    │                   └──────┬──────┘                 │
│                     │    ┌─────────┐           │                        │
│  ┌─────────────┐    ├───►│ SANDBOX │           │                        │
│  │ bugfix/*    │────┤    └─────────┘           ▼                        │
│  └─────────────┘    │         │          ┌─────────┐                    │
│                     │         │          │ RELEASE │ (Tek çıkış)        │
│  ┌─────────────┐    │         ▼          └─────────┘                    │
│  │improvement/*│────┘    🔨 BUILD                                       │
│  └─────────────┘         🧪 TEST                                        │
│                          🚀 DEPLOY                                      │
│                             (Dev)                                       │
│                                                                         │
│  ❌ YASAKLAR: main, release'den PR açılamaz                             │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

#### 📝 Çalışma Prensibi

Sandbox branch'i, tüm geliştirme aktivitelerinin entegre edildiği ve test edildiği merkezi noktadır. Geliştirme süreci şu şekilde işler:

**Adım 1 - Branch Oluşturma:** Geliştirici, `sandbox` branch'ini kaynak alarak yeni bir feature veya bugfix branch'i oluşturur. Branch isimlendirmesi `feature/ozellik-adi` veya `bugfix/hata-aciklamasi` formatında olmalıdır.

**Adım 2 - Geliştirme:** Kod değişiklikleri yapılır ve yerel ortamda test edilir. Commit mesajları açıklayıcı olmalı ve ilgili work item numarasını içermelidir.

**Adım 3 - Pull Request:** Geliştirme tamamlandığında `sandbox` branch'ine PR açılır. PR açıklaması değişiklikleri, test senaryolarını ve varsa breaking change'leri içermelidir.

**Adım 4 - Code Review:** En az 1 reviewer kodu inceleyip onaylamalıdır. Reviewer, kod kalitesi, test coverage ve best practice uyumunu kontrol eder.

**Adım 5 - Merge ve Deploy:** PR onaylandıktan sonra kod sandbox'a merge edilir. Bu işlem otomatik olarak Build pipeline'ını tetikler ve başarılı build sonrası kod Development ortamına deploy edilir.

**Adım 6 - Sonraki Aşama:** Sandbox'taki kod yeterli test sürecinden geçtikten sonra, Release branch'ine PR açılarak bir sonraki aşamaya taşınır.

### 2. Release Branch

```
┌──────────────────────────────────────────────────────────────┐
│                      RELEASE KURALLARI                        │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ✅ Kabul Edilen PR Kaynakları:                              │
│     • sandbox (test geçmiş kod)                              │
│     • hotfix/* (acil düzeltmeler)                            │
│                                                              │
│  ❌ Kabul Edilmeyen:                                         │
│     • feature/*                                              │
│     • bugfix/*                                               │
│     • Doğrudan commit                                        │
│                                                              │
│  📝 Kullanım Amacı:                                          │
│     • Sürüm hazırlığı                                        │
│     • Son kontroller                                         │
│     • UAT (User Acceptance Testing)                          │
│                                                              │
│  🗂️ Versiyon Politikası:                                     │
│     • Son 5 versiyon saklanır                                │
│     • Eski versiyonlar otomatik arşivlenir                   │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

#### 📖 Kurallar ve Politikalar

| Kural | Açıklama | Önem |
|-------|----------|------|
| **Kaynak Kısıtlaması** | Release'e yalnızca `sandbox` ve `hotfix/*` branch'lerinden PR açılabilir. Feature/bugfix branch'leri doğrudan Release'e geçemez. | 🔴 Kritik |
| **UAT Zorunluluğu** | Release ortamında User Acceptance Testing (UAT) yapılması zorunludur. UAT onayı olmadan Main'e geçiş yapılamaz. | 🔴 Kritik |
| **Versiyon Saklama** | Son 5 sürüm artifact olarak saklanır. Eski sürümler otomatik arşivlenir, rollback ihtiyacı için erişilebilir kalır. | 🟠 Önemli |
| **Sürüm Numaralandırma** | Her Release build'i otomatik olarak semantic versioning (MAJOR.MINOR.BUILD.REVISION) formatında numaralandırılır. | 🟡 Standart |

#### 📊 Release Akış Şeması

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         RELEASE AKIŞ DİYAGRAMI                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  📥 GİRİŞ (PR ile)                      📤 ÇIKIŞ (PR ile)               │
│  ─────────────────                      ──────────────────              │
│                                                                         │
│  ┌─────────────┐                        ┌─────────────┐                 │
│  │   SANDBOX   │────┐                   │   RELEASE   │                 │
│  └─────────────┘    │                   └──────┬──────┘                 │
│                     │    ┌─────────┐           │                        │
│                     ├───►│ RELEASE │           │                        │
│  ┌─────────────┐    │    └─────────┘           ▼                        │
│  │  hotfix/*   │────┘         │          ┌──────────┐                   │
│  └─────────────┘              │          │   MAIN   │ (Tek çıkış)       │
│                               ▼          └──────────┘                   │
│                          🔨 BUILD                                       │
│                          🧪 TEST                                        │
│                          🎯 DEPLOY                                      │
│                            (Staging)                                    │
│                                                                         │
│  ❌ YASAKLAR: feature/*, bugfix/* PR açamaz                             │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

#### 📝 Çalışma Prensibi

Release branch'i, production öncesi son kontrol noktasıdır. Staging/UAT ortamını temsil eder ve canlıya çıkmadan önce son testlerin yapıldığı yerdir.

**Adım 1 - Sandbox'tan Taşıma:** Development testlerini tamamlayan kod, `sandbox` branch'inden `release` branch'ine PR ile taşınır. PR açıklaması test sonuçlarını ve değişiklik listesini içermelidir.

**Adım 2 - Build ve Deploy:** PR merge edildikten sonra otomatik olarak Build pipeline tetiklenir. Başarılı build sonrası kod Staging ortamına deploy edilir.

**Adım 3 - UAT Testleri:** İş birimi kullanıcıları Staging ortamında kabul testlerini gerçekleştirir. Fonksiyonel testler, entegrasyon testleri ve performans testleri bu aşamada yapılır.

**Adım 4 - Onay ve İlerleme:** UAT testleri başarılı olduktan sonra `main` branch'ine PR açılır. Bu PR'ın onaylanması için minimum 2 reviewer gereklidir.

**Hotfix İstisnası:** Acil durumlarda `hotfix/*` branch'leri doğrudan Release'e PR açabilir. Bu, kritik düzeltmelerin hızlıca Staging ortamında test edilmesini sağlar.

### 3. Main Branch

```
┌──────────────────────────────────────────────────────────────┐
│                       MAIN KURALLARI                          │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ✅ Kabul Edilen PR Kaynakları:                              │
│     • release (normal sürümler)                              │
│     • hotfix/* (acil düzeltmeler)                            │
│                                                              │
│  ❌ Kabul Edilmeyen:                                         │
│     • feature/*                                              │
│     • bugfix/*                                               │
│     • sandbox                                                │
│     • Doğrudan commit                                        │
│                                                              │
│  📝 Kullanım Amacı:                                          │
│     • Canlı ortamı temsil eder                               │
│     • Production deployment kaynağı                          │
│     • Tek kaynak hakikati (Single Source of Truth)           │
│                                                              │
│  🔒 Güvenlik:                                                │
│     • Force push YASAKTIR                                    │
│     • Minimum 2 reviewer onayı gerekli                       │
│     • Build başarılı olmalı                                  │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

#### � Kurallar ve Politikalar

| Kural | Açıklama | Önem |
|-------|----------|------|
| **Kaynak Kısıtlaması** | Main'e yalnızca `release` ve `hotfix/*` branch'lerinden PR açılabilir. Diğer tüm branch'ler (feature, bugfix, sandbox) reddedilir. | 🔴 Kritik |
| **Çift Onay Zorunluluğu** | Her PR için minimum 2 reviewer onayı gereklidir. Tek reviewer onayı ile merge yapılamaz. Bu güvenlik katmanı canlı ortamı korur. | 🔴 Kritik |
| **Build Zorunluluğu** | PR merge edilmeden önce Build pipeline başarılı tamamlanmalıdır. Başarısız build ile merge engellenir. | 🔴 Kritik |
| **Force Push Yasağı** | Main branch'ine force push kesinlikle yasaktır. Geçmiş commit'ler korunmalı ve izlenebilirlik sağlanmalıdır. | 🔴 Kritik |
| **Back-Merge Otomasyonu** | Her Main merge sonrası otomatik olarak Release ve Sandbox branch'lerine back-merge yapılır. | 🟡 Standart |

#### �📊 Main Akış Şeması

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          MAIN AKIŞ DİYAGRAMI                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  📥 GİRİŞ (PR ile)                      📤 ÇIKIŞ (Otomatik)             │
│  ─────────────────                      ──────────────────              │
│                                                                         │
│  ┌─────────────┐                        ┌─────────────┐                 │
│  │   RELEASE   │────┐                   │    MAIN     │                 │
│  └─────────────┘    │                   └──────┬──────┘                 │
│                     │    ┌──────────┐          │                        │
│                     ├───►│   MAIN   │          │ Back-Merge             │
│  ┌─────────────┐    │    └──────────┘          │ (Otomatik)             │
│  │  hotfix/*   │────┘         │                ▼                        │
│  └─────────────┘              │          ┌─────────┐                    │
│                               ▼          │ RELEASE │───► SANDBOX        │
│                          🔨 BUILD        └─────────┘                    │
│                          🧪 TEST                                        │
│                          🌟 DEPLOY                                      │
│                          (Production)                                   │
│                                                                         │
│  ❌ YASAKLAR: feature/*, bugfix/*, sandbox PR açamaz                    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

#### 📝 Çalışma Prensibi

Main branch'i, canlı ortamı (Production) temsil eden ve "Single Source of Truth" (Tek Kaynak Hakikati) olarak kabul edilen en kritik branch'tir.

**Adım 1 - Release'den Taşıma:** UAT testlerini başarıyla tamamlayan kod, `release` branch'inden `main` branch'ine PR ile taşınır. PR açıklaması UAT onay bilgilerini, test raporlarını ve deployment notlarını içermelidir.

**Adım 2 - Çift Onay Süreci:** PR için minimum 2 reviewer'ın onayı gereklidir. Reviewer'lar kod kalitesi, güvenlik açıkları ve production hazırlığını kontrol eder. Tek onay ile merge yapılamaz.

**Adım 3 - Build ve Production Deploy:** PR merge edildikten sonra otomatik olarak Build, Test ve Production Deploy pipeline'ları tetiklenir. Deployment başarılı olana kadar süreç tamamlanmış sayılmaz.

**Adım 4 - Otomatik Back-Merge:** Production deployment tamamlandıktan sonra pipeline otomatik olarak back-merge işlemini başlatır. Main'deki değişiklikler sırasıyla Release ve Sandbox branch'lerine aktarılır. Bu sayede tüm branch'ler senkronize kalır ve conflict riski minimize edilir.

**Hotfix Senaryosu:** Canlı ortamda kritik bir hata tespit edildiğinde, `hotfix/*` branch'leri doğrudan Main'e PR açabilir. Bu durumda hızlı onay süreci (1 reviewer) uygulanabilir ve düzeltme acilen production'a alınır.

---

## 🚨 Hotfix Yönetimi

Hotfix branch'leri, canlı ortamda tespit edilen kritik hataların acil düzeltilmesi için kullanılır.

### Hotfix Akış Diyagramı

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           HOTFIX AKIŞI                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  1. HOTFIX OLUŞTURMA                                                    │
│     ┌──────┐                                                            │
│     │ MAIN │ ──────► git checkout -b hotfix/critical-fix                │
│     └──────┘                                                            │
│                                                                         │
│  2. HOTFIX GELİŞTİRME                                                   │
│     ┌────────────────────┐                                              │
│     │ hotfix/critical-fix │ ──────► Düzeltme yapılır & test edilir      │
│     └────────────────────┘                                              │
│                                                                         │
│  3. MAIN'E MERGE                                                        │
│     ┌──────┐     PR + Review + Build                                    │
│     │ MAIN │ ◄────────────────────── hotfix/critical-fix                │
│     └──────┘                                                            │
│                                                                         │
│  4. OTOMATİK SENKRONIZASYON (Back-Merge)                                │
│     ┌─────────┐                                                         │
│     │ RELEASE │ ◄──── Auto-merge from MAIN                              │
│     └─────────┘                                                         │
│          │                                                              │
│          ▼                                                              │
│     ┌─────────┐                                                         │
│     │ SANDBOX │ ◄──── Auto-merge from RELEASE                           │
│     └─────────┘                                                         │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

#### 📖 Kurallar ve Politikalar

| Kural | Açıklama | Önem |
|-------|----------|------|
| **Kaynak Zorunluluğu** | Hotfix branch'leri **yalnızca Main branch'inden** oluşturulabilir. Sandbox veya Release'den hotfix açılamaz. | 🔴 Kritik |
| **İsimlendirme Standardı** | Branch adı `hotfix/<açıklayıcı-isim>` formatında olmalıdır. Örnek: `hotfix/payment-null-reference`, `hotfix/login-timeout-fix` | 🟠 Önemli |
| **Minimum Değişiklik** | Hotfix yalnızca kritik hatayı düzelten minimum kod değişikliğini içermelidir. Yeni özellik veya refactoring yapılmamalıdır. | 🔴 Kritik |
| **Hızlı Onay** | Acil durumlar için 1 reviewer onayı yeterlidir. Normal PR sürecindeki 2 reviewer zorunluluğu hotfix için esnetilir. | 🟡 Standart |
| **Dokümantasyon** | Her hotfix için incident ticket veya bug report numarası PR açıklamasında belirtilmelidir. | 🟠 Önemli |

#### 📝 Çalışma Prensibi

Hotfix süreci, canlı ortamda tespit edilen kritik hataların en hızlı şekilde düzeltilmesi için tasarlanmış özel bir akıştır. Normal geliştirme sürecini atlayarak doğrudan production'a müdahale imkanı sağlar.

**Adım 1 - Incident Tespiti:** Canlı ortamda kritik bir hata tespit edilir. Hata, kullanıcı deneyimini ciddi şekilde etkileyen, güvenlik açığı oluşturan veya sistemin çalışmasını engelleyen türde olmalıdır.

**Adım 2 - Hotfix Branch Oluşturma:** `main` branch'inden yeni bir hotfix branch'i oluşturulur:
```bash
git checkout main
git pull origin main
git checkout -b hotfix/kritik-hata-aciklamasi
```

**Adım 3 - Düzeltme ve Test:** Minimum düzeltme yapılır ve yerel ortamda test edilir. Düzeltme yalnızca hatayı gidermeli, başka değişiklik içermemelidir.

**Adım 4 - PR ve Onay:** `main` branch'ine PR açılır. Acil durumda 1 reviewer onayı yeterlidir. PR açıklamasında incident ticket numarası ve etki analizi belirtilmelidir.

**Adım 5 - Production Deploy:** PR merge edildikten sonra otomatik olarak production deployment tetiklenir. Düzeltme canlı ortama alınır.

**Adım 6 - Otomatik Back-Merge:** Pipeline otomatik olarak back-merge başlatır:
- Main → Release: Hotfix kodu release'e aktarılır
- Release → Sandbox: Hotfix kodu sandbox'a aktarılır

Bu sayede tüm branch'ler güncel kalır ve geliştiricilerin çalışmaları hotfix ile çakışmaz.

---

## 👨‍💻 Yazılımcı Rehberi

### Yeni Özellik Geliştirme

```bash
# 1. Sandbox'tan feature branch oluştur
git checkout sandbox
git pull origin sandbox
git checkout -b feature/yeni-ozellik

# 2. Geliştirme yap
# ... kod değişiklikleri ...

# 3. Commit ve push
git add .
git commit -m "[FEATURE] Yeni özellik eklendi"
git push origin feature/yeni-ozellik

# 4. Azure DevOps'ta Sandbox'a PR aç
# 5. Code review ve onay al
# 6. Merge et
```

### Bug Düzeltme

```bash
# 1. Sandbox'tan bugfix branch oluştur
git checkout sandbox
git pull origin sandbox
git checkout -b bugfix/hata-aciklamasi

# 2. Düzeltme yap ve test et
# ... kod değişiklikleri ...

# 3. Commit ve push
git add .
git commit -m "[BUGFIX] Hata düzeltildi: açıklama"
git push origin bugfix/hata-aciklamasi

# 4. Sandbox'a PR aç
```

### Hotfix (Acil Düzeltme)

```bash
# 1. MAIN'den hotfix branch oluştur (ÖNEMLİ!)
git checkout main
git pull origin main
git checkout -b hotfix/kritik-duzeltme

# 2. Hızlı düzeltme yap
# ... minimum değişiklik ...

# 3. Commit ve push
git add .
git commit -m "[HOTFIX] Kritik hata düzeltildi: açıklama"
git push origin hotfix/kritik-duzeltme

# 4. MAIN'e PR aç (1 reviewer yeterli)
# 5. Merge sonrası otomatik back-merge başlar
```

### Branch Durumu Kontrolü

```bash
# Hangi branch'tesin?
git branch

# Tüm branch'leri gör
git branch -a

# Güncel branch'leri çek
git fetch --all --prune
```

