// **************************************************************************
// FloorGenerator
// **************************************************************************
part of 'app_db.dart';
// ignore: avoid_classes_with_only_static_members
class $FloorAppDb {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$AppDbBuilder databaseBuilder(String name) => _$AppDbBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$AppDbBuilder inMemoryDatabaseBuilder() => _$AppDbBuilder(null);
}

class _$AppDbBuilder {
  _$AppDbBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  /// Adds migrations to the builder.
  _$AppDbBuilder addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  /// Adds a database [Callback] to the builder.
  _$AppDbBuilder addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  /// Creates the database and initializes it.
  Future<AppDb> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDb();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDb extends AppDb {
  _$AppDb([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  UserDao? _userDaoInstance;

  ConfigDao? _configDaoInstance;

  HistoryDao? _historyDaoInstance;

  DeviceDao? _deviceDaoInstance;

  SyncHistoryDao? _syncHistoryDaoInstance;

  HistoryTagDao? _historyTagDaoInstance;

  Future<sqflite.Database> open(
      String path,
      List<Migration> migrations, [
        Callback? callback,
      ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Config` (`key` TEXT NOT NULL, `value` TEXT NOT NULL, `uid` TEXT NOT NULL, PRIMARY KEY (`key`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Device` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `devName` TEXT NOT NULL, `guid` TEXT NOT NULL, `uid` TEXT NOT NULL, `type` TEXT NOT NULL, `lastConnTime` TEXT, `lastAddr` TEXT)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `History` (`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, `uid` TEXT NOT NULL, `time` TEXT NOT NULL, `content` TEXT NOT NULL, `type` TEXT NOT NULL, `devId` TEXT NOT NULL, `top` INTEGER NOT NULL, `sync` INTEGER NOT NULL, `size` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `User` (`id` TEXT, `account` TEXT NOT NULL, `password` TEXT NOT NULL, `type` TEXT NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `SyncHistory` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `devId` TEXT NOT NULL, `hisId` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `HistoryTag` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `tagName` TEXT NOT NULL, `hisId` INTEGER NOT NULL)');
        await database.execute(
            'CREATE INDEX `index_SyncHistory_devId_hisId` ON `SyncHistory` (`devId`, `hisId`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_HistoryTag_tagName_hisId` ON `HistoryTag` (`tagName`, `hisId`)');
        await database.execute(
            'CREATE VIEW IF NOT EXISTS `VHistoryTagHold` AS SELECT DISTINCT\n\tht.hisId,\n\tht.tagName,\n\t(t.hisId is not null) as hasTag \nFROM\n\tHistoryTag ht\n\tLEFT JOIN ( SELECT * FROM HistoryTag ) t ON t.hisId = ht.hisId \n');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  UserDao get userDao {
    return _userDaoInstance ??= _$UserDao(database, changeListener);
  }

  @override
  ConfigDao get configDao {
    return _configDaoInstance ??= _$ConfigDao(database, changeListener);
  }

  @override
  HistoryDao get historyDao {
    return _historyDaoInstance ??= _$HistoryDao(database, changeListener);
  }

  @override
  DeviceDao get deviceDao {
    return _deviceDaoInstance ??= _$DeviceDao(database, changeListener);
  }

  @override
  SyncHistoryDao get syncHistoryDao {
    return _syncHistoryDaoInstance ??=
        _$SyncHistoryDao(database, changeListener);
  }

  @override
  HistoryTagDao get historyTagDao {
    return _historyTagDaoInstance ??= _$HistoryTagDao(database, changeListener);
  }
}

class _$UserDao extends UserDao {
  _$UserDao(
      this.database,
      this.changeListener,
      )   : _queryAdapter = QueryAdapter(database),
        _userInsertionAdapter = InsertionAdapter(
            database,
            'User',
                (User item) => <String, Object?>{
              'id': item.id,
              'account': item.account,
              'password': item.password,
              'type': item.type
            }),
        _userUpdateAdapter = UpdateAdapter(
            database,
            'User',
            ['id'],
                (User item) => <String, Object?>{
              'id': item.id,
              'account': item.account,
              'password': item.password,
              'type': item.type
            });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<User> _userInsertionAdapter;

  final UpdateAdapter<User> _userUpdateAdapter;

  @override
  Future<User?> getById(String id) async {
    return _queryAdapter.query('select * from user where id = ?1',
        mapper: (Map<String, Object?> row) => User(
            id: row['id'] as String?,
            account: row['account'] as String,
            password: row['password'] as String,
            type: row['type'] as String),
        arguments: [id]);
  }

  @override
  Future<int> add(User user) {
    return _userInsertionAdapter.insertAndReturnId(
        user, OnConflictStrategy.abort);
  }

  @override
  Future<int> updateUser(User user) {
    return _userUpdateAdapter.updateAndReturnChangedRows(
        user, OnConflictStrategy.abort);
  }
}

class _$ConfigDao extends ConfigDao {
  _$ConfigDao(
      this.database,
      this.changeListener,
      )   : _queryAdapter = QueryAdapter(database),
        _configInsertionAdapter = InsertionAdapter(
            database,
            'Config',
                (Config item) => <String, Object?>{
              'key': item.key,
              'value': item.value,
              'uid': item.uid
            }),
        _configUpdateAdapter = UpdateAdapter(
            database,
            'Config',
            ['key'],
                (Config item) => <String, Object?>{
              'key': item.key,
              'value': item.value,
              'uid': item.uid
            }),
        _configDeletionAdapter = DeletionAdapter(
            database,
            'Config',
            ['key'],
                (Config item) => <String, Object?>{
              'key': item.key,
              'value': item.value,
              'uid': item.uid
            });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Config> _configInsertionAdapter;

  final UpdateAdapter<Config> _configUpdateAdapter;

  final DeletionAdapter<Config> _configDeletionAdapter;

  @override
  Future<List<Config>> getAllConfigs() async {
    return _queryAdapter.queryList('select * from config',
        mapper: (Map<String, Object?> row) => Config(
            key: row['key'] as String,
            value: row['value'] as String,
            uid: row['uid'] as String));
  }

  @override
  Future<String?> getConfig(
      String key,
      String uid,
      ) async {
    return _queryAdapter.query(
        'select value from config where key = ?1 and uid = ?2',
        mapper: (Map<String, Object?> row) => row.values.first as String,
        arguments: [key, uid]);
  }

  @override
  Future<String?> getConfigByDefault(
      String key,
      String uid,
      String def,
      ) async {
    return _queryAdapter.query(
        'select coalesce(value,?3) as value from config where key = ?1 and uid = ?2',
        mapper: (Map<String, Object?> row) => row.values.first as String,
        arguments: [key, uid, def]);
  }

  @override
  Future<void> removeByKey(
      String key,
      String uid,
      ) async {
    await _queryAdapter.queryNoReturn(
        'delete from config where key = ?1 and uid = ?2',
        arguments: [key, uid]);
  }

  @override
  Future<int> add(Config config) {
    return _configInsertionAdapter.insertAndReturnId(
        config, OnConflictStrategy.abort);
  }

  @override
  Future<int> updateConfig(Config config) {
    return _configUpdateAdapter.updateAndReturnChangedRows(
        config, OnConflictStrategy.abort);
  }

  @override
  Future<int> remove(Config config) {
    return _configDeletionAdapter.deleteAndReturnChangedRows(config);
  }
}

class _$HistoryDao extends HistoryDao {
  _$HistoryDao(
      this.database,
      this.changeListener,
      )   : _queryAdapter = QueryAdapter(database),
        _historyInsertionAdapter = InsertionAdapter(
            database,
            'History',
                (History item) => <String, Object?>{
              'id': item.id,
              'uid': item.uid,
              'time': item.time,
              'content': item.content,
              'type': item.type,
              'devId': item.devId,
              'top': item.top ? 1 : 0,
              'sync': item.sync ? 1 : 0,
              'size': item.size
            });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<History> _historyInsertionAdapter;

  @override
  Future<History?> getLatestLocalClip(String uid) async {
    return _queryAdapter.query(
        'select * from history where uid = ?1 order by id desc limit 1',
        mapper: (Map<String, Object?> row) => History(
            id: row['id'] as int,
            uid: row['uid'] as String,
            time: row['time'] as String,
            content: row['content'] as String,
            type: row['type'] as String,
            devId: row['devId'] as String,
            top: (row['top'] as int) != 0,
            sync: (row['sync'] as int) != 0,
            size: row['size'] as int),
        arguments: [uid]);
  }

  @override
  Future<List<History>> getMissingHistory(String devId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM history h WHERE NOT EXISTS (SELECT 1 FROM SyncHistory sh WHERE sh.hisId = h.id AND sh.devId = ?1) and h.devId != ?1',
        mapper: (Map<String, Object?> row) => History(id: row['id'] as int, uid: row['uid'] as String, time: row['time'] as String, content: row['content'] as String, type: row['type'] as String, devId: row['devId'] as String, top: (row['top'] as int) != 0, sync: (row['sync'] as int) != 0, size: row['size'] as int),
        arguments: [devId]);
  }

  @override
  Future<List<History>> getHistoriesTop20(String uid) async {
    return _queryAdapter.queryList(
        'select * from history where uid = ?1 order by top,id desc limit 20',
        mapper: (Map<String, Object?> row) => History(
            id: row['id'] as int,
            uid: row['uid'] as String,
            time: row['time'] as String,
            content: row['content'] as String,
            type: row['type'] as String,
            devId: row['devId'] as String,
            top: (row['top'] as int) != 0,
            sync: (row['sync'] as int) != 0,
            size: row['size'] as int),
        arguments: [uid]);
  }

  @override
  Future<List<History>> getHistoriesPage(
      String uid,
      int fromId,
      ) async {
    return _queryAdapter.queryList(
        'select * from history where uid = ?1 and id < ?2 order by top,id desc limit 20',
        mapper: (Map<String, Object?> row) => History(id: row['id'] as int, uid: row['uid'] as String, time: row['time'] as String, content: row['content'] as String, type: row['type'] as String, devId: row['devId'] as String, top: (row['top'] as int) != 0, sync: (row['sync'] as int) != 0, size: row['size'] as int),
        arguments: [uid, fromId]);
  }

  @override
  Future<int?> setTop(
      String id,
      bool top,
      ) async {
    return _queryAdapter.query('update history set top = ?2 where id = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [id, top ? 1 : 0]);
  }

  @override
  Future<int?> setSync(
      String id,
      bool sync,
      ) async {
    return _queryAdapter.query('update history set sync = ?2 where id = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [id, sync ? 1 : 0]);
  }

  @override
  Future<int?> delete(String id) async {
    return _queryAdapter.query('delete from history where id = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [id]);
  }

  @override
  Future<int?> transformLocalToUser(String uid) async {
    return _queryAdapter.query('update history set uid = ?1 where uid = 0',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [uid]);
  }

  @override
  Future<int?> removeAllLocalHistories() async {
    return _queryAdapter.query('delete from history where uid = 0',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<int> add(History history) {
    return _historyInsertionAdapter.insertAndReturnId(
        history, OnConflictStrategy.abort);
  }
}

class _$DeviceDao extends DeviceDao {
  _$DeviceDao(
      this.database,
      this.changeListener,
      )   : _queryAdapter = QueryAdapter(database),
        _deviceInsertionAdapter = InsertionAdapter(
            database,
            'Device',
                (Device item) => <String, Object?>{
              'id': item.id,
              'devName': item.devName,
              'guid': item.guid,
              'uid': item.uid,
              'type': item.type,
              'lastConnTime': item.lastConnTime,
              'lastAddr': item.lastAddr
            }),
        _deviceUpdateAdapter = UpdateAdapter(
            database,
            'Device',
            ['id'],
                (Device item) => <String, Object?>{
              'id': item.id,
              'devName': item.devName,
              'guid': item.guid,
              'uid': item.uid,
              'type': item.type,
              'lastConnTime': item.lastConnTime,
              'lastAddr': item.lastAddr
            });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Device> _deviceInsertionAdapter;

  final UpdateAdapter<Device> _deviceUpdateAdapter;

  @override
  Future<List<Device>> getAllDevices(String uid) async {
    return _queryAdapter.queryList('select * from device where uid = ?1',
        mapper: (Map<String, Object?> row) => Device(
            id: row['id'] as int?,
            guid: row['guid'] as String,
            devName: row['devName'] as String,
            uid: row['uid'] as String,
            type: row['type'] as String),
        arguments: [uid]);
  }

  @override
  Future<Device?> getById(
      String guid,
      String uid,
      ) async {
    return _queryAdapter.query(
        'select * from device where guid = ?1 and uid = ?2',
        mapper: (Map<String, Object?> row) => Device(
            id: row['id'] as int?,
            guid: row['guid'] as String,
            devName: row['devName'] as String,
            uid: row['uid'] as String,
            type: row['type'] as String),
        arguments: [guid, uid]);
  }

  @override
  Future<int?> remove(
      String guid,
      String uid,
      ) async {
    return _queryAdapter.query(
        'delete from device where guid = ?1 and uid = ?2',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [guid, uid]);
  }

  @override
  Future<int> add(Device dev) {
    return _deviceInsertionAdapter.insertAndReturnId(
        dev, OnConflictStrategy.abort);
  }

  @override
  Future<int> updateDevice(Device dev) {
    return _deviceUpdateAdapter.updateAndReturnChangedRows(
        dev, OnConflictStrategy.abort);
  }
}

class _$SyncHistoryDao extends SyncHistoryDao {
  _$SyncHistoryDao(
      this.database,
      this.changeListener,
      ) : _syncHistoryInsertionAdapter = InsertionAdapter(
      database,
      'SyncHistory',
          (SyncHistory item) => <String, Object?>{
        'id': item.id,
        'devId': item.devId,
        'hisId': item.hisId
      });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final InsertionAdapter<SyncHistory> _syncHistoryInsertionAdapter;

  @override
  Future<int> add(SyncHistory syncHistory) {
    return _syncHistoryInsertionAdapter.insertAndReturnId(
        syncHistory, OnConflictStrategy.abort);
  }
}

class _$HistoryTagDao extends HistoryTagDao {
  _$HistoryTagDao(
      this.database,
      this.changeListener,
      )   : _queryAdapter = QueryAdapter(database),
        _historyTagInsertionAdapter = InsertionAdapter(
            database,
            'HistoryTag',
                (HistoryTag item) => <String, Object?>{
              'id': item.id,
              'tagName': item.tagName,
              'hisId': item.hisId
            });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<HistoryTag> _historyTagInsertionAdapter;

  @override
  Future<List<HistoryTag>> list(String hId) async {
    return _queryAdapter.queryList('select * from HistoryTag where hisId = ?1',
        mapper: (Map<String, Object?> row) => HistoryTag(
            row['id'] as int, row['tagName'] as String, row['hisId'] as int),
        arguments: [hId]);
  }

  @override
  Future<List<VHistoryTagHold>> listWithHold(String hId) async {
    return _queryAdapter.queryList(
        'select * from VHistoryTagHold where hisId = ?1',
        mapper: (Map<String, Object?> row) => VHistoryTagHold(
            row['hisId'] as String,
            row['tagName'] as String,
            (row['hasTag'] as int) != 0),
        arguments: [hId]);
  }

  @override
  Future<int?> remove(
      String hId,
      String tagName,
      ) async {
    return _queryAdapter.query(
        'delete from HistoryTag where hisId = ?1 and tagName = ?2',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [hId, tagName]);
  }

  @override
  Future<int> add(HistoryTag tag) {
    return _historyTagInsertionAdapter.insertAndReturnId(
        tag, OnConflictStrategy.ignore);
  }
}
