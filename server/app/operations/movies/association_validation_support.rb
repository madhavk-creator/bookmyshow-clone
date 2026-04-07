module Movies
  module AssociationValidationSupport
    VALID_LANGUAGE_TYPES = %w[original dubbed subtitled].freeze
    VALID_CAST_ROLES     = %w[actor director producer writer composer].freeze

    private

    def validate_language_entries(ctx, entries)
      normalized_entries = Array(entries)
      return [ true, [] ] if normalized_entries.empty?

      invalid_messages = []

      language_ids = normalized_entries.map { |entry| entry[:language_id] || entry["language_id"] }.compact.uniq
      valid_ids = Language.where(id: language_ids).pluck(:id)
      unknown_ids = language_ids - valid_ids

      invalid_messages << "Unknown language IDs: #{unknown_ids.join(', ')}" if unknown_ids.any?

      normalized_payload = normalized_entries.map.with_index do |entry, index|
        language_id = entry[:language_id] || entry["language_id"]
        type = entry[:type] || entry["type"]

        invalid_messages << "Entry #{index}: language_id is required" if language_id.blank?
        invalid_messages << "Entry #{index}: invalid type '#{type}'" unless VALID_LANGUAGE_TYPES.include?(type.to_s)

        {
          language_id: language_id,
          language_type: type
        }
      end

      return [ true, normalized_payload ] if invalid_messages.empty?

      ctx[:errors] = { language_entries: invalid_messages }
      [ false, [] ]
    end

    def validate_format_ids(ctx, format_ids)
      normalized_format_ids = Array(format_ids).compact.uniq
      return [ true, [] ] if normalized_format_ids.empty?

      valid_ids = Format.where(id: normalized_format_ids).pluck(:id)
      invalid_ids = normalized_format_ids - valid_ids

      if invalid_ids.any?
        ctx[:errors] = { format_ids: [ "Unknown format IDs: #{invalid_ids.join(', ')}" ] }
        return [ false, [] ]
      end

      [ true, normalized_format_ids ]
    end

    def validate_cast_member_entries(ctx, members, model: nil, allow_existing_ids: false)
      normalized_members = Array(members)
      return [ true, [] ] if normalized_members.empty?

      invalid_messages = []
      existing_ids = allow_existing_ids ? model.cast_members.pluck(:id) : []
      provided_ids = []

      normalized_payload = normalized_members.map.with_index do |member, index|
        member_id = member[:id] || member["id"]
        name = member[:name] || member["name"]
        role = member[:role] || member["role"]

        invalid_messages << "Entry #{index}: name is required" if name.blank?
        invalid_messages << "Entry #{index}: invalid role '#{role}'" unless VALID_CAST_ROLES.include?(role.to_s)

        if member_id.present?
          invalid_messages << "Entry #{index}: id is not allowed" unless allow_existing_ids

          if allow_existing_ids
            invalid_messages << "Entry #{index}: unknown cast member ID #{member_id}" unless existing_ids.include?(member_id)
            invalid_messages << "Entry #{index}: duplicate cast member ID #{member_id}" if provided_ids.include?(member_id)
            provided_ids << member_id
          end
        end

        {
          id: member_id,
          name: name,
          role: role,
          character_name: member[:character_name] || member["character_name"]
        }
      end

      return [ true, normalized_payload ] if invalid_messages.empty?

      ctx[:errors] = { cast_members: invalid_messages }
      [ false, [] ]
    end
  end
end
