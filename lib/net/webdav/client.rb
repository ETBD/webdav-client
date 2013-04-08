require 'uri'
require 'curb'


module Net
  module Webdav
    class Client
      attr_reader :host, :username, :password, :url, :http_auth_types

      def initialize url, options = {}
        scheme, userinfo, hostname, port, registry, path, opaque, query, fragment = URI.split(url)
        @host = "#{scheme}://#{hostname}#{port.nil? ? "" : ":" + port}"
        @http_auth_types = options[:http_auth_types] || :basic

        unless userinfo.nil?            
          @username, @password = userinfo.split(':')
        else
          @username = options[:username]
          @password = options[:password]
        end

        @url = URI.join(@host, path)
      end
      
      def file_exists? path
        response = Curl::Easy.http_head full_url(path)
        response.response_code >= 200 && response.response_code <= 209
      end
      
      def get_file remote_file_path, local_file_path
        Curl::Easy.download full_url(remote_file_path), local_file_path
      end
      
      def put_file path, file, create_path = false
        response = Curl::Easy.http_put full_url(path), file, &method(:auth)

        if create_path and response.response_code == 409 # conflict; parent path doesn't exist, try to create recursively
          scheme, userinfo, hostname, port, registry, path, opaque, query, fragment = URI.split(full_url(path))
          path_parts = path.split('/').reject {|s| s.nil? || s.empty?}

          for i in 0..(path_parts.length - 2)
            parent_path = path_parts[0..i].join('/')
            url = URI.join("#{scheme}://#{hostname}#{(port.nil? || port == 80) ? "" : ":" + port}/", parent_path)
            response = make_directory(url)
            return response unless response.response_code == 201 || response.response_code == 405 # 201 Created or 405 Conflict (already exists)
          end

          response = Curl::Easy.http_put full_url(path), file, &method(:auth)
        end

        raise response.status unless (response.response_code == 201 || response.response_code == 204)
        response
      end

      def delete_file path
        Curl::Easy.http_delete full_url(path), &method(:auth)
      end

      def make_directory path
        curl = Curl::Easy.new(full_url(path))
        auth(curl)
        curl.http(:MKCOL)
        curl
      end
      
      private
      def auth curl
        curl.username = @username unless @username.nil?
        curl.password = @password unless @password.nil?
        curl.http_auth_types = @http_auth_types unless @http_auth_types.nil?
      end
      
      def full_url path
        URI.join(@url, path).to_s
      end
    end
  end
end