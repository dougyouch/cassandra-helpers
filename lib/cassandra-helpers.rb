require 'cassandra'

module CassandraHelpers
  module_function

  def logger
    @logger
  end

  def logger=(logger)
    @logger = logger
  end

  def create_cluster(hosts, port = 9042)
    Cassandra.cluster(hosts: hosts, port: port)
  end

  def get_keyspace(cluster, name)
    cluster.keyspaces.detect { |keyspace| keyspace.name == name }
  end

  def create_session(cluster, keyspace_name)
    cluster.connect(keyspace_name)
  end

  def get_table(keyspace, table_name)
    keyspace.tables.detect { |table| table.name == table_name }
  end

  def execute_query(session, cql, options = {})
    started_at = Time.now
    result = session.execute(cql, options)
    took = '%.2f' % (Time.now - started_at)
    logger.debug("KS [#{took}] #{cql}") if logger && logger.debug?
    result
  end

  def delete_record(session, table, record)
    cql = "DELETE FROM #{Cassandra::Util.escape_name(table.name)} WHERE "
    cql += table.primary_key.map { |key| "#{Cassandra::Util.escape_name(key.name)} = #{Cassandra::Util.encode_object(record[key.name])}" }.join(' AND ')
    execute_query(session,  cql)
  end

  def delete_records(session, table, records)
    records.each do |record|
      delete_record(session, table, record)
    end
  end

  def each_record(session, cql, page_size = 100)
    result = execute_query(session, cql, page_size: page_size)
    loop do
      result.each { |row| yield row }
      break if result.last_page?

      result = result.next_page
    end
  end

  def retry(retries = 10, sleep_times_between_retries = nil)
    max_retries = retries
    sleep_times_between_retries = [sleep_times_between_retries] if sleep_times_between_retries.is_a?(Numeric)

    begin
      yield
    rescue Cassandra::Errors::TimeoutError => e
      logger.error(e) if logger

      sleep_time =
        if sleep_times_between_retries
          sleep_times_between_retries[max_retries - retries] || sleep_times_between_retries.last
        end

      retries -= 1
      if retries <= 0
        logger.error('no more retries') if logger
        raise(e)
      end

      logger.warn("retrying, remaining attempts #{retries}, sleeping for #{sleep_time.to_f} seconds") if logger
      sleep(sleep_time) if sleep_time

      retry
    end
  end
end
