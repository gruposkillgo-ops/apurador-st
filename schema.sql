-- =====================================================================
-- Apurador ICMS-ST — banco de dados (Supabase / PostgreSQL)
-- Cole TODO este arquivo em: Supabase → SQL Editor → New query → Run.
-- Pode ser executado de novo sem perder dados.
-- =====================================================================

-- 1) Usuários do sistema e papel de cada um --------------------------------
create table if not exists public.membros (
  user_id   uuid primary key references auth.users(id) on delete cascade,
  email     text,
  nome      text,
  papel     text not null default 'operador' check (papel in ('admin','operador')),
  criado_em timestamptz not null default now()
);

-- 2) Dados do sistema (config, regras, notas, guias) -----------------------
create table if not exists public.docs (
  colecao        text not null check (colecao in ('config','regras','notas','guias')),
  id             text not null,
  data           jsonb not null,
  atualizado_em  timestamptz not null default now(),
  atualizado_por uuid default auth.uid(),
  primary key (colecao, id)
);
alter table public.docs replica identity full;

-- 3) Funções de permissão --------------------------------------------------
create or replace function public.is_membro() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.membros where user_id = auth.uid());
$$;
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.membros where user_id = auth.uid() and papel = 'admin');
$$;

-- 4) Todo usuário criado em Authentication vira "operador" automaticamente --
create or replace function public.novo_membro() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.membros (user_id, email) values (new.id, new.email)
  on conflict (user_id) do nothing;
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.novo_membro();

-- quem já existia antes deste script também vira membro
insert into public.membros (user_id, email)
  select id, email from auth.users on conflict (user_id) do nothing;

-- 5) Carimbo de quem alterou e quando ---------------------------------------
create or replace function public.carimbo_docs() returns trigger
language plpgsql as $$
begin
  new.atualizado_em := now();
  new.atualizado_por := auth.uid();
  return new;
end $$;
drop trigger if exists docs_carimbo on public.docs;
create trigger docs_carimbo before insert or update on public.docs
  for each row execute function public.carimbo_docs();

-- 6) Regras de acesso (RLS) ------------------------------------------------
alter table public.membros enable row level security;
alter table public.docs    enable row level security;

drop policy if exists membros_ler     on public.membros;
drop policy if exists membros_admin   on public.membros;
create policy membros_ler   on public.membros for select using (user_id = auth.uid() or public.is_admin());
create policy membros_admin on public.membros for update using (public.is_admin()) with check (public.is_admin());

drop policy if exists docs_ler      on public.docs;
drop policy if exists docs_inserir  on public.docs;
drop policy if exists docs_alterar  on public.docs;
drop policy if exists docs_excluir  on public.docs;
-- todos os membros leem tudo
create policy docs_ler     on public.docs for select using (public.is_membro());
-- operadores gravam notas e guias; só admin grava regras e config
create policy docs_inserir on public.docs for insert
  with check (public.is_membro() and (colecao in ('notas','guias') or public.is_admin()));
create policy docs_alterar on public.docs for update
  using      (public.is_membro() and (colecao in ('notas','guias') or public.is_admin()))
  with check (public.is_membro() and (colecao in ('notas','guias') or public.is_admin()));
create policy docs_excluir on public.docs for delete
  using      (public.is_membro() and (colecao in ('notas','guias') or public.is_admin()));

grant select, insert, update, delete on public.docs to authenticated;
grant select, update on public.membros to authenticated;

-- 7) Atualização em tempo real entre usuários -------------------------------
do $$ begin
  alter publication supabase_realtime add table public.docs;
exception when duplicate_object then null; when undefined_object then null; end $$;

-- 8) Dados iniciais da Xingu ------------------------------------------------
insert into public.docs (colecao, id, data) values
  ('config', 'empresa', '{"cep": "78643000", "cnpj": "21174220000292", "codMunSefaz": "208000", "conv5291ok": "84339090", "diaVenc": 9, "endereco": "AV SUL, 424 QUADRA 13 LOTE 18 - SETOR H", "fcpSeparado": true, "filiais": "21174220000101=10006;21174220000292=208000;21174220000373=75000;21174220000454=89001", "fone": "6635291002", "freteNaBase": true, "ie": "135831695", "ipiNaBase": true, "municipio": "QUERÊNCIA", "portalLocal": "https://www.sefaz.mt.gov.br", "razao": "XINGU MAQUINAS AGRICOLAS LTDA", "receitaFCP": "100129", "receitaLocal": "2817", "receitaLocalFCP": "", "receitaST": "100048", "regimeMVA": "nao_optante", "tipoDoc": "10", "uf": "MT", "vencRegra": "hoje", "responsavel": "Grupo Skill"}'::jsonb),
  ('regras', 'mt-84339090-0104501', '{"ajustar": false, "aliqInterna": 17, "cest": "0104501", "descricao": "Partes de máquinas agrícolas (colheitadeira/plataforma)", "fcp": 0, "fonte": "Portaria SEFAZ-MT 195/2019, art. 2º-B, I (autopeças, não optante): 65,29% | Anexo Único, Tabela I, item 45.1 (CEST 01.045.01, NCM 8433.90.90) | art. 3º, p.ú. (sem MVA ajustada) | RICMS/MT Anexo V, art. 25, II, b (base 32,95%)", "mva": 65.29, "ncm": "84339090", "reducao": 67.05, "uf": "MT", "validada": true}'::jsonb)
on conflict (colecao, id) do nothing;

-- 9) PRIMEIRO ADMIN — depois de criar seu usuário em Authentication → Users,
--    rode só esta linha (troque o e-mail se for outro):
-- update public.membros set papel = 'admin' where email = 'leonardo.paulista@gruposkill.com.br';
