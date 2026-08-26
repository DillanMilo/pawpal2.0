const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
};

type ServiceType = 'petStore' | 'veterinarian' | 'grooming' | 'boarding';

type PlacesRequest = {
  action: 'nearby' | 'location' | 'text' | 'details';
  type?: ServiceType;
  latitude?: number;
  longitude?: number;
  radius?: number;
  locationQuery?: string;
  placeId?: string;
};

const placesBaseUrl = 'https://maps.googleapis.com/maps/api/place';
const geocodeBaseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';

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

function getApiKey() {
  const key = Deno.env.get('GOOGLE_PLACES_API_KEY');
  if (!key) {
    throw new Error('GOOGLE_PLACES_API_KEY is not configured');
  }
  return key;
}

function getSupabaseConfig() {
  const url = Deno.env.get('SUPABASE_URL');
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY');

  if (!url || !anonKey) {
    throw new Error('Supabase auth configuration is not available');
  }

  return { url, anonKey };
}

function getSearchQuery(type: ServiceType) {
  switch (type) {
    case 'petStore':
      return 'pet store';
    case 'veterinarian':
      return 'veterinarian';
    case 'grooming':
      return 'pet groomer';
    case 'boarding':
      return 'pet boarding kennel pet hotel dog daycare';
  }
}

function getPlaceType(type: ServiceType) {
  switch (type) {
    case 'petStore':
      return 'pet_store';
    case 'veterinarian':
      return 'veterinary_care';
    case 'grooming':
      return null;
    case 'boarding':
      return null;
  }
}

function requireServiceType(type: ServiceType | undefined): ServiceType {
  if (
    !type ||
    !['petStore', 'veterinarian', 'grooming', 'boarding'].includes(type)
  ) {
    throw new Error('A valid service type is required');
  }
  return type;
}

