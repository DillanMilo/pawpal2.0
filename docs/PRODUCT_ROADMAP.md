# PawPal Product Roadmap

## Is PawPal ready to justify Plus?

Yes, with a reliability-first launch. PawPal already combines pet profiles,
medical records and documents, recurring reminders, appointments, activity
history, passports, notifications, discovery, and gamification. That is enough
ongoing utility for a $4.99 monthly / $29.99 annual organizer subscription.

The product does not need AI to justify the initial price. It does need trusted
data recovery, clear limits, reliable notifications, support, export, and
correct subscription handling. Those are more valuable at launch than a broad
AI assistant.

## Phase 0 — Subscription-safe launch

- Complete Apple, Google, RevenueCat, Stripe, and webhook configuration
- Complete database and Storage backup/restore launch gate
- [x] Add full account data export, including original documents
- Contextual upgrade prompts for each launch Free limit are implemented; add
  regression coverage against the deployed database policies
- Add subscription analytics without sending pet-health content
- Add billing issue, grace period, cancel, restore, and refund support flows
- Add Terms, Privacy, Subscription Terms, and a public support URL
- Validate reminders across time zones, restarts, and permission changes

## Phase 1 — Stronger non-AI premium value

- Household and caregiver invitations with roles and an audit history
- Assignable care tasks and confirmation that medication/care was completed
- Weight trends, medication adherence, and medical timeline dashboards
- Vet-ready PDF/CSV report generation
- Emergency card and improved passport sharing
- Document categories, search, retention controls, and storage usage display
- Optional Family tier only after shared-household value is real

## Phase 2 — Narrow, auditable AI

Start with workflows that save typing and can show their source:

1. Extract structured fields from vaccination cards, prescriptions, and vet
   documents. The user reviews every field before saving.
2. Generate a chronological visit summary based only on selected records, with
   citations back to those records.
3. Prepare questions for an upcoming vet visit from user-selected history.
4. Explain trends in logged weight, activity, or medication adherence without
   diagnosing disease.

AI output must be labeled, reviewable, and excluded from medical records until
the user explicitly saves it. Do not market AI as veterinary diagnosis,
emergency triage, or a replacement for professional care.

## Phase 3 — Integrations and growth

- Wearables and smart feeders after data-consent and deletion flows exist
- Vet/clinic record import and secure sharing
- Pet insurance and telehealth integrations with clear commercial disclosure
- Sponsored provider listings separated from organic results
- Internationalization and region-aware billing experiments

## Pricing evolution

- Launch: Free + Plus at $4.99/month or $29.99/year
- Test $39.99/year for new cohorts after reports and household collaboration
- Consider Family at $7.99/month or $59.99/year only with multiple caregiver
  accounts, roles, task coordination, and higher storage
- Do not charge per pet and do not offer lifetime access while infrastructure
  costs recur

## Release criteria for AI

- A written intended-use and prohibited-use statement
- Evaluation set covering extraction accuracy and unsafe medical claims
- Source citations and user confirmation for saved fields
- Clear model/provider data retention and training settings
- Rate limits, cost ceilings, audit logs, and deletion behavior
- Escalation language for emergencies and uncertain outputs
- Monitoring for quality, cost, latency, and user corrections
