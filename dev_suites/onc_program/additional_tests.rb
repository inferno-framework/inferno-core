module ONCProgram
  class AdditionalTests < Inferno::TestGroup
    title 'Additional Tests'
    description <<~DESCRIPTION
      Not all requirements that need to be tested fit within the previous
      scenarios.  The tests contained in this section addresses remaining
      testing requirements. Each of these tests need to be run
      independently.  Please read the instructions for each in the 'About'
      section, as they may require special setup on the part of the tester.
    DESCRIPTION

    id :additional_tests

    group from: :onc_standalone_public_launch
    group from: :token_revocation
    group from: :smart_invalid_aud
    group from: :smart_invalid_launch
    group from: :onc_visual_inspection
  end
end
