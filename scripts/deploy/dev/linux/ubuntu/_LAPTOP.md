# Notebook (Laptop)

## Dev Environment

### CPU

### Memory

### SSD

### Display

* 화면 꺼짐(절전) 안 함으로 설정:

```bash
gsettings set org.gnome.desktop.session idle-delay 0
```

* 화면 자동 잠금 해제:

```bash
gsettings set org.gnome.desktop.screensaver lock-enabled false
```

* 설정 상태 확인:

```bash
gsettings get org.gnome.desktop.session idle-delay
```

* 서버 환경이나 디스플레이 없이 켜두는 경우
만약 노트북 덮개를 닫아도 절전 모드로 들어가지 않게 하려면 /etc/systemd/logind.conf 파일에서 HandleLidSwitch=ignore 옵션을 수정해 주어야 합니다.
