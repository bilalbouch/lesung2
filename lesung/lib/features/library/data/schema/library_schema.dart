/// Schéma SQL de référence pour la bibliothèque Lesung.
///
/// Ce fichier est la source de vérité pour le schéma de la base de données.
/// L'implémentation actuelle du [LibraryRepository] est en JSON pur Dart
/// (testable sans Flutter) ; le futur backend sqflite de l'application
/// devra créer exactement ces tables. Toute évolution du schéma passe par
/// une migration versionnée ([librarySchemaVersion]).
library;

/// Version courante du schéma. Incrémenter à chaque migration.
const int librarySchemaVersion = 1;

/// DDL complet, dans l'ordre de création (respecte les clés étrangères).
const List<String> librarySchemaStatements = [
  // 1. books — un livre connu de la bibliothèque, indépendant de tout état.
  '''
CREATE TABLE books (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  author TEXT NOT NULL DEFAULT '',
  cover_url TEXT,
  language TEXT,
  format TEXT,
  publisher TEXT,
  year INTEGER,
  description TEXT,
  isbn TEXT,
  downloaded INTEGER NOT NULL DEFAULT 0,
  file_path TEXT,
  file_size_bytes INTEGER,
  file_missing INTEGER NOT NULL DEFAULT 0,
  added_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  last_opened_at TEXT,
  finished_at TEXT
)
''',
  // 2. favorites — état indépendant : un livre non téléchargé peut être favori.
  '''
CREATE TABLE favorites (
  book_id TEXT PRIMARY KEY REFERENCES books(id) ON DELETE CASCADE,
  added_at TEXT NOT NULL
)
''',
  // 3. collections — collections personnalisées de l'utilisateur.
  '''
CREATE TABLE collections (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0
)
''',
  // 4. collection_books — lien N-N avec position pour tri manuel.
  '''
CREATE TABLE collection_books (
  collection_id TEXT NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
  book_id TEXT NOT NULL REFERENCES books(id) ON DELETE CASCADE,
  added_at TEXT NOT NULL,
  position INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (collection_id, book_id)
)
''',
  // 5. reading_progress — une ligne par livre, écrasée à chaque avancement.
  '''
CREATE TABLE reading_progress (
  book_id TEXT PRIMARY KEY REFERENCES books(id) ON DELETE CASCADE,
  locator TEXT NOT NULL,
  progress REAL NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL
)
''',
  // 6. history — sessions de lecture (ouverture/fermeture), base des stats.
  '''
CREATE TABLE history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  book_id TEXT NOT NULL REFERENCES books(id) ON DELETE CASCADE,
  opened_at TEXT NOT NULL,
  closed_at TEXT,
  duration_seconds INTEGER
)
''',
  // 7. downloads — trace des fichiers obtenus (alimentée par événements).
  '''
CREATE TABLE downloads (
  book_id TEXT PRIMARY KEY REFERENCES books(id) ON DELETE CASCADE,
  file_path TEXT NOT NULL,
  file_size_bytes INTEGER,
  md5_verified INTEGER NOT NULL DEFAULT 0,
  completed_at TEXT NOT NULL
)
''',
  // 8. statistics — compteurs globaux (clé/valeur pour extensibilité).
  '''
CREATE TABLE statistics (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''',
];

/// Index recommandés pour les requêtes fréquentes.
const List<String> libraryIndexStatements = [
  'CREATE INDEX idx_books_last_opened ON books(last_opened_at)',
  'CREATE INDEX idx_books_downloaded ON books(downloaded)',
  'CREATE INDEX idx_history_book ON history(book_id)',
  'CREATE INDEX idx_history_opened ON history(opened_at)',
  'CREATE INDEX idx_collection_books_book ON collection_books(book_id)',
];
