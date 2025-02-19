#
# Copyright (C) 2014 eNovance SAS <licensing@enovance.com>
#
# Author: Emilien Macchi <emilien.macchi@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

require 'spec_helper'

describe 'keystone::resource::service_identity' do
  let (:title) { 'neutron' }

  let :required_params do
    { :password     => 'secrete',
      :service_type => 'network',
      :admin_url    => 'http://192.168.0.1:9696',
      :internal_url => 'http://10.0.0.1:9696',
      :public_url   => 'http://7.7.7.7:9696' }
  end

  shared_examples 'keystone::resource::service_identity' do
    context 'with only required parameters' do
      let :params do
        required_params
      end

      it { is_expected.to contain_keystone_user(title).with(
        :ensure   => 'present',
        :password => 'secrete',
        :email    => 'neutron@localhost',
      )}

      it { is_expected.to contain_keystone_user_role("#{title}@services").with(
        :ensure => 'present',
        :roles  => ['admin'],
      )}

      it { is_expected.to_not contain_keystone_user_role("#{title}@::::all") }

      it { is_expected.to contain_keystone_service("#{title}::network").with(
        :ensure      => 'present',
        :description => 'neutron service',
      )}

      it { is_expected.to contain_keystone_endpoint("RegionOne/#{title}::network").with(
        :ensure       => 'present',
        :public_url   => 'http://7.7.7.7:9696',
        :internal_url => 'http://10.0.0.1:9696',
        :admin_url    => 'http://192.168.0.1:9696',
        :region       => 'RegionOne',
      )}
    end

    context 'with ensure set to absent' do
      let :params do
        required_params.merge(:ensure => 'absent')
      end

      it { is_expected.to contain_keystone_user(title).with(
        :ensure   => 'absent',
        :password => 'secrete',
        :email    => 'neutron@localhost',
      )}

      it { is_expected.to contain_keystone_user_role("#{title}@services").with(
        :ensure => 'absent',
        :roles  => ['admin'],
      )}

      it { is_expected.to_not contain_keystone_user_role("#{title}@::::all") }

      it { is_expected.to contain_keystone_service("#{title}::network").with(
        :ensure      => 'absent',
        :description => 'neutron service',
      )}

      it { is_expected.to contain_keystone_endpoint("RegionOne/#{title}::network").with(
        :ensure       => 'absent',
        :public_url   => 'http://7.7.7.7:9696',
        :internal_url => 'http://10.0.0.1:9696',
        :admin_url    => 'http://192.168.0.1:9696',
        :region       => 'RegionOne',
      )}
    end

    context 'with bad ensure parameter value' do
      let :params do
        required_params.merge(:ensure => 'badvalue')
      end

      it { is_expected.to raise_error(Puppet::Error) }
    end

    context 'when explicitly setting an region' do
      let :params do
        required_params.merge(
          :region => 'East',
        )
      end
      it { is_expected.to contain_keystone_endpoint("East/#{title}::network").with(
        :ensure       => 'present',
        :public_url   => 'http://7.7.7.7:9696',
        :internal_url => 'http://10.0.0.1:9696',
        :admin_url    => 'http://192.168.0.1:9696',
        :region       => 'East',
      )}
    end

    context 'when trying to create an endpoint without service_type' do
      let :params do
        required_params.delete(:service_type)
        required_params.merge(
          :configure_service => false,
        )
      end

      it { is_expected.to raise_error(Puppet::Error) }
    end

    context 'when trying to create a service without service_type' do
      let :params do
        required_params.delete(:service_type)
        required_params
      end

      it { is_expected.to raise_error(Puppet::Error) }
    end

    context 'when trying to create an endpoint without url' do
      let :params do
        required_params.delete(:public_url)
        required_params
      end

      it { is_expected.to raise_error(Puppet::Error) }
    end

    context 'with user domain' do
      let :params do
        required_params.merge({:user_domain => 'userdomain'})
      end

      it { is_expected.to contain_keystone_domain('userdomain').with(
        :ensure   => 'present',
      )}

      it { is_expected.to contain_keystone_user(title).with(
        :ensure   => 'present',
        :password => 'secrete',
        :email    => 'neutron@localhost',
        :domain   => 'userdomain',
      )}
      it { is_expected.to contain_keystone_role('admin').with(
        :ensure => 'present',
      )}

      it { is_expected.to contain_keystone_user_role("#{title}@services").with(
        :ensure      => 'present',
        :roles       => ['admin'],
        :user_domain => 'userdomain',
      )}

      it { is_expected.to_not contain_keystone_user_role("#{title}@::::all") }
    end

    context 'with user and project domain' do
      let :params do
        required_params.merge({
          :user_domain    => 'userdomain',
          :project_domain => 'projdomain',
        })
      end

      it { is_expected.to contain_keystone_user(title).with(
        :ensure   => 'present',
        :password => 'secrete',
        :email    => 'neutron@localhost',
        :domain   => 'userdomain',
      )}

      it { is_expected.to contain_keystone_domain('userdomain').with(
        :ensure   => 'present',
      )}

      it { is_expected.to contain_keystone_user_role("#{title}@services").with(
        :ensure         => 'present',
        :roles          => ['admin'],
        :user_domain    => 'userdomain',
        :project_domain => 'projdomain',
      )}

      it { is_expected.to_not contain_keystone_user_role("#{title}@::::all") }
    end

    context 'with default domain only' do
      let :params do
        required_params.merge({
          :default_domain => 'defaultdomain',
        })
      end

      it { is_expected.to contain_keystone_user(title).with(
        :ensure   => 'present',
        :password => 'secrete',
        :email    => 'neutron@localhost',
        :domain   => 'defaultdomain',
      )}

      it { is_expected.to contain_keystone_domain('defaultdomain').with(
        :ensure   => 'present',
      )}

      it { is_expected.to contain_keystone_user_role("#{title}@services").with(
        :ensure         => 'present',
        :roles          => ['admin'],
        :user_domain    => 'defaultdomain',
        :project_domain => 'defaultdomain',
      )}

      it { is_expected.to_not contain_keystone_user_role("#{title}@::::all") }
    end

    context 'with user and default domain' do
      let :params do
        required_params.merge({
          :user_domain    => 'userdomain',
          :default_domain => 'defaultdomain',
        })
      end

      it { is_expected.to contain_keystone_user(title).with(
        :ensure   => 'present',
        :password => 'secrete',
        :email    => 'neutron@localhost',
        :domain   => 'userdomain',
      )}

      it { is_expected.to contain_keystone_domain('userdomain').with(
        :ensure   => 'present',
      )}

      it { is_expected.to contain_keystone_user_role("#{title}@services").with(
        :ensure         => 'present',
        :roles          => ['admin'],
        :user_domain    => 'userdomain',
        :project_domain => 'defaultdomain',
      )}

      it { is_expected.to_not contain_keystone_user_role("#{title}@::::all") }
    end

    context 'with project and default domain' do
      let :params do
        required_params.merge({
          :project_domain => 'projdomain',
          :default_domain => 'defaultdomain',
        })
      end

      it { is_expected.to contain_keystone_user(title).with(
        :ensure   => 'present',
        :password => 'secrete',
        :email    => 'neutron@localhost',
        :domain   => 'defaultdomain',
      )}

      it { is_expected.to contain_keystone_domain('defaultdomain').with(
        :ensure   => 'present',
      )}

      it { is_expected.to contain_keystone_user_role("#{title}@services").with(
        :ensure         => 'present',
        :roles          => ['admin'],
        :user_domain    => 'defaultdomain',
        :project_domain => 'projdomain',
      )}

      it { is_expected.to_not contain_keystone_user_role("#{title}@::::all") }
    end

    context 'with customized roles' do
      let :params do
        required_params.merge({
          :roles        => ['admin', 'service'],
          :system_roles => ['member', 'reader']
        })
      end

      it { is_expected.to contain_keystone_user_role("#{title}@services").with(
        :ensure => 'present',
        :roles  => ['admin', 'service'],
      )}

      it { is_expected.to contain_keystone_user_role("#{title}@::::all").with(
        :ensure => 'present',
        :roles  => ['member', 'reader'],
      )}
    end
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts())
      end

      it_behaves_like 'keystone::resource::service_identity'
    end
  end
end
