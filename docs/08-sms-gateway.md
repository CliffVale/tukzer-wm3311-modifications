# 08 — SMS Gateway (Requires SIM)

## Overview

Tools and scripts for sending and receiving SMS using Android's telephony framework. Requires a SIM card to be inserted.

## Prerequisites

- SIM card inserted in slot 1 or 2 (dual SIM, dsds)
- Radio is active (rild + qmuxd are already running)
- Service: ISms (com.android.internal.telephony.ISms) is registered

## Approach

Three methods for SMS:

1. Android Binder — service call isms for sending SMS from shell
2. BeanShell script — Runs inside Webkey, calls SmsManager API
3. Shell tools — Wrapper scripts for common SMS operations

## Method 1: Android Binder

service command can invoke the ISms interface:

```bash
service list | grep isms
# 10 isms: [com.android.internal.telephony.ISms]

service call isms 1 \
  s16 "com.android.shell" \
  s16 "+1234567890" \
  s16 "" \
  s16 "Hello from Tukzer" \
  i32 0 i32 0
```

## Method 2: BeanShell Script (Webkey)

The Webkey framework supports BeanShell (.bsh) scripts:

```java
// sms.bsh — http://192.168.42.129/sms.bsh?number=999&message=Hello
import android.telephony.SmsManager;

String number = request.getParameter("number");
String message = request.getParameter("message");

try {
    SmsManager sms = SmsManager.getDefault();
    sms.sendTextMessage(number, null, message, null, null);
    out.println("{\"status\":\"sent\",\"to\":\"" + number + "\"}");
} catch (Exception e) {
    out.println("{\"error\":\"" + e.toString() + "\"}");
}
```

## Method 3: Shell SMS Tool

```bash
sms-tool.sh send 999 "Hello"    # Send SMS
sms-tool.sh list                # List inbox/sent
```

## Content Provider Access

```bash
content query --uri content://sms/inbox
content query --uri content://sms/sent
```

## Finding Transaction Codes

If service call isms 1 does not work, probe codes:

```bash
for code in 1 2 3 4 5 6 7 8 9 10; do
    result=$(service call isms $code 2>&1)
    echo "Code $code: $result"
done
```

## SIM Status

```bash
getprop gsm.sim.state
getprop gsm.operator.alpha
```
