import os
import uuid
from fastapi import APIRouter, UploadFile, File, HTTPException, status
from google.cloud import storage
from google.oauth2 import service_account
import json

router = APIRouter(prefix="/files", tags=["files"])

# Google Cloud Storage configuration
BUCKET_NAME = "tabi-cloud-storage"
CLOUD_STORAGE_BASE_URL = "https://storage.googleapis.com"

def get_storage_client():
    """Get Google Cloud Storage client using default credentials."""
    # Use default credentials (Cloud Run service account)
    return storage.Client()

@router.post("/upload-image", status_code=status.HTTP_201_CREATED)
async def upload_image(file: UploadFile = File(...)):
    """Accept a single image, upload to Cloud Storage, and return its public URL."""
    ext = os.path.splitext(file.filename)[1].lower()
    if ext not in {".jpg", ".jpeg", ".png", ".gif"}:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid image type")
    
    filename = f"{uuid.uuid4()}{ext}"
    content = await file.read()
    
    try:
        # Upload to Google Cloud Storage
        client = get_storage_client()
        bucket = client.bucket(BUCKET_NAME)
        blob = bucket.blob(filename)
        
        # Upload the file
        blob.upload_from_string(content, content_type=file.content_type)
        
        # With uniform bucket-level access, objects are automatically public
        # No need to call make_public() - just return the public URL
        public_url = f"{CLOUD_STORAGE_BASE_URL}/{BUCKET_NAME}/{filename}"
        return {"url": public_url}
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to upload image to Cloud Storage: {str(e)}"
        )
