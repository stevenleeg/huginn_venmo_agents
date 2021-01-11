module Agents
  class VenmoTimelineAgent < Agent
    API_BASE = 'https://api.venmo.com/v1'

    include FormConfigurable

    cannot_receive_events!
    can_dry_run!

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

      if resp.status < 200 || resp.status >= 300
        error("Venmo gave a bad response (#{resp.status}): #{resp.to_s}")
        return
      end

      json_resp = resp.parse
      event_times = []
      json_resp['data'].each do |tx|
        next if memory['latest_tx_datetime'] && tx['date_updated'].to_time.to_i <= memory['latest_tx_datetime']
        event_times << tx['date_updated'].to_time.to_i
        create_event payload: tx
      end

      if event_times.count > 0
        memory['latest_tx_datetime'] = event_times.max
      end
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
      memory['me'] = json_resp['data']['user']['id']
      return memory['me']
    end
  end
end
