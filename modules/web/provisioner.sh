curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | bash
apt -y install gitlab-ce

echo " external_url 'http://127.0.0.1' " > /etc/gitlab/gitlab.rb

gitlab-ctl reconfigure
gitlab-ctl status
