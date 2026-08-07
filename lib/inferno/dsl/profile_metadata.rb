module Inferno
  module DSL
    # A ProfileMetadata object is a small, inheritable data holder for generated metadata about a
    # profile or a group of tests -- most notably the Must Support metadata consumed by
    # {MustSupportAssessment#missing_must_support_elements} and
    # {Assertions#assert_must_support_elements_present} via their `metadata:` argument, alongside
    # whatever other generated metadata a test kit needs to carry around (searches, bindings,
    # references, etc).
    #
    # It exists so that test kits don't need to reach for `OpenStruct` (which accepts any attribute
    # silently, making typos and generator/consumer drift hard to catch) or hand-roll their own
    # version of this exact pattern.
    #
    # Test kits define a subclass and declare whatever attributes they need with `.attribute`.
    # `must_supports` is always available, since it's the attribute Inferno's Must Support logic
    # reads:
    #
    #   class GroupMetadata < Inferno::DSL::ProfileMetadata
    #     attribute :searches
    #     attribute :bindings
    #   end
    #
    #   metadata = GroupMetadata.from_file('path/to/generated/metadata.yml')
    #   metadata.must_supports #=> { elements: [...], extensions: [...], slices: [...] }
    #
    # @see MustSupportAssessment#missing_must_support_elements
    class ProfileMetadata
      class << self
        # The full list of attribute names declared on this class and its ancestors.
        # @return [Array<Symbol>]
        def attribute_names
          @attribute_names ||= superclass.respond_to?(:attribute_names) ? superclass.attribute_names.dup : []
        end

        # Declare an attribute that instances of this class (and subclasses) may be initialized with.
        # @param name [Symbol]
        # @return [void]
        def attribute(name)
          name = name.to_sym
          attribute_names << name unless attribute_names.include?(name)
          attr_accessor name
        end

        # Build an instance from a YAML file, eg one written by a metadata generator.
        # @param path [String, Pathname]
        # @return [ProfileMetadata]
        def from_file(path)
          new(YAML.load_file(path, aliases: true))
        end
      end

      # Profile identity, mirroring fields read directly off the FHIR StructureDefinition
      # (`resource` is the resource type the profile constrains, ie `profile.type`).
      attribute :resource
      attribute :profile_url
      attribute :profile_name
      attribute :profile_version

      attribute :must_supports

      # @param metadata [Hash] a hash of attribute name/value pairs. Keys not declared with
      #   `.attribute` raise an error, so that a mismatch between a metadata generator and this
      #   class's declared attributes is caught immediately rather than silently ignored.
      def initialize(metadata = {})
        metadata.each do |key, value|
          key = key.to_sym
          raise "Unknown #{self.class} attribute: #{key}" unless self.class.attribute_names.include?(key)

          public_send(:"#{key}=", value)
        end

        self.must_supports ||= {}
      end

      # @return [Hash] the declared attributes and their current values, omitting unset (nil) ones
      def to_hash
        self.class.attribute_names.each_with_object({}) do |name, hash|
          value = public_send(name)
          hash[name] = value unless value.nil?
        end
      end
    end
  end
end
