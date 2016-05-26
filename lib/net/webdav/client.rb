require 'uri'
require 'curb'


module Net
  module Webdav
    class Client
      attr_reader :host, :username, :password, :url, :http_auth_types

      def initialize url, options = {}
        scheme, userinfo, hostname, port, registry, path, opaque, query, fragment = URI.split(url)
        @host = "#{scheme}://#{hostname}#{port.nil? ? "" : ":" + port.to_s}"
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
        begin

          file = output_file(local_file_path)

          connection = Curl::Easy.new
          connection.userpwd = curl_credentials if @username.present? && @password.present?
          connection.url = full_url(remote_file_path)
          connection.perform

          notify_of_error(connection, "getting file. #{remote_file_path}")  unless connection.response_code == 200

          file.write(connection.body_str)
        ensure
          file.close
        end
      end

      def put_file path, file, create_path = false
        connection = Curl::Easy.http_head full_url(path), &method(:auth)

        if create_path
          scheme, userinfo, hostname, port, registry, path, opaque, query, fragment = URI.split(full_url(path))
          path_parts = path.split('/').reject {|s| s.nil? || s.empty?}
          path_parts.pop

          for i in 0..(path_parts.length - 1)
            #if the part part is for a file with an extension skip
            next if File.extname(path_parts[i]).present?

            parent_path = path_parts[0..i].join('/')
            url = URI.join("#{scheme}://#{hostname}#{(port.nil? || port == 80) ? "" : ":" + port.to_s}/", parent_path)
            connection.url = full_url( url )
            connection.http(:MKCOL)
            notify_of_error(connection, "creating directories") unless (connection.response_code == 201 || connection.response_code == 204 || connection.response_code == 405)
            return connection.response_code unless connection.response_code == 201 || connection.response_code == 405 # 201 Created or 405 Conflict (already exists)
          end
        end
        connection.url = full_url(path)
        connection.http_put file
        notify_of_error(connection, "creating(putting) file. File path: #{path}") unless (connection.response_code == 201 || connection.response_code == 204)
        connection.response_code
      end

      def notify_of_error(connection, action)
        raise "Error in WEBDav Client while #{action} with error: #{connection.status}"
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
      def curl_credentials
        "#{@username}:#{@password}"
      end

      def auth curl
        curl.userpwd = curl_credentials
        curl.http_auth_types = @http_auth_types unless @http_auth_types.nil?
      end

      def full_url path
        URI.join(@url, path).to_s
      end

      def output_file(filename)
        if filename.is_a? IO
          filename.binmode if filename.respond_to?(:binmode)
          filename
        else
          File.open(filename, 'wb')
        end
      end
    end
  end
end
