class DatabaseSchema {
  DatabaseSchema._();

  static const String databaseName = 'focus_rpg.db';
  static const int databaseVersion = 8;

  static const String profileTable = 'Profile';
  static const String sessionTable = 'Session';
  static const String itemTable = 'Item';
  static const String profileItemTable = 'ProfileItem';
  static const String profilePotionTable = 'ProfilePotion';
  static const String cosmeticsTable = 'Cosmetics';
  static const String ownedCosmeticsTable = 'OwnedCosmetics';
  static const String equippedCosmeticsTable = 'EquippedCosmetics';
  static const String appSettingsTable = 'AppSettings';

  static List<String> createStatements() {
    return <String>[
      '''
      CREATE TABLE $profileTable (
        profile_id INTEGER PRIMARY KEY,
        profile_class TEXT NOT NULL,
        profile_xp INTEGER NOT NULL DEFAULT 0 CHECK (profile_xp >= 0),
        profile_level INTEGER NOT NULL DEFAULT 1 CHECK (profile_level >= 1),
        profile_gold INTEGER NOT NULL DEFAULT 0 CHECK (profile_gold >= 0),
        profile_elo INTEGER NOT NULL DEFAULT 0 CHECK (profile_elo >= 0),
        profile_created_at TEXT NOT NULL,
        profile_last_played_at TEXT,
        profile_total_study_minutes INTEGER NOT NULL DEFAULT 0 CHECK (profile_total_study_minutes >= 0),
        profile_total_completed_sessions INTEGER NOT NULL DEFAULT 0 CHECK (profile_total_completed_sessions >= 0),
        profile_streak_days INTEGER NOT NULL DEFAULT 0 CHECK (profile_streak_days >= 0),
        profile_last_streak_date TEXT
      )
      ''',
      '''
      CREATE TABLE $sessionTable (
        session_id INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id INTEGER NOT NULL,
        session_type TEXT NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        duration_minutes INTEGER NOT NULL DEFAULT 0 CHECK (duration_minutes >= 0),
        completed INTEGER NOT NULL DEFAULT 0 CHECK (completed IN (0, 1)),
        xp_earned INTEGER NOT NULL DEFAULT 0 CHECK (xp_earned >= 0),
        gold_earned INTEGER NOT NULL DEFAULT 0 CHECK (gold_earned >= 0),
        FOREIGN KEY (profile_id) REFERENCES $profileTable(profile_id) ON DELETE CASCADE
      )
      ''',
      '''
      CREATE TABLE $itemTable (
        item_id INTEGER PRIMARY KEY,
        item_name TEXT NOT NULL,
        item_type TEXT NOT NULL
      )
      ''',
      '''
      CREATE TABLE $profileItemTable (
        profile_id INTEGER NOT NULL,
        item_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 0 CHECK (quantity >= 0),
        PRIMARY KEY (profile_id, item_id),
        FOREIGN KEY (profile_id) REFERENCES $profileTable(profile_id) ON DELETE CASCADE,
        FOREIGN KEY (item_id) REFERENCES $itemTable(item_id) ON DELETE CASCADE
      )
      ''',
      '''
      CREATE TABLE $profilePotionTable (
        profile_id INTEGER NOT NULL,
        potion_id TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 0 CHECK (quantity >= 0),
        PRIMARY KEY (profile_id, potion_id),
        FOREIGN KEY (profile_id) REFERENCES $profileTable(profile_id) ON DELETE CASCADE
      )
      ''',
      '''
      CREATE TABLE $cosmeticsTable (
        cosmetic_id INTEGER PRIMARY KEY,
        cosmetic_name TEXT NOT NULL,
        cosmetic_type TEXT NOT NULL,
        class_restriction TEXT NOT NULL
      )
      ''',
      '''
      CREATE TABLE $ownedCosmeticsTable (
        profile_id INTEGER NOT NULL,
        cosmetic_id INTEGER NOT NULL,
        unlocked_at TEXT NOT NULL,
        PRIMARY KEY (profile_id, cosmetic_id),
        FOREIGN KEY (profile_id) REFERENCES $profileTable(profile_id) ON DELETE CASCADE,
        FOREIGN KEY (cosmetic_id) REFERENCES $cosmeticsTable(cosmetic_id) ON DELETE CASCADE
      )
      ''',
      '''
      CREATE TABLE $equippedCosmeticsTable (
        profile_id INTEGER NOT NULL,
        slot_type TEXT NOT NULL,
        cosmetic_id INTEGER NOT NULL,
        equipped_at TEXT NOT NULL,
        PRIMARY KEY (profile_id, slot_type),
        FOREIGN KEY (profile_id) REFERENCES $profileTable(profile_id) ON DELETE CASCADE,
        FOREIGN KEY (cosmetic_id) REFERENCES $cosmeticsTable(cosmetic_id) ON DELETE CASCADE
      )
      ''',
      '''
      ${createAppSettingsTableStatement()}
      ''',
      '''
      CREATE TRIGGER profile_max_three_before_insert
      BEFORE INSERT ON $profileTable
      BEGIN
        SELECT CASE
          WHEN (SELECT COUNT(*) FROM $profileTable) >= 3
          THEN RAISE(ABORT, 'Profile limit reached')
        END;
      END;
      ''',
    ];
  }

