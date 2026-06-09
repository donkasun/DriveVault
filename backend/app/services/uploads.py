"""Cloudinary upload-signature service (Task B4b)."""

from hashlib import sha1
from time import time

from app.core.config import get_settings
from app.schemas.uploads import CloudinarySignatureRead


def sign_cloudinary_upload(folder: str) -> CloudinarySignatureRead:
    settings = get_settings()
    timestamp = int(time())
    params = {
        "folder": folder,
        "timestamp": timestamp,
    }
    param_string = "&".join(f"{key}={params[key]}" for key in sorted(params))
    signature = sha1(f"{param_string}{settings.cloudinary_api_secret}".encode()).hexdigest()

    return CloudinarySignatureRead(
        signature=signature,
        timestamp=timestamp,
        api_key=settings.cloudinary_api_key,
        cloud_name=settings.cloudinary_cloud_name,
        folder=folder,
    )
