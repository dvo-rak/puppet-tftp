require 'spec_helper_acceptance'

describe 'tftp with default parameters' do
  it_behaves_like 'an idempotent resource' do
    let(:manifest) do
      <<-EOS
      class { 'tftp':
        port => 1234,
      }

      file { "${tftp::root}/test":
        ensure  => file,
        content => 'running on a different port',
      }
      EOS
    end
  end

  service_name = case fact('osfamily')
                 when 'Archlinux'
                   'tftpd.socket'
                 when 'RedHat'
                   'tftp.socket'
                 when 'Debian'
                   'tftpd-hpa'
                 end

  describe service(service_name) do
    it { is_expected.to be_enabled }
    it { is_expected.to be_running }
  end

  describe port(69), unless: service_name.end_with?('.socket') do
    it { is_expected.not_to be_listening }
  end

  describe port(1234), unless: service_name.end_with?('.socket') do
    it { is_expected.to be_listening.with('udp') }
  end

  describe 'ensure tftp client is installed' do
    on hosts, puppet('resource', 'package', 'tftp', 'ensure=installed')
  end

  describe command("echo get /test /tmp/downloaded_file | tftp #{fact('fqdn')} 1234") do
    its(:exit_status) { should eq 0 }
  end

  describe file('/tmp/downloaded_file') do
    it { should be_file }
    its(:content) { should eq 'running on a different port' }
  end
end