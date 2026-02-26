# EDGE CASE HANDLERS SPECIFICATION

> **Status:** Canonical
> **Version:** 1.0
> **Date:** February 2026

---

## Executive Summary

This document specifies how Hydra handles edge cases that can cause agent failures in production. Each edge case includes detection, handling, and recovery strategies.

### Categories

```
1. RUN LIFECYCLE          → Crashes, duplicates, stuck runs
2. APPROVAL & CONSENT     → Lost prompts, wrong approvals, voice errors
3. CAPABILITY & POLICY    → Drift, conflicts, troubleshooting
4. BROWSER AUTOMATION     → Login, UI changes, CAPTCHAs
5. PROTOCOL HUNTING       → CSRF, auth flows, websockets
6. TERMINAL & SYSTEM      → Dangerous commands, hangs, secrets
7. FILES & DIFFS          → Binary, large files, conflicts
8. ARTIFACT GRAPH         → Duplicates, contradictions, privacy
9. OBSERVABILITY          → Chain breaks, ordering, missing evidence
10. TOKEN & COST          → Bloat, cache issues, tracking
11. VOICE                 → False triggers, spoofing, multi-user
12. FEDERATION            → Unsigned modules, loops, rate limits
```

---

## 1. RUN LIFECYCLE EDGE CASES

### 1.1 Run Crash Mid-Step

```
SCENARIO:
─────────
Run crashes mid-step (process dies, power loss).
Must resume safely or mark as frozen with receipts intact.

DETECTION:
──────────
• Process watchdog detects unexpected termination
• Incomplete receipt in ledger (no closing hash)
• Checkpoint timestamp > last heartbeat

HANDLING:
─────────
1. On startup, check for incomplete runs
2. Load last checkpoint
3. Verify receipt chain integrity
4. Mark run as "crashed" with reason
5. Offer resume or abort

RECOVERY:
─────────
• Resume from checkpoint if safe
• Rollback partial actions if possible
• Mark affected resources as "unknown state"
• Generate incident receipt
```

```rust
// crash_recovery.rs

pub struct CrashRecovery {
    checkpoint_store: CheckpointStore,
    receipt_ledger: ReceiptLedger,
}

impl CrashRecovery {
    /// Check for crashed runs on startup
    pub fn check_on_startup(&self) -> Vec<CrashedRun> {
        let incomplete = self.receipt_ledger.find_incomplete_chains();
        let orphaned = self.checkpoint_store.find_orphaned_checkpoints();
        
        incomplete.into_iter()
            .chain(orphaned.into_iter())
            .map(|id| self.analyze_crash(id))
            .collect()
    }
    
    /// Attempt to recover crashed run
    pub fn recover(&self, run_id: RunId) -> Result<RecoveryResult> {
        let checkpoint = self.checkpoint_store.latest_for(run_id)?;
        let receipts = self.receipt_ledger.get_for_run(run_id)?;
        
        // Verify chain integrity
        if !receipts.verify_chain() {
            return Ok(RecoveryResult::ChainCorrupted {
                last_valid: receipts.last_valid_receipt(),
            });
        }
        
        // Check if resumable
        let last_step = checkpoint.current_step;
        if self.is_step_resumable(&last_step) {
            Ok(RecoveryResult::Resumable {
                from_step: last_step,
                checkpoint,
            })
        } else {
            Ok(RecoveryResult::NeedsRollback {
                rollback_to: self.find_safe_rollback_point(&checkpoint),
            })
        }
    }
}
```

### 1.2 Duplicate Run Starts

```
SCENARIO:
─────────
User double-clicks, retry button, CLI re-run.
Must create runs idempotently.

DETECTION:
──────────
• Same intent hash within time window
• Same request ID (if provided)
• Rapid succession from same source

HANDLING:
─────────
1. Generate idempotency key from intent + context
2. Check if run with key exists and is recent
3. If exists: return existing run ID
4. If not: create new run

CONFIGURATION:
──────────────
idempotency:
  window_seconds: 5
  key_includes:
    - intent_hash
    - user_id
    - context_hash
```

```rust
// idempotency.rs

pub struct IdempotencyGuard {
    recent_runs: Cache<IdempotencyKey, RunId>,
    window: Duration,
}

impl IdempotencyGuard {
    pub fn check_or_create(&self, request: &RunRequest) -> IdempotencyResult {
        let key = self.compute_key(request);
        
        if let Some(existing_run) = self.recent_runs.get(&key) {
            IdempotencyResult::Duplicate { run_id: existing_run }
        } else {
            let run_id = RunId::new();
            self.recent_runs.insert(key, run_id, self.window);
            IdempotencyResult::New { run_id }
        }
    }
    
    fn compute_key(&self, request: &RunRequest) -> IdempotencyKey {
        IdempotencyKey {
            intent_hash: hash(&request.intent),
            user_id: request.user_id,
            context_hash: hash(&request.context),
        }
    }
}
```

### 1.3 Run Stuck (Tool Hangs)

