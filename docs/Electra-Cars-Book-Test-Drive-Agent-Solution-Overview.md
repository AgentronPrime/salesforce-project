# Electra Cars — Book Test Drive Agent (Detailed Solution Overview)

This document describes the **Book Test Drive Agent** solution for **Electra Cars**, an OEM that operates a **premium public website** showcasing vehicle models. Historically, customers had to complete a **long manual form** or request a callback to book a test drive—driving drop-off, low conversion (~1% of visitors booking), and heavy call-center rework for missing model, location, or time preferences.

The implementation uses **Salesforce Automotive Cloud** data (Leads, Vehicles, Accounts/dealers, `Test_Drive__c`), **Agentforce** (Einstein Service Agent) for the conversational journey, **Digital Engagement** (WhatsApp and embedded web messaging), an **Experience Cloud–style** digital site (**AutoCloudExperience1**) with **Electra Cars Agent** embedded via **Embedded Service**, **Omni-Channel** routing patterns, **Prompt Builder** for AI review summaries, and **Data Cloud** ingest metadata aligned with deeper customer and journey analytics.

**Companion docs:** For architecture diagrams, section-numbered TDD, hackathon rules alignment, WhatsApp supplement, and Data Cloud stream lists, see `docs/01-TDD-Test-Drive-Agent.md` through `docs/04-Data-Cloud-Architecture-and-Flows.md`.

---

## 1. Business problem (hackathon alignment)

| Pain point | How the challenge framed it | What the solution targets |
|------------|----------------------------|---------------------------|
| **High friction** | Long web form → massive drop-off | Replace form-first culture with **Agentforce-led** dialogue: natural steps for phone, vehicle, ZIP, dealer, slot. |
| **Low conversion** | ~1% of visitors book | **Omni-channel reach**: WhatsApp + **website embedded agent** + proactive site context (vehicle catalog before chat). |
| **Manual bottlenecks** | Agents chase missing model / location / time | **Structured capture** during conversation + **automatic** `Test_Drive__c` creation after confirmation. |
| **Routing** | — | **ZIP / dealer logic** and **skills / queues** so the right dealership and verification teams receive work. |
| **Confirmation** | — | **Preferred channel** notifications (Digital Engagement templates / messaging; see org configuration). |
| **Insights** | Data Cloud for deeper customer insights | **CRM → Data Cloud** streams for Lead, Test Drive, Review, Vehicle, Account, etc. |

---

## 2. Solution summary (conceptual)

The platform exposes **one primary Agentforce service agent** (`Agentforce_Service_Agent`) to **WhatsApp** and to **guests on the Electra website** through standard **embedded messaging** (deployment metadata: `Electra_cars_chat_deployment`). The agent runs **topic plugins** (book, review, reschedule/cancel, onboarding assistance) and **GenAI Functions** that invoke **Apex** to read/write Automotive Cloud data: find or create **Leads**, list **vehicles** and **dealers** by rules, propose **available dates and time slots**, insert/update **`Test_Drive__c`**, manage **reviews** on `Review__c`, and support **DL upload** flows tied to verification queues.

**Record automation:** A trigger on `Test_Drive__c` delegates to `TestDriveTriggerHandler` for **routing priority** (time-aware), **queue movement** (verification vs dealer request queues), and **post–DL-verified** behavior aligned with **Service Channel** / Omni configuration. **Flows** complement triggers for **before-save** rules on test drives, **service/voice routing**, and user lifecycle.

**AI beyond dialogue:** `ElectraAgentTemplateController` calls Prompt Builder template **`Electra_Agent_Template`** (via Connect `EinsteinLLM.generateMessagesForPromptTemplate`) to return **natural-language summaries** of vehicle/dealer/test-drive context for the experience.

**Data Cloud:** Ingest definitions connect Salesforce CRM objects into Data Cloud lake/DMO-style artifacts (e.g. `Test_Drive_c_Home`, `Review_c_Home`, `Lead_Home`) using the **SalesforceDotCom** connector pattern, enabling analytics and future calculated insights on the same data the agent mutates.

