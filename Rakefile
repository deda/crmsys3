# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'

Crmsys::Application.load_tasks

# создание таблиц с нуля
namespace :db do

  desc 'Drops and re create all tables, seeds initial data from db/seeds.rb'
  task :regen do |t|
    Rake::Task["db:migrate:reset"].invoke
    Rake::Task["db:seed"].invoke
  end

end