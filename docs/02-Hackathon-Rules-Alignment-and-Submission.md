# Agentforce World Tour Mumbai Hackathon — Rules Alignment & Submission Checklist

**Source:** *WT Mumbai Hackathon Official Rules.pdf* (Salesforce India–administered hackathon).  
**Purpose:** Map your project to **submission requirements** and **judging criteria** so judges can verify claims quickly. This is a **companion** to `01-TDD-Test-Drive-Agent.md` (operational / compliance context, not duplicate architecture).

---

## 1. Project requirements checklist (from official rules)

| Rule (summary) | Your project alignment | Evidence to attach in submission |
|----------------|------------------------|----------------------------------|
| **Agentforce solution** tailored to **Retail & Consumer Goods, Health Cloud, Automotive, or FINS** | Automotive test drive use case | Video + TDD §1–4; industry label in submission form |
| **Agent using Agent Builder** + **custom actions** | `Agentforce_Service_Agent` + GenAI plugins/functions + Apex invocables | Screen recording of Agent Builder; list in submission “products/tools” |
| **Runs on Salesforce Platform** | SFDX project, CRM + flows + Omni metadata | GitHub URL; org access per rules |
| **New work after start of Submission Period using provisioned orgs** | Stated as hackathon build in your narrative | Team attestation; repo commit history if allowed |
| **Third-party integrations** only if authorized | Meta / WhatsApp via Salesforce Digital Engagement + approved templates | Note authorized use; no unlicensed SDKs |
| **AppExchange** — Labs OK; other partners not as base app | Confirm only Labs / platform | Short statement in submission |
| **Testing:** share **org credentials** without restriction until judging ends | Provide admin login in submission form | Rotate secrets after judging if policy allows |
| **Video &lt; 5 minutes**, shows real device/app, uploaded via `https://sforce.co/awthackathon` | Prepare demo script: Book → DL → WhatsApp → Review → Data Cloud mention | No Einstein **name** or Einstein **imagery** per rules |
| **No gen-AI generated video/image/audio** for the submission video itself | Capture real screen recording | — |
| **List products / features / APIs used** | Agentforce, Digital Engagement, Experience Cloud (Automotive site), Flow, Omni, Apex, Data Cloud ingest metadata, Prompt Builder, Automotive objects (LWCs on site pages only—not in-agent; see TDD §2.4) | Paste bullet list from TDD §5 |
| **GitHub URL to source** | This repository | Public or judge-accessible repo |
| **Further improvements if more time** | See §3 below | 30–60 seconds in video or text |
| **Original work, no IP violation** | Your team’s build | — |
| **Access:** admin credentials + links + **suggested prompts** | README or separate testing doc | Example prompts for Book / Review / Cancel |
| **One submission per entrant** | Team submits once | Representative confirms |
| **English** (or translation provided) | Documents in English | — |

**Important conflict to resolve with your team:** The rules state projects must be **newly created after the start of the Hackathon Submission Period** using provisioned environments. Only your team can confirm timing against your org and repo. Do **not** claim compliance in writing unless the Representative verifies it.

---

## 2. Judging criteria (40% / 40% / 20%) — how to present your work

### 2.1 Creativity / Innovation (40%)

Highlight:

- **Dual guest channels** (WhatsApp + **Automotive Cloud website** with embedded Electra Cars Agent) and **one conversational model** (Apex / GenAI actions) so behavior stays consistent where LWCs cannot render (WhatsApp).  
- **Routing priority** tied to test drive datetime and queue/Omni design.  
- **Data Cloud** + **reviews** for richer personalization (tie to business outcome: dealer and model confidence).

### 2.2 Efficient usage of platform (40%)

Highlight:

- **Agentforce Service Agent** + **plugins** + **GenAI functions** instead of one-off scripts.  
- **Record-triggered flows** for voice/service routing **and** Apex trigger handler for complex routing.  
- **Data stream definitions** for CRM objects (Lead, Test Drive, Review, Vehicle, Account, …) showing platform breadth.

### 2.3 Demo delivery (20%)

- Follow the **flow PDF** narrative as the storyboard.  
- Show **status** changes on `Test_Drive__c` alongside the agent.  
- Show **one** WhatsApp outbound (template or session message) if allowed in demo org.

---

## 3. Suggested “further improvements” (submission text / video)

