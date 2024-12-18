require_relative 'entities/attributes'
require_relative 'entities/has_runnable'
require_relative 'entities/entity'
require_relative 'entities/header'
require_relative 'entities/ig'
require_relative 'entities/message'
require_relative 'entities/request'
require_relative 'entities/result'
require_relative 'entities/session_data'
require_relative 'entities/test'
require_relative 'entities/test_group'
require_relative 'entities/test_kit'
require_relative 'entities/test_run'
require_relative 'entities/test_session'
require_relative 'entities/test_suite'
require_relative 'entities/validator_session'

module Inferno
  # Entities are domain objects whose identity is based on an `id`. Entities
  # don't know anything about persistence, which is handled by Repositories.
  module Entities
  end
end
