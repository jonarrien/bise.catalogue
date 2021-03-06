class DocumentsController < InheritedResources::Base

  before_filter :authenticate_user!

  def index
    if params[:format] == 'xls'
      params[:per_page] = 1000
      response.headers["ContentType"] = "text/xml"
      response.headers["Content-Disposition"] = "attachment"
    end
    @documents = Document.search(params)

    respond_to do |format|
      format.html
      format.xls
    end
  end

  def approve_multiple
    if (params[:document_ids].nil?)
      respond_to do |format|
        format.html { redirect_to documents_path, alert: "Please, select at least one document!" }
      end
      return
    end

    @documents = Document.find(params[:document_ids])
    @documents.each do |document|
      document.approved = !document.approved
      document.save!
    end
    respond_to do |format|
      format.html { redirect_to documents_url }
      format.json { head :no_content }
    end
  end

end
