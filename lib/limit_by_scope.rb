# Copyright (c) 2007 Flinn Mueller
# Released under the MIT License.  See the MIT-LICENSE file for more details.

module LimitByScope #:nodoc:
  class MissingScopeAssociation < RuntimeError; end
  class MissingLimitColumn < RuntimeError; end

  def self.append_features(base)
    super
    base.extend(ClassMethods)
  end
    
  module ClassMethods
    # limited_by(scope = :user, options = {})
    #
    # Options are:
    # * <tt>:id</tt>: scoped foreign key, defaults to association.foreign_key
    # * <tt>:class_name</tt>: class name of the current scope class, defaults to association.classify
    # * <tt>:class_id</tt>: identifier method for current scope class, defaults to primary_key
    # * <tt>:current</tt>: method to call the current scope object, defaults to :current
    # * <tt>:column</tt>: column used for quota limit, defaults to "#{scope_association}_limit"
    # * <tt>:delegate</tt>: association to delegate limit calls to
    # * <tt>:error</tt>: error message to display when quota has been reached, defaults to 'Quota met #{self.class.limit}' (will interpolate)

    def limit_by_scope(scope_association = :user, options = {})
      scope_id = (options.delete(:id) || scope_association).to_s.foreign_key
      scope_class_name = (options.delete(:class_name) || scope_association).to_s.classify
      scope_class_id = options.delete(:class_id) || scope_class_name.constantize.primary_key
      scope_current = options.delete(:current) || :current
      scope_delegate = options.delete(:delegate)
      limit_column = options.delete(:column) || "#{self.to_s.downcase}_limit"
      limit_error = options.delete(:error) || 'Quota met: #{self.class.limit}'

      current_scope_with_delegate = [scope_class_name, scope_current]
      current_scope_with_delegate << scope_delegate unless scope_delegate.nil?
      current_scope_with_delegate = current_scope_with_delegate.join(".")

      self.class_eval <<-EOV
        validate :validate_limits

        def validate_limits
          errors.add_to_base("#{limit_error}") unless self.class.limit.blank? || self.class.limit > self.class.count
        end

        class << self
          def current_scope_with_delegate
            #{current_scope_with_delegate} || raise(MissingScopeAssociation, "Current scope is missing!")
          end
  
          def limit
            current_scope_with_delegate.send(:#{limit_column}) || nil
          end

          def available
            limit - count
          end
        
          def capacity
            (limit == 0 ? 100 : count / limit)
          end
        end
      EOV
    end
  end
end
