-- Set default connected user to empty string
ALTER DATABASE :db SET user_vars.user_id TO '';

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


INSERT INTO public.banks (id, name, code) VALUES
       (1, 'Bradesco', '237');

INSERT INTO public.states (id, name, acronym) VALUES
    (1, 'Rio de Janeiro', 'RJ');

INSERT INTO public.cities (id, name, state_id) VALUES
    (1, 'Rio de Janeiro (Capital)', 1);

INSERT INTO public.categories (id, name_pt) VALUES
    (1, 'Música');

INSERT INTO public.users (id, email, name, admin) VALUES
    (1, 'relaizador@bar.com', 'Realizador de vários projetos', FALSE),
    (2, 'apoiador@bar.com', 'Apoiador', FALSE),
    (3, 'chuck@norris.com', 'Admin', TRUE);

INSERT INTO public.category_followers (category_id, user_id) VALUES
    (1, 1);

INSERT INTO public.projects (id, name, state, user_id, category_id, permalink, headline, uploaded_image, about_html) VALUES
    (1, 'Rascunho de projeto tudo ou nada', 'draft',  1, 1, 'teste_tudo_ou_nada','headline', 'https::/amazon/some_image.jpg', 'sobre o projeto tudo ou nada'),
    (2, 'Rascunho de projeto flexível',     'draft',  1, 1, 'teste_flexivel',    'headline', 'https::/amazon/some_image.jpg', 'sobre o projeto flex'),
    (3, 'Projeto tudo ou nada no ar',       'online', 1, 1, 'tudo_ou_nada',      'headline', 'https::/amazon/some_image.jpg', 'captando no meu projeto tudo ou nada'),
    (4, 'Projeto flexível no ar',           'draft', 1, 1, 'flexivel',          'headline', 'https::/amazon/some_image.jpg', 'captando no meu projeto flex'),
    (5, 'Projeto tudo ou nada bem sucedido','successful', 1, 1, 'tudo_ou_nada_successful',      'headline', 'https::/amazon/some_image.jpg', 'captando no meu projeto tudo ou nada bem sucedido');

INSERT INTO public.project_accounts
       (id, project_id, bank_id, email, address_street, address_number, address_city, address_neighbourhood, address_state, address_zip_code, phone_number, agency, agency_digit, account, account_digit, owner_name, owner_document) VALUES
       (1, 5, 1, 'realizador@email.com', 'Rua S', '12', 'Lor', 'Foo', 'MG', '334455', '(12) 9999-9999', '1321', '9', '1234', '8', 'Owner name', '111.111.111-11');

INSERT INTO public.project_transitions (id, project_id, to_state, sort_key, most_recent, created_at, updated_at) VALUES
       (1, 3, 'online', 0, true, now(), now()),
       (2, 5, 'successful', 0, true, now(), now());

INSERT INTO public.flexible_projects (id, project_id, state) VALUES
    (1, 2, 'draft'),
    (2, 4, 'online');

INSERT INTO public.flexible_project_transitions (id, flexible_project_id, to_state, sort_key, most_recent, created_at, updated_at) VALUES
       (1, 2, 'online', 0, true, now(), now());

-- Refresh all materialized views
REFRESH MATERIALIZED VIEW "1".user_totals;
REFRESH MATERIALIZED VIEW "1".statistics;

INSERT INTO balance_transactions (project_id, event_name, user_id, amount) VALUES
       (5, 'successful_project_pledged', 1, 100),
       (5, 'catarse_project_service_fee', 1, -13);

INSERT INTO balance_transactions (event_name, user_id, amount) VALUES
       ('for_fun_credits', 2, 10);


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
