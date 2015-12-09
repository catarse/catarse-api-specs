--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5beta1
-- Dumped by pg_dump version 9.5beta1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: 1; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA "1";
--
-- Name: api_updates; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA api_updates;
--
-- Name: financial; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA financial;
--
-- Name: temp; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA temp;
--
-- Name: time; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA "time";
--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;
--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';
--
-- Name: plv8; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plv8 WITH SCHEMA pg_catalog;
--
-- Name: EXTENSION plv8; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plv8 IS 'PL/JavaScript (v8) trusted procedural language';
--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;
--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track execution statistics of all SQL statements executed';
--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;
--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';
--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;
--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';
--
-- Name: tablefunc; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS tablefunc WITH SCHEMA public;
--
-- Name: EXTENSION tablefunc; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION tablefunc IS 'functions that manipulate whole tables, including crosstab';
--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;
--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';
--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;
--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';
SET search_path = public, pg_catalog;

--
-- Name: project_state_order; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE project_state_order AS ENUM (
    'archived',
    'created',
    'sent',
    'publishable',
    'published',
    'finished'
);
--
-- Name: is_current_and_online(timestamp without time zone, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION is_current_and_online(expires_at timestamp without time zone, state text) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
    SELECT (not public.is_past(expires_at) AND state = 'online');
$$;
SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE projects (
    id integer NOT NULL,
    name text NOT NULL,
    user_id integer NOT NULL,
    category_id integer NOT NULL,
    goal numeric,
    headline text,
    video_url text,
    short_url text,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    about_html text,
    recommended boolean DEFAULT false,
    home_page_comment text,
    permalink text NOT NULL,
    video_thumbnail text,
    state character varying(255) DEFAULT 'draft'::character varying NOT NULL,
    online_days integer,
    online_date timestamp without time zone,
    more_links text,
    first_contributions text,
    uploaded_image character varying(255),
    video_embed_url character varying(255),
    referral_link text,
    sent_to_analysis_at timestamp without time zone,
    audited_user_name text,
    audited_user_cpf text,
    audited_user_moip_login text,
    audited_user_phone_number text,
    sent_to_draft_at timestamp without time zone,
    rejected_at timestamp without time zone,
    traffic_sources text,
    budget text,
    full_text_index tsvector,
    budget_html text,
    expires_at timestamp without time zone,
    city_id integer,
    origin_id integer,
    service_fee numeric DEFAULT 0.13,
    CONSTRAINT permalinkck CHECK ((permalink ~* '\A(\w|-)+\Z'::text))
);
--
-- Name: mode(projects); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION mode(project projects) RETURNS text
    LANGUAGE sql
    AS $$
        SELECT
          CASE WHEN EXISTS ( SELECT 1 FROM flexible_projects WHERE project_id = project.id ) THEN
            'flex'
          ELSE
            'aon'
          END;
      $$;
--
-- Name: remaining_time_json(projects); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION remaining_time_json(projects) RETURNS json
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $_$
            select public.interval_to_json($1.remaining_time_interval)
        $_$;
--
-- Name: state_order(projects); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION state_order(project projects) RETURNS project_state_order
    LANGUAGE sql STABLE
    AS $_$
SELECT public.state_order($1.id);
$_$;
--
-- Name: thumbnail_image(projects, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION thumbnail_image(projects, size text) RETURNS text
    LANGUAGE sql STABLE
    AS $_$
                SELECT
                  'https://' || settings('aws_host')  ||
                  '/' || settings('aws_bucket') ||
                  '/uploads/project/uploaded_image/' || $1.id::text ||
                  '/project_thumb_' || size || '_' || $1.uploaded_image
            $_$;
SET search_path = "1", pg_catalog;

--
-- Name: project_totals; Type: TABLE; Schema: 1; Owner: -
--

CREATE TABLE project_totals (
    project_id integer,
    pledged numeric,
    progress numeric,
    total_payment_service_fee numeric,
    total_contributions bigint,
    total_contributors bigint
);

ALTER TABLE ONLY project_totals REPLICA IDENTITY NOTHING;
SET search_path = public, pg_catalog;

--
-- Name: cities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cities (
    id integer NOT NULL,
    name text NOT NULL,
    state_id integer NOT NULL
);
--
-- Name: flexible_projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE flexible_projects (
    id integer NOT NULL,
    project_id integer NOT NULL,
    state text DEFAULT 'draft'::text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);
--
-- Name: project_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE project_accounts (
    id integer NOT NULL,
    project_id integer NOT NULL,
    bank_id integer,
    email text NOT NULL,
    state_inscription text,
    address_street text NOT NULL,
    address_number text NOT NULL,
    address_complement text,
    address_city text NOT NULL,
    address_neighbourhood text NOT NULL,
    address_state text NOT NULL,
    address_zip_code text NOT NULL,
    phone_number text NOT NULL,
    agency text NOT NULL,
    agency_digit text NOT NULL,
    account text NOT NULL,
    account_digit text NOT NULL,
    owner_name text NOT NULL,
    owner_document text NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    account_type text,
    CONSTRAINT project_accounts_agency_check CHECK ((length(agency) >= 4))
);
--
-- Name: states; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE states (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    acronym character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    CONSTRAINT states_acronym_not_blank CHECK ((length(btrim((acronym)::text)) > 0)),
    CONSTRAINT states_name_not_blank CHECK ((length(btrim((name)::text)) > 0))
);
--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE users (
    id integer NOT NULL,
    email text NOT NULL,
    name text,
    newsletter boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    admin boolean DEFAULT false,
    address_street text,
    address_number text,
    address_complement text,
    address_neighbourhood text,
    address_city text,
    address_state text,
    address_zip_code text,
    phone_number text,
    locale text DEFAULT 'pt'::text NOT NULL,
    cpf text,
    encrypted_password character varying(128) DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying(255),
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying(255),
    last_sign_in_ip character varying(255),
    twitter character varying(255),
    facebook_link character varying(255),
    other_link character varying(255),
    uploaded_image text,
    moip_login character varying(255),
    state_inscription character varying(255),
    channel_id integer,
    deactivated_at timestamp without time zone,
    reactivate_token text,
    address_country text,
    country_id integer,
    authentication_token text DEFAULT md5(((random())::text || (clock_timestamp())::text)) NOT NULL,
    zero_credits boolean DEFAULT false,
    about_html text,
    cover_image text,
    permalink text,
    subscribed_to_project_posts boolean DEFAULT true,
    full_text_index tsvector NOT NULL
);
SET search_path = "1", pg_catalog;

--
-- Name: projects; Type: VIEW; Schema: 1; Owner: -
--

CREATE VIEW projects AS
 SELECT p.id AS project_id,
    p.category_id,
    p.name AS project_name,
    p.headline,
    p.permalink,
    public.mode(p.*) AS mode,
    COALESCE(fp.state, (p.state)::text) AS state,
    public.state_order(p.*) AS state_order,
    p.online_date,
    p.recommended,
    public.thumbnail_image(p.*, 'large'::text) AS project_img,
    public.remaining_time_json(p.*) AS remaining_time,
    p.expires_at,
    COALESCE(( SELECT pt.pledged
           FROM project_totals pt
          WHERE (pt.project_id = p.id)), (0)::numeric) AS pledged,
    COALESCE(( SELECT pt.progress
           FROM project_totals pt
          WHERE (pt.project_id = p.id)), (0)::numeric) AS progress,
    COALESCE(s.acronym, (pa.address_state)::character varying(255)) AS state_acronym,
    u.name AS owner_name,
    COALESCE(c.name, pa.address_city) AS city_name,
    p.full_text_index,
    public.is_current_and_online(p.expires_at, COALESCE(fp.state, (p.state)::text)) AS open_for_contributions
   FROM (((((public.projects p
     JOIN public.users u ON ((p.user_id = u.id)))
     LEFT JOIN public.flexible_projects fp ON ((fp.project_id = p.id)))
     LEFT JOIN public.project_accounts pa ON ((pa.project_id = p.id)))
     LEFT JOIN public.cities c ON ((c.id = p.city_id)))
     LEFT JOIN public.states s ON ((s.id = c.state_id)));
--
-- Name: project_search(text); Type: FUNCTION; Schema: 1; Owner: -
--

CREATE FUNCTION project_search(query text) RETURNS SETOF projects
    LANGUAGE sql STABLE
    AS $$
SELECT
    p.*
FROM
    "1".projects p
WHERE
    (
        p.full_text_index @@ to_tsquery('portuguese', unaccent(query))
        OR
        p.project_name % query
    )
    AND p.state_order >= 'published'
ORDER BY
    p.open_for_contributions DESC,
    p.state_order,
    ts_rank(p.full_text_index, to_tsquery('portuguese', unaccent(query))) DESC,
    p.project_id DESC;
$$;
SET search_path = public, pg_catalog;

--
-- Name: _final_median(numeric[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION _final_median(numeric[]) RETURNS numeric
    LANGUAGE sql IMMUTABLE
    AS $_$
   SELECT AVG(val)
   FROM (
     SELECT val
     FROM unnest($1) val
     ORDER BY 1
     LIMIT  2 - MOD(array_upper($1, 1), 2)
     OFFSET CEIL(array_upper($1, 1) / 2.0) - 1
   ) sub;
$_$;
--
-- Name: approved_at(projects); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION approved_at(project projects) RETURNS timestamp without time zone
    LANGUAGE sql STABLE
    AS $$
        SELECT get_date_from_project_transitions(project.id, 'approved');
    $$;
--
-- Name: assert_not_null(anyelement, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION assert_not_null(field anyelement, field_name text) RETURNS void
    LANGUAGE plpgsql
    AS $_$
BEGIN
  IF field IS NULL THEN
    RAISE EXCEPTION $$% can't be null$$, field_name;
  END IF;
  RETURN;
END;
$_$;
--
-- Name: campaign_mode(projects); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION campaign_mode(project projects) RETURNS text
    LANGUAGE sql
    AS $$
        SELECT
          CASE WHEN EXISTS ( SELECT 1 FROM flexible_projects WHERE project_id = project.id ) THEN
            'flex'
          ELSE
            'aon'
          END;
      $$;
--
-- Name: payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE payments (
    id integer NOT NULL,
    contribution_id integer NOT NULL,
    state text NOT NULL,
    key text NOT NULL,
    gateway text NOT NULL,
    gateway_id text,
    gateway_fee numeric,
    gateway_data json,
    payment_method text NOT NULL,
    value numeric NOT NULL,
    installments integer DEFAULT 1 NOT NULL,
    installment_value numeric,
    paid_at timestamp without time zone,
    refused_at timestamp without time zone,
    pending_refund_at timestamp without time zone,
    refunded_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    full_text_index tsvector,
    deleted_at timestamp without time zone,
    chargeback_at timestamp without time zone
);
--
-- Name: can_delete(payments); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION can_delete(payments) RETURNS boolean
    LANGUAGE sql
    AS $_$
      SELECT
               $1.state = 'pending'
               AND
               (
                 SELECT count(1) AS total_of_days
                 FROM generate_series($1.created_at::date, current_date, '1 day') day
                 WHERE extract(dow from day) not in (0,1)
               )  >= 4
     $_$;
--
-- Name: project_reminders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE project_reminders (
    id integer NOT NULL,
    user_id integer NOT NULL,
    project_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);
--
-- Name: can_deliver(project_reminders); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION can_deliver(project_reminders) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $_$
select exists (
select true from projects p
left join flexible_projects fp on fp.project_id = p.id
where p.expires_at is not null
and p.id = $1.project_id
and coalesce(fp.state, p.state) = 'online'
and public.is_past((p.expires_at - '48 hours'::interval))
and not exists (select true from project_notifications pn
where pn.user_id = $1.user_id and pn.project_id = $1.project_id
and pn.template_name = 'reminder'));
$_$;
--
-- Name: contributions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE contributions (
    id integer NOT NULL,
    project_id integer NOT NULL,
    user_id integer NOT NULL,
    reward_id integer,
    value numeric NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    anonymous boolean DEFAULT false NOT NULL,
    notified_finish boolean DEFAULT false,
    payer_name text,
    payer_email text NOT NULL,
    payer_document text,
    address_street text,
    address_number text,
    address_complement text,
    address_neighbourhood text,
    address_zip_code text,
    address_city text,
    address_state text,
    address_phone_number text,
    payment_choice text,
    payment_service_fee numeric,
    deleted_at timestamp without time zone,
    country_id integer,
    donation_id integer,
    origin_id integer,
    CONSTRAINT backers_value_positive CHECK ((value >= (0)::numeric))
);
--
-- Name: can_refund(contributions); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION can_refund(contributions) RETURNS boolean
    LANGUAGE sql
    AS $_$
      SELECT
        $1.was_confirmed AND
        EXISTS(
          SELECT true
          FROM projects p
          WHERE p.id = $1.project_id and p.state = 'failed'
        )
    $_$;
--
-- Name: confirmed_states(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION confirmed_states() RETURNS text[]
    LANGUAGE sql
    AS $$
      SELECT '{"paid", "pending_refund", "refunded"}'::text[];
    $$;
--
-- Name: current_user_already_in_reminder(projects); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION current_user_already_in_reminder(projects) RETURNS boolean
    LANGUAGE sql
    AS $_$
        select public.user_has_reminder_for_project(current_user_id(), $1.id);
      $_$;
--
-- Name: current_user_has_contributed_to_project(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION current_user_has_contributed_to_project(integer) RETURNS boolean
    LANGUAGE sql STABLE
    AS $_$
        select public.user_has_contributed_to_project(current_user_id(), $1);
      $_$;
--
-- Name: current_user_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION current_user_id() RETURNS integer
    LANGUAGE sql
    AS $$
        SELECT nullif(current_setting('user_vars.user_id'), '')::integer;
      $$;
--
-- Name: delete_category_followers(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION delete_category_followers() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        begin
          delete from public.category_followers 
          where 
            user_id = current_user_id()
            and category_id = OLD.category_id;
          return old;
        end;
      $$;
--
-- Name: delete_project_reminder(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION delete_project_reminder() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        begin
          delete from public.project_reminders
          where
            user_id = current_user_id()
            and project_id = OLD.project_id;

          return old;
        end;
      $$;
--
-- Name: deleted_at(projects); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION deleted_at(project projects) RETURNS timestamp without time zone
    LANGUAGE sql STABLE
    AS $$
        SELECT get_date_from_project_transitions(project.id, 'deleted');
    $$;
--
-- Name: deps_restore_dependencies(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION deps_restore_dependencies(p_view_schema character varying, p_view_name character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
      declare
        v_curr record;
      begin
      for v_curr in 
      (
        select deps_ddl_to_run 
        from deps_saved_ddl
        where deps_view_schema = p_view_schema and deps_view_name = p_view_name
        order by deps_id desc
      ) loop
        execute v_curr.deps_ddl_to_run;
      end loop;
      delete from deps_saved_ddl
      where deps_view_schema = p_view_schema and deps_view_name = p_view_name;
      end;
      $$;
--
-- Name: deps_save_and_drop_dependencies(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION deps_save_and_drop_dependencies(p_view_schema character varying, p_view_name character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
      declare
        v_curr record;
      begin
      for v_curr in 
      (
        select obj_schema, obj_name, obj_type from
        (
        with recursive recursive_deps(obj_schema, obj_name, obj_type, depth) as 
        (
          select p_view_schema, p_view_name, null::varchar, 0
          union
          select dep_schema::varchar, dep_name::varchar, dep_type::varchar, recursive_deps.depth + 1 from 
          (
            select ref_nsp.nspname ref_schema, ref_cl.relname ref_name, 
          rwr_cl.relkind dep_type,
            rwr_nsp.nspname dep_schema,
            rwr_cl.relname dep_name
            from pg_depend dep
            join pg_class ref_cl on dep.refobjid = ref_cl.oid
            join pg_namespace ref_nsp on ref_cl.relnamespace = ref_nsp.oid
            join pg_rewrite rwr on dep.objid = rwr.oid
            join pg_class rwr_cl on rwr.ev_class = rwr_cl.oid
            join pg_namespace rwr_nsp on rwr_cl.relnamespace = rwr_nsp.oid
            where dep.deptype = 'n'
            and dep.classid = 'pg_rewrite'::regclass
          ) deps
          join recursive_deps on deps.ref_schema = recursive_deps.obj_schema and deps.ref_name = recursive_deps.obj_name
          where (deps.ref_schema != deps.dep_schema or deps.ref_name != deps.dep_name)
        )
        select obj_schema, obj_name, obj_type, depth
        from recursive_deps 
        where depth > 0
        ) t
        group by obj_schema, obj_name, obj_type
        order by max(depth) desc
      ) loop

        insert into deps_saved_ddl(deps_view_schema, deps_view_name, deps_ddl_to_run)
        select p_view_schema, p_view_name, 'COMMENT ON ' ||
        case
        when c.relkind = 'v' then 'VIEW'
        when c.relkind = 'm' then 'MATERIALIZED VIEW'
        else ''
        end
        || ' ' || n.nspname || '.' || c.relname || ' IS ''' || replace(d.description, '''', '''''') || ''';'
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        join pg_description d on d.objoid = c.oid and d.objsubid = 0
        where n.nspname = v_curr.obj_schema and c.relname = v_curr.obj_name and d.description is not null;

        insert into deps_saved_ddl(deps_view_schema, deps_view_name, deps_ddl_to_run)
        select p_view_schema, p_view_name, 'COMMENT ON COLUMN ' || quote_ident(n.nspname) || '.' || quote_ident(c.relname) || '.' || quote_ident(a.attname) || ' IS ''' || replace(d.description, '''', '''''') || ''';'
        from pg_class c
        join pg_attribute a on c.oid = a.attrelid
        join pg_namespace n on n.oid = c.relnamespace
        join pg_description d on d.objoid = c.oid and d.objsubid = a.attnum
        where n.nspname = v_curr.obj_schema and c.relname = v_curr.obj_name and d.description is not null;
        
        insert into deps_saved_ddl(deps_view_schema, deps_view_name, deps_ddl_to_run)
        select p_view_schema, p_view_name, 'GRANT ' || privilege_type || ' ON ' || quote_ident(table_schema) || '.' || quote_ident(table_name) || ' TO ' || grantee
        from information_schema.role_table_grants
        where table_schema = v_curr.obj_schema and table_name = v_curr.obj_name;
        
        if v_curr.obj_type = 'v' then
          insert into deps_saved_ddl(deps_view_schema, deps_view_name, deps_ddl_to_run)
          select p_view_schema, p_view_name, 'CREATE VIEW ' || quote_ident(v_curr.obj_schema) || '.' || quote_ident(v_curr.obj_name) || ' AS ' || view_definition
          from information_schema.views
          where table_schema = v_curr.obj_schema and table_name = v_curr.obj_name;
        elsif v_curr.obj_type = 'm' then
          insert into deps_saved_ddl(deps_view_schema, deps_view_name, deps_ddl_to_run)
          select p_view_schema, p_view_name, 'CREATE MATERIALIZED VIEW ' || quote_ident(v_curr.obj_schema) || '.' || quote_ident(v_curr.obj_name) || ' AS ' || definition
          from pg_matviews
          where schemaname = v_curr.obj_schema and matviewname = v_curr.obj_name;
        end if;
        
        execute 'DROP ' ||
        case 
          when v_curr.obj_type = 'v' then 'VIEW'
          when v_curr.obj_type = 'm' then 'MATERIALIZED VIEW'
        end
        || ' ' || quote_ident(v_curr.obj_schema) || '.' || quote_ident(v_curr.obj_name);
        
      end loop;
      end;
      $$;
--
-- Name: elapsed_time_json(projects); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION elapsed_time_json(projects) RETURNS json
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $_$
            select public.interval_to_json(least(now(), $1.expires_at) - $1.online_date)
        $_$;
--
-- Name: failed_at(projects); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION failed_at(project projects) RETURNS timestamp without time zone
    LANGUAGE sql STABLE
    AS $$
        SELECT get_date_from_project_transitions(project.id, 'failed');
    $$;
--
-- Name: get_date_from_project_transitions(integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION get_date_from_project_transitions(project_id integer, state text) RETURNS timestamp without time zone
    LANGUAGE sql STABLE
    AS $_$
        SELECT created_at
        FROM "1".project_transitions
        WHERE state = $2
        AND project_id = $1
    $_$;
--
-- Name: has_published_projects(users); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION has_published_projects(users) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $_$
        select true from public.projects p where p.is_published and p.user_id = $1.id
      $_$;
--
-- Name: in_analysis_at(projects); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION in_analysis_at(project projects) RETURNS timestamp without time zone
    LANGUAGE sql STABLE
    AS $$
        SELECT get_date_from_project_transitions(project.id, 'in_analysis');
    $$;
--
-- Name: insert_category_followers(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION insert_category_followers() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        declare
          follow "1".category_followers;
        begin
          select
            c.category_id,
            c.user_id
          from public.category_followers c
          where
            c.user_id = current_user_id()
            and c.category_id = NEW.category_id
          into follow;

          if found then
            return follow;
          end if;

          insert into public.category_followers (user_id, category_id)
          values (current_user_id(), NEW.category_id);

          return new;
        end;
      $$;
--
-- Name: insert_project_reminder(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION insert_project_reminder() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        declare
          reminder "1".project_reminders;
        begin
          select
            pr.project_id,
            pr.user_id
          from public.project_reminders pr
          where
            pr.user_id = current_user_id()
            and pr.project_id = NEW.project_id
          into reminder;

          if found then
            return reminder;
          end if;

          insert into public.project_reminders (user_id, project_id) values (current_user_id(), NEW.project_id);

          return new;
        end;
      $$;
--
-- Name: interval_to_json(interval); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION interval_to_json(interval) RETURNS json
    LANGUAGE sql IMMUTABLE SECURITY DEFINER
    AS $_$
            select (
              case
              when $1 <= '0 seconds'::interval then
                json_build_object('total', 0, 'unit', 'seconds')
              else
                case
                when $1 >= '1 day'::interval then
                  json_build_object('total', extract(day from $1), 'unit', 'days')
                when $1 >= '1 hour'::interval and $1 < '24 hours'::interval then
                  json_build_object('total', extract(hour from $1), 'unit', 'hours')
                when $1 >= '1 minute'::interval and $1 < '60 minutes'::interval then
                  json_build_object('total', extract(minutes from $1), 'unit', 'minutes')
                when $1 < '60 seconds'::interval then
                  json_build_object('total', extract(seconds from $1), 'unit', 'seconds')
                 else json_build_object('total', 0, 'unit', 'seconds') end
              end
            )
        $_$;
--
-- Name: irrf_tax(projects); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION irrf_tax(project projects) RETURNS numeric
    LANGUAGE sql STABLE
    AS $$
        SELECT
            CASE
            WHEN char_length(pa.owner_document) > 14 AND p.total_catarse_fee >= 666.66 THEN
                0.015 * p.total_catarse_fee_without_gateway_fee
            ELSE 0 END
        FROM public.projects p
        LEFT JOIN public.project_accounts pa
            ON pa.project_id = p.id
        WHERE p.id = project.id;
    $$;
--
-- Name: is_confirmed(contributions); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION is_confirmed(contributions) RETURNS boolean
    LANGUAGE sql
    AS $_$
      SELECT EXISTS (
        SELECT true
        FROM 
          payments p 
        WHERE p.contribution_id = $1.id AND p.state = 'paid'
      );
    $_$;
--
-- Name: is_expired("1".projects); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION is_expired(project "1".projects) RETURNS boolean
    LANGUAGE sql STABLE
    AS $_$
    SELECT public.is_past($1.expires_at);
$_$;
--
-- Name: is_expired(projects); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION is_expired(project projects) RETURNS boolean
    LANGUAGE sql STABLE
    AS $_$
    SELECT public.is_past($1.expires_at);
$_$;
--
-- Name: is_owner_or_admin(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION is_owner_or_admin(integer) RETURNS boolean
    LANGUAGE sql STABLE
    AS $_$
              SELECT
                current_user_id() = $1
                OR current_user = 'admin';
            $_$;
--
-- Name: is_past(timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION is_past(expires_at timestamp without time zone) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
    SELECT COALESCE(current_timestamp > expires_at, false);
$$;
--
-- Name: is_published(projects); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION is_published(projects) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $_$
          select $1.state_order >= 'published'::project_state_order;
        $_$;
--
-- Name: is_second_slip(payments); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION is_second_slip(payments) RETURNS boolean
    LANGUAGE sql STABLE
    AS $_$
          SELECT lower($1.payment_method) = 'boletobancario' and EXISTS (select true from payments p
               where p.contribution_id = $1.contribution_id
               and p.id < $1.id
               and lower(p.payment_method) = 'boletobancario')
        $_$;
--
-- Name: near_me("1".projects); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION near_me("1".projects) RETURNS boolean
    LANGUAGE sql STABLE
    AS $_$
    SELECT
      COALESCE($1.state_acronym, (SELECT pa.address_state FROM project_accounts pa WHERE pa.project_id = $1.project_id)) = (SELECT u.address_state FROM users u WHERE u.id = current_user_id());
$_$;
--
-- Name: notify_about_confirmed_payments(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION notify_about_confirmed_payments() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        declare
          v_contribution json;
        begin
          v_contribution := (select
              json_build_object(
                'user_image', u.thumbnail_image,
                'user_name', u.name,
                'project_image', p.thumbnail_image,
                'project_name', p.name)
              from contributions c
              join users u on u.id = c.user_id
              join projects p on p.id = c.project_id
              where not c.anonymous and c.id = new.contribution_id);

          if v_contribution is not null then
            perform pg_notify('new_paid_contributions', v_contribution::text);
          end if;

          return null;
        end;
      $$;
--
-- Name: open_for_contributions(projects); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION open_for_contributions(projects) RETURNS boolean
    LANGUAGE sql STABLE
    AS $_$
    SELECT public.is_current_and_online($1.expires_at, COALESCE((SELECT fp.state FROM flexible_projects fp WHERE fp.project_id = $1.id), $1.state));
$_$;
--
-- Name: original_image(projects); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION original_image(projects) RETURNS text
    LANGUAGE sql STABLE
    AS $_$
          SELECT
            'https://' || settings('aws_host')  ||
            '/' || settings('aws_bucket') ||
            '/uploads/project/uploaded_image/' || $1.id::text ||
             '/' || $1.uploaded_image
      $_$;
--
-- Name: rewards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE rewards (
    id integer NOT NULL,
    project_id integer NOT NULL,
    minimum_value numeric NOT NULL,
    maximum_contributions integer,
    description text NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    row_order integer,
    last_changes text,
    deliver_at timestamp without time zone,
    CONSTRAINT rewards_maximum_backers_positive CHECK ((maximum_contributions >= 0)),
    CONSTRAINT rewards_minimum_value_positive CHECK ((minimum_value >= (0)::numeric))
);
--
-- Name: paid_count(rewards); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION paid_count(rewards) RETURNS bigint
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $_$
      SELECT count(*) 
      FROM payments p join contributions c on c.id = p.contribution_id 
      WHERE p.state = 'paid' AND c.reward_id = $1.id
    $_$;
--
-- Name: pcc_tax(projects); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION pcc_tax(project projects) RETURNS numeric
    LANGUAGE sql STABLE
    AS $$
        SELECT
            CASE
            WHEN char_length(pa.owner_document) > 14 AND p.total_catarse_fee >= 215.05 THEN
                0.0465 * p.total_catarse_fee_without_gateway_fee
            ELSE 0 END
        FROM public.projects p
        LEFT JOIN public.project_accounts pa
            ON pa.project_id = p.id
        WHERE p.id = project.id;
    $$;
--
-- Name: percentage_funded(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION percentage_funded(project_id integer, days_before_expires integer) RETURNS integer
    LANGUAGE sql
    AS $_$
	SELECT 
		((sum(c.value)::numeric / (SELECT p.goal::numeric FROM projects p WHERE p.id = $1)) * 100)::int
	FROM
		contribution_details c
	WHERE 
		c.project_id = $1
		AND ((SELECT p.expires_at FROM projects p WHERE p.id = $1)::date - c.paid_at::date) >= $2;
$_$;
--
-- Name: remaining_time_interval(projects); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION remaining_time_interval(projects) RETURNS interval
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $_$
            select ($1.expires_at - current_timestamp)::interval
          $_$;
--
-- Name: sent_validation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION sent_validation() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
BEGIN
  IF state_order(new) >= 'sent'::project_state_order THEN
    PERFORM assert_not_null(new.about_html, 'about_html');
    PERFORM assert_not_null(new.headline, 'headline');
    IF new.video_thumbnail IS NULL AND new.uploaded_image IS NULL THEN
      RAISE EXCEPTION $$video_thumbnail and uploaded_image can't both be null$$;
    END IF;
    IF EXISTS (SELECT true FROM users u WHERE u.id = new.user_id AND u.name IS NULL) THEN
      RAISE EXCEPTION $$name of project owner can't be null$$;
    END IF;
  END IF;
  RETURN null;
END;
$_$;
--
-- Name: settings(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION settings(name text) RETURNS text
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $_$
        SELECT value FROM settings WHERE name = $1;
      $_$;
--
-- Name: slip_expiration_weekdays(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION slip_expiration_weekdays() RETURNS integer
    LANGUAGE sql STABLE
    AS $$
    SELECT 2;
    $$;
--
-- Name: slip_expired(payments); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION slip_expired(payments) RETURNS boolean
    LANGUAGE sql STABLE
    AS $_$
    SELECT $1.slip_expires_at < current_timestamp;
    $_$;
--
-- Name: slip_expires_at(payments); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION slip_expires_at(payments) RETURNS timestamp without time zone
    LANGUAGE sql STABLE
    AS $_$
SELECT weekdays_from(public.slip_expiration_weekdays(), $1.created_at);
    $_$;
--
-- Name: sold_out(rewards); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION sold_out(reward rewards) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
    SELECT reward.paid_count + reward.waiting_payment_count >= reward.maximum_contributions;
    $$;
--
-- Name: state_order(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION state_order(project_id integer) RETURNS project_state_order
    LANGUAGE sql STABLE
    AS $_$
SELECT
    CASE p.mode
    WHEN 'flex' THEN
        (
        SELECT state_order
        FROM
        flexible_project_states ps
        WHERE
        ps.state = fp.state
        )
    ELSE
        (
        SELECT state_order
        FROM
        project_states ps
        WHERE
        ps.state = p.state
        )
    END
FROM projects p
LEFT JOIN flexible_projects fp on fp.project_id = p.id
WHERE p.id = $1;
$_$;
--
-- Name: successful_at(projects); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION successful_at(project projects) RETURNS timestamp without time zone
    LANGUAGE sql STABLE
    AS $$
        SELECT get_date_from_project_transitions(project.id, 'successful');
    $$;
--
-- Name: thumbnail_image(projects); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION thumbnail_image(projects) RETURNS text
    LANGUAGE sql STABLE
    AS $_$
        SELECT public.thumbnail_image($1, 'small');
      $_$;
--
-- Name: thumbnail_image(users); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION thumbnail_image(users) RETURNS text
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $_$
            SELECT
              'https://' || (SELECT value FROM settings WHERE name = 'aws_host') ||
              '/' || (SELECT value FROM settings WHERE name = 'aws_bucket') ||
              '/uploads/user/uploaded_image/' || $1.id::text ||
              '/thumb_avatar_' || $1.uploaded_image
            $_$;
--
-- Name: total_catarse_fee(projects); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION total_catarse_fee(project projects) RETURNS numeric
    LANGUAGE sql STABLE
    AS $$
        SELECT
            p.service_fee * pt.pledged
        FROM public.projects p
        LEFT JOIN "1".project_totals pt
            ON pt.project_id = p.id
        WHERE p.id = project.id;
    $$;
--
-- Name: total_catarse_fee_without_gateway_fee(projects); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION total_catarse_fee_without_gateway_fee(project projects) RETURNS numeric
    LANGUAGE sql STABLE
    AS $$
        SELECT
            (p.service_fee * pt.pledged) - pt.total_payment_service_fee
        FROM public.projects p
        LEFT JOIN "1".project_totals pt
            ON pt.project_id = p.id
        WHERE p.id = project.id;
    $$;
--
-- Name: update_from_details_to_contributions(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_from_details_to_contributions() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
      DECLARE
       allowed_states text[] := '{"deleted"}';
      BEGIN
       -- Prevent mutiple updates
       IF EXISTS (
        SELECT true
        FROM api_updates.contributions c
        WHERE c.contribution_id <> OLD.id AND transaction_id = txid_current()
       ) THEN
        RAISE EXCEPTION 'Just one contribution update is allowed per transaction';
       END IF;
       INSERT INTO api_updates.contributions
        (contribution_id, user_id, reward_id, transaction_id, updated_at)
       VALUES
        (OLD.id, OLD.user_id, OLD.reward_id, txid_current(), now());

       UPDATE public.contributions
       SET
        user_id = new.user_id,
        reward_id = new.reward_id
       WHERE id = old.contribution_id;

       -- we only allow deleted state in API
       IF new.state <> ALL(allowed_states) THEN
         RAISE EXCEPTION 'State can only be set to % using the API', allowed_states;
       END IF;

       UPDATE public.payments
       SET state = new.state
       WHERE contribution_id = old.contribution_id;

       -- Return updated record
       SELECT * FROM "1".contribution_details cd WHERE cd.id = old.id INTO new;
       RETURN new;
      END;
    $$;
--
-- Name: update_full_text_index(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_full_text_index() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
      new.full_text_index :=  setweight(to_tsvector('portuguese', unaccent(coalesce(NEW.name::text, ''))), 'A') || 
                              setweight(to_tsvector('portuguese', unaccent(coalesce(NEW.permalink::text, ''))), 'C') || 
                              setweight(to_tsvector('portuguese', unaccent(coalesce(NEW.headline::text, ''))), 'B');
      new.full_text_index :=  new.full_text_index || setweight(to_tsvector('portuguese', unaccent(coalesce((SELECT c.name_pt FROM categories c WHERE c.id = NEW.category_id)::text, ''))), 'B');
      RETURN NEW;
    END;
    $$;
--
-- Name: update_payments_full_text_index(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_payments_full_text_index() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
     DECLARE
       v_contribution contributions;
       v_origin origins;
       v_name text;
     BEGIN
       SELECT * INTO v_contribution FROM contributions c WHERE c.id = NEW.contribution_id;
       SELECT * INTO v_origin FROM origins o WHERE o.id = v_contribution.origin_id;
       SELECT u.name INTO v_name FROM users u WHERE u.id = v_contribution.user_id;

       NEW.full_text_index :=  setweight(to_tsvector(unaccent(coalesce(NEW.key::text, ''))), 'A') ||
                               setweight(to_tsvector(unaccent(coalesce(NEW.gateway::text, ''))), 'A') ||
                               setweight(to_tsvector(unaccent(coalesce(NEW.gateway_id::text, ''))), 'A') ||
                               setweight(to_tsvector(unaccent(coalesce(NEW.state::text, ''))), 'A') ||
                               setweight(to_tsvector(unaccent(coalesce((NEW.gateway_data->>'acquirer_name'), ''))), 'B') ||
                               setweight(to_tsvector(unaccent(coalesce((NEW.gateway_data->>'card_brand'), ''))), 'B') ||
                               setweight(to_tsvector(unaccent(coalesce((NEW.gateway_data->>'tid'), ''))), 'C');
       NEW.full_text_index :=  NEW.full_text_index ||
                               setweight(to_tsvector(unaccent(coalesce(v_contribution.payer_email::text, ''))), 'A') ||
                               setweight(to_tsvector(unaccent(coalesce(v_contribution.payer_document::text, ''))), 'A') ||
                               setweight(to_tsvector(unaccent(coalesce(v_contribution.user_id::text, ''))), 'B') ||
                               setweight(to_tsvector(unaccent(coalesce(v_contribution.project_id::text, ''))), 'C');
       NEW.full_text_index :=  NEW.full_text_index ||
                               setweight(to_tsvector(unaccent(coalesce(v_origin.referral::text, ''))), 'B') ||
                               setweight(to_tsvector(unaccent(coalesce(v_origin.domain::text, ''))), 'B');
       NEW.full_text_index :=  NEW.full_text_index || setweight(to_tsvector(unaccent(coalesce(v_name::text, ''))), 'A');
       NEW.full_text_index :=  NEW.full_text_index || (SELECT full_text_index FROM projects p WHERE p.id = v_contribution.project_id);
       RETURN NEW;
     END;
    $$;
--
-- Name: update_user_from_user_details(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_user_from_user_details() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        UPDATE public.users
        SET deactivated_at = new.deactivated_at
        WHERE id = old.id AND is_owner_or_admin(old.id);
        RETURN new;
      END;
    $$;
--
-- Name: update_users_full_text_index(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_users_full_text_index() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
          NEW.full_text_index := to_tsvector(NEW.id::text) ||
            to_tsvector(unaccent(coalesce(NEW.name, ''))) ||
            to_tsvector(unaccent(NEW.email));
          RETURN NEW;
        END;
      $$;
--
-- Name: user_has_contributed_to_project(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION user_has_contributed_to_project(user_id integer, project_id integer) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $_$
        select true from "1".contribution_details c where c.state = any(public.confirmed_states()) and c.project_id = $2 and c.user_id = $1;
      $_$;
--
-- Name: user_has_reminder_for_project(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION user_has_reminder_for_project(user_id integer, project_id integer) RETURNS boolean
    LANGUAGE sql SECURITY DEFINER
    AS $_$
        select exists (select true from public.project_reminders pr where pr.user_id = $1 and pr.project_id = $2);
      $_$;
--
-- Name: user_signed_in(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION user_signed_in() RETURNS boolean
    LANGUAGE sql
    AS $$
        select current_user <> 'anonymous';
      $$;
--
-- Name: uses_credits(payments); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION uses_credits(payments) RETURNS boolean
    LANGUAGE sql
    AS $_$
        SELECT $1.gateway = 'Credits';
      $_$;
--
-- Name: validate_project_expires_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION validate_project_expires_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
    IF EXISTS(SELECT true FROM public.projects p JOIN public.contributions c ON c.project_id = p.id WHERE c.id = new.contribution_id AND p.is_expired) THEN
        RAISE EXCEPTION 'Project for contribution % in payment % is expired', new.contribution_id, new.id;
    END IF;
    RETURN new;
    END;
    $$;
--
-- Name: validate_reward_sold_out(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION validate_reward_sold_out() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
    IF EXISTS(SELECT true FROM public.rewards r JOIN public.contributions c ON c.reward_id = r.id WHERE c.id = new.contribution_id AND r.sold_out) THEN
        RAISE EXCEPTION 'Reward for contribution % in payment % is sold out', new.contribution_id, new.id;
    END IF;
    RETURN new;
    END;
    $$;
--
-- Name: waiting_funds_at(projects); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION waiting_funds_at(project projects) RETURNS timestamp without time zone
    LANGUAGE sql STABLE
    AS $$
        SELECT get_date_from_project_transitions(project.id, 'waiting_funds');
    $$;
--
-- Name: waiting_payment(payments); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION waiting_payment(payments) RETURNS boolean
    LANGUAGE sql STABLE
    AS $_$
            SELECT
                     $1.state = 'pending'
                     AND
                     (
                       SELECT count(1) AS total_of_days
                       FROM generate_series($1.created_at::date, current_date, '1 day') day
                       WHERE extract(dow from day) not in (0,1)
                     )  <= 4
           $_$;
--
-- Name: waiting_payment_count(rewards); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION waiting_payment_count(rewards) RETURNS bigint
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $_$
      SELECT count(*) 
      FROM payments p join contributions c on c.id = p.contribution_id 
      WHERE p.waiting_payment AND c.reward_id = $1.id
    $_$;
--
-- Name: was_confirmed(contributions); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION was_confirmed(contributions) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $_$
            SELECT EXISTS (
              SELECT true
              FROM
                payments p
              WHERE p.contribution_id = $1.id AND p.state = ANY(confirmed_states())
            );
          $_$;
--
-- Name: weekdays_from(integer, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION weekdays_from(weekdays integer, from_ts timestamp without time zone) RETURNS timestamp without time zone
    LANGUAGE sql STABLE
    AS $$
    SELECT max(day) FROM (
      SELECT day
      FROM generate_series(from_ts, from_ts + '1 year'::interval, '1 day') day
      WHERE extract(dow from day) not in (0,1)
      ORDER BY day
      LIMIT (weekdays + 1)
    ) a;
    $$;
--
-- Name: zone_expires_at(projects); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION zone_expires_at(projects) RETURNS timestamp without time zone
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $_$
        SELECT public.zone_timestamp($1.expires_at);
      $_$;
--
-- Name: zone_timestamp(timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION zone_timestamp(timestamp without time zone) RETURNS timestamp without time zone
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $_$
        SELECT $1::timestamptz AT TIME ZONE settings('timezone');
      $_$;
SET search_path = "time", pg_catalog;

--
-- Name: past_months(integer); Type: FUNCTION; Schema: time; Owner: -
--

CREATE FUNCTION past_months(integer) RETURNS SETOF daterange
    LANGUAGE sql
    AS $_$SELECT daterange(to_char(generate_series::date, 'yyyy-mm-01')::date, to_char((generate_series + '1 month'::interval), 'yyyy-mm-01')::date) as month from generate_series(current_timestamp - ($1 || ' months')::interval, current_timestamp, '1 month')$_$;
SET search_path = public, pg_catalog;

--
-- Name: median(numeric); Type: AGGREGATE; Schema: public; Owner: -
--

CREATE AGGREGATE median(numeric) (
    SFUNC = array_append,
    STYPE = numeric[],
    INITCOND = '{}',
    FINALFUNC = _final_median
);
SET search_path = "1", pg_catalog;

--
-- Name: categories; Type: TABLE; Schema: 1; Owner: -
--

CREATE TABLE categories (
    id integer,
    name text,
    online_projects bigint,
    followers bigint,
    following boolean
);

ALTER TABLE ONLY categories REPLICA IDENTITY NOTHING;
SET search_path = public, pg_catalog;

--
-- Name: category_followers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE category_followers (
    id integer NOT NULL,
    category_id integer NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone
);
SET search_path = "1", pg_catalog;

--
-- Name: category_followers; Type: VIEW; Schema: 1; Owner: -
--

CREATE VIEW category_followers AS
 SELECT c.category_id,
    c.user_id
   FROM public.category_followers c
  WHERE public.is_owner_or_admin(c.user_id);
--
-- Name: category_totals; Type: TABLE; Schema: 1; Owner: -
--

CREATE TABLE category_totals (
    category_id integer,
    name text,
    online_projects bigint,
    successful_projects bigint,
    failed_projects bigint,
    avg_goal numeric,
    avg_pledged numeric,
    total_successful_value numeric,
    total_value numeric,
    name_pt text,
    avg_value numeric,
    total_contributors bigint,
    followers bigint
);

ALTER TABLE ONLY category_totals REPLICA IDENTITY NOTHING;
--
-- Name: contribution_details; Type: VIEW; Schema: 1; Owner: -
--

CREATE VIEW contribution_details AS
 SELECT pa.id,
    c.id AS contribution_id,
    pa.id AS payment_id,
    c.user_id,
    c.project_id,
    c.reward_id,
    p.permalink,
    p.name AS project_name,
    public.thumbnail_image(p.*) AS project_img,
    p.online_date AS project_online_date,
    p.expires_at AS project_expires_at,
    (COALESCE(fp.state, (p.state)::text))::character varying(255) AS project_state,
    u.name AS user_name,
    public.thumbnail_image(u.*) AS user_profile_img,
    u.email,
    c.anonymous,
    c.payer_email,
    pa.key,
    pa.value,
    pa.installments,
    pa.installment_value,
    pa.state,
    public.is_second_slip(pa.*) AS is_second_slip,
    pa.gateway,
    pa.gateway_id,
    pa.gateway_fee,
    pa.gateway_data,
    pa.payment_method,
    pa.created_at,
    pa.created_at AS pending_at,
    pa.paid_at,
    pa.refused_at,
    pa.pending_refund_at,
    pa.refunded_at,
    pa.deleted_at,
    pa.chargeback_at,
    pa.full_text_index,
    public.waiting_payment(pa.*) AS waiting_payment
   FROM ((((public.projects p
     LEFT JOIN public.flexible_projects fp ON ((fp.project_id = p.id)))
     JOIN public.contributions c ON ((c.project_id = p.id)))
     JOIN public.payments pa ON ((c.id = pa.contribution_id)))
     JOIN public.users u ON ((c.user_id = u.id)));
--
-- Name: contribution_reports; Type: VIEW; Schema: 1; Owner: -
--

CREATE VIEW contribution_reports AS
 SELECT b.project_id,
    u.name,
    replace((b.value)::text, '.'::text, ','::text) AS value,
    replace((r.minimum_value)::text, '.'::text, ','::text) AS minimum_value,
    r.description,
    p.gateway,
    (p.gateway_data -> 'acquirer_name'::text) AS acquirer_name,
    (p.gateway_data -> 'tid'::text) AS acquirer_tid,
    p.payment_method,
    replace((p.gateway_fee)::text, '.'::text, ','::text) AS payment_service_fee,
    p.key,
    (b.created_at)::date AS created_at,
    (p.paid_at)::date AS confirmed_at,
    u.email,
    b.payer_email,
    b.payer_name,
    COALESCE(b.payer_document, u.cpf) AS cpf,
    u.address_street,
    u.address_complement,
    u.address_number,
    u.address_neighbourhood,
    u.address_city,
    u.address_state,
    u.address_zip_code,
    p.state
   FROM (((public.contributions b
     JOIN public.users u ON ((u.id = b.user_id)))
     JOIN public.payments p ON ((p.contribution_id = b.id)))
     LEFT JOIN public.rewards r ON ((r.id = b.reward_id)))
  WHERE (p.state = ANY (ARRAY[('paid'::character varying)::text, ('refunded'::character varying)::text, ('pending_refund'::character varying)::text]));
SET search_path = public, pg_catalog;

--
-- Name: settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE settings (
    id integer NOT NULL,
    name text NOT NULL,
    value text,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    CONSTRAINT configurations_name_not_blank CHECK ((length(btrim(name)) > 0))
);
SET search_path = "1", pg_catalog;

--
-- Name: contribution_reports_for_project_owners; Type: VIEW; Schema: 1; Owner: -
--

CREATE VIEW contribution_reports_for_project_owners AS
 SELECT b.project_id,
    COALESCE(r.id, 0) AS reward_id,
    p.user_id AS project_owner_id,
    r.description AS reward_description,
    (r.deliver_at)::date AS deliver_at,
    (pa.paid_at)::date AS confirmed_at,
    pa.value AS contribution_value,
    (pa.value * ( SELECT (settings.value)::numeric AS value
           FROM public.settings
          WHERE (settings.name = 'catarse_fee'::text))) AS service_fee,
    u.email AS user_email,
    COALESCE(b.payer_document, u.cpf) AS cpf,
    u.name AS user_name,
    b.payer_email,
    pa.gateway,
    b.anonymous,
    pa.state,
    public.waiting_payment(pa.*) AS waiting_payment,
    COALESCE(u.address_street, b.address_street) AS street,
    COALESCE(u.address_complement, b.address_complement) AS complement,
    COALESCE(u.address_number, b.address_number) AS address_number,
    COALESCE(u.address_neighbourhood, b.address_neighbourhood) AS neighbourhood,
    COALESCE(u.address_city, b.address_city) AS city,
    COALESCE(u.address_state, b.address_state) AS address_state,
    COALESCE(u.address_zip_code, b.address_zip_code) AS zip_code
   FROM ((((public.contributions b
     JOIN public.users u ON ((u.id = b.user_id)))
     JOIN public.projects p ON ((b.project_id = p.id)))
     JOIN public.payments pa ON ((pa.contribution_id = b.id)))
     LEFT JOIN public.rewards r ON ((r.id = b.reward_id)))
  WHERE (pa.state = ANY (ARRAY['paid'::text, 'pending'::text, 'pending_refund'::text, 'refunded'::text]));
--
-- Name: contributions; Type: VIEW; Schema: 1; Owner: -
--

CREATE VIEW contributions AS
 SELECT c.id,
    c.project_id,
    c.user_id,
        CASE
            WHEN c.anonymous THEN NULL::integer
            ELSE c.user_id
        END AS public_user_id,
    c.reward_id,
    c.created_at
   FROM public.contributions c;
--
-- Name: financial_reports; Type: VIEW; Schema: 1; Owner: -
--

CREATE VIEW financial_reports AS
 SELECT p.name,
    u.moip_login,
    p.goal,
    p.expires_at,
    p.state
   FROM (public.projects p
     JOIN public.users u ON ((u.id = p.user_id)));
SET search_path = public, pg_catalog;

--
-- Name: categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE categories (
    id integer NOT NULL,
    name_pt text NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    name_en character varying(255),
    name_fr character varying(255),
    CONSTRAINT categories_name_not_blank CHECK ((length(btrim(name_pt)) > 0))
);
--
-- Name: category_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE category_notifications (
    id integer NOT NULL,
    user_id integer NOT NULL,
    category_id integer NOT NULL,
    from_email text NOT NULL,
    from_name text NOT NULL,
    template_name text NOT NULL,
    locale text NOT NULL,
    sent_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    deliver_at timestamp without time zone DEFAULT now()
);
--
-- Name: contribution_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE contribution_notifications (
    id integer NOT NULL,
    user_id integer NOT NULL,
    contribution_id integer NOT NULL,
    from_email text NOT NULL,
    from_name text NOT NULL,
    template_name text NOT NULL,
    locale text NOT NULL,
    sent_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    deliver_at timestamp without time zone DEFAULT now()
);
--
-- Name: donation_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE donation_notifications (
    id integer NOT NULL,
    user_id integer NOT NULL,
    donation_id integer NOT NULL,
    from_email text NOT NULL,
    from_name text NOT NULL,
    template_name text NOT NULL,
    locale text NOT NULL,
    sent_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deliver_at timestamp without time zone DEFAULT now()
);
--
-- Name: donations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE donations (
    id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    amount integer,
    user_id integer
);
--
-- Name: project_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE project_notifications (
    id integer NOT NULL,
    user_id integer NOT NULL,
    project_id integer NOT NULL,
    from_email text NOT NULL,
    from_name text NOT NULL,
    template_name text NOT NULL,
    locale text NOT NULL,
    sent_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    deliver_at timestamp without time zone DEFAULT now()
);
--
-- Name: project_post_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE project_post_notifications (
    id integer NOT NULL,
    user_id integer NOT NULL,
    project_post_id integer NOT NULL,
    from_email text NOT NULL,
    from_name text NOT NULL,
    template_name text NOT NULL,
    locale text NOT NULL,
    sent_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    deliver_at timestamp without time zone DEFAULT now()
);
--
-- Name: project_posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE project_posts (
    id integer NOT NULL,
    user_id integer NOT NULL,
    project_id integer NOT NULL,
    title text NOT NULL,
    comment_html text NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    exclusive boolean DEFAULT false
);
--
-- Name: user_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE user_notifications (
    id integer NOT NULL,
    user_id integer NOT NULL,
    from_email text NOT NULL,
    from_name text NOT NULL,
    template_name text NOT NULL,
    locale text NOT NULL,
    sent_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    deliver_at timestamp without time zone DEFAULT now()
);
--
-- Name: user_transfer_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE user_transfer_notifications (
    id integer NOT NULL,
    user_id integer NOT NULL,
    user_transfer_id integer NOT NULL,
    from_email text NOT NULL,
    from_name text NOT NULL,
    template_name text NOT NULL,
    locale text NOT NULL,
    sent_at timestamp without time zone,
    deliver_at timestamp without time zone DEFAULT now(),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);
--
-- Name: user_transfers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE user_transfers (
    id integer NOT NULL,
    status text NOT NULL,
    amount integer NOT NULL,
    user_id integer NOT NULL,
    transfer_data json,
    gateway_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);
SET search_path = "1", pg_catalog;

--
-- Name: notifications; Type: VIEW; Schema: 1; Owner: -
--

CREATE VIEW notifications AS
 SELECT n.origin,
    n.user_id,
    n.template_name,
    n.created_at,
    n.sent_at,
    n.deliver_at
   FROM ( SELECT c.name_pt AS origin,
            cn.user_id,
            cn.template_name,
            cn.created_at,
            cn.sent_at,
            cn.deliver_at
           FROM (public.category_notifications cn
             JOIN public.categories c ON ((c.id = cn.category_id)))
        UNION ALL
         SELECT to_char(d.amount, 'L 999G990D00'::text) AS origin,
            dn.user_id,
            dn.template_name,
            dn.created_at,
            dn.sent_at,
            dn.deliver_at
           FROM (public.donation_notifications dn
             JOIN public.donations d ON ((d.id = dn.donation_id)))
        UNION ALL
         SELECT ''::text AS origin,
            user_notifications.user_id,
            user_notifications.template_name,
            user_notifications.created_at,
            user_notifications.sent_at,
            user_notifications.deliver_at
           FROM public.user_notifications
        UNION ALL
         SELECT p.name AS origin,
            pn.user_id,
            pn.template_name,
            pn.created_at,
            pn.sent_at,
            pn.deliver_at
           FROM (public.project_notifications pn
             JOIN public.projects p ON ((p.id = pn.project_id)))
        UNION ALL
         SELECT to_char(ut.amount, 'L 999G990D00'::text) AS origin,
            tn.user_id,
            tn.template_name,
            tn.created_at,
            tn.sent_at,
            tn.deliver_at
           FROM (public.user_transfer_notifications tn
             JOIN public.user_transfers ut ON ((ut.id = tn.user_transfer_id)))
        UNION ALL
         SELECT p.name AS origin,
            ppn.user_id,
            ppn.template_name,
            ppn.created_at,
            ppn.sent_at,
            ppn.deliver_at
           FROM ((public.project_post_notifications ppn
             JOIN public.project_posts pp ON ((pp.id = ppn.project_post_id)))
             JOIN public.projects p ON ((p.id = pp.project_id)))
        UNION ALL
         SELECT p.name AS origin,
            cn.user_id,
            cn.template_name,
            cn.created_at,
            cn.sent_at,
            cn.deliver_at
           FROM ((public.contribution_notifications cn
             JOIN public.contributions co ON ((co.id = cn.contribution_id)))
             JOIN public.projects p ON ((p.id = co.project_id)))) n;
--
-- Name: user_totals; Type: MATERIALIZED VIEW; Schema: 1; Owner: -
--

CREATE MATERIALIZED VIEW user_totals AS
 SELECT u.id,
    u.id AS user_id,
    COALESCE(ct.total_contributed_projects, (0)::bigint) AS total_contributed_projects,
    COALESCE(ct.sum, (0)::numeric) AS sum,
    COALESCE(ct.count, (0)::bigint) AS count,
    COALESCE(( SELECT count(*) AS count
           FROM public.projects p2
          WHERE (public.is_published(p2.*) AND (p2.user_id = u.id))), (0)::bigint) AS total_published_projects
   FROM (public.users u
     LEFT JOIN ( SELECT c.user_id,
            count(DISTINCT c.project_id) AS total_contributed_projects,
            sum(pa.value) AS sum,
            count(DISTINCT c.id) AS count
           FROM ((public.contributions c
             JOIN public.payments pa ON ((c.id = pa.contribution_id)))
             JOIN public.projects p ON ((c.project_id = p.id)))
          WHERE (pa.state = ANY (public.confirmed_states()))
          GROUP BY c.user_id) ct ON ((u.id = ct.user_id)))
  WITH NO DATA;
--
-- Name: project_contributions; Type: VIEW; Schema: 1; Owner: -
--

CREATE VIEW project_contributions AS
 SELECT c.anonymous,
    c.project_id,
    c.id,
    public.thumbnail_image(u.*) AS profile_img_thumbnail,
    u.id AS user_id,
    u.name AS user_name,
        CASE
            WHEN public.is_owner_or_admin(p.user_id) THEN c.value
            ELSE NULL::numeric
        END AS value,
    public.waiting_payment(pa.*) AS waiting_payment,
    public.is_owner_or_admin(p.user_id) AS is_owner_or_admin,
    ut.total_contributed_projects,
    public.zone_timestamp(c.created_at) AS created_at
   FROM ((((public.contributions c
     JOIN public.users u ON ((c.user_id = u.id)))
     JOIN public.projects p ON ((p.id = c.project_id)))
     JOIN public.payments pa ON ((pa.contribution_id = c.id)))
     LEFT JOIN user_totals ut ON ((ut.user_id = u.id)))
  WHERE ((public.was_confirmed(c.*) OR public.waiting_payment(pa.*)) AND ((NOT c.anonymous) OR public.is_owner_or_admin(p.user_id)));
--
-- Name: project_contributions_per_day; Type: VIEW; Schema: 1; Owner: -
--

CREATE VIEW project_contributions_per_day AS
 SELECT i.project_id,
    json_agg(json_build_object('paid_at', i.paid_at, 'total', i.total, 'total_amount', i.total_amount)) AS source
   FROM ( SELECT c.project_id,
            (p.paid_at)::date AS paid_at,
            count(c.*) AS total,
            sum(c.value) AS total_amount
           FROM (public.contributions c
             JOIN public.payments p ON ((p.contribution_id = c.id)))
          WHERE (public.was_confirmed(c.*) AND (p.paid_at IS NOT NULL))
          GROUP BY ((p.paid_at)::date), c.project_id
          ORDER BY ((p.paid_at)::date)) i
  GROUP BY i.project_id;
--
-- Name: project_contributions_per_location; Type: TABLE; Schema: 1; Owner: -
--

CREATE TABLE project_contributions_per_location (
    project_id integer,
    source json
);

ALTER TABLE ONLY project_contributions_per_location REPLICA IDENTITY NOTHING;
SET search_path = public, pg_catalog;

--
-- Name: origins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE origins (
    id integer NOT NULL,
    domain text NOT NULL,
    referral text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);
SET search_path = "1", pg_catalog;

--
-- Name: project_contributions_per_ref; Type: VIEW; Schema: 1; Owner: -
--

CREATE VIEW project_contributions_per_ref AS
 SELECT i.project_id,
    json_agg(json_build_object('referral_link', i.referral_link, 'total', i.total, 'total_amount', i.total_amount, 'total_on_percentage', ((i.total_amount / ( SELECT pt.pledged
           FROM project_totals pt
          WHERE (pt.project_id = i.project_id))) * (100)::numeric))) AS source
   FROM ( SELECT c.project_id,
            COALESCE(o.referral, o.domain) AS referral_link,
            count(c.*) AS total,
            sum(c.value) AS total_amount
           FROM (public.contributions c
             LEFT JOIN public.origins o ON ((o.id = c.origin_id)))
          WHERE public.was_confirmed(c.*)
          GROUP BY o.referral, o.domain, c.project_id) i
  GROUP BY i.project_id;
--
-- Name: project_details; Type: TABLE; Schema: 1; Owner: -
--

CREATE TABLE project_details (
    project_id integer,
    id integer,
    user_id integer,
    name text,
    headline text,
    budget text,
    goal numeric,
    about_html text,
    permalink text,
    video_embed_url character varying(255),
    video_url text,
    category_name text,
    category_id integer,
    original_image text,
    thumb_image text,
    small_image text,
    large_image text,
    video_cover_image text,
    progress numeric,
    pledged numeric,
    total_contributions bigint,
    total_contributors bigint,
    state text,
    mode text,
    state_order public.project_state_order,
    expires_at timestamp without time zone,
    zone_expires_at timestamp without time zone,
    online_date timestamp without time zone,
    zone_online_date timestamp without time zone,
    sent_to_analysis_at timestamp without time zone,
    is_published boolean,
    is_expired boolean,
    open_for_contributions boolean,
    online_days integer,
    remaining_time json,
    elapsed_time json,
    posts_count bigint,
    address json,
    "user" json,
    reminder_count bigint,
    is_owner_or_admin boolean,
    user_signed_in boolean,
    in_reminder boolean,
    total_posts bigint,
    is_admin_role boolean
);

ALTER TABLE ONLY project_details REPLICA IDENTITY NOTHING;
--
-- Name: project_financials; Type: VIEW; Schema: 1; Owner: -
--

CREATE VIEW project_financials AS
 WITH catarse_fee_percentage AS (
         SELECT (c.value)::numeric AS total,
            ((1)::numeric - (c.value)::numeric) AS complement
           FROM public.settings c
          WHERE (c.name = 'catarse_fee'::text)
        ), catarse_base_url AS (
         SELECT c.value
           FROM public.settings c
          WHERE (c.name = 'base_url'::text)
        )
 SELECT p.id AS project_id,
    p.name,
    u.moip_login AS moip,
    p.goal,
    pt.pledged AS reached,
    pt.total_payment_service_fee AS payment_tax,
    (cp.total * pt.pledged) AS catarse_fee,
    (pt.pledged * cp.complement) AS repass_value,
    to_char(timezone(COALESCE(( SELECT settings.value
           FROM public.settings
          WHERE (settings.name = 'timezone'::text)), 'America/Sao_Paulo'::text), p.expires_at), 'dd/mm/yyyy'::text) AS expires_at,
    ((catarse_base_url.value || '/admin/reports/contribution_reports.csv?project_id='::text) || p.id) AS contribution_report,
    p.state
   FROM ((((public.projects p
     JOIN public.users u ON ((u.id = p.user_id)))
     LEFT JOIN project_totals pt ON ((pt.project_id = p.id)))
     CROSS JOIN catarse_fee_percentage cp)
     CROSS JOIN catarse_base_url);
--
-- Name: project_posts_details; Type: VIEW; Schema: 1; Owner: -
--

CREATE VIEW project_posts_details AS
 SELECT pp.id,
    pp.project_id,
    public.is_owner_or_admin(p.user_id) AS is_owner_or_admin,
    pp.exclusive,
    pp.title,
        CASE
            WHEN (NOT pp.exclusive) THEN pp.comment_html
            WHEN (pp.exclusive AND (public.is_owner_or_admin(p.user_id) OR public.current_user_has_contributed_to_project(p.id))) THEN pp.comment_html
            ELSE NULL::text
        END AS comment_html,
    pp.created_at
   FROM (public.project_posts pp
     JOIN public.projects p ON ((p.id = pp.project_id)));
--
-- Name: project_reminders; Type: VIEW; Schema: 1; Owner: -
--

CREATE VIEW project_reminders AS
 SELECT pr.project_id,
    pr.user_id
   FROM public.project_reminders pr
  WHERE public.is_owner_or_admin(pr.user_id);
--
-- Name: project_transfers; Type: VIEW; Schema: 1; Owner: -
--

CREATE VIEW project_transfers AS
 SELECT p.id AS project_id,
    p.service_fee,
    p.goal,
    pt.pledged,
    public.zone_timestamp(p.expires_at) AS expires_at,
    public.zone_timestamp(COALESCE(public.successful_at(p.*), public.failed_at(p.*))) AS finished_at,
    pt.total_payment_service_fee AS gateway_fee,
    public.total_catarse_fee(p.*) AS catarse_fee,
    public.total_catarse_fee_without_gateway_fee(p.*) AS catarse_fee_without_gateway,
    (pt.pledged - public.total_catarse_fee(p.*)) AS amount_without_catarse_fee,
    public.irrf_tax(p.*) AS irrf_tax,
    public.pcc_tax(p.*) AS pcc_tax,
    (((pt.pledged - public.total_catarse_fee(p.*)) + public.irrf_tax(p.*)) + public.pcc_tax(p.*)) AS total_amount
   FROM (public.projects p
     LEFT JOIN project_totals pt ON ((pt.project_id = p.id)));
SET search_path = public, pg_catalog;

--
-- Name: flexible_project_transitions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE flexible_project_transitions (
    id integer NOT NULL,
    to_state character varying(255) NOT NULL,
    metadata text DEFAULT '{}'::text,
    sort_key integer NOT NULL,
    flexible_project_id integer NOT NULL,
    most_recent boolean NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);
--
-- Name: project_transitions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE project_transitions (
    id integer NOT NULL,
    to_state character varying(255) NOT NULL,
    metadata text DEFAULT '{}'::text,
    sort_key integer NOT NULL,
    project_id integer NOT NULL,
    most_recent boolean NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);
SET search_path = "1", pg_catalog;

--
-- Name: project_transitions; Type: VIEW; Schema: 1; Owner: -
--

CREATE VIEW project_transitions AS
 SELECT project_transitions.project_id,
    project_transitions.to_state AS state,
    project_transitions.metadata,
    project_transitions.most_recent,
    project_transitions.created_at
   FROM public.project_transitions
UNION ALL
 SELECT fp.project_id,
    fpt.to_state AS state,
    fpt.metadata,
    fpt.most_recent,
    fpt.created_at
   FROM (public.flexible_project_transitions fpt
     JOIN public.flexible_projects fp ON ((fpt.flexible_project_id = fp.id)));
--
-- Name: recommendations; Type: VIEW; Schema: 1; Owner: -
--

CREATE VIEW recommendations AS
 SELECT recommendations.user_id,
    recommendations.project_id,
    (sum(recommendations.count))::bigint AS count
   FROM ( SELECT b.user_id,
            recommendations_1.id AS project_id,
            count(DISTINCT recommenders.user_id) AS count
           FROM (((public.contributions b
             JOIN public.contributions backers_same_projects USING (project_id))
             JOIN public.contributions recommenders ON ((recommenders.user_id = backers_same_projects.user_id)))
             JOIN public.projects recommendations_1 ON ((recommendations_1.id = recommenders.project_id)))
          WHERE (public.was_confirmed(b.*) AND public.was_confirmed(backers_same_projects.*) AND public.was_confirmed(recommenders.*) AND (b.updated_at > (now() - '6 mons'::interval)) AND (recommenders.updated_at > (now() - '2 mons'::interval)) AND ((recommendations_1.state)::text = 'online'::text) AND (b.user_id <> backers_same_projects.user_id) AND (recommendations_1.id <> b.project_id) AND (NOT (EXISTS ( SELECT true AS bool
                   FROM public.contributions b2
                  WHERE (public.was_confirmed(b2.*) AND (b2.user_id = b.user_id) AND (b2.project_id = recommendations_1.id))))))
          GROUP BY b.user_id, recommendations_1.id
        UNION
         SELECT b.user_id,
            recommendations_1.id AS project_id,
            0 AS count
           FROM ((public.contributions b
             JOIN public.projects p ON ((b.project_id = p.id)))
             JOIN public.projects recommendations_1 ON ((recommendations_1.category_id = p.category_id)))
          WHERE (public.was_confirmed(b.*) AND ((recommendations_1.state)::text = 'online'::text))) recommendations
  WHERE (NOT (EXISTS ( SELECT true AS bool
           FROM public.contributions b2
          WHERE (public.was_confirmed(b2.*) AND (b2.user_id = recommendations.user_id) AND (b2.project_id = recommendations.project_id)))))
  GROUP BY recommendations.user_id, recommendations.project_id
  ORDER BY ((sum(recommendations.count))::bigint) DESC;
--
-- Name: referral_totals; Type: VIEW; Schema: 1; Owner: -
--

CREATE VIEW referral_totals AS
 SELECT to_char(c.created_at, 'YYYY-MM'::text) AS month,
    COALESCE(NULLIF(o.referral, ''::text), o.domain) AS referral_link,
    p.permalink,
    count(*) AS contributions,
    count(*) FILTER (WHERE public.was_confirmed(c.*)) AS confirmed_contributions,
    COALESCE(sum(c.value) FILTER (WHERE public.was_confirmed(c.*)), (0)::numeric) AS confirmed_value
   FROM ((public.contributions c
     JOIN public.projects p ON ((p.id = c.project_id)))
     LEFT JOIN public.origins o ON ((o.id = c.origin_id)))
  GROUP BY (to_char(c.created_at, 'YYYY-MM'::text)), COALESCE(NULLIF(o.referral, ''::text), o.domain), p.permalink;
--
-- Name: reward_details; Type: VIEW; Schema: 1; Owner: -
--

CREATE VIEW reward_details AS
 SELECT r.id,
    r.project_id,
    r.description,
    r.minimum_value,
    r.maximum_contributions,
    r.deliver_at,
    r.updated_at,
    public.paid_count(r.*) AS paid_count,
    public.waiting_payment_count(r.*) AS waiting_payment_count
   FROM public.rewards r
  ORDER BY r.row_order;
--
-- Name: statistics; Type: MATERIALIZED VIEW; Schema: 1; Owner: -
--

CREATE MATERIALIZED VIEW statistics AS
 SELECT ( SELECT count(*) AS count
           FROM public.users) AS total_users,
    contributions_totals.total_contributions,
    contributions_totals.total_contributors,
    contributions_totals.total_contributed,
    projects_totals.total_projects,
    projects_totals.total_projects_success,
    projects_totals.total_projects_online
   FROM ( SELECT count(DISTINCT c.id) AS total_contributions,
            count(DISTINCT c.user_id) AS total_contributors,
            sum(p.value) AS total_contributed
           FROM (public.contributions c
             JOIN public.payments p ON ((p.contribution_id = c.id)))
          WHERE (p.state = ANY (public.confirmed_states()))) contributions_totals,
    ( SELECT count(*) AS total_projects,
            count(
                CASE
                    WHEN ((projects.state)::text = 'successful'::text) THEN 1
                    ELSE NULL::integer
                END) AS total_projects_success,
            count(
                CASE
                    WHEN ((projects.state)::text = 'online'::text) THEN 1
                    ELSE NULL::integer
                END) AS total_projects_online
           FROM public.projects
          WHERE ((projects.state)::text <> ALL (ARRAY[('draft'::character varying)::text, ('rejected'::character varying)::text]))) projects_totals
  WITH NO DATA;
--
-- Name: team_members; Type: VIEW; Schema: 1; Owner: -
--

CREATE VIEW team_members AS
 SELECT u.id,
    u.name,
    public.thumbnail_image(u.*) AS img,
    COALESCE(ut.total_contributed_projects, (0)::bigint) AS total_contributed_projects,
    COALESCE(ut.sum, (0)::numeric) AS total_amount_contributed
   FROM (public.users u
     LEFT JOIN user_totals ut ON ((ut.user_id = u.id)))
  WHERE u.admin
  ORDER BY u.name;
SET search_path = public, pg_catalog;

--
-- Name: countries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE countries (
    id integer NOT NULL,
    name text NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone
);
SET search_path = "1", pg_catalog;

--
-- Name: team_totals; Type: VIEW; Schema: 1; Owner: -
--

CREATE VIEW team_totals AS
 SELECT count(DISTINCT u.id) AS member_count,
    array_to_json(array_agg(DISTINCT country.name)) AS countries,
    count(DISTINCT c.project_id) FILTER (WHERE public.was_confirmed(c.*)) AS total_contributed_projects,
    count(DISTINCT lower(public.unaccent(u.address_city))) AS total_cities,
    sum(c.value) FILTER (WHERE public.was_confirmed(c.*)) AS total_amount
   FROM ((public.users u
     LEFT JOIN public.contributions c ON ((c.user_id = u.id)))
     LEFT JOIN public.countries country ON ((country.id = u.country_id)))
  WHERE u.admin;
--
-- Name: user_credits; Type: VIEW; Schema: 1; Owner: -
--

CREATE VIEW user_credits AS
 SELECT u.id,
    u.id AS user_id,
        CASE
            WHEN u.zero_credits THEN (0)::numeric
            ELSE COALESCE(ct.credits, (0)::numeric)
        END AS credits
   FROM (public.users u
     LEFT JOIN ( SELECT c.user_id,
            ((sum(
                CASE
                    WHEN (lower(pa.gateway) = 'pagarme'::text) THEN (0)::numeric
                    WHEN (((p.state)::text <> 'failed'::text) AND (NOT public.uses_credits(pa.*))) THEN (0)::numeric
                    WHEN (((p.state)::text = 'failed'::text) AND public.uses_credits(pa.*)) THEN (0)::numeric
                    WHEN (((p.state)::text = 'failed'::text) AND (((pa.state = ANY (ARRAY[('pending_refund'::character varying)::text, ('refunded'::character varying)::text])) AND (NOT public.uses_credits(pa.*))) OR (public.uses_credits(pa.*) AND (NOT (pa.state = ANY (ARRAY[('pending_refund'::character varying)::text, ('refunded'::character varying)::text])))))) THEN (0)::numeric
                    WHEN (((p.state)::text = 'failed'::text) AND (NOT public.uses_credits(pa.*)) AND (pa.state = 'paid'::text)) THEN pa.value
                    ELSE (pa.value * ('-1'::integer)::numeric)
                END) - COALESCE((( SELECT (sum(ut.amount) / 100)
                   FROM public.user_transfers ut
                  WHERE ((ut.status = 'transferred'::text) AND (ut.user_id = c.user_id))))::numeric, (0)::numeric)) - COALESCE((( SELECT sum(d.amount) AS sum
                   FROM public.donations d
                  WHERE ((d.user_id = c.user_id) AND (NOT (EXISTS ( SELECT 1
                           FROM public.contributions c_1
                          WHERE (c_1.donation_id = d.id)))))))::numeric, (0)::numeric)) AS credits
           FROM ((public.contributions c
             JOIN public.payments pa ON ((c.id = pa.contribution_id)))
             JOIN public.projects p ON ((c.project_id = p.id)))
          WHERE (pa.state = ANY (public.confirmed_states()))
          GROUP BY c.user_id) ct ON ((u.id = ct.user_id)));
SET search_path = public, pg_catalog;

--
-- Name: user_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE user_links (
    id integer NOT NULL,
    link text NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone
);
SET search_path = "1", pg_catalog;

--
-- Name: user_details; Type: VIEW; Schema: 1; Owner: -
--

CREATE VIEW user_details AS
 SELECT u.id,
    u.name,
    u.address_city,
    u.deactivated_at,
    public.thumbnail_image(u.*) AS profile_img_thumbnail,
    u.facebook_link,
    u.twitter AS twitter_username,
        CASE
            WHEN (public.is_owner_or_admin(u.id) OR public.has_published_projects(u.*)) THEN u.email
            ELSE NULL::text
        END AS email,
    COALESCE(ut.total_contributed_projects, (0)::bigint) AS total_contributed_projects,
    COALESCE(ut.total_published_projects, (0)::bigint) AS total_published_projects,
    ( SELECT json_agg(DISTINCT ul.link) AS json_agg
           FROM public.user_links ul
          WHERE (ul.user_id = u.id)) AS links
   FROM (public.users u
     LEFT JOIN user_totals ut ON ((ut.user_id = u.id)));
--
-- Name: users; Type: VIEW; Schema: 1; Owner: -
--

CREATE VIEW users AS
 SELECT u.id,
    u.name,
    public.thumbnail_image(u.*) AS profile_img_thumbnail,
    u.facebook_link,
    u.twitter AS twitter_username,
        CASE
            WHEN (public.is_owner_or_admin(u.id) OR public.has_published_projects(u.*)) THEN u.email
            ELSE NULL::text
        END AS email,
    u.deactivated_at,
    u.full_text_index
   FROM public.users u;
--
-- Name: year_totals; Type: MATERIALIZED VIEW; Schema: 1; Owner: -
--

CREATE MATERIALIZED VIEW year_totals AS
 WITH year_totals AS (
         SELECT to_char(p.paid_at, 'yyyy'::text) AS ano,
            count(DISTINCT
                CASE
                    WHEN ((pr.state)::text = 'successful'::text) THEN c.user_id
                    ELSE NULL::integer
                END) AS "Usuários em projetos bem sucedidos",
            count(DISTINCT c.user_id) AS "Apoiadores distintos no ano",
            sum(c.value) AS "Total de apoios",
            sum(
                CASE
                    WHEN ((pr.state)::text = 'successful'::text) THEN c.value
                    ELSE NULL::numeric
                END) AS "Total em projetos bem sucedidos",
            round((sum(c.value) / (count(DISTINCT c.user_id))::numeric), 2) AS "Apoio médio por usuário"
           FROM ((public.projects pr
             JOIN public.contributions c ON ((c.project_id = pr.id)))
             JOIN public.payments p ON ((p.contribution_id = c.id)))
          WHERE (p.state = ANY (public.confirmed_states()))
          GROUP BY (to_char(p.paid_at, 'yyyy'::text))
        ), new_contributors AS (
         SELECT a.ano,
            count(*) AS count
           FROM ( SELECT min(to_char(p.paid_at, 'yyyy'::text)) AS ano,
                    c.user_id
                   FROM (public.contributions c
                     JOIN public.payments p ON ((p.contribution_id = c.id)))
                  WHERE ((p.state = ANY (public.confirmed_states())) AND (p.paid_at IS NOT NULL))
                  GROUP BY c.user_id) a
          GROUP BY a.ano
        )
 SELECT yt.ano,
    yt."Usuários em projetos bem sucedidos",
    yt."Apoiadores distintos no ano",
    nc.count AS "Usuários novos por ano",
    yt."Total de apoios",
    yt."Total em projetos bem sucedidos",
    yt."Apoio médio por usuário"
   FROM (year_totals yt
     JOIN new_contributors nc USING (ano))
  WITH NO DATA;
SET search_path = api_updates, pg_catalog;

--
-- Name: contributions; Type: TABLE; Schema: api_updates; Owner: -
--

CREATE TABLE contributions (
    transaction_id bigint NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    contribution_id integer,
    user_id integer,
    reward_id integer
);
SET search_path = financial, pg_catalog;

--
-- Name: payment_due_dates; Type: VIEW; Schema: financial; Owner: -
--

CREATE VIEW payment_due_dates AS
 SELECT p.id,
    p.contribution_id,
    p.payment_method,
    p.state,
    p.paid_at,
    gs.gs AS installment,
    p.installment_value,
    (p.gateway_fee / (p.installments)::numeric) AS installment_fee,
        CASE p.payment_method
            WHEN 'CartaoDeCredito'::text THEN (p.paid_at + (((gs.gs)::text || ' months'::text))::interval)
            ELSE p.paid_at
        END AS due_date
   FROM (generate_series(1, 24) gs(gs)
     JOIN public.payments p ON ((p.installments >= gs.gs)))
  WHERE ((lower(p.gateway) = 'pagarme'::text) AND (p.state = ANY (ARRAY['paid'::text, 'pending_refund'::text])));
--
-- Name: project_payments_due; Type: VIEW; Schema: financial; Owner: -
--

CREATE VIEW project_payments_due AS
 SELECT p.permalink,
    p.state AS project_state,
    dd.payment_method,
    dd.state,
    dd.paid_at,
    dd.installment,
        CASE
            WHEN ((p.state)::text = 'successful'::text) THEN (dd.installment_value * ((1)::numeric - ( SELECT (settings.value)::numeric AS value
               FROM public.settings
              WHERE (settings.name = 'catarse_fee'::text))))
            ELSE (dd.installment_value - dd.installment_fee)
        END AS value,
    dd.installment_fee
   FROM ((public.projects p
     JOIN public.contributions c ON ((c.project_id = p.id)))
     JOIN payment_due_dates dd ON ((dd.contribution_id = c.id)))
  WHERE ((p.state)::text = ANY (ARRAY[('online'::character varying)::text, ('failed'::character varying)::text, ('successful'::character varying)::text, ('waiting_funds'::character varying)::text]))
  ORDER BY p.id DESC;
--
-- Name: payments_due_summary; Type: VIEW; Schema: financial; Owner: -
--

CREATE VIEW payments_due_summary AS
 SELECT p.project_state,
    p.state,
    p.payment_method,
    round(sum(p.value), 2) AS value
   FROM project_payments_due p
  GROUP BY p.project_state, p.state, p.payment_method
  ORDER BY p.project_state, p.state, p.payment_method;
SET search_path = public, pg_catalog;

--
-- Name: authorizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE authorizations (
    id integer NOT NULL,
    oauth_provider_id integer NOT NULL,
    user_id integer NOT NULL,
    uid text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone NOT NULL
);
--
-- Name: authorizations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE authorizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: authorizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE authorizations_id_seq OWNED BY authorizations.id;
--
-- Name: bank_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE bank_accounts (
    id integer NOT NULL,
    user_id integer,
    account text NOT NULL,
    agency text NOT NULL,
    owner_name text NOT NULL,
    owner_document text NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    account_digit text NOT NULL,
    agency_digit text,
    bank_id integer NOT NULL
);
--
-- Name: bank_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bank_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: bank_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bank_accounts_id_seq OWNED BY bank_accounts.id;
--
-- Name: banks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE banks (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone
);
--
-- Name: banks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE banks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: banks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE banks_id_seq OWNED BY banks.id;
--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE categories_id_seq OWNED BY categories.id;
--
-- Name: category_followers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE category_followers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: category_followers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE category_followers_id_seq OWNED BY category_followers.id;
--
-- Name: category_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE category_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: category_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE category_notifications_id_seq OWNED BY category_notifications.id;
--
-- Name: channel_partners; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE channel_partners (
    id integer NOT NULL,
    url text NOT NULL,
    image text NOT NULL,
    channel_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone
);
--
-- Name: channel_partners_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE channel_partners_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: channel_partners_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE channel_partners_id_seq OWNED BY channel_partners.id;
--
-- Name: channel_post_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE channel_post_notifications (
    id integer NOT NULL,
    user_id integer NOT NULL,
    channel_post_id integer NOT NULL,
    from_email text NOT NULL,
    from_name text NOT NULL,
    template_name text NOT NULL,
    locale text NOT NULL,
    sent_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    deliver_at timestamp without time zone DEFAULT now()
);
--
-- Name: channel_post_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE channel_post_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: channel_post_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE channel_post_notifications_id_seq OWNED BY channel_post_notifications.id;
--
-- Name: channel_posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE channel_posts (
    id integer NOT NULL,
    title text NOT NULL,
    body text NOT NULL,
    body_html text NOT NULL,
    channel_id integer NOT NULL,
    user_id integer NOT NULL,
    visible boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    published_at timestamp without time zone
);
--
-- Name: channel_posts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE channel_posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: channel_posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE channel_posts_id_seq OWNED BY channel_posts.id;
--
-- Name: channels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE channels (
    id integer NOT NULL,
    name text NOT NULL,
    description text NOT NULL,
    permalink text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    twitter text,
    facebook text,
    email text,
    image text,
    website text,
    video_url text,
    how_it_works text,
    how_it_works_html text,
    terms_url character varying(255),
    video_embed_url text,
    ga_code text
);
--
-- Name: channels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE channels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: channels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE channels_id_seq OWNED BY channels.id;
--
-- Name: channels_projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE channels_projects (
    id integer NOT NULL,
    channel_id integer,
    project_id integer
);
--
-- Name: channels_projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE channels_projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: channels_projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE channels_projects_id_seq OWNED BY channels_projects.id;
--
-- Name: channels_subscribers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE channels_subscribers (
    id integer NOT NULL,
    user_id integer NOT NULL,
    channel_id integer NOT NULL
);
--
-- Name: channels_subscribers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE channels_subscribers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: channels_subscribers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE channels_subscribers_id_seq OWNED BY channels_subscribers.id;
--
-- Name: cities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: cities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cities_id_seq OWNED BY cities.id;
--
-- Name: configurations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE configurations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: configurations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE configurations_id_seq OWNED BY settings.id;
--
-- Name: contribution_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contribution_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: contribution_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contribution_notifications_id_seq OWNED BY contribution_notifications.id;
--
-- Name: contributions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contributions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: contributions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contributions_id_seq OWNED BY contributions.id;
--
-- Name: countries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE countries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: countries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE countries_id_seq OWNED BY countries.id;
--
-- Name: credit_cards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE credit_cards (
    id integer NOT NULL,
    user_id integer,
    last_digits text NOT NULL,
    card_brand text NOT NULL,
    subscription_id text,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    card_key text
);
--
-- Name: credit_cards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE credit_cards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: credit_cards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE credit_cards_id_seq OWNED BY credit_cards.id;
--
-- Name: dbhero_dataclips; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE dbhero_dataclips (
    id integer NOT NULL,
    description text NOT NULL,
    raw_query text NOT NULL,
    token text NOT NULL,
    "user" text,
    private boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone NOT NULL
);
--
-- Name: dbhero_dataclips_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE dbhero_dataclips_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: dbhero_dataclips_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE dbhero_dataclips_id_seq OWNED BY dbhero_dataclips.id;
--
-- Name: deps_saved_ddl; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE deps_saved_ddl (
    deps_id integer NOT NULL,
    deps_view_schema text,
    deps_view_name text,
    deps_ddl_to_run text
);
--
-- Name: deps_saved_ddl_deps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE deps_saved_ddl_deps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: deps_saved_ddl_deps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE deps_saved_ddl_deps_id_seq OWNED BY deps_saved_ddl.deps_id;
--
-- Name: donation_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE donation_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: donation_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE donation_notifications_id_seq OWNED BY donation_notifications.id;
--
-- Name: donations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE donations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: donations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE donations_id_seq OWNED BY donations.id;
--
-- Name: flexible_project_states; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE flexible_project_states (
    state text NOT NULL,
    state_order project_state_order NOT NULL
);
--
-- Name: flexible_project_transitions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE flexible_project_transitions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: flexible_project_transitions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE flexible_project_transitions_id_seq OWNED BY flexible_project_transitions.id;
--
-- Name: flexible_projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE flexible_projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: flexible_projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE flexible_projects_id_seq OWNED BY flexible_projects.id;
--
-- Name: near_mes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE near_mes (
    id integer NOT NULL
);
--
-- Name: near_mes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE near_mes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: near_mes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE near_mes_id_seq OWNED BY near_mes.id;
--
-- Name: oauth_providers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE oauth_providers (
    id integer NOT NULL,
    name text NOT NULL,
    key text NOT NULL,
    secret text NOT NULL,
    scope text,
    "order" integer,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    strategy text,
    path text,
    CONSTRAINT oauth_providers_key_not_blank CHECK ((length(btrim(key)) > 0)),
    CONSTRAINT oauth_providers_name_not_blank CHECK ((length(btrim(name)) > 0)),
    CONSTRAINT oauth_providers_secret_not_blank CHECK ((length(btrim(secret)) > 0))
);
--
-- Name: oauth_providers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE oauth_providers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: oauth_providers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE oauth_providers_id_seq OWNED BY oauth_providers.id;
--
-- Name: origins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE origins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: origins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE origins_id_seq OWNED BY origins.id;
--
-- Name: payment_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE payment_logs (
    id integer NOT NULL,
    gateway_id character varying(255) NOT NULL,
    data json NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);
--
-- Name: payment_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE payment_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: payment_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE payment_logs_id_seq OWNED BY payment_logs.id;
--
-- Name: payment_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE payment_notifications (
    id integer NOT NULL,
    contribution_id integer NOT NULL,
    extra_data text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    payment_id integer
);
--
-- Name: payment_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE payment_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: payment_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE payment_notifications_id_seq OWNED BY payment_notifications.id;
--
-- Name: payment_transfers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE payment_transfers (
    id integer NOT NULL,
    user_id integer NOT NULL,
    payment_id integer NOT NULL,
    transfer_id text NOT NULL,
    transfer_data json,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);
--
-- Name: payment_transfers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE payment_transfers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: payment_transfers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE payment_transfers_id_seq OWNED BY payment_transfers.id;
--
-- Name: payments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE payments_id_seq OWNED BY payments.id;
--
-- Name: project_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE project_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: project_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE project_accounts_id_seq OWNED BY project_accounts.id;
--
-- Name: project_budgets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE project_budgets (
    id integer NOT NULL,
    project_id integer NOT NULL,
    name text NOT NULL,
    value numeric(8,2) NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone
);
--
-- Name: project_budgets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE project_budgets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: project_budgets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE project_budgets_id_seq OWNED BY project_budgets.id;
--
-- Name: project_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE project_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: project_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE project_notifications_id_seq OWNED BY project_notifications.id;
--
-- Name: project_post_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE project_post_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: project_post_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE project_post_notifications_id_seq OWNED BY project_post_notifications.id;
--
-- Name: project_reminders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE project_reminders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: project_reminders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE project_reminders_id_seq OWNED BY project_reminders.id;
--
-- Name: project_states; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE project_states (
    state text NOT NULL,
    state_order project_state_order NOT NULL
);
--
-- Name: project_transitions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE project_transitions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: project_transitions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE project_transitions_id_seq OWNED BY project_transitions.id;
--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE projects_id_seq OWNED BY projects.id;
--
-- Name: projects_in_analysis_by_periods; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW projects_in_analysis_by_periods AS
 WITH weeks AS (
         SELECT to_char(current_year_1.current_year, 'yyyy-mm W'::text) AS current_year,
            to_char(last_year_1.last_year, 'yyyy-mm W'::text) AS last_year,
            current_year_1.current_year AS label
           FROM (generate_series((now() - '49 days'::interval), now(), '7 days'::interval) current_year_1(current_year)
             JOIN generate_series((now() - '1 year 49 days'::interval), (now() - '1 year'::interval), '7 days'::interval) last_year_1(last_year) ON ((to_char(last_year_1.last_year, 'mm W'::text) = to_char(current_year_1.current_year, 'mm W'::text))))
        ), current_year AS (
         SELECT w.label,
            count(*) AS current_year
           FROM (projects p
             JOIN weeks w ON ((w.current_year = to_char(p.sent_to_analysis_at, 'yyyy-mm W'::text))))
          GROUP BY w.label
        ), last_year AS (
         SELECT w.label,
            count(*) AS last_year
           FROM (projects p
             JOIN weeks w ON ((w.last_year = to_char(p.sent_to_analysis_at, 'yyyy-mm W'::text))))
          GROUP BY w.label
        )
 SELECT current_year.label,
    current_year.current_year,
    last_year.last_year
   FROM (current_year
     JOIN last_year USING (label));
--
-- Name: redactor_assets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE redactor_assets (
    id integer NOT NULL,
    user_id integer,
    data_file_name character varying(255) NOT NULL,
    data_content_type character varying(255),
    data_file_size integer,
    assetable_id integer,
    assetable_type character varying(30),
    type character varying(30),
    width integer,
    height integer,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone
);
--
-- Name: redactor_assets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE redactor_assets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: redactor_assets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE redactor_assets_id_seq OWNED BY redactor_assets.id;
--
-- Name: rewards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE rewards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: rewards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE rewards_id_seq OWNED BY rewards.id;
--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);
--
-- Name: sendgrid_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sendgrid_events (
    id integer NOT NULL,
    notification_id integer NOT NULL,
    notification_user integer NOT NULL,
    notification_type text NOT NULL,
    template_name text NOT NULL,
    event text NOT NULL,
    email text NOT NULL,
    useragent text,
    sendgrid_data json NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);
--
-- Name: sendgrid_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sendgrid_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: sendgrid_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sendgrid_events_id_seq OWNED BY sendgrid_events.id;
--
-- Name: states_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE states_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: states_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE states_id_seq OWNED BY states.id;
--
-- Name: subscriber_reports; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW subscriber_reports AS
 SELECT u.id,
    cs.channel_id,
    u.name,
    u.email
   FROM (users u
     JOIN channels_subscribers cs ON ((cs.user_id = u.id)));
--
-- Name: taggings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE taggings (
    id integer NOT NULL,
    tag_id integer NOT NULL,
    project_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);
--
-- Name: taggings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE taggings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: taggings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE taggings_id_seq OWNED BY taggings.id;
--
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tags (
    id integer NOT NULL,
    name text NOT NULL,
    slug text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);
--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tags_id_seq OWNED BY tags.id;
--
-- Name: unsubscribes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE unsubscribes (
    id integer NOT NULL,
    user_id integer NOT NULL,
    project_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone NOT NULL
);
--
-- Name: unsubscribes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE unsubscribes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: unsubscribes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE unsubscribes_id_seq OWNED BY unsubscribes.id;
--
-- Name: updates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE updates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: updates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE updates_id_seq OWNED BY project_posts.id;
--
-- Name: user_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: user_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_links_id_seq OWNED BY user_links.id;
--
-- Name: user_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: user_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_notifications_id_seq OWNED BY user_notifications.id;
--
-- Name: user_transfer_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_transfer_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: user_transfer_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_transfer_notifications_id_seq OWNED BY user_transfer_notifications.id;
--
-- Name: user_transfers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_transfers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: user_transfers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_transfers_id_seq OWNED BY user_transfers.id;
--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;
SET search_path = temp, pg_catalog;

--
-- Name: apoios_moip; Type: TABLE; Schema: temp; Owner: -
--

CREATE TABLE apoios_moip (
    key text
);
--
-- Name: apoios_moip7_8; Type: TABLE; Schema: temp; Owner: -
--

CREATE TABLE apoios_moip7_8 (
    key text
);
--
-- Name: apoios_moip_0106_2210; Type: TABLE; Schema: temp; Owner: -
--

CREATE TABLE apoios_moip_0106_2210 (
    key text
);
--
-- Name: apoios_paypal; Type: TABLE; Schema: temp; Owner: -
--

CREATE TABLE apoios_paypal (
    id text
);
--
-- Name: apoios_paypal_0106_2210; Type: TABLE; Schema: temp; Owner: -
--

CREATE TABLE apoios_paypal_0106_2210 (
    payment_id text
);
--
-- Name: budget_before_redactor; Type: TABLE; Schema: temp; Owner: -
--

CREATE TABLE budget_before_redactor (
    id integer,
    budget text
);
--
-- Name: contributions_to_confirm; Type: TABLE; Schema: temp; Owner: -
--

CREATE TABLE contributions_to_confirm (
    user_id integer,
    id integer,
    value numeric,
    "data catarse" timestamp without time zone,
    "data pagarme" text,
    transaction_payment_id text,
    state character varying(255),
    permalink text
);
--
-- Name: contributions_to_fix; Type: TABLE; Schema: temp; Owner: -
--

CREATE TABLE contributions_to_fix (
    contribution_id integer,
    payment_id text,
    pagarme_state text,
    key text,
    value numeric,
    payer_email text
);
--
-- Name: fixed_amex_rates; Type: TABLE; Schema: temp; Owner: -
--

CREATE TABLE fixed_amex_rates (
    id integer,
    payment_service_fee numeric
);
--
-- Name: lista_ceps; Type: TABLE; Schema: temp; Owner: -
--

CREATE TABLE lista_ceps (
    id character varying(255),
    cep character varying(255)
);
--
-- Name: lost_thumbs; Type: TABLE; Schema: temp; Owner: -
--

CREATE TABLE lost_thumbs (
    id integer
);
--
-- Name: moip_jan_2014_backers; Type: TABLE; Schema: temp; Owner: -
--

CREATE TABLE moip_jan_2014_backers (
    key text NOT NULL,
    moip_confirmed_date text,
    moip_confirmed_time text,
    moip_status text
);
--
-- Name: moip_payments; Type: TABLE; Schema: temp; Owner: -
--

CREATE TABLE moip_payments (
    id_moip text,
    key text,
    forma_pagamento text,
    descricao text,
    nome_comprador text,
    email_comprador text,
    data_inicial text,
    data_autorizacao text,
    data_conclusao text,
    data_atualizacao text,
    status text,
    substatus text,
    valor_total text,
    taxa_total text,
    pricing text,
    valor_fixo text,
    porcentagem text,
    porcentagem_antecipacao text,
    nova_taxa text,
    antecipacao text,
    taxa_antecipacao text,
    valor_liquido text,
    valor_moip text,
    valor_comissao text,
    parcelas text,
    id_lojista text
);
--
-- Name: pagarme_audit; Type: TABLE; Schema: temp; Owner: -
--

CREATE TABLE pagarme_audit (
    label text,
    contribution_id text,
    contribution_state text,
    transaction_installments text,
    transaction_payment_id text,
    transaction_amount text,
    transaction_status text,
    transaction_created text,
    transaction_customer_email text
);
--
-- Name: paypal_7_8; Type: TABLE; Schema: temp; Owner: -
--

CREATE TABLE paypal_7_8 (
    key text
);
--
-- Name: paypal_dez_2013_backers; Type: TABLE; Schema: temp; Owner: -
--

CREATE TABLE paypal_dez_2013_backers (
    payment_id text NOT NULL,
    paypal_confirmed_date text,
    paypal_confirmed_time text,
    paypal_status text
);
--
-- Name: paypal_jan_2014_backers; Type: TABLE; Schema: temp; Owner: -
--

CREATE TABLE paypal_jan_2014_backers (
    payment_id text NOT NULL,
    paypal_confirmed_date text,
    paypal_confirmed_time text,
    paypal_status text
);
--
-- Name: paypal_payments; Type: TABLE; Schema: temp; Owner: -
--

CREATE TABLE paypal_payments (
    data text,
    hora text,
    fusohorario text,
    nome text,
    tipo text,
    status text,
    moeda text,
    valorbruto text,
    tarifa text,
    liquido text,
    doe_mail text,
    parae_mail text,
    iddatransacao text,
    statusdoequivalente text,
    statusdoendereco text,
    titulodoitem text,
    iddoitem text,
    valordoenvioemanuseio text,
    valordoseguro text,
    impostosobrevendas text,
    opcao1nome text,
    opcao1valor text,
    opcao2nome text,
    opcao2valor text,
    sitedoleilao text,
    iddocomprador text,
    urldoitem text,
    datadetermino text,
    iddaescritura text,
    iddafatura text,
    "idtxn_dereferência" text,
    numerodafatura text,
    numeropersonalizado text,
    iddorecibo text,
    saldo text,
    enderecolinha1 text,
    enderecolinha2_distrito_bairro text,
    cidade text,
    "estado_regiao_território_prefeitura_republica" text,
    cep text,
    pais text,
    numerodotelefoneparacontato text,
    extra text
);
--
-- Name: paypal_temp_backers; Type: TABLE; Schema: temp; Owner: -
--

CREATE TABLE paypal_temp_backers (
    payment_id text NOT NULL
);
--
-- Name: project_ranges; Type: TABLE; Schema: temp; Owner: -
--

CREATE TABLE project_ranges (
    id integer,
    range tstzrange,
    state character varying(255)
);
--
-- Name: slips_to_update_fee; Type: TABLE; Schema: temp; Owner: -
--

CREATE TABLE slips_to_update_fee (
    date timestamp without time zone,
    gateway_id integer,
    fee numeric
);
--
-- Name: sorbonne; Type: TABLE; Schema: temp; Owner: -
--

CREATE TABLE sorbonne (
    user_id integer,
    login text,
    name text,
    wave integer DEFAULT 1 NOT NULL,
    row_number integer
);
--
-- Name: sorbonne_reinvite; Type: TABLE; Schema: temp; Owner: -
--

CREATE TABLE sorbonne_reinvite (
    user_id integer,
    login text,
    name text,
    wave integer
);
--
-- Name: taxa_antiga_pagarme; Type: TABLE; Schema: temp; Owner: -
--

CREATE TABLE taxa_antiga_pagarme (
    contribution_id integer,
    payment_id integer,
    new_payment_service_fee numeric
);
--
-- Name: temp_projects_to_get_some_info; Type: TABLE; Schema: temp; Owner: -
--

CREATE TABLE temp_projects_to_get_some_info (
    name text,
    original_id integer
);
--
-- Name: workshops; Type: TABLE; Schema: temp; Owner: -
--

CREATE TABLE workshops (
    id integer NOT NULL,
    name text NOT NULL,
    email text NOT NULL,
    workshop text NOT NULL,
    scheduled_at date NOT NULL
);
--
-- Name: workshops_id_seq; Type: SEQUENCE; Schema: temp; Owner: -
--

CREATE SEQUENCE workshops_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: workshops_id_seq; Type: SEQUENCE OWNED BY; Schema: temp; Owner: -
--

ALTER SEQUENCE workshops_id_seq OWNED BY workshops.id;
SET search_path = public, pg_catalog;

--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY authorizations ALTER COLUMN id SET DEFAULT nextval('authorizations_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY bank_accounts ALTER COLUMN id SET DEFAULT nextval('bank_accounts_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY banks ALTER COLUMN id SET DEFAULT nextval('banks_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY categories ALTER COLUMN id SET DEFAULT nextval('categories_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY category_followers ALTER COLUMN id SET DEFAULT nextval('category_followers_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY category_notifications ALTER COLUMN id SET DEFAULT nextval('category_notifications_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY channel_partners ALTER COLUMN id SET DEFAULT nextval('channel_partners_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY channel_post_notifications ALTER COLUMN id SET DEFAULT nextval('channel_post_notifications_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY channel_posts ALTER COLUMN id SET DEFAULT nextval('channel_posts_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY channels ALTER COLUMN id SET DEFAULT nextval('channels_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY channels_projects ALTER COLUMN id SET DEFAULT nextval('channels_projects_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY channels_subscribers ALTER COLUMN id SET DEFAULT nextval('channels_subscribers_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cities ALTER COLUMN id SET DEFAULT nextval('cities_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY contribution_notifications ALTER COLUMN id SET DEFAULT nextval('contribution_notifications_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY contributions ALTER COLUMN id SET DEFAULT nextval('contributions_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY countries ALTER COLUMN id SET DEFAULT nextval('countries_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY credit_cards ALTER COLUMN id SET DEFAULT nextval('credit_cards_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY dbhero_dataclips ALTER COLUMN id SET DEFAULT nextval('dbhero_dataclips_id_seq'::regclass);
--
-- Name: deps_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY deps_saved_ddl ALTER COLUMN deps_id SET DEFAULT nextval('deps_saved_ddl_deps_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY donation_notifications ALTER COLUMN id SET DEFAULT nextval('donation_notifications_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY donations ALTER COLUMN id SET DEFAULT nextval('donations_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY flexible_project_transitions ALTER COLUMN id SET DEFAULT nextval('flexible_project_transitions_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY flexible_projects ALTER COLUMN id SET DEFAULT nextval('flexible_projects_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY near_mes ALTER COLUMN id SET DEFAULT nextval('near_mes_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_providers ALTER COLUMN id SET DEFAULT nextval('oauth_providers_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY origins ALTER COLUMN id SET DEFAULT nextval('origins_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY payment_logs ALTER COLUMN id SET DEFAULT nextval('payment_logs_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY payment_notifications ALTER COLUMN id SET DEFAULT nextval('payment_notifications_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY payment_transfers ALTER COLUMN id SET DEFAULT nextval('payment_transfers_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY payments ALTER COLUMN id SET DEFAULT nextval('payments_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_accounts ALTER COLUMN id SET DEFAULT nextval('project_accounts_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_budgets ALTER COLUMN id SET DEFAULT nextval('project_budgets_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_notifications ALTER COLUMN id SET DEFAULT nextval('project_notifications_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_post_notifications ALTER COLUMN id SET DEFAULT nextval('project_post_notifications_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_posts ALTER COLUMN id SET DEFAULT nextval('updates_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_reminders ALTER COLUMN id SET DEFAULT nextval('project_reminders_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_transitions ALTER COLUMN id SET DEFAULT nextval('project_transitions_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY projects ALTER COLUMN id SET DEFAULT nextval('projects_id_seq'::regclass);
--
-- Name: permalink; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY projects ALTER COLUMN permalink SET DEFAULT ('project_'::text || (currval('projects_id_seq'::regclass))::text);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY redactor_assets ALTER COLUMN id SET DEFAULT nextval('redactor_assets_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY rewards ALTER COLUMN id SET DEFAULT nextval('rewards_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sendgrid_events ALTER COLUMN id SET DEFAULT nextval('sendgrid_events_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY settings ALTER COLUMN id SET DEFAULT nextval('configurations_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY states ALTER COLUMN id SET DEFAULT nextval('states_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY taggings ALTER COLUMN id SET DEFAULT nextval('taggings_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tags ALTER COLUMN id SET DEFAULT nextval('tags_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY unsubscribes ALTER COLUMN id SET DEFAULT nextval('unsubscribes_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_links ALTER COLUMN id SET DEFAULT nextval('user_links_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_notifications ALTER COLUMN id SET DEFAULT nextval('user_notifications_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_transfer_notifications ALTER COLUMN id SET DEFAULT nextval('user_transfer_notifications_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_transfers ALTER COLUMN id SET DEFAULT nextval('user_transfers_id_seq'::regclass);
--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);
SET search_path = temp, pg_catalog;

--
-- Name: id; Type: DEFAULT; Schema: temp; Owner: -
--

ALTER TABLE ONLY workshops ALTER COLUMN id SET DEFAULT nextval('workshops_id_seq'::regclass);
SET search_path = api_updates, pg_catalog;

--
-- Name: contributions_pkey; Type: CONSTRAINT; Schema: api_updates; Owner: -
--

ALTER TABLE ONLY contributions
    ADD CONSTRAINT contributions_pkey PRIMARY KEY (transaction_id, updated_at);
SET search_path = public, pg_catalog;

--
-- Name: authorizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY authorizations
    ADD CONSTRAINT authorizations_pkey PRIMARY KEY (id);
--
-- Name: backers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contributions
    ADD CONSTRAINT backers_pkey PRIMARY KEY (id);
--
-- Name: bank_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bank_accounts
    ADD CONSTRAINT bank_accounts_pkey PRIMARY KEY (id);
--
-- Name: banks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY banks
    ADD CONSTRAINT banks_pkey PRIMARY KEY (id);
--
-- Name: categories_name_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY categories
    ADD CONSTRAINT categories_name_unique UNIQUE (name_pt);
--
-- Name: categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);
--
-- Name: category_followers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY category_followers
    ADD CONSTRAINT category_followers_pkey PRIMARY KEY (id);
--
-- Name: category_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY category_notifications
    ADD CONSTRAINT category_notifications_pkey PRIMARY KEY (id);
--
-- Name: channel_partners_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY channel_partners
    ADD CONSTRAINT channel_partners_pkey PRIMARY KEY (id);
--
-- Name: channel_post_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY channel_post_notifications
    ADD CONSTRAINT channel_post_notifications_pkey PRIMARY KEY (id);
--
-- Name: channel_posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY channel_posts
    ADD CONSTRAINT channel_posts_pkey PRIMARY KEY (id);
--
-- Name: channel_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY channels
    ADD CONSTRAINT channel_profiles_pkey PRIMARY KEY (id);
--
-- Name: channels_projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY channels_projects
    ADD CONSTRAINT channels_projects_pkey PRIMARY KEY (id);
--
-- Name: channels_subscribers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY channels_subscribers
    ADD CONSTRAINT channels_subscribers_pkey PRIMARY KEY (id);
--
-- Name: cities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cities
    ADD CONSTRAINT cities_pkey PRIMARY KEY (id);
--
-- Name: configurations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY settings
    ADD CONSTRAINT configurations_pkey PRIMARY KEY (id);
--
-- Name: contribution_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contribution_notifications
    ADD CONSTRAINT contribution_notifications_pkey PRIMARY KEY (id);
--
-- Name: countries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (id);
--
-- Name: credit_cards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY credit_cards
    ADD CONSTRAINT credit_cards_pkey PRIMARY KEY (id);
--
-- Name: dbhero_dataclips_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY dbhero_dataclips
    ADD CONSTRAINT dbhero_dataclips_pkey PRIMARY KEY (id);
--
-- Name: deps_saved_ddl_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deps_saved_ddl
    ADD CONSTRAINT deps_saved_ddl_pkey PRIMARY KEY (deps_id);
--
-- Name: donation_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY donation_notifications
    ADD CONSTRAINT donation_notifications_pkey PRIMARY KEY (id);
--
-- Name: donations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY donations
    ADD CONSTRAINT donations_pkey PRIMARY KEY (id);
--
-- Name: flexible_project_states_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY flexible_project_states
    ADD CONSTRAINT flexible_project_states_pkey PRIMARY KEY (state);
--
-- Name: flexible_project_transitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY flexible_project_transitions
    ADD CONSTRAINT flexible_project_transitions_pkey PRIMARY KEY (id);
--
-- Name: flexible_projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY flexible_projects
    ADD CONSTRAINT flexible_projects_pkey PRIMARY KEY (id);
--
-- Name: near_mes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY near_mes
    ADD CONSTRAINT near_mes_pkey PRIMARY KEY (id);
--
-- Name: oauth_providers_name_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_providers
    ADD CONSTRAINT oauth_providers_name_unique UNIQUE (name);
--
-- Name: oauth_providers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_providers
    ADD CONSTRAINT oauth_providers_pkey PRIMARY KEY (id);
--
-- Name: origins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY origins
    ADD CONSTRAINT origins_pkey PRIMARY KEY (id);
--
-- Name: payment_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY payment_logs
    ADD CONSTRAINT payment_logs_pkey PRIMARY KEY (id);
--
-- Name: payment_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY payment_notifications
    ADD CONSTRAINT payment_notifications_pkey PRIMARY KEY (id);
--
-- Name: payment_transfers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY payment_transfers
    ADD CONSTRAINT payment_transfers_pkey PRIMARY KEY (id);
--
-- Name: payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);
--
-- Name: project_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_accounts
    ADD CONSTRAINT project_accounts_pkey PRIMARY KEY (id);
--
-- Name: project_budgets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_budgets
    ADD CONSTRAINT project_budgets_pkey PRIMARY KEY (id);
--
-- Name: project_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_notifications
    ADD CONSTRAINT project_notifications_pkey PRIMARY KEY (id);
--
-- Name: project_post_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_post_notifications
    ADD CONSTRAINT project_post_notifications_pkey PRIMARY KEY (id);
--
-- Name: project_reminders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_reminders
    ADD CONSTRAINT project_reminders_pkey PRIMARY KEY (id);
--
-- Name: project_states_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_states
    ADD CONSTRAINT project_states_pkey PRIMARY KEY (state);
--
-- Name: project_transitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_transitions
    ADD CONSTRAINT project_transitions_pkey PRIMARY KEY (id);
--
-- Name: projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);
--
-- Name: redactor_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY redactor_assets
    ADD CONSTRAINT redactor_assets_pkey PRIMARY KEY (id);
--
-- Name: rewards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY rewards
    ADD CONSTRAINT rewards_pkey PRIMARY KEY (id);
--
-- Name: sendgrid_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sendgrid_events
    ADD CONSTRAINT sendgrid_events_pkey PRIMARY KEY (id);
--
-- Name: states_acronym_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY states
    ADD CONSTRAINT states_acronym_unique UNIQUE (acronym);
--
-- Name: states_name_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY states
    ADD CONSTRAINT states_name_unique UNIQUE (name);
--
-- Name: states_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY states
    ADD CONSTRAINT states_pkey PRIMARY KEY (id);
--
-- Name: taggings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY taggings
    ADD CONSTRAINT taggings_pkey PRIMARY KEY (id);
--
-- Name: tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);
--
-- Name: unsubscribes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY unsubscribes
    ADD CONSTRAINT unsubscribes_pkey PRIMARY KEY (id);
--
-- Name: updates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_posts
    ADD CONSTRAINT updates_pkey PRIMARY KEY (id);
--
-- Name: user_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_links
    ADD CONSTRAINT user_links_pkey PRIMARY KEY (id);
--
-- Name: user_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_notifications
    ADD CONSTRAINT user_notifications_pkey PRIMARY KEY (id);
--
-- Name: user_transfer_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_transfer_notifications
    ADD CONSTRAINT user_transfer_notifications_pkey PRIMARY KEY (id);
--
-- Name: user_transfers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_transfers
    ADD CONSTRAINT user_transfers_pkey PRIMARY KEY (id);
--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);
SET search_path = temp, pg_catalog;

--
-- Name: moip_jan_2014_backers_key_key; Type: CONSTRAINT; Schema: temp; Owner: -
--

ALTER TABLE ONLY moip_jan_2014_backers
    ADD CONSTRAINT moip_jan_2014_backers_key_key UNIQUE (key);
--
-- Name: paypal_dez_2013_backers_payment_id_key; Type: CONSTRAINT; Schema: temp; Owner: -
--

ALTER TABLE ONLY paypal_dez_2013_backers
    ADD CONSTRAINT paypal_dez_2013_backers_payment_id_key UNIQUE (payment_id);
--
-- Name: paypal_jan_2014_backers_payment_id_key; Type: CONSTRAINT; Schema: temp; Owner: -
--

ALTER TABLE ONLY paypal_jan_2014_backers
    ADD CONSTRAINT paypal_jan_2014_backers_payment_id_key UNIQUE (payment_id);
--
-- Name: workshops_pkey; Type: CONSTRAINT; Schema: temp; Owner: -
--

ALTER TABLE ONLY workshops
    ADD CONSTRAINT workshops_pkey PRIMARY KEY (id);
SET search_path = "1", pg_catalog;

--
-- Name: statistics_total_users_idx; Type: INDEX; Schema: 1; Owner: -
--

CREATE UNIQUE INDEX statistics_total_users_idx ON statistics USING btree (total_users);
--
-- Name: user_totals_id_idx; Type: INDEX; Schema: 1; Owner: -
--

CREATE INDEX user_totals_id_idx ON user_totals USING btree (id);
SET search_path = public, pg_catalog;

--
-- Name: fk__authorizations_oauth_provider_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__authorizations_oauth_provider_id ON authorizations USING btree (oauth_provider_id);
--
-- Name: fk__authorizations_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__authorizations_user_id ON authorizations USING btree (user_id);
--
-- Name: fk__bank_accounts_bank_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__bank_accounts_bank_id ON bank_accounts USING btree (bank_id);
--
-- Name: fk__bank_accounts_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__bank_accounts_user_id ON bank_accounts USING btree (user_id);
--
-- Name: fk__category_followers_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__category_followers_category_id ON category_followers USING btree (category_id);
--
-- Name: fk__category_followers_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__category_followers_user_id ON category_followers USING btree (user_id);
--
-- Name: fk__category_notifications_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__category_notifications_category_id ON category_notifications USING btree (category_id);
--
-- Name: fk__category_notifications_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__category_notifications_user_id ON category_notifications USING btree (user_id);
--
-- Name: fk__channel_partners_channel_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__channel_partners_channel_id ON channel_partners USING btree (channel_id);
--
-- Name: fk__channel_post_notifications_channel_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__channel_post_notifications_channel_post_id ON channel_post_notifications USING btree (channel_post_id);
--
-- Name: fk__channel_post_notifications_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__channel_post_notifications_user_id ON channel_post_notifications USING btree (user_id);
--
-- Name: fk__channel_posts_channel_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__channel_posts_channel_id ON channel_posts USING btree (channel_id);
--
-- Name: fk__channel_posts_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__channel_posts_user_id ON channel_posts USING btree (user_id);
--
-- Name: fk__channels_subscribers_channel_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__channels_subscribers_channel_id ON channels_subscribers USING btree (channel_id);
--
-- Name: fk__channels_subscribers_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__channels_subscribers_user_id ON channels_subscribers USING btree (user_id);
--
-- Name: fk__cities_state_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__cities_state_id ON cities USING btree (state_id);
--
-- Name: fk__contribution_notifications_contribution_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__contribution_notifications_contribution_id ON contribution_notifications USING btree (contribution_id);
--
-- Name: fk__contribution_notifications_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__contribution_notifications_user_id ON contribution_notifications USING btree (user_id);
--
-- Name: fk__contributions_country_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__contributions_country_id ON contributions USING btree (country_id);
--
-- Name: fk__contributions_donation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__contributions_donation_id ON contributions USING btree (donation_id);
--
-- Name: fk__contributions_origin_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__contributions_origin_id ON contributions USING btree (origin_id);
--
-- Name: fk__credit_cards_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__credit_cards_user_id ON credit_cards USING btree (user_id);
--
-- Name: fk__donation_notifications_donation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__donation_notifications_donation_id ON donation_notifications USING btree (donation_id);
--
-- Name: fk__donation_notifications_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__donation_notifications_user_id ON donation_notifications USING btree (user_id);
--
-- Name: fk__flexible_project_transitions_flexible_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__flexible_project_transitions_flexible_project_id ON flexible_project_transitions USING btree (flexible_project_id);
--
-- Name: fk__flexible_projects_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__flexible_projects_project_id ON flexible_projects USING btree (project_id);
--
-- Name: fk__payment_notifications_payment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__payment_notifications_payment_id ON payment_notifications USING btree (payment_id);
--
-- Name: fk__payment_transfers_payment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__payment_transfers_payment_id ON payment_transfers USING btree (payment_id);
--
-- Name: fk__payment_transfers_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__payment_transfers_user_id ON payment_transfers USING btree (user_id);
--
-- Name: fk__payments_contribution_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__payments_contribution_id ON payments USING btree (contribution_id);
--
-- Name: fk__project_accounts_bank_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__project_accounts_bank_id ON project_accounts USING btree (bank_id);
--
-- Name: fk__project_budgets_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__project_budgets_project_id ON project_budgets USING btree (project_id);
--
-- Name: fk__project_notifications_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__project_notifications_project_id ON project_notifications USING btree (project_id);
--
-- Name: fk__project_notifications_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__project_notifications_user_id ON project_notifications USING btree (user_id);
--
-- Name: fk__project_post_notifications_project_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__project_post_notifications_project_post_id ON project_post_notifications USING btree (project_post_id);
--
-- Name: fk__project_post_notifications_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__project_post_notifications_user_id ON project_post_notifications USING btree (user_id);
--
-- Name: fk__project_reminders_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__project_reminders_project_id ON project_reminders USING btree (project_id);
--
-- Name: fk__project_reminders_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__project_reminders_user_id ON project_reminders USING btree (user_id);
--
-- Name: fk__project_transitions_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__project_transitions_project_id ON project_transitions USING btree (project_id);
--
-- Name: fk__projects_origin_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__projects_origin_id ON projects USING btree (origin_id);
--
-- Name: fk__redactor_assets_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__redactor_assets_user_id ON redactor_assets USING btree (user_id);
--
-- Name: fk__taggings_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__taggings_project_id ON taggings USING btree (project_id);
--
-- Name: fk__taggings_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__taggings_tag_id ON taggings USING btree (tag_id);
--
-- Name: fk__user_links_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__user_links_user_id ON user_links USING btree (user_id);
--
-- Name: fk__user_notifications_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__user_notifications_user_id ON user_notifications USING btree (user_id);
--
-- Name: fk__user_transfer_notifications_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__user_transfer_notifications_user_id ON user_transfer_notifications USING btree (user_id);
--
-- Name: fk__user_transfer_notifications_user_transfer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__user_transfer_notifications_user_transfer_id ON user_transfer_notifications USING btree (user_transfer_id);
--
-- Name: fk__user_transfers_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__user_transfers_user_id ON user_transfers USING btree (user_id);
--
-- Name: fk__users_channel_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__users_channel_id ON users USING btree (channel_id);
--
-- Name: fk__users_country_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk__users_country_id ON users USING btree (country_id);
--
-- Name: flexible_project_transitions_flexible_project_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX flexible_project_transitions_flexible_project_id_idx ON flexible_project_transitions USING btree (flexible_project_id) WHERE most_recent;
--
-- Name: idx_redactor_assetable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_redactor_assetable ON redactor_assets USING btree (assetable_type, assetable_id);
--
-- Name: idx_redactor_assetable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_redactor_assetable_type ON redactor_assets USING btree (assetable_type, type, assetable_id);
--
-- Name: index_authorizations_on_oauth_provider_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_authorizations_on_oauth_provider_id_and_user_id ON authorizations USING btree (oauth_provider_id, user_id);
--
-- Name: index_authorizations_on_uid_and_oauth_provider_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_authorizations_on_uid_and_oauth_provider_id ON authorizations USING btree (uid, oauth_provider_id);
--
-- Name: index_bank_accounts_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_accounts_on_user_id ON bank_accounts USING btree (user_id);
--
-- Name: index_banks_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_banks_on_code ON banks USING btree (code);
--
-- Name: index_categories_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_categories_on_name ON categories USING btree (name_pt);
--
-- Name: index_category_followers_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_category_followers_on_category_id ON category_followers USING btree (category_id);
--
-- Name: index_category_followers_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_category_followers_on_user_id ON category_followers USING btree (user_id);
--
-- Name: index_channel_posts_on_channel_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_channel_posts_on_channel_id ON channel_posts USING btree (channel_id);
--
-- Name: index_channel_posts_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_channel_posts_on_user_id ON channel_posts USING btree (user_id);
--
-- Name: index_channels_on_permalink; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_channels_on_permalink ON channels USING btree (permalink);
--
-- Name: index_channels_projects_on_channel_id_and_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_channels_projects_on_channel_id_and_project_id ON channels_projects USING btree (channel_id, project_id);
--
-- Name: index_channels_projects_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_channels_projects_on_project_id ON channels_projects USING btree (project_id);
--
-- Name: index_channels_subscribers_on_user_id_and_channel_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_channels_subscribers_on_user_id_and_channel_id ON channels_subscribers USING btree (user_id, channel_id);
--
-- Name: index_configurations_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_configurations_on_name ON settings USING btree (name);
--
-- Name: index_contributions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contributions_on_created_at ON contributions USING btree (created_at);
--
-- Name: index_contributions_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contributions_on_project_id ON contributions USING btree (project_id);
--
-- Name: index_contributions_on_reward_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contributions_on_reward_id ON contributions USING btree (reward_id);
--
-- Name: index_contributions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contributions_on_user_id ON contributions USING btree (user_id);
--
-- Name: index_credit_cards_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_credit_cards_on_user_id ON credit_cards USING btree (user_id);
--
-- Name: index_dbhero_dataclips_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_dbhero_dataclips_on_token ON dbhero_dataclips USING btree (token);
--
-- Name: index_dbhero_dataclips_on_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dbhero_dataclips_on_user ON dbhero_dataclips USING btree ("user");
--
-- Name: index_donations_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_donations_on_user_id ON donations USING btree (user_id);
--
-- Name: index_flexible_project_transitions_parent_sort; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_flexible_project_transitions_parent_sort ON flexible_project_transitions USING btree (flexible_project_id, sort_key);
--
-- Name: index_flexible_projects_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_flexible_projects_on_project_id ON flexible_projects USING btree (project_id);
--
-- Name: index_origins_on_domain_and_referral; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_origins_on_domain_and_referral ON origins USING btree (domain, referral);
--
-- Name: index_payment_notifications_on_contribution_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payment_notifications_on_contribution_id ON payment_notifications USING btree (contribution_id);
--
-- Name: index_payments_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_payments_on_key ON payments USING btree (key);
--
-- Name: index_project_accounts_on_bank_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_accounts_on_bank_id ON project_accounts USING btree (bank_id);
--
-- Name: index_project_accounts_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_accounts_on_project_id ON project_accounts USING btree (project_id);
--
-- Name: index_project_reminders_on_user_id_and_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_project_reminders_on_user_id_and_project_id ON project_reminders USING btree (user_id, project_id);
--
-- Name: index_project_transitions_parent_sort; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_project_transitions_parent_sort ON project_transitions USING btree (project_id, sort_key);
--
-- Name: index_projects_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_category_id ON projects USING btree (category_id);
--
-- Name: index_projects_on_city_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_city_id ON projects USING btree (city_id);
--
-- Name: index_projects_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_name ON projects USING btree (name);
--
-- Name: index_projects_on_permalink; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_projects_on_permalink ON projects USING btree (lower(permalink));
--
-- Name: index_projects_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_user_id ON projects USING btree (user_id);
--
-- Name: index_rewards_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rewards_on_project_id ON rewards USING btree (project_id);
--
-- Name: index_taggings_on_tag_id_and_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_taggings_on_tag_id_and_project_id ON taggings USING btree (tag_id, project_id);
--
-- Name: index_tags_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tags_on_slug ON tags USING btree (slug);
--
-- Name: index_unsubscribes_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_unsubscribes_on_project_id ON unsubscribes USING btree (project_id);
--
-- Name: index_unsubscribes_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_unsubscribes_on_user_id ON unsubscribes USING btree (user_id);
--
-- Name: index_updates_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_updates_on_project_id ON project_posts USING btree (project_id);
--
-- Name: index_users_on_authentication_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_authentication_token ON users USING btree (authentication_token);
--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);
--
-- Name: index_users_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_name ON users USING btree (name);
--
-- Name: index_users_on_permalink; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_permalink ON users USING btree (permalink);
--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);
--
-- Name: online_projects_id_ix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX online_projects_id_ix ON projects USING btree (id) WHERE ((state)::text = 'online'::text);
--
-- Name: payments_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payments_created_at_idx ON payments USING btree (created_at);
--
-- Name: payments_full_text_index_ix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payments_full_text_index_ix ON payments USING gin (full_text_index);
--
-- Name: payments_gateway_id_gateway_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX payments_gateway_id_gateway_idx ON payments USING btree (gateway_id, gateway);
--
-- Name: payments_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX payments_id_idx ON payments USING btree (id DESC);
--
-- Name: project_transitions_project_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX project_transitions_project_id_idx ON project_transitions USING btree (project_id) WHERE most_recent;
--
-- Name: projects_full_text_index_ix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX projects_full_text_index_ix ON projects USING gin (full_text_index);
--
-- Name: projects_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX projects_name_idx ON projects USING gist (name gist_trgm_ops);
--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);
--
-- Name: user_admin_id_ix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_admin_id_ix ON users USING btree (id) WHERE admin;
--
-- Name: users_deactivated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_deactivated_at_idx ON users USING btree (deactivated_at);
--
-- Name: users_full_text_index_ix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_full_text_index_ix ON users USING gin (full_text_index);
--
-- Name: users_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_id_idx ON users USING btree (id DESC);
SET search_path = temp, pg_catalog;

--
-- Name: workshops_email_workshop_idx; Type: INDEX; Schema: temp; Owner: -
--

CREATE UNIQUE INDEX workshops_email_workshop_idx ON workshops USING btree (email, workshop);
SET search_path = "1", pg_catalog;

--
-- Name: _RETURN; Type: RULE; Schema: 1; Owner: -
--

CREATE RULE "_RETURN" AS
    ON SELECT TO project_totals DO INSTEAD  SELECT c.project_id,
    sum(p.value) AS pledged,
    ((sum(p.value) / projects.goal) * (100)::numeric) AS progress,
    sum(p.gateway_fee) AS total_payment_service_fee,
    count(DISTINCT c.id) AS total_contributions,
    count(DISTINCT c.user_id) AS total_contributors
   FROM ((public.contributions c
     JOIN public.projects ON ((c.project_id = projects.id)))
     JOIN public.payments p ON ((p.contribution_id = c.id)))
  WHERE (p.state = ANY (public.confirmed_states()))
  GROUP BY c.project_id, projects.id;
--
-- Name: _RETURN; Type: RULE; Schema: 1; Owner: -
--

CREATE RULE "_RETURN" AS
    ON SELECT TO category_totals DO INSTEAD  WITH project_stats AS (
         SELECT ca.id AS category_id,
            ca.name_pt AS name,
            count(DISTINCT p_1.id) FILTER (WHERE ((p_1.state)::text = 'online'::text)) AS online_projects,
            count(DISTINCT p_1.id) FILTER (WHERE ((p_1.state)::text = 'successful'::text)) AS successful_projects,
            count(DISTINCT p_1.id) FILTER (WHERE ((p_1.state)::text = 'failed'::text)) AS failed_projects,
            avg(p_1.goal) AS avg_goal,
            avg(pt.pledged) AS avg_pledged,
            sum(pt.pledged) FILTER (WHERE ((p_1.state)::text = 'successful'::text)) AS total_successful_value,
            sum(pt.pledged) AS total_value
           FROM ((public.projects p_1
             JOIN public.categories ca ON ((ca.id = p_1.category_id)))
             LEFT JOIN project_totals pt ON ((pt.project_id = p_1.id)))
          WHERE ((p_1.state)::text <> ALL (ARRAY[('draft'::character varying)::text, ('in_analysis'::character varying)::text, ('rejected'::character varying)::text]))
          GROUP BY ca.id
        ), contribution_stats AS (
         SELECT ca.id AS category_id,
            ca.name_pt,
            avg(pa.value) AS avg_value,
            count(DISTINCT c_1.user_id) AS total_contributors
           FROM (((public.projects p_1
             JOIN public.categories ca ON ((ca.id = p_1.category_id)))
             JOIN public.contributions c_1 ON ((c_1.project_id = p_1.id)))
             JOIN public.payments pa ON ((pa.contribution_id = c_1.id)))
          WHERE (((p_1.state)::text <> ALL (ARRAY[('draft'::character varying)::text, ('in_analysis'::character varying)::text, ('rejected'::character varying)::text])) AND (pa.state = ANY (public.confirmed_states())))
          GROUP BY ca.id
        ), followers AS (
         SELECT cf_1.category_id,
            count(DISTINCT cf_1.user_id) AS followers
           FROM public.category_followers cf_1
          GROUP BY cf_1.category_id
        )
 SELECT p.category_id,
    p.name,
    p.online_projects,
    p.successful_projects,
    p.failed_projects,
    p.avg_goal,
    p.avg_pledged,
    p.total_successful_value,
    p.total_value,
    c.name_pt,
    c.avg_value,
    c.total_contributors,
    cf.followers
   FROM ((project_stats p
     JOIN contribution_stats c USING (category_id))
     LEFT JOIN followers cf USING (category_id));
--
-- Name: _RETURN; Type: RULE; Schema: 1; Owner: -
--

CREATE RULE "_RETURN" AS
    ON SELECT TO project_contributions_per_location DO INSTEAD  SELECT addr_agg.project_id,
    json_agg(json_build_object('state_acronym', addr_agg.state_acronym, 'state_name', addr_agg.state_name, 'total_contributions', addr_agg.total_contributions, 'total_contributed', addr_agg.total_contributed, 'total_on_percentage', addr_agg.total_on_percentage) ORDER BY addr_agg.state_acronym) AS source
   FROM ( SELECT p.id AS project_id,
            s.acronym AS state_acronym,
            s.name AS state_name,
            count(c.*) AS total_contributions,
            sum(c.value) AS total_contributed,
            ((sum(c.value) * (100)::numeric) / COALESCE(pt.pledged, (0)::numeric)) AS total_on_percentage
           FROM (((public.projects p
             JOIN public.contributions c ON ((p.id = c.project_id)))
             LEFT JOIN public.states s ON ((upper((s.acronym)::text) = upper(c.address_state))))
             LEFT JOIN project_totals pt ON ((pt.project_id = c.project_id)))
          WHERE (public.is_published(p.*) AND public.was_confirmed(c.*))
          GROUP BY p.id, s.acronym, s.name, pt.pledged
          ORDER BY p.created_at DESC) addr_agg
  GROUP BY addr_agg.project_id;
--
-- Name: _RETURN; Type: RULE; Schema: 1; Owner: -
--

CREATE RULE "_RETURN" AS
    ON SELECT TO project_details DO INSTEAD  SELECT p.id AS project_id,
    p.id,
    p.user_id,
    p.name,
    p.headline,
    p.budget,
    p.goal,
    p.about_html,
    p.permalink,
    p.video_embed_url,
    p.video_url,
    c.name_pt AS category_name,
    c.id AS category_id,
    public.original_image(p.*) AS original_image,
    public.thumbnail_image(p.*, 'thumb'::text) AS thumb_image,
    public.thumbnail_image(p.*, 'small'::text) AS small_image,
    public.thumbnail_image(p.*, 'large'::text) AS large_image,
    public.thumbnail_image(p.*, 'video_cover'::text) AS video_cover_image,
    COALESCE(pt.progress, (0)::numeric) AS progress,
    COALESCE(pt.pledged, (0)::numeric) AS pledged,
    COALESCE(pt.total_contributions, (0)::bigint) AS total_contributions,
    COALESCE(pt.total_contributors, (0)::bigint) AS total_contributors,
    COALESCE(fp.state, (p.state)::text) AS state,
    public.mode(p.*) AS mode,
    public.state_order(p.*) AS state_order,
    p.expires_at,
    public.zone_timestamp(p.expires_at) AS zone_expires_at,
    p.online_date,
    public.zone_timestamp(p.online_date) AS zone_online_date,
    p.sent_to_analysis_at,
    public.is_published(p.*) AS is_published,
    public.is_expired(p.*) AS is_expired,
    public.open_for_contributions(p.*) AS open_for_contributions,
    p.online_days,
    public.remaining_time_json(p.*) AS remaining_time,
    public.elapsed_time_json(p.*) AS elapsed_time,
    ( SELECT count(pp_1.*) AS count
           FROM public.project_posts pp_1
          WHERE (pp_1.project_id = p.id)) AS posts_count,
    json_build_object('city', COALESCE(ct.name, u.address_city), 'state_acronym', COALESCE(st.acronym, (u.address_state)::character varying), 'state', COALESCE(st.name, (u.address_state)::character varying)) AS address,
    json_build_object('id', u.id, 'name', u.name) AS "user",
    count(DISTINCT pr.user_id) AS reminder_count,
    public.is_owner_or_admin(p.user_id) AS is_owner_or_admin,
    public.user_signed_in() AS user_signed_in,
    public.current_user_already_in_reminder(p.*) AS in_reminder,
    count(pp.*) AS total_posts,
    ("current_user"() = 'admin'::name) AS is_admin_role
   FROM ((((((((public.projects p
     JOIN public.categories c ON ((c.id = p.category_id)))
     JOIN public.users u ON ((u.id = p.user_id)))
     LEFT JOIN public.flexible_projects fp ON ((fp.project_id = p.id)))
     LEFT JOIN public.project_posts pp ON ((pp.project_id = p.id)))
     LEFT JOIN project_totals pt ON ((pt.project_id = p.id)))
     LEFT JOIN public.cities ct ON ((ct.id = p.city_id)))
     LEFT JOIN public.states st ON ((st.id = ct.state_id)))
     LEFT JOIN public.project_reminders pr ON ((pr.project_id = p.id)))
  GROUP BY p.id, c.id, u.id, c.name_pt, ct.name, u.address_city, st.acronym, u.address_state, st.name, pt.progress, pt.pledged, pt.total_contributions, p.state, p.expires_at, p.sent_to_analysis_at, pt.total_payment_service_fee, fp.state, pt.total_contributors;
--
-- Name: _RETURN; Type: RULE; Schema: 1; Owner: -
--

CREATE RULE "_RETURN" AS
    ON SELECT TO categories DO INSTEAD  SELECT c.id,
    c.name_pt AS name,
    count(DISTINCT p.id) FILTER (WHERE public.is_current_and_online(p.expires_at, COALESCE(fp.state, (p.state)::text))) AS online_projects,
    ( SELECT count(DISTINCT cf.user_id) AS count
           FROM public.category_followers cf
          WHERE (cf.category_id = c.id)) AS followers,
    (EXISTS ( SELECT true AS bool
           FROM public.category_followers cf
          WHERE ((cf.category_id = c.id) AND (cf.user_id = public.current_user_id())))) AS following
   FROM ((public.categories c
     LEFT JOIN public.projects p ON ((p.category_id = c.id)))
     LEFT JOIN public.flexible_projects fp ON ((fp.project_id = p.id)))
  GROUP BY c.id;
--
-- Name: delete_category_followers; Type: TRIGGER; Schema: 1; Owner: -
--

CREATE TRIGGER delete_category_followers INSTEAD OF DELETE ON category_followers FOR EACH ROW EXECUTE PROCEDURE public.delete_category_followers();
--
-- Name: delete_project_reminder; Type: TRIGGER; Schema: 1; Owner: -
--

CREATE TRIGGER delete_project_reminder INSTEAD OF DELETE ON project_reminders FOR EACH ROW EXECUTE PROCEDURE public.delete_project_reminder();
--
-- Name: insert_category_followers; Type: TRIGGER; Schema: 1; Owner: -
--

CREATE TRIGGER insert_category_followers INSTEAD OF INSERT ON category_followers FOR EACH ROW EXECUTE PROCEDURE public.insert_category_followers();
--
-- Name: insert_project_reminder; Type: TRIGGER; Schema: 1; Owner: -
--

CREATE TRIGGER insert_project_reminder INSTEAD OF INSERT ON project_reminders FOR EACH ROW EXECUTE PROCEDURE public.insert_project_reminder();
--
-- Name: update_from_details_to_contributions; Type: TRIGGER; Schema: 1; Owner: -
--

CREATE TRIGGER update_from_details_to_contributions INSTEAD OF UPDATE ON contribution_details FOR EACH ROW EXECUTE PROCEDURE public.update_from_details_to_contributions();
SET search_path = public, pg_catalog;

--
-- Name: notify_about_confirmed_payments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER notify_about_confirmed_payments AFTER UPDATE OF state ON payments FOR EACH ROW WHEN (((old.state <> 'paid'::text) AND (new.state = 'paid'::text))) EXECUTE PROCEDURE notify_about_confirmed_payments();
--
-- Name: sent_validation; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER sent_validation AFTER INSERT OR UPDATE ON projects NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE PROCEDURE sent_validation();
--
-- Name: update_full_text_index; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_full_text_index BEFORE INSERT OR UPDATE OF name, permalink, headline ON projects FOR EACH ROW EXECUTE PROCEDURE update_full_text_index();
--
-- Name: update_payments_full_text_index; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_payments_full_text_index BEFORE INSERT OR UPDATE OF key, gateway, gateway_id, gateway_data, state ON payments FOR EACH ROW EXECUTE PROCEDURE update_payments_full_text_index();
--
-- Name: update_users_full_text_index; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_users_full_text_index BEFORE INSERT OR UPDATE OF id, name, email ON users FOR EACH ROW EXECUTE PROCEDURE update_users_full_text_index();
--
-- Name: validate_project_expires_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER validate_project_expires_at BEFORE INSERT OR UPDATE OF contribution_id ON payments FOR EACH ROW EXECUTE PROCEDURE validate_project_expires_at();
--
-- Name: validate_reward_sold_out; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER validate_reward_sold_out BEFORE INSERT OR UPDATE OF contribution_id ON payments FOR EACH ROW EXECUTE PROCEDURE validate_reward_sold_out();
--
-- Name: contributions_project_id_reference; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contributions
    ADD CONSTRAINT contributions_project_id_reference FOREIGN KEY (project_id) REFERENCES projects(id);
--
-- Name: contributions_reward_id_reference; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contributions
    ADD CONSTRAINT contributions_reward_id_reference FOREIGN KEY (reward_id) REFERENCES rewards(id);
--
-- Name: contributions_user_id_reference; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contributions
    ADD CONSTRAINT contributions_user_id_reference FOREIGN KEY (user_id) REFERENCES users(id);
--
-- Name: fk_authorizations_oauth_provider_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY authorizations
    ADD CONSTRAINT fk_authorizations_oauth_provider_id FOREIGN KEY (oauth_provider_id) REFERENCES oauth_providers(id);
--
-- Name: fk_authorizations_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY authorizations
    ADD CONSTRAINT fk_authorizations_user_id FOREIGN KEY (user_id) REFERENCES users(id);
--
-- Name: fk_bank_accounts_bank_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bank_accounts
    ADD CONSTRAINT fk_bank_accounts_bank_id FOREIGN KEY (bank_id) REFERENCES banks(id);
--
-- Name: fk_bank_accounts_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bank_accounts
    ADD CONSTRAINT fk_bank_accounts_user_id FOREIGN KEY (user_id) REFERENCES users(id);
--
-- Name: fk_category_followers_category_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY category_followers
    ADD CONSTRAINT fk_category_followers_category_id FOREIGN KEY (category_id) REFERENCES categories(id);
--
-- Name: fk_category_followers_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY category_followers
    ADD CONSTRAINT fk_category_followers_user_id FOREIGN KEY (user_id) REFERENCES users(id);
--
-- Name: fk_category_notifications_category_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY category_notifications
    ADD CONSTRAINT fk_category_notifications_category_id FOREIGN KEY (category_id) REFERENCES categories(id);
--
-- Name: fk_category_notifications_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY category_notifications
    ADD CONSTRAINT fk_category_notifications_user_id FOREIGN KEY (user_id) REFERENCES users(id);
--
-- Name: fk_channel_partners_channel_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY channel_partners
    ADD CONSTRAINT fk_channel_partners_channel_id FOREIGN KEY (channel_id) REFERENCES channels(id);
--
-- Name: fk_channel_post_notifications_channel_post_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY channel_post_notifications
    ADD CONSTRAINT fk_channel_post_notifications_channel_post_id FOREIGN KEY (channel_post_id) REFERENCES channel_posts(id);
--
-- Name: fk_channel_post_notifications_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY channel_post_notifications
    ADD CONSTRAINT fk_channel_post_notifications_user_id FOREIGN KEY (user_id) REFERENCES users(id);
--
-- Name: fk_channel_posts_channel_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY channel_posts
    ADD CONSTRAINT fk_channel_posts_channel_id FOREIGN KEY (channel_id) REFERENCES channels(id);
--
-- Name: fk_channel_posts_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY channel_posts
    ADD CONSTRAINT fk_channel_posts_user_id FOREIGN KEY (user_id) REFERENCES users(id);
--
-- Name: fk_channels_projects_channel_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY channels_projects
    ADD CONSTRAINT fk_channels_projects_channel_id FOREIGN KEY (channel_id) REFERENCES channels(id);
--
-- Name: fk_channels_projects_project_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY channels_projects
    ADD CONSTRAINT fk_channels_projects_project_id FOREIGN KEY (project_id) REFERENCES projects(id);
--
-- Name: fk_channels_subscribers_channel_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY channels_subscribers
    ADD CONSTRAINT fk_channels_subscribers_channel_id FOREIGN KEY (channel_id) REFERENCES channels(id);
--
-- Name: fk_channels_subscribers_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY channels_subscribers
    ADD CONSTRAINT fk_channels_subscribers_user_id FOREIGN KEY (user_id) REFERENCES users(id);
--
-- Name: fk_cities_state_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cities
    ADD CONSTRAINT fk_cities_state_id FOREIGN KEY (state_id) REFERENCES states(id);
--
-- Name: fk_contribution_notifications_contribution_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contribution_notifications
    ADD CONSTRAINT fk_contribution_notifications_contribution_id FOREIGN KEY (contribution_id) REFERENCES contributions(id);
--
-- Name: fk_contribution_notifications_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contribution_notifications
    ADD CONSTRAINT fk_contribution_notifications_user_id FOREIGN KEY (user_id) REFERENCES users(id);
--
-- Name: fk_contributions_country_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contributions
    ADD CONSTRAINT fk_contributions_country_id FOREIGN KEY (country_id) REFERENCES countries(id);
--
-- Name: fk_contributions_donation_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contributions
    ADD CONSTRAINT fk_contributions_donation_id FOREIGN KEY (donation_id) REFERENCES donations(id);
--
-- Name: fk_contributions_origin_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contributions
    ADD CONSTRAINT fk_contributions_origin_id FOREIGN KEY (origin_id) REFERENCES origins(id);
--
-- Name: fk_credit_cards_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY credit_cards
    ADD CONSTRAINT fk_credit_cards_user_id FOREIGN KEY (user_id) REFERENCES users(id);
--
-- Name: fk_donation_notifications_donation_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY donation_notifications
    ADD CONSTRAINT fk_donation_notifications_donation_id FOREIGN KEY (donation_id) REFERENCES donations(id);
--
-- Name: fk_donation_notifications_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY donation_notifications
    ADD CONSTRAINT fk_donation_notifications_user_id FOREIGN KEY (user_id) REFERENCES users(id);
--
-- Name: fk_donations_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY donations
    ADD CONSTRAINT fk_donations_user_id FOREIGN KEY (user_id) REFERENCES users(id);
--
-- Name: fk_flexible_project_transitions_flexible_project_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY flexible_project_transitions
    ADD CONSTRAINT fk_flexible_project_transitions_flexible_project_id FOREIGN KEY (flexible_project_id) REFERENCES flexible_projects(id);
--
-- Name: fk_flexible_projects_project_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY flexible_projects
    ADD CONSTRAINT fk_flexible_projects_project_id FOREIGN KEY (project_id) REFERENCES projects(id);
--
-- Name: fk_payment_notifications_payment_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY payment_notifications
    ADD CONSTRAINT fk_payment_notifications_payment_id FOREIGN KEY (payment_id) REFERENCES payments(id);
--
-- Name: fk_payment_transfers_payment_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY payment_transfers
    ADD CONSTRAINT fk_payment_transfers_payment_id FOREIGN KEY (payment_id) REFERENCES payments(id);
--
-- Name: fk_payment_transfers_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY payment_transfers
    ADD CONSTRAINT fk_payment_transfers_user_id FOREIGN KEY (user_id) REFERENCES users(id);
--
-- Name: fk_payments_contribution_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY payments
    ADD CONSTRAINT fk_payments_contribution_id FOREIGN KEY (contribution_id) REFERENCES contributions(id);
--
-- Name: fk_project_accounts_bank_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_accounts
    ADD CONSTRAINT fk_project_accounts_bank_id FOREIGN KEY (bank_id) REFERENCES banks(id);
--
-- Name: fk_project_accounts_project_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_accounts
    ADD CONSTRAINT fk_project_accounts_project_id FOREIGN KEY (project_id) REFERENCES projects(id);
--
-- Name: fk_project_budgets_project_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_budgets
    ADD CONSTRAINT fk_project_budgets_project_id FOREIGN KEY (project_id) REFERENCES projects(id);
--
-- Name: fk_project_notifications_project_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_notifications
    ADD CONSTRAINT fk_project_notifications_project_id FOREIGN KEY (project_id) REFERENCES projects(id);
--
-- Name: fk_project_notifications_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_notifications
    ADD CONSTRAINT fk_project_notifications_user_id FOREIGN KEY (user_id) REFERENCES users(id);
--
-- Name: fk_project_post_notifications_project_post_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_post_notifications
    ADD CONSTRAINT fk_project_post_notifications_project_post_id FOREIGN KEY (project_post_id) REFERENCES project_posts(id);
--
-- Name: fk_project_post_notifications_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_post_notifications
    ADD CONSTRAINT fk_project_post_notifications_user_id FOREIGN KEY (user_id) REFERENCES users(id);
--
-- Name: fk_project_reminders_project_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_reminders
    ADD CONSTRAINT fk_project_reminders_project_id FOREIGN KEY (project_id) REFERENCES projects(id);
--
-- Name: fk_project_reminders_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_reminders
    ADD CONSTRAINT fk_project_reminders_user_id FOREIGN KEY (user_id) REFERENCES users(id);
--
-- Name: fk_project_transitions_project_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_transitions
    ADD CONSTRAINT fk_project_transitions_project_id FOREIGN KEY (project_id) REFERENCES projects(id);
--
-- Name: fk_projects_city_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT fk_projects_city_id FOREIGN KEY (city_id) REFERENCES cities(id);
--
-- Name: fk_projects_origin_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT fk_projects_origin_id FOREIGN KEY (origin_id) REFERENCES origins(id);
--
-- Name: fk_redactor_assets_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY redactor_assets
    ADD CONSTRAINT fk_redactor_assets_user_id FOREIGN KEY (user_id) REFERENCES users(id);
--
-- Name: fk_taggings_project_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY taggings
    ADD CONSTRAINT fk_taggings_project_id FOREIGN KEY (project_id) REFERENCES projects(id);
--
-- Name: fk_taggings_tag_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY taggings
    ADD CONSTRAINT fk_taggings_tag_id FOREIGN KEY (tag_id) REFERENCES tags(id);
--
-- Name: fk_user_links_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_links
    ADD CONSTRAINT fk_user_links_user_id FOREIGN KEY (user_id) REFERENCES users(id);
--
-- Name: fk_user_notifications_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_notifications
    ADD CONSTRAINT fk_user_notifications_user_id FOREIGN KEY (user_id) REFERENCES users(id);
--
-- Name: fk_user_transfer_notifications_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_transfer_notifications
    ADD CONSTRAINT fk_user_transfer_notifications_user_id FOREIGN KEY (user_id) REFERENCES users(id);
--
-- Name: fk_user_transfer_notifications_user_transfer_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_transfer_notifications
    ADD CONSTRAINT fk_user_transfer_notifications_user_transfer_id FOREIGN KEY (user_transfer_id) REFERENCES user_transfers(id);
--
-- Name: fk_user_transfers_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_transfers
    ADD CONSTRAINT fk_user_transfers_user_id FOREIGN KEY (user_id) REFERENCES users(id);
--
-- Name: fk_users_channel_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk_users_channel_id FOREIGN KEY (channel_id) REFERENCES channels(id);
--
-- Name: fk_users_country_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk_users_country_id FOREIGN KEY (country_id) REFERENCES countries(id);
--
-- Name: flexible_projects_state_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY flexible_projects
    ADD CONSTRAINT flexible_projects_state_fkey FOREIGN KEY (state) REFERENCES flexible_project_states(state);
--
-- Name: payment_notifications_backer_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY payment_notifications
    ADD CONSTRAINT payment_notifications_backer_id_fk FOREIGN KEY (contribution_id) REFERENCES contributions(id);
--
-- Name: projects_category_id_reference; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_category_id_reference FOREIGN KEY (category_id) REFERENCES categories(id);
--
-- Name: projects_state_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_state_fkey FOREIGN KEY (state) REFERENCES project_states(state);
--
-- Name: projects_user_id_reference; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_user_id_reference FOREIGN KEY (user_id) REFERENCES users(id);
--
-- Name: rewards_project_id_reference; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY rewards
    ADD CONSTRAINT rewards_project_id_reference FOREIGN KEY (project_id) REFERENCES projects(id);
--
-- Name: unsubscribes_project_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY unsubscribes
    ADD CONSTRAINT unsubscribes_project_id_fk FOREIGN KEY (project_id) REFERENCES projects(id);
--
-- Name: unsubscribes_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY unsubscribes
    ADD CONSTRAINT unsubscribes_user_id_fk FOREIGN KEY (user_id) REFERENCES users(id);
--
-- Name: updates_project_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_posts
    ADD CONSTRAINT updates_project_id_fk FOREIGN KEY (project_id) REFERENCES projects(id);
--
-- Name: updates_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_posts
    ADD CONSTRAINT updates_user_id_fk FOREIGN KEY (user_id) REFERENCES users(id);
--
-- Name: 1; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA "1" FROM PUBLIC;
GRANT ALL ON SCHEMA "1" TO catarse;
GRANT USAGE ON SCHEMA "1" TO admin;
GRANT USAGE ON SCHEMA "1" TO web_user;
GRANT USAGE ON SCHEMA "1" TO anonymous;
--
-- Name: public; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO catarse;
GRANT ALL ON SCHEMA public TO PUBLIC;
--
-- Name: projects; Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON TABLE projects FROM PUBLIC;
GRANT ALL ON TABLE projects TO catarse;
GRANT SELECT ON TABLE projects TO web_user;
GRANT SELECT ON TABLE projects TO admin;
GRANT SELECT ON TABLE projects TO PUBLIC;
--
-- Name: flexible_projects; Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON TABLE flexible_projects FROM PUBLIC;
GRANT ALL ON TABLE flexible_projects TO catarse;
GRANT SELECT ON TABLE flexible_projects TO admin;
GRANT SELECT ON TABLE flexible_projects TO web_user;
GRANT SELECT ON TABLE flexible_projects TO anonymous;
GRANT SELECT ON TABLE flexible_projects TO PUBLIC;
--
-- Name: project_accounts; Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON TABLE project_accounts FROM PUBLIC;
GRANT SELECT ON TABLE project_accounts TO anonymous;
GRANT SELECT ON TABLE project_accounts TO web_user;
GRANT SELECT ON TABLE project_accounts TO admin;
--
-- Name: users; Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON TABLE users FROM PUBLIC;
GRANT ALL ON TABLE users TO catarse;
GRANT SELECT ON TABLE users TO admin;
--
-- Name: users.deactivated_at; Type: ACL; Schema: public; Owner: -
--

REVOKE ALL(deactivated_at) ON TABLE users FROM PUBLIC;

GRANT UPDATE(deactivated_at) ON TABLE users TO admin;
SET search_path = "1", pg_catalog;

--
-- Name: projects; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE projects FROM PUBLIC;
REVOKE ALL ON TABLE projects FROM catarse;
GRANT ALL ON TABLE projects TO catarse;
GRANT SELECT ON TABLE projects TO anonymous;
GRANT SELECT ON TABLE projects TO web_user;
GRANT SELECT ON TABLE projects TO admin;
SET search_path = public, pg_catalog;

--
-- Name: payments; Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON TABLE payments FROM PUBLIC;
GRANT ALL ON TABLE payments TO catarse;
GRANT SELECT ON TABLE payments TO admin;
--
-- Name: project_reminders; Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON TABLE project_reminders FROM PUBLIC;
GRANT ALL ON TABLE project_reminders TO catarse;
GRANT SELECT,INSERT,DELETE ON TABLE project_reminders TO web_user;
GRANT SELECT,INSERT,DELETE ON TABLE project_reminders TO admin;
SET search_path = "1", pg_catalog;

--
-- Name: categories; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE categories FROM PUBLIC;
REVOKE ALL ON TABLE categories FROM catarse;
GRANT ALL ON TABLE categories TO catarse;
GRANT SELECT ON TABLE categories TO admin;
GRANT SELECT ON TABLE categories TO web_user;
GRANT SELECT ON TABLE categories TO anonymous;
SET search_path = public, pg_catalog;

--
-- Name: category_followers; Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON TABLE category_followers FROM PUBLIC;
GRANT SELECT,INSERT,DELETE ON TABLE category_followers TO admin;
GRANT SELECT,INSERT,DELETE ON TABLE category_followers TO web_user;
SET search_path = "1", pg_catalog;

--
-- Name: category_followers; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE category_followers FROM PUBLIC;
GRANT ALL ON TABLE category_followers TO catarse;
GRANT SELECT,INSERT,DELETE ON TABLE category_followers TO admin;
GRANT SELECT,INSERT,DELETE ON TABLE category_followers TO web_user;
--
-- Name: category_totals; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE category_totals FROM PUBLIC;
GRANT ALL ON TABLE category_totals TO catarse;
GRANT SELECT ON TABLE category_totals TO admin;
--
-- Name: contribution_details; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE contribution_details FROM PUBLIC;
GRANT ALL ON TABLE contribution_details TO catarse;
GRANT SELECT,UPDATE ON TABLE contribution_details TO admin;
--
-- Name: contribution_reports; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE contribution_reports FROM PUBLIC;
GRANT ALL ON TABLE contribution_reports TO catarse;
GRANT SELECT ON TABLE contribution_reports TO admin;
GRANT SELECT ON TABLE contribution_reports TO web_user;
SET search_path = public, pg_catalog;

--
-- Name: settings; Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON TABLE settings FROM PUBLIC;
GRANT ALL ON TABLE settings TO catarse;
GRANT SELECT ON TABLE settings TO admin;
SET search_path = "1", pg_catalog;

--
-- Name: contribution_reports_for_project_owners; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE contribution_reports_for_project_owners FROM PUBLIC;
GRANT ALL ON TABLE contribution_reports_for_project_owners TO catarse;
GRANT SELECT ON TABLE contribution_reports_for_project_owners TO admin;
--
-- Name: contributions; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE contributions FROM PUBLIC;
GRANT ALL ON TABLE contributions TO catarse;
GRANT ALL ON TABLE contributions TO admin;
--
-- Name: financial_reports; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE financial_reports FROM PUBLIC;
GRANT ALL ON TABLE financial_reports TO catarse;
GRANT SELECT ON TABLE financial_reports TO admin;
GRANT SELECT ON TABLE financial_reports TO web_user;
SET search_path = public, pg_catalog;

--
-- Name: project_notifications; Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON TABLE project_notifications FROM PUBLIC;
GRANT ALL ON TABLE project_notifications TO catarse;
GRANT SELECT,INSERT,DELETE ON TABLE project_notifications TO web_user;
GRANT SELECT,INSERT,DELETE ON TABLE project_notifications TO admin;
SET search_path = "1", pg_catalog;

--
-- Name: notifications; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE notifications FROM PUBLIC;
REVOKE ALL ON TABLE notifications FROM catarse;
GRANT ALL ON TABLE notifications TO catarse;
GRANT SELECT ON TABLE notifications TO admin;
--
-- Name: user_totals; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE user_totals FROM PUBLIC;
GRANT ALL ON TABLE user_totals TO catarse;
GRANT SELECT ON TABLE user_totals TO anonymous;
GRANT SELECT ON TABLE user_totals TO admin;
GRANT SELECT ON TABLE user_totals TO web_user;
--
-- Name: project_contributions; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE project_contributions FROM PUBLIC;
GRANT ALL ON TABLE project_contributions TO catarse;
GRANT SELECT ON TABLE project_contributions TO anonymous;
GRANT SELECT ON TABLE project_contributions TO web_user;
GRANT SELECT ON TABLE project_contributions TO admin;
--
-- Name: project_contributions_per_day; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE project_contributions_per_day FROM PUBLIC;
GRANT ALL ON TABLE project_contributions_per_day TO catarse;
GRANT SELECT ON TABLE project_contributions_per_day TO anonymous;
GRANT SELECT ON TABLE project_contributions_per_day TO web_user;
GRANT SELECT ON TABLE project_contributions_per_day TO admin;
--
-- Name: project_contributions_per_location; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE project_contributions_per_location FROM PUBLIC;
GRANT ALL ON TABLE project_contributions_per_location TO catarse;
GRANT SELECT ON TABLE project_contributions_per_location TO anonymous;
GRANT SELECT ON TABLE project_contributions_per_location TO web_user;
GRANT SELECT ON TABLE project_contributions_per_location TO admin;
--
-- Name: project_contributions_per_ref; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE project_contributions_per_ref FROM PUBLIC;
GRANT ALL ON TABLE project_contributions_per_ref TO catarse;
GRANT SELECT ON TABLE project_contributions_per_ref TO admin;
GRANT SELECT ON TABLE project_contributions_per_ref TO web_user;
GRANT SELECT ON TABLE project_contributions_per_ref TO anonymous;
--
-- Name: project_details; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE project_details FROM PUBLIC;
GRANT ALL ON TABLE project_details TO catarse;
GRANT SELECT ON TABLE project_details TO admin;
GRANT SELECT ON TABLE project_details TO web_user;
GRANT SELECT ON TABLE project_details TO anonymous;
--
-- Name: project_financials; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE project_financials FROM PUBLIC;
GRANT ALL ON TABLE project_financials TO catarse;
GRANT SELECT ON TABLE project_financials TO web_user;
GRANT SELECT ON TABLE project_financials TO admin;
--
-- Name: project_posts_details; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE project_posts_details FROM PUBLIC;
GRANT ALL ON TABLE project_posts_details TO catarse;
GRANT SELECT ON TABLE project_posts_details TO admin;
GRANT SELECT ON TABLE project_posts_details TO web_user;
GRANT SELECT ON TABLE project_posts_details TO anonymous;
--
-- Name: project_reminders; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE project_reminders FROM PUBLIC;
GRANT ALL ON TABLE project_reminders TO catarse;
GRANT SELECT,INSERT,DELETE ON TABLE project_reminders TO web_user;
GRANT SELECT,INSERT,DELETE ON TABLE project_reminders TO admin;
--
-- Name: project_transfers; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE project_transfers FROM PUBLIC;
REVOKE ALL ON TABLE project_transfers FROM catarse;
GRANT ALL ON TABLE project_transfers TO catarse;
GRANT SELECT,UPDATE ON TABLE project_transfers TO admin;
--
-- Name: project_transitions; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE project_transitions FROM PUBLIC;
REVOKE ALL ON TABLE project_transitions FROM catarse;
GRANT ALL ON TABLE project_transitions TO catarse;
GRANT SELECT ON TABLE project_transitions TO admin;
--
-- Name: recommendations; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE recommendations FROM PUBLIC;
GRANT ALL ON TABLE recommendations TO catarse;
GRANT SELECT ON TABLE recommendations TO admin;
GRANT SELECT ON TABLE recommendations TO web_user;
--
-- Name: referral_totals; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE referral_totals FROM PUBLIC;
GRANT ALL ON TABLE referral_totals TO catarse;
GRANT SELECT ON TABLE referral_totals TO admin;
--
-- Name: reward_details; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE reward_details FROM PUBLIC;
GRANT ALL ON TABLE reward_details TO catarse;
GRANT SELECT ON TABLE reward_details TO admin;
GRANT SELECT ON TABLE reward_details TO web_user;
GRANT SELECT ON TABLE reward_details TO anonymous;
--
-- Name: statistics; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE statistics FROM PUBLIC;
GRANT ALL ON TABLE statistics TO catarse;
GRANT SELECT ON TABLE statistics TO admin;
GRANT SELECT ON TABLE statistics TO web_user;
GRANT SELECT ON TABLE statistics TO anonymous;
--
-- Name: team_members; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE team_members FROM PUBLIC;
GRANT ALL ON TABLE team_members TO catarse;
GRANT SELECT ON TABLE team_members TO web_user;
GRANT SELECT ON TABLE team_members TO admin;
GRANT SELECT ON TABLE team_members TO anonymous;
--
-- Name: team_totals; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE team_totals FROM PUBLIC;
GRANT ALL ON TABLE team_totals TO catarse;
GRANT SELECT ON TABLE team_totals TO admin;
GRANT SELECT ON TABLE team_totals TO web_user;
GRANT SELECT ON TABLE team_totals TO anonymous;
--
-- Name: user_credits; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE user_credits FROM PUBLIC;
GRANT ALL ON TABLE user_credits TO catarse;
GRANT SELECT ON TABLE user_credits TO admin;
GRANT SELECT ON TABLE user_credits TO web_user;
--
-- Name: user_details; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE user_details FROM PUBLIC;
GRANT ALL ON TABLE user_details TO catarse;
GRANT SELECT ON TABLE user_details TO PUBLIC;
--
-- Name: users; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE users FROM PUBLIC;
GRANT ALL ON TABLE users TO catarse;
GRANT SELECT ON TABLE users TO admin;
--
-- Name: users.deactivated_at; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL(deactivated_at) ON TABLE users FROM PUBLIC;

GRANT UPDATE(deactivated_at) ON TABLE users TO admin;
--
-- Name: year_totals; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE year_totals FROM PUBLIC;
GRANT ALL ON TABLE year_totals TO catarse;
GRANT SELECT ON TABLE year_totals TO admin;
GRANT SELECT ON TABLE year_totals TO web_user;
SET search_path = public, pg_catalog;

--
-- Name: category_followers_id_seq; Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON SEQUENCE category_followers_id_seq FROM PUBLIC;
GRANT USAGE ON SEQUENCE category_followers_id_seq TO admin;
GRANT USAGE ON SEQUENCE category_followers_id_seq TO web_user;
--
-- Name: flexible_project_states; Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON TABLE flexible_project_states FROM PUBLIC;
GRANT ALL ON TABLE flexible_project_states TO catarse;
GRANT SELECT ON TABLE flexible_project_states TO admin;
GRANT SELECT ON TABLE flexible_project_states TO web_user;
GRANT SELECT ON TABLE flexible_project_states TO anonymous;
--
-- Name: payment_logs; Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON TABLE payment_logs FROM PUBLIC;
GRANT ALL ON TABLE payment_logs TO catarse;
GRANT SELECT ON TABLE payment_logs TO admin;
GRANT SELECT ON TABLE payment_logs TO web_user;
--
-- Name: payment_transfers; Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON TABLE payment_transfers FROM PUBLIC;
GRANT ALL ON TABLE payment_transfers TO catarse;
GRANT SELECT ON TABLE payment_transfers TO admin;
GRANT SELECT ON TABLE payment_transfers TO web_user;
--
-- Name: project_notifications_id_seq; Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON SEQUENCE project_notifications_id_seq FROM PUBLIC;
GRANT ALL ON SEQUENCE project_notifications_id_seq TO catarse;
GRANT USAGE ON SEQUENCE project_notifications_id_seq TO admin;
GRANT USAGE ON SEQUENCE project_notifications_id_seq TO web_user;
--
-- Name: project_reminders_id_seq; Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON SEQUENCE project_reminders_id_seq FROM PUBLIC;
GRANT ALL ON SEQUENCE project_reminders_id_seq TO catarse;
GRANT USAGE ON SEQUENCE project_reminders_id_seq TO web_user;
GRANT USAGE ON SEQUENCE project_reminders_id_seq TO admin;
--
-- Name: project_states; Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON TABLE project_states FROM PUBLIC;
GRANT ALL ON TABLE project_states TO catarse;
GRANT SELECT ON TABLE project_states TO admin;
GRANT SELECT ON TABLE project_states TO web_user;
GRANT SELECT ON TABLE project_states TO anonymous;
--
-- PostgreSQL database dump complete
--

