#
# Cookbook Name:: git
# Recipe:: source
#
# Copyright 2012, Brian Flad, Fletcher Nichol
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

return "#{node['platform']} is not supported by the #{cookbook_name}::#{recipe_name} recipe" if node['platform'] == 'windows'

include_recipe 'build-essential'
include_recipe 'yum-epel' if node['platform_family'] == 'rhel' && node['platform_version'].to_i < 6

# move this to attributes.
case node['platform_family']
when 'rhel'
  case node['platform_version'].to_i
  when 5
    pkgs = %w{ expat-devel gettext-devel curl-devel openssl-devel zlib-devel }
  when 6
    pkgs = %w{ expat-devel gettext-devel libcurl-devel openssl-devel perl-ExtUtils-MakeMaker zlib-devel }
  else
    pkgs = %w{ expat-devel gettext-devel curl-devel openssl-devel perl-ExtUtils-MakeMaker zlib-devel } if node['platform'] == 'amazon'
  end
when 'debian'
  pkgs = %w{ libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev }
end

pkgs.each do |pkg|
  package pkg
end

# reduce line-noise-eyness
remote_file "#{Chef::Config['file_cache_path']}/git-#{node['git']['version']}.tar.gz" do
  source    node['git']['url']
  checksum  node['git']['checksum']
  mode      '0644'
end

# reduce line-noise-eyness
bash "Extracting and Building Git #{node['git']['version']} from Source" do
  flags '-ex'
  code <<-EOF
    cd "#{Chef::Config['file_cache_path']}"
    d="git-#{node['git']['version']}"
    [ -e "$d" ] && rm -rf "$d"
    mkdir "$d"
    tar -zxf "$d.tar.gz" -C "$d" --strip-components 1
    make -C"$d" prefix="#{node['git']['prefix']}" install
  EOF
  creates "#{node['git']['prefix']}/bin/git"
  not_if "git --version | grep #{node['git']['version']}"
end
