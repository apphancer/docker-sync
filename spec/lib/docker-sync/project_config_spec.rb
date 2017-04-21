describe DockerSync::ProjectConfig do
  subject { described_class.new }

  describe '#initialize' do
    describe 'minimum configuration with defaults' do
      it 'loads simplest config' do
        use_fixture 'simplest' do
          expect(subject.to_h).to eql({
            'version' => '2',
            'syncs' => {
              'simplest-sync' => {
                'src' => './app',
                'dest' => '/var/www'
              }
            }
          })
        end
      end
    end

    describe 'overwriting defaults with explicit configuration' do
      it 'loads rsync config' do
        use_fixture 'rsync' do
          expect(subject.to_h).to eql({
            'version' => '2',
            'options' => {
              'verbose' => true,
            },
            'syncs' => {
              'appcode-rsync-sync' => {
                'src' => './app',
                'dest' => '/var/www',
                'sync_host_ip' => 'localhost',
                'sync_host_port' => 10872,
                'sync_strategy' => 'rsync'
              }
            }
          })
        end
      end

      it 'loads unison config' do
        use_fixture 'unison' do
          expect(subject.to_h).to eql({
            'version' => '2',
            'options' => {
              'verbose' => true,
            },
            'syncs' => {
              'appcode-unison-sync' => {
                'src' => './app',
                'dest' => '/var/www',
                'sync_excludes' => ['ignored_folder', '.ignored_dot_folder'],
                'sync_strategy' => 'unison'
              }
            }
          })
        end
      end
    end

    describe 'parent directory lookup' do
      it 'able to lookup into parent directory' do
        use_fixture 'simplest/app' do
          expect(subject.to_h).to eql({
            'version' => '2',
            'syncs' => {
              'simplest-sync' => {
                'src' => './app',
                'dest' => '/var/www'
              }
            }
          })
        end
      end
    end

    describe 'explicit config_path' do
      subject { described_class.new(config_path: config_path) }

      context 'given config path exists' do
        let(:config_path) { File.join(fixture_path('simplest'), 'docker-sync.yml') }

        it 'load the config regardless of current working directory' do
          expect(subject.to_h).to eql({
            'version' => '2',
            'syncs' => {
              'simplest-sync' => {
                'src' => './app',
                'dest' => '/var/www'
              }
            }
          })
        end
      end

      context 'given config path does not exists' do
        let(:config_path) { File.join(fixture_path('foo'), 'bar.yml') }

        it 'raise error_missing_given_config' do
          expect {
            subject
          }.to raise_error("Config could not be loaded from #{config_path} - it does not exist")
        end
      end
    end

    describe 'explicit config_string' do
      let(:config_string) {
        <<~YAML
        version: "2"

        syncs:
          #IMPORTANT: ensure this name is unique and does not match your other application container name
          config-string-sync: #tip: add -sync and you keep consistent names als a convention
            src: './foo'
            dest: '/foo/bar'
        YAML
      }

      subject { described_class.new(config_string: config_string) }

      it 'load the config string' do
        expect(subject.to_h).to eql({
          'version' => '2',
          'syncs' => {
            'config-string-sync' => {
              'src' => './foo',
              'dest' => '/foo/bar'
            }
          }
        })
      end
    end

    describe 'dynamic configuration with ENV and interpolation' do
      it 'reads from .env and interpolate source yml' do
        use_fixture 'dynamic-configuration-dotenv' do
          expect(subject.to_h).to eql({
            'version' => '2',
            'options' => {
              'verbose' => true
            },
            'syncs' => {
              'docker-boilerplate-unison-sync' => {
                'src' => './app',
                'dest' => '/var/www',
                'sync_excludes' => ['ignored_folder', '.ignored_dot_folder' ]
              }
            }
          })
        end
      end
    end

    describe 'error handling' do
      it 'raise ERROR_MISSING_CONFIG_VERSION if version is missing from setting' do
        use_fixture 'missing_version' do
          expect { subject }.to raise_error(DockerSync::ProjectConfig::ERROR_MISSING_CONFIG_VERSION)
        end
      end

      it 'raise ERROR_MISMATCH_CONFIG_VERSION if version number does not match' do
        use_fixture 'mismatch_version' do
          expect { subject }.to raise_error(DockerSync::ProjectConfig::ERROR_MISMATCH_CONFIG_VERSION)
        end
      end
    end
  end
end
