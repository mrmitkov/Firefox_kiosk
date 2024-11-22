#!/bin/bash
# First Boot Configuration Script, created by 'Mitkov M. R.'
# Log file per monitorare l'esecuzione dello script
LOG_FILE="/var/log/first_boot_config.log"

# Funzione per loggare messaggi
log_msg() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_msg "Inizio configurazione al primo avvio"

# Step 1: Installazione pacchetti base
log_msg "Aggiornamento del sistema e installazione pacchetti"
apt-get update && apt-get upgrade -y >> "$LOG_FILE" 2>&1 || log_msg "Errore durante apt-get update/upgrade"
apt-get install -y xorg openbox firefox snmpd vim raspi-config network-manager >> "$LOG_FILE" 2>&1 || log_msg "Errore durante l'installazione dei pacchetti"

# Step 2: Configurazione X11
log_msg "Configurazione X11"
mkdir -p /etc/X11/xorg.conf.d
cat > /etc/X11/xorg.conf.d/10-monitor.conf << EOF
Section "Monitor"
    Identifier "Monitor0"
    Option "DPMS" "false"
EndSection

Section "ServerLayout"
    Identifier "ServerLayout0"
    Option "BlankTime" "0"
    Option "StandbyTime" "0"
    Option "SuspendTime" "0"
    Option "OffTime" "0"
EndSection
EOF

# Step 3: Configurazione Kiosk
log_msg "Configurazione del Kiosk Mode"
mkdir -p /opt/kiosk
cat > /opt/kiosk/kiosk.sh << 'EOF'
#!/bin/bash
pw_url="https://www.time.is/"
xset s off
xset -dpms
openbox-session &
while true; do
  x=$(xrandr --current | grep -w connected | awk '{ print $3 }')
  w=${x%%x*}
  h=${x#*x};h=${h%%+*}
  /usr/bin/firefox --kiosk --height $h --width $w --private-window $pw_url
done
EOF
chmod +x /opt/kiosk/kiosk.sh

# Creazione del servizio systemd per il Kiosk
log_msg "Creazione del servizio systemd per il Kiosk Mode"
cat > /etc/systemd/system/kiosk.service << EOF
[Unit]
Description=Start kiosk
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/startx /etc/X11/Xsession /opt/kiosk/kiosk.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF
chmod 644 /etc/systemd/system/kiosk.service
systemctl daemon-reload >> "$LOG_FILE" 2>&1
systemctl enable kiosk >> "$LOG_FILE" 2>&1

# Conclusione
log_msg "Setup completato. Puoi controllare il log in $LOG_FILE"
echo "Setup completato. Riavvia il sistema per applicare le configurazioni."
