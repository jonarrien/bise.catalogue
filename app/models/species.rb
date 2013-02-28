class Species < ActiveRecord::Base

    include Tire::Model::Search
    include Tire::Model::Callbacks

    attr_accessible :binomial_name
    attr_accessible :eunis_primary_name
    attr_accessible :genus
    attr_accessible :ignore_on_match
    attr_accessible :label
    attr_accessible :name_according_to_ID
    attr_accessible :scientific_name
    attr_accessible :scientific_name_authorship
    attr_accessible :species_code
    attr_accessible :species_group
    attr_accessible :synonym_for
    attr_accessible :taxonomic_rank
    attr_accessible :taxonomy
    attr_accessible :valid_name

    index_name "#{Tire::Model::Search.index_prefix}species"

    settings :analysis => {
        :analyzer => {
            :search_analyzer => {
                :tokenizer => "keyword",
                :filter => ["lowercase"]
            },
            :index_ngram_analyzer => {
                :tokenizer => "keyword",
                :filter => ["lowercase", "substring"],
                :type => "custom"
            }
        },
        :filter => {
            :substring => {
                :type => "nGram",
                :min_gram => 1,
                :max_gram => 20
            }
        }
    } do
        mapping {
            indexes :binomial_name, :type => 'string', :index_analyzer => 'index_ngram_analyzer', :search_analyzer => 'search_analyzer'
            indexes :scientific_name, :type => 'string', :index_analyzer => 'index_ngram_analyzer', :search_analyzer => 'search_analyzer'
            indexes :author, :type => 'string'
            indexes :created_at, :type => 'date'
        }
    end


    def self.search(params)
        tire.search :load => true, :page => params[:page], :per_page => 10 do

            query do
                 boolean do
                  should   { string 'binomial_name:' + params[:query].to_s }
                  should   { string 'scientific_name:' + params[:query].to_s }
                  # must_not { string 'published:0' }
                end
            end if params[:query].present?

            # query { string params[:query], :default_operator => "AND"} if params[:query].present?

            # highlight :name, :options => { :tag => '<strong class="highlight">' }

            # filter :term, :author => params[:author] if params[:author].present?

            sort { by :created_at, "desc" } # if params[:query].blank?

            facet('timeline') do
                date :created_at, :interval => 'year'
            end
        end
    end

end
