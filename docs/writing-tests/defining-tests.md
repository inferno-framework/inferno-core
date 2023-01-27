---
title: Defining Groups and Tests
nav_order: 1
parent: Writing Tests
---
# Defining Groups and Tests
{: .no_toc}

## Table of Contents
{: .no_toc .text-delta}

1. TOC
{:toc}
---
## Inline Group and Test Definitions
A `TestGroup` can be added to a `TestSuite` using the `group` method:

```ruby
# lib/us_core_test_kit.rb
module USCoreTestKit
  class USCoreTestSuite < Inferno::TestSuite
    group do
      title 'US Core Patient Group'
    end

    group do
      title 'US Core Condition Group'
    end
  end
end
```

A `Test` can be added to a `TestGroup` using the `test` method:

```ruby
# lib/us_core_test_kit.rb
module USCoreTestKit
  class USCoreTestSuite < Inferno::TestSuite
    group do
      title 'US Core Patient Group'

      test do
        title 'Server supports Patient Read Interaction'
        input :patient_id

        run do
          # test code goes here
        end
      end

      test do
        title 'Server supports Patient Search by id'
        input :patient_id

        run do
          # test code goes here
        end
      end
    end

    group do
      title 'US Core Condition Group'

      test do
        title 'Server supports Condition Read Interaction'
        input :condition_id

        run do
          # test code goes here
        end
      end

      test do
        title 'Server supports Condition Search by Patient'
        input :patient_id

        run do
          # test code goes here
        end
      end
    end
  end
end
```
This test suite is already getting pretty long. We can improve the organization
using externally defined groups and tests.

## External Group and Test Definitions
Let's move the Patient and Condition groups into their own files, and assign
them ids.

```ruby
# lib/us_core_test_kit/us_core_patient_group.rb
module USCoreTestKit
  class USCorePatientGroup < Inferno::TestGroup
    title 'US Core Patient Group'
    id :us_core_patient

    test do
      title 'Server supports Patient Read Interaction'
      input :patient_id

      run do
        # test code goes here
      end
    end

    test do
      title 'Server supports Patient Search by id'
      input :patient_id

      run do
        # test code goes here
      end
    end
  end
end

# lib/us_core_test_kit/us_core_condition_group.rb
module USCoreTestKit
  class USCoreConditionGroup < Inferno::TestGroup
    title 'US Core Condition Group'
    id :us_core_condition

    test do
      title 'Server supports Condition Read Interaction'
      input :condition_id

      run do
        # test code goes here
      end
    end

    test do
      title 'Server supports Condition Search by Patient' 
      input :patient_id

      run do
        # test code goes here
      end
    end
  end
end
```

Now the suite can include these groups without having to contain their entire
definitions:

```ruby
# lib/us_core_test_kit.rb
require_relative 'us_core_test_kit/us_core_patient_group'
require_relative 'us_core_test_kit/us_core_condition_group'

module USCoreTestKit
  class USCoreTestSuite < Inferno::TestSuite
    group from: :us_core_patient
    group from: :us_core_condition
  end
end
```

The tests can also be moved out of their groups:

```ruby
# lib/us_core_test_kit/us_core_patient_read_test.rb
module USCoreTestKit
  class USCorePatientReadTest < Inferno::Test
    title 'Server supports Patient Read Interaction'
    id :us_core_patient_read
    input :patient_id

    run do
      # test code goes here
    end
  end
end

# lib/us_core_test_kit/us_core_patient_search_by_id_test.rb
module USCoreTestKit
  class USCorePatientSearchByIdTest < Inferno::TestGroup
    title 'Server supports Patient Search by id'
    id :us_core_patient_search_by_id
    input :patient_id

    run do
      # test code goes here
    end
  end
end

# lib/us_core_test_kit/us_core_patient_group.rb
require_relative 'us_core_patient_read_test'
require_relative 'us_core_patient_search_by_id_test'

module USCoreTestKit
  class USCorePatientGroup < Inferno::TestGroup
    title 'US Core Patient Group'
    id :us_core_patient

    test from: :us_core_patient_read
    test from :us_core_patient_search_by_id
  end
end
```

When importing a group, its optional children can be omitted:
```ruby
group from: :us_core_patient, exclude_optional: true
```
