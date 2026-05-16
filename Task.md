# Task List - Feature Enhancements

## 1. Currency Dropdown (USD/VND)
**Status:** ✅ Completed  
**Description:** Add currency selection dropdown to switch between USD and Vietnamese Dong  
**Requirements:**
- Add currency dropdown in Profile Settings
- Convert and display amounts in selected currency
- Persist currency preference
- Update all amount displays throughout the app

**Files modified:**
- `app/lib/presentation/providers/currency_provider.dart` - Created currency provider with USD/VND conversion (1 USD = 24,000 VND)
- `app/lib/presentation/screens/profile_screen.dart` - Added currency dropdown in settings
- `app/lib/presentation/widgets/balance_card.dart` - Updated to use currency formatting
- `app/lib/presentation/widgets/transaction_item.dart` - Updated to use currency formatting currency)
- `app/lib/presentation/screens/add_transaction_screen.dart` (input with currency)

---

## 2. Profile Avatar + Name on Homepage
**Status:** ✅ Completed  
**Description:** Display user's profile avatar and name on the home screen  
**Requirements:**
- Fetch user profile data (avatar_url, first_name, last_name)
- Display avatar in home screen header
- Show greeting with user's name
- Update in real-time when profile changes

**Files modified:**
- `app/lib/presentation/screens/home_screen.dart` - Updated `_buildAppBar()` to use `profileProvider`
- Added loading and error states for better UX

---

## 3. Display OCR Bill Image on Chatbot
**Status:** ✅ Completed  
**Description:** Show the uploaded bill image in the chatbot interface  
**Requirements:**
- Display image thumbnail in chat message
- Allow tap to view full-size image
- Show image alongside OCR results
- Maintain chat history with images

**Files modified:**
- `app/lib/presentation/screens/chatbot_screen.dart` - Updated ChatMessage class to support imagePath
- Added image preview in message bubbles (200x200 thumbnail)
- Implemented tap-to-view full-screen image dialog
- Images are displayed above the text message in chat

---

## 4. Language Translation Dropdown (Vietnamese ↔ English)
**Status:** ✅ Completed  
**Description:** Add dropdown to translate chatbot responses between Vietnamese and English  
**Requirements:**
- Add language toggle in chatbot screen
- Translate chatbot responses dynamically
- Persist language preference
- Update UI labels based on selected language

**Files modified:**
- `app/lib/presentation/screens/chatbot_screen.dart` - Added language dropdown in AppBar with flag icons
- Uses existing `languageProvider` for state management
- All UI text already uses `AppTranslations.getText()` for dynamic translation

---

## Implementation Order
1. ✅ Task 2 - Profile Avatar + Name (Easiest, uses existing provider)
2. ✅ Task 4 - Language Translation (Uses existing language system)
3. ✅ Task 1 - Currency Dropdown (New feature, moderate complexity)
4. ✅ Task 3 - OCR Image Display (Requires chatbot integration)

---

**Created:** 2026-05-16  
**Last Updated:** 2026-05-16
