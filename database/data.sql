-- Set default connected user to empty string
ALTER DATABASE :db SET user_vars.user_id TO '';

-- Refresh all materialized views
REFRESH MATERIALIZED VIEW "1".user_totals;
REFRESH MATERIALIZED VIEW "1".statistics;
