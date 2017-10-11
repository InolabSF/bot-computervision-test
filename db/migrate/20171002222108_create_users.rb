class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.integer :user_id
      t.string :name
      t.string :gender
      t.integer :age
      t.integer :travel_id

      t.timestamps
    end
  end
end
