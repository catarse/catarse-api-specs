-- Set default connected user to empty string
ALTER DATABASE :db SET postgrest.claims.user_id TO '';

/*
 * Data for read-only tests
 * The data bellow is shared among several test cases,
 * So make sure no test changes this records.
 * For mutable data look for the next comment section by the end of this file.
 */

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

INSERT INTO public.flexible_project_states (state, state_order) VALUES
    ('deleted', 'archived'),
    ('rejected', 'created'),
    ('draft', 'created'),
    ('online', 'published'),
    ('waiting_funds', 'published'),
    ('successful', 'finished');


INSERT INTO public.states (id, name, acronym) VALUES
    (1, 'Rio de Janeiro', 'RJ');

INSERT INTO public.cities (id, name, state_id) VALUES
    (1, 'Rio de Janeiro (Capital)', 1);

INSERT INTO public.categories (id, name_pt) VALUES
    (1, 'Música');

INSERT INTO public.users (id, email, name) VALUES
    (1, 'relaizador@bar.com', 'Realizador de vários projetos'),
    (2, 'apoiador@bar.com', 'Apoiador');

INSERT INTO public.category_followers (category_id, user_id) VALUES
    (1, 1);

INSERT INTO public.projects (id, city_id, name, state, user_id, category_id, permalink, headline, uploaded_image, about_html) VALUES
    (1, 1, 'Rascunho de projeto tudo ou nada', 'draft',  1, 1, 'teste_tudo_ou_nada','headline', 'https::/amazon/some_image.jpg', 'sobre o projeto tudo ou nada'),
    (2, 1, 'Rascunho de projeto flexível',     'draft',  1, 1, 'teste_flexivel',    'headline', 'https::/amazon/some_image.jpg', 'sobre o projeto flex'),
    (3, 1, 'Projeto tudo ou nada no ar',       'online', 1, 1, 'tudo_ou_nada',      'headline', 'https::/amazon/some_image.jpg', 'captando no meu projeto tudo ou nada'),
    (4, 1, 'Projeto flexível no ar',           'draft', 1, 1, 'flexivel',          'headline', 'https::/amazon/some_image.jpg', 'captando no meu projeto flex');

INSERT INTO public.flexible_projects (id, project_id, state) VALUES
    (1, 2, 'draft'),
    (2, 4, 'online');

-- Refresh all materialized views
REFRESH MATERIALIZED VIEW "1".user_totals;
REFRESH MATERIALIZED VIEW "1".statistics;

/*
 * Create all data that will be modified bellow
 * Add a comment with the file name where it is used.
 * Ex.:
 * -- users.yml
 * INSERT INTO users ...
 */

-- contribution_details.yml
INSERT INTO contributions (id, project_id, user_id, value, payer_email) VALUES
    (1, 4, 1, 10, 'foo@bar.com');

INSERT INTO payments (id, contribution_id, state, key, gateway, payment_method, value) VALUES
    (1, 1, 'paid', 'key 1', 'Payment Gateway', 'Credit Card', 10);


