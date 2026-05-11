/// Thư viện chứa logic nghiệp vụ cốt lõi (Domain Layer).
/// Định nghĩa các thực thể, interface repository và các quy trình xử lý (Use Cases).

// --- Entities ---
export 'entities/transaction_entity.dart';

// --- Repository Interfaces ---
export 'repositories/i_transaction_repository.dart';

// --- Use Cases ---
export 'use_cases/add_transaction_use_case.dart';
export 'use_cases/update_transaction_use_case.dart';
export 'use_cases/delete_transaction_use_case.dart';
export 'use_cases/sync_transactions_use_case.dart';