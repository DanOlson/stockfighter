module Stockfighter
  class Settings
    ATTRIBUTES = [
      :account,
      :venue,
      :symbol,
      :api_key,
      :instance_id,
      :level
    ]

    attr_accessor *ATTRIBUTES
  end
end
