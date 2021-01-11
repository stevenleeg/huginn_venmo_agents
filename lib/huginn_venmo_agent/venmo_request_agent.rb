module Agents
  class VenmoRequestAgent < Agent
    API_BASE = 'https://api.venmo.com/v1'

    include FormConfigurable

    can_dry_run!
    cannot_be_scheduled!

    def working?
      true
    end

    def default_options
      {}
    end

    form_configurable :venmo_token
    def validate_options
      if options['venmo_token'].blank?
        errors.add(:base, 'Venmo access token is required')
      end
    end

    def default_options
      {
        'venmo_token' => '{% credential VENMO_TOKEN %}',
      }
    end

    def check
      memory['last_check'] = DateTime.now.to_i
      resp = HTTP
        .auth("Bearer #{interpolated['venmo_token']}")
        .get("#{API_BASE}/stories/target-or-actor/#{my_id}")

      log(resp.parse)
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        if event.payload['amount'].nil? || event.payload['amount'] < 0
          error('Disallowing payment (this Agent is too new/dangerous for this to be enabled)')
          next
        elsif event.payload['user_id'].nil?
          error('Payment requires a user_id key in the calling event')
          next
        elsif event.payload['note'].nil?
          error('Payment requires a note key in the calling event')
          next
        end

        log("Requesting $#{event.payload['amount']} from #{event.payload['user_id']}")
        resp = HTTP
          .auth("Bearer #{interpolated['venmo_token']}")
          .post("#{API_BASE}/payments", json: {
            note: event.payload['note'],
            amount: event.payload['amount'] * -1,
            metadata: {quasi_cash_disclaimer_viewed: false},
            user_id: event.payload['user_id'],
            audience: event.payload['audience'] || 'private',
          })

        if resp.status >= 200 && resp.status < 300
          log("Success!")
          create_event payload: resp.parse
        else
          error("Error creating payment (#{resp.status}): #{resp.parse}")
        end
      end
    end

    def self.generate_device_id
      random_string = '88884260-05O3-8U81-58I1-2WA76F357GR9'.split('').map do |char|
        if /^[0-9]$/.match?(char)
          (0..9).to_a.sample
        elsif char == '-'
          '-'
        else
          ('A'..'Z').to_a.sample
        end
      end

      random_string.join('')
    end

    private

    # Returns the ID of the currently signed in user
    def my_id
      if !memory['me'].nil?
        return memory['me']
      end

      resp = HTTP
        .auth("Bearer #{interpolated['venmo_token']}")
        .get("#{API_BASE}/me")

      json_resp = resp.parse
      memory['me'] = resp['user']['id']
      return memory['me']
    end
  end
end
