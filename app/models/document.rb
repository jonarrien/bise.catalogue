# encoding: UTF-8
# Object
class Document < ActiveRecord::Base

  include Tire::Model::Search
  include Tire::Model::Callbacks

  include Classifiable

  attr_accessible         :description
  attr_accessible         :downloads
  attr_accessible         :thumbnail
  attr_accessible         :file
  mount_uploader          :file, FileUploader

  validates :file          , presence: { on: :create }
  validate :uniqueness_of_md5hash, on: :create

  # TAGS
  attr_accessible :tag_list
  acts_as_taggable

  before_validation :compute_hash
  before_save :update_file_info

  before_destroy { |document| document.remove_file! }

  # INDEXES
  index_name "#{Tire::Model::Search.index_prefix}documents"
  refresh = -> { Tire::Index.new(index_name).refresh }
  after_save(&refresh)
  after_destroy(&refresh)

  settings analysis: {

    # An analyzer of type snowball that uses the standard tokenizer, with
    # standard filter, lowercase filter, stop filter, and snowball filter.
    analyzer: {
      search_analyzer: {
        type: 'custom',
        tokenizer: 'standard',
        filter: %w(lowercase snowball)
      },
      index_ngram_analyzer: {
        type: 'custom',
        tokenizer: 'standard',
        filter: %w(lowercase snowball substring)
      }
    },
    filter: {
      substring: {
        type: 'nGram',
        min_gram: 1,
        max_gram: 40,
        token_chars: %w(letter digit)
      }
    }
  } do
    mapping _source: { excludes: %w(attachment) } do

      indexes :site do
        indexes :id, type: 'integer'
        indexes :name, type: 'string', index: :not_analyzed
        indexes :ngram_name,
                index_analyzer: 'index_ngram_analyzer',
                search_analyzer: 'snowball'
      end

      indexes :id, index: :not_analyzed
      indexes :title, type: 'multi_field', fields: {
        title: {
          type: 'string',
          index_analyzer: 'index_ngram_analyzer',
          search_analyzer: 'snowball'
        },
        exact: { type: 'string', index: :not_analyzed }
      }
      indexes :english_title, type: 'multi_field', fields: {
        english_title: {
          type: 'string',
          index_analyzer: 'index_ngram_analyzer',
          search_analyzer: 'snowball'
        },
        exact: { type: 'string', index: :not_analyzed }
      }
      indexes :english_title ,
              index_analyzer: 'index_ngram_analyzer',
              search_analyzer: 'snowball' ,
              boost: 100
      indexes :description,
              index_analyzer: 'index_ngram_analyzer',
              search_analyzer: 'snowball'

      indexes :languages do
        indexes :id,
                type: 'integer'
        indexes :name,
                type: 'string',
                index: :not_analyzed
        indexes :ngram_name ,
                index_analyzer: 'index_ngram_analyzer',
                search_analyzer: 'snowball'
      end

      indexes :published_on ,
              type: 'date',
              index: :not_analyzed
      indexes :author,
              type: 'string',
              index: :not_analyzed
      indexes :ngram_author ,
              index_analyzer: 'index_ngram_analyzer' ,
              search_analyzer: 'snowball'

      indexes :countries do
        indexes :id,
                type: 'integer'
        indexes :name,
                type: 'string',
                index: :not_analyzed
        indexes :ngram_name ,
                index_analyzer: 'index_ngram_analyzer' ,
                search_analyzer: 'snowball'
      end

      indexes :tags do
        indexes :name,
                type: 'string',
                index: :not_analyzed
        indexes :ngram_name ,
                index_analyzer: 'index_ngram_analyzer' ,
                search_analyzer: 'snowball'
      end

      indexes :biographical_region,
              type: 'string',
              index: :not_analyzed
      indexes :biographical_region_ngram,
              index_analyzer: 'index_ngram_analyzer',
              search_analyzer: 'snowball'

      indexes :file_name,
              type: 'string' ,
              index_analyzer: 'index_ngram_analyzer',
              search_analyzer: 'snowball'
      indexes :content_type ,
              type: 'string',
              index: :not_analyzed

      indexes :attachment, type: 'attachment', fields: {
        date: { store: 'yes' },
        file: { store: 'yes', index: 'no' },
        content: {
          store: 'yes',
          term_vector: 'with_positions_offsets',
          index_analyzer: 'index_ngram_analyzer',
          search_analyzer: 'search_analyzer'
        },
        attachment: { store: 'yes', term_vector: 'with_positions_offsets' },
        author: { analyzer: 'index_ngram_analyzer' }
      }

      indexes :approved           , type: 'boolean'
      indexes :approved_at        , type: 'date'
      indexes :created_at         , type: 'date'
    end
  end

  def to_indexed_json
    {
      site:           {
        _type: 'site',
        _id: site.id,
        name: site.name,
        ngram_name: site.name
      },
      title:          title,
      english_title:  english_title,
      description:    description,
      author:         author,
      ngram_author:   author,
      published_on:   published_on,

      approved:       approved,
      approved_at:    approved_at,
      created_at:     created_at,

      languages:      languages.map { |l| { _type: 'language', _id: l.id, name: l.name, ngram_name: l.name } },

      countries:      countries.map { |c| { _type: 'country', _id: c.id, name: c.name, ngram_name: c.name } },
      tags: tag_list.map do |c|
        { name: c, ngram_name: c }
      end,

      biographical_region:       biographical_region,
      biographical_region_ngram: biographical_region,
      file_name:                 document_path,
      content_type:              content_type,
      attachment:                attachment
    }.to_json
  end

  def document_path
    file.file.file.gsub file.root, ''
    # file.store_path.gsub file.root, ''
  end

  def self.search(params)

    params[:query].gsub!(/[\+\-\:\"\~\*\!\?\{\}\[\]\(\)]/, '\\1')                          if params[:query].present?
    show_approved = (params[:approved] && params[:approved] == 'true') ? true : false

    date_init, date_end = nil
    if params[:published_on].present?
      date_init = DateTime.new(params[:published_on].to_i, 1, 1)
      date_end = DateTime.new(params[:published_on].to_i, 12, 31)
    end

    # Facet Filter
    doc_filter = []
    doc_filter << { term: { 'site.name' => params[:site] }} if params[:site].present?
    doc_filter << { term: { author: params[:author] }} if params[:author].present?
    doc_filter << { term: { 'countries.name' => params[:countries].split(/\//) }} if params[:countries].present?
    doc_filter << { term: { 'languages.name' => params[:languages].split(/\//) }} if params[:languages].present?
    doc_filter << { term: { biographical_region: params[:biographical_region] }} if params[:biographical_region].present?
    doc_filter << { range: { published_on: { gte: date_init , lt: date_end }}} if params[:published_on].present?
    doc_filter << { bool: { must: { term: { approved: show_approved} }}}

    tire.search load: true, page: params[:page], per_page: params[:per_page] do
      query do
        boolean do
          should { string 'site.ngram_name:'           + params[:query].to_s }
          should { string 'title:'                     + params[:query].to_s }
          should { string 'title.exact:'               + params[:query].to_s }
          should { string 'english_title:'             + params[:query].to_s }
          should { string 'english_title.exact:'       + params[:query].to_s }
          should { string 'description:'               + params[:query].to_s }
          should { string 'ngram_author:'              + params[:query].to_s }
          should { string 'attachment:'                + params[:query].to_s }
          should { string 'countries.ngram_name:'      + params[:query].to_s }
          should { string 'languages.ngram_name:'      + params[:query].to_s }
          should { string 'tags.ngram_name:'           + params[:query].to_s }
          should { string 'biographical_region_ngram:' + params[:query].to_s }
        end
      end if params[:query].present?

      highlight :attachment, :description

      filter :term, 'site.name' => params[:site] if params[:site].present?
      filter :term, source_db: params[:source_db] if params[:source_db].present?
      filter :term, author: params[:author] if params[:author].present?
      filter :term, 'countries.name' => params[:countries].split(/\//) if params[:countries].present?
      filter :term, 'languages.name' => params[:languages].split(/\//) if params[:languages].present?
      filter :term, biographical_region: params[:biographical_region] if params[:biographical_region].present?
      filter :range, published_on: { gte: date_init, lt: date_end } if params[:published_on].present?

      filter :bool, must: { term: { approved: show_approved } }

      if params[:sort].present?
        sort { by params[:sort].to_sym, params[:sort] == 'published_on' ? 'desc' : 'asc' }
      else
        # if no query, sort by published_on
        sort { by :published_on, 'desc' } unless params[:query].present?
      end


      facet 'sites' do
        terms 'site.name'
        facet_filter :and, doc_filter unless doc_filter.empty?
      end

      facet 'authors' do
        terms :author
        facet_filter :and, doc_filter unless doc_filter.empty?
      end

      facet 'countries' do
        terms 'countries.name', size: 60
        facet_filter :and, doc_filter unless doc_filter.empty?
      end

      facet 'biographical_regions' do
        terms :biographical_region
        facet_filter :and, doc_filter unless doc_filter.empty?
      end

      facet 'languages' do
        terms 'languages.name'
        facet_filter :and, doc_filter unless doc_filter.empty?
      end

      facet('timeline') do
        date :published_on, interval: 'year'
        facet_filter :and, doc_filter unless doc_filter.empty?
      end
    end
  end

  def attachment
    if file.present?
      path_to_file = Rails.root.to_s + '/public' + file_url.to_s
      Base64.encode64(open(path_to_file) { |f| f.read })
    else
      Base64.encode64('missing')
    end
  end

  def thumbnail
    if file.present?
      name = file.file.filename
      dot = name.rindex('.') - 1
      thumbnail_name = "#{name[0..dot]}_1.jpg"
      file_url[0..file_url.rindex('/')] + thumbnail_name
    end
  end

  def uniqueness_of_md5hash
    if Document.exists?(md5hash: md5hash)
      errors.add :file, :unique
    end
  end

  # DEPRECATED
  def generate_thumbnail
    begin
      require 'docsplit'
      file = "#{Rails.root}/public#{@document.file_url}"
      last_index = file.rindex '/'
      output = file[0..last_index]
      Docsplit.extract_images file, size: '180x', format: [:jpg], pages: 1, output: output
    rescue Exception => e
      logger.error { "Document thumbnail can't be generated" }
    end
  end

  private

    def update_file_info
      if file.present? && file_changed?
        self.content_type = file.file.content_type
        self.file_size = file.file.size
      end
    end

    def compute_hash
      # puts ":: compute_hash => #{self.file.nil?} - #{self.file.size}"
      self.md5hash = Digest::MD5.hexdigest(file.read) if file?
    end

end
