# tracebloc terminology

**The single source of truth for the words we use** — in the product UI, docs, website, decks, CLI, and support. One concept, one word.

> **This file is authoritative.** All copy defers here — including the `communication`, `persona`, and `founder-voice` skills, which **reference** this file and must not redefine terms. If a term isn't here, add it here first.
>
> **Status: working draft — started 2026-07-11, being aligned over the coming days.** Rows marked ✅ are decided; rows marked **🔵 OPEN** await a team decision (see Open questions at the bottom).
>
> **We align the vocabulary here first.** The "words to retire" section lists the drift terms currently live in the code/UI, recorded from a full cross-repo sweep **for awareness — not as a signal to start renaming.** No code or UI renames happen until the open questions are settled (especially #1 — what we call the on-prem environment). This file leads; the codebase follows later.

## How to use it

- Use the **Preferred** term. Avoid everything in **Don't use**.
- One concept = one word. If two words mean the same thing, pick one and retire the other.
- Applies everywhere customer- or team-facing: docs, app UI, website, decks, CLI copy, support replies, and code-facing copy (comments, log lines).

## 1. Core product terms

| Concept | Preferred | Don't use | Status | Definition |
|---|---|---|---|---|
| The software you run on your infra (+ what it gives you) | **secure environment** / **environment** *(leaning)* | edge device, agent, box, node, cluster, instance, deployment, site | 🔵 **OPEN** | Three candidates: **environment / secure environment** — now favored (the marketing hero uses "Your own secure environment" / "Deploy Your Environment"); **workspace** — the 2026-06-05 pick; **client** — the established federated-learning term collaborators know. ⚠️ "environment" leading *reverses* the earlier workspace decision **and** the prior soft-ban on "environment" — confirm with the team. This is the load-bearing decision (drives the biggest rename). |
| The credential connecting it to the platform | **Client ID** | client key, token, API key | ✅ | Created on the clients page; identifies your workspace. "client" as a bare noun survives **only** here. |
| The hosted tracebloc service | **the platform** | the cloud, the server, the backend, SaaS | ✅ | The hosted side (ai.tracebloc.io) collaborators connect through. |
| The web app you log into | **the dashboard** (at ai.tracebloc.io) | portal, console, "the platform" (for the UI), **Hub** | 🔵 **OPEN** | The browser UI. Brand called this the **Hub** — keep "dashboard" or adopt "Hub"? Pair once: dashboard = ai.tracebloc.io, docs = docs.tracebloc.io. |
| The user's own servers / laptop | **your infrastructure** | your box, on-prem (as a noun) | ✅ | The **hardware** tracebloc runs on. Distinct from the **(secure) environment** above, which is the tracebloc software/runtime it gives you — don't conflate the two. |
| The user's data | **dataset** | data source, "data set" (two words), "client dataset" | ✅ | Training & test data ingested and staged locally. (It's "your dataset" — never "client data set".) |
| Bringing data in | **ingest** | upload, import, load, **push**, send, transfer | ✅ | Copying a dataset into your workspace's storage. Raw data never leaves your infrastructure. |
| Removing a dataset | **delete** | rm, drop, teardown | ✅ | Say "removes the dataset from your workspace (the record is kept)"; keep table/PVC detail behind `--verbose`. |
| Connection status | **Online / Offline** | connected/disconnected, up/down | ✅ | Whether the workspace has an active secure connection. |

## 2. People

