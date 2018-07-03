require 'slack-ruby-bot'
require 'json'
require 'awesome_print'

class GithubBot < SlackRubyBot::Bot
  command 'help' do |client, data, _match|
    client.say(text: 'Mes commandes sont `pr_author LOGIN` et `what_to_review LOGIN`.', channel: data.channel)
  end

  command 'pr_author', 'pr_auteur' do |client, data, match|
    wanted_user = match['expression']

    response_body = ''
    count = 0

    hash = fetch_pull_requests
    hash.each do |pull_request|
      next unless pull_request_author(pull_request) == wanted_user &&
                  pull_request_is_open(pull_request)
      count += 1
      response_body += pull_request_to_str(pull_request)
    end

    client.say(text: "#{wanted_user} a #{count} PR ouvertes:\n" + response_body, channel: data.channel)
  end

  command 'what_to_review', 'quoi_regarder', 'quoi_review' do |client, data, match|
    wanted_user = match['expression']

    response_body = ''
    count = 0

    hash = fetch_pull_requests
    hash.each do |pull_request|
      to_review = 0

      next unless pull_request_is_open(pull_request)
      pull_request['requested_reviewers'].each do |requested_reviewer|
        if wanted_user == requested_reviewer['login']
          to_review = 1
          count += 1
        end
      end

      response_body += pull_request_to_str(pull_request) if to_review == 1
    end

    client.say(text: "#{wanted_user} a #{count} PR en tant que reviewer:\n" + response_body, channel: data.channel)
  end
end

def fetch_pull_requests
  return_value = `curl -u #{ENV['USER']} 'https://api.github.com/repos/clicrdv/clicrdv/pulls'`
  JSON.parse(return_value)
end

def pull_request_to_str(pull_request)
  str = "- #{pull_request['title']} #{pull_request['html_url']} "
  if pull_request['requested_reviewers'].count > 0
    str += '( reviewers : '
    pull_request['requested_reviewers'].each do |requested_reviewer|
      str += ' ' + requested_reviewer['login']
    end
    str += ')'
  end
  str + "\n"
end

def pull_request_is_open(pull_request)
  pull_request['state'] == 'open'
end

def pull_request_author(pull_request)
  pull_request['user']['login']
end

GithubBot.run
