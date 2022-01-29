module DatabaseHelpers
  def client_options
    options = {
      alter_statement: 'ALTER TABLE books ADD COLUMN "purchased" BOOLEAN DEFAULT FALSE;',
      schema: ENV["POSTGRES_SCHEMA"] || "public",
      dbname: ENV["POSTGRES_DB"] || "postgres",
      host: ENV["POSTGRES_HOST"] || "127.0.0.1",
      username: ENV["POSTGRES_USER"] || "jamesbond",
      password: ENV["POSTGRES_PASSWORD"] || "password",
      port: ENV["port"] || 5432,
    }
    Struct.new(*options.keys).new(*options.values)
  end

  def new_dummy_table_sql
    <<~SQL
      CREATE TABLE IF NOT EXISTS public.sellers (
        id serial PRIMARY KEY,
        name VARCHAR ( 50 ) UNIQUE NOT NULL,
        created_on TIMESTAMP NOT NULL,
        last_login TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS public.books (
        user_id serial PRIMARY KEY,
        username VARCHAR ( 50 ) UNIQUE NOT NULL,
        seller_id SERIAL REFERENCES sellers NOT NULL,
        password VARCHAR ( 50 ) NOT NULL,
        email VARCHAR ( 255 ) UNIQUE NOT NULL,
        created_on TIMESTAMP NOT NULL,
        last_login TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS public.chapters (
        id serial PRIMARY KEY,
        name VARCHAR ( 50 ) UNIQUE NOT NULL,
        book_id SERIAL REFERENCES books NOT NULL,
        created_on TIMESTAMP NOT NULL,
        last_login TIMESTAMP
      );
    SQL
  end

  def setup_tables(client = nil)
    cleanup_dummy_tables(client)
    create_dummy_tables(client)
  end

  def create_dummy_tables(client = nil)
    client ||= PgOnlineSchemaChange::Client.new(client_options)
    PgOnlineSchemaChange::Query.run(client.connection, new_dummy_table_sql)
  end

  def ingest_dummy_data_into_dummy_table(client = nil)
    client ||= PgOnlineSchemaChange::Client.new(client_options)
    query = <<~SQL
      INSERT INTO "sellers"("name", "created_on", "last_login")
      VALUES('local shop', 'now()', 'now()');

      INSERT INTO "books"("user_id", "seller_id", "username", "password", "email", "created_on", "last_login")
      VALUES
        (2, 1, 'jamesbond2', '007', 'james1@bond.com', 'now()', 'now()'),
        (3, 1, 'jamesbond3', '008', 'james2@bond.com', 'now()', 'now()'),
        (4, 1, 'jamesbond4', '009', 'james3@bond.com', 'now()', 'now()');
    SQL
    PgOnlineSchemaChange::Query.run(client.connection, query)
  end

  def cleanup_dummy_tables(client = nil)
    client ||= PgOnlineSchemaChange::Client.new(client_options)
    PgOnlineSchemaChange::Query.run(client.connection, "DROP TABLE IF EXISTS chapters;")
    PgOnlineSchemaChange::Query.run(client.connection, "DROP TABLE IF EXISTS pgosc_audit_table_for_books;")
    PgOnlineSchemaChange::Query.run(client.connection, "DROP TABLE IF EXISTS pgosc_shadow_table_for_books;")
    PgOnlineSchemaChange::Query.run(client.connection, "DROP TABLE IF EXISTS pgosc_old_primary_table_books;")
    PgOnlineSchemaChange::Query.run(client.connection, "DROP TABLE IF EXISTS books;")
    PgOnlineSchemaChange::Query.run(client.connection, "DROP TABLE IF EXISTS sellers;")
  end
end
