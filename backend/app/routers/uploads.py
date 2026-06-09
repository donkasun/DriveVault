"""Uploads - Cloudinary signature endpoints."""

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.deps import get_current_user
from app.models.users import User
from app.schemas.uploads import CloudinarySignatureRead, CloudinarySignatureRequest
from app.services import uploads as upload_service

router = APIRouter(tags=["uploads"])


@router.post("/uploads/cloudinary-signature", response_model=CloudinarySignatureRead)
def create_cloudinary_signature(
    payload: CloudinarySignatureRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
     """
      Sign upload parameters for direct-to-Cloudinary uploads.
      
      This endpoint is called by the mobile client to get signed upload parameters.
      The actual file bytes are uploaded directly to Cloudinary (not through backend).
      
      See docs/03-api-contract.md POST /api/v1/uploads/cloudinary-signature
      
      Request: {"folder": "vehicles/{vehicleId}/documents"}
      Response: {signature, timestamp, apiKey, cloudName, folder}
     
      The signature is SHA-1 HMAC using the Cloudinary API secret (server-side only).
      Parameters are sorted lexicographically before signing.
      Only signature/timestamp/apiKey/cloudName/folder are returned to client.
      Actual file upload happens at cloudinary.com endpoint with these params.
     """
    return upload_service.sign_cloudinary_upload(payload.folder)
