# GitHub'a Yükleme Talimatları

## 1. Değişiklikleri Stage Et

```bash
git add .
```

## 2. Commit Yap

```bash
git commit -m "Initial commit: Patient Monitoring App with real-time sensor data"
```

veya daha detaylı:

```bash
git commit -m "Add Patient Monitoring App

- Real-time sensor data monitoring (posture, pressure, battery)
- Modern UI with color-coded alerts
- Windows startup script for automated setup
- Express server for Arduino serial communication
- Cross-platform support (iOS, Android, Web)"
```

## 3. GitHub'da Yeni Repository Oluştur

1. GitHub'a giriş yapın: https://github.com
2. Sağ üstteki "+" butonuna tıklayın
3. "New repository" seçin
4. Repository adını girin (örn: `PatientMonitoringApp`)
5. Açıklama ekleyin (opsiyonel)
6. Public veya Private seçin
7. **"Initialize this repository with a README" seçmeyin** (zaten README var)
8. "Create repository" butonuna tıklayın

## 4. Remote Repository Ekle

GitHub'da oluşturduğunuz repository'nin URL'ini kopyalayın ve şu komutu çalıştırın:

```bash
git remote add origin https://github.com/KULLANICI_ADI/REPO_ADI.git
```

Örnek:
```bash
git remote add origin https://github.com/yourusername/PatientMonitoringApp.git
```

## 5. GitHub'a Push Et

```bash
git branch -M main
git push -u origin main
```

## Alternatif: SSH Kullanıyorsanız

Eğer SSH key kullanıyorsanız:

```bash
git remote add origin git@github.com:KULLANICI_ADI/REPO_ADI.git
git push -u origin main
```

## Sorun Giderme

### Eğer "remote origin already exists" hatası alırsanız:

```bash
git remote remove origin
git remote add origin https://github.com/KULLANICI_ADI/REPO_ADI.git
```

### Eğer "failed to push" hatası alırsanız:

```bash
git pull origin main --allow-unrelated-histories
git push -u origin main
```

## Sonraki Adımlar

1. GitHub repository sayfasında "Settings" > "Pages" ile GitHub Pages'i aktif edebilirsiniz
2. "Issues" ve "Projects" ile proje yönetimi yapabilirsiniz
3. "Actions" ile CI/CD pipeline'ları ekleyebilirsiniz

