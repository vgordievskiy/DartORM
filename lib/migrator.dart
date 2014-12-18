part of dart_orm;


class Migrator {
  static Future migrate() async {
    DBAdapter adapter = Model.ormAdapter;

    // we store database schema and its version in
    // addition table called orm_info_table
    // So the first thing we want to do is check it.
    FindOne f = new FindOne(OrmInfoTable)
      ..orderBy('currentVersion', 'DESC')
      ..setLimit(1);

    try {
      OrmInfoTable ormInfoTable = await f.execute();
      // TODO: check if existing schema in
      // tableDefinitions string is actual and run migrations
      // in dev mode or print diff in production mode
      print("Tables exists. Later here will be check for defference.");
      return true;
    } catch (e) {
      if (e.message != null && e.message == DBAdapter.ErrTableNotExist) {
        // relation does not exists
        // create db
        bool migrationResult = await Migrator.createSchemasFromScratch(
            adapter, AnnotationsParser.ormClasses);
        print('All orm tables were created from scratch.');
        return migrationResult;
      } else {
        // its bad if we don't know what happened
        // because we miss all the ifs above, but lets notice about it.
        throw e;
      }
    }

    return false;
  }

  static Future createSchemasFromScratch(DBAdapter adapter,
                                         Map<String, Table> ormClasses) {
    Completer completer = new Completer();

    // here will be all futures for creating all the tables.
    List<Future> futures = new List<Future>();
    // list of strings for all tables sql.
    // Every item will contain CREATE TABLE statement.
    List<String> tableDefinitions = new List<String>();

    for (Table t in ormClasses.values) {
      futures.add(adapter.execute(t));
      tableDefinitions.add(SQLAdapter.constructTableSql(t));
    }

    Future.wait(futures)
    .then((allTables) {
      // all tables created, lets insert version info
      OrmInfoTable ormInfo = new OrmInfoTable();
      ormInfo.currentVersion = 0;
      ormInfo.tableDefinitions = tableDefinitions.join('\n');
      return ormInfo.save();
    })
    .then((ormInfoSaveResult) {
      completer.complete(true);
    })
    .catchError((err) {
      completer.completeError(err);
    });

    return completer.future;
  }
}