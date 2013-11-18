require "httparty"
require 'open-uri'

class CountriesController < ApplicationController
  before_action :set_country, only: [:show, :edit, :update, :destroy]

  # GET /countries
  # GET /countries.json
  def index
    @countries = Country.all
  end

  def refresh_news_count
    @countries = Country.all
    @country_status = []
    # find current date to throw into country instead of hard coding
    # Time.parse(result["current_Date"]).strftime("%Y,%m,%d")
    # do news in the past month for the heat map?
    current_Date= Time.new
    current_year = current_Date.year.to_s
    current_month = current_Date.month.to_s
    @api_form_date = current_year+current_month+"01"


    # if false
      @countries.reverse_each do |country|
        sleep(0.2)
        enc_name = URI::encode(country.name)
        news_wire = HTTParty.get("http://api.nytimes.com/svc/search/v2/articlesearch.json?q=#{enc_name}&begin_date=#{@api_form_date}&sort=oldest&pages=0&api-key=ae59fa9ced00c8e0934ee66358d80da6:1:68403659")
        @news_wire_results=JSON.parse(news_wire.body)
        @hits = @news_wire_results["response"]["meta"]["hits"]
        # country.update(params[name: => country.name, heat: => @hits])
        if @hits
          logger.info "#{country.name} => got #{@hits} hits"
          country.heat = @hits
          if country.save
            @country_status << {name: country.name, status: "saved, found #{@hits} articles"}
          else
            @country_status << {name: country.name, status: "failed, found #{@hits} articles"}
          end
        else
          logger.info "no hits for [#{country.name}]"
        end
      end
    # end
  end
  # GET /countries/1
  # GET /countries/1.json

  def show
    @country = Country.find_by_name(params[:name])
    @country_news = []
    # if response = HTTParty.get("http://ajax.googleapis.com/ajax/services/search/news?v=1.0&q=#{params[:name]}")
    #google news api code
    country_name = URI::encode(@country.name)
    response = HTTParty.get("http://ajax.googleapis.com/ajax/services/search/news?v=1.0&q=#{country_name}")
    @country_news = JSON.parse(response.body)

    #NYT api response code for the timeline js
    # could use the dates from the last month
    current_Date= Time.new
    current_year = current_Date.year.to_s
    current_month = current_Date.month.to_s
    @api_form_date = current_year+current_month+"01"
    country_articles=HTTParty.get("http://api.nytimes.com/svc/search/v2/articlesearch.json?q=#{country_name}&begin_date=#{@api_form_date}&sort=oldest&pages=0&api-key=ae59fa9ced00c8e0934ee66358d80da6:1:68403659")
    @country_NYT=JSON.parse(country_articles.body)
    #take the nyt data and set it into a hash

   # getting the heat index number
   # news_wire = HTTParty.get("http://api.nytimes.com/svc/search/v2/articlesearch.json?q=#{country_name}&begin_date=20131101&sort=oldest&pages=0&api-key=ae59fa9ced00c8e0934ee66358d80da6:1:68403659")
   # @news_wire_results=JSON.parse(news_wire.body)
   # @heat_index = @news_wire_results["response"]["docs"].length

    @timeline_events_ar =[]
    @country_NYT["response"]["docs"].each_with_index do |result, i|
      @date_instance = {
        "startDate" => Time.parse(result["pub_date"]).strftime("%Y,%m,%d"),
        # "endDate" => Time.parse(result["pub_date"]).strftime("%Y,%m,%d"),
        "headline" => result["headline"]["main"],
        "text" => result["abstract"],
        "tag" => "tag#{i%6}",
        "classname" => "",
        "asset" => {
          "media" => result["web_url"],
          "thumb_nail" => "",
          "credit" => result["first_name"],
          "caption" => result["snippet"]
        }
      }
      @timeline_events_ar << @date_instance
    end
    @timeline = {
      "timeline" => {
        "headline" => "New York Times Timeline",
        "type" => "default",
        "startDate" => Time.parse(@country_NYT["response"]["docs"].first["pub_date"]).strftime("%Y,%m,%d"),
        "date" => @timeline_events_ar
      }
    }


  end

  def get_timeline_json
    @country = Country.find_by_name(params[:name])
    @country_news = []
    # if response = HTTParty.get("http://ajax.googleapis.com/ajax/services/search/news?v=1.0&q=#{params[:name]}")
    #google news api code
    country_name = URI::encode(@country.name)


    #NYT api response code
    country_articles=HTTParty.get("http://api.nytimes.com/svc/search/v2/articlesearch.json?q=#{country_name}&begin_date=20131001&sort=oldest&api-key=ae59fa9ced00c8e0934ee66358d80da6:1:68403659")
    @country_NYT=JSON.parse(country_articles.body)
    #take the nyt data and set it into a hash
    @timeline_events_ar =[]
    @country_NYT["response"]["docs"].each_with_index do |result, i|
      @date_instance = {
        "startDate" => Time.parse(result["pub_date"]).strftime("%Y,%m,%d"),
        # "endDate" => Time.parse(result["pub_date"]).strftime("%Y,%m,%d"),
        "headline" => result["headline"]["main"],
        "text" => result["abstract"],
        "tag" => "tag#{i%6}",
        "classname" => "",
        "asset" => {
          "media" => result["web_url"],
          "thumb_nail" => "",
          "credit" => result["first_name"],
          "caption" => result["snippet"]
        }
      }
      @timeline_events_ar << @date_instance
    end
    @timeline = {
      "timeline" => {
        "headline" => "New York Times Timeline",
        "type" => "default",
        "startDate" => Time.parse(@country_NYT["response"]["docs"].first["pub_date"]).strftime("%Y,%m,%d"),
        "date" => @timeline_events_ar
      }
    }
    render :json => @timeline
  end

  def time_line
    @country = Country.find_by_name(params[:name])
  end

  def get_article_urls(article)
    @original = article
    @url_array=[]
    @original.each do |result|
      url_array.push(result["web_url"])
    end
    return @url_array
  end

  # GET /countries/new
  def new
    @country = Country.new
  end

  # GET /countries/1/edit
  def edit
  end

  # POST /countries
  # POST /countries.json
  def create
    @country = Country.new(country_params)

    respond_to do |format|
      if @country.save
        format.html { redirect_to @country, notice: 'Country was successfully created.' }
        format.json { render action: 'show', status: :created, location: @country }
      else
        format.html { render action: 'new' }
        format.json { render json: @country.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /countries/1
  # PATCH/PUT /countries/1.json
  def update
    respond_to do |format|
      if @country.update(country_params)
        format.html { redirect_to @country, notice: 'Country was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @country.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /countries/1
  # DELETE /countries/1.json
  def destroy
    @country.destroy
    respond_to do |format|
      format.html { redirect_to countries_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_country
      @country = Country.find_by_name(params[:name])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def country_params
      params.permit(:name, :heat)
    end
end
