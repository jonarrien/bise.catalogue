
require 'rdf'
require 'rdf/ntriples'
require 'data_objects'
require 'do_postgres'
require 'enumerator'

module RDF
    module DataObjects
        class ElasticRepository < ::RDF::Repository

            def initialize(options)
                # @db = ::DataObjects::Connection.new(options)
                p ':: Setting up ElasticRepository...'

                @es = {
                    :host => options[:host],
                    :port => 9200
                }

                # TODO : Create UNIQUE index => 4 columns
                Tire.index 'quads' do
                    delete
                    create :mappings => {
                        :subject    => { :type => 'string', :index => :not_analyzed },
                        :predicate  => { :type => 'string', :index => :not_analyzed },
                        :object     => { :type => 'string', :index => :not_analyzed },
                        :context    => { :type => 'string', :index => :not_analyzed }
                    }
                end
            end

            def each(&block)
                s = Tire.search('articles')
                if block_given?
                    reader = result('select * from quads')
                    while reader.next!
                        block.call(RDF::Statement.new(
                            :subject   => unserialize(reader.values[0]),
                            :predicate => unserialize(reader.values[1]),
                            :object    => unserialize(reader.values[2]),
                            :context   => unserialize(reader.values[3])))
                    end
                else
                    ::Enumerable::Enumerator.new(self,:each)
                end
            end

            # @see RDF::Mutable#insert_statement
            def insert_statement(statement)
                # print '.'
                Tire.index 'quads' do
                    store :type => 'quad',
                          :subject => statement.subject.to_s,
                          :predicate => statement.predicate.to_s,
                          :object => statement.predicate.to_s,
                          :context => statement.context.to_s
                end
            end

            # @see RDF::Mutable#delete_statement
            def delete_statement(statement)
                Tire.index 'quads' do
                    delete :subject => statement.subject.to_s,
                           :predicate => statement.predicate.to_s,
                           :object => statement.predicate.to_s,
                           :context => statement.context.to_s
                end
            end


            ## These are simple helpers to serialize and unserialize component
            # fields. We use an explicit empty string for null values for clarity in
            # this example; we cannot use NULL, as SQLite considers NULLs as
            # distinct from each other when using the uniqueness constraint we
            # added when we created the table.  It would let us insert duplicate
            # with a NULL context.
            def serialize(value)
                RDF::NTriples::Writer.serialize(value) || ''
            end
            def unserialize(value)
                value == '' ? nil : RDF::NTriples::Reader.unserialize(value)
            end

            ## These are simple helpers for DataObjects
            def exec(sql, *args)
                raise ':: NOT IMPLEMENTED'
                # @db.create_command(sql).execute_non_query(*args)
            end

            def result(sql, *args)
                raise ':: NOT IMPLEMENTED'
                # @db.create_command(sql).execute_reader(*args)
            end

            def count
                raise ':: NOT IMPLEMENTED'
                result = result('select count(*) from quads')
                result.next!
                result.values.first
            end

            def query(pattern, &block)
                raise ':: NOT IMPLEMENTED'

                case pattern
                    when RDF::Statement
                        query(pattern.to_hash)
                    when Array
                        query(RDF::Statement.new(*pattern))
                    when Hash
                        statements = []
                        reader = query_hash(pattern)
                        while reader.next!
                            statements << RDF::Statement.new(
                                :subject   => unserialize(reader.values[0]),
                                :predicate => unserialize(reader.values[1]),
                                :object    => unserialize(reader.values[2]),
                                :context   => unserialize(reader.values[3]))
                        end
                        case block_given?
                            when true
                                statements.each(&block)
                            else
                                statements.extend(RDF::Enumerable, RDF::Queryable)
                        end
                    else
                        super(pattern)
                end
            end

            def query_hash(hash)
                raise ':: NOT IMPLEMENTED'

                conditions = []
                params = []
                [:subject, :predicate, :object, :context].each do |resource|
                  unless hash[resource].nil?
                    conditions << "#{resource.to_s} = ?"
                    params     << serialize(hash[resource])
                  end
                end
                where = conditions.empty? ? "" : "WHERE "
                where << conditions.join(' AND ')
                result('select * from quads ' + where, *params)
            end

        end
    end
end
