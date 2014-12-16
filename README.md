Dart ORM
========

Easy-to-use and easy-to-setup database ORM for dart.

It is in the very beginning stage of development and not ready for production use.
Feel free to contribute!

Feature tour
============

If you want to jump to example code click here: https://github.com/ustims/DartORM/blob/master/example/example.dart

Annotations
-----------

```dart
import 'package:dart_orm/orm.dart' as ORM;

@ORM.DBTable('users')
class User extends ORM.Model {
  // Every field that needs to be stored in database should be annotated with @DBField
  @ORM.DBField()
  @ORM.DBFieldPrimaryKey()
  // Database field type can be overridden to database-engine specific type
  // By default a property annotated with DBFieldPrimaryKey will set field type to SERIAL
  // if you use postgres adapter.
  // So this is for example.
  @ORM.DBFieldType('SERIAL')
  int id;

  @ORM.DBField()
  String givenName;

  // Database field name will be converted to underscore
  // for example: family_name in this case,
  // but this can be overridden by
  // providing string argument to the annotation constructor
  @ORM.DBField('family_name')
  String familyName;
}
```

With such annotated class when you first run ORM.Migrator.migrate()

it will execute such statement:

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    given_name text,
    family_name text
);
```

Migrations, schema versions and diffs will be implemented later.

Inserts and updates
-------------------

Every ORM.Model has .save() method which will update/insert new row.

If class instance has 'id' field with not-null value, .save() will execute 'UPDATE' statement with 'WHERE id = $id'.

If class instance has null 'id' field, 'INSERT' statement will be executed.

```dart
User u = new User();
u.givenName = 'Sergey';
u.familyName = 'Ustimenko';

var saveResult = await u.save();
```

This statement will be executed on save():

```sql
INSERT INTO users (
    given_name,
    family_name)
VALUES (
    'Sergey',
    'Ustimenko'
);
```

Finding records
---------------

ORM has two classes for finding records: Find and FindOne.

Constructors receives a class that extends ORM.Model.

```dart

ORM.Find f = new ORM.Find(User)
  ..where(new ORM.LowerThan('id', 3)
    .and(new ORM.Equals('givenName', 'Sergey')
      .or(new ORM.Equals('familyName', 'Ustimenko'))
    )
  )
  ..orderBy('id', 'DESC')
  ..setLimit(10);

List foundUsers = await f.execute();

for(User u in foundUsers){
  print('Found user:');
  print(u);
}
```

This will result such statement executed on the database:

```sql
SELECT *
FROM users
WHERE id < 3 AND (given_name = 'Sergey' OR (family_name = 'Ustimenko'))
ORDER BY id DESC LIMIT 10
```