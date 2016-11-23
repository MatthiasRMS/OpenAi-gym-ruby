require 'webrick'
server = WEBrick::HTTPServer.new :Port => 8000
trap 'INT' do server.shutdown end


server.mount_proc '/' do |req, res|
  res.body = 'Hello, rld!'
end

server.start


########## Container for environments ##########
class Envs
    """
    Container and manager for the environments instantiated
    on this server.

    When a new environment is created, such as with
    envs.create('CartPole-v0'), it is stored under a short
    identifier (such as '3c657dbc'). Future API calls make
    use of this instance_id to identify which environment
    should be manipulated.
    """
    def initialize
        @envs = {}
        @id_len = 8

    def lookup_env(instance_id)
      begin
        return @envs[instance_id]
      rescue KeyError:
        raise InvalidUsage, "Instance_id #{instance_id} unknown"
      end
    end

    def remove_env(instance_id)
      begin
        @envs.delete(instance_id)
      rescue KeyError
        raise InvalidUsage, "Instance_id #{instance_id} unknown"
      end
    end

    def create(env_id)
      begin
          env = gym.make(env_id)
      rescue gym.error.Error:
          raise InvalidUsage("Attempted to look up malformed environment ID '{}'".format(env_id))
      end
      instance_id = str(uuid.uuid4().hex)[:self.id_len]
      self.envs[instance_id] = env
      return instance_id
    end

    def list_all(self)
      return dict([(instance_id, env.spec.id) for (instance_id, env) in self.envs.items()])
    end

    def reset(instance_id)
      env = self._lookup_env(instance_id)
      obs = env.reset()
      return env.observation_space.to_jsonable(obs)
    end

    def step(instance_id, action, render)
      env = self._lookup_env(instance_id)
      if isinstance( action, six.integer_types )
          nice_action = action
      else:
          nice_action = np.array(action)
      if render:
          env.render()
      [observation, reward, done, info] = env.step(nice_action)
      obs_jsonable = env.observation_space.to_jsonable(observation)
      return [obs_jsonable, reward, done, info]
    end

    def get_action_space_contains(instance_id, x)
      env = self._lookup_env(instance_id)
      return env.action_space.contains(int(x))
    end

    def get_action_space_info(instance_id)
      env = self._lookup_env(instance_id)
      return self._get_space_properties(env.action_space)
    end

    def get_action_space_sample(instance_id)
      env = self._lookup_env(instance_id)
      action = env.action_space.sample()
      if isinstance(action, (list, tuple)) or ('numpy' in str(type(action)))
          try:
              action = action.tolist()
          except TypeError:
              print(type(action))
              print('TypeError')
      return action
    end

    def get_action_space_contains(instance_id, x)
      env = self._lookup_env(instance_id)
      return env.action_space.contains(int(x))
    end

    def get_observation_space_info(instance_id)
      env = self._lookup_env(instance_id)
      return self._get_space_properties(env.observation_space)
    end

    def _get_space_properties(space)
      info = {}
      info['name'] = space.__class__.__name__
      if info['name'] == 'Discrete':
          info['n'] = space.n
      elif info['name'] == 'Box':
          info['shape'] = space.shape
          # It's not JSON compliant to have Infinity, -Infinity, NaN.
          # Many newer JSON parsers allow it, but many don't. Notably python json
          # module can read and write such floats. So we only here fix "export version",
          # also make it flat.
          info['low']  = [(x if x != -np.inf else -1e100) for x in np.array(space.low ).flatten()]
          info['high'] = [(x if x != +np.inf else +1e100) for x in np.array(space.high).flatten()]
      elif info['name'] == 'HighLow':
          info['num_rows'] = space.num_rows
          info['matrix'] = [((float(x) if x != -np.inf else -1e100) if x != +np.inf else +1e100) for x in np.array(space.matrix).flatten()]

      return info
    end

    def monitor_start(instance_id, directory, force, resume, video_callable)
      env = self._lookup_env(instance_id)
      if video_callable == False:
          v_c = lambda count: False
      else:
          v_c = lambda count: count % video_callable == 0
      env.monitor.start(directory, force=force, resume=resume, video_callable=v_c)
      end
    end


    def monitor_close(instance_id)
      env = self._lookup_env(instance_id)
      env.monitor.close()
    end

    def env_close(instance_id)
      env = self._lookup_env(instance_id)
      env.close()
      self._remove_env(instance_id)
    end