Use items your team can **honestly** deliver next. Below is an **expanded** list you can paste or trim for the hackathon form (mix **product** ideas with **engineering** quality).

### 3.1 Already on your roadmap (from team)

1. **Geolocation-assisted pincode (ZIP)** — On the **Experience site**, use the browser **Geolocation API** (with clear **consent** and fallback to manual entry) to suggest or pre-fill **postal code** for dealer matching, reducing typing errors and drop-off. Optionally pair with a **geocoding** service (authorized, rate-limited) for reverse lookup where policy allows.  
2. **Voice channel fully aligned with the main agent** — **Service Cloud Voice** / voice routing flows (`voice_agent_route`, `Service_Agent_Route_to_Work`) and Omni metadata exist in the project; in the org, voice was **enabled and validated on a test agent**, but **not showcased** end-to-end and **not fully wired to the same production Agentforce definition** as WhatsApp/web due to **time constraints**. Next step: **one published agent** across **WhatsApp, web, and voice** with a demo script and test numbers.  
3. **Auto-capture WhatsApp phone number (context-first)** — For **WhatsApp**, pass **`MessagingEndUser`** / session context into the agent so the **customer’s number is read from the channel** instead of asking “what is your phone number?” again. Keep **explicit collection** only on the **website** channel (or when context is missing) so **dual-channel** behavior stays correct and privacy-safe.

### 3.2 Product and UX

4. **Progressive disclosure** — Short “quick replies” or numbered choices in text for common paths (book vs reschedule) while keeping **no LWC-in-agent** constraint for WhatsApp.  
5. **Multilingual templates and agent topics** — Align `EndUserLanguage` on `MessagingSession` with translated **Meta templates** and localized plugin copy.  
6. **DL verification SLA dashboard** — Supervisor view of queue age for **Verification_Queue** vs **Test_Drive_Requests_Queue** with alerts.  
7. **No-show and reschedule prediction** — Use **Data Cloud** calculated insights + history on `Test_Drive__c` to nudge confirmation or offer alternate slots.

### 3.3 Platform, data, and reliability

8. **Higher automated test coverage** — Apex tests for every **`Electra*`** invocable, `TestDriveTriggerHandler` bulk scenarios, and `AgentWorkTriggerHandler` edge cases (PSR deleted before resolve).  
9. **Centralized configuration** — Custom Metadata Types for **template API names**, channel ids, and feature flags (replace literals in samples and reduce deploy drift).  
10. **Observability** — Platform Events or structured logging to **`Webhook_Log__c`** for conversation milestones (started booking, abandoned at dealer step, DL failed).  
11. **Data Cloud beyond ingest** — Identity resolution (Lead ↔ Contact ↔ Messaging End User), **activations** (Journey Builder / re-engagement), and **retrieval-augmented** prompts where licensed.  
12. **Security hardening** — Guest Experience **CSP** review, PII minimization on `WhatsApp_Message__c`, rotate any legacy webhook verify patterns out of source if reused.

### 3.4 Operations and compliance

13. **Runbook for Meta / DE changes** — Document template version bumps, WABA number changes, and regression prompts after each change.  
14. **Capacity and staffing models** — Tune Omni **presence** and **routing priority** tiers using production volume, not demo defaults.

**Short paragraph for the form (example):**  
*“With more time we would (a) use browser geolocation with consent to improve pincode capture on the site, (b) unify voice with the same Agentforce agent we use for WhatsApp and web and include it in the demo, (c) bind WhatsApp sessions to the customer’s phone from Messaging context to avoid redundant questions, and (d) deepen tests, metadata-driven config, and Data Cloud insights for no-shows and SLAs.”*

---

## 4. Submission artifacts (practical list)

1. **Video** (rules-compliant).  
2. **Text description** (can paste summary from TDD §1–2 + WhatsApp supplement).  
3. **Admin credentials** + **deep links** (Test Drive tab, Agent Builder, Messaging channel).  
4. **Suggested prompts** (3–5 per plugin).  
5. **GitHub URL** (this repo).  
6. **Product/feature list** (copy from TDD).

---

## 5. Non-technical items (Representative)

- **Team size 3–5**, one **Representative**, Agentforce 360 League completion for at least one member (per rules).  
- **Finalists:** in-person showdown registration and attendance rules apply if you advance.

This document does not provide legal advice; it summarizes published hackathon rules for your convenience.