```
SCENARIO:
─────────
Tool hangs, browser deadlocks, infinite loop.
Must timeout and handle gracefully.

DETECTION:
──────────
• Step exceeds timeout
• No progress events for threshold duration
• Resource usage anomaly (100% CPU, no I/O)

HANDLING:
─────────
1. Send interrupt signal to stuck operation
2. Wait grace period for clean shutdown
3. Force kill if no response
4. Capture partial state/evidence
5. Generate timeout receipt
6. Offer retry or skip

CONFIGURATION:
──────────────
timeouts:
  step_default_seconds: 60
  step_max_seconds: 300
  grace_period_seconds: 5
  
watchdog:
  heartbeat_interval_seconds: 1
  stuck_threshold_missed: 10
```

```rust
// stuck_detector.rs

pub struct StuckDetector {
    watchdog: Watchdog,
    config: TimeoutConfig,
}

impl StuckDetector {
    /// Monitor step for stuckness
    pub async fn monitor_step<F, T>(&self, step_id: StepId, future: F) -> Result<T>
    where
        F: Future<Output = Result<T>>,
    {
        let timeout = self.config.step_timeout;
        
        match tokio::time::timeout(timeout, future).await {
            Ok(result) => result,
            Err(_) => {
                // Step timed out
                self.handle_timeout(step_id).await
            }
        }
    }
    
    async fn handle_timeout(&self, step_id: StepId) -> Result<()> {
        // 1. Try graceful interrupt
        self.send_interrupt(step_id).await;
        
        // 2. Wait grace period
        tokio::time::sleep(self.config.grace_period).await;
        
        // 3. Check if stopped
        if self.is_still_running(step_id) {
            // 4. Force kill
            self.force_kill(step_id).await;
        }
        
        // 5. Capture evidence
        let evidence = self.capture_partial_state(step_id).await;
        
        // 6. Generate timeout receipt
        self.generate_timeout_receipt(step_id, evidence).await;
        
        Err(Error::StepTimeout { step_id })
    }
}
```

### 1.4 Concurrent Resource Contention

```
SCENARIO:
─────────
Multiple runs contend for browser, ports, file locks.
Must manage resources safely.

DETECTION:
──────────
• Resource acquisition fails
• Lock timeout
• Port already in use

HANDLING:
─────────
1. Implement resource leasing
2. Queue requests for busy resources
3. Timeout with clear error
4. Support resource pooling (multiple browsers)

CONFIGURATION:
──────────────
resources:
  browser:
    pool_size: 2
    lease_timeout_seconds: 300
  ports:
    range: 9000-9100
    lease_timeout_seconds: 60
  file_locks:
    timeout_seconds: 30
```

```rust
// resource_manager.rs

pub struct ResourceManager {
    browser_pool: ResourcePool<Browser>,
    port_pool: ResourcePool<Port>,
    file_locks: LockManager,
}

impl ResourceManager {
    /// Acquire resource with timeout
    pub async fn acquire<R: Resource>(&self, timeout: Duration) -> Result<Lease<R>> {
        let pool = self.pool_for::<R>();
        
        match pool.try_acquire() {
            Some(resource) => Ok(Lease::new(resource)),
            None => {
                // Wait for resource
                match tokio::time::timeout(timeout, pool.wait_for_available()).await {
                    Ok(resource) => Ok(Lease::new(resource)),
                    Err(_) => Err(Error::ResourceTimeout {
                        resource_type: R::TYPE_NAME,
                        timeout,
                    }),
                }
            }
        }
    }
}
```

---

## 2. APPROVAL & CONSENT EDGE CASES

### 2.1 Approval Prompt Lost

```
SCENARIO:
─────────
UI closed, SSH disconnect, terminal cleared.
Approval must be durable and retrievable.

DETECTION:
──────────
• Approval request sent, no response
• Client disconnected while awaiting
• Approval timeout approaching

HANDLING:
─────────
1. Persist all pending approvals
2. Provide retrieval endpoint
3. Support multiple notification channels
4. Allow approval from any connected client

CLI COMMAND:
────────────
hydra approvals pending

# Output:
# PENDING APPROVALS
# ─────────────────
# [a1b2c3] Run: fix-tests | Action: DELETE 4 files | Risk: HIGH
#          Requested: 5 minutes ago
#          
# Approve: hydra approve a1b2c3
# Deny:    hydra deny a1b2c3
# Details: hydra inspect a1b2c3
```

```rust
// durable_approvals.rs

pub struct DurableApprovalManager {
    store: ApprovalStore,
    notifier: MultiChannelNotifier,
}

impl DurableApprovalManager {
    /// Request approval (persisted)
    pub async fn request(&self, approval: ApprovalRequest) -> Result<ApprovalId> {
        let id = ApprovalId::new();
        
        // 1. Persist to durable store
        self.store.save(&id, &approval).await?;
        
        // 2. Notify all channels
        self.notifier.notify_all(&id, &approval).await;
        
        Ok(id)
    }
    
    /// List pending approvals
    pub async fn list_pending(&self) -> Vec<PendingApproval> {
        self.store.get_all_pending().await
    }
    
    /// Approve from any client
    pub async fn approve(&self, id: ApprovalId, approver: ApproverId) -> Result<()> {
        let approval = self.store.get(&id).await?;
        
        // Verify approver has permission
        self.verify_approver(&approval, &approver)?;
        
        // Record approval
        self.store.mark_approved(&id, &approver).await?;
        
        // Resume run
        self.resume_run(&approval.run_id).await?;
        
        Ok(())
    }
}
```

