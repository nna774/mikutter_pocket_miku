# -*- coding: utf-8 -*-

require 'pocket_miku'
require 'MeCab'

Plugin.create(:pocket_miku) do
  notify_thread = SerialThreadGroup.new

  settings "ポケット・ミク" do
    fileselect 'midiデバイス', :pocket_miku_device, '/dev/'

    sound_test_button = Gtk::Button.new('発音テスト')
    closeup sound_test_button.right

    boolean 'ふぁぼ通知', :pocket_miku_fav_notification
    boolean 'リプライ読みあげ', :pocket_miku_reply_notification

    sound_test_button.signal_connect('clicked') do
      # 調教的にキツい
      sing do
        tempo 140
        み key: 72, length: PocketMiku::Note16
        く key: 76, length: PocketMiku::Note16
        っ PocketMiku::Note8
        た key: 72, length: PocketMiku::Note4
      end
    end end

  on_appear do |ms|
    if UserConfig[:pocket_miku_reply_notification]
      ms.each do |m|
        # まえのリプライには反応しない 
        if Time.now - m[:created] > 5
          next
        end
        if m[:system]
          next
        end
        c = MeCab::Tagger.new("-O yomi")
        if m.message.to_s =~ /@#{Service.primary.user.to_s}/
          msg = m.message.to_s
          msgStr = msg.gsub(/@#{Service.primary.user.to_s}/, " ")
          msgStr = c.parse(msgStr)
          msgStr = msgStr.force_encoding(Encoding::UTF_8) 
          #        msgStr = msgStr.encode("UTF-8", :undef=> :replace, :replace=> " ")
          prev = " "
          (msgStr+" ").tr('ァ-ン','ぁ-ん').chars do |s|
            t = s
            if PocketMiku::CharTable[(prev + s).intern]
              prev = prev + s
            end
            puts prev
            talk = prev
            prev = t
            if PocketMiku::CharTable[talk.intern]
              notify_thread.new do
                sing do 
                  tempo 60
                  generate_note(PocketMiku::CharTable[talk.intern],key: 60, length: PocketMiku::Note8)
                end
              end
            end
            if talk == "っ"
              notify_thread.new do  
                sing do
                  tempo 60
                  っ PocketMiku::Note8
                end
              end
            end
            if talk == "、"
              notify_thread.new do  
                sing do
                  tempo 60
                  っ PocketMiku::Note8
                end
              end
            end
            if talk == "。"
              notify_thread.new do  
                sing do
                  tempo 60
                  っ PocketMiku::Note4
                end
              end
            end
            
          end
        end
      end
    end
  end
  
  on_favorite do |service, by, to|
    if UserConfig[:pocket_miku_fav_notification] and to.from_me?
      notify_thread.new do
        sing do
          tempo 140
          ふぁ key: 75, length: PocketMiku::Note16
          ぼ key: 82, length: PocketMiku::Note16
        end end end end

  device_watcher = UserConfig.connect(:pocket_miku_device) do
    pocket_miku_reset end

  on_unload do
    pocket_miku_reset
    UserConfig.disconnect(device_watcher) end

  at_exit do
    pocket_miku_reset end

  def sing
    if pocket_miku
      pocket_miku.sing(&Proc.new) end
  rescue => exception
    error exception
    pocket_miku_reset end

  def pocket_miku
    return nil unless UserConfig[:pocket_miku_device]
    atomic do
      if not(@pocket_miku) or @pocket_miku.closed?
        @pocket_miku = PocketMiku::Device.new(UserConfig[:pocket_miku_device]) end end
    @pocket_miku
  rescue => exception
    error exception
    @pocket_miku = nil end

  def pocket_miku_reset
    atomic do
      if @pocket_miku
        @pocket_miku.stop.close rescue nil end
      @pocket_miku = nil end end

end


