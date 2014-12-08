class ImportWorkers::WikipediaSummaryWorker < ImportWorkers::Base
  def perform protected_area_id
    save_wikipedia_article(protected_area_id)
  ensure
    finalise_job
  end

  def save_wikipedia_article protected_area_id
    @protected_area = ProtectedArea.find protected_area_id

    articles = WikipediaArticle.search search_term

    return false if articles.empty?

    wikipedia_article = articles.first
    wikipedia_article.summary = Wikipedia::Summary.fetch wikipedia_article
    wikipedia_article.url = Wikipedia::URL.build wikipedia_article

    wikipedia_article.save!

    @protected_area.wikipedia_article = wikipedia_article
    @protected_area.save!
  end

  private

  def search_term
    [
      @protected_area.name,
      @protected_area.designation.try(:name)
    ].join ' '
  end
end