### 2.2 Approval Arrives Late

```
SCENARIO:
─────────
User approves after run has moved on or timed out.

DETECTION:
──────────
• Approval received for non-pending request
• Run state doesn't match expected

HANDLING:
─────────
1. Tie approvals to approval_id + run state hash
2. Reject stale approvals with clear message
3. Offer to re-request if action still relevant
```

```rust
// approval_validation.rs

impl DurableApprovalManager {
    pub async fn process_approval(&self, id: ApprovalId, response: ApprovalResponse) -> Result<()> {
        let approval = self.store.get(&id).await?;
        
        // Check if still pending
        if approval.status != ApprovalStatus::Pending {
            return Err(Error::ApprovalAlreadyProcessed {
                id,
                status: approval.status,
            });
        }
        
        // Check if run state matches
        let current_state = self.get_run_state(&approval.run_id).await?;
        if current_state.hash() != approval.expected_state_hash {
            return Err(Error::ApprovalStateMismatch {
                id,
                message: "Run state has changed since approval was requested",
                can_retry: self.can_re_request(&approval),
            });
        }
        
        // Process approval
        self.apply_approval(&approval, response).await
    }
}
```

### 2.3 Wrong Approval Target

```
SCENARIO:
─────────
User approves wrong action (different from what they think).

PREVENTION:
───────────
1. Include action hash phrase in approval
2. Show clear action summary
3. Require hash phrase for high-risk actions

APPROVAL DISPLAY:
─────────────────
⚠ Approval required: DELETE 4 files

Action ID: a1b2c3
Hash phrase: DELTA-NINE-FOX

Files to delete:
  /tmp/cache/session_a.tmp
  /tmp/cache/session_b.tmp
  /tmp/cache/session_c.tmp
  /tmp/cache/session_d.tmp

Risk: HIGH (irreversible)

To approve, type: hydra approve a1b2c3 --confirm DELTA-NINE-FOX
```

```rust
// approval_verification.rs

pub struct ApprovalVerifier {
    config: ApprovalConfig,
}

impl ApprovalVerifier {
    /// Generate hash phrase for action
    pub fn generate_hash_phrase(&self, action: &Action) -> HashPhrase {
        let hash = hash(&action);
        let words = self.config.word_list;
        
        HashPhrase {
            phrase: format!(
                "{}-{}-{}",
                words[(hash[0] as usize) % words.len()],
                words[(hash[1] as usize) % words.len()],
                words[(hash[2] as usize) % words.len()],
            ).to_uppercase(),
        }
    }
    
    /// Verify approval includes correct hash phrase
    pub fn verify(&self, approval: &ApprovalResponse, expected: &HashPhrase) -> Result<()> {
        if approval.risk_level >= RiskLevel::High {
            match &approval.hash_phrase {
                Some(phrase) if phrase == expected => Ok(()),
                Some(phrase) => Err(Error::HashPhraseMismatch {
                    expected: expected.clone(),
                    provided: phrase.clone(),
                }),
                None => Err(Error::HashPhraseRequired),
            }
        } else {
            Ok(())
        }
    }
}
```

### 2.4 Voice Approval in Noisy Environment

```
SCENARIO:
─────────
False trigger, misheard approval, ambient noise.

HANDLING:
─────────
1. Push-to-talk default for approvals
2. Challenge phrase for high risk
3. Confirmation feedback ("Did you say approve?")
4. Visual confirmation if display available

CONFIGURATION:
──────────────
voice:
  approval_mode: push_to_talk  # or always_listen
  require_confirmation: true
  high_risk_challenge: true
  noise_threshold_db: 60
```

```rust
// voice_approval.rs

pub struct VoiceApprovalHandler {
    asr: WhisperLocal,
    config: VoiceConfig,
}

impl VoiceApprovalHandler {
    pub async fn process_voice_approval(&self, audio: &[f32]) -> Result<VoiceApprovalResult> {
        // 1. Check noise level
        let noise_level = self.calculate_noise_level(audio);
        if noise_level > self.config.noise_threshold_db {
            return Err(Error::TooNoisy { level: noise_level });
        }
        
        // 2. Transcribe
        let transcript = self.asr.transcribe(audio).await?;
        
        // 3. Parse intent
        let intent = self.parse_approval_intent(&transcript)?;
        
        // 4. Confirm if configured
        if self.config.require_confirmation {
            self.speak_confirmation(&intent).await;
            let confirmation = self.listen_for_confirmation().await?;
            
            if !confirmation.is_affirmative() {
                return Ok(VoiceApprovalResult::Cancelled);
            }
        }
        
        // 5. Process
        Ok(VoiceApprovalResult::Approved { intent })
    }
}
```

