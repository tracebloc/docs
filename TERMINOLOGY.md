# tracebloc terminology

The single source of truth for the words we use — in the product UI, docs, website, decks, and support. One concept, one word. The goal: every person and every page names things the same way.

> **Status: seed.** Lukas owns this file. Add terms as they come up; we run it against the team so we stay consistent. The **open questions** at the bottom need a decision before we hard-enforce them.
>
> ⚠️ **Sync note (2026-07-12):** the `communication` skill's "Terminology Bible" is a *second copy* of these terms and still says **workspace** / **contributors** (and explicitly "don't say environment"). The website and decks say **workspace** too. When the terms below change, those surfaces need a matching sweep — otherwise the two versions drift. See open question #1.

## How to use it

- Use the **Preferred** term. Avoid everything in **Don't use**.
- One concept = one word. If two words mean the same thing, we pick one and retire the other.
- Applies everywhere customer- or team-facing: docs, app UI, website, decks, support replies, and code-facing copy (comments, log lines).

## Core terms

| Concept | Preferred | Don't use | Definition |
|---|---|---|---|
| The software you run on your infra (and the environment it gives you) | **secure environment** | workspace, client (as a noun), agent, node, box, instance, deployment | tracebloc's software running on your own infrastructure — your private, dedicated AI environment, where you invite collaborators to train models on your data. |
| The credential that connects it to the platform | **Client ID** | client key, token, API key | Created on the clients page; identifies your secure environment to the platform. ("client" survives **only** here, matching the current UI.) |
| The command-line tool | **the tracebloc CLI** (the `tracebloc` / `tb` command) | the client, the binary, the agent | The command you run to manage your secure environment — ingest data, check status, diagnose. Runs on the same machine. |
| The hosted tracebloc service | **the platform** | the cloud, the server, the backend, SaaS | The hosted side (ai.tracebloc.io) that collaborators connect through. |
| The user's own servers / laptop | **your infrastructure** (the specific host: **this machine**) | your box, your environment, on-prem (as a noun) | The hardware the secure environment runs on — owned and controlled by the user. In CLI/installer copy the specific host is "this machine". |
| The person who deploys & owns it | **owner** / "you" | admin, host, customer, "the user" | The person who deploys the secure environment, ingests data, creates use cases, and controls what's shared. (Label still under review — see open question #2.) |
| The invited model builder | **collaborator** | contributor, vendor, participant, expert, "the user" | An invited, whitelisted data scientist who submits and trains models — and never sees the raw data. |
| The collaborative task | **use case** | project, challenge, competition | A task defined from your datasets that collaborators build models for. |
| The user's data | **dataset** | data source, "data set" (two words) | Training and test data ingested and staged locally. |
| Bringing data in | **ingest** | upload, import, load, push | Staging a dataset locally for use cases. (Raw data never leaves your infrastructure.) |
| Connection status | **Online / Offline** | connected/disconnected, up/down | Whether your secure environment has an active secure connection to the platform. |

## Words to retire

- **"workspace"** → **secure environment** (decision reversed 2026-07-12; see open question #1).
- **"contributor"** for model builders → **collaborator** (2026-07-12).
- **"box"** — casual and vague. Say **your infrastructure**.
- **"the cloud"** — implies the data leaves. Say **the platform** (hosted side) or **your infrastructure** (their side).
- **"upload your data" / "push"** — implies the data leaves. Say **ingest** / **stage**.
- **"vendor"** for model builders — say **collaborator**.
- **"Tracebloc"** capitalized mid-sentence — the brand is lowercase **tracebloc** (except at the start of a sentence or in titles).

## Open questions (decide before enforcing)

1. ✅ **environment term — RE-DECIDED 2026-07-12 (Lukas): use _secure environment_.** Supersedes the 2026-06-05 "workspace" decision. *workspace* → retired everywhere user-facing; *client* survives only in **Client ID**. **Propagation gap (do these next):** the `communication` skill's Terminology Bible (still says *workspace* + "don't say environment"), the website, and the decks all need a sweep to match. The app UI's "client" / "clients page" rename is also still pending.
2. **owner label** — workspace-owner / admin / data owner: what do we call the deploying person, especially in the UI? (Was "workspace owner"; needs a new label now that *workspace* is retired.)
3. ✅ **model builders — DECIDED 2026-07-12 (Lukas): use _collaborators_** (retiring *contributor*).
