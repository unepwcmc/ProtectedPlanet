class WikipediaSummaryWorker
  include Sidekiq::Worker

  def perform protected_area_id
    @protected_area = ProtectedArea.find protected_area_id

    articles = WikipediaArticle.search search_term

    wikipedia_article = articles.first
    wikipedia_article.summary = Wikipedia::Summary.fetch wikipedia_article
    wikipedia_article.save!

    @protected_area.wikipedia_article = wikipedia_article
    @protected_area.save!
  end

  private

  def search_term
    [
      @protected_area.name,
      @protected_area.designation.name
    ].join ' '
  end
end
