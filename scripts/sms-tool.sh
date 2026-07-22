#!/system/xbin/ash
# sms-tool.sh - SMS helper for Tukzer WM3311
# Usage: sms-tool.sh send NUMBER MESSAGE | list

SMS_SEND() {
    local NUM="$1"
    local MSG="$2"
    echo "Sending SMS to $NUM..."
    service call isms 1 s16 "com.android.shell" s16 "$NUM" s16 "" s16 "$MSG" i32 0 i32 0
    echo "Done"
}

SMS_LIST() {
    echo "=== Inbox ==="
    content query --uri content://sms/inbox 2>/dev/null || echo "No inbox access (needs SIM or root)"
    echo ""
    echo "=== Sent ==="
    content query --uri content://sms/sent 2>/dev/null || echo "No sent items"
}

case "$1" in
    send) SMS_SEND "$2" "$3" ;;
    list) SMS_LIST ;;
    *) echo "Usage: sms-tool.sh send NUMBER MESSAGE | list" ;;
esac
