ActiveRecord::Schema.define(:version => 1) do

  create_table :things, :force => true do |t|
    t.column :name, :string
    t.column :user_id, :integer
  end

  create_table :items, :force => true do |t|
    t.column :name, :string
    t.column :user_id, :integer
    t.column :host_id, :integer
  end

  create_table :roles, :force => true do |t|
    t.column :name, :string
  end

  create_table :users, :force => true do |t|
    t.column :name, :string
    t.column :description, :text
    t.column :role_id, :integer
    t.column :account_id, :integer
    t.column :thing_limit, :integer
  end

  create_table :hosts, :force => true do |t|
    t.column :name, :string
    t.column :plan_id, :integer
  end

  create_table :plans, :force => true do |t|
    t.column :name, :string
    t.column :item_limit, :integer
  end
end