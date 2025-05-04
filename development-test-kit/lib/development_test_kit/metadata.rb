require_relative 'version'

module DevelopmentTestKit
  class Metadata < Inferno::TestKit
    id :development_test_kit
    title 'Development Test Kit'
    description <<~DESCRIPTION
      A collection of example test suites for Inferno Core development and testing.
      
      This test kit contains various example suites that demonstrate
      different features and capabilities of the Inferno testing framework.
      It is designed to be used with a local copy of Inferno Core for development purposes.

      ## Included Test Suites

      - **Infrastructure Test Suite**: An internal test suite to verify that inferno infrastructure works
      - **Demonstration Suite**: Development suite for testing standard inputs and results
      - **AuthInfo Suite**: Demonstrates authentication information handling
      - **Custom Result Suite**: Shows custom result handling
      - **Options Suite**: Demonstrates suite options functionality
      - **Requirements Suite**: Shows requirements verification
      - **Validator Suite**: Makes calls to the HL7 Validator
    DESCRIPTION

    suite_ids [
      :infra_test,          # From DevelopmentTestKit::InfrastructureSuite
      :demo,                # From DevelopmentTestKit::DemoSuite
      :auth_info,           # From DevelopmentTestKit::AuthInfoSuite
      :custom_result_suite, # From DevelopmentTestKit::CustomResultSuite
      :options,             # From DevelopmentTestKit::OptionsSuite
      :ig_requirements,     # From DevelopmentTestKit::RequirementsSuite
      :dev_validator        # From DevelopmentTestKit::ValidatorSuite
    ]
    tags ['Development', 'Examples']
    last_updated LAST_UPDATED
    version VERSION
    maturity 'Low'
    authors ['Inferno Team']
    # repo 'https://github.com/inferno-framework/inferno-core'
  end
end
