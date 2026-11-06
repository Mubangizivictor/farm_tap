# Optional: a self-hosted language model (Ollama)

**Not needed today.** The Farm Assistant answers from calculations without
any model (decision 0025). Add this only if you later want answers phrased
more freely. The model never makes the numbers; it only rewords the
calculated answer, and a reply with any new number is thrown away
(`shared/aiPrivacy.ts`).

## What it costs

- Software and model: free (Ollama is MIT; Qwen3 models are Apache-2.0).
- The server: you pay the hosting company monthly, not per question.
  - Small CPU server (4 vCPU, 8 GB RAM) with `qwen3:4b`: roughly USD 10–40 a
    month, about 5–20 seconds an answer.
  - A GPU server is much faster and much dearer (USD 150+ a month).
- Do **not** use `qwen2.5:3b` or `qwen2.5:72b`: their licence is not Apache.

## Set-up (about 30 minutes)

```bash
# On a Linux server with Docker
docker run -d --name ollama --restart unless-stopped -p 127.0.0.1:11434:11434 \
  -v ollama:/root/.ollama ollama/ollama:RELEASE   # pin a release tag from hub.docker.com/r/ollama/ollama
docker exec ollama ollama pull qwen3:4b
curl http://127.0.0.1:11434/api/generate -d '{"model":"qwen3:4b","prompt":"Say hello","stream":false}'
```

Keep port 11434 closed to the internet. Put an HTTPS reverse proxy (Caddy or
nginx) in front with a long random key in a header, and give that URL and key
only to Cloud Functions (AI Control Centre → APIs and keys, stored in
`platformSecrets`, never in the apps).

## Still to build when you decide to do this

1. A Cloud Function `aiAsk` that takes the question and the calculated answer
   from the app, checks the person is a member of the farm, sends
   `buildPrompt()` (names, tags, phones and places removed) to the server
   with a time limit, checks `inventedNumbers()`, and returns the reply or
   the calculated answer if anything fails.
2. Turn on "Use the language model" in the AI Control Centre.

Ask before deploying: it changes production (project rule 7).
