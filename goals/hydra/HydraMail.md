Option 1: Desktop Mail Client Automation (Truly Local)
APPROACH:
─────────
Control user's existing mail app directly.

macOS:
├── AppleScript → Apple Mail
├── osascript commands
└── No API, no internet dependency (mail client handles sending)

Windows:
├── COM automation → Outlook
├── PowerShell commands
└── Uses user's existing Outlook account

Linux:
├── D-Bus → Thunderbird/Evolution
└── Command line tools

EXAMPLE (macOS):
────────────────
osascript -e '
tell application "Mail"
    set newMessage to make new outgoing message with properties {
        subject:"Report Ready",
        content:"Your report is attached.",
        visible:true
    }
    tell newMessage
        make new to recipient at end of to recipients with properties {
            address:"recipient@example.com"
        }
    end tell
    send newMessage
end tell
'

HYDRA INTEGRATION:
──────────────────
hydra_core/
├── action_fabric/
│   └── mail_driver/
│       ├── apple_mail_adapter/    # macOS
│       ├── outlook_adapter/       # Windows
│       └── thunderbird_adapter/   # Linux
Cost: ZERO API. Uses user's existing email account.

Option 2: Browser Automation (Webmail)
APPROACH:
─────────
Open Gmail/Outlook web UI and send through browser.

FLOW:
─────
1. Open browser to mail.google.com
2. Click "Compose"
3. Fill To, Subject, Body
4. Click Send

This is "protocol hunting" for email.

HYDRA INTEGRATION:
──────────────────
hydra_core/
├── action_fabric/
│   └── ui_driver/
│       └── webmail/
│           ├── gmail_driver/
│           ├── outlook_web_driver/
│           └── protonmail_driver/
Cost: ZERO API. Uses user's existing webmail session.

Option 3: Local SMTP with User Credentials
APPROACH:
─────────
Send via SMTP directly, using user's email credentials.

REQUIREMENTS:
─────────────
- User provides: email, password (or app password)
- Hydra stores securely in Identity (.aid)
- Sends via standard SMTP protocol

CODE:
─────
# Python example (no external API)
import smtplib
from email.mime.text import MIMEText

msg = MIMEText("Your report is ready.")
msg['Subject'] = "Report Ready"
msg['From'] = "user@gmail.com"
msg['To'] = "recipient@example.com"

# Connect to Gmail's SMTP (user's own account)
with smtplib.SMTP_SSL('smtp.gmail.com', 465) as server:
    server.login("user@gmail.com", "app_password")
    server.send_message(msg)

HYDRA INTEGRATION:
──────────────────
hydra_core/
├── action_fabric/
│   └── mail_driver/
│       └── smtp_direct/
│           ├── credential_store/   # Encrypted in .aid
│           ├── smtp_sender/        # Direct SMTP
│           └── provider_configs/   # Gmail, Outlook, etc. settings
Cost: ZERO API. Standard SMTP protocol.

Option 4: Self-Hosted Mail Server (Full Control)
APPROACH:
─────────
User runs their own mail server.

SETUP:
──────
- Postfix/Sendmail on user's server
- Proper DNS (MX, SPF, DKIM, DMARC)
- Hydra sends to localhost SMTP

WHEN USEFUL:
────────────
- Enterprise/self-hosted setups
- Privacy-focused users
- Full control over mail delivery

HYDRA INTEGRATION:
──────────────────
Same as Option 3, but pointing to localhost:25
Cost: ZERO external API. Full sovereignty.

Comparison
METHOD                  API COST    SETUP          RELIABILITY
────────────────────────────────────────────────────────────────
Desktop Mail App        $0          None           High (uses existing)
Browser Webmail         $0          None           Medium (UI can change)
Direct SMTP             $0          Credentials    High
Self-Hosted             $0          Complex        High (if configured right)
────────────────────────────────────────────────────────────────
SendGrid/Mailgun API    $$$         API key        High

My Recommendation for Hydra
PRIMARY: Desktop Mail Client Automation
─────────────────────────────────────────
- Truly zero setup for user
- Uses their existing account
- No credentials to store
- Works offline (queues until online)

FALLBACK: Direct SMTP
─────────────────────
- If no desktop client
- User provides credentials once
- Stored encrypted in .aid

ENTERPRISE: Self-Hosted Integration
───────────────────────────────────
- For companies with own mail servers
- Configure once, works forever

Hydra Mail Architecture
hydra_core/
├── action_fabric/
│   └── mail_driver/
│       ├── detector/
│       │   ├── detect_mail_client/     # What's installed?
│       │   ├── detect_webmail_session/ # Logged into Gmail?
│       │   └── detect_smtp_config/     # Credentials available?
│       │
│       ├── desktop_adapters/
│       │   ├── apple_mail/             # macOS
│       │   ├── outlook_desktop/        # Windows
│       │   └── thunderbird/            # Linux
│       │
│       ├── webmail_adapters/
│       │   ├── gmail_web/
│       │   ├── outlook_web/
│       │   └── protonmail_web/
│       │
│       ├── smtp_direct/
│       │   ├── credential_manager/     # Encrypted storage
│       │   ├── smtp_sender/            # Send via SMTP
│       │   └── provider_presets/       # Gmail, Outlook, etc.
│       │
│       └── router/
│           ├── best_method_selector/   # Pick best available
│           ├── fallback_chain/         # If primary fails
│           └── approval_gate/          # Confirm before send

The Flow
User: "Send the report to john@example.com"

HYDRA:
1. Detect available methods:
   ✓ Apple Mail installed
   ✓ Gmail session in browser
   ✓ No SMTP credentials stored

2. Select best: Apple Mail (most reliable, truly local)

3. Show approval:
   ⚠ Approval required: SEND_EMAIL
   To: john@example.com
   Subject: Report
   Via: Apple Mail (local)
   
   Approve? [y/n]

4. Execute via AppleScript

5. Receipt:
   {
     "action": "send_email",
     "method": "apple_mail_local",
     "api_cost": "$0.00",
     "status": "sent"
   }

Answer
CAN HYDRA SEND EMAIL WITHOUT API?
─────────────────────────────────
YES.

Methods (all zero API cost):
- Desktop mail client automation
- Browser webmail automation  
- Direct SMTP with user credentials
- Self-hosted mail server

Recommended: Desktop client automation (zero setup, zero API)
