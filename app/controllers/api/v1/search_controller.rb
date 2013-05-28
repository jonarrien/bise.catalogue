module Api
    module V1
        class SearchController < ApplicationController

            # We overwrite as_json method to create custom mappings
            # class EcosystemAssessment < ::EcosystemAssessment
            #     def as_json(options={})
            #         super.merge(:released_on => released_at.to_date)
            #     end
            # end

            respond_to :json

            after_filter :set_access_control_headers

            def set_access_control_headers
                headers['Access-Control-Allow-Origin'] = '*'
                headers['Access-Control-Request-Method'] = '*'
            end

            def index
                q = params[:query]
                q = nil if q == ''

                indexes = [
                    'articles',
                    'documents',
                    'news',
                    'links',
                    'protected_areas',
                    'habitats',
                    'species'
                ].map do |i|
                    if Rails.env.production?
                        "deployer_catalogue_production_#{i}"
                    else
                        "jon_catalogue_development_#{i}"
                    end
                end

                puts indexes

                if !q.nil?

                    page = if params[:page].present? then params[:page].to_i else 1 end
                    per  = if params[:per_page].present? then params[:per_page].to_i else 10 end
                    from = if page == 1 then 0 else (page - 1) * per end

                    @rows = Tire.search indexes, :load => false, :from => from, :size => per do
                        query do
                            boolean do
                                # Article & Documents titles
                                should   { string 'title:' + q }

                                # Species scientifi name
                                should   { string 'scientific_name:' + q }

                                # should   { string 'content:' + params[:query].to_s }
                                # must_not { string 'published:0' }
                            end
                        end

                        facet 'sites' do
                            terms 'site.name'
                        end

                        facet 'authors' do
                            terms :author
                        end

                        facet 'countries' do
                            terms 'countries.name'
                        end

                        facet 'biographical_regions' do
                            terms :biographical_region
                        end

                        facet 'languages' do
                            terms 'languages.name'
                        end

                        # facet('timeline') do
                        #     date :published_on, :interval => 'year'
                        # end
                    end
                else
                    @rows = nil
                end


                unless @rows.results.nil?
                    response = Hash.new
                    response['total'] = @rows.results.total
                    response['results'] = @rows.results
                    response['facets'] = @rows.results.facets
                end

                if @rows and @rows.results
                    # respond_with @rows.results
                    respond_with response
                else
                    result = { :results => 0 }
                    respond_with result
                end

            end
        end
    end
end