---

## 3. BROWSER AUTOMATION EDGE CASES

### 3.1 Login State / Session Expiry

```
SCENARIO:
─────────
Session expires mid-run, MFA prompt appears.

DETECTION:
──────────
• Login page detected (URL pattern, DOM elements)
• MFA challenge detected
• 401/403 responses

HANDLING:
─────────
1. Pause run
2. Request human assistance
3. Wait for login completion
4. Resume with fresh session
5. Store session for reuse (if allowed)

STATE MACHINE:
──────────────
Executing → LoginRequired → WaitingForHuman → LoggedIn → Executing
```

```rust
// login_handler.rs

pub struct LoginHandler {
    detector: LoginDetector,
    human_assist: HumanAssistManager,
}

impl LoginHandler {
    /// Check if current page is login
    pub async fn check_page(&self, page: &Page) -> LoginState {
        let url = page.url().await;
        let dom = page.content().await;
        
        if self.detector.is_login_page(&url, &dom) {
            return LoginState::LoginRequired;
        }
        
        if self.detector.is_mfa_challenge(&dom) {
            return LoginState::MfaRequired;
        }
        
        LoginState::LoggedIn
    }
    
    /// Handle login requirement
    pub async fn handle_login_required(&self, run: &mut Run, page: &Page) -> Result<()> {
        // 1. Pause run
        run.set_state(RunState::AwaitingHuman);
        
        // 2. Notify user
        let request = HumanAssistRequest {
            run_id: run.id,
            request_type: HumanAssistType::Login,
            context: format!("Please log in to {}", page.url().await),
            screenshot: page.screenshot().await?,
        };
        
        self.human_assist.request(request).await?;
        
        // 3. Wait for completion
        let result = self.human_assist.wait_for_completion(run.id).await?;
        
        // 4. Verify login successful
        let new_state = self.check_page(page).await;
        if new_state != LoginState::LoggedIn {
            return Err(Error::LoginFailed);
        }
        
        // 5. Resume
        run.set_state(RunState::Executing);
        Ok(())
    }
}
```

### 3.2 UI Changes / Selector Breakage

```
SCENARIO:
─────────
Site redesign, A/B test, selectors break.

DETECTION:
──────────
• Selector returns no elements
• Element type mismatch
• Visual fingerprint differs

HANDLING:
─────────
1. Try alternative selectors (text, ARIA, role)
2. Use fuzzy matching
3. Update skill's selector strategy
4. Fall back to protocol hunting
5. Request human assistance if critical
```

```rust
// selector_recovery.rs

pub struct SelectorRecovery {
    strategies: Vec<Box<dyn SelectorStrategy>>,
}

impl SelectorRecovery {
    /// Find element with recovery
    pub async fn find_element(&self, page: &Page, target: &ElementTarget) -> Result<Element> {
        // 1. Try primary selector
        if let Ok(element) = page.query_selector(&target.primary_selector).await {
            return Ok(element);
        }
        
        // 2. Try alternative strategies
        for strategy in &self.strategies {
            if let Ok(element) = strategy.find(page, target).await {
                // Update skill with working selector
                self.update_skill_selector(target, strategy.name(), &element).await;
                return Ok(element);
            }
        }
        
        // 3. Fall back to protocol hunting
        if let Some(api_call) = self.find_api_equivalent(target).await? {
            return Ok(Element::ApiAction(api_call));
        }
        
        // 4. Request human assistance
        Err(Error::ElementNotFound {
            target: target.clone(),
            tried_strategies: self.strategies.iter().map(|s| s.name()).collect(),
        })
    }
}

// Strategies
struct TextMatchStrategy;      // Find by text content
struct AriaStrategy;           // Find by ARIA labels
struct RoleStrategy;           // Find by role
struct VisualStrategy;         // Find by visual similarity
struct AccessibilityStrategy;  // Use accessibility tree
```

### 3.3 CAPTCHA Handling

```
SCENARIO:
─────────
CAPTCHA appears, cannot be solved automatically.

DETECTION:
──────────
• Known CAPTCHA providers (reCAPTCHA, hCaptcha, etc.)
• CAPTCHA DOM patterns
• iframe with known sources

HANDLING:
─────────
1. Pause run immediately
2. Request human assistance
3. Show CAPTCHA in notification
4. Wait for human to solve
5. Continue after solved
6. Record as incident (for rate limit awareness)

NOTE: Never attempt automatic CAPTCHA solving.
```

