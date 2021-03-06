class WatsonConversationService
  include ConversationActions

  def self.setup
    convo = JSON.parse(ENV["VCAP_SERVICES"])['conversation'].first['credentials']
    wkspace_id = ENV["CONV_WORKSPACE_ID"]
    url = convo['url'] + '/v1/workspaces/' + wkspace_id + '/message?version=2016-07-11'

    new(url, convo)
  end

  attr_reader :watson_connection, :user, :image, :context

  def initialize(url, convo)
    @watson_connection = Faraday.new(url: url) do |f|
      f.adapter Faraday.default_adapter
    end
    @watson_connection.basic_auth(convo['username'], convo['password'])
  end

  def prepare_payload(key, txt)
    @payload = {}
    @key = key
    set_input(txt)
    set_context(key)
  end

  def set_input(txt)
    @payload['input'] = { text: txt }
  end

  def set_context(key)
    stack = get_stack
    ctx = {
      system: {
        dialog_stack: stack.dialog_stack,
        dialog_turn_counter: stack.turn_counter,
        dialog_request_counter: stack.turn_counter,
      }
    }
    ctx["conversation_id"] = stack.convo_id if stack.convo_id
    @payload['context'] = ctx
    @payload['context']['username'] = stack.user.fullname if stack.user_id
  end

  def add_context_field(key, value)
    @payload['context'][key] = value
  end

  def send_to_watson
    r = watson_connection.post do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['Accept'] = 'application/json'
      req.body = @payload.to_json
    end

    if r.status != 200
      return "Terror has been unleashed in cloud! Wait a while and try again 😰"
    end

    pkg = JSON.parse(r.body)
    ctx = pkg['context']

    ctx["clear_context"].nil? ? save_context(pkg) : clear_context

    if ctx['action']
      act = ctx['action']
      return send(act, ctx)
    end

    pkg["output"]["text"].reject{|txt| txt.empty? }.join(", ")
  end

  def save_context(pkg)
    ctx = pkg["context"]["system"]
    stack = pkg["output"]["nodes_visited"]
    turn_counter = ctx["dialog_turn_counter"]
    request_counter = ctx["dialog_request_counter"]
    wID = pkg["conversation_id"]

    ctx = get_stack
    @user = ctx.user if ctx.user_id
    attributes = {
             dialog_stack: stack,
             turn_counter: turn_counter,
             request_counter: request_counter,
             convo_id: wID
           }
    attributes[:user_id] = user.id if user
    ctx.update_attributes(attributes)
  end

  def clear_context
    convo = get_stack
    convo.destroy unless convo.new_record?
  end

  def save_login_context(pkg)
    login_ctx = LoginContext.find_or_initialize_by(key: @key)
    ctx = get_stack.attributes
    ctx.delete("user_id")
    ctx.delete("id")

    login_ctx.update_attributes(ctx)
    prepare_payload(@key, "yes")
    send_to_watson
  end

  def reset_login_context(pkg)
    login_ctx = LoginContext.find_by(key: @key)
    ctx = login_ctx.attributes
    ctx.delete("id")
    login_ctx.destroy
    ConversationContext.find_by(key: @key).update_attributes(ctx)
    prepare_payload(@key, "false")
    add_user
    send_to_watson
  end

  def get_stack
    @context ||= ConversationContext.includes(:user).find_by(key: @key) || ConversationContext.new(key: @key)
    context
  end

  def update_context_user(user)
    ConversationContext.find_by(key: @key).update_attributes(user: user)
  end

  def add_user
    add_context_field('username', user.try(:fullname))
  end
end
