module ConversationActions
  def new_field(ctx)
    temp_user = TempNewUser.find_or_create_by(key: @key)
    acc_num = ""
    val = ctx['value']

    if ctx['field'] == 'phone'
      firstname, lastname = temp_user.name.split
      @user = User.create(email: temp_user.email, phone: val, firstname: firstname, lastname: lastname)
      acc_num = Faker::Number.number(10)
      user.accounts.create(account_num: acc_num, balance: 100000)
      update_context_user(user)
    else
      temp_user.update_attributes(ctx['field'] => val)
    end

    prepare_payload(@key, "yes")
    add_context_field("username", temp_user.name)
    add_context_field("account_num", acc_num)
    send_to_watson
  end

  def send_otp(ctx, partial=false)
    otp = rand(10000000...100000000)
    @user ||= User.last
    user.otps.create(value: otp)
    TextMessage.send_text("You Secure Code: #{otp}", user.phone)
    return if partial
    prepare_payload(@key, "yes")
    send_to_watson
  end

  def temp_save_field(ctx)
    @user ||= User.last
    temp = TempUserUpdate.find_or_initalize_by(user: user)
    temp.update_attributes(ctx['field'] => ctx['value'])
    prepare_payload(@key, "yes")
    send_to_watson
  end

  def confirm_update(ctx)
    prepare_payload(@key, "yes")
    add_user
    add_context_field('update_msg', 'value')
    send_to_watson
  end

  def save_update(ctx)
    @user ||= User.last
    attr = TempUserUpdate.find_by(user: user).attributes
    attr.delete(:user_id)
    user.update_attributes(attr)
    prepare_payload(@key, "yes")
    send_to_watson
  end

  def get_location(ctx)
    begin
      gmaps = Navigation::Assistant.new
      gmaps.directions("Victory Island, Lagos", ctx['location'])
      @image = gmaps.get_image_url#["secure_url"]
      gmaps.parse.get_directions
    rescue
      prepare_payload(@key, "false")
      add_context_field("error_msg", "couldn't get the required directions")
      send_to_watson
    end
  end

  def confirm_check(ctx)
    @user ||= User.last
    # TODO: query database
    if true
      prepare_payload(@key, "yes")
      add_context_field("status", "status of check")
    else
      prepare_payload(@key, 'false')
    end
    add_user
    send_to_watson
  end

  def check_atm_status(ctx)
    @user ||= User.last
    prepare_payload(@key, 'yes')
    add_user
    add_context_field('card_type', "")
    send_to_watson
  end

  def schedule_delivery(ctx)
    @user ||= User.last
    MeetingSchedulerService.new.create(user)
    prepare_payload(@key, 'yes')
    add_user
    add_context_field("address", "user.address")
    send_to_watson
  end

  def schedule_appointment(ctx)
    @user ||= User.last
    status = MeetingSchedulerService.new.create(user)
    prepare_payload(@key, 'yes')
    add_context_field("schedule_status", status)
    add_user
    send_to_watson
  end

  def atm_application(ctx)
    @user ||= User.last
    # TODO: save application to the db
    prepare_payload(@key, 'yes')
    add_context_field("card_type", ctx["card_type"])
    add_user
    send_to_watson
  end

  def update_alert(ctx)
    @user ||= User.last
    # TODO: save to database User.alerts.update ctx["value"] => enable or disable
    prepare_payload(@key, 'yes')
    add_user
    add_context_field('alert_types', 'Email notification and SMS notification')
    send_to_watson
  end

  def validate_receiver_account(ctx)
    @user ||= User.last
    acc = Account.includes(:user).find_by(account_num: ctx['account_number'])
    if acc
      transc = TempTransaction.find_or_initialize_by(sender: user)
      transc.update_attributes(receiver: acc.user)
      prepare_payload(@key, 'yes')
      add_context_field("receiver_name", acc.user.fullname)
      validation_status(true)
      add_user
    else
      prepare_payload(@key, 'false')
      validation_status(false)
    end
    send_to_watson
  end

  def save_amount_to_transfer(ctx)
    @user ||= User.last
    bal = user.accounts.first.balance
    if bal > ctx['amount'].to_i
      transc = TempTransaction.find_by(sender_id: user.id)
      transc.update_attributes(amount: ctx['amount'])
      prepare_payload(@key, "yes")
      add_user
      add_context_field('amount', ctx['amount'])
      add_context_field('receiver_name', transc.receiver.fullname)
    else
      prepare_payload(@key, "false")
      add_context_field("error_msg", "you have less than #{ctx['amount']} in your account. Your Account balance is #{bal}.")
      add_user
    end

    send_to_watson
  end

  def make_transaction(ctx)
   @user ||= User.last
    transc = TempTransaction.find_by(sender_id: user.id)
    transc.sender.accounts.first.decrement!(:balance, transc.amount)
    transc.receiver.accounts.first.increment!(:balance, transc.amount)
    transc.destroy

    prepare_payload(@key, 'yes')
    send_to_watson
  end

  def validate_account(ctx)
    acc = Account.includes(:user).find_by(account_num: ctx['account_no'])
    if acc
      @user = acc.user
      send_otp('', true)
      prepare_payload(@key, 'yes')
      update_context_user(user)
      validation_status(true)
      add_user
    else
      validation_status(false)
    end
    send_to_watson
  end

  def validate_otp(ctx)
    @user ||= User.last
    otp = user.otps.find_by(value: ctx['otp'])
    if otp
      update_context_user(user)
      add_user
      prepare_payload(@key, 'yes')
      validation_status(true)
      otp.destroy
    else
      validation_status(false)
    end
    send_to_watson
  end

  def get_statement(ctx)
    @user ||= User.last
    acc = user.get_statement
    prepare_payload(@key, 'yes')
    add_user
    add_context_field('statement', acc)
    send_to_watson
  end

  def validation_status(status)
    add_context_field('valid', status.to_s)
  end
end
