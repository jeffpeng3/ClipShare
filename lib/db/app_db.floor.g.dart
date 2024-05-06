part of 'app_db.dart'; 
// **************************************************************************
// FloorGenerator
// **************************************************************************

// ignore: avoid_classes_with_only_static_members
class $Floor_AppDb {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$_AppDbBuilder databaseBuilder(String name) => _$_AppDbBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$_AppDbBuilder inMemoryDatabaseBuilder() => _$_AppDbBuilder(null);
}

class _$_AppDbBuilder {
  _$_AppDbBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  /// Adds migrations to the builder.
  _$_AppDbBuilder addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  /// Adds a database [Callback] to the builder.
  _$_AppDbBuilder addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  /// Creates the database and initializes it.
  Future<_AppDb> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$_AppDb();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$_AppDb extends _AppDb {
  _$_AppDb([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  UserDao? _userDaoInstance;

  ConfigDao? _configDaoInstance;

  HistoryDao? _historyDaoInstance;

  DeviceDao? _deviceDaoInstance;

  OperationSyncDao? _operationSyncDaoInstance;

  HistoryTagDao? _historyTagDaoInstance;

  OperationRecordDao? _operationRecordDaoInstance;

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
            'CREATE TABLE IF NOT EXISTS `Config` (`key` TEXT NOT NULL, `value` TEXT NOT NULL, `uid` INTEGER NOT NULL, PRIMARY KEY (`key`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Device` (`guid` TEXT NOT NULL, `devName` TEXT NOT NULL, `uid` INTEGER NOT NULL, `customName` TEXT, `type` TEXT NOT NULL, `address` TEXT, `isPaired` INTEGER NOT NULL, PRIMARY KEY (`guid`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `History` (`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, `uid` INTEGER NOT NULL, `time` TEXT NOT NULL, `content` TEXT NOT NULL, `type` TEXT NOT NULL, `devId` TEXT NOT NULL, `top` INTEGER NOT NULL, `sync` INTEGER NOT NULL, `size` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `User` (`id` INTEGER, `account` TEXT NOT NULL, `password` TEXT NOT NULL, `type` TEXT NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `OperationSync` (`opId` INTEGER NOT NULL, `devId` TEXT NOT NULL, `uid` INTEGER NOT NULL, `time` TEXT NOT NULL, PRIMARY KEY (`opId`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `HistoryTag` (`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, `tagName` TEXT NOT NULL, `hisId` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `OperationRecord` (`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, `uid` INTEGER NOT NULL, `module` TEXT NOT NULL, `method` TEXT NOT NULL, `data` TEXT NOT NULL, `time` TEXT NOT NULL)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_HistoryTag_tagName_hisId` ON `HistoryTag` (`tagName`, `hisId`)');
        await database.execute(
            'CREATE INDEX `index_OperationRecord_uid_module_method` ON `OperationRecord` (`uid`, `module`, `method`)');
        await database.execute(
            'CREATE VIEW IF NOT EXISTS `VHistoryTagHold` AS select t1.* ,(t2.hisId is not null) as hasTag \nfrom (\n  SELECT distinct h.id as hisId,tag.tagName\n  FROM\n    history as h,historyTag as tag\n) t1\nLEFT JOIN ( SELECT * FROM HistoryTag ) t2\nON t2.hisId = t1.hisId and t2.tagName = t1.tagName\n');

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
  OperationSyncDao get operationSyncDao {
    return _operationSyncDaoInstance ??=
        _$OperationSyncDao(database, changeListener);
  }

  @override
  HistoryTagDao get historyTagDao {
    return _historyTagDaoInstance ??= _$HistoryTagDao(database, changeListener);
  }

  @override
  OperationRecordDao get operationRecordDao {
    return _operationRecordDaoInstance ??=
        _$OperationRecordDao(database, changeListener);
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
  Future<User?> getById(int id) async {
    return _queryAdapter.query('select * from user where id = ?1',
        mapper: (Map<String, Object?> row) => User(
            id: row['id'] as int?,
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
  Future<List<Config>> getAllConfigs(int uid) async {
    return _queryAdapter.queryList('select * from config where uid = ?1',
        mapper: (Map<String, Object?> row) => Config(
            key: row['key'] as String,
            value: row['value'] as String,
            uid: row['uid'] as int),
        arguments: [uid]);
  }

  @override
  Future<String?> getConfig(
    String key,
    int uid,
  ) async {
    return _queryAdapter.query(
        'select `value` from config where `key` = ?1 and uid = ?2',
        mapper: (Map<String, Object?> row) => row.values.first as String,
        arguments: [key, uid]);
  }

  @override
  Future<void> removeByKey(
    String key,
    int uid,
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
                }),
        _historyUpdateAdapter = UpdateAdapter(
            database,
            'History',
            ['id'],
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

  final UpdateAdapter<History> _historyUpdateAdapter;

  @override
  Future<History?> getLatestLocalClip(int uid) async {
    return _queryAdapter.query(
        'select * from history where uid = ?1 order by id desc limit 1',
        mapper: (Map<String, Object?> row) => History(
            id: row['id'] as int,
            uid: row['uid'] as int,
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
  Future<List<History>> getHistoriesPageByWhere(
    int uid,
    int fromId,
    String content,
    String type,
    List<String> tags,
    List<String> devIds,
    String startTime,
    String endTime,
    bool onlyNoSync,
  ) async {
    int offset = 8;
    final _sqliteVariablesForTags =
        Iterable<String>.generate(tags.length, (i) => '?${i + offset}')
            .join(',');
    offset += tags.length;
    final _sqliteVariablesForDevIds =
        Iterable<String>.generate(devIds.length, (i) => '?${i + offset}')
            .join(',');
    return _queryAdapter.queryList(
        'select * from History   where uid = ?1      and case           when ?2 != 0             then               id < ?2             else               id > 0           end      and case            when ?3 = \'\'            then               1            else               content like \'%\'||?3||\'%\'           end      and case            when ?4 = \'\'            then               1            else               type = ?4           end      and case            when ?5 = \'\' or ?6 = \'\'            then               1            else               date(time) between ?5 and ?6           end      and case            when length(null in (' +
            _sqliteVariablesForDevIds +
            ')) = 1 then             1           else             devId in (' +
            _sqliteVariablesForDevIds +
            ')           end      and case            when length(null in (' +
            _sqliteVariablesForTags +
            ')) = 1 then             1           else             id in (               select distinct hisId                from HistoryTag ht                where tagName in (' +
            _sqliteVariablesForTags +
            ')             )           end      and case            when ?7 = 1 then             sync = 0           else             1           end   order by top desc,id desc   limit 20',
        mapper: (Map<String, Object?> row) => History(
            id: row['id'] as int,
            uid: row['uid'] as int,
            time: row['time'] as String,
            content: row['content'] as String,
            type: row['type'] as String,
            devId: row['devId'] as String,
            top: (row['top'] as int) != 0,
            sync: (row['sync'] as int) != 0,
            size: row['size'] as int),
        arguments: [
          uid,
          fromId,
          content,
          type,
          startTime,
          endTime,
          onlyNoSync ? 1 : 0,
          ...tags,
          ...devIds
        ]);
  }

  @override
  Future<List<History>> getMissingHistory(String devId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM history h WHERE NOT EXISTS (SELECT 1 FROM SyncHistory sh WHERE sh.hisId = h.id AND sh.devId = ?1) and h.devId != ?1',
        mapper: (Map<String, Object?> row) => History(id: row['id'] as int, uid: row['uid'] as int, time: row['time'] as String, content: row['content'] as String, type: row['type'] as String, devId: row['devId'] as String, top: (row['top'] as int) != 0, sync: (row['sync'] as int) != 0, size: row['size'] as int),
        arguments: [devId]);
  }

  @override
  Future<List<History>> getHistoriesTop20(int uid) async {
    return _queryAdapter.queryList(
        'select * from history where uid = ?1 order by top desc,id desc limit 20',
        mapper: (Map<String, Object?> row) => History(id: row['id'] as int, uid: row['uid'] as int, time: row['time'] as String, content: row['content'] as String, type: row['type'] as String, devId: row['devId'] as String, top: (row['top'] as int) != 0, sync: (row['sync'] as int) != 0, size: row['size'] as int),
        arguments: [uid]);
  }

  @override
  Future<List<History>> getHistoriesPage(
    int uid,
    int fromId,
  ) async {
    return _queryAdapter.queryList(
        'select * from history where uid = ?1 and id < ?2 order by top desc,id desc limit 20',
        mapper: (Map<String, Object?> row) => History(id: row['id'] as int, uid: row['uid'] as int, time: row['time'] as String, content: row['content'] as String, type: row['type'] as String, devId: row['devId'] as String, top: (row['top'] as int) != 0, sync: (row['sync'] as int) != 0, size: row['size'] as int),
        arguments: [uid, fromId]);
  }

  @override
  Future<int?> setTop(
    int id,
    bool top,
  ) async {
    return _queryAdapter.query('update history set top = ?2 where id = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [id, top ? 1 : 0]);
  }

  @override
  Future<int?> setSync(
    int id,
    bool sync,
  ) async {
    return _queryAdapter.query('update history set sync = ?2 where id = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [id, sync ? 1 : 0]);
  }

  @override
  Future<int?> delete(int id) async {
    return _queryAdapter.query('delete from history where id = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [id]);
  }

  @override
  Future<int?> transformLocalToUser(int uid) async {
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
  Future<History?> getById(int id) async {
    return _queryAdapter.query('select * from history where id = ?1',
        mapper: (Map<String, Object?> row) => History(
            id: row['id'] as int,
            uid: row['uid'] as int,
            time: row['time'] as String,
            content: row['content'] as String,
            type: row['type'] as String,
            devId: row['devId'] as String,
            top: (row['top'] as int) != 0,
            sync: (row['sync'] as int) != 0,
            size: row['size'] as int),
        arguments: [id]);
  }

  @override
  Future<int?> getAllImagesCnt(int uid) async {
    return _queryAdapter.query(
        'select count(*) from history where uid = ?1 and type = \'Image\'',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [uid]);
  }

  @override
  Future<History?> getImageBrotherById(
    int id,
    int uid,
    int pre,
  ) async {
    return _queryAdapter.query(
        'select * from history    where uid = ?2         and type = \'Image\'          and case                when ?3 = 1 then id > ?1               else id < ?1             end     order by case when ?3 = 1 then -id else id end desc    limit 1',
        mapper: (Map<String, Object?> row) => History(id: row['id'] as int, uid: row['uid'] as int, time: row['time'] as String, content: row['content'] as String, type: row['type'] as String, devId: row['devId'] as String, top: (row['top'] as int) != 0, sync: (row['sync'] as int) != 0, size: row['size'] as int),
        arguments: [id, uid, pre]);
  }

  @override
  Future<int?> getImageSeqDesc(
    int id,
    int uid,
  ) async {
    return _queryAdapter.query(
        'select count(*) from history   where id >= ?1 and uid = ?2 and type = \'Image\'   order by id desc',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [id, uid]);
  }

  @override
  Future<int> add(History history) {
    return _historyInsertionAdapter.insertAndReturnId(
        history, OnConflictStrategy.replace);
  }

  @override
  Future<int> updateHistory(History history) {
    return _historyUpdateAdapter.updateAndReturnChangedRows(
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
                  'guid': item.guid,
                  'devName': item.devName,
                  'uid': item.uid,
                  'customName': item.customName,
                  'type': item.type,
                  'address': item.address,
                  'isPaired': item.isPaired ? 1 : 0
                }),
        _deviceUpdateAdapter = UpdateAdapter(
            database,
            'Device',
            ['guid'],
            (Device item) => <String, Object?>{
                  'guid': item.guid,
                  'devName': item.devName,
                  'uid': item.uid,
                  'customName': item.customName,
                  'type': item.type,
                  'address': item.address,
                  'isPaired': item.isPaired ? 1 : 0
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Device> _deviceInsertionAdapter;

  final UpdateAdapter<Device> _deviceUpdateAdapter;

  @override
  Future<List<Device>> getAllDevices(int uid) async {
    return _queryAdapter.queryList('select * from device where uid = ?1',
        mapper: (Map<String, Object?> row) => Device(
            guid: row['guid'] as String,
            devName: row['devName'] as String,
            uid: row['uid'] as int,
            type: row['type'] as String,
            customName: row['customName'] as String?,
            address: row['address'] as String?,
            isPaired: (row['isPaired'] as int) != 0),
        arguments: [uid]);
  }

  @override
  Future<Device?> getById(
    String guid,
    int uid,
  ) async {
    return _queryAdapter.query(
        'select * from device where guid = ?1 and uid = ?2',
        mapper: (Map<String, Object?> row) => Device(
            guid: row['guid'] as String,
            devName: row['devName'] as String,
            uid: row['uid'] as int,
            type: row['type'] as String,
            customName: row['customName'] as String?,
            address: row['address'] as String?,
            isPaired: (row['isPaired'] as int) != 0),
        arguments: [guid, uid]);
  }

  @override
  Future<int?> rename(
    String guid,
    String name,
    int uid,
  ) async {
    return _queryAdapter.query(
        'update device set customName = ?2 where uid = ?3 and guid = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [guid, name, uid]);
  }

  @override
  Future<int?> remove(
    String guid,
    int uid,
  ) async {
    return _queryAdapter.query(
        'delete from device where guid = ?1 and uid = ?2',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [guid, uid]);
  }

  @override
  Future<int?> removeAll(int uid) async {
    return _queryAdapter.query('delete from device where uid = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [uid]);
  }

  @override
  Future<int?> updateDeviceAddress(
    String guid,
    int uid,
    String address,
  ) async {
    return _queryAdapter.query(
        'update device set address = ?3 where uid = ?2 and guid = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [guid, uid, address]);
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

class _$OperationSyncDao extends OperationSyncDao {
  _$OperationSyncDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _operationSyncInsertionAdapter = InsertionAdapter(
            database,
            'OperationSync',
            (OperationSync item) => <String, Object?>{
                  'opId': item.opId,
                  'devId': item.devId,
                  'uid': item.uid,
                  'time': item.time
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<OperationSync> _operationSyncInsertionAdapter;

  @override
  Future<int?> removeAll(int uid) async {
    return _queryAdapter.query('delete OperationSync where uid = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [uid]);
  }

  @override
  Future<int?> resetSyncStatus(String devId) async {
    return _queryAdapter.query('update history set sync = 0 where devId = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [devId]);
  }

  @override
  Future<int> add(OperationSync syncHistory) {
    return _operationSyncInsertionAdapter.insertAndReturnId(
        syncHistory, OnConflictStrategy.ignore);
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
                }),
        _historyTagUpdateAdapter = UpdateAdapter(
            database,
            'HistoryTag',
            ['id'],
            (HistoryTag item) => <String, Object?>{
                  'id': item.id,
                  'tagName': item.tagName,
                  'hisId': item.hisId
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<HistoryTag> _historyTagInsertionAdapter;

  final UpdateAdapter<HistoryTag> _historyTagUpdateAdapter;

  @override
  Future<List<String>> getAllTagNames() async {
    return _queryAdapter.queryList(
        'select distinct tagName from HistoryTag order by tagName',
        mapper: (Map<String, Object?> row) => row.values.first as String);
  }

  @override
  Future<List<HistoryTag>> list(int hId) async {
    return _queryAdapter.queryList('select * from HistoryTag where hisId = ?1',
        mapper: (Map<String, Object?> row) => HistoryTag(
            row['tagName'] as String, row['hisId'] as int, row['id'] as int?),
        arguments: [hId]);
  }

  @override
  Future<List<HistoryTag>> getAll() async {
    return _queryAdapter.queryList('select * from HistoryTag',
        mapper: (Map<String, Object?> row) => HistoryTag(
            row['tagName'] as String, row['hisId'] as int, row['id'] as int?));
  }

  @override
  Future<List<VHistoryTagHold>> listWithHold(int hId) async {
    return _queryAdapter.queryList(
        'SELECT * from VHistoryTagHold where hisId = ?1',
        mapper: (Map<String, Object?> row) => VHistoryTagHold(
            row['hisId'] as int,
            row['tagName'] as String,
            (row['hasTag'] as int) != 0),
        arguments: [hId]);
  }

  @override
  Future<int?> remove(
    int hId,
    String tagName,
  ) async {
    return _queryAdapter.query(
        'delete from HistoryTag where hisId = ?1 and tagName = ?2',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [hId, tagName]);
  }

  @override
  Future<int?> removeById(int id) async {
    return _queryAdapter.query('delete from HistoryTag where id = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [id]);
  }

  @override
  Future<int?> removeAllByHisId(int hId) async {
    return _queryAdapter.query('delete from HistoryTag where hisId = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [hId]);
  }

  @override
  Future<int?> removeAll() async {
    return _queryAdapter.query('delete from HistoryTag',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<HistoryTag?> get(
    int hId,
    String tagName,
  ) async {
    return _queryAdapter.query(
        'select * from HistoryTag where hisId = ?1 and tagName = ?2',
        mapper: (Map<String, Object?> row) => HistoryTag(
            row['tagName'] as String, row['hisId'] as int, row['id'] as int?),
        arguments: [hId, tagName]);
  }

  @override
  Future<HistoryTag?> getById(int id) async {
    return _queryAdapter.query('select * from HistoryTag where id = ?1',
        mapper: (Map<String, Object?> row) => HistoryTag(
            row['tagName'] as String, row['hisId'] as int, row['id'] as int?),
        arguments: [id]);
  }

  @override
  Future<int> add(HistoryTag tag) {
    return _historyTagInsertionAdapter.insertAndReturnId(
        tag, OnConflictStrategy.ignore);
  }

  @override
  Future<int> updateTag(HistoryTag tag) {
    return _historyTagUpdateAdapter.updateAndReturnChangedRows(
        tag, OnConflictStrategy.abort);
  }
}

class _$OperationRecordDao extends OperationRecordDao {
  _$OperationRecordDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _operationRecordInsertionAdapter = InsertionAdapter(
            database,
            'OperationRecord',
            (OperationRecord item) => <String, Object?>{
                  'id': item.id,
                  'uid': item.uid,
                  'module': _moduleTypeConverter.encode(item.module),
                  'method': _opMethodTypeConverter.encode(item.method),
                  'data': item.data,
                  'time': item.time
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<OperationRecord> _operationRecordInsertionAdapter;

  @override
  Future<List<OperationRecord>> getSyncRecord(
    int uid,
    String devId,
  ) async {
    return _queryAdapter.queryList(
        'select * from OperationRecord record   where not exists (     select 1 from OperationSync opsync     where opsync.uid = ?1 and opsync.devId = ?2 and opsync.opId = record.id   )   order by id desc',
        mapper: (Map<String, Object?> row) => OperationRecord(id: row['id'] as int, uid: row['uid'] as int, module: _moduleTypeConverter.decode(row['module'] as String), method: _opMethodTypeConverter.decode(row['method'] as String), data: row['data'] as String),
        arguments: [uid, devId]);
  }

  @override
  Future<int?> removeAll(int uid) async {
    return _queryAdapter.query('delete from OperationRecord where uid = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [uid]);
  }

  @override
  Future<OperationRecord?> getByDataId(
    int id,
    String module,
    String opMethod,
    int uid,
  ) async {
    return _queryAdapter.query(
        'select * from OperationRecord where uid = ?4 and module = ?2 and method = ?3 and data = ?1',
        mapper: (Map<String, Object?> row) => OperationRecord(id: row['id'] as int, uid: row['uid'] as int, module: _moduleTypeConverter.decode(row['module'] as String), method: _opMethodTypeConverter.decode(row['method'] as String), data: row['data'] as String),
        arguments: [id, module, opMethod, uid]);
  }

  @override
  Future<int> add(OperationRecord record) {
    return _operationRecordInsertionAdapter.insertAndReturnId(
        record, OnConflictStrategy.abort);
  }
}

// ignore_for_file: unused_element
final _moduleTypeConverter = ModuleTypeConverter();
final _opMethodTypeConverter = OpMethodTypeConverter();
