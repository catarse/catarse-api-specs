-- Set default connected user to empty string
ALTER DATABASE :db SET user_vars.user_id TO '';

INSERT INTO public.project_states (state, state_order) VALUES
    ('deleted', 'archived'),
    ('rejected', 'created'),
    ('draft', 'created'),
    ('in_analysis', 'created'),
    ('approved', 'publishable'),
    ('online', 'published'),
    ('waiting_funds', 'published'),
    ('failed', 'finished'),
    ('successful', 'finished');

INSERT INTO public.states (id, name, acronym) VALUES
    (1, 'Rio de Janeiro', 'RJ');

INSERT INTO public.cities (id, name, state_id) VALUES
    (1, 'Rio de Janeiro (Capital)', 1);

INSERT INTO public.categories (id, name_pt) VALUES
    (1, 'Música');

INSERT INTO public.users (id, email) VALUES
    (1, 'foo@bar.com');

INSERT INTO public.projects (id, name, user_id, category_id, permalink) VALUES
    (1, 'Projeto tudo ou nada', 1, 1, 'tudo_ou_nada');

INSERT INTO public.projects (id, name, user_id, category_id, permalink) VALUES
    (2, 'Projeto flexível', 1, 1, 'flexivel');

INSERT INTO public.flexible_projects (id) VALUES
    (2);

-- Refresh all materialized views
REFRESH MATERIALIZED VIEW "1".user_totals;
REFRESH MATERIALIZED VIEW "1".statistics;
