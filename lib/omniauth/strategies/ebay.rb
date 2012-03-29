require 'omniauth'
require 'lib/ebay_api'

module OmniAuth
  module Strategies
    class Ebay
      include OmniAuth::Strategy
      include EbayAPI

      args [:runame, :devid, :appid, :certid, :siteid, :apiurl]
      option :name, "ebay"
      option :runame, nil
      option :devid, nil
      option :appid, nil
      option :certid, nil
      option :siteid, nil
      option :apiurl, nil

      uid { raw_info['EIASToken'] }
      info do
        {
            :ebay_id => raw_info['UserID'],
            :ebay_token => @auth_token,
            :email => raw_info['Email']
        }
      end

      extra do
        {
            :return_to => request.params["return_to"]
        }
      end

      #1: We'll get to the request_phase by accessing /auth/ebay
      #2: Request from eBay a SessionID
      #3: Redirect to eBay Login URL with the RUName and SessionID
      def request_phase
        session_id = generate_session_id
        redirect ebay_login_url(session_id)
      end

      #4: We'll get to the callback phase by setting our accept/reject URL in the ebay application settings(/auth/ebay/callback)
      #5: Request an eBay Auth Token with the returned username&secret_id parameters.
      #6: Request the user info from eBay
      def callback_phase
        @auth_token = get_auth_token(request.params["username"], request.params["sid"])
        @user_info = get_user_info(@auth_token)
        super
      rescue Exception => ex
        fail!("Failed to retrieve user info from ebay", ex)
      end

      def raw_info
        @user_info
      end

      protected

      def ebay_login_url(session_id)
        #TODO: Refactor ruparams to receive all of the request query string
        url = "#{EBAY_LOGIN_URL}?SingleSignOn&runame=#{options.runame}&sid=#{URI.escape(session_id).gsub('+', '%2B')}"
        if request.params[:return_to]
          url << "&ruparams=#{CGI::escape('return_to=' + request.params['return_to'])}"
        end
        return url
      end

    end
  end
end

OmniAuth.config.add_camelization 'ebay', 'Ebay'