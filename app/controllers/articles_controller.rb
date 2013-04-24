class ArticlesController < ApplicationController

    # GET /articles
    # GET /articles.json
    def index
        @articles = Article.search(params)
        respond_to do |format|
            format.html # show.html.erb
            format.json { render :json => @articles }
        end
    end

    # GET /articles/search
    # def search
    #     # if params[:q] != ""
    #     #     logger.debug { ":: SEARCHING" }
    #     @articles = Article.search params
    #     # else
    #     #     logger.debug { ":: ALL" }
    #     #     @articles = Article.all
    #     # end
    #     render :action => "index"
    # end

    # FIXME Not going to be used
    # GET /articles/concepts.json
    def concepts
        @themes = Theme.all
        respond_to do |format|
            # format.html # new.html.erb
            format.json { render :json => @themes }
        end
    end


    # GET /articles/1
    # GET /articles/1.json
    def show
        @article = Article.find(params[:id])
        # respond_to do |format|
        #     format.html # show.html.erb
        #     format.json { render json: @article }
        # end
    end

    # GET /articles/new
    # GET /articles/new.json
    def new
        @countries = Country.all
        @article = Article.new
        # respond_to do |format|
        #     format.html # new.html.erb
        #     format.json { render json: @article }
        # end
    end

    # GET /articles/1/edit
    def edit
        @countries = Country.all
        @article = Article.find(params[:id])
    end

    # POST /articles
    # POST /articles.json
    def create
        @article = Article.new(params[:article])
        @article.concepts = get_concepts(params['ft']) unless params['ft'].nil?

        respond_to do |format|
            if @article.save
                format.html { redirect_to @article, :notice => 'Article was successfully created.' }
                format.json { render :json => @article, :status => :created, :location => @article }
            else
                format.html { render :action => "new" }
                format.json { render :json => @article.errors, :status => :unprocessable_entity }
            end
        end
    end

    # PUT /articles/1
    # PUT /articles/1.json
    def update
        @article = Article.find(params[:id])
        @article.concepts = get_concepts(params) unless params['ft'].nil?
        respond_to do |format|
            if @article.update_attributes(params[:article])
                format.html { redirect_to @article, :notice => 'Article was successfully updated.' }
                format.json { head :no_content }
            else
                format.html { render :action => "edit" }
                format.json { render :json => @article.errors, :status => :unprocessable_entity }
            end
        end
    end

    # DELETE /articles/1
    # DELETE /articles/1.json
    def destroy
        @article = Article.find(params[:id])
        @article.destroy
        respond_to do |format|
            format.html { redirect_to articles_url }
            format.json { head :no_content }
        end
    end


    private

        # Returns an array of Concepts
        def get_concepts(params)
            a = Array.new
            params['ft'].each do |f|
                a.push Concept.find(f.to_i)
            end
            return a
        end

end
