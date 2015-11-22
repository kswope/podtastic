
FROM phusion/baseimage


ENV HOME /root
CMD ["/sbin/my_init"]

# rm runs these
RUN rm -f /etc/service/sshd/down
# RUN rm -f /etc/service/nginx/down
# RUN rm -f /etc/service/memcached/down

# Invalidate all following layer caches by changing date in update_to_apt_upgrade.txt
# Don't put this above SECRET_KEY_BASE generation!
# COPY apt_upgrade.txt /tmp/

# upgrade the system, you can later upgrade the system by modifying apt_upgrade.txt
RUN apt-get update && apt-get upgrade -y -o Dpkg::Options::="--force-confold"
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# If you want ssh access put your pub key here
# COPY id_rsa.pub /tmp/your_key.pub
# RUN cat /tmp/your_key.pub >> /root/.ssh/authorized_keys && rm -f /tmp/your_key.pub

# ENV rails_root /home/app/webapp

# RUN rm /etc/nginx/sites-enabled/default
# COPY webapp.conf           /etc/nginx/sites-enabled/
# COPY preserve_secrets.conf /etc/nginx/main.d/
# COPY nginx_tunings.conf    /etc/nginx/conf.d/
# COPY rake_db_migrate.sh    /etc/my_init.d/90_rake_db_migrate.sh

# RUN mkdir $rails_root
# WORKDIR $rails_root

# # Create a caching layer with gems installed, but not source
# COPY backend/Gemfile      ${rails_root}/
# COPY backend/Gemfile.lock ${rails_root}/
# RUN RAILS_ENV=production bundle install --without development test

# # now copy over source
# COPY backend ${rails_root}/
# RUN RAILS_ENV=production rake assets:precompile

# # COPY and assets:precompile made everything root
# RUN chown -R app.app $rails_root

