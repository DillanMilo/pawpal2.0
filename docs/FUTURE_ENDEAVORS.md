# PawPal Future Endeavors

> Beta feedback captured: 2026-08-26

This document holds promising post-launch product ideas that should be validated
before they become committed roadmap work. PawPal's immediate priority remains
store readiness and learning from its first real users.

## 1. Improve grooming search quality

### Observed bug

Pet shops can appear in the Grooming results. The current Google Places proxy
uses the broad `pet_store` place type for grooming because the legacy Places API
does not provide a dedicated grooming type. A `pet grooming` keyword helps, but
does not reliably exclude ordinary pet-supply stores.

### Proposed fix

- [ ] Create a reproducible set of grooming searches in several locations.
- [x] Prefer a grooming-specific text/keyword query over treating every
  `pet_store` as a groomer.
- [ ] Filter or rank results using business name, Google categories, and place
  details so a listing needs positive grooming evidence.
- [ ] Keep legitimate mixed businesses that offer both retail and grooming.
- [ ] Add proxy/service tests proving an ordinary pet shop is not presented as
  a groomer.
- [ ] Recheck empty and low-density locations so stricter filtering does not
  leave users with misleadingly blank results.

This is a search-quality fix rather than a new feature and should be considered
before expanding the Services catalog.

## 2. Boarding, kennels, pet hotels, and doggy daycare

### User value

Add a Boarding & Daycare section to Services for owners who are traveling,
working away from home, or need short-term care. Results could include:

- kennels and overnight boarding;
- pet hotels;
- doggy daycare;
- cat boarding and other species-specific boarding where available.

### Discovery phase

- [ ] Research which Google Places queries and categories produce trustworthy
  boarding results in PawPal's initial launch markets.
- [x] Add a distinct `boarding` service type and Services card.
- [ ] Show useful decision information such as distance, rating, hours, phone,
  website, directions, and supported animals when the source provides it.
- [ ] Clearly label third-party listing data and give users a way to report an
  incorrect or closed provider.
- [ ] Measure searches, listing views, calls, direction requests, and website
  visits before building a booking marketplace.

### Booking marketplace phase

If discovery usage shows real demand, PawPal could let participating providers
accept daycare or boarding requests and pay PawPal a commission or referral fee
for completed bookings. This is a separate product from directory search and
would require:

- provider onboarding and listing ownership verification;
- services, prices, capacity, and live availability;
- booking requests, confirmations, changes, and cancellations;
- payments, refunds, payouts, receipts, and marketplace tax handling;
- vaccination or care-requirement collection with explicit user consent;
- customer support, disputes, no-shows, and provider quality controls;
- clear commercial disclosure for sponsored or commission-paying listings;
- legal review of marketplace, insurance, liability, and local requirements.

Start with a small provider pilot and a lightweight booking-request or referral
flow. Do not build real-time inventory and marketplace payments until providers
and pet owners demonstrate repeat usage.

## 3. Preventive-care and refill reminders

PawPal already supports custom and recurring reminders. The next useful step is
to make common pet-care reminders quicker to create and easier to understand,
not to build a second reminder system.

### Suggested reminder presets

- tick and flea prevention;
- vaccinations and boosters;
- medication doses and refill dates;
- medication or prescription expiration dates;
- deworming.

### Proposed experience

- [x] Add these as guided presets within the existing reminder flow.
- [ ] Let the owner choose the pet, due date, recurrence, lead time, and notes.
- [ ] Where appropriate, offer to create a reminder from a vaccination or
  medication record's next-due, refill, or expiration date.
- [ ] Distinguish a dose reminder from a refill or expiration reminder.
- [ ] Show overdue and upcoming preventive-care items on the existing home and
  reminders surfaces without adding another dashboard.
- [ ] Preserve the existing notification lifecycle for create, complete,
  delete, and recurring reminders.

Schedules must remain user- or veterinarian-entered. PawPal should not infer a
treatment schedule, recommend medication, or present reminders as veterinary
advice. Copy should encourage users to confirm timing with their veterinarian
or the product label.

## Recommended sequence

1. Fix and test the Grooming result contamination bug.
2. Validate existing reminder notifications on physical iOS and Android
   devices, then add preventive-care presets to the same system.
3. Add boarding/daycare discovery and measure whether owners engage with it.
4. Interview local boarding providers and pilot booking requests or referrals.
5. Add payments and commission-based booking only after repeat demand is clear.

## Early success signals

- Grooming searches return materially fewer irrelevant pet shops.
- Owners create and complete preventive-care reminders more often than generic
  custom reminders.
- Boarding users take high-intent actions: call, directions, website, or save.
- A small provider pilot produces completed bookings and repeat customers with
  manageable support needs.