function authenticationError() {
  return new Response(JSON.stringify({ error: 'Authentication required' }), {
    status: 401,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

async function requireAuthenticatedUser(request: Request) {
  const authHeader = request.headers.get('authorization');
  const token = authHeader?.replace(/^Bearer\s+/i, '');

  if (!token) {
    throw authenticationError();
  }

  const { url, anonKey } = getSupabaseConfig();
  const response = await fetch(`${url}/auth/v1/user`, {
    headers: {
      apikey: anonKey,
      authorization: `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    throw authenticationError();
  }

  const user = await response.json();
  if (!user?.id) {
    throw authenticationError();
  }
}

async function fetchGoogleJson(url: URL) {
  const response = await fetch(url);
  const data = await response.json();

  if (!response.ok) {
    throw new Error(`Google request failed with status ${response.status}`);
  }

  if (data.status && !['OK', 'ZERO_RESULTS'].includes(data.status)) {
    throw new Error(data.error_message ?? `Google returned ${data.status}`);
  }

  return data;
}

async function searchNearby(request: PlacesRequest, key: string) {
  const type = requireServiceType(request.type);
  const latitude = Number(request.latitude);
  const longitude = Number(request.longitude);
  const radius = Number(request.radius ?? 10000);

  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
    throw new Error('Latitude and longitude are required');
  }

  // Grooming has no dedicated legacy place type. Sending it as `pet_store`
  // caused ordinary supply stores to leak into Grooming results. Text Search
  // makes the requested service the primary query instead. Boarding uses the
  // same path until the production key is moved to Places API (New), where
  // `pet_boarding_service` is available as a strict type.
  const usesServiceQuery = type === 'grooming' || type === 'boarding';
  const url = new URL(
    `${placesBaseUrl}/${usesServiceQuery ? 'textsearch' : 'nearbysearch'}/json`,
  );
  url.searchParams.set('location', `${latitude},${longitude}`);
  url.searchParams.set('radius', String(radius));
  if (usesServiceQuery) {
    url.searchParams.set('query', getSearchQuery(type));
  } else {
    const placeType = getPlaceType(type);
    if (placeType) url.searchParams.set('type', placeType);
    url.searchParams.set('keyword', getSearchQuery(type));
  }
  url.searchParams.set('key', key);

  return await fetchGoogleJson(url);
}

async function searchText(request: PlacesRequest, key: string) {
  const type = requireServiceType(request.type);
  const locationQuery = request.locationQuery?.trim();
  if (!locationQuery) throw new Error('Location query is required');

  const url = new URL(`${placesBaseUrl}/textsearch/json`);
  url.searchParams.set('query', `${getSearchQuery(type)} near ${locationQuery}`);
  url.searchParams.set('key', key);

  return await fetchGoogleJson(url);
}

async function searchLocation(request: PlacesRequest, key: string) {
  const locationQuery = request.locationQuery?.trim();
  if (!locationQuery) throw new Error('Location query is required');

  const geocodeUrl = new URL(geocodeBaseUrl);
  geocodeUrl.searchParams.set('address', locationQuery);
  geocodeUrl.searchParams.set('key', key);

  const geocodeData = await fetchGoogleJson(geocodeUrl);
  const firstResult = geocodeData.results?.[0];
  const location = firstResult?.geometry?.location;

  if (!location) {
    return await searchText(request, key);
  }

  return await searchNearby(
    {
      ...request,
      latitude: location.lat,
      longitude: location.lng,
    },
    key,
  );
}

async function getDetails(request: PlacesRequest, key: string) {
  if (!request.placeId) throw new Error('Place ID is required');

  const url = new URL(`${placesBaseUrl}/details/json`);
  url.searchParams.set('place_id', request.placeId);
  url.searchParams.set(
    'fields',
    [
      'place_id',
      'name',
      'formatted_address',
      'formatted_phone_number',
      'international_phone_number',
      'website',
      'url',
      'rating',
      'user_ratings_total',
      'geometry',
      'opening_hours',
      'photos',
    ].join(','),
  );
  url.searchParams.set('key', key);

  return await fetchGoogleJson(url);
}

async function proxyPhoto(request: Request, key: string) {
  const url = new URL(request.url);
  const photoReference = url.searchParams.get('photo_reference');

  if (!photoReference) {
    return jsonResponse({ error: 'photo_reference is required' }, { status: 400 });
  }

  const photoUrl = new URL(`${placesBaseUrl}/photo`);
  photoUrl.searchParams.set('maxwidth', url.searchParams.get('maxwidth') ?? '600');
  photoUrl.searchParams.set('photo_reference', photoReference);
  photoUrl.searchParams.set('key', key);

  const googleResponse = await fetch(photoUrl, { redirect: 'manual' });
  const redirectUrl = googleResponse.headers.get('location');

  if (redirectUrl) {
    return new Response(null, {
      status: 302,
      headers: {
        ...corsHeaders,
        Location: redirectUrl,
        'Cache-Control': 'public, max-age=86400',
      },
    });
  }

  if (!googleResponse.ok) {
    return jsonResponse(
      { error: `Photo request failed with status ${googleResponse.status}` },
      { status: googleResponse.status },
    );
  }

  return new Response(googleResponse.body, {
    status: googleResponse.status,
    headers: {
      ...corsHeaders,
      'Content-Type':
        googleResponse.headers.get('content-type') ?? 'application/octet-stream',
      'Cache-Control': 'public, max-age=86400',
    },
  });
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const key = getApiKey();
    const url = new URL(request.url);

    if (request.method === 'GET' && url.pathname.endsWith('/photo')) {
      return await proxyPhoto(request, key);
    }

    await requireAuthenticatedUser(request);

    if (request.method !== 'POST') {
      return jsonResponse({ error: 'Method not allowed' }, { status: 405 });
    }

    const body = (await request.json()) as PlacesRequest;

    switch (body.action) {
      case 'nearby':
        return jsonResponse(await searchNearby(body, key));
      case 'location':
        return jsonResponse(await searchLocation(body, key));
      case 'text':
        return jsonResponse(await searchText(body, key));
      case 'details':
        return jsonResponse(await getDetails(body, key));
      default:
        return jsonResponse({ error: 'Unsupported action' }, { status: 400 });
    }
  } catch (error) {
    if (error instanceof Response) return error;

    return jsonResponse(
      { error: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 },
    );
  }
});
