# 🚀 Azure DevOps Branch & Pipeline Strategy

Bu repository, profesyonel bir Azure DevOps CI/CD altyapısı için gerekli tüm pipeline yapılandırmalarını ve dokümantasyonu içermektedir.

## 📁 Klasör Yapısı

```
├── azure-pipelines/
│   ├── ci-pipeline.yml              # Ana CI/CD pipeline
│   ├── hotfix-sync-pipeline.yml     # Hotfix sonrası auto-sync
│   ├── branch-cleanup-pipeline.yml  # Branch temizleme (haftalık)
│   ├── pr-validation-pipeline.yml   # PR doğrulama
│   └── templates/
│       ├── build-template.yml       # Build adımları template
│       ├── notification-template.yml # Bildirim template
│       └── version-template.yml     # Versiyon yönetimi
├── scripts/
│   └── branch-cleanup.ps1           # Manuel cleanup script
├── docs/
│   ├── BRANCHING-STRATEGY.md        # Branch stratejisi
│   ├── BRANCH-NAMING-CONVENTION.md  # İsimlendirme kuralları
│   ├── FEATURE-BRANCH-WORKFLOW.md   # Feature workflow
│   └── CHECKLIST.md                 # Setup checklist
└── README.md
```

## 🌿 Branch Yapısı

```
main (production) ← release (UAT) ← sandbox (dev) ← feature/*
```

## 🔄 Akış Kuralları

| Source | Target | İzin |
|--------|--------|------|
| feature/* | sandbox | ✅ |
| bugfix/* | sandbox | ✅ |
| sandbox | release | ✅ |
| release | main | ✅ |
| hotfix/* | main | ✅ |
| feature/* | main | ❌ |

## 🚀 Hızlı Başlangıç

1. Bu dosyaları projenize kopyalayın
2. Azure DevOps'ta pipeline'ları oluşturun
3. Branch policy'leri yapılandırın
4. Variable groups oluşturun

## 📚 Dokümantasyon

Detaylı bilgi için `docs/` klasörüne bakın.

## 📞 Destek

Sorularınız için issue açabilirsiniz.