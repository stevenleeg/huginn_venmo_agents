# Venmo Agents
This gem implements agents for [Huginn](https://github.com/huginn/huginn) which provide an interface for interacting with the [unofficial Venmo API](https://github.com/mmohades/VenmoApiDocumentation):

* `ReadVenmoTimelineAgent` - Allows you to monitor your Venmo timeline for new transactions.
* `CreateVenmoTransactionAgent` - Allows you to request money from other users on Venmo.

## Installation
Like any other Huginn agent, you may install this agent by adding the following to your `.env` file:

```
ADDITIONAL_GEMS=huginn_venmo_agents
```

or, if you wish to stay on the bleeding edge:

```
ADDITIONAL_GEMS=huginn_venmo_agents(git:https://github.com/stevenleeg/huginn_venmo_agent.git)
```

## Usage
### Access Token
Each of the agents provided by this gem require a Venmo access token. This part is a bit tricky, but I've included a Rake task that should hopefully make the process easier. After installing the gem, run the following command in the directory Huginn is installed in:

```
$ rake venmo:authenticate
```

You'll be prompted to enter your username, password and possibly a 2FA token in order to generate the access token that can be used with these agents. You'll likely want to store these in a credential that can be reused between multiple agents.

**NOTE:** Your Venmo access token is a very important credential that *must* be kept secret. If a malicious actor were to find this secret, they can do anything you can do with the actual Venmo app. *This includes sending money!* While there are some safeguards in place (ie daily transaction limits), you should be extra super duper careful to ensure this token does not get leaked out of your Huginn instance. I take no responsibility for any security issues that may arise from the usage of this Gem.

### Finding User IDs
In order to begin sending requests via the `CreateVenmoTransaction` agent, you'll need to find your friends' Venmo user IDs. I haven't yet found a way to do this outside of the API (if anyone knows please open an issue!), however this gem includes a rake task that should hopefully make the process easier. Run the following command in the directory Huginn is installed in:

```
$ rake venmo:search
```

You will be prompted to enter your Venmo auth token and for a Venmo username. The script will then ping the Venmo search API and return the results, within which you can find the user ID that can be used to make transactions.
