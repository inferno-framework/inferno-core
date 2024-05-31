module DemoIG_STU1 # rubocop:disable Naming/ClassAndModuleCamelCase
  class AuthInputGroup < Inferno::TestGroup
    id :auth_input_demo
    title 'Auth Input Demo'

    test do
      title 'Public Auth'
      id :public_auth
      input :public_auth_input,
            type: :auth_input,
            options: {
              sub_inputs: [
                {
                  name: :auth_type,
                  value: 'public',
                  locked: true
                }
              ]
            }
      run { pass }
    end

    test do
      title 'Symmetric Confidential Auth'
      id :symmetric_auth
      input :symmetric_auth_input,
            type: :auth_input,
            options: {
              sub_inputs: [
                {
                  name: :auth_type,
                  value: 'symmetric',
                  locked: true
                }
              ]
            }
      run { pass }
    end

    test do
      title 'Asymmetric Confidential Auth'
      id :asymmetric_auth
      input :asymmetric_auth_input,
            type: :auth_input,
            options: {
              sub_inputs: [
                {
                  name: :auth_type,
                  value: 'asymmetric',
                  locked: true
                }
              ]
            }
      run { pass }
    end
  end
end