**Design choice — no LWC inside the agent thread:** Rich **Lightning Web Components** do **not** power the **in-chat** UI, because **WhatsApp cannot render** custom agent LWCs. The team uses **conversational text + invocable Apex** so **WhatsApp and web** share identical behavior. LWCs such as `vehicleShowcaseCmp`, `vehicleDetailsCmp`, and `electraDLUpload` support **site pages** (showcase, detail, DL upload views), not the embedded chat surface.

---

## 3. Channel architecture

### 3.1 WhatsApp and Digital Engagement (Agentforce)

**Messaging channels** (metadata under `messagingChannels/`) define **WhatsApp** sender configuration, including **opt-in / double opt-in** automated responses required for compliant outreach.

**Bot context:** `bots/Agentforce_Service_Agent/Agentforce_Service_Agent.bot-meta.xml` maps **MessagingEndUser** and **MessagingSession** context (e.g. `ContactId`, `EndUserLanguage`, session `Id`) for **WhatsApp** and **EmbeddedMessaging** (and other declared types), so the same published agent definition participates in Digital Engagement sessions.

**Production WhatsApp path:** Live outbound and inbound traffic uses **Salesforce Digital Engagement** with a **Meta-approved WhatsApp Business** number and **messaging templates** (standard session and template sends)—not a custom **Graph API via Apex** integration. That approach satisfied compliance and removed the need to host webhook callouts for day-to-day booking.

**Apex Graph / webhook helpers (retained in repo, not used in the live solution):** The following classes were built during development (e.g. for a direct Cloud API or webhook pattern) and are **kept in source control** for reference or future use; they are **not** on the production path once the approved number and Digital Engagement messaging were in place.

| Class | Role (reference implementation in Git) |
|-------|------------------------------------------|
| `WhatsAppService` | Graph API–style JSON for text, template, image, and document sends; message logging hooks. Uses **placeholder** id/token strings in sample code—would require Named Credentials if ever activated. |
| `WhatsAppDirectAPI` | Additional direct API helper patterns. |
| `WhatsAppFreeFormService` / `sendFreeFormMessage` | Free-form messaging utilities. |
| `WhatsAppWebhookHandler` | `@RestResource(urlMapping='/whatsapp/webhook/*')`: **GET** verification and **POST** inbound handling. If reused, move verify tokens to **Custom Metadata / Custom Settings** and avoid hard-coded secrets. |

**Custom object `WhatsApp_Message__c`:** Metadata in the repo supports **optional** message-level logging (direction, template name, status, etc.). Whether production populates it depends on org automation; it aligns with audit patterns whether traffic is DE-driven or custom Apex.

### 3.2 Website and Experience Cloud (guest acquisition)

**Digital Experience site:** `digitalExperiences/site/AutoCloudExperience1/` defines CMS-backed views including **home**, **Vehicle_Showcase** / **VehicleShowcase**, **vehicle_details**, **Upload_Driving_License**, login/register/password flows, and error pages—matching a **marketing + catalog + test drive** journey.

**Embedded Agentforce:** `EmbeddedServiceConfig/Electra_cars_chat_deployment.EmbeddedServiceConfig-meta.xml` ties the **Electra Cars** web deployment to embedded chat so visitors use the **same agent** as WhatsApp for **book / review / reschedule / cancel** and **AI insights**.

**Site messaging channel:** `messagingChannels/Electra_Site_Messaging_channel.messagingChannel-meta.xml` supports digital engagement for the **site** surface alongside WhatsApp channel metadata.

**Supporting LWCs (site, not in-agent):** e.g. `vehicleShowcaseCmp`, `vehicleDetailsCmp`, `electraDLUpload`, `navigationBanner`, `eventBanner`—bound to Experience views where configured.

### 3.3 Voice

**Flows** `voice_agent_route.flow-meta.xml` and `Service_Agent_Route_to_Work.flow-meta.xml` (with **Omni**-related metadata: `serviceChannels/`, `queueRoutingConfigs/`, `queues/`, `skills/`, `presenceUserConfigs/`, `servicePresenceStatuses/`) route **voice** or **service** work so test-drive operations can align with **same-day** or rep-assist scenarios described in the functional flow document. Voice is configured as an additional channel; **WhatsApp + web** remain the primary demo paths for guests.