```rust
// captcha_handler.rs

pub struct CaptchaHandler {
    detector: CaptchaDetector,
    human_assist: HumanAssistManager,
}

impl CaptchaHandler {
    /// Check and handle CAPTCHA
    pub async fn check_and_handle(&self, page: &Page, run: &mut Run) -> Result<()> {
        if !self.detector.detect_captcha(page).await? {
            return Ok(());
        }
        
        // 1. Pause run
        run.set_state(RunState::CaptchaRequired);
        
        // 2. Capture screenshot
        let screenshot = page.screenshot().await?;
        
        // 3. Request human assistance
        let request = HumanAssistRequest {
            run_id: run.id,
            request_type: HumanAssistType::Captcha,
            context: "Please solve the CAPTCHA to continue",
            screenshot,
            timeout: Duration::from_secs(300),  // 5 minute timeout
        };
        
        self.human_assist.request(request).await?;
        
        // 4. Wait for completion
        self.human_assist.wait_for_completion(run.id).await?;
        
        // 5. Verify CAPTCHA solved
        if self.detector.detect_captcha(page).await? {
            return Err(Error::CaptchaNotSolved);
        }
        
        // 6. Record incident
        self.record_captcha_incident(run.id, page.url().await).await;
        
        // 7. Resume
        run.set_state(RunState::Executing);
        Ok(())
    }
}
```

### 3.4 Popups / Modals / Cookie Banners

```
SCENARIO:
─────────
Unexpected popups block interaction.

DETECTION:
──────────
• Modal overlays detected
• Cookie consent patterns
• Newsletter popups
• Chat widgets

HANDLING:
─────────
1. Detect and classify popup type
2. Dismiss if safe (close button, escape key)
3. Accept/reject cookies based on policy
4. If cannot dismiss, escalate
```

```rust
// popup_handler.rs

pub struct PopupHandler {
    patterns: PopupPatterns,
    policy: PopupPolicy,
}

impl PopupHandler {
    /// Handle popups before action
    pub async fn clear_popups(&self, page: &Page) -> Result<PopupReport> {
        let mut report = PopupReport::new();
        
        // Find all popups
        let popups = self.detect_popups(page).await?;
        
        for popup in popups {
            match popup.popup_type {
                PopupType::CookieConsent => {
                    self.handle_cookie_consent(page, &popup, &self.policy.cookies).await?;
                    report.dismissed.push(popup);
                }
                PopupType::Newsletter => {
                    self.dismiss_popup(page, &popup).await?;
                    report.dismissed.push(popup);
                }
                PopupType::ChatWidget => {
                    self.minimize_widget(page, &popup).await?;
                    report.minimized.push(popup);
                }
                PopupType::Critical => {
                    // Don't auto-dismiss critical popups
                    report.requires_attention.push(popup);
                }
                _ => {
                    if let Err(_) = self.try_dismiss(page, &popup).await {
                        report.failed.push(popup);
                    } else {
                        report.dismissed.push(popup);
                    }
                }
            }
        }
        
        Ok(report)
    }
}
```

---

## 4. TERMINAL & SYSTEM EDGE CASES

### 4.1 Dangerous Command Patterns

```
SCENARIO:
─────────
Destructive commands (rm -rf, sudo, etc.)

DETECTION:
──────────
• Pattern matching on commands
• Privilege escalation attempts
• Recursive/mass operations
• Credential exposure risk

HANDLING:
─────────
1. Classify command risk
2. Block or require elevated approval
3. Suggest safer alternatives
4. Never execute in production without approval

BLOCKED PATTERNS:
─────────────────
• rm -rf / (or any root delete)
• :(){ :|:& };: (fork bomb)
• dd if=/dev/zero of=/dev/sda
• chmod -R 777 /
• curl ... | sudo bash
• eval "$(user_input)"
```

```rust
// command_guard.rs

pub struct CommandGuard {
    patterns: DangerousPatterns,
    policy: CommandPolicy,
}

impl CommandGuard {
    /// Check command before execution
    pub fn check(&self, command: &str) -> CommandCheckResult {
        // 1. Check blocked patterns
        if let Some(pattern) = self.patterns.matches_blocked(command) {
            return CommandCheckResult::Blocked {
                reason: format!("Matches blocked pattern: {}", pattern.name),
                pattern: pattern.clone(),
            };
        }
        
        // 2. Classify risk
        let risk = self.classify_risk(command);
        
        // 3. Check policy
        match self.policy.check(command, risk) {
            PolicyResult::Allow => CommandCheckResult::Allowed,
            PolicyResult::RequireApproval => CommandCheckResult::RequiresApproval {
                risk,
                explanation: self.explain_risk(command),
            },
            PolicyResult::Deny(reason) => CommandCheckResult::Blocked {
                reason,
                pattern: None,
            },
        }
    }
    
    fn classify_risk(&self, command: &str) -> RiskLevel {
        let mut risk = RiskLevel::Low;
        
        // Check for sudo/root
        if command.contains("sudo") || command.starts_with("su ") {
            risk = risk.max(RiskLevel::High);
        }
        
        // Check for destructive commands
        if command.contains("rm ") && command.contains("-r") {
            risk = risk.max(RiskLevel::High);
        }
        
        // Check for mass operations
        if command.contains("find") && (command.contains("-exec") || command.contains("-delete")) {
            risk = risk.max(RiskLevel::Medium);
        }
        
        // Check for network exfil
        if (command.contains("curl") || command.contains("wget")) && 
           !self.is_known_safe_domain(&command) {
            risk = risk.max(RiskLevel::Medium);
        }
        
        risk
    }
}
```

