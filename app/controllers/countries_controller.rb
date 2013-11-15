require "httparty"
require 'open-uri'

class CountriesController < ApplicationController
  before_action :set_country, only: [:show, :edit, :update, :destroy]

  # GET /countries
  # GET /countries.json
  def index
    @countries = Country.all
  end

  # GET /countries/1
  # GET /countries/1.json
  #this needs to take the name of the country, match it to the name in the database
  def show
    @country = Country.find_by_name(params[:name])
    @country_news = []
    # if response = HTTParty.get("http://ajax.googleapis.com/ajax/services/search/news?v=1.0&q=#{params[:name]}")
    #google news api code
    country_name = URI::encode(@country.name)
    response = HTTParty.get("http://ajax.googleapis.com/ajax/services/search/news?v=1.0&q=#{country_name}")
    @country_news = JSON.parse(response.body)

    #NYT api response code
    country_articles=HTTParty.get("http://api.nytimes.com/svc/search/v2/articlesearch.json?q=#{country_name}&begin_date=20131001&api-key=ae59fa9ced00c8e0934ee66358d80da6:1:68403659")
    @country_NYT=JSON.parse(country_articles.body)

    #render :json => @country_NYT


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
      params.permit(:name)
    end
end
