# Database Schema & RLS Policies
## Table: transactions
- id (int8): Primary Key.
- amount (float): Transaction value in USD.
- is_expense (bool): Type classification.
- category_name (text): Enum-like category strings (Food, Transport, etc.)
- sync_id (uuid): Unique identifier for offline-first synchronization.

## Security
- Implement Row-Level Security (RLS) to ensure users only access their own data via uth.uid().
