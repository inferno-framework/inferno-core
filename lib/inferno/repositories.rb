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
