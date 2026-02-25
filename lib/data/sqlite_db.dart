// lib/data/sqlite_db.dart
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class SqliteDb {
  SqliteDb._();

  static const _dbName = 'piece_tracker_v1.db';
  static const _dbVersion = 1;

  static Database? _db;

  /// SQLite 打开与初始化（唯一入口，单例）
  static Future<Database> open() async {
    final existing = _db;
    if (existing != null) return existing;

    final basePath = await getDatabasesPath();
    final dbPath = p.join(basePath, _dbName);

    final db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onConfigure: (db) async {
        // 必须在这里开，否则外键约束不生效
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onOpen: (db) async {
        // PRAGMA journal_mode 会返回结果，必须用 rawQuery
        await db.rawQuery('PRAGMA journal_mode=WAL;');

        // 这个也用 rawQuery，统一风格（安全）
        await db.rawQuery('PRAGMA synchronous=NORMAL;');
        // 注意：journal_mode 不能在 transaction 内执行
        // onOpen 保证不在 onCreate 的 txn 内
        //await db.execute('PRAGMA journal_mode = WAL;');
        //await db.execute('PRAGMA synchronous = NORMAL;');
      },
      onCreate: (db, version) async {
        // -----------------------------
        // workers 表：工人
        // -----------------------------
        await db.execute('''
CREATE TABLE workers (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  name      TEXT    NOT NULL,
  type      INTEGER NOT NULL,          -- 0=sewing, 1=ironing
  is_active INTEGER NOT NULL DEFAULT 1 -- 0/1
);
''');

        // -----------------------------
        // piece_entries 表：计件记录（只存 count>0）
        // 唯一约束：同一天同一工人只能一条
        // -----------------------------
        await db.execute('''
CREATE TABLE piece_entries (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  date_key  INTEGER NOT NULL,          -- YYYYMMDD
  worker_id INTEGER NOT NULL,
  count     INTEGER NOT NULL,
  FOREIGN KEY(worker_id) REFERENCES workers(id) ON DELETE RESTRICT,
  UNIQUE(date_key, worker_id)
);
''');

        // 索引（v1.0.1 固定）
        await db.execute(
            'CREATE INDEX idx_workers_active_id ON workers(is_active, id);');
        await db
            .execute('CREATE INDEX idx_entries_date ON piece_entries(date_key);');
        await db.execute(
            'CREATE INDEX idx_entries_worker ON piece_entries(worker_id);');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // v1.0.1：预留
      },
    );

    _db = db;
    return db;
  }

  static Future<void> close() async {
    final db = _db;
    _db = null;
    if (db != null) await db.close();
  }
}
