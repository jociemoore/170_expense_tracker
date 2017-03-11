require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, "secret"
end

before do
  session[:expenses] ||= []
  session[:timeperiods] ||= []
  session[:filter] ||= "year"
end

helpers do
  def match_year_or_month?(timeperiod, transaction)
    (timeperiod == transaction[:date].slice(-4,4) && session[:filter] == "year") || 
    (timeperiod == transaction[:date].slice(0,2) && session[:filter] == "month")
  end
end

def get_all_timeperiods
  session[:expenses].each_with_object([]) do |transaction, arr|
    if session[:filter] == "year"
      arr << transaction[:date].slice(-4, 4)
    else
      arr << transaction[:date].slice(0, 2)
    end
  end
end

def filter_expenses
  if session[:filter] == "year"
    session[:year_btn_class] = "active"
    session[:month_btn_class] = "inactive"
  else
    session[:year_btn_class] = "inactive"
    session[:month_btn_class] = "active"
  end
  session[:timeperiods] = get_all_timeperiods.uniq.sort
end

def error_message
  if params[:month].to_i > 12
    "Please enter a month between the 01 and 12."
  elsif params[:day].to_i > 31
    "Please enter a day between the 1st and 31st."
  elsif (Time.mktime(params[:year], params[:month], params[:day]) <=> Time.now) > 0
    "Wow, can you time travel?! Please enter a date in the past."
  end
end

def strip_dollar_sign(str_amount)
  if str_amount.include?('$') 
    str_amount.slice(1..-1)
  else
    str_amount
  end
end

get "/" do 
  filter_expenses
  erb :index
end

post "/add-transaction" do
  if error_message
    session[:error] = error_message
    erb :index
  else
    date = "#{params[:month]}/#{params[:day]}/#{params[:year]}"
    payee = params[:payee] 
    amount = strip_dollar_sign(params[:amount]).to_f

    transaction = {:date => date, :payee => payee, :amount => amount}
    session[:expenses] << transaction
    filter_expenses
    session[:message] = "The transaction was added."
    redirect "/"
  end
end

post "/sort/:timeperiod" do
  session[:filter] = params[:timeperiod]
  redirect "/"
end
