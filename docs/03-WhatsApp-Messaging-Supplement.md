# WhatsApp & Digital Messaging — Supplement (Repository Facts + Org Narrative)

This document separates **what is verifiable in Git** from **what you configure only in the Salesforce / Meta consoles** so judges are not misled.

---

## Part A — Verified from this repository (metadata & code)

### A.1 Messaging channels (metadata files)

| File | Channel type |
|------|----------------|
| `force-app/main/default/messagingChannels/WHATSAPP_US_1028994640302379.messagingChannel-meta.xml` | WhatsApp |
| `force-app/main/default/messagingChannels/WHATSAPP_US_1135194629668782.messagingChannel-meta.xml` | WhatsApp |
| `force-app/main/default/messagingChannels/Electra_Site_Messaging_channel.messagingChannel-meta.xml` | Digital engagement (site) |

**Observed pattern in WhatsApp channel metadata:** automated responses for **opt-in**, **double opt-in**, **opt-out**, **help**, and **consent** (`DoubleOptIn` usage). Exact labels and external account IDs are **org-specific**—refer to the XML in-repo for your demo org.

### A.2 Agent bot: WhatsApp + Embedded Messaging context

`force-app/main/default/bots/Agentforce_Service_Agent/Agentforce_Service_Agent.bot-meta.xml` maps **MessagingEndUser** and **MessagingSession** context variables for **`WhatsApp`** and **`EmbeddedMessaging`** (and other declared message types). This supports your statement that the **same agent** is configured for **WhatsApp** and other messaging surfaces.

### A.3 Apex classes (WhatsApp-related naming in repo)

**Production path (team statement):** Live WhatsApp uses **Digital Engagement** with a **Meta-approved** WhatsApp Business number and **messaging templates**—not these Apex classes as the integration layer.

**Classes retained in Git (built but not used on the live path):**

| Class | Role (reference / alternate implementation in source) |
|-------|------------------------------------------------------|
| `WhatsAppService.cls` | Graph API–style JSON for text, template, image, document messages + logging hooks; **placeholder** id/token constants in sample code |
| `WhatsAppDirectAPI.cls` | Direct API helper |
| `WhatsAppFreeFormService.cls` | Free-form messaging service |
| `WhatsAppWebhookHandler.cls` | `@RestResource` webhook verification and inbound handling pattern |
| `sendFreeFormMessage.cls` | Invocable or utility for free-form sends |

**For judges:** The repo proves an **optional direct Graph + webhook** pattern was developed; **production** traffic is **Salesforce Messaging / templates** via the approved number. Placeholders in Apex do not imply those values are used in production.

### A.4 Custom object: `WhatsApp_Message__c` (fields in metadata)

Fields present under `objects/WhatsApp_Message__c/fields/` include (API names):

- `Contact__c`  
- `Direction__c`  
- `Error_Message__c`  
- `Media_URL__c`  
- `Message_Body__c`  
- `Message_Type__c`  
- `Phone_Number__c`  
- `Status__c`  
- `Template_Name__c`  
- `WhatsApp_Message_Id__c`  

This supports **auditing** template sends and statuses in CRM.

### A.5 Flows touching voice / service routing (related to omnichannel)

- `flows/voice_agent_route.flow-meta.xml`  
- `flows/Service_Agent_Route_to_Work.flow-meta.xml`  

These align with your note that **voice** was configured in addition to WhatsApp, with **WhatsApp as primary** demo focus.

### A.6 Test drive statuses relevant to WhatsApp templates (metadata picklist)

`Test_Drive__c.Status__c` includes values such as **Draft**, **Pending DL Verification**, **DL Verified**, **DL Verification Failed**, **Test Drive Scheduled**, **Completed**, **Cancelled**, etc. Your **template choice per status** should be described as **org automation** (Flow / Apex / Messaging rules)—the **template definitions themselves are not exported** in this repo.

---

## Part B — Org / Meta / operations narrative (you provide; not in Git)

**Instructions:** Fill in bracketed items only with facts you can evidence (screenshots, Meta Business Manager, Setup screenshots, Support emails). Do not copy this paragraph to judges as “proof” without attachments.

| Topic | Your statement (draft for you to verify) |
|-------|------------------------------------------|
| **Salesforce case for number approval** | You raised a case to approve a **personal** phone number; after **Meta** approval, **business number** provisioning made development smoother but took time. **[Add case # and dates if you have them.]** |
| **Meta-approved templates** | Booking confirmation; DL verification failed; test drive completed; reminder **~4 hours before** test drive. **[Add exact template API names from Setup or Meta.]** |
| **Outbound mechanism** | You used **Messaging components** / standard outbound messaging aligned to `Test_Drive__c` status. **[Name the Flow or Apex entry point in org.]** |
| **Compliance** | Messaging templates + **Salesforce and Meta approved** sender; double opt-in configured in channel metadata. |

### Personal / ethical note (optional for judges)

You mentioned doing WhatsApp work **personally** even when using **approved templates and numbers**. If your employer requires disclosure, add a one-line note that participation complied with **internal policies**—only if true.

---

## Part C — What is **not** in this repo (do not claim from Git alone)

- Meta **template** JSON definitions and **template approval** timestamps.  
- **Live** WhatsApp Business Account IDs / tokens (and they should remain out of Git).  
- **Exact** scheduled job or Flow version that sends the **4-hour** reminder (unless you add metadata later).  

---

## Part D — Quick “classes vs. templates” summary for your write-up

- **Classes / metadata in Git:** listed in Parts A.3–A.4 and messaging channel files.  
- **Templates:** document separately with **Setup → Messaging Templates** or **Digital Engagement** screenshots in the submission appendix.

This supplement is intended to sit **beside** `01-TDD-Test-Drive-Agent.md` for hackathon reviewers who want **WhatsApp depth** without mixing unverified org claims into the core TDD.
