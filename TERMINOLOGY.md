# tracebloc terminology

The single source of truth for the words we use — in the product UI, docs, website, decks, and support. One concept, one word. The goal: every person and every page names things the same way.

> **Status: seed.** Lukas owns this file. Add terms as they come up; we run it against the team so we stay consistent. The **open questions** at the bottom need a decision before we hard-enforce them.

## How to use it

- Use the **Preferred** term. Avoid everything in **Don't use**.
- One concept = one word. If two words mean the same thing, we pick one and retire the other.
- Applies everywhere customer- or team-facing: docs, app UI, website, decks, support replies, and code-facing copy (comments, log lines).

## Core terms

| Concept | Preferred | Don't use | Definition |
|---|---|---|---|
| Our software on the user's infra | **client** | agent, node, box, instance | tracebloc's software running on your own infrastructure — your private AI workspace, where you invite contributors to train models on your data. |
| The user's deployed environment | **workspace** | environment, deployment, "the install" | Your private, dedicated AI workspace on one machine (the client plus your data). |
| The hosted tracebloc service | **the platform** | the cloud, the server, the backend, SaaS | The hosted side (ai.tracebloc.io) that contributors connect through. |
| The user's own servers / laptop | **your infrastructure** | your box, your environment, on-prem (as a noun) | The hardware the workspace runs on — owned and controlled by the user. |
| The person who deploys & owns it | **workspace owner** | admin, host, customer, "the user" | The person who deploys the workspace, ingests data, creates use cases, and controls what's shared. |
| The invited model builder | **contributor** | vendor, participant, expert, "the user" | An invited, whitelisted data scientist who submits and trains models — and never sees the raw data. |
| The collaborative task | **use case** | project, challenge, competition | A task defined from your datasets that contributors build models for. |
| The user's data | **dataset** | data source, "data set" (two words) | Training and test data ingested and staged locally. |
| Bringing data in | **ingest** | upload, import, load | Staging a dataset locally for use cases. (Raw data never leaves your infrastructure.) |
| Connection status | **Online / Offline** | connected/disconnected, up/down | Whether the client has an active secure connection to the platform. |

## Words to retire

- **"box"** — casual and vague. Say **your infrastructure**.
- **"the cloud"** — implies the data leaves. Say **the platform** (hosted side) or **your infrastructure** (their side).
- **"upload your data"** — implies the data leaves. Say **ingest** / **stage**.
- **"vendor"** for model builders — say **contributor**.
- **"Tracebloc"** capitalized mid-sentence — the brand is lowercase **tracebloc** (except at the start of a sentence or in titles).

## Open questions (decide before enforcing)

1. **client vs. workspace** — the big one; we currently use both for "the thing on your infra." Options:
   - **(a)** *workspace* = the user-facing concept ("your private AI workspace"); *client* = the registered object on the platform (has a **Client ID**, shows **Online/Offline**). Framing: "you deploy your workspace; it connects as a client."
   - **(b)** Use *workspace* everywhere user-facing; keep *client* only in **Client ID**.
   - Pick one — docs and UI follow it.
2. **workspace owner vs. admin vs. data owner** — what do we call the deploying person, especially in the UI ("admin panel")?
3. **contributor vs. data scientist** — is *contributor* the term in both product and marketing?
