require File.join(File.dirname(__FILE__), 'test_helper')

class User < ActiveRecord::Base
  cattr_accessor :current
  has_many :things
  has_many :items
  belongs_to :role
end

class Plan < ActiveRecord::Base
  has_many :hosts
end

class Host < ActiveRecord::Base
  cattr_accessor :current
  belongs_to :plan
end

class Thing < ActiveRecord::Base
  limit_by_scope :user
  belongs_to :user
end

class Item < ActiveRecord::Base
  limit_by_scope :host, :delegate => :plan, :error => 'Quota met: #{self.class.limit}, please upgrade your plan to add more.'
  belongs_to :host
end

class Role < ActiveRecord::Base
  limit_by_scope :user
  has_one :user
end

class LimitByTest < Test::Unit::TestCase
  fixtures :things, :items, :roles, :users, :hosts, :plans

  def test_limit_by_scope_methods_work
    User.current = users(:user_1)
    assert_equal 4, Thing.count
    assert_equal 4, Thing.limit
    assert_equal 0, Thing.available
  end

  def test_limit_by_scope_methods_dont_work_without_scope
    User.current = nil
    assert_raises(LimitByScope::MissingScopeAssociation) do
      Thing.limit
    end
  end

  def test_can_create_within_limit
    User.current = users(:user_1)
    assert Thing.create(:name => 'Thing 1')
  end

  def test_cannot_create_when_over_limit
    User.current = users(:user_1)
    assert_equal "Quota met: 4", Thing.create(:name => 'Thing 2').errors['base']
  end

  def test_use_delegation
    Host.current = hosts(:host_3)
    assert Item.create(:name => 'Foo')
  end

  def test_use_delegate_with_nil_limit
    Host.current = hosts(:host_1)
    [1..50].each{ |i| Item.create(:name => "Foo #{i}") }
    assert Item.create(:name => 'Foo')
  end

  def test_use_delegate_with_limit
    Host.current = hosts(:host_3)
    assert_equal 4, Item.count # should already be 4 items from the fixture
    assert_equal "Quota met: 3, please upgrade your plan to add more.", Item.create(:name => 'Bar').errors['base']
  end
end