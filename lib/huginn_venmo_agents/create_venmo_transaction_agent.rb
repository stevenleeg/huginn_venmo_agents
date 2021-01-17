module Agents
  class CreateVenmoTransactionAgent < Agent
    API_BASE = 'https://api.venmo.com/v1'

    include FormConfigurable

    can_dry_run!

    description <<-MD
      This agent connects your Huginn instance to the
      [unofficial Venmo API](https://github.com/mmohades/VenmoApiDocumentation),
      allowing you to create Venmo transactions by sending it properly
      formatted events. Generally you'll want to use this in combination with a
      Javascript agent, which will allow you to intake arbitrary events and
      properly transform them into the event schema expected by this agent.

      Note that this agent requires you to generate a Venmo access token. This
      can be a bit tricky, but there is a rake task included with the Gem that
      should make the process easier. You'll also need to find your friends'
      Venmo IDs, which is also tricky but has an associated take task included.
      See the [documentation](https://github.com/stevenleeg/huginn_venmo_agents)
      for details on how to accomplish both of these.

      ## Event schema
      This agent accepts events in the following format:
      
          {
            "amount": 15.23,
            "user_id": "987435897345987",
            "note": "Some text goes here"
          }

      Regardless of the result, the agent will _not_ transmit any outgoing
      events. It will, however, log whether or not the query was successful.
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
        'venmo_token' => '{% credential venmo_token %}',
      }
    end

    def check
      if memory['last_success'].nil?
        true
      else
        memory['last_success']
      end
    end

    def receive(incoming_events)
      memory['last_success'] = false

      incoming_events.each do |event|
        if event.payload['amount'] < 0
          error('Disallowing payment (this Agent is too new/dangerous for this to be enabled)')
          next
        elsif agent['user_id'].nil?
          error('Payment requires a user_id key in the calling event')
          next
        elsif agent['note'].nil?
          error('Payment requires a note key in the calling event')
          next
        end

        log("Requesting $#{event.payload['amount']} from #{event.payload['user_id']}")
        resp = HTTP
          .auth("Bearer #{options['venmo_token']}")
          .post("#{API_BASE}/payments", json: {
            note: event.payload['note'],
            amount: event.payload['amount'] * -1,
            metadata: {quasi_cash_disclaimer_viewed: false},
            user_id: event.payload['user_id'],
            audience: event.payload['audience'] || 'private',
          })

        if resp.status >= 200 && resp.status < 300
          log("Success!")
          memory['last_success'] = true
          create_event payload: resp.body.parse
        else
          error("Error creating payment (#{resp.status}): #{resp.body.parse}")
        end
      end
    end
  end
end
