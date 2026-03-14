class CreateNotificationsAndDevices < ActiveRecord::Migration[8.1]
  def change
    # -------------------------------------------------------------- #
    # Notifications table                                              #
    # Stores in-app notifications for every user action or event.     #
    # -------------------------------------------------------------- #
    create_table :notifications, id: :uuid do |t|
      t.references :user,    null: false, foreign_key: { to_table: :users }, type: :uuid
      t.string     :ntype,   null: false              # notification type e.g. "transaction", "kyc"
      t.string     :title,   null: false
      t.text       :body,    null: false
      t.boolean    :is_read, null: false, default: false
      t.jsonb      :metadata,             default: {}  # arbitrary payload (amount, tx ref, etc.)

      t.timestamps
    end

    add_index :notifications, [ :user_id, :is_read ]
    add_index :notifications, :ntype

    # -------------------------------------------------------------- #
    # Devices table                                                    #
    # Stores FCM tokens per user. One user → many devices.            #
    # -------------------------------------------------------------- #
    create_table :devices, id: :uuid do |t|
      t.references :user,        null: false, foreign_key: { to_table: :users }, type: :uuid
      t.string     :token,       null: false              # FCM registration token
      t.string     :device_type, null: false              # "ios", "android", "web"
      t.string     :device_id                             # optional unique device identifier

      t.timestamps
    end

    add_index :devices, :token,  unique: true
    add_index :devices, :user_id
  end
end
