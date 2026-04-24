# ClosetGenius Backend — GCP Cloud Run Deployment

## Prerequisites
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) (`gcloud`)
- Docker Desktop running locally
- A GCP billing account

---

## 1. One-time GCP setup

```bash
# Install gcloud if you haven't already, then:
gcloud auth login
gcloud projects create closetgenius-backend --name="ClosetGenius Backend"
gcloud config set project closetgenius-backend

# Enable billing — do this in the GCP Console:
# https://console.cloud.google.com/billing/linkedaccount?project=closetgenius-backend

# Enable required APIs
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  secretmanager.googleapis.com
```

## 2. Store the Groq API key in Secret Manager

```bash
echo -n "YOUR_GROQ_API_KEY" | \
  gcloud secrets create GROQ_API_KEY --data-file=- --project=closetgenius-backend
```

## 3. Build and push the Docker image

```bash
# Create Artifact Registry repo
gcloud artifacts repositories create closetgenius \
  --repository-format=docker \
  --location=us-central1

# Authenticate Docker to GCP
gcloud auth configure-docker us-central1-docker.pkg.dev

# Build and push (from the backend/ folder)
cd /Users/biancagambino/Desktop/ClosetGenius/backend

docker build -t us-central1-docker.pkg.dev/closetgenius-backend/closetgenius/api:latest .
docker push us-central1-docker.pkg.dev/closetgenius-backend/closetgenius/api:latest
```

> **Note:** The first build takes ~10 min (downloads Florence-2 weights into the image).

## 4. Deploy to Cloud Run (GPU)

```bash
gcloud run deploy closetgenius-api \
  --image=us-central1-docker.pkg.dev/closetgenius-backend/closetgenius/api:latest \
  --region=us-central1 \
  --platform=managed \
  --gpu=1 \
  --gpu-type=nvidia-l4 \
  --cpu=8 \
  --memory=32Gi \
  --min-instances=0 \
  --max-instances=1 \
  --timeout=300 \
  --set-secrets=GROQ_API_KEY=GROQ_API_KEY:latest \
  --allow-unauthenticated
```

> `--min-instances=1` keeps one warm instance so the iOS app doesn't wait for a cold start.  
> Remove it (scale-to-zero) to save money if latency on first request is acceptable.

## 5. Get your permanent URL

```bash
gcloud run services describe closetgenius-api \
  --region=us-central1 \
  --format="value(status.url)"
```

Copy that URL — paste it into the iOS app under **Profile → Settings → AI Server**.

---

## Updating after code changes

```bash
docker build -t us-central1-docker.pkg.dev/closetgenius-backend/closetgenius/api:latest .
docker push us-central1-docker.pkg.dev/closetgenius-backend/closetgenius/api:latest
gcloud run deploy closetgenius-api \
  --image=us-central1-docker.pkg.dev/closetgenius-backend/closetgenius/api:latest \
  --region=us-central1
```

---

## Cost estimate (rough)

| Resource | Cost |
|---|---|
| Cloud Run GPU (L4, 1 instance) | ~$0.90/hr (~$650/mo if always-on) |
| Cloud Run GPU (scale-to-zero) | ~$0 idle, ~$0.90/hr active |
| Artifact Registry storage | ~$0.10/GB/mo |
| Secret Manager | ~$0.06/secret/mo |

For a low-traffic app, **scale-to-zero** (`--min-instances=0`) is cheapest — first request takes ~30s cold start while Florence-2 loads.
