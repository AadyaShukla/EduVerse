import pyotp

class AuthService:
    @staticmethod
    def generate_totp_secret():
        return pyotp.random_base32()

    @staticmethod
    def verify_totp(secret: str, code: str):
        totp = pyotp.TOTP(secret)
        return totp.verify(code)

    @staticmethod
    def get_totp_uri(secret: str, email_or_name: str, issuer_name: str = "EduVerse"):
        totp = pyotp.TOTP(secret)
        return totp.provisioning_uri(name=email_or_name, issuer_name=issuer_name)
