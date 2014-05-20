#
# Copyright:: Copyright (c) 2014 Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/cookbook/cookbook_version_loader'
require 'digest/sha1'
require 'chef/digester'

module ChefDK
  module CookbookProfiler
    class Identifiers

      attr_reader :cookbook_path

      def initialize(cookbook_path)
        @cookbook_path = cookbook_path
      end

      def semver_version
        cookbook_version.version
      end

      def content_identifier
        Digest::SHA1.new.hexdigest(fingerprint_text)
      end

      def dotted_decimal_identifier
        hex_id = content_identifier
        major = hex_id[0...14]
        minor = hex_id[14...28]
        patch = hex_id[28..40]
        decimal_integers =[major, minor, patch].map {|hex| hex.to_i(16) }
        decimal_integers.join(".")
      end

      def fingerprint_text
        files_with_checksums.sort {|a,b| a[0] <=> b[0]}.inject("") do |fingerprint, file_spec|
          fingerprint << "#{file_spec[0]}:#{file_spec[1]}\n"
        end
      end

      def files_with_checksums
        cookbook_files.inject([]) do |files_with_checksums, (_name, file_info)|
          files_with_checksums << [file_info["path"], file_info["checksum"]]
        end
      end

      def cookbook_files
        @files ||= cookbook_version.manifest_records_by_path
      end

      def cookbook_version
        @cookbook_version ||= cookbook_loader.cookbook_version
      end

      def cookbook_loader
        @cookbook_loader ||=
          begin
            loader = Chef::Cookbook::CookbookVersionLoader.new(cookbook_path)
            loader.load_cookbooks
            loader
          end
      end
    end
  end
end
