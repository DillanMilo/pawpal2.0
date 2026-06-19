import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const buckets = {
  profilePhotos: 'profile-photos',
  petPhotos: 'pet-photos',
  medicalDocs: 'medical-documents',
};

function jsonResponse(body: unknown, init: ResponseInit = {}) {
  return new Response(JSON.stringify(body), {
    ...init,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
      ...(init.headers ?? {}),
    },
  });
}

function requiredEnv(name: string) {
  const value = Deno.env.get(name);
  if (!value) {
    throw new Error(`${name} is not configured`);
  }
  return value;
}

function storagePathFromValue(value: string | null | undefined, bucket: string) {
  if (!value) return null;

  try {
    const url = new URL(value);
    const pathSegments = url.pathname.split('/');
    const bucketIndex = pathSegments.indexOf(bucket);
    if (bucketIndex !== -1 && bucketIndex < pathSegments.length - 1) {
      return pathSegments.slice(bucketIndex + 1).join('/');
    }
  } catch {
    // The value may already be a storage path.
  }

  return value;
}

async function removeStorageObjects(
  supabase: ReturnType<typeof createClient>,
  bucket: string,
  paths: Array<string | null>,
) {
  const uniquePaths = [...new Set(paths.filter(Boolean) as string[])];
  if (uniquePaths.length === 0) return;

  const { error } = await supabase.storage.from(bucket).remove(uniquePaths);
  if (error) {
    console.warn(`Failed to remove objects from ${bucket}:`, error.message);
  }
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, { status: 405 });
  }

  try {
    const supabaseUrl = requiredEnv('SUPABASE_URL');
    const anonKey = requiredEnv('SUPABASE_ANON_KEY');
    const serviceRoleKey = requiredEnv('SUPABASE_SERVICE_ROLE_KEY');
    const authHeader = request.headers.get('authorization');

    if (!authHeader) {
      return jsonResponse({ error: 'Authentication required' }, { status: 401 });
    }

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const { data: authData, error: authError } =
      await userClient.auth.getUser();
    const userId = authData.user?.id;

    if (authError || !userId) {
      return jsonResponse({ error: 'Authentication required' }, { status: 401 });
    }

    const { data: profile } = await adminClient
      .from('users')
      .select('photo_url')
      .eq('id', userId)
      .maybeSingle();

    const { data: pets } = await adminClient
      .from('pets')
      .select('id, photo_url')
      .eq('user_id', userId);

    const petIds = (pets ?? []).map((pet) => pet.id);
    const { data: medicalRecords } = petIds.length
      ? await adminClient
          .from('medical_records')
          .select('document_url')
          .in('pet_id', petIds)
      : { data: [] };

    await removeStorageObjects(adminClient, buckets.profilePhotos, [
      storagePathFromValue(profile?.photo_url, buckets.profilePhotos),
    ]);
    await removeStorageObjects(
      adminClient,
      buckets.petPhotos,
      (pets ?? []).map((pet) =>
        storagePathFromValue(pet.photo_url, buckets.petPhotos),
      ),
    );
    await removeStorageObjects(
      adminClient,
      buckets.medicalDocs,
      (medicalRecords ?? []).map((record) =>
        storagePathFromValue(record.document_url, buckets.medicalDocs),
      ),
    );

    const { error: deleteError } = await adminClient.auth.admin.deleteUser(
      userId,
    );

    if (deleteError) {
      return jsonResponse({ error: deleteError.message }, { status: 500 });
    }

    return jsonResponse({ ok: true });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    return jsonResponse({ error: message }, { status: 500 });
  }
});
