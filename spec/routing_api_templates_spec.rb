# rubocop: disable LineLength
# rubocop: disable BlockLength
require 'rspec'
require 'bosh/template/test'
require 'yaml'
require 'json'

describe 'routing_api' do
  let(:release_path) { File.join(File.dirname(__FILE__), '..') }
  let(:release) { Bosh::Template::Test::ReleaseDir.new(release_path) }
  let(:job) { release.job('routing-api') }

  let(:merged_manifest_properties) do
    {
      'routing_api' => {
        'system_domain' => 'the.system.domain',
        'sqldb' => {
          'host' => 'host',
          'port' => 1234,
          'type' => 'mysql',
          'schema' => 'schema',
          'username' => 'username',
          'password' => 'password'
        }
      },
      'uaa' => {
        'tls_port' => 8080
      }
    }
  end

  describe 'config/certs/routing-api/client_ca.crt' do
    let(:template) { job.template('config/certs/routing-api/client_ca.crt') }

    describe 'when server mtls is enabled' do
      before do
        merged_manifest_properties['routing_api']['mtls_enabled'] = true
      end

      it 'renders the client ca cert' do
        merged_manifest_properties['routing_api']['mtls_client_ca'] = 'the client ca cert'
        client_ca = template.render(merged_manifest_properties)
        expect(client_ca).to eq('the client ca cert')
      end

      describe 'when the client ca is not provided' do
        it 'should err' do
          expect { template.render(merged_manifest_properties) }.to raise_error Bosh::Template::UnknownProperty
        end
      end
    end

    describe 'when server mtls not enabled' do
      before do
        merged_manifest_properties['routing_api']['mtls_enabled'] = false
      end

      it 'should not err when the client ca is not specified' do
        client_ca = template.render(merged_manifest_properties)
        expect(client_ca).to eq('')
      end
    end
  end

  describe 'config/certs/routing-api/server.crt' do
    let(:template) { job.template('config/certs/routing-api/server.crt') }

    describe 'when server mtls is enabled' do
      before do
        merged_manifest_properties['routing_api']['mtls_enabled'] = true
      end

      it 'renders the server cert' do
        merged_manifest_properties['routing_api']['mtls_server_cert'] = 'the server cert'
        client_ca = template.render(merged_manifest_properties)
        expect(client_ca).to eq('the server cert')
      end

      describe 'when the server cert is not provided' do
        it 'should err' do
          expect { template.render(merged_manifest_properties) }.to raise_error Bosh::Template::UnknownProperty
        end
      end
    end

    describe 'when server mtls not enabled' do
      before do
        merged_manifest_properties['routing_api']['mtls_enabled'] = false
      end

      it 'should not err when the server cert is not specified' do
        expect(template.render(merged_manifest_properties)).to eq('')
      end
    end
  end

  describe 'config/keys/routing-api/server.key' do
    let(:template) { job.template('config/certs/routing-api/server.key') }

    describe 'when server mtls is enabled' do
      before do
        merged_manifest_properties['routing_api']['mtls_enabled'] = true
      end

      it 'renders the server key' do
        merged_manifest_properties['routing_api']['mtls_server_key'] = 'the server key'
        client_ca = template.render(merged_manifest_properties)
        expect(client_ca).to eq('the server key')
      end

      describe 'when the server key is not provided' do
        it 'should err' do
          expect { template.render(merged_manifest_properties) }.to raise_error Bosh::Template::UnknownProperty
        end
      end
    end

    describe 'when server mtls not enabled' do
      before do
        merged_manifest_properties['routing_api']['mtls_enabled'] = false
      end

      it 'should not err when the server key is not specified' do
        expect(template.render(merged_manifest_properties)).to eq('')
      end
    end
  end

  describe 'routing-api.yml' do
    let(:template) { job.template('config/routing-api.yml') }

    subject(:rendered_config) do
      YAML.safe_load(template.render(merged_manifest_properties))
    end

    it 'renders a file with default properties' do
      expect(rendered_config).to eq('admin_port' => 15_897,
                                    'consul_cluster' => { 'servers' => 'http://127.0.0.1:8500', 'lock_ttl' => '10s', 'retry_interval' => '5s' },
                                    'debug_address' => '127.0.0.1:17002',
                                    'locket' => {
                                      'locket_address' => nil,
                                      'locket_ca_cert_file' => '/var/vcap/jobs/routing-api/config/certs/locket/ca.crt',
                                      'locket_client_cert_file' => '/var/vcap/jobs/routing-api/config/certs/locket/client.crt',
                                      'locket_client_key_file' => '/var/vcap/jobs/routing-api/config/certs/locket/client.key'
                                    },
                                    'log_guid' => 'routing_api',
                                    'max_ttl' => '120s',
                                    'metrics_reporting_interval' => '30s',
                                    'metron_config' => { 'address' => 'localhost', 'port' => 3457 },
                                    'oauth' => {
                                      'token_endpoint' => 'uaa.service.cf.internal',
                                      'port' => 8080,
                                      'skip_ssl_validation' => false
                                    },
                                    'api' => {
                                      'listen_port' => 3000,
                                      'http_enabled' => true,
                                      'mtls_enabled' => false,
                                      'mtls_listen_port' => 3001,
                                      'mtls_client_ca_file' => '/var/vcap/jobs/routing-api/config/certs/routing-api/client_ca.crt',
                                      'mtls_server_cert_file' => '/var/vcap/jobs/routing-api/config/certs/routing-api/server.crt',
                                      'mtls_server_key_file' => '/var/vcap/jobs/routing-api/config/certs/routing-api/server.key'
                                    },
                                    'router_groups' => [],
                                    'skip_consul_lock' => false,
                                    'sqldb' => {
                                      'host' => 'host',
                                      'port' => 1234,
                                      'type' => 'mysql',
                                      'schema' => 'schema',
                                      'username' => 'username',
                                      'password' => 'password',
                                      'skip_hostname_validation' => false
                                    },
                                    'statsd_client_flush_interval' => '300ms',
                                    'statsd_endpoint' => 'localhost:8125',
                                    'system_domain' => 'the.system.domain',
                                    'uuid' => 'xxxxxx-xxxxxxxx-xxxxx')
    end

    describe 'when disabiling http' do
      before do
        merged_manifest_properties['routing_api']['http_enabled'] = false
      end

      it 'renders http_enabled as false' do
        expect(rendered_config['api']['http_enabled']).to eq(false)
      end
    end

    describe 'when overrideing the mTLS api listen port' do
      before do
        merged_manifest_properties['routing_api']['mtls_port'] = 6000
      end

      it 'renders the overridden port' do
        expect(rendered_config['api']['mtls_listen_port']).to eq(6000)
      end
    end

    describe 'when overrideing the api listen port' do
      before do
        merged_manifest_properties['routing_api']['port'] = 6000
      end

      it 'renders the overridden port' do
        expect(rendered_config['api']['listen_port']).to eq(6000)
      end
    end

    describe 'when mtls is enabled' do
      before do
        merged_manifest_properties['routing_api']['mtls_enabled'] = true
      end

      it 'renders the truth' do
        expect(rendered_config['api']['mtls_enabled']).to eq(true)
      end
    end

    describe 'when the db connection should skip hostname validation' do
      before do
        merged_manifest_properties['routing_api']['sqldb']['skip_hostname_validation'] = true
      end

      it 'should render the yml accordingly' do
        expect(rendered_config['sqldb']['skip_hostname_validation']).to be true
      end
    end
  end
end
