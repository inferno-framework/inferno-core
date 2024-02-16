require_relative 'repositories/in_memory_repository'
require_relative 'repositories/validate_runnable_reference'
require_relative 'repositories/test_groups'
require_relative 'repositories/test_suites'
require_relative 'repositories/tests'

# Skip loading things which require the db when not necessary, such as CLI
# commands which don't need the db
unless ENV['NO_DB']&.casecmp? 'true'
  require_relative 'repositories/repository'
  require_relative 'repositories/headers'
  require_relative 'repositories/messages'
  require_relative 'repositories/requests'
  require_relative 'repositories/results'
  require_relative 'repositories/session_data'
  require_relative 'repositories/test_runs'
  require_relative 'repositories/test_sessions'
  require_relative 'repositories/validator_sessions'
end

module Inferno
  # Repositories provide an abstraction layer for dealing with entity
  # persistence. All code for interacting with the database lives in
  # repositories. The rest of the codebase interacts with the database through a
  # public api provided by various repositories.
  #
  # **Naming Convention:** A repository should be named the plural version of
  # the entity name. For example:
  #
  # - `TestSessions` is the repsitory for the `TestSession` entity
  # - `TestGroups` is the repository for the `TestGroup` entity
  module Repositories
  end
end
