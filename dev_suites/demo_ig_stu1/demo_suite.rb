require_relative 'groups/demo_group'
require 'sinatra/base'

module DemoIG_STU1 # rubocop:disable Naming/ClassAndModuleCamelCase
  class DemoSuite < Inferno::TestSuite
    title 'Demonstration Suite'

    # Ideas:
    # * Suite metadata (name, associated ig, version, etc etc)
    # * Be able to define new sequences that map inputs, force certain parameters, etc
    # * Allow suites / groups to have inputs (for suites inputs, have it be like what 'url'
    #   is for legacy inferno)
    # * Different types of gruops
    # * Default group?
    # * Sequences in groups should be uniquely identified, basically what inferno 'test cases'
    #   are.  Group id + sequence id.

    # group title: 'the first group',
    #   id: :first_group,
    #   link: 'http://example.com',
    #   description: %( This is the description for the first test! ) do

    # This is a little too simplistic, because we want groups to be able to
    # restrict params, map params, etc

    validator do
      url ENV.fetch('VALIDATOR_URL')
      exclude_message { |message| message.type == 'info' }
    end

    group :simple_group do
      title 'Group 1'
      group from: 'DemoIG_STU1::DemoGroup', title: 'Demo Group Instance 1'
    end

    # Note that in order to support test procedures that run the same group
    # under different conditions, groups in groups need to be considered
    # separate groups (so their results don't collide)
    group :repetitive_group do
      title 'Group 2'
      group from: 'DemoIG_STU1::DemoGroup', id: 'DEF', title: 'Demo Group Instance 2'
      group from: 'DemoIG_STU1::DemoGroup' do
        id 'GHI'
        title 'Demo Group Instance 3'
      end
    end

    class ExampleController
      include Hanami::Action

      def self.call(params)
        new.call(params)
      end

      def call(_params)
        self.body = 'ExampleRoute Response'
      end
    end

    class ExampleApp < Sinatra::Base
      get '/' do
        'App Response'
      end

      get '/2' do
        'App Response 2'
      end
    end

    route :get, '/proc', ->(_env) { [200, {}, ['Proc Response']] }

    route :get, '/controller', ExampleController

    route :all, '/app', ExampleApp

    group do
      id 'wait_group'

      test do
        run { pass }
      end

      test do
        run { wait(identifier: 'abc') }
      end

      test do
        run { cancel }
      end
    end
  end
end
