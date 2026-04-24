#!/bin/bash
set -e

IMAGE=us-central1-docker.pkg.dev/closetgenius-backend/closetgenius/api:latest

echo "Building..."
docker build -t $IMAGE /Users/biancagambino/Desktop/ClosetGenius/backend

echo "Pushing..."
docker push $IMAGE

echo "Deploying..."
gcloud run deploy closetgenius-api \
  --image=$IMAGE \
  --region=us-central1 \
  --platform=managed \
  --cpu=8 \
  --memory=16Gi \
  --min-instances=0 \
  --max-instances=1 \
  --timeout=300 \
  --cpu-boost \
  --set-secrets=GROQ_API_KEY=GROQ_API_KEY:latest \
  --allow-unauthenticated \
  --project=closetgenius-backend

echo "Done! Service URL:"
gcloud run services describe closetgenius-api --region=us-central1 --format="value(status.url)"
