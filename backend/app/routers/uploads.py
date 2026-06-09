"""Uploads — Cloudinary signature endpoint."""

from fastapi import APIRouter, Depends

from app.deps import get_current_user
from app.models.users import User
from app.schemas.uploads import CloudinarySignatureRead, CloudinarySignatureRequest
from app.services import uploads as upload_service

router = APIRouter(tags=["uploads"])


@router.post("/uploads/cloudinary-signature", response_model=CloudinarySignatureRead)
def create_cloudinary_signature(
    payload: CloudinarySignatureRequest,
    current_user: User = Depends(get_current_user),
):
    return upload_service.sign_cloudinary_upload(payload.folder)