### 4.2 Interactive Prompts

```
SCENARIO:
─────────
Command hangs waiting for input (y/n, password, etc.)

DETECTION:
──────────
• No output for threshold duration
• Known interactive patterns
• stdout contains prompt patterns

HANDLING:
─────────
1. Detect interactive prompt
2. Auto-respond if safe and configured
3. Fail fast if not configured
4. Never auto-respond to password prompts
```

```rust
// interactive_handler.rs

pub struct InteractiveHandler {
    patterns: InteractivePatterns,
    auto_responses: AutoResponses,
}

impl InteractiveHandler {
    /// Handle potential interactive command
    pub async fn execute_with_handling(&self, command: &str) -> Result<CommandOutput> {
        let mut child = Command::new("sh")
            .arg("-c")
            .arg(command)
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()?;
            
        let mut output = String::new();
        let timeout = Duration::from_secs(5);
        
        loop {
            // Read with timeout
            match tokio::time::timeout(timeout, self.read_output(&mut child)).await {
                Ok(Ok(chunk)) => {
                    output.push_str(&chunk);
                }
                Ok(Err(e)) => return Err(e.into()),
                Err(_) => {
                    // Timeout - check for interactive prompt
                    if let Some(prompt) = self.detect_prompt(&output) {
                        if let Some(response) = self.auto_responses.get(&prompt) {
                            // Auto-respond
                            child.stdin.as_mut().unwrap()
                                .write_all(response.as_bytes()).await?;
                        } else {
                            // Cannot auto-respond, fail
                            child.kill().await?;
                            return Err(Error::InteractivePromptNotHandled {
                                prompt,
                                output,
                            });
                        }
                    }
                }
            }
            
            // Check if finished
            if child.try_wait()?.is_some() {
                break;
            }
        }
        
        Ok(CommandOutput { stdout: output, ..Default::default() })
    }
}
```

### 4.3 Secrets in Terminal Output

```
SCENARIO:
─────────
Command accidentally echoes secrets to stdout.

DETECTION:
──────────
• Pattern matching (API keys, tokens, passwords)
• Entropy analysis (high entropy = likely secret)
• Known secret formats

HANDLING:
─────────
1. Scan output before storing
2. Redact detected secrets
3. Log that redaction occurred
4. Never store unredacted secrets in receipts/evidence
```

```rust
// secret_redactor.rs

pub struct SecretRedactor {
    patterns: SecretPatterns,
}

impl SecretRedactor {
    /// Redact secrets from output
    pub fn redact(&self, output: &str) -> RedactionResult {
        let mut redacted = output.to_string();
        let mut redactions = vec![];
        
        // Check patterns
        for pattern in &self.patterns.all() {
            for capture in pattern.regex.captures_iter(output) {
                let secret = capture.get(0).unwrap();
                let replacement = format!("[REDACTED:{}]", pattern.name);
                
                redacted = redacted.replace(secret.as_str(), &replacement);
                redactions.push(Redaction {
                    pattern_name: pattern.name.clone(),
                    position: secret.start()..secret.end(),
                });
            }
        }
        
        // Check high entropy strings
        for (start, end, entropy) in self.find_high_entropy(&redacted) {
            if entropy > 4.5 {  // Threshold for random-looking strings
                let replacement = "[REDACTED:HIGH_ENTROPY]";
                redacted.replace_range(start..end, replacement);
                redactions.push(Redaction {
                    pattern_name: "high_entropy".into(),
                    position: start..end,
                });
            }
        }
        
        RedactionResult {
            redacted,
            redactions,
            had_secrets: !redactions.is_empty(),
        }
    }
}
```

---

## 5. FILE & DIFF EDGE CASES

### 5.1 Git Conflicts

```
SCENARIO:
─────────
User edits file while Hydra is editing same file.

DETECTION:
──────────
• Git status shows conflicts
• File hash changed unexpectedly
• Concurrent edit detected

HANDLING:
─────────
1. Detect conflict before attempting write
2. Show three-way diff to user
3. Offer merge strategies:
   - Keep user's changes
   - Keep Hydra's changes
   - Manual merge
4. Never silently overwrite
```

```rust
// conflict_handler.rs

pub struct ConflictHandler {
    git: GitClient,
    diff_engine: DiffEngine,
}

impl ConflictHandler {
    /// Check and handle potential conflict
    pub async fn check_before_write(&self, path: &Path, new_content: &str) -> Result<WriteDecision> {
        // 1. Get current state
        let current = fs::read_to_string(path)?;
        let original = self.git.get_original_content(path)?;  // From when we started
        
        // 2. Check if changed externally
        if current != original {
            // Conflict detected
            let user_changes = self.diff_engine.diff(&original, &current);
            let hydra_changes = self.diff_engine.diff(&original, new_content);
            
            // 3. Try auto-merge if non-overlapping
            if !self.changes_overlap(&user_changes, &hydra_changes) {
                let merged = self.merge_changes(&original, &user_changes, &hydra_changes)?;
                return Ok(WriteDecision::Merged { content: merged });
            }
            
            // 4. Escalate to user
            return Ok(WriteDecision::Conflict {
                original,
                user_version: current,
                hydra_version: new_content.to_string(),
                diff: self.three_way_diff(&original, &current, new_content),
            });
        }
        
        Ok(WriteDecision::NoConflict)
    }
}
```

