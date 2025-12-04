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
TG_BOT_TOKEN="ISI_TOKEN_KAMU"
TG_CHAT_ID="ISI_CHAT_ID_KAMU"

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

TG_BOT_TOKEN="ISI_TOKEN_KAMU"
TG_CHAT_ID="ISI_CHAT_ID_KAMU"

send_account_to_telegram() {
    local PASS="$1"
    local EXP="$2"
    local SERVER="zivpn.skuylan.my.id"

    TEXT="<b>✅ AKUN BERHASIL DIBUAT</b>
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
        fi
    done
}

menu() {
    clear
    sync_accounts
    auto_remove_expired

    echo "===================================="
    echo "     ZIVPN UDP ACCOUNT MANAGER"
    echo "===================================="
    echo "1) Lihat akun UDP"
    echo "2) Tambah akun baru"
    echo "3) Hapus akun"
    echo "4) Restart layanan"
    echo "0) Keluar"
    echo "===================================="
    read -rp "Pilih: " choice

    case $choice in
        1) jq -r '.accounts[] | "• \(.user) | Exp: \(.expired)"' "$META_FILE"; read -rp "Enter..." ;;
        2) add_account ;;
        3) delete_account ;;
        4) systemctl restart "$SERVICE_NAME"; menu ;;
        0) exit 0 ;;
        *) menu ;;
    esac
    menu
}

add_account() {
    read -rp "Password baru: " new_pass
    read -rp "Berlaku (hari): " days
    exp_date=$(date -d "+$days days" +%Y-%m-%d)

    jq --arg pass "$new_pass" '.auth.config += [$pass]' "$CONFIG_FILE" > /tmp/conf.tmp && mv /tmp/conf.tmp "$CONFIG_FILE"
    jq --arg user "$new_pass" --arg expired "$exp_date" '.accounts += [{"user":$user,"expired":$expired}]' "$META_FILE" > /tmp/meta.tmp && mv /tmp/meta.tmp "$META_FILE"

    systemctl restart "$SERVICE_NAME"
    send_account_to_telegram "$new_pass" "$exp_date"
}

delete_account() {
    read -rp "Password hapus: " del_pass
    jq --arg pass "$del_pass" '.auth.config |= map(select(. != $pass))' "$CONFIG_FILE" > /tmp/conf.tmp && mv /tmp/conf.tmp "$CONFIG_FILE"
    jq --arg pass "$del_pass" '.accounts |= map(select(.user != $pass))' "$META_FILE" > /tmp/meta.tmp && mv /tmp/meta.tmp "$META_FILE"
    systemctl restart "$SERVICE_NAME"
}

menu
EOF

# Create shortcut zivpn
cat <<EOF > "$SHORTCUT"
#!/bin/bash
sudo $MANAGER_SCRIPT
EOF

chmod +x "$MANAGER_SCRIPT" "$SHORTCUT"

echo "===================================="
echo "ZIVPN Manager terinstall!"
echo "Jalankan dengan: zivpn"
echo "===================================="
