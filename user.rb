require 'sequel'

DB = Sequel.sqlite

DB.create_table :teams do
  primary_key :id
  integer :team_id
  string :token
end

class Team < Sequel::Model
end
