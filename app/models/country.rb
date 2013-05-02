class Country < ActiveRecord::Base

    include Tire::Model::Search
    include Tire::Model::Callbacks

    attr_accessible :code
    attr_accessible :name
    attr_accessible :eea
    attr_accessible :eu15
    attr_accessible :eu25
    attr_accessible :eu27
    attr_accessible :eu28

    has_and_belongs_to_many :articles, :association_foreign_key => "article_id", :join_table => "articles_countries", :class_name => "Article"
    has_and_belongs_to_many :documents, :association_foreign_key => "document_id", :join_table => "documents_countries", :class_name => "Document"



    index_name "#{Tire::Model::Search.index_prefix}countries"

    refresh = lambda { Tire::Index.new(index_name).refresh }
    after_save(&refresh)
    after_destroy(&refresh)

    mapping do
        indexes :id,    :index    => :not_analyzed
        indexes :name,  :analyzer => 'snowball'
    end

end
