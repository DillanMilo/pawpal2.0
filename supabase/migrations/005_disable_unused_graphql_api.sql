-- PawPal uses Supabase's REST/client APIs, not the generated GraphQL API.
-- Disable pg_graphql to reduce exposed API surface area.
DROP EXTENSION IF EXISTS pg_graphql CASCADE;
