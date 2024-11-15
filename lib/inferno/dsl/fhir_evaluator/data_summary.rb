module FhirEvaluator
  # DataSummary represents the results of performing data characterization.
  class DataSummary
    attr_accessor :root_resource_ids, # All Example (root resource) Ids
                  :root_bundle_resource_ids, # All Example (root resource) Ids that are Bundle
                  :domain_resource_ids,   # Domain resource Ids from root and child resources (exclude Bundle)
                  :resource_profile_map,  # Resources and corresponding profiles
                  :resource_patient_map,  # Resources and corresponding Patient Ids as subject
                  :resource_subject_map   # Resources and corresponding subject

    def initialize(data)
      @root_resource_ids = []
      @root_bundle_resource_ids = []
      @domain_resource_ids = []
      @resource_profile_map = []
      @resource_patient_map = []
      @resource_subject_map = []

      validate(data)
      summarize(data)
    end

    def validate(data)
      # Check if duplicate Ids exist for same Resource Type in a data set
      r_ids = data.map { |r| resources_ids(r) }.flatten

      if r_ids.uniq == r_ids
        puts 'No duplicate Ids found. Proceed to evaluate..'
      else
        dup = r_ids.detect { |r| r_ids.count(r) > 1 }
        puts "Warning: Found duplicate resource Ids: #{dup}. Please validate Examples before running FHIR Evaluator."
      end
    end

    def summarize(data)
      @root_resource_ids = data.map { |r| { type: r.resourceType, id: r.id } }
      @root_bundle_resource_ids = data.map { |r| { type: r.resourceType, id: r.id } if r.resourceType == 'Bundle' }

      id_hash = Hash.new { |hash, key| hash[key] = [] }
      data.map { |e| resources(e) }.flatten.each do |item|
        id_hash[item[:type]] << item[:id]
      end
      @domain_resource_ids = id_hash.to_a

      @resource_profile_map = data.map { |e| resources_profiles(e) }.flatten.uniq
      @resource_patient_map = data.map { |e| resources_patients(e) }.flatten.uniq
      @resource_subject_map = data.map { |e| resources_subjects(e) }.flatten.uniq
    end

    def resources_ids(resource)
      if resource.resourceType == 'Bundle'
        resource.entry.map { |e| resources_ids(e.resource) }.flatten
      else
        "#{resource.resourceType}/#{resource.id}"
      end
    end

    def resources(resource)
      if resource.resourceType == 'Bundle'
        resource.entry.map { |e| resources(e.resource) }.flatten
      else
        { type: resource.resourceType, id: resource.id }
      end
    end

    def resources_profiles(resource)
      if resource.resourceType == 'Bundle'
        resource.entry.map { |e| resources_profiles(e.resource) }.flatten.uniq
      elsif resource.meta&.profile
        { resource_id: resource.id, profile: resource.meta&.profile }
      end
    end

    def resources_patients(resource)
      if resource.resourceType == 'Bundle'
        resource.entry.map { |e| resources_patients(e.resource) }.flatten.uniq
      elsif defined? resource.patient.reference
        { resource_id: resource.id, patient: resource.patient.reference }
      end
    end

    def resources_subjects(resource)
      if resource.resourceType == 'Bundle'
        resource.entry.map { |e| resources_subjects(e.resource) }.flatten.uniq
      elsif defined? resource.subject.reference
        { resource_id: resource.id, subject: resource.subject.reference }
      end
    end

    def to_json(*_args)
      {
        'Resources' => domain_resource_ids.length,
        'Root Resources' => root_resource_ids.length
      }
    end
  end
end
