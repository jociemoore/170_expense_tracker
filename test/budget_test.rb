ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../budget"

class BudgetTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def session
    last_request.env["rack.session"]
  end

  def add_expenses
    post "/add-transaction", params={:month=>"01", :day=>"01", :year=>"2001", :payee=>"Forever 21", :amount=>"100"}
    post "/add-transaction", params={:month=>"02", :day=>"02", :year=>"2001", :payee=>"David's Tea", :amount=>"50"}
    post "/add-transaction", params={:month=>"01", :day=>"03", :year=>"2011", :payee=>"Sports Authority", :amount=>"25"}
  end

  def test_index
    get "/"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<form action=\"/add-transaction\""
  end

  def test_add_transaction
    post "/add-transaction", params={:month=>"01", :day=>"01", :year=>"2001", :payee=>"Forever 21", :amount=>"101"}
    assert_equal "01/01/2001", session[:expenses][0][:date]
    assert_equal 302, last_response.status
  end

  def test_total_adds
    get "/"
    post "/add-transaction", params={:month=>"01", :day=>"01", :year=>"2001", :payee=>"Forever 21", :amount=>"101"}
    get last_response["Location"]
    assert_includes last_response.body, "Total: $101"
    post "/add-transaction", params={:month=>"01", :day=>"01", :year=>"2001", :payee=>"David's Tea", :amount=>"2"}
    get last_response["Location"]
    assert_includes last_response.body, "Total: $103"
  end

  def test_sort_by_years
    add_expenses
    post "/sort/year"
    get last_response["Location"]
    assert_equal ["2001", "2011"], session[:timeperiods]
    assert_includes last_response.body, "Total: $150"
  end

  def test_sort_by_months
    add_expenses
    post "/sort/month"
    get last_response["Location"]
    assert_equal ["01", "02"], session[:timeperiods]
    assert_includes last_response.body, "Total: $125"
  end

  def test_month_error
    post "/add-transaction", params={:month=>"21", :day=>"01", :year=>"2001", :payee=>"Forever 21", :amount=>"101"}
    assert_includes last_response.body, "Please enter a month between the 01 and 12."
  end

  def test_days_error
    post "/add-transaction", params={:month=>"01", :day=>"45", :year=>"2001", :payee=>"Forever 21", :amount=>"101"}
    assert_includes last_response.body, "Please enter a day between the 1st and 31st."
  end

  def test_year_error
    post "/add-transaction", params={:month=>"01", :day=>"01", :year=>"2021", :payee=>"Forever 21", :amount=>"101"}
    assert_includes last_response.body, "Wow, can you time travel?! Please enter a date in the past."
  end

  def test_with_decimal
    post "/add-transaction", params={:month=>"01", :day=>"01", :year=>"2005", :payee=>"Forever 21", :amount=>"101.11"}
    assert_equal 101.11, session[:expenses][0][:amount]
  end

  def test_one_decimal
    post "/add-transaction", params={:month=>"01", :day=>"01", :year=>"2005", :payee=>"Forever 21", :amount=>"101.1"}
    get last_response["Location"]
    assert_includes last_response.body, "$101.10"
  end

  def test_with_dollar_sign
    post "/add-transaction", params={:month=>"01", :day=>"01", :year=>"2005", :payee=>"Forever 21", :amount=>"$101.11"}
    assert_equal 101.11, session[:expenses][0][:amount]
    get last_response["Location"]
    assert_includes last_response.body, "$101.11"
  end
end