---

## 4. Agentforce: dialogue, plugins, and invocable Apex

**Agent:** `Agentforce_Service_Agent` (Einstein Service Agent template `SvcCopilotTmpl__EinsteinServiceAgent` per bot metadata).

**GenAI plugins (topic bundles):**

| Plugin | Purpose |
|--------|---------|
| `Book_Test_Drive` | End-to-end booking dialogue. |
| `Review_Test_Drive` | Post-drive review capture and updates. |
| `Reschedule_or_Cancel_Test_Drive` | Change or cancel upcoming drives. |
| `Customer_onboarding_Assistance` | General onboarding assistance. |

**GenAI Functions → Apex invocation targets:**

| GenAI Function | Invokes |
|----------------|---------|
| `Lookup_Lead_By_Phone` | `ElectraLookupLeadByPhoneAction` |
| `Create_Lead_From_Phone_And_Name` | `ElectraCreateLeadAction` |
| `Get_Electra_Quick_Options` | `ElectraQuickOptionsAction` |
| `Get_Test_Drive_Options` | `AgentOptionResponse` |
| `Case_Status` | `CaseManagementController` |

**Representative Electra / domain Apex** (booking and data capture):  
`ElectraFetchVehiclesAction`, `ElectraFetchDealersAction`, `ElectraFetchAvailableDatesAction`, `ElectraFetchTimeSlotsAction`, `ElectraCreateTestDriveAction`, `ElectraRescheduleTestDriveAction`, `ElectraCancelTestDriveAction`, `ElectraFetchTestDrivesAction`, `ElectraFetchReviewAction`, `ElectraSaveReviewAction`, `ElectraTriggerDLUploadRequest`, `ElectraUploadDLController`, `ElectraUploadDLVFController`, plus orchestration helpers (`ElectraQuickOptions`, `ElectraQuickOptionsController`, `GetQuickOptionsRendererAction`, `AgentforceQuickOptionsController`, `TestDriveDetailService`, `TestDriveRetrievalService`, `TestDriveReviewService`).

Together, these actions implement the hackathon **mandatory** behaviors: **AI-driven booking**, **automatic capture** of model / ZIP / slot, **`Test_Drive__c` creation**, and **ZIP-aware dealer** selection logic backed by **Vehicle**, **VehicleDefinition**, and **`VehicleDef_Dealer__c`** availability.

---

## 5. Intelligent routing and dealer operations

**`TestDriveTriggerHandler`** (invoked from `triggers/TestDriveTrigger.trigger` on `Test_Drive__c`):

- Maintains **`Routing_Priority__c`** using `RoutingPriorityCalculator` (time-sensitive priority for Omni **secondary routing** semantics).  
- Moves records between **Verification** and **Test Drive** queues (`Verification_Queue`, `Test_Drive_Requests_Queue` developer names in code).  
- Reacts to **status** transitions (e.g. **DL Verified**, **Pending DL Verification**, **Test Drive Scheduled**) to support verification and same-day rep scenarios.  
- Resolves **Service Channel** where `RelatedEntity = 'Test_Drive__c'` for channel-aware routing.

**Dealer / skill automation:** `DealerRoutingService`, `DealerSkillCreationBatch`, `DealerSkillSetupBatch`, `DealerSkillSetupInvocable` support **ZIP- or skill-oriented** routing configuration.

**Agent work:** `AgentWorkTrigger.trigger` + `AgentWorkTriggerHandler` integrate agent work updates where configured.

---

## 6. Confirmation loop and proactive engagement

**Confirmation:** After booking confirmation, customers receive notification through **Digital Engagement** (WhatsApp template sends and/or session messages). Exact **Meta template API names** and Flow names live in **org configuration**; see `docs/03-WhatsApp-Messaging-Supplement.md` for how to document them with screenshots.

