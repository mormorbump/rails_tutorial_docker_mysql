module UsersHelper

    def gravatar_for(user, size: 80)
        # ::（二重コロン）もメソッドの呼び出し。の他に定数の呼び出しも孕んでいる。
        # Rubyでは， クラスやモジュールも定数
        gravatar_id = Digest::MD5::hexdigest(user.email.downcase)
        gravatar_url =  "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{size}"
        image_tag(gravatar_url, alt: user.name, class: "gravatar")
    end
end
