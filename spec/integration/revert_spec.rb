require "spec_helper"

describe "Reverting scenic schema statements" do
  around do |example|
    with_view_definition :greetings, 1, "SELECT text 'hola' AS greeting" do
      example.run
    end
  end

  it "reverts dropped view to specified version" do
    run_migration(migration_for_create, :up)
    run_migration(migration_for_drop, :up)
    run_migration(migration_for_drop, :down)

    expect { execute("SELECT * from greetings") }
      .not_to raise_error
  end

  def migration_for_create
    Class.new(::ActiveRecord::Migration) do
      def change
        create_view :greetings
      end
    end
  end

  def migration_for_drop
    Class.new(::ActiveRecord::Migration) do
      def change
        drop_view :greetings, revert_to_version: 1
      end
    end
  end

  def run_migration(migration, directions)
    silence_stream(STDOUT) do
      Array.wrap(directions).each do |direction|
        migration.migrate(direction)
      end
    end
  end

  def execute(sql)
    ActiveRecord::Base.connection.execute(sql)
  end
end