### 5.2 Large Files

```
SCENARIO:
─────────
File too large to process in memory or send to LLM.

DETECTION:
──────────
• File size exceeds threshold
• Token count exceeds limit

HANDLING:
─────────
1. Detect large file before processing
2. Chunk into smaller pieces
3. Summarize each chunk locally
4. Process summaries
5. Never send entire large file to API
```

```rust
// large_file_handler.rs

pub struct LargeFileHandler {
    config: LargeFileConfig,
    summarizer: LocalSummarizer,
}

impl LargeFileHandler {
    /// Process large file
    pub async fn process(&self, path: &Path) -> Result<ProcessedFile> {
        let size = fs::metadata(path)?.len();
        
        if size <= self.config.max_direct_size {
            // Small enough to process directly
            return Ok(ProcessedFile::Direct(fs::read_to_string(path)?));
        }
        
        // 1. Chunk the file
        let chunks = self.chunk_file(path).await?;
        
        // 2. Summarize each chunk locally
        let summaries: Vec<_> = futures::future::join_all(
            chunks.iter().map(|c| self.summarizer.summarize(c))
        ).await.into_iter().collect::<Result<Vec<_>>>()?;
        
        // 3. Return chunked representation
        Ok(ProcessedFile::Chunked {
            path: path.to_path_buf(),
            total_size: size,
            chunks: chunks.len(),
            summaries,
        })
    }
}
```

### 5.3 Binary Files

```
SCENARIO:
─────────
Binary file (image, executable, archive) - diff not possible.

DETECTION:
──────────
• File extension check
• Content-type detection
• Non-UTF8 content

HANDLING:
─────────
1. Detect binary file
2. Hash content for comparison
3. Store as artifact without diff
4. Show metadata only (size, type, hash)
```

```rust
// binary_file_handler.rs

pub struct BinaryFileHandler;

impl BinaryFileHandler {
    /// Handle binary file
    pub fn process(&self, path: &Path) -> Result<BinaryFileInfo> {
        let content = fs::read(path)?;
        
        // 1. Detect file type
        let file_type = self.detect_type(&content);
        
        // 2. Calculate hash
        let hash = sha256(&content);
        
        // 3. Extract metadata
        let metadata = match file_type {
            FileType::Image => self.extract_image_metadata(&content)?,
            FileType::Pdf => self.extract_pdf_metadata(&content)?,
            FileType::Archive => self.extract_archive_metadata(&content)?,
            _ => Metadata::default(),
        };
        
        Ok(BinaryFileInfo {
            path: path.to_path_buf(),
            size: content.len(),
            file_type,
            hash,
            metadata,
        })
    }
    
    /// Compare binary files
    pub fn compare(&self, a: &BinaryFileInfo, b: &BinaryFileInfo) -> BinaryComparison {
        BinaryComparison {
            same_content: a.hash == b.hash,
            size_diff: (b.size as i64) - (a.size as i64),
            type_changed: a.file_type != b.file_type,
        }
    }
}
```

---

## 6. RECEIPT & OBSERVABILITY EDGE CASES

### 6.1 Receipt Chain Breaks

```
SCENARIO:
─────────
Crash mid-write causes broken hash chain.

DETECTION:
──────────
• Hash verification fails
• Missing receipt in sequence
• Incomplete receipt record

HANDLING:
─────────
1. Detect break point
2. Mark chain as "repaired" after break
3. Generate repair receipt
4. Continue with new chain segment
5. Preserve both segments for audit
```

```rust
// chain_repair.rs

pub struct ChainRepairer {
    ledger: ReceiptLedger,
}

impl ChainRepairer {
    /// Repair broken chain
    pub fn repair(&self) -> Result<RepairReport> {
        let mut report = RepairReport::new();
        
        // 1. Find break points
        let breaks = self.find_chain_breaks()?;
        
        for break_point in breaks {
            // 2. Determine repair strategy
            let strategy = self.determine_strategy(&break_point);
            
            match strategy {
                RepairStrategy::LinkSegments => {
                    // Create bridge receipt
                    let bridge = self.create_bridge_receipt(&break_point)?;
                    report.bridges.push(bridge);
                }
                RepairStrategy::MarkOrphaned => {
                    // Mark orphaned receipts
                    self.mark_orphaned(&break_point)?;
                    report.orphaned.push(break_point);
                }
                RepairStrategy::Reconstruct => {
                    // Attempt to reconstruct from evidence
                    let reconstructed = self.reconstruct(&break_point)?;
                    report.reconstructed.push(reconstructed);
                }
            }
        }
        
        // 3. Verify repaired chain
        let verified = self.verify_chain()?;
        report.chain_valid = verified;
        
        Ok(report)
    }
}
```

### 6.2 Event Ordering Issues

