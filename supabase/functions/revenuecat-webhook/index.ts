import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'jsr:@supabase/supabase-js@2';

type RevenueCatEvent = {
  id?: string;
  type?: string;
  app_user_id?: string;
  original_app_user_id?: string;
  entitlement_ids?: string[];
  product_id?: string;
  store?: string;
  expiration_at_ms?: number | null;
  grace_period_expiration_at_ms?: number | null;
  original_transaction_id?: string | null;
  transaction_id?: string | null;
  period_type?: string;
};

type RevenueCatPayload = {
  api_version?: string;
  event?: RevenueCatEvent;
};

const plusEntitlementId = 'pawpal_plus';

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

function requiredEnv(name: string) {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`${name} is not configured`);
  return value;
}

function secureEquals(left: string, right: string) {
  if (left.length !== right.length) return false;
  let mismatch = 0;
  for (let index = 0; index < left.length; index += 1) {
    mismatch |= left.charCodeAt(index) ^ right.charCodeAt(index);
  }
  return mismatch === 0;
}

async function verifyHmac(rawBody: string, signatureHeader: string) {
  const parts = Object.fromEntries(
    signatureHeader.split(',').map((part) => {
      const separator = part.indexOf('=');
      return separator === -1
        ? [part, '']
        : [part.slice(0, separator), part.slice(separator + 1)];
    }),
  );
  const timestamp = parts.t;
  const expectedSignature = parts.v1;
  const timestampSeconds = Number(timestamp);

  if (!timestamp || !expectedSignature || !Number.isFinite(timestampSeconds)) {
    return false;
  }
  if (Math.abs(Date.now() / 1000 - timestampSeconds) > 300) return false;

  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(requiredEnv('REVENUECAT_WEBHOOK_SIGNING_SECRET')),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign(
    'HMAC',
    key,
    encoder.encode(`${timestamp}.${rawBody}`),
  );
  const computedSignature = [...new Uint8Array(signature)]
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');

  return secureEquals(computedSignature, expectedSignature);
}

function sourceForStore(store: string | undefined) {
  switch ((store ?? '').toUpperCase()) {
    case 'APP_STORE':
    case 'MAC_APP_STORE':
      return 'app_store';
    case 'PLAY_STORE':
      return 'play_store';
    case 'STRIPE':
      return 'stripe';
    default:
      return 'promotional';
  }
}

function statusForEvent(type: string) {
  switch (type) {
    case 'INITIAL_PURCHASE':
    case 'RENEWAL':
    case 'PRODUCT_CHANGE':
    case 'UNCANCELLATION':
    case 'SUBSCRIPTION_EXTENDED':
    case 'TEMPORARY_ENTITLEMENT_GRANT':
      return 'active';
    case 'CANCELLATION':
      return 'canceled';
    case 'BILLING_ISSUE':
      return 'past_due';
    case 'SUBSCRIPTION_PAUSED':
      return 'canceled';
    case 'EXPIRATION':
      return 'expired';
    default:
      return null;
  }
}

function willRenewForEvent(type: string) {
  return ['INITIAL_PURCHASE', 'RENEWAL', 'PRODUCT_CHANGE', 'UNCANCELLATION']
    .includes(type);
}

export default {
  async fetch(request: Request) {
  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  try {
    const expectedAuth = `Bearer ${requiredEnv('REVENUECAT_WEBHOOK_SECRET')}`;
    const providedAuth = request.headers.get('authorization') ?? '';
    if (!secureEquals(providedAuth, expectedAuth)) {
      return jsonResponse({ error: 'Unauthorized' }, 401);
    }

    const rawBody = await request.text();
    const signatureHeader =
      request.headers.get('x-revenuecat-webhook-signature') ?? '';
    if (!(await verifyHmac(rawBody, signatureHeader))) {
      return jsonResponse({ error: 'Invalid webhook signature' }, 401);
    }

    const payload = JSON.parse(rawBody) as RevenueCatPayload;
    const event = payload.event;
    const eventId = event?.id;
    const eventType = event?.type;
    const userId = event?.app_user_id ?? event?.original_app_user_id;

    if (!event || !eventId || !eventType || !userId) {
      return jsonResponse({ error: 'Invalid RevenueCat payload' }, 400);
    }

    // RevenueCat's dashboard test uses a synthetic app user ID that is not a
    // PawPal auth user. Acknowledge it after both auth checks so the integration
    // can be verified without creating orphaned subscription audit records.
    if (eventType === 'TEST') {
      return jsonResponse({ ok: true, test: true });
    }

    const supabase = createClient(
      requiredEnv('SUPABASE_URL'),
      requiredEnv('SUPABASE_SERVICE_ROLE_KEY'),
    );

    const { data: existingEvent, error: existingEventError } = await supabase
      .from('subscription_events')
      .select('event_id')
      .eq('event_id', eventId)
      .maybeSingle();
    if (existingEventError) throw existingEventError;
    if (existingEvent) {
      return jsonResponse({ ok: true, duplicate: true });
    }

    const status = statusForEvent(eventType);
    const affectsPlus =
      (event.entitlement_ids?.includes(plusEntitlementId) ?? false) ||
      eventType === 'EXPIRATION' ||
      eventType === 'BILLING_ISSUE';

    if (status && affectsPlus) {
      const accessEndMs = event.grace_period_expiration_at_ms ??
        event.expiration_at_ms;
      const periodEnd = accessEndMs
        ? new Date(accessEndMs).toISOString()
        : null;

      const { error: entitlementError } = await supabase
        .from('account_entitlements')
        .upsert({
          user_id: userId,
          tier: 'plus',
          status,
          source: sourceForStore(event.store),
          current_period_ends_at: periodEnd,
          product_id: event.product_id ?? null,
          store: event.store ?? null,
          external_customer_id: userId,
          original_transaction_id:
            event.original_transaction_id ?? event.transaction_id ?? null,
          will_renew: willRenewForEvent(eventType),
        }, { onConflict: 'user_id' });

      if (entitlementError) throw entitlementError;
    }

    // Record only after successful mutation. Entitlement upserts are safe to
    // repeat if two deliveries race before either event row is visible.
    const { error: eventError } = await supabase
      .from('subscription_events')
      .insert({
        event_id: eventId,
        user_id: userId,
        event_type: eventType,
        source: 'revenuecat',
        payload,
      });
    if (eventError && eventError.code !== '23505') throw eventError;

    return jsonResponse({ ok: true, ignored: !status || !affectsPlus });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    console.error('RevenueCat webhook failure:', message);
    return jsonResponse({ error: 'Webhook processing failed' }, 500);
  }
  },
};