**Proactive nudge (hackathon “brainstorm”):** The **website** surfaces campaigns and vehicle highlights; the **embedded agent** lowers the step count to “ask and book.” Optional next steps (not all required to be in Git) include **scheduled reminders** (e.g. hours before test drive) via **Flow + scheduled paths** or **messaging templates**, aligned with `Test_Drive__c.Status__c`.

---

## 7. Einstein and Prompt Builder

| Artifact | Role |
|----------|------|
| `ElectraAgentTemplateController` | Aura-enabled server method `getReviewSummary` builds `ConnectApi.EinsteinPromptTemplateGenerationsInput` and calls **`Electra_Agent_Template`** with inputs: Type, Vehicle Model Number, Account Id, Test Drive Id. |
| Prompt template (org) | Must exist in **Prompt Builder** with matching input contract; `applicationName` in code uses `PromptBuilderPreview` for generations configuration as authored. |

This supports **AI-led insights** on the **website** (and any surface that calls the controller), complementing the conversational agent.

---

## 8. Data model (Automotive Cloud + extensions)

| Object / area | Role |
|---------------|------|
| **Lead** | Phone-first identity; address/ZIP capture; conversion path. |
| **`Test_Drive__c`** | Single record for booking lifecycle: dealer, vehicle, definition, date/time, slot label, status (Draft, Pending DL Verification, DL Verified, DL Verification Failed, Test Drive Scheduled, Completed, Cancelled, …), DL fields, upload URL, routing priority, pincode, booking id, etc. |
| **`Review__c`** | Customer reviews linked to test drive, vehicle, account, lead; ratings and descriptions. |
| **`VehicleDef_Dealer__c`** | Which dealers stock which vehicle definitions, pincode, availability flags. |
| **`WhatsApp_Message__c`** | Optional message-level audit trail. |
| **`Webhook_Log__c`** | Webhook / integration diagnostics. |
| **User** extension | e.g. `Dealer_Zip__c` where used for dealer users. |

Standard **Vehicle** / **VehicleDefinition** / **Account** objects participate per Automotive Cloud patterns and existing metadata.

---

## 9. Data Cloud alignment

**Data stream definitions** under `dataStreamDefinitions/` ingest CRM entities via **SalesforceDotCom_Home** with **FULL_REFRESH** extract mode, including at minimum:

- `Lead_Home`, `Test_Drive_c_Home`, `Review_c_Home`, `Vehicle_Home`, `VehicleDefinition_Home`, `Account_Home`, `AccountTeamMember_Home`, `Contact_Home`, `Asset_Home`, `CurrencyType_Home`

**Data source objects** under `dataSourceObjects/` mirror these entities for Data Cloud mapping (including `_Home1` variants where present).

This satisfies the hackathon **Data Cloud** requirement at the **ingest / unified profile data foundation** layer; **calculated insights**, **identity resolution**, and **activations** can be described as roadmap items once provisioned in the org.

---

## 10. Security, integration, and operations

- **Live WhatsApp:** Digital Engagement and **Meta-approved** templates—follow Salesforce and Meta admin guidance; no custom Graph secrets required for the path you used in production.  
- **If Apex Graph / webhook classes are ever activated:** Move tokens, verify values, and phone number IDs into **Named Credentials**, **External Credentials**, or **protected Custom Metadata**; never commit production secrets.  
- **Remote site / CORS:** Needed only for direct Graph or media callouts (e.g. if `WhatsAppService` / webhook path were turned on).  
- **Permission sets / profiles** in `permissionsets/` and `profiles/` grant agent users, integration users, and guest/community access appropriate to your org design.  
- **Field-level security** on `Test_Drive__c` and PII on Lead for Experience guest policies.

---

## 11. Outcomes for Electra Cars

- **Guests** book through **conversation** instead of a **static long form**, on **WhatsApp** or the **Electra website**.  
- **CRM accuracy** improves because model, ZIP, dealer, and slot are **validated in flow** and stored on **`Test_Drive__c`**.  
- **Operations** gain **queue-based verification**, **routing priority**, and **status-driven** handoffs.  
- **Marketing and analytics** gain a path to **Data Cloud** on the same objects the agent updates.  
- **One agent definition** reduces duplicate maintenance across **web** and **WhatsApp**.

