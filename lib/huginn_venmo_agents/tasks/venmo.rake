require 'huginn_venmo_agents'

def generate_device_id
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

namespace :venmo do
  API_BASE = 'https://api.venmo.com/v1'

  task search: :environment do
    print "Venmo auth token: "
    access_token = STDIN.gets.chomp

    print "Enter username: "
    query = STDIN.gets.chomp

    resp = HTTP
      .auth("Bearer #{access_token}")
      .get("#{API_BASE}/users", json: {
        query: query,
        limit: 5,
        type: 'username',
      })

    if resp.status < 200 || resp.status >= 300
      puts("Bad response from Venmo (#{resp.status}): #{resp.body.parse}")
      exit
    end

    puts resp.to_s
  end

  task authenticate: :environment do
    device_id = generate_device_id
    puts "Your device ID is #{device_id} (save this!)"
    print "Venmo Username: "
    username = STDIN.gets.chomp
    print "Venmo Password: "
    password = STDIN.gets.chomp

    puts("Requesting an auth token with the provided credentials...")
    resp = HTTP
      .headers('device-id' => device_id)
      .post("#{API_BASE}/oauth/access_token", json: {
        phone_email_or_username: username,
        client_id: '1',
        password: password,
      })

    if resp.code == 201
      json_resp = resp.body.parse
      puts("Your access token is #{json_resp['access_token']}")
      puts("Please keep this token safe! It grants access to pretty much all of Venmo's functionality (including sending money!!)")
    elsif resp.code == 400
      puts("Your username/password was incorrect. Aborting!")
    elsif resp.code == 401
      otp_secret = resp.headers['venmo-otp-secret']
      puts otp_token

      # Send off a text to their phone
      resp = HTTP
        .headers('device-id' => device_id, 'venmo-otp-secret' => otp_secret)
        .post("#{API_BASE}/account/two-factor/token", json: {
          phone_email_or_username: username,
          client_id: '1',
          password: password,
        })

      if resp.code == 201
        puts("Looks like you have 2FA enabled, please enter the auth code texted to your phone.")
        print "Auth code: "
        auth_code = STDIN.gets.chomp

        resp = HTTP
          .headers('device-id' => device_id, 'venmo-otp-secret' => otp_secret, 'Venmo-Otp' => auth_code)
          .post("#{API_BASE}/oauth/access_token?client_id=1", json: {
            phone_email_or_username: username,
            client_id: '1',
            password: password,
          })

        if resp.code == 201
          json_resp = resp.body.parse
          puts("Your access token is #{json_resp['access_token']}")
          puts("Please keep this token safe! It grants access to pretty much all of Venmo's functionality (including sending money!!)")
        else
          puts("Wonky response code from Venmo (#{resp.code}): #{resp.to_s}")
        end
      elsif resp.code == 400
        puts("Looks like your 2FA session expired. Try again.")
      else
        puts("Wonky response code from Venmo (#{resp.code}): #{resp.to_s}")
      end
    else
      puts("Wonky response code from Venmo (#{resp.code}): #{resp.to_s}")
    end
  end
end
