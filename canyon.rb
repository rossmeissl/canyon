require 'sinatra/base'
require 'remote_table'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/array/conversions'
require 'active_support/core_ext/string/inflections'

class CanyonApp < Sinatra::Base
  get '/' do
    days = RemoteTable.new 'https://docs.google.com/spreadsheet/pub?hl=en_US&hl=en_US&key=0AtyCBJLCFHlwdHRsU0VWRFkySk1ydjB3REdBX3VYR0E&single=true&gid=2&output=csv'
    erb :index, :locals => { :days => days }
  end

  helpers do
    %w(breakfast lunch dinner).each do |meal|
      define_method "#{meal}?".to_sym do |day|
        (1..5).any? do |i|
          day["#{meal.titlecase} #{i}"].present?
        end
      end
  
      define_method meal.to_s do |day|
        day.slice(*(1..5).map {|i| "#{meal.titlecase} #{i}"}).values.select(&:present?).map do |b|
          erb :li, :locals => { :content => b }
        end.join("\n")
      end
    end
    %w(midway endpoint).each do |place|
      define_method "#{place}_hike?".to_sym do |day, num|
        day["#{place.titlecase} hike #{num}"].present?
      end
    end
    def start_hike?(day)
      day["Start hike"].present?
    end
    def layover?(day)
      day['Total river mileage'] == "0"
    end
    def mileage(day)
      if layover?(day)
        'Layover'
      else
        "#{day['Total river mileage']} mi."
      end
    end
    def start(day)
      day['Mile #'].to_f - day['Total river mileage'].to_f
    end
    def finish(day)
      day['Mile #'].to_f
    end
    def summary(day)
      if layover?(day)
        s = "#{day['Put in at']} layover"
      else
        s = "#{day['Put in at']} to #{day['Take out at']}"
      end
      s += " hiking #{[day['Midway hike?'], day['Endpoint hike?']].select(&:present?).to_sentence}" if hike?(day)
      s
    end
    def hike?(day)
      day['Midway hike?'].present? || day['Endpoint hike?'].present?
    end
    def cooks(day)
      day.slice(*(1..3).map { |n| "Cook #{n}" }).values.to_sentence
    end
  end
end
