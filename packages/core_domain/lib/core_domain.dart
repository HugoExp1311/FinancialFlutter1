// core_domain — Infrastructure-agnostic business logic.
// Cả Monolith và Microservices đều phụ thuộc vào package này.
// Package này KHÔNG phụ thuộc vào Isar, Supabase, http, hay Flutter widgets.

// --- Entities ---
export 'entities/transaction_entity.dart';

// --- Repository Interfaces (Contracts) ---
export 'repositories/i_transaction_repository.dart';

// --- Use Cases ---
export 'use_cases/add_transaction_use_case.dart';
export 'use_cases/update_transaction_use_case.dart';
export 'use_cases/delete_transaction_use_case.dart';
export 'use_cases/sync_transactions_use_case.dart';
