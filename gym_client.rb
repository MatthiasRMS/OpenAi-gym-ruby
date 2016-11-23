require 'rest-client'
require 'json'


$logger = Logger.new File.new('file.log')

class Client
  attr_reader :remote_base

  def initialize(remote_base)
    @remote_base = remote_base
    @session =  RestClient::Resource.new(remote_base, :headers => {'Content-type': 'application/json'})
  end

  def parse_server_error_or_raise_for_status(resp)
    j = {}
    begin
      resp.body
    rescue
      # TO DO
    end
    if resp.code != 200 && resp.body.present?
      raise ServerError, resp.body
      puts "Status code: #{resp.code}"
    end
    return j

  end

  def post_request(route, data)
    url = self.remote_base + route
    puts url
    $logger.info "POST #{url}\n#{data}"
    #resp = @session.post(url, data)
    resp = RestClient.post("http://127.0.0.1:5000/v1/envs/", data.to_json)
    return self.parse_server_error_or_raise_for_status(resp)
  end

  def get_request(route)
    url = self.remote_base + route
    $logger.info("GET #{url}")
    resp = @session.get(url)
    return self.parse_server_error_or_raise_for_status(resp)
  end

  def env_create(env_id)
    route = '/v1/envs/'
    data = {'env_id': env_id}
    self.post_request(route, data)
    instance_id = resp.body['instance_id']
    return instance_id
  end

  def env_list_all
    route = '/v1/envs/'
    resp = self.get_request(route)
    all_envs = resp.body['all_envs']
    return all_envs
  end

  def env_reset(instance_id)
    route = "/v1/envs/#{instance_id}/reset/"
    resp = self.post_request(route, "")
    observation = resp.body['observation']
    return observation
  end

  def env_step(instance_id, action, render=false)
    route = "/v1/envs/#{instance_id}/step/"
    data = {'action': action, 'render': render}
    resp = self.post_request(route, data)
    observation = resp.body['observation']
    reward = resp.body['reward']
    done = resp.body['done']
    info = resp.body['info']
    return [observation, reward, done, info]
  end

  def env_action_space_info(instance_id)
    route = "/v1/envs/#{instance_id}/action_space/"
    resp = self.get_request(route)
    info = resp.body['info']
    return info
  end

  def env_action_space_sample(instance_id)
    route = "/v1/envs/#{instance_id}/action_space/sample"
    resp = self.get_request(route)
    action = resp.body['action']
    return action
  end

  def env_action_space_contains(instance_id, x)
    route = "/v1/envs/#{instance_id}/action_space/contains/#{x}"
    resp = self.get_request(route)
    member = resp.body['member']
    return member
  end

  def env_observation_space_info(instance_id)
    route = "/v1/envs/#{instance_id}/observation_space/"
    resp = self.get_request(route)
    info = resp.body['info']
    return info
  end

  def env_monitor_start(instance_id, directory, force=false, resume=false, video_callable=false)
    route = "/v1/envs/#{instance_id}/monitor/start/"
    data = {'directory': directory,
            'force': force,
            'resume': resume,
            'video_callable': video_callable}
    self.post_request(route, data)
  end

  def env_monitor_close(instance_id)
    route = "/v1/envs/#{instance_id}/monitor/close/"
    self.post_request(route, "")
  end

  def env_close(instance_id)
    route = "/v1/envs/#{instance_id}/close/"
    self.post_request(route, "")
  end

  def upload(training_dir, algorithm_id="", api_key="")
    if api_key.empty?
      api_key = ENV['OPENAI_GYM_API_KEY']
    end

    route = '/v1/upload/'
    data = {'training_dir': training_dir,
            'algorithm_id': algorithm_id,
            'api_key': api_key}
    self.post_request(route, data)
  end

  def shutdown_server
    route = "/v1/shutdown/"
    self.post_request(route, "")
  end
end


  remote_base = 'http://127.0.0.1:5000'
  client = Client.new(remote_base)

  # Create environment
  env_id = 'CartPole-v0'
  instance_id = client.env_create(env_id)

  # Check properties
  all_envs = client.env_list_all
  action_info = client.env_action_space_info(instance_id)
  obs_info = client.env_observation_space_info(instance_id)

  # Run a single step
  client.env_monitor_start(instance_id, directory='tmp', force=true)
  init_obs = client.env_reset(instance_id)
  # [observation, reward, done, info] = client.env_step(instance_id, 1, true)
  # client.env_monitor_close(instance_id)
  # client.upload(training_dir='tmp')
