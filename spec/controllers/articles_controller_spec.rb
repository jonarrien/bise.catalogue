require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

describe ArticlesController do

  before :each do
    @article = FactoryGirl.create :article
  end

  # This should return the minimal set of attributes required to create a valid
  # Article. As you add validations to Article, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    {
      site_id: 1,
      title: "Example Article",
      english_title: "Example Article in English",
      author: "Jon Arrien",
      content: "This is an example Article... ",
      language_ids: [5],
      published_on: '01/01/2012'
    }
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # ArticlesController. Be sure to keep this updated too.
  def valid_session
    {}
  end

  describe "GET index" do
    it "assigns all articles as @articles" do
      params = Hash.new
      params[:query] = ''

      articles = Article.search(params)
      get :index, {}, valid_session
      assigns(:articles).should be_a(Tire::Results::Collection)
    end
  end

  describe "GET show" do
    it "assigns the requested article as @article" do
      get :show, {:id => @article.to_param}, valid_session
      assigns(:article).should eq(@article)
    end
  end

  describe "GET new" do
    it "assigns a new article as @article" do
      get :new, {}, valid_session
      assigns(:article).should be_a_new(Article)
    end
  end

  describe "GET edit" do
    it "assigns the requested article as @article" do
      # article = Article.create! valid_attributes
      get :edit, {:id => @article.to_param}, valid_session
      assigns(:article).should eq(@article)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Article" do
        expect {
          post :create, {:article => valid_attributes}, valid_session
        }.to change(Article, :count).by(1)
      end

      it "assigns a newly created article as @article" do
        post :create, {:article => valid_attributes}, valid_session
        assigns(:article).should be_a(Article)
        assigns(:article).should be_persisted
      end

      it "redirects to the created article" do
        post :create, {:article => valid_attributes}, valid_session
        response.should redirect_to(Article.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved article as @article" do
        # Trigger the behavior that occurs when invalid params are submitted
        Article.any_instance.stub(:save).and_return(false)
        post :create, {:article => {}}, valid_session
        assigns(:article).should be_a_new(Article)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Article.any_instance.stub(:save).and_return(false)
        post :create, {:article => {}}, valid_session
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested article" do
        # Assuming there are no other articles in the database, this
        # specifies that the Article created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        Article.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, {:id => @article.to_param, :article => {'these' => 'params'}}, valid_session
      end

      it "assigns the requested article as @article" do
        put :update, {:id => @article.to_param, :article => valid_attributes}, valid_session
        assigns(:article).should eq(@article)
      end

      it "redirects to the article" do
        put :update, {:id => @article.to_param, :article => valid_attributes}, valid_session
        response.should redirect_to(@article)
      end
    end

    describe "with invalid params" do
      it "assigns the article as @article" do
        # Trigger the behavior that occurs when invalid params are submitted
        Article.any_instance.stub(:save).and_return(false)
        put :update, {:id => @article.to_param, :article => {}}, valid_session
        assigns(:article).should eq(@article)
      end

      it "re-renders the 'edit' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Article.any_instance.stub(:save).and_return(false)
        put :update, {:id => @article.to_param, :article => {}}, valid_session
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested article" do
      expect {
        delete :destroy, {:id => @article.to_param}, valid_session
      }.to change(Article, :count).by(-1)
    end

    it "redirects to the articles list" do
      article = Article.create! valid_attributes
      delete :destroy, {:id => @article.to_param}, valid_session
      response.should redirect_to(articles_url)
    end
  end

end
