class CreateStrategy
  def initialize
    @strategy = FactoryBot.strategy_by_name(:create).new
  end

  delegate :association, to: :@strategy

  def result(evaluation)
    result = nil
    evaluation.object.tap do |instance|
      evaluation.notify(:after_build, instance)
      evaluation.notify(:before_create, instance)
      result = evaluation.create(instance)
      evaluation.notify(:after_create, result)
    end

    result
  end

  # breaking change in factory_bot 6.2.1
  # https://github.com/thoughtbot/factory_bot/issues/1536
  def to_sym
    :repo_create
  end
end

FactoryBot.register_strategy(:repo_create, CreateStrategy)
