ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually 
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...

  #-----------------------------------------------------------------------------
  # создание тестового аккаунта, админа и пользователя
  def self.set_account_admin_user
    unless $current_account ||= Account.find_by_subdomain('test')
      $current_account = Account.create!(
        :name      => 'Тестовый аккаунт',
        :subdomain => 'test',
        :max_users => 5,
        :end_time  => Date.commercial(3000, 2, 2))
    end
    unless $current_admin ||= User.for_account($current_account).find_by_email('admin@test.com')
      $current_admin = User.for_account($current_account).create!(
        :name                   => 'Администратор',
        :email                  => 'admin@test.com',
        :password               => '1111',
        :password_confirmation  => '1111',
        :email_confirmed        => true,
        :is_admin               => true)
    end
    unless $current_user ||= User.for_account($current_account).find_by_email('user@test.com')
      $current_user = User.for_account($current_account).create!(
        :name                   => 'Пользователь',
        :email                  => 'user@test.com',
        :password               => '1111',
        :password_confirmation  => '1111',
        :email_confirmed        => true,
        :is_admin               => false)
    end
  end
  set_account_admin_user

end
