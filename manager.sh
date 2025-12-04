#!/bin/bash
# ============================
# ZIVPN Manager Full + Telegram Backup
# Final Version (No Color)
# Shortcut: zivpn
# Author: Harun & GPT-5
# ============================

CONFIG_FILE="/etc/zivpn/config.json"
META_FILE="/etc/zivpn/accounts_meta.json"
SERVICE_NAME="zivpn.service"
MANAGER_SCRIPT="/usr/local/bin/zivpn-manager.sh"
SHORTCUT="/usr/local/bin/zivpn"

# Telegram Config
TG_BOT_TOKEN="8470709706:AAFb0Nus3Sb8q0ooO0wQ4wH4IW5UeqiWyTo"
TG_CHAT_ID="413682138"

# Create directory & default files
mkdir -p /etc/zivpn
[ ! -f "$CONFIG_FILE" ] && echo '{"auth":{"config":[]}, "listen":":5667"}' > "$CONFIG_FILE"
[ ! -f "$META_FILE" ] && echo '{"accounts":[]}' > "$META_FILE"

# Delete old scripts
[ -f "$MANAGER_SCRIPT" ] && rm -f "$MANAGER_SCRIPT"
[ -f "$SHORTCUT" ] && rm -f "$SHORTCUT"

# Write manager script
cat <<'EOF' > "$MANAGER_SCRIPT"
#!/bin/bash
CONFIG_FILE="/etc/zivpn/config.json"
META_FILE="/etc/zivpn/accounts_meta.json"
SERVICE_NAME="zivpn.service"

TG_BOT_TOKEN="8470709706:AAFb0Nus3Sb8q0ooO0wQ4wH4IW5UeqiWyTo"
TG_CHAT_ID="413682138"
send_account_to_telegram() {
    local PASS="$1"
    local EXP="$2"
    local SERVER="zivpn.skuylan.my.id"

    TEXT="<b>✅ AKUN VERHASIL DIBUAT</b>
━━━━━━━━━━━━━━━━━━
<b>🌐 Server :</b> <code>$SERVER</code>
<b>🔐 Password :</b> <code>$PASS</code>
<b>⏳ Expired :</b> <b>$EXP</b>
━━━━━━━━━━━━━━━━━━
<b>Terima kasih telah menggunakan layanan ZIVPN</b> 🚀"

    curl -s -X POST "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage" \
        -d chat_id="$TG_CHAT_ID" \
        -d parse_mode="HTML" \
        --data-urlencode text="$TEXT" >/dev/null
}
[ ! -f "$META_FILE" ] && echo '{"accounts":[]}' > "$META_FILE"

sync_accounts() {
    for pass in $(jq -r ".auth.config[]" "$CONFIG_FILE"); do
        exists=$(jq -r --arg u "$pass" ".accounts[]?.user // empty | select(.==\$u)" "$META_FILE")
        [ -z "$exists" ] && jq --arg user "$pass" --arg exp "2099-12-31" \
            ".accounts += [{\"user\":\$user,\"expired\":\$exp}]" "$META_FILE" > /tmp/meta.tmp && mv /tmp/meta.tmp "$META_FILE"
    done
}

auto_remove_expired() {
    today=$(date +%s)
    jq -c ".accounts[]" "$META_FILE" | while read -r acc; do
        user=$(echo "$acc" | jq -r ".user")
        exp=$(echo "$acc" | jq -r ".expired")
        exp_epoch=$(date -d "$exp" +%s 2>/dev/null)

        if [ "$today" -ge "$exp_epoch" ]; then
            jq --arg user "$user" '.auth.config |= map(select(. != $user))' "$CONFIG_FILE" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG_FILE"
            jq --arg user "$user" '.accounts |= map(select(.user != $user))' "$META_FILE" > /tmp/meta.tmp && mv /tmp/meta.tmp "$META_FILE"
            systemctl restart "$SERVICE_NAME" >/dev/null 2>&1
            echo "Auto remove expired: $user"
        fi
    done
}

send_backup_telegram() {
    BACKUP_DIR="/etc/zivpn"
    [ ! -f "$BACKUP_DIR/backup_config.json" ] && return
    [ ! -f "$BACKUP_DIR/backup_meta.json" ] && return

    echo "Mengirim backup ke Telegram..."
    curl -s -F chat_id=$TG_CHAT_ID -F document=@$BACKUP_DIR/backup_config.json https://api.telegram.org/bot$TG_BOT_TOKEN/sendDocument
    curl -s -F chat_id=$TG_CHAT_ID -F document=@$BACKUP_DIR/backup_meta.json https://api.telegram.org/bot$TG_BOT_TOKEN/sendDocument
    echo "Backup terkirim."
}

backup_accounts() {
    BACKUP_DIR="/etc/zivpn"
    cp "$CONFIG_FILE" "$BACKUP_DIR/backup_config.json"
    cp "$META_FILE" "$BACKUP_DIR/backup_meta.json"
    send_backup_telegram
    read -rp "Enter..." enter
    menu
}

restore_accounts() {
    BACKUP_DIR="/etc/zivpn"
    if [ ! -f "$BACKUP_DIR/backup_config.json" ] || [ ! -f "$BACKUP_DIR/backup_meta.json" ]; then
        echo "Backup tidak ada!"
        read -rp "Enter..." enter
        menu
    fi
    cp "$BACKUP_DIR/backup_config.json" "$CONFIG_FILE"
    cp "$BACKUP_DIR/backup_meta.json" "$META_FILE"
    systemctl restart "$SERVICE_NAME"
    echo "Restore selesai."
    read -rp "Enter..." enter
    menu
}

