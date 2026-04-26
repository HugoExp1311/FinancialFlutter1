# Localization Strategy (I18n)
## Implementation
- Use Riverpod to manage languageProvider.
- Dictionary-based approach (pp_translations.dart).

## Logic
- UI displays translated keys (e.g., 'Ăn uống').
- Backend/DB consistently stores raw English keys (e.g., 'Food') to maintain AI compatibility.
- Instant language switching without app restart.
