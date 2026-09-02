# Règles R8 / ProGuard pour la build release.

# Google Tink, embarqué par flutter_secure_storage pour chiffrer les
# EncryptedSharedPreferences (stockage du jeton Sanctum), référence des
# annotations présentes seulement à la compilation. Elles n'existent pas à
# l'exécution : on demande à R8 de ne pas s'en alarmer.
# Règles produites par R8 lui-même (build/app/outputs/mapping/release/missing_rules.txt).
-dontwarn com.google.errorprone.annotations.CanIgnoreReturnValue
-dontwarn com.google.errorprone.annotations.CheckReturnValue
-dontwarn com.google.errorprone.annotations.Immutable
-dontwarn com.google.errorprone.annotations.RestrictedApi
-dontwarn javax.annotation.Nullable
-dontwarn javax.annotation.concurrent.GuardedBy