menu() {
    clear
    sync_accounts
    auto_remove_expired

    echo "===================================="
    echo "     ZIVPN UDP ACCOUNT MANAGER"
    echo "===================================="

    VPS_IP=$(curl -s ifconfig.me || echo "Tidak ditemukan")
    echo "IP VPS       : ${VPS_IP}"

    ISP_NAME=$(curl -s https://ipinfo.io/org || echo "Tidak ditemukan")
    echo "ISP          : ${ISP_NAME}"

    NET_IFACE=$(ip route | awk '/default/ {print $5}' | head -n1)

    BW_DAILY_DOWN=$(vnstat -i "$NET_IFACE" --json | jq -r '.interfaces[0].traffic.day[-1].rx')
    BW_DAILY_UP=$(vnstat -i "$NET_IFACE" --json | jq -r '.interfaces[0].traffic.day[-1].tx')

    BW_MONTH_DOWN=$(vnstat -i "$NET_IFACE" --json | jq -r '.interfaces[0].traffic.month[-1].rx')
    BW_MONTH_UP=$(vnstat -i "$NET_IFACE" --json | jq -r '.interfaces[0].traffic.month[-1].tx')

# Konversi dari byte ke MB
    BW_DAILY_DOWN=$(awk -v b=$BW_DAILY_DOWN 'BEGIN {printf "%.2f MB", b/1024/1024}')
    BW_DAILY_UP=$(awk -v b=$BW_DAILY_UP 'BEGIN {printf "%.2f MB", b/1024/1024}')
    BW_MONTH_DOWN=$(awk -v b=$BW_MONTH_DOWN 'BEGIN {printf "%.2f MB", b/1024/1024}')
    BW_MONTH_UP=$(awk -v b=$BW_MONTH_UP 'BEGIN {printf "%.2f MB", b/1024/1024}')

    echo "Daily        : D $BW_DAILY_DOWN | U $BW_DAILY_UP"
    echo "Monthly      : D $BW_MONTH_DOWN | U $BW_MONTH_UP"
    echo "===================================="

    echo "1) Lihat akun UDP"
    echo "2) Tambah akun baru"
    echo "3) Hapus akun"
    echo "4) Restart layanan"
    echo "5) Status VPS"
    echo "6) Backup + Telegram"
    echo "7) Restore akun"
    echo "0) Keluar"
    echo "===================================="
    read -rp "Pilih: " choice

    case $choice in
        1) list_accounts ;;
        2) add_account ;;
        3) delete_account ;;
        4) restart_service ;;
        5) vps_status ;;
        6) backup_accounts ;;
        7) restore_accounts ;;
        0) exit 0 ;;
        *) menu ;;
    esac
}

list_accounts() {
    today=$(date +%s)
    jq -c ".accounts[]" "$META_FILE" | while read -r acc; do
        user=$(echo "$acc" | jq -r ".user")
        exp=$(echo "$acc" | jq -r ".expired")
        exp_ts=$(date -d "$exp" +%s 2>/dev/null)
        status="Aktif"
        [ "$today" -ge "$exp_ts" ] && status="Expired"
        echo "• $user | Exp: $exp | $status"
    done
    read -rp "Enter..." enter
    menu
}

add_account() {
    read -rp "Password baru: " new_pass
    [ -z "$new_pass" ] && menu

    read -rp "Berlaku (hari): " days
    [[ -z "$days" ]] && days=3

    exp_date=$(date -d "+$days days" +%Y-%m-%d)

    jq --arg pass "$new_pass" '.auth.config |= . + [$pass]' "$CONFIG_FILE" > /tmp/conf.tmp && mv /tmp/conf.tmp "$CONFIG_FILE"
    jq --arg user "$new_pass" --arg expired "$exp_date" '.accounts += [{"user":$user,"expired":$expired}]' "$META_FILE" > /tmp/meta.tmp && mv /tmp/meta.tmp "$META_FILE"

    systemctl restart "$SERVICE_NAME"

    send_account_to_telegram "$new_pass" "$exp_date"

    echo "$new_pass ditambahkan."
    read -rp "Tekan ENTER untuk kembali ke menu..." enter
    menu
}

delete_account() {
    read -rp "Password hapus: " del_pass
    jq --arg pass "$del_pass" '.auth.config |= map(select(. != $pass))' "$CONFIG_FILE" > /tmp/conf.tmp && mv /tmp/conf.tmp "$CONFIG_FILE"
    jq --arg pass "$del_pass" '.accounts |= map(select(.user != $pass))' "$META_FILE" > /tmp/meta.tmp && mv /tmp/meta.tmp "$META_FILE"
    systemctl restart "$SERVICE_NAME"
    echo "$del_pass dihapus."
    menu
}

restart_service() {
    systemctl restart "$SERVICE_NAME"
    sleep 1
    menu
}

vps_status() {
    echo "Uptime      : $(uptime -p)"
    echo "CPU Usage   : $(top -bn1 | grep Cpu | awk '{print $2 + $4 "%"}')"
    echo "RAM Usage   : $(free -h | awk '/Mem:/ {print $3 " / " $2}')"
    echo "Disk Usage  : $(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')"
    read -rp "Enter..." enter
    menu
}

menu
EOF

# Create shortcut
cat <<EOF > "$SHORTCUT"
#!/bin/bash
sudo $MANAGER_SCRIPT
EOF

chmod +x "$MANAGER_SCRIPT" "$SHORTCUT"

echo "===================================="
echo "ZIVPN Manager terinstall!"
echo "Jalankan dengan:  zivpn"
echo "===================================="
