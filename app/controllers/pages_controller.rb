class PagesController < ApplicationController
  def index
    # render :file => 'views/pages/index.html.erb'
    # render :action => "index"
    # @country = Country.find_by_name(params[:name])
    # news_wire = HTTParty.get("http://api.nytimes.com/svc/search/v2/articlesearch.json?q=#{country_name}&begin_date=20131101&sort=oldest&pages=0&api-key=ae59fa9ced00c8e0934ee66358d80da6:1:68403659")
    # @news_wire_results=JSON.parse(news_wire.body)
    # @heat_index = @news_wire_results["response"]["docs"].length
    @countries = Country.all
    @countries_hash = {}
    @max_heat = 0
    @countries.each do |country|
      if country.heat && country.heat > @max_heat
          @max_heat = country.heat
      end
    end
    exponent = 1
    @max_heat **= exponent
    # heat_num = country.heat ** exponent
    @countries.each do |country|
      heat_num = country.heat ** exponent
      @countries_hash[country.name] = {heat: heat_num, norm_heat: (heat_num*100/@max_heat).to_i}
    end
    @countries_json = @countries_hash.to_json.html_safe
  end
end