| Concept | Preferred | Don't use | Status | Definition |
|---|---|---|---|---|
| The people who build & train models on your data | **collaborators** | vendor, contributor, participant, expert, "the user" | ✅ | Invited, whitelisted data scientists who train models and never see the raw data. **(Decided 2026-07-11 — supersedes the seed's "contributor".)** |
| The person who deploys & owns the workspace | **workspace owner** | admin, host, customer, data owner, "the user" | 🔵 **OPEN** | Deploys the workspace, ingests data, creates use cases, controls sharing. (Esp. the UI "admin panel" — decide.) |

## 3. The ML problem type: **task**

Say **task** on every user surface. The wire/spec field is `category` — internal only. **Don't use** (user-facing): category, task category, "task categories", task_type, use_case (as the type).

### Task taxonomy — canonical display names + glosses (16 tasks)

| task_id (internal) | Display name (user-facing) | Gloss |
|---|---|---|
| image_classification | Image classification | sort images into classes |
| object_detection | Object detection | draw boxes around objects |
| keypoint_detection | Keypoint detection | locate landmark points (e.g. pose) |
| semantic_segmentation | Semantic segmentation | label every pixel |
| text_classification | Text classification | sort text into classes |
| masked_language_modeling | Masked language modeling (fill-mask) | predict masked-out words (no labels) |
| token_classification | Token classification | label each word in a sequence |
| sentence_pair_classification | Sentence-pair classification | label how two texts relate |
| causal_language_modeling | Causal language modeling | predict the next word |
| seq2seq | Sequence-to-sequence (translation / summarization) | map input sequence → output |
| embeddings | Embeddings | learn vector representations from text pairs |
| tabular_classification | Tabular classification | predict a class from table columns |
| tabular_regression | Tabular regression | predict a number from table columns |
| time_series_forecasting | Time-series forecasting | predict future values from past |
| time_series_classification | Time-series classification | predict a class per whole sequence |
| time_to_event_prediction | Survival analysis | predict how long until an event |

### Per-task data layout & label/target column

How the user lays out each task's data, and what the label/target column is actually **called** (from the di#347 layout contract + the ingestor modality specs + shipped template CSVs). `⇥` = tab.

| Task | Input layout | Sidecars | Label / target column | Supervision |
|---|---|---|---|---|
| Image classification | folder `images/` + CSV (`filename,label`) | — | `label` | labeled |
| Object detection | `images/` + CSV (`filename,image_label`) + `annotations/*.xml` | Pascal-VOC XML, paired by filename stem | boxes+class in the **XML**; CSV `image_label` is coarse | labeled |
| Keypoint detection | `images/` + CSV (`filename,Annotation,Visibility,image_label`) | — | class `image_label`; coords in `Annotation` (JSON) | labeled |
| Semantic segmentation | `images/` + CSV (`filename,mask_id,image_label`) + `masks/*.png` | `masks/*.png` linked by **`mask_id`** | mask PNG via `mask_id`; class `image_label` | labeled |
| Text classification | folder `texts/` + CSV (`filename,extension,label`) | — | `label` | labeled |
| Masked language modeling | folder `sequences/` + CSV (`filename,extension`) | — | **none** | self-supervised |
| Token classification | `texts/` + CSV (`filename,extension,label`) | — | `label` (BIO/IOB2 tag sequence) | labeled |
| Sentence-pair classification | `texts/` (`text_a⇥text_b`) + CSV (`…,label`) | — | `label` | labeled |
| Causal language modeling | `texts/` (raw or `prompt⇥completion`) + CSV (`filename,extension`) | — | **none** | self-supervised |
| Seq2seq | `texts/` (`source⇥target`) + CSV (`filename,extension`) | — | **none** | self-supervised |
| Embeddings | `texts/` (`anchor⇥positive[⇥negative]`) + CSV (`filename,extension`) | — | **none** (contrastive) | self-supervised |
| Tabular classification | single CSV: id + features + `label` | — | `label` | labeled |
| Tabular regression | single CSV: id + features + numeric target | — | configurable numeric target — **no fixed word** (sample `price`); `label.policy=bucket` | labeled (regression) |
| Time-series forecasting | single CSV: `timestamp` + features + numeric target | — | configurable numeric target (sample `value`); time col `timestamp` | labeled (regression) |
| Time-series classification | single **grouped** CSV: `sequence_id,timestamp,…,label` | — | `label` (one per sequence); group `sequence_id`, time `timestamp` | labeled |
| Survival analysis (time-to-event) | single CSV: features + `time` + event indicator | — | duration col **`time`** (fixed) + event indicator = the label column (sample `DEATH_EVENT`) | labeled (survival) |

**Consistent, keep:** `filename` (every file-bearing task), optional `extension` (text tasks), `mask_id` (semseg link), `Annotation` (keypoint coords), `sequence_id`/`timestamp` (time-series grouping).

**🔵 Column-naming inconsistencies to decide (folded into Open Q#7):**
- **`label` vs `image_label`** — classification/text/tabular/TSC use `label`; the three vision tasks (object detection, keypoint, semseg) use `image_label`. Canonicalize on one, or document `label` (classification) vs `image_label` (vision image-level)?
- **`timestamp` vs `time`** — time-series uses `timestamp`; survival uses `time`. Same concept, two words.
- **Survival event indicator has no platform name** — it's just the configurable label column; `DEATH_EVENT` is only the shipped Heart-Failure sample. Docs must say "event indicator (the label column)" + the fixed `time` column — never present `DEATH_EVENT` as a tracebloc column.
- **`masked_language_modeling` stages from `sequences/`**, the other three self-supervised text tasks from `texts/` — spell this folder difference out.

## 4. Training

| Concept | Preferred | Don't use | Status | Definition |
|---|---|---|---|---|
| A collaborator's attempt within a use case | **experiment** | training run, training job, training plan | ✅ | The unit a collaborator runs against a use case. |
| The act of training a model | **training** (run a training) | — | ✅ | A training happens *inside* an experiment. |
| The Kubernetes/infra work object | **job** | — | ✅ | **Infra-internal only — never user-facing.** "job" = the K8s Job; don't use it in product/docs/CLI copy. |

## 5. Models

| Concept | Preferred | Don't use | Status | Definition |
|---|---|---|---|---|
| The ML model a collaborator trains | **model** | architecture | ✅ | — |
| A ready-made starter model/project | **template** | sample, demo | ✅ | model-zoo starters only. |
| The act of a collaborator adding their model | **submit a model** *or* **upload a model** | — | 🔵 **OPEN** | SDK method is `upload_model`. Is the verb "upload", "submit", or "contribute" a model? (Data is never "uploaded" — but a *model* legitimately goes to the platform.) |

## 6. Federated learning

| Concept | Preferred | Don't use | Status | Definition |
|---|---|---|---|---|
| Training across workspaces + combining weights | **federated training** ("build together") | distributed learning, FedAvg (in user copy) | ✅ | User-facing. |
| The infra that merges the weights | **averaging service** / **federated averaging** | — | ✅ | Internal component name. |

## 7. Positioning / brand terms (folded in from the communication skill)

| Concept | Preferred | Don't use | Status |
|---|---|---|---|
| Our category | **Collaborative AI** / "build AI together" | "AI collaboration platform", "secure AI" | ✅ |
| The results view | **Leaderboard** | dashboard, scoreboard | ✅ |
| Pricing / compute unit | **PetaFLOPs (PF)** | credits, tokens | ✅ |
| Our security story | **Compliance by architecture** | enterprise-grade security, **compliance by design** | ✅ |

## 8. CLI verb & flag vocabulary

| Surface | Preferred | Don't use |
|---|---|---|
| load data | `tracebloc data ingest <path>` | `dataset push`, upload |
| list datasets | `tracebloc data list` | — |
| remove a dataset | `tracebloc data delete <name>` | `dataset rm` |
| the task flag | `--task` | `--category` (hidden alias only) |
| the name flag | `--name` (rename delete's positional `<table>` → `<name>`) | `--table` (hidden alias only) |
| train/test flag | `--split (train\|test)` *(RFC-0002 — not yet implemented; today `--intent`)* | `--intent` (after migration) |

Command group is `data` (alias `dataset` one cycle). Keep cluster/namespace/PVC/"stage pod" jargon behind `--verbose`.

## 9. Component & code naming (engineering-internal)

**"client" today names five different things** — disambiguate 🔵:

| Thing | Today | Proposed |
|---|---|---|
| Helm chart that deploys the workspace | `client` repo | **workspace-chart** |
| Training-execution container images | `tracebloc-client` repo | keep; describe as "training images" |
| In-cluster pod orchestration | `client-runtime` repo | keep; "runtime" |
| The credential | Client ID | unchanged (the one legit "client") |
| CLI command group | `tracebloc client` | installer-internal, hidden |

- **Ingestor:** distribution **`tracebloc-ingestor`** (PyPI) / import **`tracebloc_ingestor`** — state both (fix data-ingestors/CLAUDE.md which claims the PyPI name is the underscore form).
- **SDK methods:** snake_case (`upload_model`, `link_model_dataset`); camelCase (`uploadModel`) forms are **deprecated aliases** — fix the model-zoo README quick-start.
- **Backend model:** `EdgeDevice`/`edge` = the workspace/client; `Competition`/`PrivateCompetition` = a **use case**. Biggest reality-vs-canon gap (rename = migration + API; own epic).

## 10. Casing & style

- **tracebloc** is always lowercase — including sentence-start and mid-sentence. Not "Tracebloc"/"TraceBloc" (except unavoidable title-case contexts).
- Avoid hype/corporate filler (revolutionary, cutting-edge, seamless, leverage, end-to-end, enterprise-grade, AI-powered, democratize, …) — full banned list in the `communication` skill, which references this file.

## 11. Words to retire (currently live in the code/UI — review targets)

- **competition / PrivateCompetition** → **use case** *(frontend ×782, backend `Competition` model + route)*
- **edge / edge device / EdgeDevice** → **workspace/client** *(frontend "edge" ×449, backend `EdgeDevice`)*
- **vendor** → **collaborators** *(client README, SDK README, frontend "Vendor Testing Platform" ×54, several docs pages)*
- **push / `dataset push`** → **ingest / `data ingest`** *(client README quick-install, docs cli.mdx)*
- **`dataset rm`** → **`data delete`** *(cli README)*
- **"data set" (two words) / "client dataset"** → **dataset** / "your dataset"
- **category** → **task** *(docs cli.mdx, "9 task categories")*
- **uploadModel()** → **upload_model()** *(model-zoo README)*
- **Tracebloc** (capitalized) → **tracebloc** *(docs key-terms.mdx, frontend alt text)*
- **admin / data owner** → **workspace owner** *(pending Q, docs + UI)*
- **"compliance by design"** → **Compliance by architecture** *(the website hero currently says "compliance by design" — fix it)*

## 12. Open questions (decide before enforcing)

1. **What we call the on-prem thing** — the load-bearing one. Candidates: **secure environment / environment** (*now leaning* — marketing hero: "Your own secure environment"), **workspace** (2026-06-05 pick), **client** (FL-standard). Reverses the earlier workspace decision + the prior "environment" ban — needs team sign-off before the rename.
2. **Hub vs the dashboard/platform** — one name for the web UI.
3. **The model verb** — submit / upload / contribute a model?
4. **workspace owner vs admin** — esp. the UI "admin panel".
5. **The `client` component overload** — rename the `client` repo, or only fix user-facing copy?
6. **Internal ML-type field** — keep `category` on the wire, or move to `task_type`? (User-facing is "task" either way.)
7. **Per-task column names** — (a) **`label` vs `image_label`** (classification/text/tabular/TSC vs the 3 vision tasks); (b) **`timestamp` vs `time`** (time-series vs survival). Unify each, or document the split? (The survival event indicator stays "the label column" — no fixed name; `time` and `mask_id` stay fixed.)