```
SCENARIO:
─────────
Async operations cause out-of-order events.

DETECTION:
──────────
• Timestamp ordering doesn't match sequence
• Causal dependency violations

HANDLING:
─────────
1. Use monotonic event IDs
2. Include causal links in events
3. Sort by causal order, not timestamp
4. Detect and flag ordering anomalies
```

```rust
// event_ordering.rs

pub struct EventOrderer {
    clock: MonotonicClock,
}

#[derive(Clone)]
pub struct OrderedEvent {
    pub sequence_id: u64,        // Monotonic
    pub timestamp: DateTime<Utc>, // Wall clock (for display)
    pub caused_by: Option<u64>,  // Causal link
    pub event: Event,
}

impl EventOrderer {
    /// Create ordered event
    pub fn create_event(&self, event: Event, caused_by: Option<u64>) -> OrderedEvent {
        OrderedEvent {
            sequence_id: self.clock.next(),
            timestamp: Utc::now(),
            caused_by,
            event,
        }
    }
    
    /// Sort events by causal order
    pub fn sort_causal(&self, events: &mut [OrderedEvent]) {
        // Topological sort based on caused_by links
        let mut sorted = vec![];
        let mut remaining: HashSet<_> = events.iter().map(|e| e.sequence_id).collect();
        
        while !remaining.is_empty() {
            // Find events with no unsatisfied dependencies
            let ready: Vec<_> = events.iter()
                .filter(|e| remaining.contains(&e.sequence_id))
                .filter(|e| e.caused_by.map(|c| !remaining.contains(&c)).unwrap_or(true))
                .cloned()
                .collect();
                
            for event in ready {
                remaining.remove(&event.sequence_id);
                sorted.push(event);
            }
        }
        
        events.copy_from_slice(&sorted);
    }
}
```

---

## 7. MULTI-USER EDGE CASES

### 7.1 Voice User Identification

```
SCENARIO:
─────────
Multi-user household, wrong person gives voice approval.

DETECTION:
──────────
• Voice doesn't match registered user
• Multiple voices detected
• Anomalous approval pattern

HANDLING:
─────────
1. Voice enrollment for authorized users
2. Speaker verification before approval
3. Challenge phrase for high-risk
4. Visual confirmation if display available
```

```rust
// voice_identification.rs

pub struct VoiceIdentification {
    enrolled_users: HashMap<UserId, VoicePrint>,
    verification_threshold: f32,
}

impl VoiceIdentification {
    /// Verify speaker
    pub async fn verify_speaker(&self, audio: &[f32]) -> Result<SpeakerVerification> {
        // 1. Extract voice print from audio
        let voice_print = self.extract_voice_print(audio)?;
        
        // 2. Compare against enrolled users
        let mut best_match: Option<(UserId, f32)> = None;
        
        for (user_id, enrolled_print) in &self.enrolled_users {
            let similarity = voice_print.similarity(enrolled_print);
            
            if similarity > self.verification_threshold {
                if best_match.map(|(_, s)| similarity > s).unwrap_or(true) {
                    best_match = Some((user_id.clone(), similarity));
                }
            }
        }
        
        match best_match {
            Some((user_id, confidence)) => Ok(SpeakerVerification::Verified {
                user_id,
                confidence,
            }),
            None => Ok(SpeakerVerification::Unknown),
        }
    }
}
```

---

## 8. SUMMARY: EDGE CASE CATEGORIES

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      EDGE CASE HANDLING SUMMARY                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  CATEGORY              STRATEGY                    PRIORITY                  │
│                                                                              │
│  Run crashes           Checkpoint + Resume         CRITICAL                  │
│  Duplicate runs        Idempotency keys            HIGH                      │
│  Stuck runs            Timeout + Watchdog          CRITICAL                  │
│  Resource contention   Pooling + Leasing           HIGH                      │
│                                                                              │
│  Lost approvals        Durable persistence         CRITICAL                  │
│  Late approvals        State hash validation       HIGH                      │
│  Wrong approvals       Hash phrases                HIGH                      │
│  Voice errors          Push-to-talk + Confirm      MEDIUM                    │
│                                                                              │
│  Login required        Human assist                HIGH                      │
│  UI changes            Selector recovery           HIGH                      │
│  CAPTCHAs              Human assist                HIGH                      │
│  Popups                Auto-dismiss                MEDIUM                    │
│                                                                              │
│  Dangerous commands    Block + Approval            CRITICAL                  │
│  Interactive prompts   Detect + Fail fast          HIGH                      │
│  Secrets exposed       Redaction                   CRITICAL                  │
│                                                                              │
│  Git conflicts         Three-way merge             HIGH                      │
│  Large files           Chunking + Summary          MEDIUM                    │
│  Binary files          Hash + Metadata             LOW                       │
│                                                                              │
│  Chain breaks          Repair + Bridge             HIGH                      │
│  Event ordering        Causal links                MEDIUM                    │
│                                                                              │
│  Multi-user voice      Speaker verification        MEDIUM                    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

*Document Version: 1.0*
*Status: Canonical*
