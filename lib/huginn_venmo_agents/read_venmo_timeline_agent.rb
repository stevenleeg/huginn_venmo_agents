module Agents
  class ReadVenmoTimelineAgent < Agent
    include FormConfigurable

    API_BASE = 'https://api.venmo.com/v1'

    cannot_receive_events!
    can_dry_run!

    description <<-MD
      This agent connects your Huginn instance to the
      [unofficial Venmo API](https://github.com/mmohades/VenmoApiDocumentation),
      allowing you to periodically fetch your Venmo transaction timeline and
      emit events each time a new transaction is detected.

      Note that this agent requires you to generate a Venmo access token. This
      can be a bit tricky, but there is a rake task included with the Gem that
      should make the process easier. See the
      [documentation](https://github.com/stevenleeg/huginn_venmo_agent) for
      details.

      ## Event schema
      Each time a new transaction has been detected, this agent will emit an
      event containing the raw JSON payload returned by the API for the
      transaction. See the documentation for the
      [transactions list](https://github.com/mmohades/VenmoApiDocumentation#users-transactions-list)
      endpoint for details on what this contains.

      A few notable values within the tx payload:

      * `payment.amount` - The amount of money being sent/received.
      * `payment.status` - Will help you determine whether or not this is a
        pending request for money or a settled transaction.
      * `payment.action` - This, in combination with a key like `payment.actor.username`
        will help you determine whether or not the transaction is you
        requesting/sending money to someone else, or them requesting/sending
        money to you. If you're using this agent to sync transactions with some
        kind of ledger service, you'll generally need this information in order
        to determine whether or not the amount should be multiplied by -1.
    MD

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