---

## 12. Repository map (quick reference)

| Area | Key artifacts |
|------|----------------|
| **Agent (bot)** | `bots/Agentforce_Service_Agent/Agentforce_Service_Agent.bot-meta.xml`, `bots/Agentforce_Service_Agent/v1.botVersion-meta.xml` |
| **GenAI plugins** | `genAiPlugins/Book_Test_Drive.genAiPlugin-meta.xml`, `Review_Test_Drive.genAiPlugin-meta.xml`, `Reschedule_or_Cancel_Test_Drive.genAiPlugin-meta.xml`, `Customer_onboarding_Assistance.genAiPlugin-meta.xml` |
| **GenAI functions** | `genAiFunctions/Lookup_Lead_By_Phone/`, `Create_Lead_From_Phone_And_Name/`, `Get_Electra_Quick_Options/`, `Get_Test_Drive_Options/`, `Case_Status/` |
| **Test drive & routing Apex** | `ElectraCreateTestDriveAction`, `ElectraRescheduleTestDriveAction`, `ElectraCancelTestDriveAction`, `ElectraFetchTestDrivesAction`, `ElectraFetchVehiclesAction`, `ElectraFetchDealersAction`, `ElectraFetchAvailableDatesAction`, `ElectraFetchTimeSlotsAction`, `TestDriveTriggerHandler`, `TestDriveTrigger.trigger`, `RoutingPriorityCalculator`, `DealerRoutingService`, `DealerSkill*` classes |
| **Reviews** | `ElectraFetchReviewAction`, `ElectraSaveReviewAction`, `TestDriveReviewService` |
| **DL** | `ElectraUploadDLController`, `ElectraUploadDLVFController`, `ElectraTriggerDLUploadRequest`, LWC `electraDLUpload` |
| **Lead** | `ElectraLookupLeadByPhoneAction`, `ElectraCreateLeadAction` |
| **Prompt / AI summary** | `ElectraAgentTemplateController.cls` → template `Electra_Agent_Template` |
| **WhatsApp (live)** | `messagingChannels/*.xml`, Agentforce bot context for WhatsApp; **Digital Engagement** templates / session messaging (org config) |
| **WhatsApp (Apex, not used live)** | `WhatsAppService`, `WhatsAppWebhookHandler`, `WhatsAppDirectAPI`, `WhatsAppFreeFormService`, `sendFreeFormMessage` — retained in repo only |
| **WhatsApp audit object** | `objects/WhatsApp_Message__c/` (optional use) |
| **Messaging & embedded chat** | `messagingChannels/*.xml`, `EmbeddedServiceConfig/Electra_cars_chat_deployment.EmbeddedServiceConfig-meta.xml` |
| **Website (LWR/B2C)** | `digitalExperiences/site/AutoCloudExperience1/` |
| **Site LWCs** | `lwc/vehicleShowcaseCmp`, `vehicleDetailsCmp`, `electraDLUpload`, `navigationBanner`, `eventBanner`, … |
| **Flows** | `Test_Drive_Before_Save`, `Service_Agent_Route_to_Work`, `voice_agent_route`, `User_After_Save_Flow`, … |
| **Data Cloud ingest** | `dataStreamDefinitions/*`, `dataSourceObjects/*` |
| **Omni / skills** | `serviceChannels/`, `queues/`, `queueRoutingConfigs/`, `skills/`, `presenceUserConfigs/`, `servicePresenceStatuses/` |

---

## 13. Org-specific configuration (not fully in source)

Exact **Meta template** names, **live** Graph credentials, **production** webhook URLs, **Experience Cloud** live URL, and **Data Cloud** activation schedules are **environment-specific**. Document them in the hackathon submission with **screenshots and links** rather than asserting values here.

---

*This overview reflects the metadata and Apex present in this repository plus the hackathon scenario text you provided. It is written in the same narrative style as the sample “Warranty Intelligence” document for judge readability; technical diagrams and numbered TDD sections remain in `docs/01-TDD-Test-Drive-Agent.md`.*