  static List<String> seedStatements() {
    return <String>[
      '''
      INSERT OR IGNORE INTO $itemTable (item_id, item_name, item_type)
      VALUES
        (1, 'Focus Potion', 'consumable'),
        (2, 'Energy Elixir', 'consumable'),
        (3, 'Quest Compass', 'utility')
      ''',
      seedCosmeticsStatement(),
      seedAppSettingsStatement(),
    ];
  }

  static String seedCosmeticsStatement() {
    return '''
      INSERT OR IGNORE INTO $cosmeticsTable (cosmetic_id, cosmetic_name, cosmetic_type, class_restriction)
      VALUES
        (1001, 'Simple Cloth Hat', 'hat', 'all'),
        (1101, 'Hogwarts Sorting Hat', 'hat', 'mage'),
        (1102, 'Crystal Wizard Hat', 'hat', 'mage'),
        (1201, 'Gothic Knight Helm', 'hat', 'knight'),
        (1202, 'Lionguard Knight Helm', 'hat', 'knight'),
        (1301, 'Mirkwood Elven Hood', 'hat', 'archer'),
        (1302, 'Crystal Scout Crown', 'hat', 'archer'),
        (1401, 'Ezio''s White Hood', 'hat', 'thief'),
        (1402, 'Rust Leather Skull Hood', 'hat', 'thief'),
        (2001, 'Plain Traveler Tunic', 'torso', 'all'),
        (2101, 'Hogwarts Robe', 'torso', 'mage'),
        (2102, 'Crystal Wizard Robe', 'torso', 'mage'),
        (2201, 'Gothic Plate Armor', 'torso', 'knight'),
        (2202, 'Lionguard Plate Armor', 'torso', 'knight'),
        (2301, 'Legolas Elven Armor', 'torso', 'archer'),
        (2302, 'Gray Crystal Scout Armor', 'torso', 'archer'),
        (2401, 'Auditore Robe', 'torso', 'thief'),
        (2402, 'Rust Leather Skull Vest', 'torso', 'thief'),
        (4101, 'Mage Staff', 'weapon', 'mage'),
        (4201, 'Knight Sword', 'weapon', 'knight'),
        (4301, 'Archer Bow', 'weapon', 'archer'),
        (4401, 'Thief Dagger', 'weapon', 'thief'),
        (3001, 'Wooden Profile Frame', 'frame', 'all'),
        (3002, 'Bronze Profile Frame', 'frame', 'all'),
        (3003, 'Silver Profile Frame', 'frame', 'all'),
        (3004, 'Gold Profile Frame', 'frame', 'all'),
        (3005, 'Platinum Profile Frame', 'frame', 'all'),
        (3006, 'Emerald Profile Frame', 'frame', 'all'),
        (3007, 'Diamond Profile Frame', 'frame', 'all')
      ''';
  }

  static String createProfilePotionTableStatement() {
    return '''
      CREATE TABLE IF NOT EXISTS $profilePotionTable (
        profile_id INTEGER NOT NULL,
        potion_id TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 0 CHECK (quantity >= 0),
        PRIMARY KEY (profile_id, potion_id),
        FOREIGN KEY (profile_id) REFERENCES $profileTable(profile_id) ON DELETE CASCADE
      )
      ''';
  }

  static String createAppSettingsTableStatement() {
    return '''
      CREATE TABLE IF NOT EXISTS $appSettingsTable (
        settings_id INTEGER PRIMARY KEY CHECK (settings_id = 1),
        dark_mode INTEGER NOT NULL DEFAULT 1 CHECK (dark_mode IN (0, 1)),
        music_enabled INTEGER NOT NULL DEFAULT 1 CHECK (music_enabled IN (0, 1)),
        sfx_enabled INTEGER NOT NULL DEFAULT 1 CHECK (sfx_enabled IN (0, 1)),
        music_volume REAL NOT NULL DEFAULT 0.15 CHECK (music_volume >= 0 AND music_volume <= 1),
        sfx_volume REAL NOT NULL DEFAULT 0.55 CHECK (sfx_volume >= 0 AND sfx_volume <= 1),
        updated_at TEXT NOT NULL
      )
      ''';
  }

  static String seedAppSettingsStatement() {
    return '''
      INSERT OR IGNORE INTO $appSettingsTable (
        settings_id,
        dark_mode,
        music_enabled,
        sfx_enabled,
        music_volume,
        sfx_volume,
        updated_at
      )
      VALUES (1, 1, 1, 1, 0.15, 0.55, '${DateTime.now().toIso8601String()}')
      ''';
  }

  static List<String> addProfileStreakColumnsStatements() {
    return <String>[
      '''
      ALTER TABLE $profileTable
      ADD COLUMN profile_streak_days INTEGER NOT NULL DEFAULT 0 CHECK (profile_streak_days >= 0)
      ''',
      '''
      ALTER TABLE $profileTable
      ADD COLUMN profile_last_streak_date TEXT
      ''',
    ];
  }

  static List<String> addProfileEloColumnStatements() {
    return <String>[
      '''
      ALTER TABLE $profileTable
      ADD COLUMN profile_elo INTEGER NOT NULL DEFAULT 0 CHECK (profile_elo >= 0)
      ''',
      '''
      UPDATE $profileTable
      SET profile_elo =
        CAST(profile_xp / 10 AS INTEGER) +
        profile_gold +
        (profile_total_completed_sessions * 50)
      ''',
    ];
  }
}
