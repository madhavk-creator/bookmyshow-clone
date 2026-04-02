
class ApplicationPolicy
  attr_reader :current_user, :record

  def initialize(current_user, record)
    @current_user = current_user
    @record       = record
  end

  def index?   = false
  def show?    = false
  def create?  = false
  def update?  = false
  def destroy? = false

  class Scope
    def initialize(current_user, scope)
      @current_user = current_user
      @scope        = scope
    end

    def resolve
      raise NotImplementedError, "#{self.class} must implement #resolve"
    end

    private

    attr_reader :current_user, :scope
  end
end