require File.join(File.dirname(__FILE__), 'test_helper')

class Plan < ActiveRecord::Base
  has_many :hosts
end

class Host < ActiveRecord::Base
  cattr_accessor :current
  belongs_to :plan
end

class Item < ActiveRecord::Base
  acts_as_scoped :host
  limit_by_scope :host, :delegate => :plan, :error => 'Quota met: #{self.class.limit}, please <a href=\"/upgrade?id=#{self.host.id}\">upgrade</a> your plan to add more.'
  belongs_to :host
end

class LimitByTest < Test::Unit::TestCase
  fixtures :items, :hosts, :plans

  def test_limit_with_aa_scoped
    Host.current = hosts(:host_3)
    assert_equal 1, Item.count # should only be 1 item from the fixtures
    assert Item.create(:name => 'Foo')
  end

  def test_limit_with_aa_scoped
    Host.current = hosts(:host_3)
    assert_equal 3, Item.count # should only be 3 items from the fixtures
    assert_equal 'Quota met: 3, please <a href="/upgrade?id=3">upgrade</a> your plan to add more.', Item.create(:name => 'Bar').errors['base']
  end
end