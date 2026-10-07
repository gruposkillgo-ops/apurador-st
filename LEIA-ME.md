# Apurador ICMS-ST — como colocar o site no ar

São dois serviços gratuitos:
- **Supabase** guarda os dados (notas, guias, regras) e faz o login.
- **GitHub Pages** hospeda o site e gera o endereço.

Tempo total: uns 20 minutos, feito uma vez só.

---

## Parte 1 — Supabase (banco de dados e login)

1. Entre em **supabase.com** → *Start your project* e crie a conta.
2. Clique em **New project**:
   - Name: `apurador-st`
   - Database password: crie uma senha forte e **guarde**.
   - Region: **South America (São Paulo)**
   - Clique em *Create new project* e espere uns 2 minutos.
3. No menu lateral, abra **SQL Editor** → *New query*. Abra o arquivo `supabase/schema.sql` deste pacote, copie **tudo**, cole e clique em **Run**. Deve aparecer "Success".
4. **Authentication → Sign In / Providers**: desligue **"Allow new users to sign up"**. Só entra quem vocês cadastrarem.
5. **Authentication → Users → Add user → Create new user**: coloque o seu e-mail e uma senha e marque **Auto Confirm User**.
6. Volte ao **SQL Editor** e rode esta linha para virar administrador:
   ```sql
   update public.membros set papel = 'admin' where email = 'leonardo.paulista@gruposkill.com.br';
   ```
7. **Project Settings → API** (ou *Data API*): copie a **Project URL** e a chave **anon public**. Elas vão no passo 3 da Parte 2.

## Parte 2 — GitHub Pages (o site)

1. Entre em **github.com** e crie a conta, se não tiver.
2. Clique em **New repository**:
   - Repository name: `apurador-st`
   - Marque **Public**. No plano gratuito, o GitHub Pages só funciona com repositório público. O código fica visível, mas **os dados não**: eles ficam no Supabase, protegidos por login.
   - Clique em *Create repository*.
3. Na página do repositório, clique em **uploading an existing file** e arraste **todos os arquivos desta pasta**: `index.html`, `config.js`, `base-legal-mt.json` e a pasta `supabase`. Clique em **Commit changes**.
4. Abra o arquivo **config.js** no GitHub e clique no lápis (editar). Troque os dois `COLE_AQUI...` pela Project URL e pela chave anon public da Parte 1, passo 7. Clique em **Commit changes**.
5. **Settings → Pages**. Em *Build and deployment*, deixe Source = **Deploy from a branch**, Branch = **main**, pasta **/ (root)**, e clique em **Save**.
6. Em 1 a 2 minutos o site fica no ar em:
   **https://SEU-USUARIO.github.io/apurador-st/**
7. Volte ao Supabase, em **Authentication → URL Configuration**. Em **Site URL**, cole o endereço do site. Isso faz o link de "Esqueci minha senha" funcionar.

## Parte 3 — Usuários

- **Incluir alguém:** Supabase → Authentication → Users → *Add user* (e-mail, senha, *Auto Confirm User*). Passe o e-mail e a senha para a pessoa. Ela entra no site e pode trocar a senha em "Esqueci minha senha".
- Toda pessoa nova entra como **operador**: importa notas, calcula, registra DAR e baixa o PDF.
- Para dar **administrador** (edita regras fiscais e dados da empresa): no site, vá em **Empresa → Usuários** e troque o papel.
- **Remover alguém:** Supabase → Authentication → Users → apagar o usuário.

## Parte 4 — Trazer os dados que já existem

1. No sistema atual (dentro do Claude), abra **Empresa → Exportar backup**.
2. No site novo, entre como administrador, abra **Empresa → Importar backup** e escolha o arquivo.

## Atualizações

Quando houver uma versão nova, é só substituir o `index.html` (e o `base-legal-mt.json`, se mudar) no GitHub, com *Add file → Upload files*. O `config.js` e os dados continuam os mesmos.
