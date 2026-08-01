import os
from typing import Optional, Dict, Any, List
from app.core.config import settings

class SupabaseClientWrapper:
    """
    Wrapper for Supabase client supporting live Supabase connection
    or local fallback mock store for offline testing.
    """
    def __init__(self):
        self.client = None
        self._mock_students: Dict[str, Dict[str, Any]] = {}
        self._mock_guardians: Dict[str, Dict[str, Any]] = {}
        self._mock_links: List[Dict[str, Any]] = []
        self._mock_lectures: Dict[str, Dict[str, Any]] = {}
        
        # Try initializing real supabase client
        if settings.SUPABASE_URL and not "mock" in settings.SUPABASE_URL:
            try:
                from supabase import create_client, Client
                self.client: Optional[Client] = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
            except Exception as e:
                print(f"[SupabaseClient] Warning: Could not initialize live Supabase client: {e}. Falling back to in-memory store.")

    @property
    def is_live(self) -> bool:
        return self.client is not None

# Singleton database instance
db = SupabaseClientWrapper()
