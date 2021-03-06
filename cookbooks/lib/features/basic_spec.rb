require 'support'

require 'features/apt_spec'
require 'features/bats_spec'
require 'features/ccache_spec'
require 'features/clang_spec'
require 'features/cloud_init_spec'
require 'features/cmake_spec'
require 'features/dictionaries_spec'
require 'features/gcc_spec'
require 'features/gimme_spec'
require 'features/git_spec'
require 'features/heroku_toolbelt_spec'
require 'features/imagemagick_spec'
require 'features/jq_spec'
require 'features/md5deep_spec'
require 'features/mercurial_spec'
require 'features/openssl_spec'
require 'features/packer_spec'
require 'features/ragel_spec'
require 'features/rvm_spec'
require 'features/ssh_spec'
require 'features/subversion_spec'
require 'features/sudoers_spec'
require 'features/sysctl_spec'
require 'features/system_info_spec'
require 'features/tmpfs_spec'
require 'features/travis_build_environment_packages_spec'
require 'features/travis_user_spec'
require 'features/unarchivers_spec'
require 'features/vim_spec'

describe command('lsof -v 2>&1 | head -2 | tail -1') do
  its(:stdout) { should match(/revision:/) }
  its(:exit_status) { should eq 0 }
end

describe command('iptables --version') do
  its(:stdout) { should include 'iptables' }
  its(:exit_status) { should eq 0 }
end

describe command('curl --version | head -1') do
  its(:stdout) { should include 'curl' }
  its(:exit_status) { should eq 0 }
end

describe command('wget --version') do
  its(:stdout) { should include 'GNU Wget' }
  its(:exit_status) { should eq 0 }
end

describe command('rsync --version') do
  its(:stdout) { should match(/rsync.+version/) }
  its(:exit_status) { should eq 0 }
end

describe command('nc -h') do
  its(:exit_status) { should eq 0 }
end

describe command('ldconfig -V') do
  its(:stdout) { should include 'ldconfig ' }
  its(:exit_status) { should eq 0 }
end

describe command('ldconfig -p | grep libldap') do
  its(:stdout) { should match(/libldap_r/) }
  its(:exit_status) { should eq 0 }
end

context 'with something listening on 19494' do
  around :each do |example|
    pid = spawn(
      'python', '-m', 'SimpleHTTPServer', '19494',
      [:out, :err] => '/dev/null'
    )
    tcpwait('127.0.0.1', 19_494)
    example.run
    Process.kill(:TERM, pid)
  end

  describe command('nc -zv 127.0.0.1 19494') do
    stream = if RbConfig::CONFIG['build_os'] =~ /darwin/
               :stdout
             else
               :stderr
             end
    its(stream) { should include 'succeeded' }
  end
end

describe file('/opt') do
  it { should be_directory }
  it 'is writable' do
    File.open('/opt/.travis-write-test', 'w') do |f|
      f.puts Time.now.utc.to_s
    end
    expect(File.read('/opt/.travis-write-test')).to_not be_empty
  end
end

describe file('/etc/hosts') do
  let :lines do
    subject.content.split("\n").map(&:strip).reject do |line|
      line =~ /^\s*#/ || line.empty?
    end
  end

  %w(127.0.0.1 127.0.1.1).each do |ipv4_addr|
    it "has one #{ipv4_addr} entry" do
      expect(lines.grep(/^\s*#{ipv4_addr}\b/).length).to eq(1)
    end
  end

  {
    '127.0.0.1' => 'localhost',
    '127.0.1.1' => 'ip4-loopback'
  }.each do |addr, name|
    it "maps #{addr} to #{name}" do
      expect(lines.grep(/^\s*#{addr}\b/).first.split(/\s+/)).to include(name)
    end
  end
end
