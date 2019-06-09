class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    # ヘルパーメソッドは一箇所にパッケージ化できて、これは自動的にviewに読み込まれている。
    # さらに以下のようにapplicationControllerにincludeさせれば、この子クラス全てのコントローラが使えるようになる。
    include SessionsHelper
end
